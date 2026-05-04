// ============================================================================
// MODEL FILE — one per campaign type
// Path: lib/src/models/<campaign>_models.dart
//
// WHAT GOES HERE:
//   - The campaign data class (mirrors the JSON "details" object)
//   - The styling data class (mirrors the JSON "styling" object)
//   - Any nested sub-classes (margins, cross-button config, etc.)
//
// RULES:
//   - All fromJson() take Map<String, dynamic> — never Map<dynamic, dynamic>
//   - All numeric fields use (json['key'] as num?)?.toDouble() — handles both
//     int and double coming from JSON without crashing
//   - Every field is nullable unless the backend guarantees a value
//   - No Flutter/widget imports here — pure data only
// ============================================================================

// ── CAMPAIGN DATA CLASS ──────────────────────────────────────────────────────
// Mirrors the flattened JSON object that _onCampaignsUpdate builds after
// merging raw campaign + details. Fields map 1-to-1 with JSON keys.
class FloaterCampaign {
  final String id;          // always required — used for trackEvent calls
  final String? image;      // static image URL
  final String? lottieData; // Lottie animation URL (.json / .lottie)
  final double? width;      // rendered width in logical pixels
  final double? height;     // rendered height in logical pixels
  final String? link;       // deep-link / URL opened on tap
  final String? position;   // "left" | "right" — where floater is anchored
  final FloaterStyling? styling; // optional — use defaults if null

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

  // fromJson receives the NORMALIZED map built in _onCampaignsUpdate:
  //   final normalized = { ...details, 'id': campaignId }
  // It is NOT the raw campaign object — id is always present.
  factory FloaterCampaign.fromJson(Map<String, dynamic> json) {
    return FloaterCampaign(
      id: (json['id'] as String?) ?? '',
      image: json['image'] as String?,
      lottieData: json['lottie_data'] as String?,
      // (num?)?.toDouble() safely handles int, double, or null from JSON
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      link: json['link'] as String?,
      position: json['position'] as String?,
      // Styling is always nested under 'styling' key — wrap in Map<String,dynamic>
      styling: json['styling'] != null
          ? FloaterStyling.fromJson(Map<String, dynamic>.from(json['styling'] as Map))
          : null,
    );
  }
}

// ── STYLING CLASS ────────────────────────────────────────────────────────────
// Mirrors the "styling" sub-object in the campaign JSON.
// Use const constructor + default values so the widget never needs null checks
// on individual style properties — just pass FloaterStyling() for all-zeros.
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
    // Helper defined locally — handles both num and String values from KMP.
    // KMP serializes all styling fields as String? — double.tryParse handles that.
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
      marginTop: v('marginTop'),
      // NOTE: KMP field names for margins differ from the dashboard JSON keys.
      // Always verify against the actual JSON payload — do not assume key names.
      marginBottom: v('floaterBottomPadding'),
      marginLeft: v('floaterLeftPadding'),
      marginRight: v('floaterRightPadding'),
    );
  }
}
