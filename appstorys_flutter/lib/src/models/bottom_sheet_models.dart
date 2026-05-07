// Models for BottomSheet (BTS) campaign type.
// Field names and structure mirror BottomSheetModels.kt in shared-core.

// ── HELPERS ─────────────────────────────────────────────────────────────────

double? _toDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

// ── CAMPAIGN ─────────────────────────────────────────────────────────────────

class BottomSheetCampaign {
  final String id;
  final String? backdropColor;
  final double? backdropOpacity;
  final String? backgroundColor;
  final String? bottomsheetType;
  final BottomSheetCornerRadius? cornerRadius;
  final BottomSheetCrossButton? crossButton;
  final BottomSheetCrossButton? _stylingCrossButton;
  final String? enableCrossButton;
  final List<BottomSheetElement> elements;

  BottomSheetCampaign({
    required this.id,
    this.backdropColor,
    this.backdropOpacity,
    this.backgroundColor,
    this.bottomsheetType,
    this.cornerRadius,
    this.crossButton,
    BottomSheetCrossButton? stylingCrossButton,
    this.enableCrossButton,
    this.elements = const [],
  }) : _stylingCrossButton = stylingCrossButton;

  // Mirror Kotlin: root-level crossButton takes priority over styling.crossButton
  BottomSheetCrossButton? get effectiveCrossButton =>
      crossButton ?? _stylingCrossButton;

  bool get isCrossEnabled {
    final btn = effectiveCrossButton;
    if (btn?.enabled != null) return btn!.enabled!;
    final raw = enableCrossButton?.trim().toLowerCase();
    if (raw == null) return true; // Kotlin default is true
    return raw == 'true';
  }

  factory BottomSheetCampaign.fromJson(Map<String, dynamic> json) {
    final rawElements = json['elements'];
    final elements = rawElements is List
        ? rawElements
            .whereType<Map>()
            .map((e) =>
                BottomSheetElement.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <BottomSheetElement>[];

    BottomSheetCornerRadius? cr(dynamic raw) {
      if (raw is Map) {
        return BottomSheetCornerRadius.fromJson(
            Map<String, dynamic>.from(raw));
      }
      if (raw is num) {
        final v = raw.toDouble();
        return BottomSheetCornerRadius(
            topLeft: v, topRight: v, bottomLeft: v, bottomRight: v);
      }
      return null;
    }

    BottomSheetCrossButton? cb(dynamic raw) {
      if (raw is Map) {
        return BottomSheetCrossButton.fromJson(
            Map<String, dynamic>.from(raw));
      }
      return null;
    }

    BottomSheetCrossButton? stylingCrossButton;
    final styling = json['styling'];
    if (styling is Map) {
      stylingCrossButton = cb(styling['crossButton']);
    }

    return BottomSheetCampaign(
      id: (json['id'] as String?) ?? '',
      backdropColor: json['backdropColor'] as String?,
      backdropOpacity: _toDouble(json['backdropOpacity']),
      backgroundColor: json['backgroundColor'] as String?,
      bottomsheetType: json['bottomsheetType'] as String?,
      cornerRadius: cr(json['cornerRadius']),
      crossButton: cb(json['crossButton']),
      stylingCrossButton: stylingCrossButton,
      enableCrossButton: json['enableCrossButton'] as String?,
      elements: elements,
    );
  }
}

// ── CORNER RADIUS ─────────────────────────────────────────────────────────────

class BottomSheetCornerRadius {
  final double topLeft;
  final double topRight;
  final double bottomLeft;
  final double bottomRight;

  const BottomSheetCornerRadius({
    this.topLeft = 0,
    this.topRight = 0,
    this.bottomLeft = 0,
    this.bottomRight = 0,
  });

  factory BottomSheetCornerRadius.fromJson(Map<String, dynamic> json) {
    double v(String key) {
      final val = json[key];
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0;
      return 0;
    }
    return BottomSheetCornerRadius(
      topLeft: v('topLeft'),
      topRight: v('topRight'),
      bottomLeft: v('bottomLeft'),
      bottomRight: v('bottomRight'),
    );
  }
}

// ── CROSS BUTTON ─────────────────────────────────────────────────────────────
// Mirrors BannerStyleConfig from Kotlin (reused by BottomSheetDetails and
// BottomSheetStyling). Supports both 'color' and 'colors' JSON keys.

class BottomSheetCrossButton {
  final bool? enabled;
  final double? size;
  final Map<String, String>? color;
  final BottomSheetButtonMargin? margin;
  final String? image;
  final String? selectedStyle;

  BottomSheetCrossButton({
    this.enabled,
    this.size,
    this.color,
    this.margin,
    this.image,
    this.selectedStyle,
  });

  factory BottomSheetCrossButton.fromJson(Map<String, dynamic> json) {
    final colorRaw = json['color'] ?? json['colors'];
    final marginRaw = json['margin'];
    return BottomSheetCrossButton(
      enabled: json['enabled'] as bool?,
      size: _toDouble(json['size']),
      color: colorRaw is Map
          ? Map<String, String>.fromEntries(
              colorRaw.entries
                  .map((e) => MapEntry('${e.key}', '${e.value ?? ''}')),
            )
          : null,
      margin: marginRaw is Map
          ? BottomSheetButtonMargin.fromJson(
              Map<String, dynamic>.from(marginRaw))
          : null,
      image: json['image'] as String?,
      selectedStyle: json['selectedStyle'] as String?,
    );
  }
}

class BottomSheetButtonMargin {
  final double top;
  final double right;
  final double bottom;
  final double left;

  const BottomSheetButtonMargin({
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.left = 0,
  });

  factory BottomSheetButtonMargin.fromJson(Map<String, dynamic> json) {
    double v(String key) {
      final val = json[key];
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0;
      return 0;
    }
    return BottomSheetButtonMargin(
      top: v('top'),
      right: v('right'),
      bottom: v('bottom'),
      left: v('left'),
    );
  }
}

// ── ELEMENT ───────────────────────────────────────────────────────────────────
// Mirrors BottomSheetElement from Kotlin. All fields are nullable except
// type and order which are always present.

class BottomSheetElement {
  final String type;
  final int order;
  final String? id;
  final String? alignment;
  final String? position; // 'left' | 'right' — for paired CTA rendering

  // Image fields
  final String? url;
  final String? imageLink;
  final String? imageBackgroundColor;
  final bool? overlayButton;
  final BottomSheetCornerRadius? cornerRadius;
  final double? paddingLeft;
  final double? paddingRight;
  final double? paddingTop;
  final double? paddingBottom;

  // Body fields — note: body uses marginLeft/Right/Top/Bottom for outer spacing
  final String? titleText;
  final BottomSheetFontStyle? titleFontStyle;
  final int? titleFontSize;
  final String? descriptionText;
  final BottomSheetFontStyle? descriptionFontStyle;
  final int? descriptionFontSize;
  final double? titleLineHeight;
  final double? descriptionLineHeight;
  final double? spacingBetweenTitleDesc;
  final String? bodyBackgroundColor;
  final double? marginLeft;
  final double? marginRight;
  final double? marginTop;
  final double? marginBottom;

  // CTA fields
  final String? ctaText;
  final String? ctaLink;
  final BottomSheetCta? cta;
  final BottomSheetCornerRadius? ctaBorderRadius;
  final double? ctaHeight;
  final double? ctaWidth;
  final String? ctaTextColour;
  final String? ctaFontSize;
  final String? ctaFontFamily;
  final List<String>? ctaFontDecoration;
  final String? ctaBoxColor;
  final String? ctaBackgroundColor;
  final bool? ctaFullWidth;

  BottomSheetElement({
    required this.type,
    this.order = 0,
    this.id,
    this.alignment,
    this.position,
    this.url,
    this.imageLink,
    this.imageBackgroundColor,
    this.overlayButton,
    this.cornerRadius,
    this.paddingLeft,
    this.paddingRight,
    this.paddingTop,
    this.paddingBottom,
    this.titleText,
    this.titleFontStyle,
    this.titleFontSize,
    this.descriptionText,
    this.descriptionFontStyle,
    this.descriptionFontSize,
    this.titleLineHeight,
    this.descriptionLineHeight,
    this.spacingBetweenTitleDesc,
    this.bodyBackgroundColor,
    this.marginLeft,
    this.marginRight,
    this.marginTop,
    this.marginBottom,
    this.ctaText,
    this.ctaLink,
    this.cta,
    this.ctaBorderRadius,
    this.ctaHeight,
    this.ctaWidth,
    this.ctaTextColour,
    this.ctaFontSize,
    this.ctaFontFamily,
    this.ctaFontDecoration,
    this.ctaBoxColor,
    this.ctaBackgroundColor,
    this.ctaFullWidth,
  });

  factory BottomSheetElement.fromJson(Map<String, dynamic> json) {
    BottomSheetCornerRadius? cr(dynamic raw) {
      if (raw is Map) {
        return BottomSheetCornerRadius.fromJson(
            Map<String, dynamic>.from(raw));
      }
      if (raw is num) {
        final v = raw.toDouble();
        return BottomSheetCornerRadius(
            topLeft: v, topRight: v, bottomLeft: v, bottomRight: v);
      }
      return null;
    }

    BottomSheetFontStyle? fs(dynamic raw) {
      if (raw is Map) {
        return BottomSheetFontStyle.fromJson(
            Map<String, dynamic>.from(raw));
      }
      return null;
    }

    List<String>? deco(dynamic raw) {
      if (raw is List) return raw.map((e) => '$e').toList();
      return null;
    }

    return BottomSheetElement(
      type: (json['type'] as String?) ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      id: json['id'] as String?,
      alignment: json['alignment'] as String?,
      position: json['position'] as String?,
      url: json['url'] as String?,
      imageLink: json['imageLink'] as String?,
      imageBackgroundColor: json['imageBackgroundColor'] as String?,
      overlayButton: json['overlayButton'] as bool?,
      cornerRadius: cr(json['cornerRadius']),
      paddingLeft: _toDouble(json['paddingLeft']),
      paddingRight: _toDouble(json['paddingRight']),
      paddingTop: _toDouble(json['paddingTop']),
      paddingBottom: _toDouble(json['paddingBottom']),
      titleText: json['titleText'] as String?,
      titleFontStyle: fs(json['titleFontStyle']),
      titleFontSize: (json['titleFontSize'] as num?)?.toInt(),
      descriptionText: json['descriptionText'] as String?,
      descriptionFontStyle: fs(json['descriptionFontStyle']),
      descriptionFontSize: (json['descriptionFontSize'] as num?)?.toInt(),
      titleLineHeight: _toDouble(json['titleLineHeight']),
      descriptionLineHeight: _toDouble(json['descriptionLineHeight']),
      spacingBetweenTitleDesc: _toDouble(json['spacingBetweenTitleDesc']),
      bodyBackgroundColor: json['bodyBackgroundColor'] as String?,
      marginLeft: _toDouble(json['marginLeft']),
      marginRight: _toDouble(json['marginRight']),
      marginTop: _toDouble(json['marginTop']),
      marginBottom: _toDouble(json['marginBottom']),
      ctaText: json['ctaText'] as String?,
      ctaLink: json['ctaLink'] as String?,
      cta: json['cta'] is Map
          ? BottomSheetCta.fromJson(
              Map<String, dynamic>.from(json['cta'] as Map))
          : null,
      ctaBorderRadius: cr(json['ctaBorderRadius']),
      ctaHeight: _toDouble(json['ctaHeight']),
      ctaWidth: _toDouble(json['ctaWidth']),
      ctaTextColour: json['ctaTextColour'] as String?,
      ctaFontSize: json['ctaFontSize'] as String?,
      ctaFontFamily: json['ctaFontFamily'] as String?,
      ctaFontDecoration: deco(json['ctaFontDecoration']),
      ctaBoxColor: json['ctaBoxColor'] as String?,
      ctaBackgroundColor: json['ctaBackgroundColor'] as String?,
      ctaFullWidth: json['ctaFullWidth'] as bool?,
    );
  }
}

// ── FONT STYLE ────────────────────────────────────────────────────────────────
// Mirrors FontStyle from Kotlin. Renamed to avoid clash with Flutter's FontStyle.

class BottomSheetFontStyle {
  final String? fontFamily;
  final double? fontSize;
  final String? colour;
  final List<String>? decoration;
  final String? alignment;

  BottomSheetFontStyle({
    this.fontFamily,
    this.fontSize,
    this.colour,
    this.decoration,
    this.alignment,
  });

  factory BottomSheetFontStyle.fromJson(Map<String, dynamic> json) {
    return BottomSheetFontStyle(
      fontFamily: json['fontFamily'] as String?,
      fontSize: _toDouble(json['fontSize']),
      colour: json['colour'] as String?,
      decoration: json['decoration'] is List
          ? (json['decoration'] as List).map((e) => '$e').toList()
          : null,
      alignment: json['alignment'] as String?,
    );
  }
}

// ── CTA NESTED OBJECT ─────────────────────────────────────────────────────────
// Mirrors BottomSheetCta from Kotlin.

class BottomSheetCta {
  final BottomSheetCtaContainer? container;
  final BottomSheetCornerRadius? cornerRadius;
  final BottomSheetButtonMargin? margin;
  final BottomSheetCtaText? text;

  BottomSheetCta({
    this.container,
    this.cornerRadius,
    this.margin,
    this.text,
  });

  factory BottomSheetCta.fromJson(Map<String, dynamic> json) {
    BottomSheetCornerRadius? cr(dynamic raw) {
      if (raw is Map) {
        return BottomSheetCornerRadius.fromJson(
            Map<String, dynamic>.from(raw));
      }
      if (raw is num) {
        final v = raw.toDouble();
        return BottomSheetCornerRadius(
            topLeft: v, topRight: v, bottomLeft: v, bottomRight: v);
      }
      return null;
    }

    return BottomSheetCta(
      container: json['container'] is Map
          ? BottomSheetCtaContainer.fromJson(
              Map<String, dynamic>.from(json['container'] as Map))
          : null,
      cornerRadius: cr(json['cornerRadius']),
      margin: json['margin'] is Map
          ? BottomSheetButtonMargin.fromJson(
              Map<String, dynamic>.from(json['margin'] as Map))
          : null,
      text: json['text'] is Map
          ? BottomSheetCtaText.fromJson(
              Map<String, dynamic>.from(json['text'] as Map))
          : null,
    );
  }
}

class BottomSheetCtaContainer {
  final String? alignment;
  final String? backgroundColor;
  final String? borderColor;
  final double? borderWidth;
  final String? ctaBoxColor;
  final bool? ctaFullWidth;
  final double? ctaWidth;
  final double? height;

  BottomSheetCtaContainer({
    this.alignment,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.ctaBoxColor,
    this.ctaFullWidth,
    this.ctaWidth,
    this.height,
  });

  factory BottomSheetCtaContainer.fromJson(Map<String, dynamic> json) {
    return BottomSheetCtaContainer(
      alignment: json['alignment'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      borderColor: json['borderColor'] as String?,
      borderWidth: _toDouble(json['borderWidth']),
      ctaBoxColor: json['ctaBoxColor'] as String?,
      ctaFullWidth: json['ctaFullWidth'] as bool?,
      ctaWidth: _toDouble(json['ctaWidth']),
      height: _toDouble(json['height']),
    );
  }
}

class BottomSheetCtaText {
  final String? color;
  final List<String>? fontDecoration;
  final String? fontFamily;
  final int? fontSize;

  BottomSheetCtaText({
    this.color,
    this.fontDecoration,
    this.fontFamily,
    this.fontSize,
  });

  factory BottomSheetCtaText.fromJson(Map<String, dynamic> json) {
    return BottomSheetCtaText(
      color: json['color'] as String?,
      fontDecoration: json['fontDecoration'] is List
          ? (json['fontDecoration'] as List).map((e) => '$e').toList()
          : null,
      fontFamily: json['fontFamily'] as String?,
      fontSize: (json['fontSize'] as num?)?.toInt(),
    );
  }
}
