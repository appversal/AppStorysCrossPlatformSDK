// Models for CSAT campaign type.
// Field names and structure mirror CsatModels.kt in shared-core.

// ── Helpers ───────────────────────────────────────────────────────────────────

double? _toDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

// ── Top-level Campaign ────────────────────────────────────────────────────────

class CsatCampaign {
  final String id;
  final String campaignType;
  final CsatDetails details;

  CsatCampaign({
    required this.id,
    required this.campaignType,
    required this.details,
  });

  factory CsatCampaign.fromJson(Map<String, dynamic> json) {
    final id = (json['campaign_id'] ?? json['id'] ?? '').toString();
    final rawDetails = json['details'];
    final detailsMap = rawDetails is Map
        ? Map<String, dynamic>.from(rawDetails)
        : <String, dynamic>{};
    return CsatCampaign(
      id: id,
      campaignType: json['campaign_type'] as String? ?? 'CSAT',
      details: CsatDetails.fromJson(detailsMap, fallbackId: id),
    );
  }
}

// ── CSAT Details ──────────────────────────────────────────────────────────────

class CsatDetails {
  final String id;
  final String title;
  final num? height;
  final num? width;
  final String? thankyouImage;
  final String thankyouText;
  final String thankyouDescription;
  final String highStarText;
  final String lowStarText;
  final String descriptionText;

  /// Ordered key → display label, preserves insertion order.
  final Map<String, String> feedbackOptions;

  final String link;
  final CsatStyling styling;

  /// Raw JSON map — passed to the Flutter styling flattener in the sheet widget.
  final Map<String, dynamic> raw;

  CsatDetails({
    required this.id,
    required this.title,
    this.height,
    this.width,
    this.thankyouImage,
    required this.thankyouText,
    required this.thankyouDescription,
    required this.highStarText,
    required this.lowStarText,
    required this.descriptionText,
    required this.feedbackOptions,
    required this.link,
    required this.styling,
    required this.raw,
  });

  factory CsatDetails.fromJson(
    Map<String, dynamic> json, {
    String fallbackId = '',
  }) {
    final rawStyling = json['styling'];
    final stylingMap = rawStyling is Map
        ? Map<String, dynamic>.from(rawStyling)
        : <String, dynamic>{};

    // Fallback titles from nested styling.rating when top-level fields are empty.
    final ratingRaw = stylingMap['rating'];
    final ratingMap = ratingRaw is Map
        ? Map<String, dynamic>.from(ratingRaw)
        : <String, dynamic>{};
    final highRatingTitle = ratingMap['highRatingTitle'] as String? ?? 'Rate Us';
    final lowRatingTitle =
        ratingMap['lowRatingTitle'] as String? ?? 'Give Feedback';

    // feedback_option: key → display label.
    final rawFeedback = json['feedback_option'];
    final Map<String, String> feedbackOptions = {};
    if (rawFeedback is Map) {
      rawFeedback.forEach((k, v) => feedbackOptions['$k'] = '$v');
    }

    final highStarRaw = json['highStarText']?.toString() ?? '';
    final lowStarRaw = json['lowStarText']?.toString() ?? '';

    return CsatDetails(
      id: json['id'] as String? ?? fallbackId,
      title: json['title'] as String? ?? 'Rate Your Experience',
      height: json['height'] as num?,
      width: json['width'] as num?,
      thankyouImage: json['thankyouImage'] as String?,
      thankyouText: json['thankyouText'] as String? ?? 'Thank You!',
      thankyouDescription: json['thankyouDescription'] as String? ?? '',
      highStarText: highStarRaw.isNotEmpty ? highStarRaw : highRatingTitle,
      lowStarText: lowStarRaw.isNotEmpty ? lowStarRaw : lowRatingTitle,
      descriptionText: json['description_text'] as String? ?? '',
      feedbackOptions: feedbackOptions,
      link: json['link'] as String? ?? '',
      styling: CsatStyling.fromJson(stylingMap),
      raw: json,
    );
  }
}

// ── Styling ───────────────────────────────────────────────────────────────────

class CsatStyling {
  final CsatAppearance appearance;
  final CsatCrossButton? crossButton;

  /// Full raw styling map — passed unchanged to the Flutter flattener.
  final Map<String, dynamic> raw;

  CsatStyling({
    required this.appearance,
    this.crossButton,
    required this.raw,
  });

  factory CsatStyling.fromJson(Map<String, dynamic> json) {
    final rawAppearance = json['appearance'];
    final appearanceMap = rawAppearance is Map
        ? Map<String, dynamic>.from(rawAppearance)
        : <String, dynamic>{};

    final rawCross = json['crossButton'];
    final crossButton = rawCross is Map
        ? CsatCrossButton.fromJson(Map<String, dynamic>.from(rawCross))
        : null;

    return CsatStyling(
      appearance: CsatAppearance.fromJson(appearanceMap),
      crossButton: crossButton,
      raw: json,
    );
  }
}

class CsatAppearance {
  final String backdropColor;
  final double backdropOpacity;
  final String backgroundColor;
  final double borderRadius;
  final int displayDelay;

  const CsatAppearance({
    this.backdropColor = '#000000',
    this.backdropOpacity = 50,
    this.backgroundColor = '#FFFFFF',
    this.borderRadius = 4,
    this.displayDelay = 0,
  });

  factory CsatAppearance.fromJson(Map<String, dynamic> json) {
    return CsatAppearance(
      backdropColor: json['backdropColor'] as String? ?? '#000000',
      backdropOpacity: _toDouble(json['backdropOpacity']) ?? 50,
      backgroundColor: json['backgroundColor'] as String? ?? '#FFFFFF',
      borderRadius: _toDouble(json['borderRadius']) ?? 4,
      displayDelay: (json['displayDelay'] as num?)?.toInt() ?? 0,
    );
  }
}

class CsatCrossButton {
  final bool enabled;

  const CsatCrossButton({this.enabled = true});

  factory CsatCrossButton.fromJson(Map<String, dynamic> json) {
    return CsatCrossButton(enabled: json['enabled'] != false);
  }
}
