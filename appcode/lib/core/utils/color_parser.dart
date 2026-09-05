import 'package:flutter/material.dart';

Color parseHexColor(String value, {Color fallback = Colors.transparent}) {
  if (value.startsWith('#')) {
    final hex = value.substring(1);
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  }

  const named = <String, Color>{
    'Red': Colors.red,
    'Blue': Colors.blue,
    'Green': Colors.green,
    'Yellow': Colors.yellow,
    'Orange': Colors.orange,
    'Purple': Colors.purple,
    'Black': Colors.black,
    'White': Colors.white,
    'Pink': Colors.pink,
    'Teal': Colors.teal,
  };
  return named[value] ?? fallback;
}
