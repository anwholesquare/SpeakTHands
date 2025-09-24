// This is a basic Flutter widget test for SpeakTHands app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:speak_t_hands/themes/app_theme.dart';

void main() {
  testWidgets('SpeakTHands theme test', (WidgetTester tester) async {
    // Build a simple widget with our theme
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(
            child: Text('SpeakTHands Test'),
          ),
        ),
      ),
    );

    // Verify that the theme is applied correctly
    expect(find.text('SpeakTHands Test'), findsOneWidget);
    
    // Verify the theme colors are correct
    final ThemeData theme = Theme.of(tester.element(find.text('SpeakTHands Test')));
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, AppTheme.primaryColor);
  });
}
