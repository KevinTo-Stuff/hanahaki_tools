// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:hanahaki_tools/src/presentation/screens/home_screen.dart';

// Import the HomeScreen from the project

void main() {
  testWidgets('HomeScreen shows title, description, settings and grid buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: HomeScreen()));

    // Allow any frames to settle
    await tester.pumpAndSettle();

    // Check title
    expect(find.text('Hanahaki Tools'), findsOneWidget);

    // Check description text
    expect(find.textContaining('A set of tools designed'), findsOneWidget);

    // Settings button - it's a Button.outline with title 'Settings' which will render the text
    expect(find.text('Settings'), findsOneWidget);

    // GridView should be present
    expect(find.byType(GridView), findsOneWidget);

    // There are six SquareButton.primary widgets - they contain their titles as text
    final expectedButtons = [
      'Characters',
      'Compendium',
      'Skills',
      'Items',
      'Tools',
      'Battle Simulator',
    ];

    for (final title in expectedButtons) {
      expect(
        find.text(title),
        findsOneWidget,
        reason: 'Expected to find button with title "$title"',
      );
    }
  });
}
