import 'package:flutter/material.dart';

class Pixel extends StatelessWidget {
  final Color color; // Use `final` for immutability.

  const Pixel({
    super.key,
    required this.color, // Named parameter.
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      margin: const EdgeInsets.all(1),
    );
  }
}
