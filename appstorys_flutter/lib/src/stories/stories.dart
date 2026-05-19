import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../appstorys_flutter.dart';
import '../models/stories_models.dart';
import '../utils/campaigns_stream_mixin.dart';
import 'story_screen.dart';

class Stories extends StatefulWidget {
  final List<dynamic> campaigns;
  final AppstorysFlutter? appStorys;
  final void Function(String link)? onLinkTap;

  const Stories({
    super.key,
    required this.campaigns,
    this.appStorys,
    this.onLinkTap,
  });

  @override
  State<Stories> createState() => _StoriesState();
}

/// Stream-driven wrapper used by the root overlay to mount stories from the
/// campaigns stream, matching the same pattern used by other campaign types.
class AppStorysStories extends StatefulWidget {
  final AppstorysFlutter appStorys;
  final void Function(String link)? onLinkTap;

  const AppStorysStories({
    super.key,
    required this.appStorys,
    this.onLinkTap,
  });

  @override
  State<AppStorysStories> createState() => _AppStorysStoriesState();
}

class _AppStorysStoriesState extends State<AppStorysStories>
    with CampaignsStreamMixin {
  List<dynamic> _campaigns = const [];
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    subscribeToCampaigns(widget.appStorys.campaignsStream, _handleCampaigns);
  }

  @override
  void didUpdateWidget(covariant AppStorysStories oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appStorys != widget.appStorys) {
      subscribeToCampaigns(widget.appStorys.campaignsStream, _handleCampaigns);
    }
  }

  void _handleCampaigns(String json) {
    final campaign = _parseStories(json);
    if (!mounted) return;

    setState(() {
      _campaigns = campaign == null ? const [] : [campaign];
      _visible = _campaigns.isNotEmpty;
    });
  }

  Map<String, dynamic>? _parseStories(String json) {
    try {
      final data = jsonDecode(json) as List<dynamic>;
      final raw = data.whereType<Map>().firstWhere(
            (c) => c['campaign_type'] == 'STR',
        orElse: () => {},
      );
      if (raw.isEmpty) return null;
      return _normalize(raw);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _normalize(Map raw) {
    final details = raw['details'];
    return {
      ...Map<String, dynamic>.from(raw),
      'id': (raw['id'] ?? '').toString(),
      'details': details is List
          ? details
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : e)
          .toList()
          : details is Map
          ? Map<String, dynamic>.from(details)
          : details,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _campaigns.isEmpty) return const SizedBox.shrink();

    return Stories(
      campaigns: _campaigns,
      appStorys: widget.appStorys,
      onLinkTap: widget.onLinkTap,
    );
  }
}



class _StoriesState extends State<Stories> {
  CampaignStory? currentStory;
  Set<String> viewedSlides = {};
  late SharedPreferences prefs;
  final String storageKey = 'VIEWED_STORY_SLIDES';

  @override
  void initState() {
    super.initState();
    _initializeStorage();
  }

  @override
  void didUpdateWidget(Stories oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasEmpty = oldWidget.campaigns.isEmpty;
    final isNowNonEmpty = widget.campaigns.isNotEmpty;
    if (wasEmpty && isNowNonEmpty && currentStory == null) {
      _loadStoryData();
    }
  }

  Future<void> _initializeStorage() async {
    prefs = await SharedPreferences.getInstance();
    await _loadViewedStories();
    _loadStoryData();
  }

  Future<void> _loadViewedStories() async {
    final storedStories = prefs.getStringList(storageKey);

    debugPrint('=== LOADING VIEWED STORIES ===');
    debugPrint('Stored stories from SharedPreferences: $storedStories');

    if (storedStories != null && storedStories.isNotEmpty) {
      setState(() {
        viewedSlides = Set<String>.from(storedStories);
      });
      debugPrint(
          'Loaded ${viewedSlides.length} viewed slides: $viewedSlides');
    } else {
      debugPrint('No viewed stories found. Starting fresh with empty set.');
      setState(() {
        viewedSlides = {};
      });
    }
  }

  Future<void> _saveViewedStories() async {
    await prefs.setStringList(storageKey, viewedSlides.toList());
    debugPrint(
        'Saved ${viewedSlides.length} viewed slides to storage: $viewedSlides');
  }

  void _loadStoryData() {
    try {
      if (widget.campaigns.isNotEmpty) {
        final rawCampaign = widget.campaigns.firstWhere(
          (c) => c is Map && c['campaign_type'] == 'STR',
          orElse: () => widget.campaigns.first,
        );
        final campaign = Map<String, dynamic>.from(rawCampaign as Map);
        currentStory = CampaignStory.fromCampaignMap(campaign);

        debugPrint('=== LOADED STORY DATA ===');
        debugPrint('Total stories loaded: ${currentStory?.groups.length}');
        for (var detail in currentStory?.groups ?? []) {
          debugPrint('Story: ${detail.name} (ID: ${detail.id})');
        }

        _sortStories();
      }
    } catch (e) {
      debugPrint('Error loading banner: $e');
    }
  }

  void _sortStories() {
    if (currentStory != null) {
      currentStory!.groups.sort((a, b) {
        final aViewed = _isGroupViewed(a);
        final bViewed = _isGroupViewed(b);

        debugPrint(
            'Sorting: ${a.name} (viewed: $aViewed) vs ${b.name} (viewed: $bViewed)');

        if (aViewed == bViewed) return a.order.compareTo(b.order);
        return aViewed ? 1 : -1;
      });

      debugPrint('=== SORTED STORIES ===');
      for (var detail in currentStory!.groups) {
        final isViewed = _isGroupViewed(detail);
        debugPrint('${detail.name} - Viewed: $isViewed');
      }
    }
  }

  bool _isGroupViewed(StoryGroupModel group) {
    final slides = group.slides;
    if (slides.isEmpty) return false;
    return slides.every((slide) => viewedSlides.contains(slide.id));
  }

  Future<void> _handleStoryTap(int index) async {
    final story = currentStory!.groups[index];
    final storyId = story.id;

    debugPrint('=== STORY TAPPED ===');
    debugPrint('Story: ${story.name} (ID: $storyId)');
    debugPrint('Was viewed before: ${_isGroupViewed(story)}');

    await showGeneralDialog(
      barrierLabel: "Label",
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      context: context,
      pageBuilder: (context, anim1, anim2) {
        return StoryScreen(
          storyCampaignId: currentStory!.id,
          storyGroup: currentStory!,
          groupIndex: index,
          appStorys: widget.appStorys,
          onLinkTap: widget.onLinkTap,
          onSlideViewed: (slideId) {
            if (slideId.trim().isEmpty) return;
            if (viewedSlides.add(slideId)) {
              _saveViewedStories();
            }
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
              .animate(anim1),
          child: child,
        );
      },
    );

    debugPrint('=== DIALOG CLOSED ===');
    debugPrint('Marking story as viewed: ${story.name}');

    setState(() {
      for (final slide in story.slides) {
        viewedSlides.add(slide.id);
      }
      debugPrint('Current viewed slides: $viewedSlides');
    });

    await _saveViewedStories();
    _sortStories();
    setState(() {});

    debugPrint(
        'Story ${story.name} marked as viewed. Total viewed slides: ${viewedSlides.length}');
  }

  bool _isLottieThumbnail(String thumbnail) {
    return thumbnail.toLowerCase().endsWith('.json');
  }

  Widget _buildThumbnail(
      String thumbnail,
      double size,
      BorderRadius borderRadius,
      bool isViewed,
      ) {
    final isLottie = _isLottieThumbnail(thumbnail);

    if (isLottie) {
      return _buildLottieThumbnail(thumbnail, size, borderRadius, isViewed);
    } else {
      return _buildImageThumbnail(thumbnail, size, borderRadius, isViewed);
    }
  }

  /// BUILD LOTTIE - FIXED VERSION ✅
  /// Use BoxFit.contain instead of cover to show complete animation
  Widget _buildLottieThumbnail(
      String thumbnail,
      double size,
      BorderRadius borderRadius,
      bool isViewed,
      ) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        height: size,
        width: size,
        color: Colors.grey[200],
        child: AnimatedOpacity(
          opacity: isViewed ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Center(
            child: Lottie.network(
              thumbnail,
              fit: BoxFit.contain, // ✅ Changed from cover to contain
              repeat: true, // ✅ Auto-repeat animation
              reverse: false,
              animate: true,
              width: size * 0.85, // ✅ 85% of available space
              height: size * 0.85,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading Lottie: $error');
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(
                      Icons.animation_outlined,
                      color: Colors.grey[600],
                      size: size * 0.4,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(
      String thumbnail,
      double size,
      BorderRadius borderRadius,
      bool isViewed,
      ) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: AnimatedOpacity(
        opacity: isViewed ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Image.network(
          fit: BoxFit.cover,
          thumbnail,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading image: $error');
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey[600],
                  size: size * 0.4,
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color hexToColor(String hexCode) {
      final hexString = hexCode.replaceAll('#', '');
      return Color(int.parse('FF$hexString', radix: 16));
    }

    if (currentStory?.id == null) {
      debugPrint('Current story is null');
      return Container();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(currentStory?.groups.length ?? 0, (index) {
            final story = currentStory!.groups[index];
            final isViewed = _isGroupViewed(story);

            debugPrint(
                'Building story: ${story.name}, isViewed: $isViewed, thumbnail: ${story.thumbnail}');

            final storySize =
                double.tryParse(story.styling?['size']?.toString() ?? '70') ??
                    70;

            final ringWidth = double.tryParse(
                story.styling?['ringWidth']?.toString() ?? '3') ??
                3;

            final nameFontSize = double.tryParse(
                story.styling?['name']?['size']?.toString() ?? '12') ??
                12;

            final cornerRadiusData = story.styling?['cornerRadius'];
            final topLeft = double.tryParse(
                cornerRadiusData?['topLeft']?.toString() ?? '55') ??
                55;
            final topRight = double.tryParse(
                cornerRadiusData?['topRight']?.toString() ?? '30') ??
                30;
            final bottomLeft = double.tryParse(
                cornerRadiusData?['bottomLeft']?.toString() ?? '30') ??
                30;
            final bottomRight = double.tryParse(
                cornerRadiusData?['bottomRight']?.toString() ?? '30') ??
                30;

            final ringColor = hexToColor(story.ringColor);
            final nameColor = hexToColor(story.nameColor);

            final displayRingColor =
            isViewed ? Colors.grey[400] ?? Colors.grey : ringColor;
            final displayNameColor =
            isViewed ? Colors.grey[600] ?? Colors.grey : nameColor;

            debugPrint(
                'Story ${story.name}: ringColor=$ringColor, displayRingColor=$displayRingColor, isViewed=$isViewed');

            final thumbnailBorderRadius = BorderRadius.only(
              topLeft: Radius.circular(topLeft > 6 ? topLeft - 6 : 0),
              topRight: Radius.circular(topRight > 6 ? topRight - 6 : 0),
              bottomLeft: Radius.circular(bottomLeft > 6 ? bottomLeft - 6 : 0),
              bottomRight:
              Radius.circular(bottomRight > 6 ? bottomRight - 6 : 0),
            );

            return GestureDetector(
              onTap: () => _handleStoryTap(index),
              child: Container(
                width: storySize,
                margin: const EdgeInsets.only(
                  left: 6,
                  right: 6,
                  top: 0,
                  bottom: 0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          height: storySize,
                          width: storySize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(topLeft),
                              topRight: Radius.circular(topRight),
                              bottomLeft: Radius.circular(bottomLeft),
                              bottomRight: Radius.circular(bottomRight),
                            ),
                            border: Border.all(
                              color: displayRingColor,
                              width: ringWidth,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(6),
                          height: storySize - 12,
                          width: storySize - 12,
                          child: _buildThumbnail(
                            story.thumbnail,
                            storySize - 12,
                            thumbnailBorderRadius,
                            isViewed,
                          ),
                        ),
                      ],
                    ),
                    if (story.name != null && story.name!.isNotEmpty)
                      const SizedBox(height: 6),
                    if (story.name != null && story.name!.isNotEmpty)
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        style: TextStyle(
                          color: displayNameColor,
                          fontSize: nameFontSize,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                        child: Text(
                          story.name ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

