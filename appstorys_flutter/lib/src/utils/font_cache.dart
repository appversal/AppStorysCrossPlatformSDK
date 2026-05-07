import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FontCache {
  static const String _tag = 'FontCache';
  static const String _fontCacheDir = 'custom_fonts';

  static final Map<String, String> _fontFamilyCache = {};
  static final Set<String> _downloadingFonts = {};

  /// Resolves a text style font value.
  /// - URL: downloads/registers and returns the runtime family name
  /// - plain family: returns as-is
  /// - null/empty: returns null
  static Future<String?> resolveFontFamily(String? fontValue) async {
    if (fontValue == null || fontValue.trim().isEmpty) return null;
    if (isFontUrl(fontValue)) {
      return loadFont(fontUrl: fontValue);
    }
    return fontValue;
  }

  static bool isFontUrl(String value) {
    final v = value.trim().toLowerCase();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  /// Load a custom font from URL with caching support.
  /// Returns the registered font-family name for TextStyle(fontFamily: ...)
  /// or null if loading fails.
  static Future<String?> loadFont({
    required String? fontUrl,
    String? fontFamily,
  }) async {
    if (fontUrl == null || fontUrl.trim().isEmpty) return null;

    try {
      if (_fontFamilyCache.containsKey(fontUrl)) {
        log('Font loaded from memory cache: $fontUrl', name: _tag);
        return _fontFamilyCache[fontUrl];
      }

      final cacheDir = await _getFontCacheDir();
      final fontFile = _getFontFile(cacheDir, fontUrl);

      if (!fontFile.existsSync()) {
        await _downloadFont(fontUrl, fontFile);
      }

      final resolvedFamily = fontFamily ?? _familyNameFromUrl(fontUrl);
      final success = await _loadFontFromFile(
        fontFile: fontFile,
        fontFamily: resolvedFamily,
      );

      if (!success) return null;

      _fontFamilyCache[fontUrl] = resolvedFamily;
      log('Font loaded successfully: $fontUrl', name: _tag);
      return resolvedFamily;
    } catch (e) {
      log('Failed to load font from $fontUrl: $e', name: _tag);
      return null;
    }
  }

  static Future<Directory> _getFontCacheDir() async {
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/$_fontCacheDir');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  static File _getFontFile(Directory cacheDir, String fontUrl) {
    String extension = fontUrl.split('.').last.split('?').first;
    if (extension.length > 4 || extension.isEmpty) extension = 'ttf';
    final hash = fontUrl.hashCode.abs();
    return File('${cacheDir.path}/font_$hash.$extension');
  }

  static Future<void> _downloadFont(String fontUrl, File destFile) async {
    if (_downloadingFonts.contains(fontUrl)) {
      log('Font already downloading, waiting: $fontUrl', name: _tag);
      while (_downloadingFonts.contains(fontUrl)) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _downloadingFonts.add(fontUrl);

    try {
      log('Downloading font: $fontUrl', name: _tag);
      final response =
          await http.get(Uri.parse(fontUrl)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await destFile.writeAsBytes(response.bodyBytes);
        log('Font downloaded successfully: $fontUrl', name: _tag);
      } else {
        throw HttpException('Bad status ${response.statusCode} for $fontUrl');
      }
    } catch (e) {
      log('Failed to download font $fontUrl: $e', name: _tag);
      if (destFile.existsSync()) destFile.deleteSync();
      rethrow;
    } finally {
      _downloadingFonts.remove(fontUrl);
    }
  }

  static Future<bool> _loadFontFromFile({
    required File fontFile,
    required String fontFamily,
  }) async {
    try {
      if (!fontFile.existsSync()) {
        log('Font file not found: ${fontFile.path}', name: _tag);
        return false;
      }

      final loader = FontLoader(fontFamily);
      final bytes = await fontFile.readAsBytes();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();

      return true;
    } catch (e) {
      log('Error loading font from file ${fontFile.path}: $e', name: _tag);
      return false;
    }
  }

  static String _familyNameFromUrl(String fontUrl) {
    return fontUrl
        .split('/')
        .last
        .split('?')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  static Future<void> clearCache() async {
    try {
      final cacheDir = await _getFontCacheDir();
      if (cacheDir.existsSync()) {
        cacheDir.listSync().whereType<File>().forEach((f) => f.deleteSync());
      }
      _fontFamilyCache.clear();
      log('Font cache cleared', name: _tag);
    } catch (e) {
      log('Error clearing font cache: $e', name: _tag);
    }
  }

  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getFontCacheDir();
      int total = 0;
      for (final f in cacheDir.listSync().whereType<File>()) {
        total += f.lengthSync();
      }
      return total;
    } catch (e) {
      log('Error calculating cache size: $e', name: _tag);
      return 0;
    }
  }

  static Future<bool> isFontCached(String fontUrl) async {
    final cacheDir = await _getFontCacheDir();
    final fontFile = _getFontFile(cacheDir, fontUrl);
    return fontFile.existsSync();
  }
}

