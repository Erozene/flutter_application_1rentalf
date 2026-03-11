const express = require("express");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
const cors = require("cors");

const app = express();

app.use(cors());
app.use(express.json());

// ── Health check (Render needs this to confirm the service is up) ─────────────
app.get("/", (req, res) => {
  res.json({ status: "BASERENT backend running" });
});

// ── Create Payment Intent ─────────────────────────────────────────────────────
// Called by the Flutter app before showing the Stripe payment sheet.
// Body: { amount: number (in cents), currency: string, receipt_email?: string }
app.post("/create-payment-intent", async (req, res) => {
  try {
    const { amount, currency = "usd", receipt_email } = req.body;

    if (!amount || typeof amount !== "number" || amount <= 0) {
      return res.status(400).json({ error: "Invalid amount" });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount), // already in cents from Flutter
      currency,
      receipt_email: receipt_email || undefined,
      automatic_payment_methods: { enabled: true },
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (err) {
    console.error("Stripe error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ── Stripe Webhook (optional but recommended for production) ──────────────────
// Set your webhook secret in Render env vars as STRIPE_WEBHOOK_SECRET
// This lets Stripe confirm payments server-side rather than trusting the client.
app.post(
  "/webhook",
  express.raw({ type: "application/json" }), // must be raw body for signature check
  (req, res) => {
    const sig = req.headers["stripe-signature"];
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    if (!webhookSecret) {
      // Webhook secret not configured — skip verification in dev
      return res.json({ received: true });
    }

    let event;
    try {
      event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
    } catch (err) {
      console.error("Webhook signature failed:", err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    switch (event.type) {
      case "payment_intent.succeeded":
        console.log("✅ Payment succeeded:", event.data.object.id);
        // You can log, notify, or update anything here.
        // Note: on Spark plan you can't call Firebase Admin SDK,
        // so booking is written directly from Flutter after payment.
        break;

      case "payment_intent.payment_failed":
        console.log("❌ Payment failed:", event.data.object.id);
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.json({ received: true });
  }
);

// ── Start server ──────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`BASERENT backend listening on port ${PORT}`);
});
