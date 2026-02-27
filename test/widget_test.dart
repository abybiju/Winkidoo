import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Minimal app tree builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: Text('Test')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Test'), findsOneWidget);
  });
}
