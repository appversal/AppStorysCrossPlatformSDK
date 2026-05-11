import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef IdentifyElementsCallback =
Future<void> Function(
    String screenName,
    Uint8List screenshot,
    String childrenJson,
    );

class CaptureManager {
  CaptureManager._();

  static final ValueNotifier<bool> _enabledNotifier = ValueNotifier(false);
  static bool _capturing = false;

  static void setEnabled(bool enabled) {
    _enabledNotifier.value = enabled;
  }

  static Widget captureButton({
    required String screenName,
    required BuildContext screenContext,
    required IdentifyElementsCallback identifyElements,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: _enabledNotifier,
      builder: (context, enabled, _) {
        if (!enabled) return const SizedBox.shrink();
        return Positioned(
          bottom: 20,
          right: 16,
          child: SizedBox(
            width: 120,
            child: FloatingActionButton.extended(
              heroTag: 'appstorys_capture',
              backgroundColor: Colors.white,
              tooltip: 'Capture screen layout',
              onPressed: _capturing
                  ? null
                  : () async {
            try {
              await _capture(
                screenName: screenName,
                context: screenContext,
                identifyElements: identifyElements,
              );

              if (screenContext.mounted) {
                ScaffoldMessenger.of(screenContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Screen layout captured on screen : $screenName',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              if (screenContext.mounted) {
                ScaffoldMessenger.of(screenContext).showSnackBar(
                  SnackBar(
                    content: Text('Capture failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          label: const Center(
            child: Text(
              'Capture Screen',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
        );
      },
    );
  }

  static Future<void> _capture({
    required String screenName,
    required BuildContext context,
    required IdentifyElementsCallback identifyElements,
  }) async {
    _capturing = true;

    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 250));

      final rootElement = WidgetsBinding.instance.rootElement;

      if (rootElement == null) {
        debugPrint('[CaptureManager] root element null');
        return;
      }

      final rootRenderObject = rootElement.renderObject;
      if (rootRenderObject == null) {
        debugPrint('[CaptureManager] root render object null');
        return;
      }

      final boundary = _findBoundaryFromRoot(rootRenderObject);

      if (boundary == null) {
        debugPrint('[CaptureManager] no boundary found');
        return;
      }

      int retries = 0;
      while (boundary.debugNeedsPaint && retries < 10) {
        await Future.delayed(const Duration(milliseconds: 50));
        retries++;
      }

      final pixelRatio =
          ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

      // Collect layout; guard against unmounted context after async gaps.
      if (!context.mounted) return;
      final layoutJson = _collectLayout(context, pixelRatio);

      final image = await boundary.toImage(pixelRatio: pixelRatio);

      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      await identifyElements(
        screenName,
        pngBytes,
        layoutJson,
      );
    } catch (e) {
      debugPrint('[CaptureManager] capture failed: $e');
    } finally {
      _capturing = false;
    }
  }

  static RenderRepaintBoundary? _findBoundaryFromRoot(
      RenderObject node,
      ) {
    if (node is RenderRepaintBoundary) {
      return node;
    }

    RenderRepaintBoundary? found;

    node.visitChildren((child) {
      found ??= _findBoundaryFromRoot(child);
    });

    return found;
  }

  static String _collectLayout(
      BuildContext context,
      double pixelRatio,
      ) {
    final data = <Map<String, dynamic>>[];

    void visit(Element el) {
      final key = el.widget.key;
      final ro = el.renderObject;

      if (key is ValueKey<String> &&
          ro is RenderBox &&
          ro.hasSize) {
        final pos = ro.localToGlobal(Offset.zero);
        final sz = ro.size;

        data.add({
          'id': key.value,
          'frame': {
            'x': (pos.dx * pixelRatio).round(),
            'y': (pos.dy * pixelRatio).round(),
            'width': (sz.width * pixelRatio).round(),
            'height': (sz.height * pixelRatio).round(),
          },
        });
      }

      el.visitChildren(visit);
    }

    try {
      visit(context as Element);
    } catch (_) {}

    return jsonEncode(data);
  }
}