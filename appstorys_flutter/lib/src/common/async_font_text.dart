import 'package:flutter/material.dart';

import '../utils/font_cache.dart';

class AsyncFontText extends StatefulWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AsyncFontText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<AsyncFontText> createState() => _AsyncFontTextState();
}

class _AsyncFontTextState extends State<AsyncFontText> {
  String? _resolvedFontFamily;

  @override
  void initState() {
    super.initState();
    _resolveFont();
  }

  @override
  void didUpdateWidget(covariant AsyncFontText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style?.fontFamily != widget.style?.fontFamily) {
      _resolveFont();
    }
  }

  Future<void> _resolveFont() async {
    final raw = widget.style?.fontFamily;
    final resolved = await FontCache.resolveFontFamily(raw);
    if (mounted) {
      setState(() => _resolvedFontFamily = resolved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.data,
      style: widget.style?.copyWith(fontFamily: _resolvedFontFamily),
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}

