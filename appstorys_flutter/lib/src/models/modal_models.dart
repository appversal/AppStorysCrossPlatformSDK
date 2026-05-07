// Models for Modal (MDA) campaign type.
// Field names and structure mirror ModalModels.kt in shared-core.

// ── HELPERS ──────────────────────────────────────────────────────────────────

int? _toInt(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}

// ── CAMPAIGN DETAILS ──────────────────────────────────────────────────────────

class ModalCampaignDetails {
  final String? id;
  final List<ModalItem>? modals;
  final String? name;

  ModalCampaignDetails({this.id, this.modals, this.name});

  factory ModalCampaignDetails.fromJson(Map<String, dynamic> json) {
    final rawModals = json['modals'];
    final modals = rawModals is List
        ? rawModals
            .whereType<Map>()
            .map((m) => ModalItem.fromJson(Map<String, dynamic>.from(m)))
            .toList()
        : <ModalItem>[];
    return ModalCampaignDetails(
      id: json['id'] as String?,
      modals: modals,
      name: json['name'] as String?,
    );
  }
}

// ── MODAL ─────────────────────────────────────────────────────────────────────

class ModalItem {
  final String? id;
  final String? modalType;
  final ModalContent? content;
  final ModalStyling? styling;
  final int? screen;
  final String? name;
  // Flat media-only modal fields
  final ModalMedia? chooseMediaType;
  final String? link;
  final String? url;
  final String? size;
  final String? backgroundOpacity;
  final int? borderRadius;
  final bool? enableBackdrop;
  final bool? enableCrossButton;
  final String? crossButtonImage;
  final ModalRedirection? redirection;

  ModalItem({
    this.id,
    this.modalType,
    this.content,
    this.styling,
    this.screen,
    this.name,
    this.chooseMediaType,
    this.link,
    this.url,
    this.size,
    this.backgroundOpacity,
    this.borderRadius,
    this.enableBackdrop,
    this.enableCrossButton,
    this.crossButtonImage,
    this.redirection,
  });

  factory ModalItem.fromJson(Map<String, dynamic> json) {
    return ModalItem(
      id: json['id'] as String?,
      modalType: json['modal_type'] as String?,
      content: json['content'] is Map
          ? ModalContent.fromJson(Map<String, dynamic>.from(json['content'] as Map))
          : null,
      styling: json['styling'] is Map
          ? ModalStyling.fromJson(Map<String, dynamic>.from(json['styling'] as Map))
          : null,
      screen: _toInt(json['screen']),
      name: json['name'] as String?,
      chooseMediaType: json['chooseMediaType'] is Map
          ? ModalMedia.fromJson(Map<String, dynamic>.from(json['chooseMediaType'] as Map))
          : null,
      link: json['link'] as String?,
      url: json['url'] as String?,
      size: json['size']?.toString(),
      backgroundOpacity: json['backgroundOpacity']?.toString(),
      borderRadius: _toInt(json['borderRadius']),
      enableBackdrop: json['enableBackdrop'] as bool?,
      enableCrossButton: json['enableCrossButton'] as bool?,
      crossButtonImage: json['crossButtonImage'] as String?,
      redirection: json['redirection'] is Map
          ? ModalRedirection.fromJson(Map<String, dynamic>.from(json['redirection'] as Map))
          : null,
    );
  }
}

// ── MODAL CONTENT ─────────────────────────────────────────────────────────────

class ModalContent {
  final ModalMedia? chooseMediaType;
  final String? titleText;
  final String? subtitleText;
  final String? primaryCtaText;
  final ModalRedirection? primaryCtaRedirection;
  final String? secondaryCtaText;
  final ModalRedirection? secondaryCtaRedirection;
  final List<ModalContent>? set;
  final ModalStyling? styling;
  // Alternate CTA keys (some backends use these)
  final String? primaryCta;
  final String? secondayCta;
  final String? secondaryCtaAlt;
  final String? enableCrossButton;

  ModalContent({
    this.chooseMediaType,
    this.titleText,
    this.subtitleText,
    this.primaryCtaText,
    this.primaryCtaRedirection,
    this.secondaryCtaText,
    this.secondaryCtaRedirection,
    this.set,
    this.styling,
    this.primaryCta,
    this.secondayCta,
    this.secondaryCtaAlt,
    this.enableCrossButton,
  });

  factory ModalContent.fromJson(Map<String, dynamic> json) {
    List<ModalContent>? slides;
    final rawSet = json['set'];
    if (rawSet is List) {
      slides = rawSet
          .whereType<Map>()
          .map((s) => ModalContent.fromJson(Map<String, dynamic>.from(s)))
          .toList();
    }

    return ModalContent(
      chooseMediaType: json['chooseMediaType'] is Map
          ? ModalMedia.fromJson(Map<String, dynamic>.from(json['chooseMediaType'] as Map))
          : null,
      titleText: json['titleText'] as String?,
      subtitleText: json['subtitleText'] as String?,
      primaryCtaText: json['primaryCtaText'] as String?,
      primaryCtaRedirection: json['primaryCtaRedirection'] is Map
          ? ModalRedirection.fromJson(Map<String, dynamic>.from(json['primaryCtaRedirection'] as Map))
          : null,
      secondaryCtaText: json['secondaryCtaText'] as String?,
      secondaryCtaRedirection: json['secondaryCtaRedirection'] is Map
          ? ModalRedirection.fromJson(Map<String, dynamic>.from(json['secondaryCtaRedirection'] as Map))
          : null,
      set: slides,
      styling: json['styling'] is Map
          ? ModalStyling.fromJson(Map<String, dynamic>.from(json['styling'] as Map))
          : null,
      primaryCta: json['primaryCta'] as String?,
      secondayCta: json['secondayCta'] as String?,
      secondaryCtaAlt: json['secondaryCta'] as String?,
      enableCrossButton: json['enableCrossButton']?.toString(),
    );
  }
}

// ── MODAL MEDIA ───────────────────────────────────────────────────────────────

class ModalMedia {
  final String? type;
  final String? url;

  ModalMedia({this.type, this.url});

  factory ModalMedia.fromJson(Map<String, dynamic> json) {
    return ModalMedia(
      type: json['type'] as String?,
      url: json['url'] as String?,
    );
  }
}

// ── MODAL REDIRECTION ─────────────────────────────────────────────────────────

class ModalRedirection {
  final String? type;
  final String? url;
  final String? value;
  final String? key;
  final String? pageName;

  ModalRedirection({this.type, this.url, this.value, this.key, this.pageName});

  factory ModalRedirection.fromJson(Map<String, dynamic> json) {
    return ModalRedirection(
      type: json['type'] as String?,
      url: json['url'] as String?,
      value: json['value'] as String?,
      key: json['key'] as String?,
      pageName: json['pageName'] as String?,
    );
  }
}

// ── MODAL STYLING ─────────────────────────────────────────────────────────────

class ModalStyling {
  final ModalAppearance? appearance;
  final ModalCrossButton? crossButton;
  final ModalCta? primaryCta;
  final ModalCta? secondaryCta;
  final ModalTextStyling? title;
  final ModalTextStyling? subTitle;

  ModalStyling({
    this.appearance,
    this.crossButton,
    this.primaryCta,
    this.secondaryCta,
    this.title,
    this.subTitle,
  });

  factory ModalStyling.fromJson(Map<String, dynamic> json) {
    return ModalStyling(
      appearance: json['appearance'] is Map
          ? ModalAppearance.fromJson(Map<String, dynamic>.from(json['appearance'] as Map))
          : null,
      crossButton: json['crossButton'] is Map
          ? ModalCrossButton.fromJson(Map<String, dynamic>.from(json['crossButton'] as Map))
          : null,
      primaryCta: json['primaryCta'] is Map
          ? ModalCta.fromJson(Map<String, dynamic>.from(json['primaryCta'] as Map))
          : null,
      secondaryCta: json['secondaryCta'] is Map
          ? ModalCta.fromJson(Map<String, dynamic>.from(json['secondaryCta'] as Map))
          : null,
      title: json['title'] is Map
          ? ModalTextStyling.fromJson(Map<String, dynamic>.from(json['title'] as Map))
          : null,
      subTitle: json['subTitle'] is Map
          ? ModalTextStyling.fromJson(Map<String, dynamic>.from(json['subTitle'] as Map))
          : null,
    );
  }
}

// ── MODAL CROSS BUTTON ────────────────────────────────────────────────────────

class ModalCrossButton {
  // `default` is a reserved word in Dart — renamed to defaultConfig
  final ModalCrossButtonDefault? defaultConfig;
  final bool? enableCrossButton;
  final ModalUploadImage? uploadImage;
  final ModalColors? color;
  final ModalColors? colors;
  final bool? enabled;
  final String? image;
  final ModalMargin? margin;
  final String? option;
  final String? selectedStyle;
  final int? size;

  ModalCrossButton({
    this.defaultConfig,
    this.enableCrossButton,
    this.uploadImage,
    this.color,
    this.colors,
    this.enabled,
    this.image,
    this.margin,
    this.option,
    this.selectedStyle,
    this.size,
  });

  factory ModalCrossButton.fromJson(Map<String, dynamic> json) {
    return ModalCrossButton(
      defaultConfig: json['default'] is Map
          ? ModalCrossButtonDefault.fromJson(Map<String, dynamic>.from(json['default'] as Map))
          : null,
      enableCrossButton: json['enableCrossButton'] as bool?,
      uploadImage: json['uploadImage'] is Map
          ? ModalUploadImage.fromJson(Map<String, dynamic>.from(json['uploadImage'] as Map))
          : null,
      color: json['color'] is Map
          ? ModalColors.fromJson(Map<String, dynamic>.from(json['color'] as Map))
          : null,
      colors: json['colors'] is Map
          ? ModalColors.fromJson(Map<String, dynamic>.from(json['colors'] as Map))
          : null,
      enabled: json['enabled'] as bool?,
      image: json['image'] as String?,
      margin: json['margin'] is Map
          ? ModalMargin.fromJson(Map<String, dynamic>.from(json['margin'] as Map))
          : null,
      option: json['option'] as String?,
      selectedStyle: json['selectedStyle'] as String?,
      size: _toInt(json['size']),
    );
  }
}

class ModalColors {
  final String? fill;
  final String? cross;
  final String? stroke;

  ModalColors({this.fill, this.cross, this.stroke});

  factory ModalColors.fromJson(Map<String, dynamic> json) {
    return ModalColors(
      fill: json['fill'] as String?,
      cross: json['cross'] as String?,
      stroke: json['stroke'] as String?,
    );
  }
}

class ModalCrossButtonDefault {
  final ModalColors? color;
  final ModalSpacing? spacing;
  final String? crossButtonImage;
  final int? size;

  ModalCrossButtonDefault({this.color, this.spacing, this.crossButtonImage, this.size});

  factory ModalCrossButtonDefault.fromJson(Map<String, dynamic> json) {
    return ModalCrossButtonDefault(
      color: json['color'] is Map
          ? ModalColors.fromJson(Map<String, dynamic>.from(json['color'] as Map))
          : null,
      spacing: json['spacing'] is Map
          ? ModalSpacing.fromJson(Map<String, dynamic>.from(json['spacing'] as Map))
          : null,
      crossButtonImage: json['crossButtonImage'] as String?,
      size: _toInt(json['size']),
    );
  }
}

class ModalUploadImage {
  final String? url;

  ModalUploadImage({this.url});

  factory ModalUploadImage.fromJson(Map<String, dynamic> json) {
    return ModalUploadImage(url: json['url'] as String?);
  }
}

class ModalSpacing {
  final ModalMargin? margin;
  final ModalPadding? padding;

  ModalSpacing({this.margin, this.padding});

  factory ModalSpacing.fromJson(Map<String, dynamic> json) {
    return ModalSpacing(
      margin: json['margin'] is Map
          ? ModalMargin.fromJson(Map<String, dynamic>.from(json['margin'] as Map))
          : null,
      padding: json['padding'] is Map
          ? ModalPadding.fromJson(Map<String, dynamic>.from(json['padding'] as Map))
          : null,
    );
  }
}

class ModalMargin {
  final int? top;
  final int? right;
  final int? bottom;
  final int? left;

  ModalMargin({this.top, this.right, this.bottom, this.left});

  factory ModalMargin.fromJson(Map<String, dynamic> json) {
    return ModalMargin(
      top: _toInt(json['top']),
      right: _toInt(json['right']),
      bottom: _toInt(json['bottom']),
      left: _toInt(json['left']),
    );
  }
}

class ModalPadding {
  final int? top;
  final int? right;
  final int? bottom;
  final int? left;

  ModalPadding({this.top, this.right, this.bottom, this.left});

  factory ModalPadding.fromJson(Map<String, dynamic> json) {
    return ModalPadding(
      top: _toInt(json['top']),
      right: _toInt(json['right']),
      bottom: _toInt(json['bottom']),
      left: _toInt(json['left']),
    );
  }
}

// ── MODAL CTA ─────────────────────────────────────────────────────────────────

class ModalCta {
  final String? backgroundColor;
  final String? borderColor;
  final ModalCtaContainer? containerStyle;
  final ModalCtaContainer? container;
  final ModalCtaCornerRadius? cornerRadius;
  final String? occupyFullWidth;
  final ModalSpacing? spacing;
  final ModalMargin? margin;
  final String? textColor;
  final ModalTextStyle? textStyle;
  final ModalCtaText? text;

  ModalCta({
    this.backgroundColor,
    this.borderColor,
    this.containerStyle,
    this.container,
    this.cornerRadius,
    this.occupyFullWidth,
    this.spacing,
    this.margin,
    this.textColor,
    this.textStyle,
    this.text,
  });

  factory ModalCta.fromJson(Map<String, dynamic> json) {
    return ModalCta(
      backgroundColor: json['backgroundColor'] as String?,
      borderColor: json['borderColor'] as String?,
      containerStyle: json['containerStyle'] is Map
          ? ModalCtaContainer.fromJson(Map<String, dynamic>.from(json['containerStyle'] as Map))
          : null,
      container: json['container'] is Map
          ? ModalCtaContainer.fromJson(Map<String, dynamic>.from(json['container'] as Map))
          : null,
      cornerRadius: json['cornerRadius'] is Map
          ? ModalCtaCornerRadius.fromJson(Map<String, dynamic>.from(json['cornerRadius'] as Map))
          : null,
      occupyFullWidth: json['occupyFullWidth']?.toString(),
      spacing: json['spacing'] is Map
          ? ModalSpacing.fromJson(Map<String, dynamic>.from(json['spacing'] as Map))
          : null,
      margin: json['margin'] is Map
          ? ModalMargin.fromJson(Map<String, dynamic>.from(json['margin'] as Map))
          : null,
      textColor: json['textColor'] as String?,
      textStyle: json['textStyle'] is Map
          ? ModalTextStyle.fromJson(Map<String, dynamic>.from(json['textStyle'] as Map))
          : null,
      text: json['text'] is Map
          ? ModalCtaText.fromJson(Map<String, dynamic>.from(json['text'] as Map))
          : null,
    );
  }
}

class ModalCtaContainer {
  final String? alignment;
  final int? borderWidth;
  final int? ctaWidth;
  final int? height;
  final String? backgroundColor;
  final String? borderColor;
  final bool? ctaFullWidth;

  ModalCtaContainer({
    this.alignment,
    this.borderWidth,
    this.ctaWidth,
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.ctaFullWidth,
  });

  factory ModalCtaContainer.fromJson(Map<String, dynamic> json) {
    return ModalCtaContainer(
      alignment: json['alignment'] as String?,
      borderWidth: _toInt(json['borderWidth']),
      ctaWidth: _toInt(json['ctaWidth']),
      height: _toInt(json['height']),
      backgroundColor: json['backgroundColor'] as String?,
      borderColor: json['borderColor'] as String?,
      ctaFullWidth: json['ctaFullWidth'] as bool?,
    );
  }
}

class ModalCtaCornerRadius {
  final int? topLeft;
  final int? topRight;
  final int? bottomLeft;
  final int? bottomRight;

  ModalCtaCornerRadius({this.topLeft, this.topRight, this.bottomLeft, this.bottomRight});

  factory ModalCtaCornerRadius.fromJson(Map<String, dynamic> json) {
    return ModalCtaCornerRadius(
      topLeft: _toInt(json['topLeft']),
      topRight: _toInt(json['topRight']),
      bottomLeft: _toInt(json['bottomLeft']),
      bottomRight: _toInt(json['bottomRight']),
    );
  }
}

class ModalTextStyle {
  final String? font;
  final int? size;

  ModalTextStyle({this.font, this.size});

  factory ModalTextStyle.fromJson(Map<String, dynamic> json) {
    return ModalTextStyle(
      font: json['font'] as String?,
      size: _toInt(json['size']),
    );
  }
}

class ModalCtaText {
  final String? color;
  final int? fontSize;
  final String? fontFamily;
  final List<String>? fontDecoration;

  ModalCtaText({this.color, this.fontSize, this.fontFamily, this.fontDecoration});

  factory ModalCtaText.fromJson(Map<String, dynamic> json) {
    return ModalCtaText(
      color: json['color'] as String?,
      fontSize: _toInt(json['fontSize']),
      fontFamily: json['fontFamily'] as String?,
      fontDecoration: json['fontDecoration'] is List
          ? (json['fontDecoration'] as List).map((e) => '$e').toList()
          : null,
    );
  }
}

class ModalTextStyling {
  final String? alignment;
  final String? textAlign;
  final String? color;
  final String? font;
  final String? fontFamily;
  final String? fontStyle;
  final int? size;
  final int? fontSize;
  final List<String>? fontDecoration;

  ModalTextStyling({
    this.alignment,
    this.textAlign,
    this.color,
    this.font,
    this.fontFamily,
    this.fontStyle,
    this.size,
    this.fontSize,
    this.fontDecoration,
  });

  factory ModalTextStyling.fromJson(Map<String, dynamic> json) {
    return ModalTextStyling(
      alignment: json['alignment'] as String?,
      textAlign: json['textAlign'] as String?,
      color: json['color'] as String?,
      font: json['font'] as String?,
      fontFamily: json['fontFamily'] as String?,
      fontStyle: json['fontStyle'] as String?,
      size: _toInt(json['size']),
      fontSize: _toInt(json['fontSize']),
      fontDecoration: json['fontDecoration'] is List
          ? (json['fontDecoration'] as List).map((e) => '$e').toList()
          : null,
    );
  }
}

// ── MODAL APPEARANCE ──────────────────────────────────────────────────────────

class ModalAppearance {
  final ModalDimension? dimension;
  final ModalCornerRadius? cornerRadius;
  final ModalBackdrop? backdrop;
  final bool? enableBackdrop;
  final ModalPadding? padding;
  final String? ctaDisplay;
  final String? backgroundColor;
  final String? backdropColor;
  final String? backdropOpacity;

  ModalAppearance({
    this.dimension,
    this.cornerRadius,
    this.backdrop,
    this.enableBackdrop,
    this.padding,
    this.ctaDisplay,
    this.backgroundColor,
    this.backdropColor,
    this.backdropOpacity,
  });

  factory ModalAppearance.fromJson(Map<String, dynamic> json) {
    return ModalAppearance(
      dimension: json['dimension'] is Map
          ? ModalDimension.fromJson(Map<String, dynamic>.from(json['dimension'] as Map))
          : null,
      cornerRadius: json['cornerRadius'] is Map
          ? ModalCornerRadius.fromJson(Map<String, dynamic>.from(json['cornerRadius'] as Map))
          : null,
      backdrop: json['backdrop'] is Map
          ? ModalBackdrop.fromJson(Map<String, dynamic>.from(json['backdrop'] as Map))
          : null,
      enableBackdrop: json['enableBackdrop'] as bool?,
      padding: json['padding'] is Map
          ? ModalPadding.fromJson(Map<String, dynamic>.from(json['padding'] as Map))
          : null,
      ctaDisplay: json['ctaDisplay'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      backdropColor: json['backdropColor'] as String?,
      backdropOpacity: json['backdropOpacity']?.toString(),
    );
  }
}

class ModalBackdrop {
  final String? color;
  final String? opacity;

  ModalBackdrop({this.color, this.opacity});

  factory ModalBackdrop.fromJson(Map<String, dynamic> json) {
    return ModalBackdrop(
      color: json['color'] as String?,
      opacity: json['opacity']?.toString(),
    );
  }
}

class ModalDimension {
  final String? height;
  final String? borderWidth;

  ModalDimension({this.height, this.borderWidth});

  factory ModalDimension.fromJson(Map<String, dynamic> json) {
    return ModalDimension(
      height: json['height']?.toString(),
      borderWidth: json['borderWidth']?.toString(),
    );
  }
}

class ModalCornerRadius {
  final int? topLeft;
  final int? topRight;
  final int? bottomLeft;
  final int? bottomRight;

  ModalCornerRadius({this.topLeft, this.topRight, this.bottomLeft, this.bottomRight});

  factory ModalCornerRadius.fromJson(Map<String, dynamic> json) {
    return ModalCornerRadius(
      topLeft: _toInt(json['topLeft']),
      topRight: _toInt(json['topRight']),
      bottomLeft: _toInt(json['bottomLeft']),
      bottomRight: _toInt(json['bottomRight']),
    );
  }
}
