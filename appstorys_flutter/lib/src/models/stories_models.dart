class CampaignStory {
  final String id;
  final String campaignType;
  final List<StoryGroupModel> groups;

  const CampaignStory({
    required this.id,
    required this.campaignType,
    required this.groups,
  });

  factory CampaignStory.fromCampaignMap(Map<String, dynamic> campaign) {
    final details = campaign['details'];

    final rawGroups = details is Map
        ? (details['groups'] as List? ?? const [])
        : (details as List? ?? const []);

    final groups = rawGroups
        .whereType<Map>()
        .map((e) => StoryGroupModel.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return CampaignStory(
      id: (campaign['id'] ?? '').toString(),
      campaignType: (campaign['campaign_type'] ?? '').toString(),
      groups: groups,
    );
  }
}

class StoryGroupModel {
  final String id;
  final String? name;
  final Map<String, dynamic>? styling;
  final String thumbnail;
  final String ringColor;
  final String nameColor;
  final int order;
  final List<StorySlideModel> slides;

  const StoryGroupModel({
    required this.id,
    required this.name,
    required this.styling,
    required this.thumbnail,
    required this.ringColor,
    required this.nameColor,
    required this.order,
    required this.slides,
  });

  factory StoryGroupModel.fromMap(Map<String, dynamic> map) {
    final rawSlides = (map['slides'] as List? ?? const []);
    final slides = rawSlides
        .whereType<Map>()
        .map((e) => StorySlideModel.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return StoryGroupModel(
      id: (map['id'] ?? '').toString(),
      name: map['name']?.toString(),
      styling: map['styling'] is Map
          ? Map<String, dynamic>.from(map['styling'] as Map)
          : null,
      thumbnail: (map['thumbnail'] ?? '').toString(),
      ringColor: (map['ringColor'] ?? '#CCCCCC').toString(),
      nameColor: (map['nameColor'] ?? '#000000').toString(),
      order: _toInt(map['order'], 0),
      slides: slides,
    );
  }
}

class StorySlideModel {
  final String id;
  final String parent;
  final int order;
  final String? image;
  final String? video;
  final String? link;
  final String? buttonText;
  final String? content;
  final Map<String, dynamic>? styling;
  final Map<dynamic, dynamic>? crossButton;
  final Map<dynamic, dynamic>? soundToggle;

  const StorySlideModel({
    required this.id,
    required this.parent,
    required this.order,
    required this.image,
    required this.video,
    required this.link,
    required this.buttonText,
    required this.content,
    required this.styling,
    required this.crossButton,
    required this.soundToggle,
  });

  factory StorySlideModel.fromMap(Map<String, dynamic> map) {
    return StorySlideModel(
      id: (map['id'] ?? '').toString(),
      parent: (map['parent'] ?? '').toString(),
      order: _toInt(map['order'], 0),
      image: map['image']?.toString(),
      video: map['video']?.toString(),
      link: map['link']?.toString(),
      buttonText: map['button_text']?.toString(),
      content: map['content']?.toString(),
      styling: map['styling'] is Map
          ? Map<String, dynamic>.from(map['styling'] as Map)
          : null,
      crossButton: map['crossButton'] is Map
          ? Map<dynamic, dynamic>.from(map['crossButton'] as Map)
          : null,
      soundToggle: map['soundToggle'] is Map
          ? Map<dynamic, dynamic>.from(map['soundToggle'] as Map)
          : null,
    );
  }
}

int _toInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

