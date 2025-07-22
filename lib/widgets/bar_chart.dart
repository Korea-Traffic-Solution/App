import 'package:flutter/material.dart';

class BarChart extends StatelessWidget {
  final String day;
  final double height;
  final Color color;

  const BarChart({
    Key? key,
    required this.day,
    required this.height,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: height * 1.5,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(day),
      ],
    );
  }
}