import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

Widget redDot() {
  return Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: Colors.red,
      shape: BoxShape.circle,
    ),
  );
}

Widget blueDot() {
  return Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: Colors.blue,
      shape: BoxShape.circle,
    ),
  );
}

Widget yellowDot() {
  return Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: Colors.yellow,
      shape: BoxShape.circle,
    ),
  );
}
