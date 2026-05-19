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
  static String _currentScreen = '';

  static void setEnabled(bool enabled) {
    _enabledNotifier.value = enabled;
  }

  static void setCurrentScreen(String screen) {
    _currentScreen = screen;
  }

  static Widget captureButton({
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
                screenName: _currentScreen,
                context: screenContext,
                identifyElements: identifyElements,
              );

              if (screenContext.mounted) {
                ScaffoldMessenger.of(screenContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Screen layout captured on screen : $_currentScreen',
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

      debugPrint('[CaptureManager] ── capture start ── screen="$screenName"');

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

      final layoutJson = _collectLayout(pixelRatio);

      final image = await boundary.toImage(pixelRatio: pixelRatio);

      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      debugPrint('[CaptureManager] screenshot size=${pngBytes.length} bytes — sending to identifyElements');

      await identifyElements(
        screenName,
        pngBytes,
        layoutJson,
      );

      debugPrint('[CaptureManager] ── capture done ── screen="$screenName"');
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

  static String _collectLayout(double pixelRatio) {
    final data = <Map<String, dynamic>>[];

    void visit(Element el) {
      final key = el.widget.key;
      final ro = el.renderObject;

      if (key is ValueKey<String> && ro is RenderBox && ro.hasSize) {
        final pos = ro.localToGlobal(Offset.zero);
        final sz = ro.size;

        final x = (pos.dx * pixelRatio).round();
        final y = (pos.dy * pixelRatio).round();
        final w = (sz.width * pixelRatio).round();
        final h = (sz.height * pixelRatio).round();

        debugPrint('[CaptureManager] element: id="${key.value}" x=$x y=$y w=$w h=$h');

        data.add({
          'id': key.value,
          'frame': {'x': x, 'y': y, 'width': w, 'height': h},
        });
      }

      el.visitChildren(visit);
    }

    try {
      final root = WidgetsBinding.instance.rootElement;
      if (root != null) visit(root);
    } catch (_) {}

    debugPrint('[CaptureManager] layout done: ${data.length} element(s) on "$_currentScreen"');
    if (data.isEmpty) {
      debugPrint('[CaptureManager] WARNING: no ValueKey<String> widgets found on "$_currentScreen" — add ValueKey to elements you want captured');
    }

    return jsonEncode(data);
  }
}