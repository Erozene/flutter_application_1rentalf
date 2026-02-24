require('dotenv').config();

const functions = require("firebase-functions");
const express = require("express");
const cors = require("cors");
const Stripe = require("stripe");

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

app.post("/create-payment-link", async (req, res) => {
  try {
    const { priceId } = req.body;

    const paymentLink = await stripe.paymentLinks.create({
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
    });

    res.json({ url: paymentLink.url });
  } catch (error) {
    console.error(error);
    res.status(500).send("Error creating payment link");
  }
});

exports.api = functions.https.onRequest(app);
