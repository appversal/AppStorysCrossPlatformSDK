// Models for Survey (SUR) campaign type.
// Field names and structure mirror SurveyModels.kt in shared-core.

// ── Helpers ───────────────────────────────────────────────────────────────────

double? _toDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

// ── Top-level Campaign ────────────────────────────────────────────────────────

class SurveyCampaign {
  final String id;
  final String campaignType;
  final SurveyDetails details;

  SurveyCampaign({
    required this.id,
    required this.campaignType,
    required this.details,
  });

  factory SurveyCampaign.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'];
    final detailsMap = rawDetails is Map
        ? Map<String, dynamic>.from(rawDetails)
        : <String, dynamic>{};
    return SurveyCampaign(
      id: (json['campaign_id'] ?? json['id'] ?? '').toString(),
      campaignType: json['campaign_type'] as String? ?? 'SUR',
      details: SurveyDetails.fromJson(detailsMap),
    );
  }
}

// ── Survey Details ────────────────────────────────────────────────────────────

class SurveyDetails {
  final String id;
  final String name;
  final List<SurveySlide> slides;
  final String thankYouTitle;
  final String thankYouSubtitle;
  final String thankYouText;
  final String? thankYouImage;
  final String thankYouButtonText;
  final SurveyThankYouButtonConfig thankYouButtonConfig;
  final SurveyStyling styling;

  /// Raw JSON map — passed directly to Flutter UI helper classes
  /// (AppearanceConfig, OptionsConfig, etc.) that parse from `Map<String,dynamic>`.
  final Map<String, dynamic> raw;

  SurveyDetails({
    required this.id,
    required this.name,
    required this.slides,
    required this.thankYouTitle,
    required this.thankYouSubtitle,
    required this.thankYouText,
    this.thankYouImage,
    required this.thankYouButtonText,
    required this.thankYouButtonConfig,
    required this.styling,
    required this.raw,
  });

  factory SurveyDetails.fromJson(Map<String, dynamic> json) {
    final rawSlides = json['slides'];
    final slides = (rawSlides is List
            ? rawSlides
                .whereType<Map>()
                .map((s) => SurveySlide.fromJson(Map<String, dynamic>.from(s)))
                .toList()
            : <SurveySlide>[])
        ..sort((a, b) => a.order.compareTo(b.order));

    final rawStyling = json['styling'];
    final stylingMap = rawStyling is Map
        ? Map<String, dynamic>.from(rawStyling)
        : <String, dynamic>{};

    return SurveyDetails(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slides: slides,
      thankYouTitle: json['thankYouTitle'] as String? ?? 'Thank You',
      thankYouSubtitle: json['thankYouSubtitle'] as String? ?? '',
      thankYouText: json['thankYouText'] as String? ?? '',
      thankYouImage: json['thankYouImage'] as String?,
      thankYouButtonText: json['thankYouButtonText'] as String? ?? 'Done',
      thankYouButtonConfig: SurveyThankYouButtonConfig.fromJson(json),
      styling: SurveyStyling.fromJson(stylingMap),
      raw: json,
    );
  }
}

// ── Slide ─────────────────────────────────────────────────────────────────────

class SurveySlide {
  final String id;
  final int order;
  final String title;
  final String subtitle;
  final String question;

  /// key → display label, preserves insertion order.
  final Map<String, String> options;

  final String? image;
  final String submitButtonText;
  final String parent;
  final SurveyAdditionalComment? additionalComment;
  final List<SurveyLogic> logic;

  SurveySlide({
    required this.id,
    required this.order,
    required this.title,
    required this.subtitle,
    required this.question,
    required this.options,
    this.image,
    required this.submitButtonText,
    required this.parent,
    this.additionalComment,
    required this.logic,
  });

  factory SurveySlide.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final Map<String, String> parsedOptions = {};
    if (rawOptions is Map) {
      rawOptions.forEach((k, v) => parsedOptions['$k'] = '$v');
    }

    final rawLogic = json['logic'];
    final logic = rawLogic is List
        ? rawLogic
            .whereType<Map>()
            .map((l) => SurveyLogic.fromJson(Map<String, dynamic>.from(l)))
            .toList()
        : <SurveyLogic>[];

    final rawComment = json['additionalComment'];
    final additionalComment = rawComment is Map
        ? SurveyAdditionalComment.fromJson(
            Map<String, dynamic>.from(rawComment))
        : null;

    return SurveySlide(
      id: json['id'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: parsedOptions,
      image: json['image'] as String?,
      submitButtonText: json['submitButtonText'] as String? ?? 'Next',
      parent: json['parent'] as String? ?? '',
      additionalComment: additionalComment,
      logic: logic,
    );
  }
}

// ── Slide sub-types ───────────────────────────────────────────────────────────

class SurveyAdditionalComment {
  final bool enabled;
  final String placeholder;

  const SurveyAdditionalComment({
    required this.enabled,
    required this.placeholder,
  });

  factory SurveyAdditionalComment.fromJson(Map<String, dynamic> json) {
    return SurveyAdditionalComment(
      enabled: json['enabled'] == true,
      placeholder: json['placeholder'] as String? ?? '',
    );
  }
}

class SurveyLogic {
  final String? redirectTo;
  final List<String> selectOption;

  const SurveyLogic({this.redirectTo, required this.selectOption});

  factory SurveyLogic.fromJson(Map<String, dynamic> json) {
    final rawSelect = json['selectOption'];
    final selectOption = rawSelect is List
        ? rawSelect.map((e) => '$e').toList()
        : <String>[];
    return SurveyLogic(
      redirectTo: json['redirectTo'] as String?,
      selectOption: selectOption,
    );
  }
}

// ── Thank-you button ──────────────────────────────────────────────────────────

class SurveyThankYouButtonConfig {
  final bool enabled;
  final String action;
  final String? redirectUrl;

  const SurveyThankYouButtonConfig({
    required this.enabled,
    required this.action,
    this.redirectUrl,
  });

  factory SurveyThankYouButtonConfig.fromJson(Map<String, dynamic> json) {
    final cfg = json['thankYouButtonConfig'];
    final cfgMap = cfg is Map ? Map<String, dynamic>.from(cfg) : <String, dynamic>{};
    return SurveyThankYouButtonConfig(
      enabled: cfgMap['enabled'] != false,
      action: cfgMap['action'] as String? ?? 'close',
      redirectUrl: cfgMap['redirectUrl'] as String?,
    );
  }
}

// ── Styling ───────────────────────────────────────────────────────────────────

class SurveyStyling {
  final SurveyAppearance appearance;
  final SurveyCrossButton? crossButton;

  /// Full raw styling map — passed unchanged to Flutter UI helper classes
  /// (AppearanceConfig, OptionsConfig, TextStyleConfig…) that parse Maps.
  final Map<String, dynamic> raw;

  SurveyStyling({
    required this.appearance,
    this.crossButton,
    required this.raw,
  });

  factory SurveyStyling.fromJson(Map<String, dynamic> json) {
    final rawAppearance = json['appearance'];
    final appearanceMap = rawAppearance is Map
        ? Map<String, dynamic>.from(rawAppearance)
        : <String, dynamic>{};

    final rawCross = json['crossButton'];
    final crossButton = rawCross is Map
        ? SurveyCrossButton.fromJson(Map<String, dynamic>.from(rawCross))
        : null;

    return SurveyStyling(
      appearance: SurveyAppearance.fromJson(appearanceMap),
      crossButton: crossButton,
      raw: json,
    );
  }
}

class SurveyAppearance {
  final String backdropColor;
  final double backdropOpacity;
  final String backgroundColor;
  final SurveyCornerRadius cornerRadius;
  final int displayDelay;

  const SurveyAppearance({
    this.backdropColor = '#000000',
    this.backdropOpacity = 50,
    this.backgroundColor = '#FFFFFF',
    this.cornerRadius = const SurveyCornerRadius(),
    this.displayDelay = 0,
  });

  factory SurveyAppearance.fromJson(Map<String, dynamic> json) {
    final rawCr = json['cornerRadius'];
    final crMap = rawCr is Map ? Map<String, dynamic>.from(rawCr) : null;
    return SurveyAppearance(
      backdropColor: json['backdropColor'] as String? ?? '#000000',
      backdropOpacity: _toDouble(json['backdropOpacity']) ?? 50,
      backgroundColor: json['backgroundColor'] as String? ?? '#FFFFFF',
      cornerRadius:
          crMap != null ? SurveyCornerRadius.fromJson(crMap) : const SurveyCornerRadius(),
      displayDelay: (json['displayDelay'] as num?)?.toInt() ?? 0,
    );
  }
}

class SurveyCornerRadius {
  final double topLeft;
  final double topRight;
  final double bottomLeft;
  final double bottomRight;

  const SurveyCornerRadius({
    this.topLeft = 12,
    this.topRight = 12,
    this.bottomLeft = 0,
    this.bottomRight = 0,
  });

  factory SurveyCornerRadius.fromJson(Map<String, dynamic> json) {
    return SurveyCornerRadius(
      topLeft: _toDouble(json['topLeft']) ?? 12,
      topRight: _toDouble(json['topRight']) ?? 12,
      bottomLeft: _toDouble(json['bottomLeft']) ?? 0,
      bottomRight: _toDouble(json['bottomRight']) ?? 0,
    );
  }
}

class SurveyCrossButton {
  final bool enabled;

  const SurveyCrossButton({this.enabled = true});

  factory SurveyCrossButton.fromJson(Map<String, dynamic> json) {
    return SurveyCrossButton(enabled: json['enabled'] != false);
  }
}
