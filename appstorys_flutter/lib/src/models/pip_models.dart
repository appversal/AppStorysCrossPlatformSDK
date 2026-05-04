class PipCampaign {
  final String id;
  final String? smallVideoUrl;
  final String? largeVideoUrl;
  final String? link;
  final String? buttonText;
  final double width;
  final double height;
  final String position;
  final PipStyling? styling;

  const PipCampaign({
    required this.id,
    this.smallVideoUrl,
    this.largeVideoUrl,
    this.link,
    this.buttonText,
    this.width = 113,
    this.height = 200,
    this.position = 'right',
    this.styling,
  });

  factory PipCampaign.fromJson(Map<String, dynamic> json) {
    final styling = json['styling'] is Map
        ? PipStyling.fromJson(Map<String, dynamic>.from(json['styling'] as Map))
        : null;
    // appearance.pipHeight / pipWidth take precedence over root-level fields.
    return PipCampaign(
      id: (json['id'] as String?) ?? '',
      smallVideoUrl: json['small_video'] as String?,
      largeVideoUrl: json['large_video'] as String?,
      link: json['link'] as String?,
      buttonText: json['button_text'] as String?,
      width: styling?.appearanceWidth ?? (json['width'] as num?)?.toDouble() ?? 113,
      height: styling?.appearanceHeight ?? (json['height'] as num?)?.toDouble() ?? 200,
      position: (json['position'] as String?) ?? 'right',
      styling: styling,
    );
  }
}

class PipStyling {
  final bool isMovable;
  final Map<String, dynamic>? soundToggle;
  final Map<String, dynamic>? crossButton;
  final Map<String, dynamic>? expandControls;
  final Map<String, dynamic>? cta;
  // appearance: contains defaultSound, pipHeight, pipWidth
  final Map<String, dynamic>? appearance;
  // Extra padding from backend — added on top of host-provided padding (mirrors Kotlin's pipBottomPadding / pipTopPadding).
  final double pipBottomPadding;
  final double pipTopPadding;

  const PipStyling({
    this.isMovable = true,
    this.soundToggle,
    this.crossButton,
    this.expandControls,
    this.cta,
    this.appearance,
    this.pipBottomPadding = 0,
    this.pipTopPadding = 0,
  });

  // appearance.pipHeight overrides root-level height.
  double? get appearanceHeight {
    final v = appearance?['pipHeight'];
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  // appearance.pipWidth overrides root-level width.
  double? get appearanceWidth {
    final v = appearance?['pipWidth'];
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  // appearance.defaultSound takes precedence over soundToggle.defaultSound.
  // "yes" = unmuted (sound plays), "no" = muted (silent), null = unmuted.
  String? get defaultSound =>
      appearance?['defaultSound'] as String? ??
      soundToggle?['defaultSound'] as String?;

  // soundToggle.enabled defaults to true when absent.
  bool get soundToggleEnabled =>
      soundToggle?['enabled'] != false;

  // crossButton.enabled defaults to true when absent.
  bool get crossButtonEnabled =>
      crossButton?['enabled'] != false;

  // expandControls.enabled defaults to true when absent.
  bool get expandControlsEnabled =>
      expandControls?['enabled'] != false;

  factory PipStyling.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(String key) =>
        json[key] is Map ? Map<String, dynamic>.from(json[key] as Map) : null;

    double parseD(String key) =>
        double.tryParse(json[key]?.toString() ?? '') ?? 0;

    return PipStyling(
      isMovable: json['isMovable']?.toString() != 'false',
      soundToggle: asMap('soundToggle'),
      crossButton: asMap('crossButton'),
      expandControls: asMap('expandControls'),
      cta: asMap('cta'),
      appearance: asMap('appearance'),
      pipBottomPadding: parseD('pipBottomPadding'),
      pipTopPadding: parseD('pipTopPadding'),
    );
  }
}
