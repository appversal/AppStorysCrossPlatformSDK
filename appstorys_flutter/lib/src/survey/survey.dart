import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../appstorys_flutter.dart';
import '../common/cross_button.dart';
import '../common/cta_button.dart';
import '../utils/campaigns_stream_mixin.dart';
import '../utils/font_cache.dart';
import '../utils/link_handler.dart';

export '../models/survey_models.dart';

// ─── KMP Entry Widget ─────────────────────────────────────────────────────────
// Subscribes to the campaigns stream and shows Survey (SUR) campaigns as a
// modal bottom sheet. Add to AppStorysOverlay or your widget tree directly.

class AppStorysSurvey extends StatefulWidget {
  final AppstorysFlutter appStorys;
  final void Function(String)? onLinkTap;

  const AppStorysSurvey({
    super.key,
    required this.appStorys,
    this.onLinkTap,
  });

  @override
  State<AppStorysSurvey> createState() => _AppStorysSurveyState();
}

class _AppStorysSurveyState extends State<AppStorysSurvey>
    with CampaignsStreamMixin, WidgetsBindingObserver {
  bool _showing = false;
  String? _currentCampaignId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    subscribeToCampaigns(widget.appStorys.campaignsStream, _handleCampaigns);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _showing = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleCampaigns(String json) {
    final campaign = _parseCampaign(json);
    if (campaign == null) return;

    if (campaign.id == _currentCampaignId || _showing) return;
    _currentCampaignId = campaign.id;

    final appearance = campaign.details.styling.appearance;
    final delay = appearance.displayDelay;
    final bdColor = _hexToColor(appearance.backdropColor)
        .withValues(alpha: (appearance.backdropOpacity / 100).clamp(0.0, 1.0));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _showing) return;
      if (delay > 0) await Future.delayed(Duration(seconds: delay));
      if (!mounted || _showing) return;
      _showing = true;
      widget.appStorys
          .trackEvent(event: 'viewed', campaignId: campaign.id)
          .catchError((_) {});
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        barrierColor: bdColor,
        builder: (ctx) => _SurveySheet(
          campaign: campaign,
          appStorys: widget.appStorys,
          onLinkTap: widget.onLinkTap,
          onDismiss: () => Navigator.of(ctx).pop(),
        ),
      ).then((_) {
        if (mounted) _showing = false;
      });
    });
  }

  SurveyCampaign? _parseCampaign(String json) {
    try {
      final data = jsonDecode(json) as List<dynamic>;
      final raw = data.whereType<Map>().firstWhere(
        (c) => c['campaign_type'] == 'SUR',
        orElse: () => {},
      );
      if (raw.isEmpty) return null;
      return SurveyCampaign.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return null;
    }
  }

  static Color _hexToColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ─── Flutter UI helper models (parsed from styling raw map) ───────────────────

class AppearanceConfig {
  final Color backdropColor;
  final double backdropOpacity;
  final Color backgroundColor;
  final BorderRadius cornerRadius;
  final int displayDelay;

  AppearanceConfig({
    required this.backdropColor,
    required this.backdropOpacity,
    required this.backgroundColor,
    required this.cornerRadius,
    required this.displayDelay,
  });

  factory AppearanceConfig.fromModel(SurveyAppearance m) {
    return AppearanceConfig(
      backdropColor: _hexToColor(m.backdropColor),
      backdropOpacity: m.backdropOpacity.clamp(0, 100),
      backgroundColor: _hexToColor(m.backgroundColor),
      cornerRadius: BorderRadius.only(
        topLeft: Radius.circular(m.cornerRadius.topLeft),
        topRight: Radius.circular(m.cornerRadius.topRight),
        bottomLeft: Radius.circular(m.cornerRadius.bottomLeft),
        bottomRight: Radius.circular(m.cornerRadius.bottomRight),
      ),
      displayDelay: m.displayDelay,
    );
  }

  static Color _hexToColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.black;
    }
  }

  double get flutterOpacity => backdropOpacity / 100;
}

class TextStyleConfig {
  final Color color;
  final double fontSize;
  final String fontFamily;
  final TextAlign textAlign;
  final List<String> fontDecoration;
  final EdgeInsets margin;

  TextStyleConfig({
    required this.color,
    required this.fontSize,
    required this.fontFamily,
    required this.textAlign,
    required this.fontDecoration,
    required this.margin,
  });

  factory TextStyleConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return TextStyleConfig.defaultStyle();
    try {
      final marginMap = map['margin'] as Map<String, dynamic>? ?? {};
      return TextStyleConfig(
        color: _hexToColor(map['color'] as String? ?? '#111827'),
        fontSize: (map['fontSize'] as num?)?.toDouble() ?? 14,
        fontFamily: map['fontFamily'] as String? ?? '',
        textAlign: _parseTextAlign(map['textAlign'] as String? ?? 'left'),
        fontDecoration: List<String>.from(map['fontDecoration'] as List? ?? []),
        margin: EdgeInsets.only(
          top: (marginMap['top'] as num?)?.toDouble() ?? 0,
          bottom: (marginMap['bottom'] as num?)?.toDouble() ?? 0,
          left: (marginMap['left'] as num?)?.toDouble() ?? 0,
          right: (marginMap['right'] as num?)?.toDouble() ?? 0,
        ),
      );
    } catch (_) {
      return TextStyleConfig.defaultStyle();
    }
  }

  factory TextStyleConfig.defaultStyle() => TextStyleConfig(
    color: Colors.black,
    fontSize: 14,
    fontFamily: '',
    textAlign: TextAlign.left,
    fontDecoration: [],
    margin: const EdgeInsets.all(4),
  );

  static Color _hexToColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.black;
    }
  }

  static TextAlign _parseTextAlign(String a) {
    switch (a.toLowerCase()) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  bool get isUnderlined => fontDecoration.contains('underline');
  bool get isBold => fontDecoration.contains('bold');
  bool get isItalic => fontDecoration.contains('italic');
}

class OptionStateStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final double fontSize;
  final String fontFamily;
  final List<String> fontDecoration;
  final double borderWidth;
  final TextAlign textAlign;

  OptionStateStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.fontSize,
    required this.fontFamily,
    required this.fontDecoration,
    required this.borderWidth,
    required this.textAlign,
  });

  factory OptionStateStyle.fromMap(
    Map<String, dynamic>? map, {
    required Color defaultBg,
    required Color defaultBorder,
    required Color defaultText,
  }) {
    if (map == null) {
      return OptionStateStyle(
        backgroundColor: defaultBg,
        borderColor: defaultBorder,
        textColor: defaultText,
        fontSize: 12,
        fontFamily: '',
        fontDecoration: [],
        borderWidth: 1,
        textAlign: TextAlign.left,
      );
    }
    final colors = map['colors'] as Map<String, dynamic>? ?? {};
    final textStyle = map['textStyle'] as Map<String, dynamic>? ?? {};
    double bw = 1;
    final bwRaw = textStyle['borderwidth'];
    if (bwRaw != null && bwRaw.toString() != 'null') {
      bw = double.tryParse(bwRaw.toString()) ?? 1;
    }
    return OptionStateStyle(
      backgroundColor: _hex(colors['background'] as String? ?? '') ?? defaultBg,
      borderColor: _hex(colors['border'] as String? ?? '') ?? defaultBorder,
      textColor: _hex(colors['text'] as String? ?? '') ?? defaultText,
      fontSize: (textStyle['fontSize'] as num?)?.toDouble() ?? 12,
      fontFamily: textStyle['fontFamily'] as String? ?? '',
      fontDecoration: List<String>.from(
        textStyle['fontDecoration'] as List? ?? [],
      ),
      borderWidth: bw,
      textAlign: TextStyleConfig._parseTextAlign(
        textStyle['textAlign'] as String? ?? 'left',
      ),
    );
  }

  static Color? _hex(String hex) {
    if (hex.isEmpty) return null;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return null;
    }
  }

  bool get isBold => fontDecoration.contains('bold');
  bool get isItalic => fontDecoration.contains('italic');
  bool get isUnderlined => fontDecoration.contains('underline');
}

class AdditionalCommentsConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final double fontSize;
  final double borderWidth;
  final TextAlign textAlign;

  AdditionalCommentsConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.fontSize,
    required this.borderWidth,
    required this.textAlign,
  });

  factory AdditionalCommentsConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return AdditionalCommentsConfig.defaultStyle();
    try {
      final colors = map['colors'] as Map<String, dynamic>? ?? {};
      final textStyle = map['textStyle'] as Map<String, dynamic>? ?? {};
      double bw = 1;
      final bwRaw = textStyle['borderwidth'];
      if (bwRaw != null && bwRaw.toString() != 'null') {
        bw = double.tryParse(bwRaw.toString()) ?? 1;
      }
      return AdditionalCommentsConfig(
        backgroundColor: _hex(colors['background'] as String? ?? '#FFFFFF'),
        borderColor: _hex(colors['border'] as String? ?? '#E5E7EB'),
        textColor: _hex(colors['text'] as String? ?? '#6B7280'),
        fontSize: (textStyle['fontSize'] as num?)?.toDouble() ?? 12,
        borderWidth: bw,
        textAlign: TextStyleConfig._parseTextAlign(
          textStyle['textAlign'] as String? ?? 'left',
        ),
      );
    } catch (_) {
      return AdditionalCommentsConfig.defaultStyle();
    }
  }

  factory AdditionalCommentsConfig.defaultStyle() => AdditionalCommentsConfig(
    backgroundColor: const Color(0xFFF3F4F6),
    borderColor: const Color(0xFFE5E7EB),
    textColor: const Color(0xFF111827),
    fontSize: 12,
    borderWidth: 1,
    textAlign: TextAlign.left,
  );

  static Color _hex(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.black;
    }
  }
}

class OptionsConfig {
  final String optionListStyle;
  final double optionsSpacing;
  final double bulletSpacing;
  final double? optionsHeight;
  final BorderRadius cornerRadius;
  final OptionStateStyle selectedStyle;
  final OptionStateStyle nonSelectedStyle;
  final AdditionalCommentsConfig additionalComments;

  OptionsConfig({
    required this.optionListStyle,
    required this.optionsSpacing,
    required this.bulletSpacing,
    this.optionsHeight,
    required this.cornerRadius,
    required this.selectedStyle,
    required this.nonSelectedStyle,
    required this.additionalComments,
  });

  factory OptionsConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return OptionsConfig.defaultStyle();
    try {
      final crMap = map['cornerRadius'] as Map<String, dynamic>? ?? {};
      return OptionsConfig(
        optionListStyle: map['optionListStyle'] as String? ?? 'number',
        optionsSpacing: (map['optionsSpacing'] as num?)?.toDouble() ?? 12,
        bulletSpacing: (map['bulletSpacing'] as num?)?.toDouble() ?? 12,
        optionsHeight: (map['optionsHeight'] as num?)?.toDouble(),
        cornerRadius: BorderRadius.only(
          topLeft:
              Radius.circular((crMap['topLeft'] as num?)?.toDouble() ?? 12),
          topRight:
              Radius.circular((crMap['topRight'] as num?)?.toDouble() ?? 12),
          bottomLeft:
              Radius.circular((crMap['bottomLeft'] as num?)?.toDouble() ?? 12),
          bottomRight:
              Radius.circular((crMap['bottomRight'] as num?)?.toDouble() ?? 12),
        ),
        selectedStyle: OptionStateStyle.fromMap(
          map['selectedOptions'] as Map<String, dynamic>?,
          defaultBg: const Color(0xFF1e56c8),
          defaultBorder: const Color(0xFF111827),
          defaultText: Colors.white,
        ),
        nonSelectedStyle: OptionStateStyle.fromMap(
          map['nonSelectedOptions'] as Map<String, dynamic>?,
          defaultBg: Colors.white,
          defaultBorder: const Color(0xFFE5E7EB),
          defaultText: const Color(0xFF111827),
        ),
        additionalComments: AdditionalCommentsConfig.fromMap(
          map['additionalComments'] as Map<String, dynamic>?,
        ),
      );
    } catch (_) {
      return OptionsConfig.defaultStyle();
    }
  }

  factory OptionsConfig.defaultStyle() => OptionsConfig(
    optionListStyle: 'number',
    optionsSpacing: 12,
    bulletSpacing: 12,
    optionsHeight: null,
    cornerRadius: BorderRadius.circular(12),
    selectedStyle: OptionStateStyle.fromMap(
      null,
      defaultBg: const Color(0xFF1e56c8),
      defaultBorder: const Color(0xFF111827),
      defaultText: Colors.white,
    ),
    nonSelectedStyle: OptionStateStyle.fromMap(
      null,
      defaultBg: Colors.white,
      defaultBorder: const Color(0xFFE5E7EB),
      defaultText: const Color(0xFF111827),
    ),
    additionalComments: AdditionalCommentsConfig.fromMap(null),
  );
}

// ── Parsed view of the campaign details (Flutter layer only) ──────────────────
// Wraps SurveyDetails + builds Flutter-specific styling configs from the raw map.

class _SurveyViewModel {
  final String id;
  final String name;
  final List<SurveySlide> slides;
  final Map<String, dynamic> styling; // raw styling map for UI helpers
  final String thankYouTitle;
  final String thankYouSubtitle;
  final String thankYouText;
  final String? thankYouImageUrl;
  final String thankYouButtonText;
  final bool thankYouButtonEnabled;
  final String thankYouButtonAction;
  final String? thankYouButtonRedirectUrl;
  final AppearanceConfig appearanceConfig;
  final OptionsConfig optionsConfig;
  final TextStyleConfig titleStyle;
  final TextStyleConfig subtitleStyle;

  _SurveyViewModel({
    required this.id,
    required this.name,
    required this.slides,
    required this.styling,
    required this.thankYouTitle,
    required this.thankYouSubtitle,
    required this.thankYouText,
    this.thankYouImageUrl,
    required this.thankYouButtonText,
    required this.thankYouButtonEnabled,
    required this.thankYouButtonAction,
    this.thankYouButtonRedirectUrl,
    required this.appearanceConfig,
    required this.optionsConfig,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  factory _SurveyViewModel.fromDetails(SurveyDetails d) {
    final stylingRaw = d.styling.raw;
    return _SurveyViewModel(
      id: d.id,
      name: d.name,
      slides: d.slides,
      styling: stylingRaw,
      thankYouTitle: d.thankYouTitle,
      thankYouSubtitle: d.thankYouSubtitle,
      thankYouText: d.thankYouText,
      thankYouImageUrl: d.thankYouImage,
      thankYouButtonText: d.thankYouButtonText,
      thankYouButtonEnabled: d.thankYouButtonConfig.enabled,
      thankYouButtonAction: d.thankYouButtonConfig.action,
      thankYouButtonRedirectUrl: d.thankYouButtonConfig.redirectUrl,
      appearanceConfig: AppearanceConfig.fromModel(d.styling.appearance),
      optionsConfig: OptionsConfig.fromMap(
        stylingRaw['options'] as Map<String, dynamic>?,
      ),
      titleStyle: TextStyleConfig.fromMap(
        (stylingRaw['title']?['textStyle']) as Map<String, dynamic>?,
      ),
      subtitleStyle: TextStyleConfig.fromMap(
        (stylingRaw['subtitle']?['textStyle']) as Map<String, dynamic>?,
      ),
    );
  }

  ThankYouTextStyleConfig get thankYouTitleStyle {
    final tyPage = styling['thankyouPage'] as Map<String, dynamic>? ?? {};
    return ThankYouTextStyleConfig(
      style: TextStyleConfig.fromMap(
        tyPage['title']?['textStyle'] as Map<String, dynamic>?,
      ),
      imageStyleMap:
          tyPage['imageStyle'] as Map<String, dynamic>? ?? {},
      cta: tyPage['cta'] as Map<dynamic, dynamic>?,
    );
  }

  ThankYouTextStyleConfig get thankYouSubtitleStyleCfg {
    final tyPage = styling['thankyouPage'] as Map<String, dynamic>? ?? {};
    return ThankYouTextStyleConfig(
      style: TextStyleConfig.fromMap(
        tyPage['subtitle']?['textStyle'] as Map<String, dynamic>?,
      ),
      imageStyleMap: {},
      cta: null,
    );
  }
}

class ThankYouTextStyleConfig {
  final TextStyleConfig style;
  final Map<String, dynamic> imageStyleMap;
  final Map<dynamic, dynamic>? cta;

  ThankYouTextStyleConfig({
    required this.style,
    required this.imageStyleMap,
    this.cta,
  });
}

// ─── Survey Sheet UI ──────────────────────────────────────────────────────────

class _SurveySheet extends StatefulWidget {
  final SurveyCampaign campaign;
  final AppstorysFlutter appStorys;
  final VoidCallback onDismiss;
  final void Function(String)? onLinkTap;

  const _SurveySheet({
    required this.campaign,
    required this.appStorys,
    required this.onDismiss,
    this.onLinkTap,
  });

  @override
  State<_SurveySheet> createState() => _SurveySheetState();
}

class _SurveySheetState extends State<_SurveySheet> {
  _SurveyViewModel? _vm;
  SurveySlide? currentSlide;

  int currentSlideIndex = 0;
  List<String> selectedOptions = [];
  bool showSurvey = false;
  bool showThankYouPage = false;

  final List<int> _slideHistory = [0];
  final TextEditingController _commentController = TextEditingController();

  late Offset _swipeStartPosition;
  static const double _swipeThreshold = 80.0;
  String _lastSwipeDirection = '';

  String? _resolvedTitleFont;
  String? _resolvedSubtitleFont;
  String? _resolvedThankYouTitleFont;
  String? _resolvedThankYouSubtitleFont;
  String? _resolvedSelectedOptionFont;
  String? _resolvedNonSelectedOptionFont;

  Color _hex(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.black;
    }
  }

  Future<void> _loadFont(String? raw, void Function(String?) onResolved) async {
    if (raw == null || raw.trim().isEmpty) return;
    final loaded = await FontCache.resolveFontFamily(raw);
    if (mounted) setState(() => onResolved(loaded));
  }

  Future<void> _loadFonts() async {
    final vm = _vm;
    if (vm == null) return;
    await _loadFont(vm.titleStyle.fontFamily, (v) => _resolvedTitleFont = v);
    await _loadFont(
      vm.subtitleStyle.fontFamily,
      (v) => _resolvedSubtitleFont = v,
    );
    await _loadFont(
      vm.thankYouTitleStyle.style.fontFamily,
      (v) => _resolvedThankYouTitleFont = v,
    );
    await _loadFont(
      vm.thankYouSubtitleStyleCfg.style.fontFamily,
      (v) => _resolvedThankYouSubtitleFont = v,
    );
    await _loadFont(
      vm.optionsConfig.selectedStyle.fontFamily,
      (v) => _resolvedSelectedOptionFont = v,
    );
    await _loadFont(
      vm.optionsConfig.nonSelectedStyle.fontFamily,
      (v) => _resolvedNonSelectedOptionFont = v,
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeSurvey();
  }

  void _initializeSurvey() {
    try {
      _vm = _SurveyViewModel.fromDetails(widget.campaign.details);
      if (_vm!.slides.isEmpty) return;
      currentSlide = _vm!.slides.first;
      _loadFonts();
      setState(() => showSurvey = true);
    } catch (e, st) {
      debugPrint('❌ [SURVEY] _initializeSurvey: $e\n$st');
    }
  }

  void _trackEvent(String event, [Map<String, dynamic>? metadata]) {
    final id = widget.campaign.id;
    if (id.isEmpty) return;
    widget.appStorys
        .trackEvent(event: event, campaignId: id, metadata: metadata)
        .catchError((_) {});
  }

  void _trackViewedEvent() {
    _trackEvent('viewed', {
      'survey_id': _vm?.id ?? '',
      'slide_id': currentSlide?.id ?? '',
    });
  }

  void _trackClickedAnalytics({
    required List<String> selectedValues,
    required String comment,
  }) {
    final optionKeys = selectedValues.where((v) => v != 'Others').map((text) {
      final entry = currentSlide?.options.entries
          .firstWhere((e) => e.value == text, orElse: () => MapEntry('', text));
      return entry?.key.isNotEmpty == true ? entry!.key : text;
    }).toList();

    if (optionKeys.isNotEmpty) {
      _trackEvent('clicked', {
        'survey_id': _vm?.id ?? '',
        'slide_id': currentSlide?.id ?? '',
        'selected_options': optionKeys,
      });
    }
    if (comment.isNotEmpty) {
      _trackEvent('clicked', {
        'survey_id': _vm?.id ?? '',
        'slide_id': currentSlide?.id ?? '',
        'additional_comment': comment,
      });
    }
  }

  void _trackSurveySubmittedEvent() {
    _trackEvent('SurveySubmitted', {
      'survey_id': _vm?.id ?? '',
      'slide_id': _vm?.slides.lastOrNull?.id ?? '',
    });
  }

  void _trackSurveyDismissedEvent() {
    _trackEvent('SurveyDismissed', {
      'survey_id': _vm?.id ?? '',
      'slide_id': _vm?.slides.lastOrNull?.id ?? '',
    });
  }

  void _trackThankYouCTAClickedEvent() {
    _trackEvent('ThankYouCTAClicked', {
      'survey_id': _vm?.id ?? '',
      'slide_id': _vm?.slides.lastOrNull?.id ?? '',
    });
  }

  void _handleThankYouButtonAction() {
    _trackThankYouCTAClickedEvent();
    final vm = _vm!;
    if (vm.thankYouButtonAction.toLowerCase() == 'redirect' &&
        vm.thankYouButtonRedirectUrl != null &&
        vm.thankYouButtonRedirectUrl!.isNotEmpty) {
      widget.appStorys.viaAppStorys(vm.thankYouButtonRedirectUrl!).catchError((_) {});
      LinkHandler.handle(vm.thankYouButtonRedirectUrl, widget.onLinkTap);
    }
    widget.onDismiss();
  }

  int? _getNextSlideByLogic(List<String> selected) {
    final logic = currentSlide?.logic;
    if (logic == null || logic.isEmpty) return null;

    final selectedValue = selected.firstOrNull;
    if (selectedValue == null) return null;

    SurveyLogic? matchedRule;
    for (final rule in logic) {
      if (rule.selectOption.contains(selectedValue)) {
        matchedRule = rule;
        break;
      }
    }
    if (matchedRule == null) return null;

    final redirectTo = matchedRule.redirectTo;
    if (redirectTo == null) return null;
    if (redirectTo == 'thank_you' || redirectTo == 'thank-you') return -1;

    final slides = _vm!.slides;
    final byId = slides.indexWhere((s) => s.id == redirectTo);
    if (byId != -1) return byId;

    final byTitle = slides.indexWhere(
      (s) => s.title.toLowerCase() == redirectTo.toLowerCase(),
    );
    if (byTitle != -1) return byTitle;

    final numMatch =
        RegExp(r'^(?:[Qq]uestion|[Ss]lide)\s*(\d+)$').firstMatch(redirectTo);
    if (numMatch != null) {
      final n = int.tryParse(numMatch.group(1) ?? '');
      if (n != null) {
        final idx = n - 1;
        if (idx >= 0 && idx < slides.length) return idx;
      }
    }
    return null;
  }

  String _getOptionPrefix(int index, String style) {
    switch (style.toLowerCase()) {
      case 'number':
        return '${index + 1}.';
      case 'alpha':
      case 'alphabetic':
      case 'alphabet':
        return '${String.fromCharCode(65 + index)}.';
      case 'roman':
        return '${_toRoman(index + 1)}.';
      default:
        return '${index + 1}.';
    }
  }

  String _toRoman(int n) {
    const vals = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    const syms = [
      'M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I',
    ];
    final sb = StringBuffer();
    for (int i = 0; i < vals.length; i++) {
      while (n >= vals[i]) {
        sb.write(syms[i]);
        n -= vals[i];
      }
    }
    return sb.toString().toLowerCase();
  }

  void _previousSlide() {
    if (_slideHistory.length <= 1) return;
    _slideHistory.removeLast();
    final prevIndex = _slideHistory.last;
    setState(() {
      currentSlideIndex = prevIndex;
      currentSlide = _vm!.slides[currentSlideIndex];
      selectedOptions.clear();
      _commentController.clear();
    });
    _trackViewedEvent();
  }

  void _nextSlide() {
    if (selectedOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one option')),
      );
      return;
    }

    final currentSelected = List<String>.from(selectedOptions);
    final comment = _commentController.text;
    final slides = _vm!.slides;
    final isLastSlide = currentSlideIndex == slides.length - 1;

    final logicResult = _getNextSlideByLogic(currentSelected);
    final isThankYouRedirect = logicResult == -1;
    final redirectTargetIndex =
        (logicResult != null && logicResult >= 0) ? logicResult : null;

    _trackClickedAnalytics(selectedValues: currentSelected, comment: comment);

    if (isThankYouRedirect) {
      _submitSurvey(currentSelected, comment);
    } else if (redirectTargetIndex != null) {
      _slideHistory.add(redirectTargetIndex);
      setState(() {
        currentSlideIndex = redirectTargetIndex;
        currentSlide = slides[currentSlideIndex];
        selectedOptions.clear();
        _commentController.clear();
      });
      _trackViewedEvent();
    } else if (isLastSlide) {
      _submitSurvey(currentSelected, comment);
    } else {
      final nextPage = currentSlideIndex + 1;
      _slideHistory.add(nextPage);
      setState(() {
        currentSlideIndex = nextPage;
        currentSlide = slides[currentSlideIndex];
        selectedOptions.clear();
        _commentController.clear();
      });
      _trackViewedEvent();
    }
  }

  void _submitSurvey(List<String> options, String comment) {
    _trackSurveySubmittedEvent();

    widget.appStorys.getUserId().then((uid) {
      if (uid != null && uid.isNotEmpty) {
        final responseOptions = options.where((o) => o != 'Others').toList();
        final finalComment = comment.isNotEmpty ? comment : null;
        widget.appStorys
            .captureSurveyResponse(
              surveyId: widget.campaign.details.id,
              userId: uid,
              responseOptions: responseOptions.isNotEmpty
                  ? responseOptions
                  : ['Others'],
              comment: finalComment,
            )
            .catchError((_) {});
      }
    });

    if (_vm!.thankYouButtonEnabled) {
      setState(() => showThankYouPage = true);
    } else {
      widget.onDismiss();
    }
  }

  void _closeSurvey() {
    _trackSurveyDismissedEvent();
    widget.onDismiss();
  }

  void _onHorizontalDragStart(DragStartDetails d) {
    _swipeStartPosition = d.globalPosition;
    _lastSwipeDirection = '';
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    final diff = _swipeStartPosition.dx - d.globalPosition.dx;
    if (diff > _swipeThreshold && _lastSwipeDirection != 'left') {
      _lastSwipeDirection = 'left';
      if (selectedOptions.isNotEmpty) _nextSlide();
    } else if (diff < -_swipeThreshold && _lastSwipeDirection != 'right') {
      _lastSwipeDirection = 'right';
      _previousSlide();
    }
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dx;
    if (v > 500 && _lastSwipeDirection == '') _previousSlide();
    if (v < -500 && _lastSwipeDirection == '' && selectedOptions.isNotEmpty) {
      _nextSlide();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!showSurvey || _vm == null || currentSlide == null) {
      return const SizedBox.shrink();
    }
    return showThankYouPage ? _buildThankYouSheet() : _buildSurveySheet();
  }

  Widget _buildSurveySheet() {
    final vm = _vm!;
    final slide = currentSlide!;
    final appearance = vm.appearanceConfig;
    final optCfg = vm.optionsConfig;

    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Container(
        decoration: BoxDecoration(
          color: appearance.backgroundColor,
          borderRadius: appearance.cornerRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(vm.styling),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        slide.title,
                        textAlign: vm.titleStyle.textAlign,
                        style: _buildTextStyle(
                          vm.titleStyle,
                          resolvedFont: _resolvedTitleFont,
                        ),
                      ),
                    ),

                    if (slide.subtitle.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          slide.subtitle,
                          textAlign: vm.subtitleStyle.textAlign,
                          style: _buildTextStyle(
                            vm.subtitleStyle,
                            resolvedFont: _resolvedSubtitleFont,
                          ),
                        ),
                      ),

                    ...slide.options.entries.toList().asMap().entries.map((
                      entry,
                    ) {
                      final idx = entry.key;
                      final optionText = entry.value.value;
                      final isSelected = selectedOptions.contains(optionText);
                      return Padding(
                        padding: EdgeInsets.only(bottom: optCfg.optionsSpacing),
                        child: _buildOptionButton(
                          optionText: optionText,
                          isSelected: isSelected,
                          optCfg: optCfg,
                          prefix: _getOptionPrefix(idx, optCfg.optionListStyle),
                        ),
                      );
                    }),

                    if (slide.additionalComment?.enabled == true)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: optCfg.optionsSpacing,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOthersButton(
                              isSelected: selectedOptions.contains('Others'),
                              optCfg: optCfg,
                              othersIndex: slide.options.length,
                            ),
                            if (selectedOptions.contains('Others'))
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _buildAdditionalTextField(
                                  slide: slide,
                                  addlCfg: optCfg.additionalComments,
                                ),
                              ),
                          ],
                        ),
                      ),

                    CtaButton(
                      text: slide.submitButtonText.isNotEmpty
                          ? slide.submitButtonText
                          : (currentSlideIndex == vm.slides.length - 1
                              ? 'Submit'
                              : 'Next'),
                      onTap: _nextSlide,
                      styling: vm.styling['cta'] as Map<dynamic, dynamic>?,
                    ),

                    _buildProgressDots(optCfg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThankYouSheet() {
    final vm = _vm!;
    final appearance = vm.appearanceConfig;
    final tyCfg = vm.thankYouTitleStyle;
    final tySubCfg = vm.thankYouSubtitleStyleCfg;

    final imgStyleMap = tyCfg.imageStyleMap;
    final imgH = (imgStyleMap['height'] as num?)?.toDouble() ?? 80;
    final imgW = (imgStyleMap['width'] as num?)?.toDouble() ?? 80;
    final imgMargMap = imgStyleMap['margin'] as Map<String, dynamic>? ?? {};
    final imgMargin = EdgeInsets.only(
      top: (imgMargMap['top'] as num?)?.toDouble() ?? 0,
      bottom: (imgMargMap['bottom'] as num?)?.toDouble() ?? 16,
      left: (imgMargMap['left'] as num?)?.toDouble() ?? 0,
      right: (imgMargMap['right'] as num?)?.toDouble() ?? 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: appearance.backgroundColor,
        borderRadius: appearance.cornerRadius,
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTopBar(vm.styling),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (vm.thankYouImageUrl?.isNotEmpty == true)
                    Padding(
                      padding: imgMargin,
                      child: _buildThankYouMedia(
                        url: vm.thankYouImageUrl!,
                        width: imgW,
                        height: imgH,
                      ),
                    ),
                  if (vm.thankYouTitle.isNotEmpty)
                    Padding(
                      padding: tyCfg.style.margin,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          vm.thankYouTitle,
                          textAlign: tyCfg.style.textAlign,
                          style: _buildTextStyle(
                            tyCfg.style,
                            resolvedFont: _resolvedThankYouTitleFont,
                          ),
                        ),
                      ),
                    ),
                  if (vm.thankYouText.isNotEmpty)
                    Padding(
                      padding: tySubCfg.style.margin,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          vm.thankYouText,
                          textAlign: tySubCfg.style.textAlign,
                          style: _buildTextStyle(
                            tySubCfg.style,
                            resolvedFont: _resolvedThankYouSubtitleFont,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (vm.thankYouButtonEnabled)
                    CtaButton(
                      text: vm.thankYouButtonText,
                      onTap: _handleThankYouButtonAction,
                      styling: tyCfg.cta,
                    ),
                  if (vm.thankYouButtonEnabled) const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThankYouMedia({
    required String url,
    required double width,
    required double height,
  }) {
    if (url.endsWith('.json')) {
      return SizedBox(
        width: width,
        height: height,
        child: Lottie.network(
          url,
          width: width,
          height: height,
          fit: BoxFit.contain,
          repeat: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildTopBar(Map<String, dynamic> styling) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CrossButton(
            onTap: _closeSurvey,
            styling: styling['crossButton'] as Map<dynamic, dynamic>?,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String optionText,
    required bool isSelected,
    required OptionsConfig optCfg,
    required String prefix,
  }) {
    final st = isSelected ? optCfg.selectedStyle : optCfg.nonSelectedStyle;
    return GestureDetector(
      onTap: () => setState(
        () => isSelected
            ? selectedOptions.remove(optionText)
            : selectedOptions.add(optionText),
      ),
      child: Container(
        height: optCfg.optionsHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: st.backgroundColor,
          border: Border.all(color: st.borderColor, width: st.borderWidth),
          borderRadius: optCfg.cornerRadius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildBullet(
              isSelected: isSelected,
              optCfg: optCfg,
              prefix: prefix,
              st: st,
            ),
            SizedBox(width: optCfg.bulletSpacing),
            Expanded(
              child: Text(
                optionText,
                textAlign: st.textAlign,
                style: _buildOptionTextStyle(
                  st,
                  resolvedFont: isSelected
                      ? _resolvedSelectedOptionFont
                      : _resolvedNonSelectedOptionFont,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOthersButton({
    required bool isSelected,
    required OptionsConfig optCfg,
    required int othersIndex,
  }) {
    final st = isSelected ? optCfg.selectedStyle : optCfg.nonSelectedStyle;
    final prefix = _getOptionPrefix(othersIndex, optCfg.optionListStyle);
    return GestureDetector(
      onTap: () => setState(
        () => isSelected
            ? selectedOptions.remove('Others')
            : selectedOptions.add('Others'),
      ),
      child: Container(
        height: optCfg.optionsHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: st.backgroundColor,
          border: Border.all(color: st.borderColor, width: st.borderWidth),
          borderRadius: optCfg.cornerRadius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildBullet(
              isSelected: isSelected,
              optCfg: optCfg,
              prefix: prefix,
              st: st,
            ),
            SizedBox(width: optCfg.bulletSpacing),
            Expanded(
              child: Text(
                'Others',
                textAlign: st.textAlign,
                style: _buildOptionTextStyle(
                  st,
                  resolvedFont: isSelected
                      ? _resolvedSelectedOptionFont
                      : _resolvedNonSelectedOptionFont,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet({
    required bool isSelected,
    required OptionsConfig optCfg,
    required String prefix,
    required OptionStateStyle st,
  }) {
    if (optCfg.optionListStyle.toLowerCase() == 'bulleted') {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: st.borderColor, width: st.borderWidth),
          color: isSelected ? st.borderColor : Colors.transparent,
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: st.backgroundColor,
                  ),
                ),
              )
            : null,
      );
    }
    return Text(
      prefix,
      style: TextStyle(
        color: st.textColor,
        fontSize: st.fontSize,
        fontWeight: FontWeight.w600,
        fontFamily: st.fontFamily.isNotEmpty ? st.fontFamily : null,
      ),
    );
  }

  Widget _buildAdditionalTextField({
    required SurveySlide slide,
    required AdditionalCommentsConfig addlCfg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: addlCfg.backgroundColor,
        border: Border.all(
          color: addlCfg.borderColor,
          width: addlCfg.borderWidth,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _commentController,
        maxLines: 3,
        maxLength: 200,
        textAlign: addlCfg.textAlign,
        style: TextStyle(color: addlCfg.textColor, fontSize: addlCfg.fontSize),
        decoration: InputDecoration(
          hintText: slide.additionalComment?.placeholder.isNotEmpty == true
              ? slide.additionalComment!.placeholder
              : 'Please enter details (max 200 characters)',
          hintStyle: TextStyle(
            color: addlCfg.textColor.withValues(alpha: 0.6),
            fontSize: addlCfg.fontSize,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildProgressDots(OptionsConfig optCfg) {
    final vm = _vm!;
    final activeDotColor = _hex(
      vm.styling['cta']?['container']?['backgroundColor'] as String? ??
          '#1f35db',
    );
    final inactiveDotColor = optCfg.nonSelectedStyle.borderColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(vm.slides.length, (index) {
        final isActive = index == currentSlideIndex;
        return GestureDetector(
          onTap: () {
            if (selectedOptions.isNotEmpty || index < currentSlideIndex) {
              setState(() {
                currentSlideIndex = index;
                currentSlide = vm.slides[index];
                selectedOptions.clear();
                _commentController.clear();
              });
              _trackViewedEvent();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? activeDotColor : inactiveDotColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }

  TextStyle _buildTextStyle(TextStyleConfig cfg, {String? resolvedFont}) =>
      TextStyle(
        color: cfg.color,
        fontSize: cfg.fontSize,
        fontWeight: cfg.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: cfg.isItalic ? FontStyle.italic : FontStyle.normal,
        decoration:
            cfg.isUnderlined ? TextDecoration.underline : TextDecoration.none,
        fontFamily: resolvedFont,
      );

  TextStyle _buildOptionTextStyle(
    OptionStateStyle st, {
    String? resolvedFont,
  }) =>
      TextStyle(
        color: st.textColor,
        fontSize: st.fontSize,
        fontWeight: st.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: st.isItalic ? FontStyle.italic : FontStyle.normal,
        decoration:
            st.isUnderlined ? TextDecoration.underline : TextDecoration.none,
        fontFamily: resolvedFont,
      );
}
