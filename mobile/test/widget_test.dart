import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rapid_photo_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: RapidPhotoApp(),
      ),
    );

    // Verify that the app title is displayed.
    expect(find.text('Welcome to RapidPhoto Upload'), findsOneWidget);
    expect(find.text('Flutter 3.27 Mobile App'), findsOneWidget);
    expect(find.byIcon(Icons.photo_library), findsOneWidget);
  });
}
