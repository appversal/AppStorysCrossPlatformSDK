import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../appstorys_flutter.dart';
import '../common/cross_button.dart';
import '../common/cta_button.dart';
import '../utils/font_cache.dart';

export '../models/csat_models.dart';

// ─── KMP Entry Widget ─────────────────────────────────────────────────────────
// Subscribes to the campaigns stream and shows CSAT campaigns as a modal bottom
// sheet. Add to AppStorysOverlay or your widget tree directly.

class AppStorysCsat extends StatefulWidget {
  final AppstorysFlutter appStorys;
  final void Function(String)? onLinkTap;

  const AppStorysCsat({
    super.key,
    required this.appStorys,
    this.onLinkTap,
  });

  @override
  State<AppStorysCsat> createState() => _AppStorysCsatState();
}

class _AppStorysCsatState extends State<AppStorysCsat>
    with CampaignsStreamMixin {
  bool _showing = false;
  String? _currentCampaignId;

  @override
  void initState() {
    super.initState();
    subscribeToCampaigns(widget.appStorys.campaignsStream, _handleCampaigns);
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
        backgroundColor: Colors.transparent,
        barrierColor: bdColor,
        builder: (ctx) => _CsatSheet(
          campaign: campaign,
          appStorys: widget.appStorys,
          onLinkTap: widget.onLinkTap,
          onDismiss: () => Navigator.of(ctx).pop(),
        ),
      ).then((_) {
        if (mounted) _showing = false;
        if (campaign.id.isNotEmpty) {
          widget.appStorys.dismissCampaign(campaign.id).catchError((_) {});
        }
      });
    });
  }

  CsatCampaign? _parseCampaign(String json) {
    try {
      final data = jsonDecode(json) as List<dynamic>;
      final raw = data.whereType<Map>().firstWhere(
        (c) => c['campaign_type'] == 'CSAT',
        orElse: () => {},
      );
      if (raw.isEmpty) return null;
      return CsatCampaign.fromJson(Map<String, dynamic>.from(raw));
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

// ─── CSAT Sheet UI ────────────────────────────────────────────────────────────

class _CsatSheet extends StatefulWidget {
  final CsatCampaign campaign;
  final AppstorysFlutter appStorys;
  final VoidCallback onDismiss;
  final void Function(String)? onLinkTap;

  const _CsatSheet({
    required this.campaign,
    required this.appStorys,
    required this.onDismiss,
    this.onLinkTap,
  });

  @override
  State<_CsatSheet> createState() => _CsatSheetState();
}

class _CsatSheetState extends State<_CsatSheet> {
  late Map<String, dynamic> _styling;

  int selectedStars = 0;
  bool showThanks = false;
  bool showFeedback = false;
  String? selectedOption;
  String? selectedOptionId;

  String? _resolvedTitleFont;
  String? _resolvedSubtitleFont;
  String? _resolvedThankyouTitleFont;
  String? _resolvedThankyouSubtitleFont;
  String? _resolvedOptionTextFont;
  String? _resolvedSelectedOptionTextFont;

  final TextEditingController _textcontroller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final details = widget.campaign.details;
    _styling = _flattenStyling(
      details.styling.raw,
      detailsHeight: details.height,
      detailsWidth: details.width,
    );
    _loadFonts();
    _commentFocusNode.addListener(_onCommentFocus);
  }

  void _onCommentFocus() {
    if (_commentFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _textcontroller.dispose();
    _scrollController.dispose();
    _commentFocusNode
      ..removeListener(_onCommentFocus)
      ..dispose();
    super.dispose();
  }

  void _trackEvent(String event, [Map<String, Object?>? metadata]) {
    final id = widget.campaign.id;
    if (id.isEmpty) return;
    widget.appStorys
        .trackEvent(event: event, campaignId: id, metadata: metadata)
        .catchError((_) {});
  }

  Future<void> _loadFont(
    String? raw,
    void Function(String?) onResolved,
  ) async {
    if (raw == null || raw.trim().isEmpty) return;
    final loaded = await FontCache.resolveFontFamily(raw);
    if (mounted) setState(() => onResolved(loaded));
  }

  Future<void> _loadFonts() async {
    await _loadFont(
      _styling['csatTitleFont']?.toString(),
      (v) => _resolvedTitleFont = v,
    );
    await _loadFont(
      _styling['csatDescriptionFont']?.toString(),
      (v) => _resolvedSubtitleFont = v,
    );
    await _loadFont(
      _styling['thankyouTitleFont']?.toString(),
      (v) => _resolvedThankyouTitleFont = v,
    );
    await _loadFont(
      _styling['thankyouSubtitleFont']?.toString(),
      (v) => _resolvedThankyouSubtitleFont = v,
    );
    await _loadFont(
      _styling['csatOptionTextFont']?.toString(),
      (v) => _resolvedOptionTextFont = v,
    );
    await _loadFont(
      _styling['csatSelectedOptionTextFont']?.toString(),
      (v) => _resolvedSelectedOptionTextFont = v,
    );
  }

  // ── Styling flattener ─────────────────────────────────────────────────────

  num? _parseToNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  Map<String, dynamic> _flattenStyling(
    Map<String, dynamic> styling, {
    num? detailsHeight,
    num? detailsWidth,
  }) {
    return {
      'csatBackgroundColor':
          styling['appearance']?['backgroundColor'] ?? '#FFFFFF',
      'displayDelay': styling['appearance']?['displayDelay'] ?? 0,
      'csatBorderRadius': styling['appearance']?['borderRadius'] ?? 4,
      'csatHeight': detailsHeight != null
          ? detailsHeight.toString()
          : (styling['appearance']?['height']?.toString() ?? ''),
      'csatWidth': detailsWidth != null
          ? detailsWidth.toString()
          : (styling['appearance']?['width']?.toString() ?? ''),
      'csatMarginTop': styling['appearance']?['margin']?['top'] ?? 0,
      'csatMarginBottom': styling['appearance']?['margin']?['bottom'] ?? 0,
      'csatMarginLeft': styling['appearance']?['margin']?['left'] ?? 0,
      'csatMarginRight': styling['appearance']?['margin']?['right'] ?? 0,
      'csatPaddingTop': styling['appearance']?['padding']?['top'] ?? 10,
      'csatPaddingBottom': styling['appearance']?['padding']?['bottom'] ?? 20,
      'csatPaddingLeft': styling['appearance']?['padding']?['left'] ?? 10,
      'csatPaddingRight': styling['appearance']?['padding']?['right'] ?? 10,

      'csatTitleColor':
          styling['initialFeedback']?['title']?['textStyle']?['color'] ??
              '#000000',
      'csatTitleAlignment':
          styling['initialFeedback']?['title']?['textStyle']?['textAlign'] ??
              'center',
      'csatTitleFont':
          styling['initialFeedback']?['title']?['textStyle']?['fontFamily'] ??
              'Arial',
      'csatTitleSize':
          styling['initialFeedback']?['title']?['textStyle']?['fontSize'] ?? 12,
      'csatTitleDecoration':
          styling['initialFeedback']?['title']?['textStyle']
              ?['fontDecoration'] ??
              [],

      'csatDescriptionTextColor':
          styling['initialFeedback']?['subtitle']?['textStyle']?['color'] ??
              '#666666',
      'csatDescriptionAlignment':
          styling['initialFeedback']?['subtitle']?['textStyle']?['textAlign'] ??
              'center',
      'csatDescriptionFont':
          styling['initialFeedback']?['subtitle']?['textStyle']
              ?['fontFamily'] ??
              'Arial',
      'csatDescriptionSize':
          styling['initialFeedback']?['subtitle']?['textStyle']?['fontSize'] ??
              12,
      'csatDescriptionDecoration':
          styling['initialFeedback']?['subtitle']?['textStyle']
              ?['fontDecoration'] ??
              [],

      'csatRatingType': styling['rating']?['ratingType'] ?? 'star',
      'csatRatingDisplayText': styling['rating']?['displayText'] ?? 'same',
      'csatRatingAlignment': styling['rating']?['alignment'] ?? 'center',

      'csatHighStarColor':
          styling['rating']?['star']?['high']?['stylingStar']?['background'] ??
              '#FFD700',
      'csatHighStarBorder':
          styling['rating']?['star']?['high']?['stylingStar']?['border'] ??
              '#DAA520',
      'csatHighStarBorderWidth':
          styling['rating']?['star']?['high']?['stylingStar']?['borderWidth'] ??
              0,
      'csatLowStarColor':
          styling['rating']?['star']?['low']?['stylingStar']?['background'] ??
              '#FF6B35',
      'csatLowStarBorder':
          styling['rating']?['star']?['low']?['stylingStar']?['border'] ??
              '#FF4500',
      'csatLowStarBorderWidth':
          styling['rating']?['star']?['low']?['stylingStar']?['borderWidth'] ??
              0,
      'csatUnselectedStarColor':
          styling['rating']?['star']?['unselected']?['stylingStar']
              ?['background'] ??
              '#CCCCCC',
      'csatUnselectedStarBorder':
          styling['rating']?['star']?['unselected']?['stylingStar']?['border'] ??
              '#999999',
      'csatUnselectedStarBorderWidth':
          styling['rating']?['star']?['unselected']?['stylingStar']
              ?['borderWidth'] ??
              0,

      'csatEmojiValues':
          styling['rating']?['emoji']?['values'] ??
              ['😞', '😕', '😐', '🙂', '😄'],
      'csatEmojiSelectedBackground':
          styling['rating']?['emoji']?['selected']?['stylingContainer']
              ?['fill'] ??
              '#fff3ed',
      'csatEmojiSelectedBorder':
          styling['rating']?['emoji']?['selected']?['stylingContainer']
              ?['border'] ??
              '#ff4400',
      'csatEmojiSelectedBorderWidth':
          styling['rating']?['emoji']?['selected']?['stylingContainer']
              ?['borderWidth'] ??
              2,
      'csatEmojiUnselectedBackground':
          styling['rating']?['emoji']?['unselected']?['stylingContainer']
              ?['fill'] ??
              '#f0f0f0',
      'csatEmojiUnselectedBorder':
          styling['rating']?['emoji']?['unselected']?['stylingContainer']
              ?['border'] ??
              '#908989',
      'csatEmojiUnselectedBorderWidth':
          styling['rating']?['emoji']?['unselected']?['stylingContainer']
              ?['borderWidth'] ??
              1,
      'csatEmojiSize': 38.0,
      'csatEmojiContainerPadding':
          styling['rating']?['emoji']?['containerPadding'] ?? 8.0,

      'csatNumberHighBackground':
          styling['rating']?['number']?['high']?['stylingContainer']?['fill'] ??
              '#42e6f5',
      'csatNumberHighBorder':
          styling['rating']?['number']?['high']?['stylingContainer']
              ?['border'] ??
              '#f75555',
      'csatNumberHighBorderWidth':
          styling['rating']?['number']?['high']?['stylingContainer']
              ?['borderWidth'] ??
              0,
      'csatNumberLowBackground':
          styling['rating']?['number']?['low']?['stylingContainer']?['fill'] ??
              '#87ff66',
      'csatNumberLowBorder':
          styling['rating']?['number']?['low']?['stylingContainer']?['border'] ??
              '#ff4242',
      'csatNumberLowBorderWidth':
          styling['rating']?['number']?['low']?['stylingContainer']
              ?['borderWidth'] ??
              1,
      'csatNumberUnselectedBackground':
          styling['rating']?['number']?['unselected']?['stylingContainer']
              ?['fill'] ??
              '#ededed',
      'csatNumberUnselectedBorder':
          styling['rating']?['number']?['unselected']?['stylingContainer']
              ?['border'] ??
              '#FE6B35',
      'csatNumberUnselectedBorderWidth':
          styling['rating']?['number']?['unselected']?['stylingContainer']
              ?['borderWidth'] ??
              0,
      'csatNumberTextColor':
          styling['rating']?['number']?['unselected']?['stylingNumber']
              ?['text'] ??
              '#FE6B35',
      'csatNumberSize': 24.0,

      'csatHighRatingTitle': styling['rating']?['highRatingTitle'] ?? '',
      'csatHighRatingSubtitle': styling['rating']?['highRatingSubtitle'] ?? '',
      'csatLowRatingTitle': styling['rating']?['lowRatingTitle'] ?? '',
      'csatLowRatingSubtitle': styling['rating']?['lowRatingSubtitle'] ?? '',

      // ── Feedback options ────────────────────────────────────────────────────
      'csatOptionBoxColour':
          styling['feedbackPage']?['options']?['nonSelectedOptions']?['colors']
              ?['background'] ??
              '#F5F5F5',
      'csatOptionStrokeColor':
          styling['feedbackPage']?['options']?['nonSelectedOptions']?['colors']
              ?['border'] ??
              '#DDDDDD',
      'csatOptionTextColour':
          styling['feedbackPage']?['options']?['nonSelectedOptions']?['colors']
              ?['text'] ??
              '#000000',
      'csatOptionTextAlignment':
          styling['feedbackPage']?['options']?['nonSelectedOptions']
              ?['textStyle']?['textAlign'] ??
              'center',
      'csatOptionTextFont':
          styling['feedbackPage']?['options']?['nonSelectedOptions']
              ?['textStyle']?['fontFamily'],
      'csatOptionTextSize':
          styling['feedbackPage']?['options']?['nonSelectedOptions']
              ?['textStyle']?['fontSize'] ??
              12,
      'csatOptionTextDecoration':
          styling['feedbackPage']?['options']?['nonSelectedOptions']
              ?['textStyle']?['fontDecoration'] ??
              [],

      'csatSelectedOptionBackgroundColor':
          styling['feedbackPage']?['options']?['selectedOptions']?['colors']
              ?['background'] ??
              '#FE6B35',
      'csatSelectedOptionStrokeColor':
          styling['feedbackPage']?['options']?['selectedOptions']?['colors']
              ?['border'] ??
              '#FE6B35',
      'csatSelectedOptionTextColor':
          styling['feedbackPage']?['options']?['selectedOptions']?['colors']
              ?['text'] ??
              '#FFFFFF',
      'csatSelectedOptionTextAlignment':
          styling['feedbackPage']?['options']?['selectedOptions']?['textStyle']
              ?['textAlign'] ??
              'center',
      'csatSelectedOptionTextFont':
          styling['feedbackPage']?['options']?['selectedOptions']?['textStyle']
              ?['fontFamily'],
      'csatSelectedOptionTextSize':
          styling['feedbackPage']?['options']?['selectedOptions']?['textStyle']
              ?['fontSize'] ??
              12,
      'csatSelectedOptionTextDecoration':
          styling['feedbackPage']?['options']?['selectedOptions']?['textStyle']
              ?['fontDecoration'] ??
              [],

      'csatOptionHeight':
          styling['feedbackPage']?['options']?['optionsHeight'],
      'csatOptionSpacing':
          styling['feedbackPage']?['options']?['optionsSpacing'] ?? 8,
      'csatOptionCornerRadiusTopLeft':
          styling['feedbackPage']?['options']?['cornerRadius']?['topLeft'] ?? 12,
      'csatOptionCornerRadiusTopRight':
          styling['feedbackPage']?['options']?['cornerRadius']?['topRight'] ??
              12,
      'csatOptionCornerRadiusBottomLeft':
          styling['feedbackPage']?['options']?['cornerRadius']?['bottomLeft'] ??
              12,
      'csatOptionCornerRadiusBottomRight':
          styling['feedbackPage']?['options']?['cornerRadius']?['bottomRight'] ??
              12,

      // ── Additional comments ─────────────────────────────────────────────────
      'csatAdditionalCommentsEnabled':
          styling['feedbackPage']?['additionalComments']?['enabled'] ?? true,
      'csatAdditionalBackgroundColor':
          styling['feedbackPage']?['additionalComments']?['colors']
              ?['background'] ??
              '#ededed',
      'csatAdditionalBorderColor':
          styling['feedbackPage']?['additionalComments']?['colors']?['border'] ??
              '#050505',
      'csatAdditionalTextColor':
          styling['feedbackPage']?['additionalComments']?['colors']?['text'] ??
              '#000000',
      'csatAdditionalTextAlignment':
          styling['feedbackPage']?['additionalComments']?['textStyle']
              ?['textAlign'] ??
              'center',
      'csatAdditionalTextFont':
          styling['feedbackPage']?['additionalComments']?['textStyle']
              ?['fontFamily'] ??
              'Arial',
      'csatAdditionalTextSize':
          styling['feedbackPage']?['additionalComments']?['textStyle']
              ?['fontSize'] ??
              12,
      'csatAdditionalTextDecoration':
          styling['feedbackPage']?['additionalComments']?['textStyle']
              ?['fontDecoration'] ??
              [],

      // ── Submit button ───────────────────────────────────────────────────────
      'csatSubmitStyling': {
        'cornerRadius': styling['feedbackPage']?['submitButton']?['cta']
            ?['cornerRadius'],
        'container': {
          'backgroundColor':
              styling['feedbackPage']?['submitButton']?['cta']?['container']
                  ?['backgroundColor'] ??
                  '#FE6B35',
          'borderColor':
              styling['feedbackPage']?['submitButton']?['cta']?['container']
                  ?['borderColor'] ??
                  '#050505',
          'borderWidth':
              styling['feedbackPage']?['submitButton']?['cta']?['container']
                  ?['borderWidth'] ??
                  0,
          'height':
              styling['feedbackPage']?['submitButton']?['cta']?['container']
                  ?['height'] ??
                  40,
          'ctaWidth':
              styling['feedbackPage']?['submitButton']?['cta']?['container']
                  ?['ctaWidth'] ??
                  100,
          'ctaFullWidth':
              styling['feedbackPage']?['submitButton']?['cta']?['container']
                  ?['ctaFullWidth'] ??
                  false,
          'alignment':
              styling['feedbackPage']?['submitButton']?['cta']?['container']
                  ?['alignment'] ??
                  'center',
        },
        'margin': styling['feedbackPage']?['submitButton']?['cta']?['margin'],
        'text': {
          'color': styling['feedbackPage']?['submitButton']?['cta']?['text']
              ?['color'] ??
              '#FFFFFF',
          'fontSize':
              styling['feedbackPage']?['submitButton']?['cta']?['text']
                  ?['fontSize'] ??
                  12,
          'fontFamily':
              styling['feedbackPage']?['submitButton']?['cta']?['text']
                  ?['fontFamily'],
          'fontDecoration':
              styling['feedbackPage']?['submitButton']?['cta']?['text']
                  ?['fontDecoration'] ??
                  [],
        },
      },
      'csatCtaText':
          styling['feedbackPage']?['submitButton']?['text'] ?? 'Submit',
      'csatCtaEnabled':
          styling['feedbackPage']?['submitButton']?['enabled'] ?? true,

      // ── Done button ─────────────────────────────────────────────────────────
      'thankyouDoneStyling': {
        'cornerRadius': styling['thankyouPage']?['doneButton']?['cta']
            ?['cornerRadius'],
        'container': {
          'backgroundColor':
              styling['thankyouPage']?['doneButton']?['cta']?['container']
                  ?['backgroundColor'] ??
                  '#fe6b35',
          'borderColor':
              styling['thankyouPage']?['doneButton']?['cta']?['container']
                  ?['borderColor'] ??
                  '#fe6b35',
          'borderWidth':
              styling['thankyouPage']?['doneButton']?['cta']?['container']
                  ?['borderWidth'] ??
                  0,
          'height':
              styling['thankyouPage']?['doneButton']?['cta']?['container']
                  ?['height'] ??
                  40,
          'ctaWidth':
              styling['thankyouPage']?['doneButton']?['cta']?['container']
                  ?['ctaWidth'] ??
                  100,
          'ctaFullWidth':
              styling['thankyouPage']?['doneButton']?['cta']?['container']
                  ?['ctaFullWidth'] ??
                  false,
          'alignment':
              styling['thankyouPage']?['doneButton']?['cta']?['container']
                  ?['alignment'] ??
                  'center',
        },
        'margin': styling['thankyouPage']?['doneButton']?['cta']?['margin'],
        'text': {
          'color': styling['thankyouPage']?['doneButton']?['cta']?['text']
              ?['color'] ??
              '#ffffff',
          'fontSize':
              styling['thankyouPage']?['doneButton']?['cta']?['text']
                  ?['fontSize'] ??
                  12,
          'fontFamily':
              styling['thankyouPage']?['doneButton']?['cta']?['text']
                  ?['fontFamily'],
          'fontDecoration':
              styling['thankyouPage']?['doneButton']?['cta']?['text']
                  ?['fontDecoration'] ??
                  [],
        },
      },
      'thankyouDoneButtonText':
          styling['thankyouPage']?['doneButton']?['text'] ?? 'Done',

      'thankyouImageMarginTop':
          styling['thankyouPage']?['imageStyle']?['margin']?['top'] ?? 12,
      'thankyouImageMarginBottom':
          styling['thankyouPage']?['imageStyle']?['margin']?['bottom'] ?? 12,
      'thankyouImageMarginLeft':
          styling['thankyouPage']?['imageStyle']?['margin']?['left'] ?? 12,
      'thankyouImageMarginRight':
          styling['thankyouPage']?['imageStyle']?['margin']?['right'] ?? 12,
      'thankyouImageHeight':
          _parseToNum(styling['thankyouPage']?['imageStyle']?['height']) ?? 80,
      'thankyouImageWidth':
          _parseToNum(styling['thankyouPage']?['imageStyle']?['width']) ?? 80,

      'thankyouTitleColor':
          styling['thankyouPage']?['title']?['textStyle']?['color'] ??
              '#FE6B35',
      'thankyouTitleAlignment':
          styling['thankyouPage']?['title']?['textStyle']?['textAlign'] ??
              'center',
      'thankyouTitleFont':
          styling['thankyouPage']?['title']?['textStyle']?['fontFamily'] ??
              'Arial',
      'thankyouTitleSize':
          styling['thankyouPage']?['title']?['textStyle']?['fontSize'] ?? 12,
      'thankyouTitleDecoration':
          styling['thankyouPage']?['title']?['textStyle']?['fontDecoration'] ??
              [],

      'thankyouSubtitleColor':
          styling['thankyouPage']?['subtitle']?['textStyle']?['color'] ??
              '#FE6B35',
      'thankyouSubtitleAlignment':
          styling['thankyouPage']?['subtitle']?['textStyle']?['textAlign'] ??
              'center',
      'thankyouSubtitleFont':
          styling['thankyouPage']?['subtitle']?['textStyle']?['fontFamily'] ??
              'Arial',
      'thankyouSubtitleSize':
          styling['thankyouPage']?['subtitle']?['textStyle']?['fontSize'] ?? 12,
      'thankyouSubtitleDecoration':
          styling['thankyouPage']?['subtitle']?['textStyle']?['fontDecoration'] ??
              [],

      'fontSize': styling['fontSize'] ?? 12,
      'crossButton': styling['crossButton'],

      'feedbackPagePaddingTop':
          styling['appearance']?['padding']?['top'] ?? 0,
      'feedbackPagePaddingBottom':
          styling['appearance']?['padding']?['bottom'] ?? 16,
      'feedbackPagePaddingLeft':
          styling['appearance']?['padding']?['left'] ?? 16,
      'feedbackPagePaddingRight':
          styling['appearance']?['padding']?['right'] ?? 16,
      'headerPaddingTop': styling['appearance']?['padding']?['top'] ?? 20,
      'headerPaddingBottom': styling['appearance']?['padding']?['bottom'] ?? 8,
      'headerPaddingLeft': styling['appearance']?['padding']?['left'] ?? 16,
      'headerPaddingRight': styling['appearance']?['padding']?['right'] ?? 16,
    };
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  Color _hexToColor(String? hexCode) {
    if (hexCode == null || hexCode.isEmpty) return Colors.black;
    try {
      return Color(int.parse('FF${hexCode.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.black;
    }
  }

  TextAlign _getTextAlign(String? alignment) {
    switch (alignment?.toLowerCase()) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.center;
    }
  }

  TextStyle _applyFontDecorations(TextStyle style, dynamic decorations) {
    if (decorations == null || decorations is! List || decorations.isEmpty) {
      return style;
    }
    final list = decorations.cast<String>();
    return style.copyWith(
      fontWeight: list.contains('bold') ? FontWeight.bold : FontWeight.normal,
      fontStyle:
          list.contains('italic') ? FontStyle.italic : FontStyle.normal,
      decoration: list.contains('underline')
          ? TextDecoration.underline
          : TextDecoration.none,
      decorationColor: style.color,
    );
  }

  double get _baseFontSize {
    final v = _styling['fontSize'];
    if (v == null) return 16.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 16.0;
  }

  BorderRadius get _optionCornerRadius => BorderRadius.only(
    topLeft: Radius.circular(
      (_styling['csatOptionCornerRadiusTopLeft'] as num).toDouble(),
    ),
    topRight: Radius.circular(
      (_styling['csatOptionCornerRadiusTopRight'] as num).toDouble(),
    ),
    bottomLeft: Radius.circular(
      (_styling['csatOptionCornerRadiusBottomLeft'] as num).toDouble(),
    ),
    bottomRight: Radius.circular(
      (_styling['csatOptionCornerRadiusBottomRight'] as num).toDouble(),
    ),
  );

  // ── Rating interaction ────────────────────────────────────────────────────

  void _handleRatingSelected(int rating) {
    setState(() => selectedStars = rating);

    if (selectedStars >= 4) {
      _trackEvent('csat captured', {
        'starCount': selectedStars,
        'selectedOption': '',
        'additionalComments': null,
      });
      _captureCsatResponse();
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => showThanks = true);
      });
    } else {
      setState(() => showFeedback = true);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _captureCsatResponse({String? feedbackOption, String? additionalComments}) {
    widget.appStorys.getUserId().then((uid) {
      if (uid != null && uid.isNotEmpty) {
        widget.appStorys
            .captureCsatResponse(
              csatId: widget.campaign.id,
              userId: uid,
              rating: selectedStars.toDouble(),
              feedbackOption: feedbackOption,
              additionalComments: additionalComments,
            )
            .catchError((_) {});
      }
    });
  }

  // ── Rating widgets ────────────────────────────────────────────────────────

  Widget _buildStarRating() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final isSelected = index < selectedStars;

          final starColor = isSelected
              ? (selectedStars >= 4
                  ? _hexToColor(_styling['csatHighStarColor'] as String?)
                  : _hexToColor(_styling['csatLowStarColor'] as String?))
              : _hexToColor(_styling['csatUnselectedStarColor'] as String?);

          final borderColor = isSelected
              ? (selectedStars >= 4
                  ? _hexToColor(_styling['csatHighStarBorder'] as String?)
                  : _hexToColor(_styling['csatLowStarBorder'] as String?))
              : _hexToColor(_styling['csatUnselectedStarBorder'] as String?);

          final borderWidth = isSelected
              ? (selectedStars >= 4
                  ? (_styling['csatHighStarBorderWidth'] as num).toDouble()
                  : (_styling['csatLowStarBorderWidth'] as num).toDouble())
              : (_styling['csatUnselectedStarBorderWidth'] as num).toDouble();

          return AnimatedScale(
            scale: isSelected ? 1.18 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: InkWell(
              onTap: () => _handleRatingSelected(index + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (borderWidth > 0)
                      ColorFiltered(
                        colorFilter:
                            ColorFilter.mode(borderColor, BlendMode.srcIn),
                        child: Image.asset(
                          'lib/assets/icons/star.png',
                          width: 40.0 + (borderWidth * 3),
                          height: 40.0 + (borderWidth * 3),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ColorFiltered(
                      colorFilter:
                          ColorFilter.mode(starColor, BlendMode.srcIn),
                      child: Image.asset(
                        'lib/assets/icons/star.png',
                        width: 40.0,
                        height: 40.0,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmojiRating() {
    final emojiValues =
        _styling['csatEmojiValues'] as List? ?? ['😞', '😕', '😐', '🙂', '😄'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (index) {
          final rating = index + 1;
          final isSelected = rating <= selectedStars;

          String getEmoji() => index < emojiValues.length
              ? emojiValues[index] as String
              : ['😞', '😕', '😐', '🙂', '😄'][index];

          return AnimatedScale(
            scale: isSelected ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: InkWell(
              onTap: () => _handleRatingSelected(rating),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Container(
                  width: 46.0,
                  height: 46.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? _hexToColor(
                            _styling['csatEmojiSelectedBackground'] as String?,
                          )
                        : _hexToColor(
                            _styling['csatEmojiUnselectedBackground'] as String?,
                          ),
                    border: Border.all(
                      color: isSelected
                          ? _hexToColor(
                              _styling['csatEmojiSelectedBorder'] as String?,
                            )
                          : _hexToColor(
                              _styling['csatEmojiUnselectedBorder'] as String?,
                            ),
                      width: isSelected
                          ? (_styling['csatEmojiSelectedBorderWidth'] as num)
                              .toDouble()
                          : (_styling['csatEmojiUnselectedBorderWidth'] as num)
                              .toDouble(),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      getEmoji(),
                      style: const TextStyle(
                        fontSize: 24.0,
                        height: 1.0,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNumberRating() {
    final numberSize =
        (_styling['csatNumberSize'] as num).toDouble();
    final numberTextColor =
        _hexToColor(_styling['csatNumberTextColor'] as String?);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final rating = index + 1;
          final isSelected = rating <= selectedStars;

          Color getBackgroundColor() {
            if (!isSelected) {
              return _hexToColor(
                _styling['csatNumberUnselectedBackground'] as String?,
              );
            }
            if (rating >= 4) {
              return _hexToColor(
                _styling['csatNumberHighBackground'] as String?,
              );
            }
            return _hexToColor(_styling['csatNumberLowBackground'] as String?);
          }

          Color getBorderColor() {
            if (!isSelected) {
              return _hexToColor(
                _styling['csatNumberUnselectedBorder'] as String?,
              );
            }
            if (rating >= 4) {
              return _hexToColor(_styling['csatNumberHighBorder'] as String?);
            }
            return _hexToColor(_styling['csatNumberLowBorder'] as String?);
          }

          double getBorderWidth() {
            if (!isSelected) {
              return (_styling['csatNumberUnselectedBorderWidth'] as num)
                  .toDouble();
            }
            if (rating >= 4) {
              return (_styling['csatNumberHighBorderWidth'] as num).toDouble();
            }
            return (_styling['csatNumberLowBorderWidth'] as num).toDouble();
          }

          return AnimatedScale(
            scale: isSelected ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: InkWell(
              onTap: () => _handleRatingSelected(rating),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Container(
                  width: numberSize + 16,
                  height: numberSize + 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: getBackgroundColor(),
                    border: Border.all(
                      color: getBorderColor(),
                      width: getBorderWidth(),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      '$rating',
                      style: TextStyle(
                        fontSize: numberSize - 2,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: numberTextColor,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRatingWidget() {
    final ratingType =
        (_styling['csatRatingType'] as String?)?.toLowerCase() ?? 'star';
    final ratingAlignment =
        (_styling['csatRatingAlignment'] as String?)?.toLowerCase() ?? 'center';

    Widget ratingWidget;
    switch (ratingType) {
      case 'emoji':
        ratingWidget = _buildEmojiRating();
        break;
      case 'number':
        ratingWidget = _buildNumberRating();
        break;
      default:
        ratingWidget = _buildStarRating();
    }

    MainAxisAlignment mainAxisAlignment;
    switch (ratingAlignment) {
      case 'left':
        mainAxisAlignment = MainAxisAlignment.start;
        break;
      case 'right':
        mainAxisAlignment = MainAxisAlignment.end;
        break;
      default:
        mainAxisAlignment = MainAxisAlignment.center;
    }

    return Row(mainAxisAlignment: mainAxisAlignment, children: [ratingWidget]);
  }

  // ── Header (title + description + rating) ────────────────────────────────

  Widget _buildHeader() {
    var titleStyle = TextStyle(
      fontSize: (_styling['csatTitleSize'] as num).toDouble(),
      color: _hexToColor(_styling['csatTitleColor'] as String?),
      fontFamily: _resolvedTitleFont,
    );
    titleStyle = _applyFontDecorations(
      titleStyle,
      _styling['csatTitleDecoration'],
    );

    var descriptionStyle = TextStyle(
      fontSize: (_styling['csatDescriptionSize'] as num).toDouble(),
      color: _hexToColor(_styling['csatDescriptionTextColor'] as String?),
      fontFamily: _resolvedSubtitleFont,
    );
    descriptionStyle = _applyFontDecorations(
      descriptionStyle,
      _styling['csatDescriptionDecoration'],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.campaign.details.title,
          textAlign: _getTextAlign(_styling['csatTitleAlignment'] as String?),
          style: titleStyle,
        ),
        const SizedBox(height: 4),
        Text(
          widget.campaign.details.descriptionText,
          textAlign:
              _getTextAlign(_styling['csatDescriptionAlignment'] as String?),
          style: descriptionStyle,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, _) => _buildRatingWidget()),
      ],
    );
  }

  // ── Feedback body (options + additional comments + submit) ────────────────

  Widget _buildFeedbackBody() {
    final feedbackOptions = widget.campaign.details.feedbackOptions.entries
        .map((e) => {'id': e.key, 'name': e.value})
        .toList();

    final optionSpacing =
        (_styling['csatOptionSpacing'] as num).toDouble();
    final optionHeightRaw = _styling['csatOptionHeight'];
    final double? optionHeight =
        optionHeightRaw != null ? (optionHeightRaw as num).toDouble() : null;
    final optionRadius = _optionCornerRadius;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...feedbackOptions.map((option) {
          final isSelected = selectedOptionId == option['id'];

          var optionStyle = TextStyle(
            fontSize: ((isSelected
                    ? _styling['csatSelectedOptionTextSize']
                    : _styling['csatOptionTextSize']) as num)
                .toDouble(),
            color: isSelected
                ? _hexToColor(
                    _styling['csatSelectedOptionTextColor'] as String?,
                  )
                : _hexToColor(_styling['csatOptionTextColour'] as String?),
            fontFamily: isSelected
                ? _resolvedSelectedOptionTextFont
                : _resolvedOptionTextFont,
          );
          optionStyle = _applyFontDecorations(
            optionStyle,
            isSelected
                ? _styling['csatSelectedOptionTextDecoration']
                : _styling['csatOptionTextDecoration'],
          );

          return Column(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  selectedOptionId = option['id'];
                  selectedOption = option['name'];
                }),
                child: Container(
                  width: double.infinity,
                  height: optionHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  margin: EdgeInsets.only(bottom: optionSpacing),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _hexToColor(
                            _styling['csatSelectedOptionBackgroundColor']
                                as String?,
                          )
                        : _hexToColor(
                            _styling['csatOptionBoxColour'] as String?,
                          ),
                    borderRadius: optionRadius,
                    border: Border.all(
                      color: isSelected
                          ? _hexToColor(
                              _styling['csatSelectedOptionStrokeColor']
                                  as String?,
                            )
                          : _hexToColor(
                              _styling['csatOptionStrokeColor'] as String?,
                            ),
                    ),
                  ),
                  child: Text(
                    option['name'] as String,
                    textAlign: _getTextAlign(
                      isSelected
                          ? _styling['csatSelectedOptionTextAlignment']
                              as String?
                          : _styling['csatOptionTextAlignment'] as String?,
                    ),
                    style: optionStyle,
                  ),
                ),
              ),
            ],
          );
        }),

        const SizedBox(height: 8),

        if (_styling['csatAdditionalCommentsEnabled'] == true) ...[
          Text(
            'Additional Comments',
            style: TextStyle(
              fontSize: _baseFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textcontroller,
            focusNode: _commentFocusNode,
            minLines: 3,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            textAlign: _getTextAlign(
              _styling['csatAdditionalTextAlignment'] as String?,
            ),
            cursorColor: _hexToColor(
              _styling['csatAdditionalBorderColor'] as String?,
            ),
            style: TextStyle(
              color: _hexToColor(
                _styling['csatAdditionalTextColor'] as String?,
              ),
              fontSize:
                  (_styling['csatAdditionalTextSize'] as num).toDouble(),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _hexToColor(
                _styling['csatAdditionalBackgroundColor'] as String?,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              enabledBorder: OutlineInputBorder(
                borderRadius: optionRadius,
                borderSide: BorderSide(
                  color: _hexToColor(
                    _styling['csatAdditionalBorderColor'] as String?,
                  ),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: optionRadius,
                borderSide: BorderSide(
                  color: _hexToColor(
                    _styling['csatSelectedOptionStrokeColor'] as String?,
                  ),
                  width: 1.5,
                ),
              ),
              hintText: 'Write your feedback...',
              hintStyle: TextStyle(
                fontSize:
                    (_styling['csatAdditionalTextSize'] as num).toDouble(),
                color: _hexToColor(
                  _styling['csatAdditionalTextColor'] as String?,
                ).withValues(alpha: 0.6),
              ),
            ),
          ),
        ],

        CtaButton(
          text: _styling['csatCtaText'] as String? ?? 'Submit',
          onTap: _submitFeedback,
          styling: _styling['csatSubmitStyling'] as Map<dynamic, dynamic>?,
        ),
      ],
    );
  }

  void _submitFeedback() {
    final comment =
        _textcontroller.text.isEmpty ? null : _textcontroller.text;
    _trackEvent('csat captured', {
      'starCount': selectedStars,
      'selectedOption': selectedOptionId ?? '',
      'additionalComments': comment,
    });
    _captureCsatResponse(
      feedbackOption: selectedOption,
      additionalComments: comment,
    );
    setState(() => showThanks = true);
  }

  // ── Thank-you page ────────────────────────────────────────────────────────

  Widget _buildThankYouMedia() {
    final mediaUrl = widget.campaign.details.thankyouImage;
    if (mediaUrl == null || mediaUrl.isEmpty) return const SizedBox.shrink();

    final isLottie = mediaUrl.toLowerCase().endsWith('.json');

    dynamic heightValue = _styling['thankyouImageHeight'];
    dynamic widthValue = _styling['thankyouImageWidth'];

    final imageHeight = heightValue is num
        ? heightValue.toDouble()
        : double.tryParse(heightValue?.toString() ?? '80') ?? 80.0;
    final imageWidth = widthValue is num
        ? widthValue.toDouble()
        : double.tryParse(widthValue?.toString() ?? '80') ?? 80.0;

    return Container(
      margin: EdgeInsets.only(
        top: (_styling['thankyouImageMarginTop'] as num).toDouble(),
        bottom: (_styling['thankyouImageMarginBottom'] as num).toDouble(),
        left: (_styling['thankyouImageMarginLeft'] as num).toDouble(),
        right: (_styling['thankyouImageMarginRight'] as num).toDouble(),
      ),
      child: isLottie
          ? Lottie.network(
              mediaUrl,
              height: imageHeight,
              width: imageWidth,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => SizedBox(
                height: imageHeight,
                width: imageWidth,
                child: const Center(child: Icon(Icons.error_outline)),
              ),
            )
          : Image.network(
              mediaUrl,
              height: imageHeight,
              width: imageWidth,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => SizedBox(
                height: imageHeight,
                width: imageWidth,
                child: const Center(child: Icon(Icons.error_outline)),
              ),
            ),
    );
  }

  Widget _buildThankYou() {
    final details = widget.campaign.details;

    String getThankyouTitle() {
      if (selectedStars >= 4) {
        final t = _styling['csatHighRatingTitle'] as String? ?? '';
        return t.isNotEmpty ? t : details.thankyouText;
      }
      final t = _styling['csatLowRatingTitle'] as String? ?? '';
      return t.isNotEmpty ? t : details.thankyouText;
    }

    String getThankyouDescription() {
      if (selectedStars >= 4) {
        final d = _styling['csatHighRatingSubtitle'] as String? ?? '';
        return d.isNotEmpty ? d : details.thankyouDescription;
      }
      final d = _styling['csatLowRatingSubtitle'] as String? ?? '';
      return d.isNotEmpty ? d : details.thankyouDescription;
    }

    String getDoneButtonText() {
      final text = _styling['thankyouDoneButtonText'] as String? ?? '';
      if (text.isNotEmpty) return text;
      return selectedStars >= 4 ? details.highStarText : details.lowStarText;
    }

    final thankyouTitle = getThankyouTitle();
    final thankyouDesc = getThankyouDescription();
    final doneButtonText = getDoneButtonText();

    return Container(
      padding: EdgeInsets.only(
        top: (_styling['csatPaddingTop'] as num?)?.toDouble() ?? 10,
        bottom: (_styling['csatPaddingBottom'] as num?)?.toDouble() ?? 20,
        left: (_styling['csatPaddingLeft'] as num?)?.toDouble() ?? 10,
        right: (_styling['csatPaddingRight'] as num?)?.toDouble() ?? 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildThankYouMedia(),

          if (thankyouTitle.isNotEmpty) ...[
            Text(
              thankyouTitle,
              textAlign: _getTextAlign(
                _styling['thankyouTitleAlignment'] as String?,
              ),
              style: _applyFontDecorations(
                TextStyle(
                  fontSize:
                      (_styling['thankyouTitleSize'] as num).toDouble(),
                  fontWeight: FontWeight.bold,
                  color: _hexToColor(
                    _styling['thankyouTitleColor'] as String?,
                  ),
                  fontFamily: _resolvedThankyouTitleFont,
                  height: 1.0,
                ),
                _styling['thankyouTitleDecoration'],
              ),
            ),
            const SizedBox(height: 4),
          ],

          if (thankyouDesc.isNotEmpty) ...[
            Text(
              thankyouDesc,
              textAlign: _getTextAlign(
                _styling['thankyouSubtitleAlignment'] as String?,
              ),
              style: _applyFontDecorations(
                TextStyle(
                  fontSize:
                      (_styling['thankyouSubtitleSize'] as num).toDouble(),
                  color: _hexToColor(
                    _styling['thankyouSubtitleColor'] as String?,
                  ),
                  fontFamily: _resolvedThankyouSubtitleFont,
                  height: 1.0,
                ),
                _styling['thankyouSubtitleDecoration'],
              ),
            ),
            const SizedBox(height: 16),
          ],

          CtaButton(
            text: doneButtonText,
            onTap: () {
              if (selectedStars >= 4 && details.link.isNotEmpty) {
                widget.onLinkTap?.call(details.link);
              }
              widget.onDismiss();
            },
            styling: _styling['thankyouDoneStyling'] as Map<dynamic, dynamic>?,
          ),
        ],
      ),
    );
  }

  // ── Root build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final double maxAvailableHeight = screenHeight - keyboardHeight - 150;

    final containerHeightStr = _styling['csatHeight'];
    final containerWidthStr = _styling['csatWidth'];

    double? specificHeight;
    if (containerHeightStr != null &&
        containerHeightStr.toString().isNotEmpty) {
      final parsed = containerHeightStr is num
          ? containerHeightStr.toDouble()
          : double.tryParse(containerHeightStr.toString());
      if (parsed != null && parsed > 200) specificHeight = parsed;
    }

    double? specificWidth;
    if (containerWidthStr != null && containerWidthStr.toString().isNotEmpty) {
      final parsed = containerWidthStr is num
          ? containerWidthStr.toDouble()
          : double.tryParse(containerWidthStr.toString());
      if (parsed != null && parsed > 200) specificWidth = parsed;
    }

    return Stack(
      children: [
        InkWell(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            width: specificWidth ?? double.infinity,
            constraints: BoxConstraints(
              maxHeight: specificHeight ??
                  (maxAvailableHeight > 0
                      ? maxAvailableHeight
                      : screenHeight * 0.65),
              minHeight: 0,
            ),
            padding: EdgeInsets.only(
              top: (_styling['csatPaddingTop'] as num?)?.toDouble() ?? 10,
              bottom: (_styling['csatPaddingBottom'] as num?)?.toDouble() ?? 20,
              left: (_styling['csatPaddingLeft'] as num?)?.toDouble() ?? 10,
              right: (_styling['csatPaddingRight'] as num?)?.toDouble() ?? 10,
            ),
            decoration: BoxDecoration(
              color: _hexToColor(
                _styling['csatBackgroundColor'] as String? ?? '#FFFFFF',
              ),
              borderRadius: BorderRadius.circular(
                (_styling['csatBorderRadius'] as num?)?.toDouble() ?? 4,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: showThanks
                ? _buildThankYou()
                : SingleChildScrollView(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: (_styling['headerPaddingTop'] as num?)
                                    ?.toDouble() ??
                                20,
                            left: (_styling['headerPaddingLeft'] as num?)
                                    ?.toDouble() ??
                                16,
                            right: (_styling['headerPaddingRight'] as num?)
                                    ?.toDouble() ??
                                16,
                            bottom: (_styling['headerPaddingBottom'] as num?)
                                    ?.toDouble() ??
                                8,
                          ),
                          child: _buildHeader(),
                        ),
                        if (showFeedback)
                          Padding(
                            padding: EdgeInsets.only(
                              left: (_styling['feedbackPagePaddingLeft'] as num?)
                                      ?.toDouble() ??
                                  16,
                              right:
                                  (_styling['feedbackPagePaddingRight'] as num?)
                                          ?.toDouble() ??
                                      16,
                              bottom:
                                  (_styling['feedbackPagePaddingBottom'] as num?)
                                          ?.toDouble() ??
                                      16,
                              top: (_styling['feedbackPagePaddingTop'] as num?)
                                      ?.toDouble() ??
                                  0,
                            ),
                            child: _buildFeedbackBody(),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: CrossButton(
            onTap: widget.onDismiss,
            styling: _styling['crossButton'] as Map<dynamic, dynamic>?,
          ),
        ),
      ],
    );
  }
}
