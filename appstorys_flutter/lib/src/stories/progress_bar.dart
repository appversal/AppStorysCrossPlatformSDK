import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class ProgressBar extends StatefulWidget {
  const ProgressBar({
    super.key,
    required this.percentWatched,
    this.isCompleted = false,
  });

  final double percentWatched;
  final bool isCompleted;

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  @override
  Widget build(BuildContext context) {
    return LinearPercentIndicator(
      padding: const EdgeInsets.only(left: 6),
      barRadius: const Radius.circular(20),
      lineHeight: 3,
      percent: widget.isCompleted ? 1.0 : widget.percentWatched,
      progressColor: const Color.fromARGB(255, 211, 202, 202),
      backgroundColor: Colors.grey[600],
      animation: false,
    );
  }
}