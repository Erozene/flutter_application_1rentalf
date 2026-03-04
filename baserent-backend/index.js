import express from 'express';
import cors from 'cors';
import Stripe from 'stripe';
import dotenv from 'dotenv';

// Load environment variables from Render's environment
dotenv.config();

const app = express();
const port = process.env.PORT || 10000;

// Configure middleware
app.use(cors());
app.use(express.json());

// Initialize Stripe with secret key from environment
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

// Example endpoint: create a payment intent
app.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount, currency } = req.body;

    if (!amount || !currency) {
      return res.status(400).json({ error: 'Amount and currency are required' });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency
    });

    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (error) {
    console.error('Stripe error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Health check endpoint
app.get('/', (req, res) => {
  res.send('BaseRent Backend is running 🚀');
});

// Start server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});