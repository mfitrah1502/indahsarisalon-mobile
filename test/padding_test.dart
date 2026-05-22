// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Padding constraints test', (WidgetTester tester) async {
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 200),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 216),
                  child: Container(),
                ),
              ),
            ),
          ),
        ),
      );
      print("NO ERROR");
    } catch (e) {
      print("ERROR CAUGHT: $e");
    }
  });
}
