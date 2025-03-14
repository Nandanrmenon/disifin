import 'package:flutter/material.dart';

class SoundWaveformWidget extends StatefulWidget {
  const SoundWaveformWidget({super.key});

  @override
  _SoundWaveformWidgetState createState() => _SoundWaveformWidgetState();
}

class _SoundWaveformWidgetState extends State<SoundWaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Container(
                width: 4,
                height: 10 + 10 * (1 - _controller.value * (index + 1) / 5),
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }),
        );
      },
    );
  }
}
