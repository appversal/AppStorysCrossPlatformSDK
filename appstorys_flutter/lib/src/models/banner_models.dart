// Data models for AppStorys banner campaigns.
// This module provides the data structures needed to parse and render
// banner campaigns fetched from the AppStorys API via the Dart plugin.

class BannerCampaign {
  final String id;
  final String? image;
  final double? width;
  final double? height;
  final String? link;
  final BannerStyling? styling;
  final String? lottieData;

  BannerCampaign({
    required this.id,
    this.image,
    this.width,
    this.height,
    this.link,
    this.styling,
    this.lottieData,
  });

  factory BannerCampaign.fromJson(Map<String, dynamic> json) {
    return BannerCampaign(
      id: (json['id'] as String?) ?? '',
      image: json['image'] as String?,
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      link: json['link'] as String?,
      styling: json['styling'] != null
          ? BannerStyling.fromJson(json['styling'] as Map<String, dynamic>)
          : null,
      lottieData: json['lottie_data'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'image': image,
        'width': width,
        'height': height,
        'link': link,
        'styling': styling?.toJson(),
        'lottie_data': lottieData,
      };
}

class BannerStyling {
  final double? topLeftRadius;
  final double? topRightRadius;
  final double? bottomLeftRadius;
  final double? bottomRightRadius;
  final double? marginBottom;
  final double? marginLeft;
  final double? marginRight;
  final CrossButtonStyling? crossButton;

  BannerStyling({
    this.topLeftRadius,
    this.topRightRadius,
    this.bottomLeftRadius,
    this.bottomRightRadius,
    this.marginBottom,
    this.marginLeft,
    this.marginRight,
    this.crossButton,
  });

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory BannerStyling.fromJson(Map<String, dynamic> json) {
    return BannerStyling(
      topLeftRadius: _toDouble(json['topLeftRadius']),
      topRightRadius: _toDouble(json['topRightRadius']),
      bottomLeftRadius: _toDouble(json['bottomLeftRadius']),
      bottomRightRadius: _toDouble(json['bottomRightRadius']),
      marginBottom: _toDouble(json['marginBottom']),
      marginLeft: _toDouble(json['marginLeft'] ?? json['margin_left']),
      marginRight: _toDouble(json['marginRight'] ?? json['margin_right']),
      crossButton: json['crossButton'] != null
          ? CrossButtonStyling.fromJson(Map<String, dynamic>.from(json['crossButton'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'topLeftRadius': topLeftRadius,
        'topRightRadius': topRightRadius,
        'bottomLeftRadius': bottomLeftRadius,
        'bottomRightRadius': bottomRightRadius,
        'marginBottom': marginBottom,
        'margin_left': marginLeft,
        'margin_right': marginRight,
        'crossButton': crossButton?.toJson(),
      };
}

class CrossButtonStyling {
  final bool? enabled;
  final double? size;
  final Map<String, String>? colorObj;  // {cross, fill, stroke}
  final String? margin;

  CrossButtonStyling({
    this.enabled,
    this.size,
    this.colorObj,
    this.margin,
  });

  factory CrossButtonStyling.fromJson(Map<String, dynamic> json) {
    final dynamic colorRaw = json['color'];
    return CrossButtonStyling(
      enabled: json['enabled'] as bool?,
      size: BannerStyling._toDouble(json['size']),
      colorObj: colorRaw is Map
          ? colorRaw.map((key, value) => MapEntry('$key', '${value ?? ''}'))
          : null,
      margin: json['margin']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'size': size,
        'color': colorObj,
        'margin': margin,
      };
}
