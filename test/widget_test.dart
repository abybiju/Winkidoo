import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winkidoo/app.dart';

void main() {
  testWidgets('App builds and shows loading or login', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WinkidooApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
