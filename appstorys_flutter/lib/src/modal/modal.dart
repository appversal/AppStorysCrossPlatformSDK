import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../appstorys_flutter.dart';
import '../common/cross_button.dart';
import '../utils/campaigns_stream_mixin.dart';
import '../utils/link_handler.dart';
import 'modal_fullpage.dart';
import 'modal_with_cta.dart';

// ─── KMP Entry Widget ─────────────────────────────────────────────────────────
// Subscribes to the campaigns stream and shows Modal (MDA) campaigns.
// Add to AppStorysOverlay or directly to your widget tree.

class AppStorysModal extends StatefulWidget {
  final AppstorysFlutter appStorys;
  final void Function(String)? onLinkTap;

  const AppStorysModal({
    super.key,
    required this.appStorys,
    this.onLinkTap,
  });

  @override
  State<AppStorysModal> createState() => _AppStorysModalState();
}

class _AppStorysModalState extends State<AppStorysModal>
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
    final parsed = _parseCampaign(json);
    if (parsed == null) return;

    final id = (parsed['campaign_id'] ?? parsed['id'])?.toString() ?? '';
    if (id == _currentCampaignId || _showing) return;

    _currentCampaignId = id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _showing) return;
      _showing = true;
      widget.appStorys
          .trackEvent(event: 'viewed', campaignId: id)
          .catchError((_) {});
      Modal.show(
        context,
        [parsed],
        '',
        appStorys: widget.appStorys,
        onLinkTap: widget.onLinkTap,
        onDismiss: () => _showing = false,
      );
    });
  }

  Map<String, dynamic>? _parseCampaign(String json) {
    try {
      final data = jsonDecode(json) as List<dynamic>;
      final raw = data.whereType<Map>().firstWhere(
        (c) => c['campaign_type'] == 'MOD',
        orElse: () => {},
      );
      if (raw.isEmpty) return null;
      return Map<String, dynamic>.from(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ─────────────────────────────────────────────────────────────────────────────

class CampaignModals {
  final String id;
  final String campaignType;
  final ModalDetails details;

  CampaignModals({
    required this.id,
    required this.campaignType,
    required this.details,
  });
}

class ModalDetails {
  final List? modals;

  ModalDetails({
    required this.modals,
  });
}

class Modal {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    List? modalDetails,
    String userId, {
    AppstorysFlutter? appStorys,
    void Function(String)? onLinkTap,
    VoidCallback? onDismiss,
  }) {
    if (_entry != null) return;

    CampaignModals? currentModal;
    Map<String, dynamic>? modalData;
    String modalType = '';

    if (modalDetails != null) {
      try {
        final campaignData = modalDetails.first;
        final details =
            (campaignData['details'] as Map<String, dynamic>?) ?? campaignData;

        currentModal = CampaignModals(
          id: (campaignData['campaign_id'] ?? campaignData['id']).toString(),
          campaignType: campaignData['campaign_type'],
          details: ModalDetails(
            modals: details['modals'],
          ),
        );

        modalData = currentModal.details.modals?[0];
        // modal_type can live at campaign level, details level, or inside modals[0]
        modalType = (campaignData['modal_type'] ?? details['modal_type'] ?? modalData?['modal_type'])?.toString() ?? '';
        debugPrint('[Modal] modalType: $modalType, slides: ${(modalData?['content']?['set'] as List?)?.length ?? 0}');
      } catch (e) {
        debugPrint('Error loading modal: $e');
      }
    }

    if (modalData != null) {

      if (modalType == 'modal-with-cta') {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) {
            return ModalWithCTA(
              modalData: modalData!,
              campaignId: currentModal?.id,
              appStorys: appStorys,
              onLinkTap: onLinkTap,
              onClose: () {
                Navigator.of(dialogContext).pop();
                appStorys?.trackEvent(
                    event: 'closed',
                    campaignId: currentModal?.id ?? '').catchError((_) {});
              },
            );
          },
        ).whenComplete(() => onDismiss?.call());
        return;
      }

      if (modalType == 'modal-fullpage-carousel') {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) {
            return ModalFullPageCarousel(
              modalData: modalData!,
              campaignId: currentModal?.id,
              appStorys: appStorys,
              onLinkTap: onLinkTap,
              onClose: () {
                Navigator.of(dialogContext).pop();
                appStorys?.trackEvent(
                    event: 'closed',
                    campaignId: currentModal?.id ?? '').catchError((_) {});
              },
            );
          },
        ).whenComplete(() => onDismiss?.call());
        return;
      }

      // ✅ Get backdrop properties
      final backdropOpacity = double.tryParse(modalData['styling']
                  ?['appearance']?['backdrop']?['opacity']
                  ?.toString() ??
              '40') ??
          40;

      final backdropColorStr =
          modalData['styling']?['appearance']?['backdrop']?['color'] ??
              '#000000';
      final backdropColor = _parseColor(backdropColorStr);

      // Get media properties
      final mediaType = modalData['chooseMediaType']?['type'];
      final mediaUrl = modalData['chooseMediaType']?['url'];

      // ✅ Get size (used as width, height auto-adjusts)
      final modalSize =
          double.tryParse(modalData['size']?.toString() ?? '300') ?? 300;

      // ✅ Get redirect properties
      final redirectUrl = modalData['redirection']?['url'] ?? '';
      final redirectType = modalData['redirection']?['type'] ?? 'url';

      // ✅ Get cross button styling
      final crossButtonStyling = modalData['styling']?['crossButton'];

      _entry = OverlayEntry(
        builder: (_) => GestureDetector(
          onTap: () {
            hide();
            onDismiss?.call();
          },
          child: Material(
            color: backdropColor.withValues(alpha: backdropOpacity / 100),
            child: GestureDetector(
              onTap: () async {
                final target = redirectType == 'url'
                    ? redirectUrl
                    : redirectType == 'page'
                        ? (modalData?['redirection']?['pageName'] ?? '')
                        : '';
                if (target.isNotEmpty) {
                  appStorys?.trackEvent(
                      event: 'clicked',
                      campaignId: currentModal?.id ?? '').catchError((_) {});
                  LinkHandler.handle(target, onLinkTap);
                }
              },
              child: Center(
                child: Stack(
                  children: [
                    // Main container with size as width, height auto-adjusts
                    SizedBox(
                      width: modalSize,
                      child: ClipRRect(
                        borderRadius: _buildBorderRadius(modalData),
                        child: _buildMediaWidget(
                          mediaType: mediaType,
                          mediaUrl: mediaUrl,
                        ),
                      ),
                    ),

                    // ✅ Cross button positioned at TOP-RIGHT
                    if (crossButtonStyling != null &&
                        crossButtonStyling['enabled'] == true)
                      Positioned(
                        top: double.tryParse(crossButtonStyling['margin']
                                    ?['top']
                                    ?.toString() ??
                                '0') ??
                            0,
                        right: double.tryParse(crossButtonStyling['margin']
                                    ?['right']
                                    ?.toString() ??
                                '0') ??
                            0,
                        child: CrossButton(
                          onTap: () {
                            hide();
                            appStorys?.trackEvent(
                                event: 'closed',
                                campaignId: currentModal?.id ?? '').catchError((_) {});
                            onDismiss?.call();
                          },
                          iconSize:
                              (crossButtonStyling['size'] ?? 30).toDouble(),
                          styling: crossButtonStyling,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context, rootOverlay: true).insert(_entry!);
    }
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }

  // ✅ Helper to parse hex color strings
  static Color _parseColor(String colorStr) {
    try {
      final hex = colorStr.replaceFirst('#', '0xff');
      return Color(int.parse(hex));
    } catch (e) {
      debugPrint('Color parse error: $e');
      return Colors.black;
    }
  }

  // ✅ Helper to build border radius with per-corner support
  static BorderRadius _buildBorderRadius(Map<String, dynamic>? modalData) {
    try {
      final cornerRadius =
          modalData?['styling']?['appearance']?['cornerRadius'];

      if (cornerRadius != null) {
        return BorderRadius.only(
          topLeft: Radius.circular(
              double.tryParse(cornerRadius['topLeft']?.toString() ?? '12') ??
                  12),
          topRight: Radius.circular(
              double.tryParse(cornerRadius['topRight']?.toString() ?? '12') ??
                  12),
          bottomLeft: Radius.circular(
              double.tryParse(cornerRadius['bottomLeft']?.toString() ?? '12') ??
                  12),
          bottomRight: Radius.circular(double.tryParse(
                  cornerRadius['bottomRight']?.toString() ?? '12') ??
              12),
        );
      }

      return BorderRadius.circular(12);
    } catch (e) {
      debugPrint('Border radius parse error: $e');
      return BorderRadius.circular(12);
    }
  }

  // ✅ Media widget builder with support for image and video
  // Height auto-adjusts based on media aspect ratio
  static Widget _buildMediaWidget({
    required dynamic mediaType,
    required dynamic mediaUrl,
  }) {
    final String type = mediaType?.toString() ?? '';
    final String url = mediaUrl?.toString() ?? '';

    if (url.isEmpty) {
      return const SizedBox.shrink();
    }

    try {
      // 🎥 VIDEO - Height adjusts based on video aspect ratio
      if (type == 'video') {
        return VideoPlayerWidget(url: url);
      }

      // 🖼 IMAGE / LOTTIE / GIF — all rendered via Image.network
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    } catch (e) {
      debugPrint('Media render error: $e');
      return const SizedBox.shrink();
    }
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  const VideoPlayerWidget({required this.url, super.key});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
          _controller.setLooping(true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
  }
}
