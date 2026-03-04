import express from 'express';
import Stripe from 'stripe';
import dotenv from 'dotenv';

// Load environment variables from .env
dotenv.config();

const app = express();
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, { apiVersion: '2023-08-16' });

// Parse JSON bodies
app.use(express.json());

// Simple test endpoint
app.get('/', (req, res) => res.send('Baserent Backend is running!'));

// Stripe payment intent endpoint
app.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount } = req.body;
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency: 'usd',
    });
    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Start server
const PORT = process.env.PORT || 10000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));