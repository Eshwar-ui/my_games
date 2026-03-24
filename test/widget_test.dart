import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_games/games/game_2048.dart';
import 'package:my_games/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Game selection screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Select a Game'), findsOneWidget);
    expect(find.text('Tic-Tac-Toe'), findsOneWidget);
    expect(find.text('Space War'), findsOneWidget);
  });

  testWidgets('2048 starts with two visible tiles', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Game2048()));
    await tester.pumpAndSettle();

    final tileTexts = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .where((text) => text == '2' || text == '4')
        .length;

    expect(tileTexts, greaterThanOrEqualTo(2));
  });
}
