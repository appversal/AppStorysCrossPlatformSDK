import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PipVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool mute;
  final bool isPlaying;
  final bool showControls;
  final void Function(VideoPlayerController controller)? onControllerReady;

  const PipVideoPlayer({
    super.key,
    required this.videoUrl,
    this.mute = false,
    this.isPlaying = true,
    this.showControls = false,
    this.onControllerReady,
  });

  @override
  State<PipVideoPlayer> createState() => _PipVideoPlayerState();
}

class _PipVideoPlayerState extends State<PipVideoPlayer> {
  VideoPlayerController? _controller;

  bool _initialized = false;
  bool _hasError = false;

  int _retry = 0;
  static const int _maxRetry = 3;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant PipVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔹 mute toggle
    if (widget.mute != oldWidget.mute) {
      _controller?.setVolume(widget.mute ? 0 : 1);
    }

    // 🔹 play / pause
    if (widget.isPlaying != oldWidget.isPlaying) {
      widget.isPlaying ? _controller?.play() : _controller?.pause();
    }

    // 🔹 video changed (important fix)
    if (widget.videoUrl != oldWidget.videoUrl) {
      _resetAndReinitialize();
    }
  }

  Future<void> _resetAndReinitialize() async {
    await _disposeController();
    _retry = 0;
    _initialized = false;
    _hasError = false;
    _initialize();
  }

  Future<void> _initialize() async {
    if (_retry >= _maxRetry) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );

      _controller = controller;

      controller.addListener(_errorListener);

      await controller.initialize();

      if (!mounted) return;

      controller
        ..setLooping(true)
        ..setVolume(widget.mute ? 0 : 1);

      if (widget.isPlaying) {
        await controller.play();
      }

      widget.onControllerReady?.call(controller);

      setState(() {
        _initialized = true;
        _hasError = false;
      });
    } catch (_) {
      _retry++;

      if (_retry < _maxRetry) {
        await Future.delayed(const Duration(seconds: 1));
        _initialize();
      } else {
        if (mounted) setState(() => _hasError = true);
      }
    }
  }

  void _errorListener() {
    final hasError = _controller?.value.hasError ?? false;

    if (hasError && mounted) {
      setState(() => _hasError = true);
    }
  }

  Future<void> _disposeController() async {
    try {
      _controller?.removeListener(_errorListener);
      await _controller?.dispose();
    } catch (_) {}
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 ERROR STATE
    if (_hasError) {
      return Center(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _hasError = false;
              _retry = 0;
            });
            _initialize();
          },
          child: const Icon(
            Icons.refresh,
            color: Colors.white,
            size: 32,
          ),
        ),
      );
    }

    // ⏳ LOADING STATE
    if (!_initialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // ▶️ VIDEO
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),

        if (widget.showControls)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white54,
                backgroundColor: Colors.black45,
              ),
            ),
          ),
      ],
    );
  }
}