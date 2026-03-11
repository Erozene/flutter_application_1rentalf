import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;

Future<void> initStripe() async {
  Stripe.publishableKey =
      'pk_test_51T3jQCF1I6MooqLu46kR18bf5LiyjGxISNsafZgekNVJlOqF0r8Yp3hbCYptGf0aruHOByvToFrUWrOeR0diQwYe000I0qiWiJ';
  await Stripe.instance.applySettings();
}

Future<void> initStripePaymentSheet(String clientSecret) async {
  await Stripe.instance.initPaymentSheet(
    paymentSheetParameters: SetupPaymentSheetParameters(
      paymentIntentClientSecret: clientSecret,
      merchantDisplayName: 'BASERENT',
      style: ThemeMode.dark,
    ),
  );
  await Stripe.instance.presentPaymentSheet();
}
