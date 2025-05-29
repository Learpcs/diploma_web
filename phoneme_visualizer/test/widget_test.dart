// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:phoneme_visualizer/main.dart';

void main() {
  testWidgets('Phoneme Visualizer main UI smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PhonemeVisualizerApp());

    // Verify that the main title is present.
    expect(find.text('Phoneme Visualizer'), findsOneWidget);
    expect(find.text('Audio Settings'), findsOneWidget);
    expect(find.text('Tweak Variables'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });
}
