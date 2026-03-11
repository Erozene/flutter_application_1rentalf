// Web stub — Stripe is not supported on web
Future<void> initStripe() async {}

Future<void> initStripePaymentSheet(String clientSecret) async {
  throw Exception('Stripe payments are not available on web.');
}
