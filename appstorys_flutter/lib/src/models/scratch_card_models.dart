// Models for Scratch Card (SC) campaign type.
// Field names and structure mirror the shared-core SC campaign schema.

// ── Helpers ───────────────────────────────────────────────────────────────────

double _toDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

int _toInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

// ── Top-level Campaign ────────────────────────────────────────────────────────

class ScratchCardCampaign {
  final String id;
  final String campaignType;
  final ScratchCardDetails details;

  ScratchCardCampaign({
    required this.id,
    required this.campaignType,
    required this.details,
  });

  factory ScratchCardCampaign.fromJson(Map<String, dynamic> json) {
    final id = (json['campaign_id'] ?? json['id'] ?? '').toString();
    final rawDetails = json['details'];
    final detailsMap = rawDetails is Map
        ? Map<String, dynamic>.from(rawDetails)
        : <String, dynamic>{};
    return ScratchCardCampaign(
      id: id,
      campaignType: json['campaign_type'] as String? ?? 'SC',
      details: ScratchCardDetails.fromJson(detailsMap, fallbackId: id),
    );
  }
}

// ── Scratch Card Details ──────────────────────────────────────────────────────

class ScratchCardDetails {
  final String id;

  /// Reward/banner image shown after revealing.
  final String? bannerImage;

  /// Cover/overlay image scratched away by the user.
  final String? overlayImage;

  final String? couponCode;
  final String? link;
  final String? soundFile;
  final int? height;
  final int? width;

  final ScratchCardSize cardSize;
  final Map<String, dynamic>? crossButton;
  final ScratchCardCta cta;
  final ScratchCardRewardContent rewardContent;

  final bool customSoundEnabled;
  final bool haptics;
  final String? termsAndConditions;

  final ScratchCardAppearance appearance;

  /// Raw JSON map for any additional fields.
  final Map<String, dynamic> raw;

  ScratchCardDetails({
    required this.id,
    this.bannerImage,
    this.overlayImage,
    this.couponCode,
    this.link,
    this.soundFile,
    this.height,
    this.width,
    required this.cardSize,
    this.crossButton,
    required this.cta,
    required this.rewardContent,
    required this.customSoundEnabled,
    required this.haptics,
    this.termsAndConditions,
    required this.appearance,
    required this.raw,
  });

  factory ScratchCardDetails.fromJson(
    Map<String, dynamic> json, {
    String fallbackId = '',
  }) {
    final content = json['content'] is Map
        ? Map<String, dynamic>.from(json['content'] as Map)
        : <String, dynamic>{};

    final cardSizeRaw = content['card_size'] is Map
        ? Map<String, dynamic>.from(content['card_size'] as Map)
        : <String, dynamic>{};

    final crossButtonRaw = content['crossButton'] is Map
        ? Map<String, dynamic>.from(content['crossButton'] as Map)
        : null;

    final ctaRaw = content['cta'] is Map
        ? Map<String, dynamic>.from(content['cta'] as Map)
        : <String, dynamic>{};

    final rewardRaw = content['reward_content'] is Map
        ? Map<String, dynamic>.from(content['reward_content'] as Map)
        : <String, dynamic>{};

    final interactionsRaw = content['interactions'] is Map
        ? Map<String, dynamic>.from(content['interactions'] as Map)
        : <String, dynamic>{};

    final stylingRaw = json['styling'] is Map
        ? Map<String, dynamic>.from(json['styling'] as Map)
        : <String, dynamic>{};

    final appearanceRaw = stylingRaw['appearance'] is Map
        ? Map<String, dynamic>.from(stylingRaw['appearance'] as Map)
        : <String, dynamic>{};

    return ScratchCardDetails(
      id: json['id'] as String? ?? fallbackId,
      bannerImage: json['bannerImage'] as String?,
      overlayImage: json['coverImage'] as String?,
      couponCode: json['coupon_code'] as String?,
      link: json['link'] as String?,
      soundFile: json['soundFile'] as String?,
      height: json['height'] is num ? (json['height'] as num).toInt() : null,
      width: json['width'] is num ? (json['width'] as num).toInt() : null,
      cardSize: ScratchCardSize.fromJson(cardSizeRaw),
      crossButton: crossButtonRaw,
      cta: ScratchCardCta.fromJson(
        ctaRaw,
        buttonText: json['button_text'] as String?,
        url: json['link'] as String?,
      ),
      rewardContent: ScratchCardRewardContent.fromJson(rewardRaw),
      customSoundEnabled: content['custom_sound_enabled'] == true,
      haptics: interactionsRaw['haptics'] == true,
      termsAndConditions: content['terms_and_conditions'] as String?,
      appearance: ScratchCardAppearance.fromJson(appearanceRaw),
      raw: json,
    );
  }
}

// ── Appearance (backdrop / delay) ─────────────────────────────────────────────

class ScratchCardAppearance {
  final String backdropColor;
  final double backdropOpacity;
  final int displayDelay;

  const ScratchCardAppearance({
    this.backdropColor = '#000000',
    this.backdropOpacity = 70,
    this.displayDelay = 0,
  });

  factory ScratchCardAppearance.fromJson(Map<String, dynamic> json) {
    return ScratchCardAppearance(
      backdropColor: json['backdropColor'] as String? ?? '#000000',
      backdropOpacity: _toDouble(json['backdropOpacity'], 70),
      displayDelay: _toInt(json['displayDelay']),
    );
  }
}

// ── Card dimensions ───────────────────────────────────────────────────────────

class ScratchCardSize {
  final double width;
  final double height;
  final double cornerRadius;

  const ScratchCardSize({
    this.width = 300,
    this.height = 300,
    this.cornerRadius = 16,
  });

  factory ScratchCardSize.fromJson(Map<String, dynamic> json) {
    return ScratchCardSize(
      width: _toDouble(json['width'], 300),
      height: _toDouble(json['height'], 300),
      cornerRadius: _toDouble(json['corner_radius'], 16),
    );
  }
}

// ── CTA ───────────────────────────────────────────────────────────────────────

class ScratchCardCta {
  final String buttonText;
  final String? url;

  /// Raw cta map passed to [CtaButton] styling.
  final Map<String, dynamic> raw;

  const ScratchCardCta({
    required this.buttonText,
    this.url,
    required this.raw,
  });

  factory ScratchCardCta.fromJson(
    Map<String, dynamic> json, {
    String? buttonText,
    String? url,
  }) {
    return ScratchCardCta(
      buttonText: buttonText ?? 'Claim offer now',
      url: url,
      raw: json,
    );
  }
}

// ── Reward Content ────────────────────────────────────────────────────────────

class ScratchCardRewardContent {
  final String? backgroundColor;
  final bool onlyImage;
  final ScratchCardOfferSection? offerTitle;
  final ScratchCardOfferSection? offerSubtitle;
  final ScratchCardImageCircle? imageCircle;
  final ScratchCardCouponCta? couponCta;

  /// Full raw map for additional fields.
  final Map<String, dynamic> raw;

  ScratchCardRewardContent({
    this.backgroundColor,
    required this.onlyImage,
    this.offerTitle,
    this.offerSubtitle,
    this.imageCircle,
    this.couponCta,
    required this.raw,
  });

  factory ScratchCardRewardContent.fromJson(Map<String, dynamic> json) {
    final offerTitleRaw = json['offerTitle'] is Map
        ? Map<String, dynamic>.from(json['offerTitle'] as Map)
        : null;
    final offerSubtitleRaw = json['offerSubtitle'] is Map
        ? Map<String, dynamic>.from(json['offerSubtitle'] as Map)
        : null;
    final imageCircleRaw = json['imageCircle'] is Map
        ? Map<String, dynamic>.from(json['imageCircle'] as Map)
        : null;
    final couponCtaRaw = json['couponCodeCta'] is Map
        ? Map<String, dynamic>.from(json['couponCodeCta'] as Map)
        : null;

    return ScratchCardRewardContent(
      backgroundColor: json['background_color'] as String?,
      onlyImage: json['onlyImage'] == true,
      offerTitle: offerTitleRaw != null
          ? ScratchCardOfferSection.fromJson(offerTitleRaw)
          : null,
      offerSubtitle: offerSubtitleRaw != null
          ? ScratchCardOfferSection.fromJson(offerSubtitleRaw)
          : null,
      imageCircle: imageCircleRaw != null
          ? ScratchCardImageCircle.fromJson(imageCircleRaw)
          : null,
      couponCta: couponCtaRaw != null
          ? ScratchCardCouponCta.fromJson(couponCtaRaw)
          : null,
      raw: json,
    );
  }
}

// ── Offer text section (title / subtitle) ─────────────────────────────────────

class ScratchCardOfferSection {
  final String text;
  final String? color;
  final String? fontFamily;
  final double fontSize;
  final List<dynamic> fontDecoration;
  final String? textAlign;
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;

  const ScratchCardOfferSection({
    required this.text,
    this.color,
    this.fontFamily,
    required this.fontSize,
    required this.fontDecoration,
    this.textAlign,
    required this.marginTop,
    required this.marginBottom,
    required this.marginLeft,
    required this.marginRight,
  });

  factory ScratchCardOfferSection.fromJson(Map<String, dynamic> json) {
    final textStyle = json['textStyle'] is Map
        ? Map<String, dynamic>.from(json['textStyle'] as Map)
        : <String, dynamic>{};
    final margin = textStyle['margin'] is Map
        ? Map<String, dynamic>.from(textStyle['margin'] as Map)
        : <String, dynamic>{};

    return ScratchCardOfferSection(
      text: json['text'] as String? ?? '',
      color: textStyle['color'] as String?,
      fontFamily: textStyle['fontFamily'] as String?,
      fontSize: _toDouble(textStyle['fontSize'], 16),
      fontDecoration: textStyle['fontDecoration'] is List
          ? textStyle['fontDecoration'] as List
          : const [],
      textAlign: textStyle['textAlign'] as String?,
      marginTop: _toDouble(margin['top'], 10),
      marginBottom: _toDouble(margin['bottom'], 0),
      marginLeft: _toDouble(margin['left'], 0),
      marginRight: _toDouble(margin['right'], 0),
    );
  }
}

// ── Image Circle ──────────────────────────────────────────────────────────────

class ScratchCardImageCircle {
  final double width;
  final double height;
  final double cornerRadiusTopLeft;
  final double cornerRadiusTopRight;
  final double cornerRadiusBottomLeft;
  final double cornerRadiusBottomRight;
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;

  const ScratchCardImageCircle({
    this.width = 80,
    this.height = 80,
    this.cornerRadiusTopLeft = 40,
    this.cornerRadiusTopRight = 40,
    this.cornerRadiusBottomLeft = 40,
    this.cornerRadiusBottomRight = 40,
    this.marginTop = 40,
    this.marginBottom = 20,
    this.marginLeft = 20,
    this.marginRight = 20,
  });

  factory ScratchCardImageCircle.fromJson(Map<String, dynamic> json) {
    final size = json['size'] is Map
        ? Map<String, dynamic>.from(json['size'] as Map)
        : <String, dynamic>{};
    final cr = json['cornerRadius'] is Map
        ? Map<String, dynamic>.from(json['cornerRadius'] as Map)
        : <String, dynamic>{};
    final margin = json['margin'] is Map
        ? Map<String, dynamic>.from(json['margin'] as Map)
        : <String, dynamic>{};

    return ScratchCardImageCircle(
      width: _toDouble(size['width'], 80),
      height: _toDouble(size['height'], 80),
      cornerRadiusTopLeft: _toDouble(cr['topLeft'], 40),
      cornerRadiusTopRight: _toDouble(cr['topRight'], 40),
      cornerRadiusBottomLeft: _toDouble(cr['bottomLeft'], 40),
      cornerRadiusBottomRight: _toDouble(cr['bottomRight'], 40),
      marginTop: _toDouble(margin['top'], 40),
      marginBottom: _toDouble(margin['bottom'], 20),
      marginLeft: _toDouble(margin['left'], 20),
      marginRight: _toDouble(margin['right'], 20),
    );
  }
}

// ── Coupon CTA ────────────────────────────────────────────────────────────────

class ScratchCardCouponCta {
  final String? alignment;
  final String? backgroundColor;
  final String? borderColor;
  final double borderWidth;
  final bool fullWidth;
  final double? ctaWidth;
  final double? ctaHeight;
  final double cornerRadiusTopLeft;
  final double cornerRadiusTopRight;
  final double cornerRadiusBottomLeft;
  final double cornerRadiusBottomRight;
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;
  final String? textColor;
  final String? textFontFamily;
  final double textFontSize;
  final List<dynamic> textFontDecoration;

  /// Raw map for CtaButton or custom rendering.
  final Map<String, dynamic> raw;

  const ScratchCardCouponCta({
    this.alignment,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.fullWidth = false,
    this.ctaWidth,
    this.ctaHeight,
    this.cornerRadiusTopLeft = 12,
    this.cornerRadiusTopRight = 12,
    this.cornerRadiusBottomLeft = 12,
    this.cornerRadiusBottomRight = 12,
    this.marginTop = 0,
    this.marginBottom = 0,
    this.marginLeft = 0,
    this.marginRight = 0,
    this.textColor,
    this.textFontFamily,
    this.textFontSize = 12,
    this.textFontDecoration = const [],
    required this.raw,
  });

  factory ScratchCardCouponCta.fromJson(Map<String, dynamic> json) {
    final container = json['container'] is Map
        ? Map<String, dynamic>.from(json['container'] as Map)
        : <String, dynamic>{};
    final cr = json['cornerRadius'] is Map
        ? Map<String, dynamic>.from(json['cornerRadius'] as Map)
        : <String, dynamic>{};
    final margin = json['margin'] is Map
        ? Map<String, dynamic>.from(json['margin'] as Map)
        : <String, dynamic>{};
    final text = json['text'] is Map
        ? Map<String, dynamic>.from(json['text'] as Map)
        : <String, dynamic>{};

    return ScratchCardCouponCta(
      alignment: container['alignment'] as String?,
      backgroundColor: container['backgroundColor'] as String?,
      borderColor: container['borderColor'] as String?,
      borderWidth: _toDouble(container['borderWidth']),
      fullWidth: container['ctaFullWidth'] == true,
      ctaWidth: container['ctaWidth'] != null
          ? _toDouble(container['ctaWidth'])
          : null,
      ctaHeight: container['height'] != null
          ? _toDouble(container['height'])
          : null,
      cornerRadiusTopLeft: _toDouble(cr['topLeft'], 12),
      cornerRadiusTopRight: _toDouble(cr['topRight'], 12),
      cornerRadiusBottomLeft: _toDouble(cr['bottomLeft'], 12),
      cornerRadiusBottomRight: _toDouble(cr['bottomRight'], 12),
      marginTop: _toDouble(margin['top']),
      marginBottom: _toDouble(margin['bottom']),
      marginLeft: _toDouble(margin['left']),
      marginRight: _toDouble(margin['right']),
      textColor: text['color'] as String?,
      textFontFamily: text['fontFamily'] as String?,
      textFontSize: _toDouble(text['fontSize'], 12),
      textFontDecoration: text['fontDecoration'] is List
          ? text['fontDecoration'] as List
          : const [],
      raw: json,
    );
  }
}
