import 'package:flutter/material.dart';

import '../../appstorys_flutter.dart';
import '../common/cross_button.dart';
import '../common/cta_button.dart';
import '../common/minimize_button.dart';
import '../common/mute_button.dart';
import '../common/unmute_button.dart';
import '../utils/link_handler.dart';
import 'pip_video_player.dart';

class PipFullScreen extends StatefulWidget {
  final AppstorysFlutter appStorys;
  final String videoUrl;
  final PipCampaign campaign;
  final void Function(bool showPip) onClose;
  final VoidCallback onMinimize;
  final void Function(String link)? onLinkTap;

  const PipFullScreen({
    super.key,
    required this.appStorys,
    required this.videoUrl,
    required this.campaign,
    required this.onClose,
    required this.onMinimize,
    this.onLinkTap,
  });

  @override
  State<PipFullScreen> createState() => _PipFullScreenState();
}

class _PipFullScreenState extends State<PipFullScreen> {
  late bool _muted;

  @override
  void initState() {
    super.initState();

    // defaultSound: "no" = muted
    _muted = widget.campaign.styling?.defaultSound == 'no';

    _trackView();
  }

  void _trackView() {
    if (widget.campaign.id.isEmpty) return;

    widget.appStorys
        .trackEvent(event: 'viewed', campaignId: widget.campaign.id)
        .catchError((_) {});
  }

  void _onCtaTap() {
    final link = widget.campaign.link;

    if (link?.isEmpty ?? true) return;

    widget.appStorys
        .trackEvent(event: 'clicked', campaignId: widget.campaign.id)
        .catchError((_) {});
    widget.appStorys.viaAppStorys(link!).catchError((_) {});

    LinkHandler.handle(link, widget.onLinkTap);
  }

  void _onClose() {
    Navigator.pop(context);
    widget.onClose(false);
  }

  void _onMinimize() {
    widget.onMinimize();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final campaign = widget.campaign;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            /// VIDEO
            Positioned.fill(
              child: PipVideoPlayer(
                videoUrl: widget.videoUrl,
                mute: _muted,
              ),
            ),

            /// TOP LEFT (minimize)
            if (campaign.styling?.expandControlsEnabled != false)
              Positioned(
                top: 12,
                left: 12,
                child: MinimiseButton(
                  onTap: _onMinimize,
                  styling: campaign.styling?.expandControls,
                ),
              ),

            /// TOP RIGHT (sound + close)
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (campaign.styling?.soundToggleEnabled != false) ...[
                    _muted
                        ? MuteButton(
                            onTap: () => setState(() => _muted = !_muted),
                            styling: campaign.styling?.soundToggle,
                          )
                        : UnmuteButton(
                            onTap: () => setState(() => _muted = !_muted),
                            styling: campaign.styling?.soundToggle,
                          ),
                    const SizedBox(width: 8),
                  ],
                  if (campaign.styling?.crossButtonEnabled != false)
                    CrossButton(
                      onTap: _onClose,
                      styling: campaign.styling?.crossButton,
                    ),
                ],
              ),
            ),

            /// CTA BUTTON
            if (campaign.buttonText?.isNotEmpty == true)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: CtaButton(
                  onTap: _onCtaTap,
                  text: campaign.buttonText!,
                  fullWidth: true,
                  styling: campaign.styling?.cta,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

