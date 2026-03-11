const express = require("express");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
const cors = require("cors");
const { Resend } = require("resend");

const app = express();
const resend = new Resend(process.env.RESEND_API_KEY);

// Firebase Admin for FCM
let adminDb = null;
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    const admin = require('firebase-admin');
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    adminDb = admin.firestore();
    console.log('✅ Firebase Admin initialized');
  } catch (e) {
    console.error('Firebase Admin init failed:', e.message);
  }
}
const FROM_EMAIL = process.env.FROM_EMAIL || "BASERENT <noreply@baserent.com>";
const APP_URL = process.env.APP_URL || "https://baserent.onrender.com";

app.use(cors());
app.use(express.json());

// ── Email helper ──────────────────────────────────────────────────────────────
async function sendEmail({ to, subject, html }) {
  if (!process.env.RESEND_API_KEY) {
    console.log(`[EMAIL SKIPPED - no RESEND_API_KEY] To: ${to} | ${subject}`);
    return;
  }
  try {
    await resend.emails.send({ from: FROM_EMAIL, to, subject, html });
    console.log(`✉️  Email sent to ${to}: ${subject}`);
  } catch (err) {
    console.error("Email send failed:", err.message);
  }
}

// ── Email templates ───────────────────────────────────────────────────────────
function emailBase(content) {
  return `
    <div style="background:#0A0A0A;padding:40px 0;font-family:'Courier New',monospace;">
      <div style="max-width:560px;margin:0 auto;background:#111;border:1px solid #222;">
        <div style="background:#FF4E00;padding:20px 32px;">
          <span style="font-size:28px;letter-spacing:6px;color:#fff;font-weight:bold;">BASE</span><span style="font-size:28px;letter-spacing:6px;color:#111;font-weight:bold;">RENT</span>
        </div>
        <div style="padding:32px;">
          ${content}
        </div>
        <div style="padding:20px 32px;border-top:1px solid #222;text-align:center;">
          <p style="color:#555;font-size:11px;letter-spacing:1px;margin:0;">BASERENT · EQUIPMENT RENTAL MARKETPLACE</p>
        </div>
      </div>
    </div>`;
}

function row(label, value) {
  return `<tr>
    <td style="color:#888;font-size:11px;letter-spacing:1px;padding:6px 0;">${label.toUpperCase()}</td>
    <td style="color:#fff;font-size:12px;text-align:right;padding:6px 0;">${value}</td>
  </tr>`;
}

function bookingConfirmedEmail({ equipmentTitle, days, total, depositAmount, startDate, endDate, bookingId }) {
  const depositRow = depositAmount > 0
    ? row("Security Deposit (held)", `$${depositAmount.toFixed(2)}`)
    : "";
  return emailBase(`
    <p style="color:#FF4E00;font-size:11px;letter-spacing:3px;margin:0 0 16px;">BOOKING CONFIRMED</p>
    <h1 style="color:#fff;font-size:32px;letter-spacing:3px;margin:0 0 8px;font-weight:bold;">YOUR GEAR<br>IS RESERVED</h1>
    <p style="color:#888;font-size:12px;line-height:1.8;margin:0 0 28px;">Your payment was successful and your rental is confirmed.</p>
    <table style="width:100%;border-collapse:collapse;border-top:1px solid #222;margin-bottom:28px;">
      ${row("Gear", equipmentTitle)}
      ${row("Dates", `${startDate} → ${endDate}`)}
      ${row("Duration", `${days} day${days !== 1 ? "s" : ""}`)}
      ${row("Rental Total", `$${total.toFixed(2)}`)}
      ${depositRow}
      ${row("Booking ID", `#${bookingId.substring(0, 8).toUpperCase()}`)}
    </table>
    ${depositAmount > 0 ? `<div style="background:#1a1a1a;border:1px solid #333;padding:16px;margin-bottom:20px;">
      <p style="color:#FF4E00;font-size:11px;letter-spacing:1px;margin:0 0 6px;">ABOUT YOUR DEPOSIT</p>
      <p style="color:#888;font-size:11px;line-height:1.6;margin:0;">A $${depositAmount.toFixed(2)} security deposit has been held. It will be automatically refunded when you confirm the gear has been returned.</p>
    </div>` : ""}
    <p style="color:#555;font-size:11px;line-height:1.6;">Questions? Reply to this email and we'll help you out.</p>
  `);
}

function bookingCancelledEmail({ equipmentTitle, bookingId }) {
  return emailBase(`
    <p style="color:#FF4E00;font-size:11px;letter-spacing:3px;margin:0 0 16px;">BOOKING CANCELLED</p>
    <h1 style="color:#fff;font-size:32px;letter-spacing:3px;margin:0 0 8px;font-weight:bold;">BOOKING<br>CANCELLED</h1>
    <p style="color:#888;font-size:12px;line-height:1.8;margin:0 0 28px;">Your booking has been cancelled.</p>
    <table style="width:100%;border-collapse:collapse;border-top:1px solid #222;margin-bottom:28px;">
      ${row("Gear", equipmentTitle)}
      ${row("Booking ID", `#${bookingId.substring(0, 8).toUpperCase()}`)}
    </table>
    <p style="color:#555;font-size:11px;line-height:1.6;">If you were charged and a refund is due, it will appear within 5–10 business days.</p>
  `);
}

function depositReleasedEmail({ equipmentTitle, depositAmount, bookingId }) {
  return emailBase(`
    <p style="color:#4CAF50;font-size:11px;letter-spacing:3px;margin:0 0 16px;">DEPOSIT RELEASED</p>
    <h1 style="color:#fff;font-size:32px;letter-spacing:3px;margin:0 0 8px;font-weight:bold;">YOUR DEPOSIT<br>IS ON ITS WAY</h1>
    <p style="color:#888;font-size:12px;line-height:1.8;margin:0 0 28px;">You confirmed the gear was returned. Your deposit is being refunded.</p>
    <table style="width:100%;border-collapse:collapse;border-top:1px solid #222;margin-bottom:28px;">
      ${row("Gear", equipmentTitle)}
      ${row("Deposit Refund", `$${depositAmount.toFixed(2)}`)}
      ${row("Booking ID", `#${bookingId.substring(0, 8).toUpperCase()}`)}
    </table>
    <p style="color:#555;font-size:11px;line-height:1.6;">Refunds typically appear within 5–10 business days depending on your bank.</p>
  `);
}

function newMessageEmail({ senderEmail, equipmentTitle, messagePreview }) {
  return emailBase(`
    <p style="color:#FF4E00;font-size:11px;letter-spacing:3px;margin:0 0 16px;">NEW MESSAGE</p>
    <h1 style="color:#fff;font-size:32px;letter-spacing:3px;margin:0 0 8px;font-weight:bold;">YOU HAVE A<br>NEW MESSAGE</h1>
    <p style="color:#888;font-size:12px;line-height:1.8;margin:0 0 28px;">Someone sent you a message about <strong style="color:#fff;">${equipmentTitle}</strong>.</p>
    <div style="background:#1a1a1a;border-left:3px solid #FF4E00;padding:16px;margin-bottom:28px;">
      <p style="color:#888;font-size:10px;letter-spacing:1px;margin:0 0 8px;">FROM ${senderEmail.toUpperCase()}</p>
      <p style="color:#fff;font-size:13px;line-height:1.6;margin:0;">${messagePreview}</p>
    </div>
    <p style="color:#555;font-size:11px;">Open the BASERENT app to reply.</p>
  `);
}

// ── Push notification helper ─────────────────────────────────────────────────
async function sendPush(userId, title, body, data = {}) {
  if (!adminDb) return;
  try {
    const admin = require('firebase-admin');
    const userDoc = await adminDb.collection('users').doc(userId).get();
    const token = userDoc.data()?.fcmToken;
    if (!token) return;

    await admin.messaging().send({
      token,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      apns: { payload: { aps: { sound: 'default', badge: 1 } } },
      android: { notification: { sound: 'default' } },
    });
    console.log(`🔔 Push sent to ${userId}: ${title}`);
  } catch (e) {
    console.error('Push send error:', e.message);
  }
}

// ── Push send endpoint ────────────────────────────────────────────────────────
app.post("/push/send", async (req, res) => {
  try {
    const { userId, title, body, data } = req.body;
    await sendPush(userId, title, body, data);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Health check ──────────────────────────────────────────────────────────────
app.get("/", (req, res) => {
  res.json({ status: "BASERENT backend running" });
});

// ── Create Payment Intent ─────────────────────────────────────────────────────
app.post("/create-payment-intent", async (req, res) => {
  try {
    const { amount, currency = "usd", receipt_email, owner_stripe_account_id, metadata } = req.body;

    if (!amount || typeof amount !== "number" || amount <= 0) {
      return res.status(400).json({ error: "Invalid amount" });
    }

    const params = {
      amount: Math.round(amount),
      currency,
      receipt_email: receipt_email || undefined,
      automatic_payment_methods: { enabled: true },
      metadata: metadata || {},
    };

    if (owner_stripe_account_id) {
      const platformFee = Math.round(amount * (parseFloat(process.env.PLATFORM_FEE_PERCENT || "30") / 100));
      params.application_fee_amount = platformFee;
      params.transfer_data = { destination: owner_stripe_account_id };
    }

    const paymentIntent = await stripe.paymentIntents.create(params);

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (err) {
    console.error("Stripe error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// ── Booking confirmed email ───────────────────────────────────────────────────
app.post("/email/booking-confirmed", async (req, res) => {
  try {
    const { userEmail, equipmentTitle, days, total, depositAmount, startDate, endDate, bookingId } = req.body;
    await sendEmail({
      to: userEmail,
      subject: `Booking confirmed — ${equipmentTitle}`,
      html: bookingConfirmedEmail({ equipmentTitle, days, total: total || 0, depositAmount: depositAmount || 0, startDate, endDate, bookingId }),
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Booking cancelled email ───────────────────────────────────────────────────
app.post("/email/booking-cancelled", async (req, res) => {
  try {
    const { userEmail, equipmentTitle, bookingId } = req.body;
    await sendEmail({
      to: userEmail,
      subject: `Booking cancelled — ${equipmentTitle}`,
      html: bookingCancelledEmail({ equipmentTitle, bookingId }),
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Deposit released email ────────────────────────────────────────────────────
app.post("/email/deposit-released", async (req, res) => {
  try {
    const { userEmail, equipmentTitle, depositAmount, bookingId } = req.body;
    await sendEmail({
      to: userEmail,
      subject: `Deposit refunded — ${equipmentTitle}`,
      html: depositReleasedEmail({ equipmentTitle, depositAmount: depositAmount || 0, bookingId }),
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── New message email ─────────────────────────────────────────────────────────
app.post("/email/new-message", async (req, res) => {
  try {
    const { recipientEmail, senderEmail, equipmentTitle, messagePreview } = req.body;
    await sendEmail({
      to: recipientEmail,
      subject: `New message about ${equipmentTitle}`,
      html: newMessageEmail({ senderEmail, equipmentTitle, messagePreview }),
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Release deposit (refund) ──────────────────────────────────────────────────
app.post("/release-deposit", async (req, res) => {
  try {
    const { payment_intent_id, booking_id } = req.body;
    if (!payment_intent_id) {
      return res.status(400).json({ error: "payment_intent_id required" });
    }

    const refund = await stripe.refunds.create({
      payment_intent: payment_intent_id,
    });

    res.json({ success: true, refund_id: refund.id, status: refund.status, booking_id });
  } catch (err) {
    console.error("Release deposit error:", err);
    res.status(500).json({ error: err.message });
  }
});

// ── Stripe Connect: onboard ───────────────────────────────────────────────────
app.post("/connect/onboard", async (req, res) => {
  try {
    const { email, return_url, refresh_url } = req.body;
    const account = await stripe.accounts.create({ type: "express", email });
    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: refresh_url || `${APP_URL}/connect/refresh`,
      return_url: return_url || `${APP_URL}/connect/return`,
      type: "account_onboarding",
    });
    res.json({ account_id: account.id, onboarding_url: accountLink.url });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Stripe Connect: status ────────────────────────────────────────────────────
app.post("/connect/status", async (req, res) => {
  try {
    const { stripe_account_id } = req.body;
    const account = await stripe.accounts.retrieve(stripe_account_id);
    res.json({
      charges_enabled: account.charges_enabled,
      payouts_enabled: account.payouts_enabled,
      details_submitted: account.details_submitted,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Stripe Connect: dashboard link ───────────────────────────────────────────
app.post("/connect/dashboard", async (req, res) => {
  try {
    const { stripe_account_id } = req.body;
    const loginLink = await stripe.accounts.createLoginLink(stripe_account_id);
    res.json({ url: loginLink.url });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Stripe Connect: balance ───────────────────────────────────────────────────
app.post("/connect/balance", async (req, res) => {
  try {
    const { stripe_account_id } = req.body;
    const balance = await stripe.balance.retrieve({ stripeAccount: stripe_account_id });
    res.json({
      available: balance.available.reduce((s, b) => s + b.amount, 0),
      pending: balance.pending.reduce((s, b) => s + b.amount, 0),
      currency: balance.available[0]?.currency || "usd",
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Webhook ───────────────────────────────────────────────────────────────────
app.post("/webhook", express.raw({ type: "application/json" }), (req, res) => {
  const sig = req.headers["stripe-signature"];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  if (!webhookSecret) return res.json({ received: true });

  let event;
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  switch (event.type) {
    case "payment_intent.succeeded":
      console.log("✅ Payment succeeded:", event.data.object.id);
      break;
    case "payment_intent.payment_failed":
      console.log("❌ Payment failed:", event.data.object.id);
      break;
    default:
      console.log(`Unhandled event: ${event.type}`);
  }

  res.json({ received: true });
});

// ── Start server ──────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`BASERENT backend listening on port ${PORT}`));
