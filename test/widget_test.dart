// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:midterm_project/main.dart';

void main() {
  testWidgets('shows splash screen then opens a new chess game', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ChessApp());

    expect(find.text('One board. Two players.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('game-status')), findsOneWidget);
    expect(find.text('White to move'), findsOneWidget);
    expect(find.byKey(const Key('square-e2')), findsOneWidget);
  });

  testWidgets('plays a legal move and can reset the board', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChessHome()));

    await tester.tap(find.byKey(const Key('square-e2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('square-e4')));
    await tester.pump();

    expect(find.text('Black to move'), findsOneWidget);
    expect(find.text('1. e4'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reset-game')));
    await tester.pump();

    expect(find.text('White to move'), findsOneWidget);
    expect(find.text('Your game starts here'), findsOneWidget);
  });

  testWidgets('does not allow an illegal move', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChessHome()));

    await tester.tap(find.byKey(const Key('square-e2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('square-e5')));
    await tester.pump();

    expect(find.text('White to move'), findsOneWidget);
    expect(find.text('1. e5'), findsNothing);
  });
}
