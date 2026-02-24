import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// MOCK HTTP CLIENT (so Image.network() works in widget tests)
// ---------------------------------------------------------------------------
class MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => MockHttpClientRequest();
}

class MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => MockHttpClientResponse();
}

class MockHttpClientResponse extends Fake implements HttpClientResponse {
  static final Uint8List _imageBytes = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
    0xDE, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
    0x54, 0x08, 0xD7, 0x63, 0xF8, 0x0F, 0x00, 0x01,
    0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0x18, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82
  ]);

  @override
  int get statusCode => HttpStatus.ok;

  // ✅ Updated to match latest Flutter SDK (returns StreamSubscription)
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final controller = Stream<List<int>>.fromIterable([_imageBytes]);
    return controller.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => MockHttpClient();
}

// ---------------------------------------------------------------------------
// TESTS
// ---------------------------------------------------------------------------
void main() {
  setUpAll(() {
    // Replace real HTTP with our mock so images load
    HttpOverrides.global = TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('EquipmentApp builds and shows equipment list',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const EquipmentApp() as Widget);

    // Allow widget tree to settle (load images, etc.)
    await tester.pumpAndSettle();

    // Verify title
    expect(find.text('Equipment Rental'), findsOneWidget);

    // Verify that image widgets are loaded (network images mocked)
    expect(find.byType(Image), findsWidgets);

    // Verify that sample equipment appears
    expect(find.textContaining('Sony A7'), findsWidgets);
    expect(find.textContaining('DJI'), findsWidgets);
  });

  // OPTIONAL: If your app supports tapping to open a detail screen, uncomment this:
  /*
  testWidgets('Tap on an equipment item opens details page',
      (WidgetTester tester) async {
    await tester.pumpWidget(const EquipmentApp());
    await tester.pumpAndSettle();

    // Tap on the first equipment card
    final firstItem = find.textContaining('Sony A7');
    await tester.tap(firstItem);
    await tester.pumpAndSettle();

    // Verify detail view (adjust text as needed)
    expect(find.textContaining('Sarah Johnson'), findsOneWidget);
  });
  */
}

class EquipmentApp {
  const EquipmentApp();
}
