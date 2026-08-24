class ItineraryDay {
  const ItineraryDay({required this.day, this.activities = const []});

  final int day;
  final List<String> activities;

  Map<String, dynamic> toJson() => {'day': day, 'activities': activities};

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    return ItineraryDay(
      day: (json['day'] as num).toInt(),
      activities: List<String>.from(json['activities'] as List? ?? const []),
    );
  }
}

/// An AI-generated itinerary before it has been saved (no id/createdAt yet).
class ItineraryDraft {
  const ItineraryDraft({
    required this.title,
    this.description,
    this.days = const [],
  });

  final String title;
  final String? description;
  final List<ItineraryDay> days;

  factory ItineraryDraft.fromJson(Map<String, dynamic> json) {
    return ItineraryDraft(
      title: json['title'] as String? ?? 'Your trip',
      description: json['description'] as String?,
      days: List<Map<String, dynamic>>.from(
        json['days'] as List? ?? const [],
      ).map(ItineraryDay.fromJson).toList(),
    );
  }
}

class Itinerary {
  const Itinerary({
    required this.id,
    required this.title,
    this.description,
    this.destinationId,
    this.destinationName,
    required this.durationDays,
    this.budget,
    this.isAiGenerated = false,
    this.days = const [],
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? destinationId;
  final String? destinationName;
  final int durationDays;
  final String? budget;
  final bool isAiGenerated;
  final List<ItineraryDay> days;
  final DateTime createdAt;

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      destinationId: json['destination_id'] as String?,
      destinationName: json['destination_name'] as String?,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 1,
      budget: json['budget'] as String?,
      isAiGenerated: json['is_ai_generated'] as bool? ?? false,
      days: List<Map<String, dynamic>>.from(
        json['days'] as List? ?? const [],
      ).map(ItineraryDay.fromJson).toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
