import 'package:flutter_test/flutter_test.dart';
import 'package:suraksha_ai/app.dart';

void main() {
  testWidgets('SURAKSHA AI map-first smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SurakshaApp());
    await tester.pump();

    // Verify that Photon search bar hint is present.
    expect(
      find.text('Search places via Photon (Hyderabad)...'),
      findsOneWidget,
    );

    // Verify Plan Road Route button is present.
    expect(find.text('Plan Road Route (OSRM)'), findsOneWidget);

    // Verify OSM attribution is present.
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
  });
}
