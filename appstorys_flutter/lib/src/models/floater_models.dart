class FloaterCampaign {
  final String id;
  final String? image;
  final String? lottieData;
  final double? width;
  final double? height;
  final String? link;
  final String? position; // "left" | "right"
  final FloaterStyling? styling;

  FloaterCampaign({
    required this.id,
    this.image,
    this.lottieData,
    this.width,
    this.height,
    this.link,
    this.position,
    this.styling,
  });

  factory FloaterCampaign.fromJson(Map<String, dynamic> json) {
    return FloaterCampaign(
      id: (json['id'] as String?) ?? '',
      image: json['image'] as String?,
      lottieData: json['lottie_data'] as String?,
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      link: json['link'] as String?,
      position: json['position'] as String?,
      styling: json['styling'] != null
          ? FloaterStyling.fromJson(Map<String, dynamic>.from(json['styling'] as Map))
          : null,
    );
  }
}

class FloaterStyling {
  final double topLeftRadius;
  final double topRightRadius;
  final double bottomLeftRadius;
  final double bottomRightRadius;
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;

  const FloaterStyling({
    this.topLeftRadius = 0,
    this.topRightRadius = 0,
    this.bottomLeftRadius = 0,
    this.bottomRightRadius = 0,
    this.marginTop = 0,
    this.marginBottom = 0,
    this.marginLeft = 0,
    this.marginRight = 0,
  });

  factory FloaterStyling.fromJson(Map<String, dynamic> json) {
    // KMP serializes all FloaterStyling fields as String? — handle both String and num.
    double v(String key) {
      final val = json[key];
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0;
    }
    return FloaterStyling(
      topLeftRadius: v('topLeftRadius'),
      topRightRadius: v('topRightRadius'),
      bottomLeftRadius: v('bottomLeftRadius'),
      bottomRightRadius: v('bottomRightRadius'),
      // KMP field names for margins differ from dashboard JSON keys.
      marginTop: v('marginTop'),
      marginBottom: v('floaterBottomPadding'),
      marginLeft: v('floaterLeftPadding'),
      marginRight: v('floaterRightPadding'),
    );
  }
}
