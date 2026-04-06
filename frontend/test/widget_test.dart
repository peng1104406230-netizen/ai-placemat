import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('frontend placeholder shell mounts', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('AI 智能餐垫'),
        ),
      ),
    );

    expect(find.text('AI 智能餐垫'), findsOneWidget);
  });
}
