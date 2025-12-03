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
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: color,
        inactiveTrackColor: color.withOpacity(0.2),
        thumbColor: Colors.white,
        overlayColor: color.withOpacity(0.3),
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
      ),
      child: Slider(
        value: value,
        onChanged: onChanged,
        onChangeStart: (_) => onStart(),
        onChangeEnd: (_) => onEnd(),
      ),
    );
  }
}