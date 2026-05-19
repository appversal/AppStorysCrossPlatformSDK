// Models for Spin The Wheel (STW) campaign type.

// ── Helpers ───────────────────────────────────────────────────────────────────

double _toDouble(dynamic v, [double def = 0.0]) {
  if (v == null) return def;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? def;
  return def;
}

int _toInt(dynamic v, [int def = 0]) {
  if (v == null) return def;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? def;
  return def;
}

bool _toBool(dynamic v, [bool def = false]) {
  if (v == null) return def;
  if (v is bool) return v;
  return def;
}

String _toStr(dynamic v, [String def = '']) {
  if (v == null) return def;
  return v.toString();
}

Map<String, dynamic> _safeMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

// ── Top-level Campaign ────────────────────────────────────────────────────────

class SpinWheelCampaign {
  final String id;
  final String campaignType;
  final SpinWheelDetails details;

  SpinWheelCampaign({
    required this.id,
    required this.campaignType,
    required this.details,
  });

  factory SpinWheelCampaign.fromJson(Map<String, dynamic> json) {
    final id = (json['campaign_id'] ?? json['id'] ?? '').toString();
    return SpinWheelCampaign(
      id: id,
      campaignType: _toStr(json['campaign_type'], 'STW'),
      details: SpinWheelDetails.fromJson(
        _safeMap(json['details']),
        fallbackId: id,
      ),
    );
  }
}

// ── Campaign Details ──────────────────────────────────────────────────────────

class SpinWheelDetails {
  final String id;

  // Content fields
  final int availableSpins;
  final String popupTitle;
  final String popupDescription;
  final String spinButtonText;
  final String rewardDisplayMode;
  final String availableSpinsText;
  final String spinDirection;
  final int totalSliceCount;
  final bool hapticFeedback;

  // Backdrop
  final String backdropColor;
  final int backdropOpacity;

  // Wheel-screen text/button styling (raw textStyle maps from VTC)
  final Map<String, dynamic> titleTextStyle;
  final Map<String, dynamic> subtitleTextStyle;
  final Map<String, dynamic> spinsTextStyle;

  // Spin button (full spinButton map: container, margin, text)
  final Map<String, dynamic> spinButton;

  // Wheel border styling
  final Map<String, dynamic> wheelConfig;

  // Cross button on wheel screen
  final Map<String, dynamic> stwCrossButton;

  // Reward screen
  final String rewardBackdropColor;
  final Map<String, dynamic> rewardTitleStyle;
  final Map<String, dynamic> rewardSubtitleStyle;
  final Map<String, dynamic> rewardCrossButton;
  final Map<String, dynamic> confetti;

  final List<SpinWheelSlice> slices;

  SpinWheelDetails({
    required this.id,
    required this.availableSpins,
    required this.popupTitle,
    required this.popupDescription,
    required this.spinButtonText,
    required this.rewardDisplayMode,
    required this.availableSpinsText,
    required this.spinDirection,
    required this.totalSliceCount,
    required this.hapticFeedback,
    required this.backdropColor,
    required this.backdropOpacity,
    required this.titleTextStyle,
    required this.subtitleTextStyle,
    required this.spinsTextStyle,
    required this.spinButton,
    required this.wheelConfig,
    required this.stwCrossButton,
    required this.rewardBackdropColor,
    required this.rewardTitleStyle,
    required this.rewardSubtitleStyle,
    required this.rewardCrossButton,
    required this.confetti,
    required this.slices,
  });

  factory SpinWheelDetails.fromJson(
    Map<String, dynamic> json, {
    String fallbackId = '',
  }) {
    final content = _safeMap(json['content']);
    final wheelCfgContent = _safeMap(content['wheelConfiguration']);
    final userInt = _safeMap(content['userInteraction']);

    final styling = _safeMap(json['styling']);
    final stw = _safeMap(styling['spinTheWheel']);
    final vtc = _safeMap(stw['visualTextCommunication']);

    final titleMap = _safeMap(vtc['title']);
    final titleTs = _safeMap(titleMap['textStyle']);

    final subtitleMap = _safeMap(vtc['subtitle']);
    final subtitleTs = _safeMap(subtitleMap['textStyle']);

    final spinsTextMap = _safeMap(vtc['availableSpinText']);
    final spinsTextTs = _safeMap(spinsTextMap['textStyle']);

    final spinBtn = _safeMap(vtc['spinButton']);
    final wheelCfgStl = _safeMap(stw['wheelConfiguration']);
    final stwCross = _safeMap(stw['crossButton']);

    final rewardCfg = _safeMap(styling['rewardConfiguration']);
    final rwTitle = _safeMap(rewardCfg['title']);
    final rwTitleTs = _safeMap(rwTitle['textStyle']);
    final rwSubtitle = _safeMap(rewardCfg['subtitle']);
    final rwSubtitleTs = _safeMap(rwSubtitle['textStyle']);
    final rwCross = _safeMap(rewardCfg['crossButton']);
    final confettiMap = _safeMap(rewardCfg['confetti']);

    final rawSlices = json['slices'];
    final slices = rawSlices is List
        ? rawSlices
            .whereType<Map>()
            .map((s) => SpinWheelSlice.fromJson(Map<String, dynamic>.from(s)))
            .toList()
        : <SpinWheelSlice>[];

    return SpinWheelDetails(
      id: _toStr(json['id'], fallbackId),
      availableSpins: _toInt(json['availableSpins'], 1),
      popupTitle: _toStr(json['popupTitle'], 'Spin To Win'),
      popupDescription: _toStr(json['popupDescription']),
      spinButtonText: _toStr(json['spinButtonText'], 'Spin now'),
      rewardDisplayMode: _toStr(json['rewardDisplayMode'], 'full-screen'),
      availableSpinsText: _toStr(content['availableSpinsText'], 'Spins left'),
      spinDirection: _toStr(wheelCfgContent['spinDirection'], 'clockwise'),
      totalSliceCount: _toInt(wheelCfgContent['totalSliceCount'], slices.length),
      hapticFeedback: _toBool(userInt['hapticFeedback']),
      backdropColor: _toStr(vtc['backdropColor'], '#000000'),
      backdropOpacity: _toInt(vtc['backdropOpacity'], 50),
      titleTextStyle: titleTs,
      subtitleTextStyle: subtitleTs,
      spinsTextStyle: spinsTextTs,
      spinButton: spinBtn,
      wheelConfig: wheelCfgStl,
      stwCrossButton: stwCross,
      rewardBackdropColor: _toStr(rewardCfg['backdropColor'], '#000000ff'),
      rewardTitleStyle: rwTitleTs,
      rewardSubtitleStyle: rwSubtitleTs,
      rewardCrossButton: rwCross,
      confetti: confettiMap,
      slices: slices,
    );
  }
}

// ── Wheel Slice ───────────────────────────────────────────────────────────────

class SpinWheelSlice {
  final String id;
  final String prizeLabel;
  final String sliceMedia;
  final bool noPrize;
  final int weight;

  // Wheel visual styling
  final String bgColor;
  final String strokeColor;
  final double strokeWidth;
  final double cornerRadiusTopLeft;
  final double cornerRadiusTopRight;
  final double cornerRadiusBottomLeft;
  final double cornerRadiusBottomRight;

  // Prize label text
  final String labelColor;
  final String labelFontFamily;
  final double labelFontSize;

  // Image config
  final double imageRotation;

  final SpinWheelReward? reward;

  SpinWheelSlice({
    required this.id,
    required this.prizeLabel,
    required this.sliceMedia,
    required this.noPrize,
    required this.weight,
    required this.bgColor,
    required this.strokeColor,
    required this.strokeWidth,
    required this.cornerRadiusTopLeft,
    required this.cornerRadiusTopRight,
    required this.cornerRadiusBottomLeft,
    required this.cornerRadiusBottomRight,
    required this.labelColor,
    required this.labelFontFamily,
    required this.labelFontSize,
    required this.imageRotation,
    this.reward,
  });

  factory SpinWheelSlice.fromJson(Map<String, dynamic> json) {
    final styling = _safeMap(json['styling']);
    final ws = _safeMap(styling['wheelStyling']);
    final color = _safeMap(ws['color']);
    final corner = _safeMap(ws['cornerRadius']);
    final plLabel = _safeMap(ws['priceLabel']);
    final plTs = _safeMap(plLabel['textStyle']);
    final image = _safeMap(ws['image']);

    final rewards = json['rewards'];
    final reward = rewards is List && rewards.isNotEmpty
        ? SpinWheelReward.fromJson(
            Map<String, dynamic>.from(rewards.first as Map))
        : null;

    return SpinWheelSlice(
      id: _toStr(json['id']),
      prizeLabel: _toStr(json['prizeLabel']),
      sliceMedia: _toStr(json['sliceMedia']),
      noPrize: _toBool(json['noPrize']),
      weight: _toInt(json['weight'], 10),
      bgColor: _toStr(color['background'], '#0B1020'),
      strokeColor: _toStr(color['stroke'], '#FFFFFF'),
      strokeWidth: _toDouble(ws['strokeWidth'], 2),
      cornerRadiusTopLeft: _toDouble(corner['topLeft']),
      cornerRadiusTopRight: _toDouble(corner['topRight']),
      cornerRadiusBottomLeft: _toDouble(corner['bottomLeft']),
      cornerRadiusBottomRight: _toDouble(corner['bottomRight']),
      labelColor: _toStr(plTs['color'], '#FFFFFF'),
      labelFontFamily: _toStr(plTs['fontFamily'], 'Helvetica'),
      labelFontSize: _toDouble(plTs['fontSize'], 12),
      imageRotation: _toDouble(image['rotation']),
      reward: reward,
    );
  }
}

// ── Slice Reward ──────────────────────────────────────────────────────────────

class SpinWheelReward {
  final String id;
  final String sliceId;
  final String prizeName;
  final String couponCode;
  final String buttonCta;
  final String subText;
  final String sliceRewardMedia;
  final String link;
  final String termsNConditions;
  final String tNcCta;

  // Raw styling maps — parsed inline in the widget
  final Map<String, dynamic> ctaStyling;
  final Map<String, dynamic> couponStyling;
  final Map<String, dynamic> priceLabelTextStyle;
  final Map<String, dynamic> subtitleTextStyle;

  SpinWheelReward({
    required this.id,
    required this.sliceId,
    required this.prizeName,
    required this.couponCode,
    required this.buttonCta,
    required this.subText,
    required this.sliceRewardMedia,
    required this.link,
    required this.termsNConditions,
    required this.tNcCta,
    required this.ctaStyling,
    required this.couponStyling,
    required this.priceLabelTextStyle,
    required this.subtitleTextStyle,
  });

  factory SpinWheelReward.fromJson(Map<String, dynamic> json) {
    final styling = _safeMap(json['styling']);
    final cta = _safeMap(styling['cta']);
    final coupon = _safeMap(styling['couponCodeCta']);
    final priceLabel = _safeMap(styling['priceLabel']);
    final priceLabelTs = _safeMap(priceLabel['textStyle']);
    final subtitleMap = _safeMap(styling['subtitleText']);
    final subtitleTs = _safeMap(subtitleMap['textStyle']);

    return SpinWheelReward(
      id: _toStr(json['id']),
      sliceId: _toStr(json['sliceId']),
      prizeName: _toStr(json['prizeName']),
      couponCode: _toStr(json['couponCode']),
      buttonCta: _toStr(json['buttonCta'], 'Claim'),
      subText: _toStr(json['subText']),
      sliceRewardMedia: _toStr(json['sliceRewardMedia']),
      link: _toStr(json['link']),
      termsNConditions: _toStr(json['termsNConditions']),
      tNcCta: _toStr(json['tNcCta'], 'T&C'),
      ctaStyling: cta,
      couponStyling: coupon,
      priceLabelTextStyle: priceLabelTs,
      subtitleTextStyle: subtitleTs,
    );
  }
}
