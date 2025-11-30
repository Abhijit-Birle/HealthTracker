import 'package:flutter/material.dart';

class FuturisticSlider extends StatelessWidget {
  final double value;
  final Color color;
  final Function(double) onChanged;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  const FuturisticSlider({
    super.key,
    required this.value,
    required this.color,
    required this.onChanged,
    required this.onStart,
    required this.onEnd
  });

  @override
  Widget build(BuildContext context) {
    return Slider(
        value: value,
        onChanged: onChanged,
        activeColor: color,
        onChangeStart: (_) => onStart(),
        onChangeEnd: (_) => onEnd()
    );
  }
}