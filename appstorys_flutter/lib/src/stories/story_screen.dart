import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../appstorys_flutter.dart';
import '../common/cross_button.dart';
import '../common/share_button.dart';
import '../common/cta_button.dart';
import '../models/stories_models.dart';
import '../stories/stories_bar.dart';
import '../utils/link_handler.dart';
import '../common/mute_button.dart';
import '../common/unmute_button.dart';

class StoryScreen extends StatefulWidget {
  final CampaignStory storyGroup;
  final String storyCampaignId;
  final int groupIndex;
  final AppstorysFlutter? appStorys;
  final ValueChanged<String>? onSlideViewed;
  final void Function(String link)? onLinkTap;

  const StoryScreen({
    super.key,
    required this.storyGroup,
    required this.storyCampaignId,
    required this.groupIndex,
    this.appStorys,
    this.onSlideViewed,
    this.onLinkTap,
  });

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

enum MediaType { video, lottie, gif, image }

class _StoryScreenState extends State<StoryScreen> {
  late CampaignStory storyGroup;
  int currentStoryIndex = 0;
  int currentGroupIndex = 0;
  double percentWatched = 0;
  VideoPlayerController? _videoController;
  Timer? _progressTimer;
  MediaType currentMediaType = MediaType.image;
  bool isLoading = true;
  bool hasError = false;
  bool isVideoReady = false;
  bool isImageLoading = true;
  bool isCompletingStory = false;

  bool isSoundMuted = false;
  double videoAspectRatio = 1;

  double _dragStartY = 0;
  double _dragDistance = 0;
  final double _dismissThreshold = 100.0;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void initState() {
    super.initState();
    storyGroup = widget.storyGroup;
    currentGroupIndex = widget.groupIndex;

    // Initialize sound mute state from JSON
    final soundToggleConfig =
    storyGroup.groups[currentGroupIndex].styling?['soundToggle'];
    if (soundToggleConfig is Map) {
      isSoundMuted = soundToggleConfig['defaultSound'] == 'yes';
    }

    _startWatching();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _videoController?.pause();
    _videoController?.dispose();
    _removeImageStreamListener();
    super.dispose();
  }

  void _removeImageStreamListener() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
      _imageStreamListener = null;
      _imageStream = null;
    }
  }

  MediaType _getMediaType(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.mov')) {
      return MediaType.video;
    } else if (lowerUrl.endsWith('.json')) {
      return MediaType.lottie;
    } else if (lowerUrl.endsWith('.gif')) {
      return MediaType.gif;
    } else {
      return MediaType.image;
    }
  }

  /// Helper method to check if thumbnail is Lottie
  bool _isLottieThumbnail(String thumbnail) {
    return thumbnail.toLowerCase().endsWith('.json');
  }

  void _loadImage(String imageUrl) {
    setState(() {
      isImageLoading = true;
      isLoading = true;
    });

    _removeImageStreamListener();

    final ImageProvider imageProvider = CachedNetworkImageProvider(imageUrl);
    _imageStream = imageProvider.resolve(ImageConfiguration.empty);

    _imageStreamListener = ImageStreamListener(
          (ImageInfo imageInfo, bool synchronousCall) {
        if (!mounted) return;
        setState(() {
          isImageLoading = false;
          isLoading = false;
        });
        final slideShowTime =
                storyGroup.groups[currentGroupIndex].styling?['slideShowTime'] ??
                5;
        _startProgressTimer(Duration(seconds: slideShowTime));
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        if (!mounted) return;
        debugPrint('Image loading error: $exception');
        setState(() {
          isImageLoading = false;
          isLoading = false;
          hasError = true;
        });
      },
    );

    _imageStream!.addListener(_imageStreamListener!);
  }

  void _loadGif(String gifUrl) {
    if (!mounted) return;
    setState(() {
      currentMediaType = MediaType.gif;
      isLoading = false;
      hasError = false;
    });

    final slideShowTime =
        storyGroup.groups[currentGroupIndex].styling?['slideShowTime'] ?? 5;
    _startProgressTimer(Duration(seconds: slideShowTime));
  }

  void _loadLottie(String lottieUrl) {
    if (!mounted) return;
    setState(() {
      currentMediaType = MediaType.lottie;
      isLoading = false;
      hasError = false;
    });

    final slideShowTime =
        storyGroup.groups[currentGroupIndex].styling?['slideShowTime'] ?? 5;
    _startProgressTimer(Duration(seconds: slideShowTime));
  }

  void _startWatching() {
    if (!mounted) return;

    final currentMedia =
    storyGroup.groups[currentGroupIndex].slides[currentStoryIndex];
    _progressTimer?.cancel();

    // Properly dispose old video controller
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.dispose();
      _videoController = null;
    }

    percentWatched = 0;
    isCompletingStory = false;
    isVideoReady = false;

    if (currentMedia.video != null && currentMedia.video!.isNotEmpty) {
      debugPrint('Loading video: ${currentMedia.video}');
      _playVideo(currentMedia.video!);
    } else if (currentMedia.image != null && currentMedia.image!.isNotEmpty) {
      final mediaType = _getMediaType(currentMedia.image!);
      debugPrint('Loading media type: $mediaType, URL: ${currentMedia.image}');

      switch (mediaType) {
        case MediaType.video:
          _playVideo(currentMedia.image!);
          break;
        case MediaType.lottie:
          _loadLottie(currentMedia.image!);
          break;
        case MediaType.gif:
          _loadGif(currentMedia.image!);
          break;
        case MediaType.image:
          setState(() {
            currentMediaType = MediaType.image;
            isLoading = false;
            isVideoReady = false;
          });
          _loadImage(currentMedia.image!);
          break;
      }
    } else {
      if (!mounted) return;
      debugPrint('No media found for current slide');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }

    final slideId =
        storyGroup.groups[currentGroupIndex].slides[currentStoryIndex].id;
    widget.onSlideViewed?.call(slideId);
    widget.appStorys?.trackEvent(
      event: 'viewed',
      campaignId: widget.storyCampaignId,
      metadata: {
        'story_slide': slideId,
      },
    );
  }

  void _playVideo(String videoUrl) async {
    if (!mounted) return;

    debugPrint('Starting video play: $videoUrl');

    setState(() {
      currentMediaType = MediaType.video;
      isLoading = true;
      hasError = false;
      isVideoReady = false;
    });

    // Dispose old controller properly
    if (_videoController != null) {
      await _videoController!.pause();
      await _videoController!.dispose();
      _videoController = null;
    }

    try {
      debugPrint('Attempting to load video from cache: $videoUrl');
      final file = await DefaultCacheManager().getSingleFile(videoUrl);

      if (!mounted) return;

      debugPrint('Video cached successfully, creating controller');
      _videoController = VideoPlayerController.file(file);

      // Try to initialize from cached file
      await _initializeVideoController(isNetworkFallback: false);
    } catch (e) {
      if (!mounted) return;

      debugPrint('Cache load failed: $e, using network URL');

      // Fallback to network URL
      if (_videoController != null) {
        _videoController!.dispose();
        _videoController = null;
      }

      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _initializeVideoController(isNetworkFallback: true);
    }
  }

  Future<void> _initializeVideoController(
      {required bool isNetworkFallback}) async {
    if (!mounted || _videoController == null) return;

    try {
      await _videoController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint(
              '${isNetworkFallback ? '[Network]' : '[Cached]'} Video initialization timeout');
          throw TimeoutException('Video initialization took too long');
        },
      );

      if (!mounted) return;

      debugPrint(
          '${isNetworkFallback ? '[Network]' : '[Cached]'} Video initialized successfully');

      _videoController!.addListener(_onVideoProgress);

      // Apply initial mute state
      if (isSoundMuted) {
        _videoController!.setVolume(0.0);
      } else {
        _videoController!.setVolume(1.0);
      }

      setState(() {
        isLoading = false;
        isVideoReady = true;
        videoAspectRatio = _videoController!.value.aspectRatio;
        hasError = false;
      });

      _videoController!.play();
      _startProgressTimer(_videoController!.value.duration);
    } catch (error) {
      if (!mounted) return;

      debugPrint(
          "${isNetworkFallback ? '[Network]' : '[Cached]'} Error initializing: $error");

      // If this was cached version and failed, try network
      if (!isNetworkFallback) {
        debugPrint('Retrying with network URL...');

        if (_videoController != null) {
          _videoController!.dispose();
          _videoController = null;
        }

        final currentMedia =
        storyGroup.groups[currentGroupIndex].slides[currentStoryIndex];
        final videoUrl = currentMedia.video ?? currentMedia.image;

        if (videoUrl != null) {
          _videoController =
              VideoPlayerController.networkUrl(Uri.parse(videoUrl));
          await _initializeVideoController(isNetworkFallback: true);
        }
      } else {
        // Both attempts failed
        setState(() {
          isLoading = false;
          hasError = true;
          isVideoReady = false;
        });
      }
    }
  }

  void _onVideoProgress() {
    if (!mounted || _videoController == null) return;

    if (_videoController!.value.isBuffering) {
      _progressTimer?.cancel();
      return;
    }

    final Duration position = _videoController!.value.position;
    final Duration duration = _videoController!.value.duration;
    final bool isNearEnd =
        position.inMilliseconds >= duration.inMilliseconds - 100;

    if (isNearEnd && !isCompletingStory) {
      isCompletingStory = true;
      _onStoryComplete();
    } else if (!isNearEnd) {
      isCompletingStory = false;
    }
  }

  void _startProgressTimer(Duration duration) {
    if (isLoading || hasError) return;

    _progressTimer?.cancel();

    const interval = Duration(milliseconds: 50);
    final step = interval.inMilliseconds / duration.inMilliseconds;

    _progressTimer = Timer.periodic(interval, (timer) {
      if (!mounted) return;

      if (currentMediaType == MediaType.video) {
        if (_videoController == null ||
            !_videoController!.value.isInitialized) {
          return;
        }

        videoAspectRatio = _videoController!.value.aspectRatio;

        if (_videoController!.value.isBuffering ||
            !_videoController!.value.isPlaying) {
          return;
        }
      }

      setState(() {
        if (percentWatched + step < 1) {
          percentWatched += step;
        } else {
          _onStoryComplete();
        }
      });
    });
  }

  void _onStoryComplete() {
    _progressTimer?.cancel();

    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.pause();
    }

    setState(() {
      percentWatched = 0;
    });

    Future.delayed(const Duration(milliseconds: 10), () {
      if (!mounted) return;

      if (currentStoryIndex <
          storyGroup.groups[currentGroupIndex].slides.length - 1) {
        setState(() {
          currentStoryIndex++;
        });
        _startWatching();
      } else if (currentGroupIndex > 0) {
        setState(() {
          currentGroupIndex--;
          currentStoryIndex = 0;
        });
        _startWatching();
      } else {
        Navigator.pop(context);
      }
    });
  }

  void _onTapDown(TapDownDetails details) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dx = details.globalPosition.dx;

    if (dx < screenWidth / 3) {
      if (currentStoryIndex > 0) {
        _progressTimer?.cancel();
        if (_videoController != null) {
          _videoController!.pause();
          _videoController!.dispose();
          _videoController = null;
        }
        setState(() {
          currentStoryIndex--;
        });
        _startWatching();
      } else if (currentGroupIndex < storyGroup.groups.length - 1) {
        _progressTimer?.cancel();
        if (_videoController != null) {
          _videoController!.pause();
          _videoController!.dispose();
          _videoController = null;
        }
        setState(() {
          currentGroupIndex++;
          currentStoryIndex = 0;
        });
        _startWatching();
      }
    } else if (dx > screenWidth / 1.5) {
      if (currentStoryIndex <
          storyGroup.groups[currentGroupIndex].slides.length - 1) {
        _progressTimer?.cancel();
        if (_videoController != null) {
          _videoController!.pause();
          _videoController!.dispose();
          _videoController = null;
        }
        setState(() {
          currentStoryIndex++;
        });
        _startWatching();
      } else if (currentGroupIndex > 0) {
        _progressTimer?.cancel();
        if (_videoController != null) {
          _videoController!.pause();
          _videoController!.dispose();
          _videoController = null;
        }
        setState(() {
          currentGroupIndex--;
          currentStoryIndex = 0;
        });
        _startWatching();
      } else {
        setState(() {
          percentWatched = 1;
        });
      }
    } else {
      if (currentMediaType == MediaType.video &&
          isVideoReady &&
          _videoController != null) {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
          _progressTimer?.cancel();
        } else {
          _videoController!.play();
          _startProgressTimer(_videoController!.value.duration);
        }
      } else if (currentMediaType == MediaType.lottie ||
          currentMediaType == MediaType.gif ||
          currentMediaType == MediaType.image) {
        if (_progressTimer?.isActive ?? false) {
          _progressTimer?.cancel();
        } else {
          final slideShowTime =
              storyGroup.groups[currentGroupIndex].styling?['slideShowTime'] ??
                  5;
          _startProgressTimer(Duration(seconds: slideShowTime));
        }
      }
    }
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _dragStartY = details.globalPosition.dy;
      _dragDistance = 0;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDistance = details.globalPosition.dy - _dragStartY;
      if (_dragDistance < 0) {
        _dragDistance = 0;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragDistance > _dismissThreshold) {
      _progressTimer?.cancel();
      if (_videoController != null) {
        _videoController!.pause();
        _videoController!.dispose();
        _videoController = null;
      }
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragDistance = 0;
      });
    }
  }

  void _toggleSound() {
    setState(() {
      isSoundMuted = !isSoundMuted;
      if (_videoController != null && _videoController!.value.isInitialized) {
        _videoController!.setVolume(isSoundMuted ? 0.0 : 1.0);
      }
    });
  }

  void _shareStory() async {
    final slide =
    storyGroup.groups[currentGroupIndex].slides[currentStoryIndex];
    if (slide.link != null && slide.link!.isNotEmpty) {
      await Share.share(slide.link!);

      widget.appStorys?.trackEvent(
        event: 'shared',
        campaignId: widget.storyCampaignId,
        metadata: {
          'story_slide': slide.id,
        },
      );
    }
  }

  Widget _buildHeaderThumbnail(
      String thumbnail, double size, double cornerRadius) {
    if (_isLottieThumbnail(thumbnail)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius),
        child: Container(
          height: size,
          width: size,
          color: Colors.transparent,
          child: Center(
            child: Lottie.network(
              thumbnail,
              fit: BoxFit.contain,
              repeat: true,
              animate: true,
              width: size * 0.85,
              height: size * 0.85,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.animation_outlined,
                  color: Colors.white30,
                );
              },
            ),
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius),
        child: Image.network(
          fit: BoxFit.cover,
          height: size,
          width: size,
          thumbnail,
          errorBuilder: (context, url, error) {
            return Container(
              color: Colors.grey[700],
              child: Icon(
                Icons.image_outlined,
                color: Colors.white30,
                size: size * 0.5,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = storyGroup.groups[currentGroupIndex];
    final slide = detail.slides[currentStoryIndex];
    final groupStyling = detail.styling;

    final bool showCta = slide.link != null &&
        slide.link!.isNotEmpty &&
        slide.buttonText != null &&
        slide.buttonText!.isNotEmpty;

    final cornerRadius =
    (groupStyling?['cornerRadius']?['topLeft'] ?? 8).toDouble();

    return GestureDetector(
      onTapDown: (details) => _onTapDown(details),
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      onLongPress: () {
        if (currentMediaType == MediaType.video &&
            isVideoReady &&
            _videoController != null) {
          _videoController!.pause();
          _progressTimer?.cancel();
        } else {
          _progressTimer?.cancel();
        }
      },
      onLongPressEnd: (details) {
        if (currentMediaType == MediaType.video &&
            isVideoReady &&
            _videoController != null) {
          _videoController!.play();
          _startProgressTimer(_videoController!.value.duration);
        } else {
          final slideShowTime = groupStyling?['slideShowTime'] ?? 5;
          _startProgressTimer(Duration(seconds: slideShowTime));
        }
      },
      child: Scaffold(
        body: Container(
          color: Colors.black,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.02,
          ),
          child: Stack(
            children: [
              SafeArea(
                child: Scaffold(
                  backgroundColor: Colors.black,
                  body: Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height * 0.075,
                        ),
                        height: double.infinity,
                        width: double.infinity,
                        child: isLoading
                            ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                            : hasError
                            ? const Center(
                          child: Text(
                            'An Error Occurred',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        )
                            : _buildMediaContent(),
                      ),
                      // Header with thumbnail and name
                      Positioned(
                        top: 22,
                        left: 20,
                        right: 20,
                        child: Row(
                          children: [
                            // Thumbnail - NOW WITH FIXED LOTTIE SUPPORT
                            _buildHeaderThumbnail(
                              detail.thumbnail,
                              40,
                              cornerRadius,
                            ),
                            const SizedBox(width: 10),
                            // Story name
                            if (detail.name != null && detail.name!.isNotEmpty)
                              Expanded(
                                child: Text(
                                  detail.name ?? "",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Share button (positioned with JSON margin)
                      if (groupStyling?['share']?['enabled'] == true)
                        Positioned(
                          top: _getDoubleValue(
                              groupStyling?['share']?['margin']?['top'],
                              10) +
                              10,
                          right: _getDoubleValue(
                              groupStyling?['share']?['margin']?['right'], 75),
                          child: ShareButton(
                            onTap: _shareStory,
                            styling: groupStyling?['share'],
                            iconSize: _getDoubleValue(
                                groupStyling?['share']?['size'], 24),
                          ),
                        ),

                      if (currentMediaType == MediaType.video &&
                          groupStyling?['soundToggle']?['enabled'] == true)
                        Positioned(
                          top: _getDoubleValue(
                              groupStyling?['soundToggle']?['mute']
                              ?['margin']?['top'],
                              10) +
                              10,
                          right: _getDoubleValue(
                              groupStyling?['soundToggle']?['mute']?['margin']
                              ?['right'],
                              40),
                          child: isSoundMuted
                              ? MuteButton(
                            onTap: _toggleSound,
                            styling: groupStyling?['soundToggle']
                            ?['mute'],
                            iconSize: _getDoubleValue(
                                groupStyling?['soundToggle']?['mute']
                                ?['size'],
                                24),
                          )
                              : UnmuteButton(
                            onTap: _toggleSound,
                            styling: groupStyling?['soundToggle']
                            ?['unmute'],
                            iconSize: _getDoubleValue(
                                groupStyling?['soundToggle']?['unmute']
                                ?['size'],
                                24),
                          ),
                        ),
                      // Cross button (positioned with JSON margin)
                      Positioned(
                        top: _getDoubleValue(
                            groupStyling?['crossButton']?['margin']?['top'],
                            0) +
                            10,
                        right: _getDoubleValue(
                            groupStyling?['crossButton']?['margin']?['right'],
                            0),
                        child: CrossButton(
                          onTap: () => Navigator.of(context).pop(),
                          styling: groupStyling?['crossButton'],
                          iconSize: _getDoubleValue(
                              groupStyling?['crossButton']?['size'], 0),
                        ),
                      ),
                      // CTA Button
                      if (showCta)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: CtaButton(
                            text: slide.buttonText!,
                            onTap: () async {
                              widget.appStorys?.trackEvent(
                                event: 'clicked',
                                campaignId: widget.storyCampaignId,
                                metadata: {
                                  'story_slide': slide.id,
                                },
                              );
                              LinkHandler.handle(slide.link, widget.onLinkTap);
                            },
                            styling: slide.styling?['cta'],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Progress bar
              StoriesBar(
                percentWatched: percentWatched,
                currentIndex: currentStoryIndex,
                totalStories: detail.slides.length,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getDoubleValue(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  Widget _buildMediaContent() {
    final currentSlide =
    storyGroup.groups[currentGroupIndex].slides[currentStoryIndex];

    switch (currentMediaType) {
      case MediaType.video:
        if (_videoController != null && _videoController!.value.isInitialized) {
          return FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          );
        }
        return const SizedBox.shrink();

      case MediaType.lottie:
        if (currentSlide.image != null && currentSlide.image!.isNotEmpty) {
          return Center(
            child: Lottie.network(
              currentSlide.image!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text(
                    'Failed to load animation',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();

      case MediaType.gif:
        if (currentSlide.image != null && currentSlide.image!.isNotEmpty) {
          return Center(
            child: Image.network(
              currentSlide.image!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text(
                    'Failed to load GIF',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();

      case MediaType.image:
        if (currentSlide.image != null && currentSlide.image!.isNotEmpty) {
          return CachedNetworkImage(
            fit: BoxFit.contain,
            imageUrl: currentSlide.image!,
            errorWidget: (context, url, error) {
              return const Center(
                child: Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
    }
  }
}