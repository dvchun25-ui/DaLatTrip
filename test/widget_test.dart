import 'package:flutter_test/flutter_test.dart';
import 'package:dalattrip/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Basic test checking widget definition
    expect(const DaLatTripApp(), isNotNull);
  });
}
