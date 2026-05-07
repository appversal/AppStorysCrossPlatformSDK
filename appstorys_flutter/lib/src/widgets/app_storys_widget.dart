import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../../appstorys_flutter.dart';

// =============================================================================
// PUBLIC WIDGET
// =============================================================================

class AppStorysWidget extends StatefulWidget {
  /// AppstorysFlutter SDK instance — stream subscription + event tracking.
  final AppstorysFlutter appStorys;

  /// Position slot this widget occupies (e.g. "home_top").
  /// Pass null to match any campaign that has no position constraint.
  final String? position;

  /// Called with the campaign link when a banner image is tapped.
  /// Navigation is the host app's responsibility — the SDK only tracks the event.
  final void Function(String link)? onTap;

  /// Colour of the active pagination dot. Defaults to black.
  final Color dotSelectedColor;

  /// Colour of inactive pagination dots. Defaults to grey.
  final Color dotUnselectedColor;

  /// How long each slide is shown before auto-advancing. Defaults to 5 s.
  final Duration autoScrollInterval;

  const AppStorysWidget({
    super.key,
    required this.appStorys,
    this.position,
    this.onTap,
    this.dotSelectedColor = Colors.black,
    this.dotUnselectedColor = Colors.grey,
    this.autoScrollInterval = const Duration(seconds: 5),
  });

  @override
  State<AppStorysWidget> createState() => _AppStorysWidgetState();
}

// =============================================================================
// STATE — stream subscription · parsing · height calculation · event tracking
// =============================================================================

class _AppStorysWidgetState extends State<AppStorysWidget>
    with CampaignsStreamMixin {
  WidgetCampaign? _campaign;
  bool _isLoading = true;

  /// widget_image IDs that have already fired a "viewed" event this session.
  /// Cleared when the campaign changes so re-appearing images re-track.
  final Set<String> _impressions = {};

  @override
  void initState() {
    super.initState();
    subscribeToCampaigns(
      widget.appStorys.campaignsStream,
      _onCampaignsUpdate,
      onError: () {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  // ── Parsing ──────────────────────────────────────────────────────────────────

  void _onCampaignsUpdate(String json) {
    final campaign = _parse(json);
    if (!mounted) return;
    setState(() {
      if (campaign?.id != _campaign?.id) _impressions.clear();
      _campaign = campaign;
      _isLoading = false;
    });
  }

  WidgetCampaign? _parse(String json) {
    try {
      final all = jsonDecode(json) as List<dynamic>;

      // Collect all WID campaigns then find the one matching our position.
      // Follows Kotlin: exact position match only — no null-position fallback
      // when a specific position is requested.
      final match = all
          .whereType<Map>()
          .where((c) => c['campaign_type'] == 'WID')
          .map((c) => Map<String, dynamic>.from(c))
          .where((c) => c['position'] == widget.position)
          .firstOrNull;

      return match != null ? WidgetCampaign.fromJson(match) : null;
    } catch (_) {
      return null;
    }
  }

  // ── Height calculation (mirrors Kotlin exactly) ───────────────────────────
  //
  // Full widget (Kotlin FullWidget):
  //   height = availableWidth × (h / w)          when both dimensions given
  //   height = h                                  when only height given
  //
  // Half widget (Kotlin DoubleWidget):
  //   height = (availableWidth − gap) × (h / w) ÷ 2   when both given
  //   height = (h − gap) ÷ 2                           when only height given

  double? _fullHeight(double screenWidth) {
    final d = _campaign!.details;
    final available = screenWidth - d.styling.leftMargin - d.styling.rightMargin;
    if (d.width != null && d.height != null && d.width! > 0) {
      return available * (d.height! / d.width!);
    }
    return d.height;
  }

  double? _halfHeight(double screenWidth) {
    final d = _campaign!.details;
    final gap = d.styling.gapBetweenImages;
    final available = screenWidth - d.styling.leftMargin - d.styling.rightMargin;
    if (d.width != null && d.height != null && d.width! > 0) {
      return (available - gap) * (d.height! / d.width!) / 2;
    }
    return d.height != null ? (d.height! - gap) / 2 : null;
  }

  // ── Event tracking ────────────────────────────────────────────────────────

  void _trackImpression(String imageId) {
    if (_impressions.contains(imageId) || _campaign == null) return;
    _impressions.add(imageId);
    widget.appStorys
        .trackEvent(
          event: 'viewed',
          campaignId: _campaign!.id,
          metadata: {'widget_image': imageId},
        )
        .catchError((_) {});
  }

  void _handleTap(String? link, String imageId) {
    if (link == null || link.isEmpty || _campaign == null) return;
    widget.appStorys
        .trackEvent(
          event: 'clicked',
          campaignId: _campaign!.id,
          metadata: {'widget_image': imageId},
        )
        .catchError((_) {});
    widget.onTap?.call(link);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _campaign == null) return const SizedBox.shrink();

    final details = _campaign!.details;
    final images = details.sortedImages;
    if (images.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final styling = details.styling;

    Widget body;
    switch (details.type) {
      case 'full':
        body = _FullWidgetView(
          images: images,
          styling: styling,
          height: _fullHeight(screenWidth),
          dotSelectedColor: widget.dotSelectedColor,
          dotUnselectedColor: widget.dotUnselectedColor,
          autoScrollInterval: widget.autoScrollInterval,
          onImpression: _trackImpression,
          onTap: _handleTap,
        );
      case 'half':
        body = _HalfWidgetView(
          images: images,
          styling: styling,
          height: _halfHeight(screenWidth),
          dotSelectedColor: widget.dotSelectedColor,
          dotUnselectedColor: widget.dotUnselectedColor,
          autoScrollInterval: widget.autoScrollInterval,
          onImpression: _trackImpression,
          onTap: _handleTap,
        );
      default:
        return const SizedBox.shrink();
    }

    // Outer padding mirrors Kotlin's modifier.padding(top, bottom, start, end).
    return Padding(
      padding: EdgeInsets.only(
        top: styling.topMargin,
        bottom: styling.bottomMargin,
        left: styling.leftMargin,
        right: styling.rightMargin,
      ),
      child: body,
    );
  }
}

// =============================================================================
// FULL WIDGET VIEW
// Single full-width image per page. Manages page state + visibility tracking.
// =============================================================================

class _FullWidgetView extends StatefulWidget {
  final List<WidgetImage> images;
  final WidgetStyling styling;
  final double? height;
  final Color dotSelectedColor;
  final Color dotUnselectedColor;
  final Duration autoScrollInterval;
  final void Function(String imageId) onImpression;
  final void Function(String? link, String imageId) onTap;

  const _FullWidgetView({
    required this.images,
    required this.styling,
    required this.height,
    required this.dotSelectedColor,
    required this.dotUnselectedColor,
    required this.autoScrollInterval,
    required this.onImpression,
    required this.onTap,
  });

  @override
  State<_FullWidgetView> createState() => _FullWidgetViewState();
}

class _FullWidgetViewState extends State<_FullWidgetView> {
  int _currentPage = 0;
  bool _isVisible = false;

  void _onVisibilityChanged(bool visible) {
    _isVisible = visible;
    if (visible && widget.images.isNotEmpty) {
      widget.onImpression(widget.images[_currentPage].id);
    }
  }

  void _onPageChanged(int page) {
    _currentPage = page;
    // Only track if already visible — mirrors Kotlin LaunchedEffect(isVisible) guard.
    if (_isVisible) widget.onImpression(widget.images[page].id);
  }

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.only(
      topLeft: Radius.circular(widget.styling.topLeftRadius),
      topRight: Radius.circular(widget.styling.topRightRadius),
      bottomLeft: Radius.circular(widget.styling.bottomLeftRadius),
      bottomRight: Radius.circular(widget.styling.bottomRightRadius),
    );

    return _VisibilityDetector(
      onVisibilityChanged: _onVisibilityChanged,
      child: _AutoCarousel(
        itemCount: widget.images.length,
        height: widget.height,
        dotSelectedColor: widget.dotSelectedColor,
        dotUnselectedColor: widget.dotUnselectedColor,
        autoScrollInterval: widget.autoScrollInterval,
        onPageChanged: _onPageChanged,
        itemBuilder: (i) {
          final img = widget.images[i];
          return GestureDetector(
            onTap: () => widget.onTap(img.link, img.id),
            child: ClipRRect(
              borderRadius: br,
              child: _WidgetMedia(image: img),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// HALF WIDGET VIEW
// Two images side-by-side per page. Builds pairs, manages page + visibility.
// =============================================================================

class _HalfWidgetView extends StatefulWidget {
  final List<WidgetImage> images;
  final WidgetStyling styling;
  final double? height;
  final Color dotSelectedColor;
  final Color dotUnselectedColor;
  final Duration autoScrollInterval;
  final void Function(String imageId) onImpression;
  final void Function(String? link, String imageId) onTap;

  const _HalfWidgetView({
    required this.images,
    required this.styling,
    required this.height,
    required this.dotSelectedColor,
    required this.dotUnselectedColor,
    required this.autoScrollInterval,
    required this.onImpression,
    required this.onTap,
  });

  @override
  State<_HalfWidgetView> createState() => _HalfWidgetViewState();
}

class _HalfWidgetViewState extends State<_HalfWidgetView> {
  int _currentPage = 0;
  bool _isVisible = false;

  // Pair images: [[left, right?], [left, right?], ...]
  late final List<(WidgetImage, WidgetImage?)> _pairs;

  @override
  void initState() {
    super.initState();
    _pairs = _buildPairs(widget.images);
  }

  static List<(WidgetImage, WidgetImage?)> _buildPairs(List<WidgetImage> imgs) {
    final pairs = <(WidgetImage, WidgetImage?)>[];
    for (var i = 0; i < imgs.length; i += 2) {
      pairs.add((imgs[i], i + 1 < imgs.length ? imgs[i + 1] : null));
    }
    return pairs;
  }

  void _trackPairImpressions(int page) {
    if (page >= _pairs.length) return;
    final (left, right) = _pairs[page];
    widget.onImpression(left.id);
    if (right != null) widget.onImpression(right.id);
  }

  void _onVisibilityChanged(bool visible) {
    _isVisible = visible;
    if (visible) _trackPairImpressions(_currentPage);
  }

  void _onPageChanged(int page) {
    _currentPage = page;
    if (_isVisible) _trackPairImpressions(page);
  }

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.only(
      topLeft: Radius.circular(widget.styling.topLeftRadius),
      topRight: Radius.circular(widget.styling.topRightRadius),
      bottomLeft: Radius.circular(widget.styling.bottomLeftRadius),
      bottomRight: Radius.circular(widget.styling.bottomRightRadius),
    );
    final gap = widget.styling.gapBetweenImages;

    return _VisibilityDetector(
      onVisibilityChanged: _onVisibilityChanged,
      child: _AutoCarousel(
        itemCount: _pairs.length,
        height: widget.height,
        dotSelectedColor: widget.dotSelectedColor,
        dotUnselectedColor: widget.dotUnselectedColor,
        autoScrollInterval: widget.autoScrollInterval,
        onPageChanged: _onPageChanged,
        itemBuilder: (i) {
          final (left, right) = _pairs[i];
          return Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onTap(left.link, left.id),
                  child: ClipRRect(
                    borderRadius: br,
                    child: SizedBox(
                      height: widget.height,
                      child: _WidgetMedia(image: left),
                    ),
                  ),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: right != null
                    ? GestureDetector(
                        onTap: () => widget.onTap(right.link, right.id),
                        child: ClipRRect(
                          borderRadius: br,
                          child: SizedBox(
                            height: widget.height,
                            child: _WidgetMedia(image: right),
                          ),
                        ),
                      )
                    : const SizedBox.expand(),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// AUTO CAROUSEL
// PageView with auto-scroll timer + animated dot pagination.
// Pauses on touch, resumes on release — mirrors Kotlin's isDragged guard.
// =============================================================================

class _AutoCarousel extends StatefulWidget {
  final int itemCount;
  final Widget Function(int index) itemBuilder;
  final double? height;
  final Duration autoScrollInterval;
  final Color dotSelectedColor;
  final Color dotUnselectedColor;
  final void Function(int page)? onPageChanged;

  const _AutoCarousel({
    required this.itemCount,
    required this.itemBuilder,
    this.height,
    required this.autoScrollInterval,
    required this.dotSelectedColor,
    required this.dotUnselectedColor,
    this.onPageChanged,
  });

  @override
  State<_AutoCarousel> createState() => _AutoCarouselState();
}

class _AutoCarouselState extends State<_AutoCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _scheduleAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAutoScroll() {
    if (widget.itemCount <= 1) return;
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoScrollInterval, (_) {
      if (!_controller.hasClients) return;
      final next = (_currentPage + 1) % widget.itemCount;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Listener pauses/resumes auto-scroll on user touch — same as Kotlin's
        // isDragged guard on LaunchedEffect.
        SizedBox(
          height: widget.height ?? 200,
          child: Listener(
            onPointerDown: (_) => _timer?.cancel(),
            onPointerUp: (_) => _scheduleAutoScroll(),
            onPointerCancel: (_) => _scheduleAutoScroll(),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.itemCount,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
                widget.onPageChanged?.call(page);
              },
              itemBuilder: (_, i) => widget.itemBuilder(i),
            ),
          ),
        ),
        if (widget.itemCount > 1) ...[
          const SizedBox(height: 12),
          _DotsIndicator(
            count: widget.itemCount,
            current: _currentPage,
            selectedColor: widget.dotSelectedColor,
            unselectedColor: widget.dotUnselectedColor,
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// DOTS INDICATOR
// Animated pill dots — selected dot expands to 16 dp, unselected stays at 8 dp.
// Uses AnimatedContainer for smooth width + colour transitions (300 ms).
// Equivalent to Kotlin's PageIndicatorView with animateColorAsState + animateDpAsState.
// =============================================================================

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int current;
  final Color selectedColor;
  final Color unselectedColor;

  const _DotsIndicator({
    required this.count,
    required this.current,
    required this.selectedColor,
    required this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: i == current ? 16.0 : 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: i == current ? selectedColor : unselectedColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGET MEDIA
// Renders Lottie / GIF / static image in priority order.
// Mirrors Kotlin's CarousalImage / ImageCard when block.
// =============================================================================

class _WidgetMedia extends StatelessWidget {
  final WidgetImage image;

  const _WidgetMedia({required this.image});

  @override
  Widget build(BuildContext context) {
    // Priority: Lottie → image (GIF or static) → placeholder.
    if (isLottieUrl(image.lottieData)) {
      // Lottie placeholder — add the lottie package and replace when ready.
      return Container(color: Colors.grey[200]);
    }

    if (image.image?.isNotEmpty == true) {
      return Image.network(
        image.image!,
        fit: isGifUrl(image.image) ? BoxFit.contain : BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => Container(color: Colors.grey[200]),
      );
    }

    return Container(color: Colors.grey[200]);
  }
}

// =============================================================================
// VISIBILITY DETECTOR
// Fires onVisibilityChanged when ≥50% of the widget enters/leaves the viewport.
// Subscribes directly to every ancestor ScrollPosition so it works without any
// NotificationListener or ScrollController in the host page — same approach as
// the Kotlin onGloballyPositioned + boundsInWindow check.
// =============================================================================

class _VisibilityDetector extends StatefulWidget {
  final Widget child;
  final void Function(bool visible) onVisibilityChanged;

  const _VisibilityDetector({
    required this.child,
    required this.onVisibilityChanged,
  });

  @override
  State<_VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<_VisibilityDetector> {
  final _key = GlobalKey();
  bool _isVisible = false;
  final List<ScrollPosition> _positions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attach();
      _check();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-attach when widget moves (TabView, Navigator push, etc.).
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _attach() {
    if (!mounted) return;
    _detach();
    // Walk every ancestor Scrollable and listen to its ScrollPosition.
    ScrollableState? s = Scrollable.maybeOf(context);
    while (s != null) {
      final p = s.position;
      if (!_positions.contains(p)) {
        _positions.add(p);
        p.addListener(_check);
      }
      s = Scrollable.maybeOf(s.context);
    }
  }

  void _detach() {
    for (final p in _positions) { p.removeListener(_check); }
    _positions.clear();
  }

  void _check() {
    if (!mounted) return;
    final ctx = _key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screenH = MediaQuery.of(ctx).size.height;

    // Clamp visible region to screen bounds.
    final visTop = offset.dy.clamp(0.0, screenH);
    final visBottom = (offset.dy + size.height).clamp(0.0, screenH);
    final ratio = size.height > 0 ? (visBottom - visTop) / size.height : 0.0;
    final visible = ratio >= 0.5;

    if (visible != _isVisible) {
      _isVisible = visible;
      widget.onVisibilityChanged(visible);
    }
  }

  @override
  Widget build(BuildContext context) {
    // KeyedSubtree gives _key a stable context without adding a layout node.
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
