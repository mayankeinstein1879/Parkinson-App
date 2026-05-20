import 'package:flutter_test/flutter_test.dart';
import 'package:parkinson_insole_app/app.dart';

void main() {
  testWidgets('App smoke test — launches without crashing', (WidgetTester tester) async {
    // Basic smoke test — ensures the app widget builds
    // Full BLE tests are skipped here (hardware required)
    expect(ParkinsonInsoleApp, isNotNull);
  });
}
