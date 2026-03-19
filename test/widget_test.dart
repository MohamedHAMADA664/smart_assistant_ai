import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_assistant_ai/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartAssistantApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
