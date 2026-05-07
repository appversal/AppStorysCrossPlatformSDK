import 'package:flutter/material.dart';
import '../stories/progress_bar.dart';

class StoriesBar extends StatefulWidget {
  final double percentWatched;
  final int currentIndex;
  final int totalStories;

  const StoriesBar({
    super.key,
    required this.percentWatched,
    required this.currentIndex,
    required this.totalStories,
  });

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 6, right: 6),
        child: Row(
          children: List.generate(
            widget.totalStories,
                (index) => Expanded(
              child: ProgressBar(
                percentWatched: index < widget.currentIndex
                    ? 1.0
                    : index == widget.currentIndex
                    ? widget.percentWatched
                    : 0.0,
                isCompleted: index < widget.currentIndex,
              ),
            ),
          ),
        ),
      ),
    );
  }
}