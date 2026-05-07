// Pure data models for the WID (Widget) campaign type.
// No Flutter imports — data only.

// ── STYLING ──────────────────────────────────────────────────────────────────

class WidgetStyling {
  final double topMargin;
  final double bottomMargin;
  final double leftMargin;
  final double rightMargin;
  final double topLeftRadius;
  final double topRightRadius;
  final double bottomLeftRadius;
  final double bottomRightRadius;
  // Gap between the two images in a "half" layout. Defaults to 12.
  final double gapBetweenImages;

  const WidgetStyling({
    this.topMargin = 0,
    this.bottomMargin = 0,
    this.leftMargin = 0,
    this.rightMargin = 0,
    this.topLeftRadius = 0,
    this.topRightRadius = 0,
    this.bottomLeftRadius = 0,
    this.bottomRightRadius = 0,
    this.gapBetweenImages = 12,
  });

  factory WidgetStyling.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WidgetStyling();
    // KMP may serialize numeric fields as String — _v handles both.
    double v(String key, {double def = 0}) {
      final val = json[key];
      if (val == null) return def;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    return WidgetStyling(
      topMargin: v('topMargin'),
      bottomMargin: v('bottomMargin'),
      leftMargin: v('leftMargin'),
      rightMargin: v('rightMargin'),
      topLeftRadius: v('topLeftRadius'),
      topRightRadius: v('topRightRadius'),
      bottomLeftRadius: v('bottomLeftRadius'),
      bottomRightRadius: v('bottomRightRadius'),
      gapBetweenImages: v('gapBetweenImages', def: 12),
    );
  }
}

// ── INDIVIDUAL IMAGE ──────────────────────────────────────────────────────────

class WidgetImage {
  final String id;
  final String? image;
  final String? lottieData;
  final String? link;
  final int order;

  const WidgetImage({
    required this.id,
    this.image,
    this.lottieData,
    this.link,
    required this.order,
  });

  factory WidgetImage.fromJson(Map<String, dynamic> json) {
    // Kotlin serializes link as JsonElement? — can be a JSON string, a Map/object,
    // or null. The Kotlin Widget() composable does .toString().removeSurrounding("\"")
    // to strip the surrounding quotes from a serialized JsonString. We mirror that.
    final rawLink = json['link'];
    String? link;
    if (rawLink is String) {
      final trimmed = rawLink.trim();
      link = trimmed.isNotEmpty ? trimmed : null;
    } else if (rawLink is Map) {
      // JsonObject serialized as map — try common URL keys
      final val = rawLink['url'] ?? rawLink['web'] ?? rawLink['href'];
      link = val?.toString().trim().isNotEmpty == true ? val.toString().trim() : null;
    } else if (rawLink != null) {
      final s = rawLink.toString().trim();
      link = s.isNotEmpty ? s : null;
    }

    return WidgetImage(
      id: (json['id'] as String?) ?? '',
      image: json['image'] as String?,
      lottieData: json['lottie_data'] as String?,
      link: link,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isLottie => lottieData != null && lottieData!.isNotEmpty;
  bool get hasMedia => (image?.isNotEmpty ?? false) || isLottie;
}

// ── CAMPAIGN DETAILS ──────────────────────────────────────────────────────────

class WidgetDetails {
  final String id;
  // "full" = single full-width carousel | "half" = side-by-side pairs carousel
  final String type;
  // Source dimensions used for aspect-ratio height calculation.
  // When both are present: height = availableWidth × (height/width).
  // When only height is present: height is used directly.
  final double? width;
  final double? height;
  final WidgetStyling styling;
  final List<WidgetImage> widgetImages;

  const WidgetDetails({
    required this.id,
    required this.type,
    this.width,
    this.height,
    required this.styling,
    required this.widgetImages,
  });

  factory WidgetDetails.fromJson(Map<String, dynamic> json) {
    double? parseNum(String key) => (json[key] as num?)?.toDouble();

    return WidgetDetails(
      id: (json['id'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'full',
      width: parseNum('width'),
      height: parseNum('height'),
      styling: WidgetStyling.fromJson(
        json['styling'] is Map
            ? Map<String, dynamic>.from(json['styling'] as Map)
            : null,
      ),
      widgetImages: (json['widget_images'] as List?)
              ?.whereType<Map>()
              .map((e) => WidgetImage.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  // Images sorted by their order field — always use this in the UI, never raw widgetImages.
  List<WidgetImage> get sortedImages =>
      [...widgetImages]..sort((a, b) => a.order.compareTo(b.order));
}

// ── TOP-LEVEL CAMPAIGN ────────────────────────────────────────────────────────

class WidgetCampaign {
  final String id;
  // Matches the position slot registered by the host app (e.g. "home_top").
  // null means the campaign has no position constraint.
  final String? position;
  final WidgetDetails details;

  const WidgetCampaign({
    required this.id,
    this.position,
    required this.details,
  });

  // Receives the raw campaign envelope from the campaigns stream.
  // 'details' is the nested object; 'id' and 'position' live at the top level.
  factory WidgetCampaign.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'];
    final details = rawDetails is Map
        ? Map<String, dynamic>.from(rawDetails)
        : json;

    return WidgetCampaign(
      id: (json['id'] ?? '').toString(),
      position: json['position'] as String?,
      details: WidgetDetails.fromJson(details),
    );
  }
}
