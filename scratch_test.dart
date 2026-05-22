import 'package:flutter/material.dart';

void main() {
  runApp(
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
}
