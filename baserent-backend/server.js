const express = require('express');
const cors = require('cors');
const Stripe = require('stripe');

const app = express();
app.use(cors());
app.use(express.json());

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

// CREATE PAYMENT LINK
app.post('/create-payment-link', async (req, res) => {
  try {
    const { amount, title } = req.body;

    const product = await stripe.products.create({
      name: title,
    });

    const price = await stripe.prices.create({
      unit_amount: amount,
      currency: 'eur',
      product: product.id,
    });

    const paymentLink = await stripe.paymentLinks.create({
      line_items: [
        {
          price: price.id,
          quantity: 1,
        },
      ],
    });

    res.json({
      url: paymentLink.url,
    });
  } catch (error) {
    console.error(error);
    res.status(500).send('Error creating payment link');
  }
});

app.get('/', (req, res) => {
  res.send('Stripe backend running');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log('Server started'));