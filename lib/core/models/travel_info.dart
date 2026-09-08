// AI-generated, web-grounded answers for the travel-essentials tools. Each
// is parsed from the JSON string the `ai-assistant` edge function returns
// in `structuredInfo` mode.

List<String> _stringList(dynamic value) =>
    (value as List<dynamic>?)
        ?.map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList() ??
    const [];

/// A local food guide for a place — must-try dishes, local drinks, and
/// practical dining tips.
class FoodGuide {
  const FoodGuide({
    required this.summary,
    required this.dishes,
    required this.drinks,
    required this.tips,
  });

  final String summary;
  final List<FoodItem> dishes;
  final List<FoodItem> drinks;
  final List<String> tips;

  bool get isEmpty => dishes.isEmpty && drinks.isEmpty && tips.isEmpty;

  factory FoodGuide.fromJson(Map<String, dynamic> json) {
    return FoodGuide(
      summary: (json['summary'] as String? ?? '').trim(),
      dishes: FoodItem._listFrom(json['dishes']),
      drinks: FoodItem._listFrom(json['drinks']),
      tips: _stringList(json['tips']),
    );
  }
}

class FoodItem {
  const FoodItem({
    required this.name,
    required this.description,
    this.whereToTry,
  });

  final String name;
  final String description;

  /// Only set for dishes, not drinks.
  final String? whereToTry;

  static List<FoodItem> _listFrom(dynamic value) =>
      (value as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(FoodItem._fromJson)
          .where((item) => item.name.isNotEmpty)
          .toList() ??
      const [];

  factory FoodItem._fromJson(Map<String, dynamic> json) {
    final where = (json['whereToTry'] as String?)?.trim();
    return FoodItem(
      name: (json['name'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      whereToTry: where != null && where.isNotEmpty ? where : null,
    );
  }
}

/// A guide to staying connected in a place — local carriers, eSIM options,
/// prices, and where to buy.
class SimGuide {
  const SimGuide({
    required this.summary,
    required this.options,
    required this.whereToBuy,
    required this.tips,
  });

  final String summary;
  final List<SimOption> options;
  final List<String> whereToBuy;
  final List<String> tips;

  bool get isEmpty => options.isEmpty && whereToBuy.isEmpty && tips.isEmpty;

  factory SimGuide.fromJson(Map<String, dynamic> json) {
    return SimGuide(
      summary: (json['summary'] as String? ?? '').trim(),
      options:
          (json['options'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(SimOption.fromJson)
              .where((o) => o.provider.isNotEmpty)
              .toList() ??
          const [],
      whereToBuy: _stringList(json['whereToBuy']),
      tips: _stringList(json['tips']),
    );
  }
}

class SimOption {
  const SimOption({
    required this.provider,
    required this.type,
    required this.typicalPrice,
    required this.notes,
  });

  final String provider;

  /// "Physical SIM", "eSIM", or similar.
  final String type;
  final String typicalPrice;
  final String notes;

  factory SimOption.fromJson(Map<String, dynamic> json) {
    return SimOption(
      provider: (json['provider'] as String? ?? '').trim(),
      type: (json['type'] as String? ?? '').trim(),
      typicalPrice: (json['typicalPrice'] as String? ?? '').trim(),
      notes: (json['notes'] as String? ?? '').trim(),
    );
  }
}

/// Tourist visa requirements for a passport holder from one country
/// travelling to another.
class VisaRequirement {
  const VisaRequirement({
    required this.requirement,
    required this.summary,
    required this.allowedStay,
    required this.cost,
    required this.processingTime,
    required this.howToApply,
    required this.documents,
    required this.notes,
  });

  /// "Visa-free", "Visa on arrival", "eVisa", "Visa required", or "Unknown".
  final String requirement;
  final String summary;
  final String allowedStay;
  final String cost;
  final String processingTime;
  final String howToApply;
  final List<String> documents;
  final List<String> notes;

  bool get isEmpty => summary.isEmpty && requirement.isEmpty;

  factory VisaRequirement.fromJson(Map<String, dynamic> json) {
    final requirement = (json['requirement'] as String? ?? '').trim();
    return VisaRequirement(
      requirement: requirement.isEmpty ? 'Unknown' : requirement,
      summary: (json['summary'] as String? ?? '').trim(),
      allowedStay: (json['allowedStay'] as String? ?? '').trim(),
      cost: (json['cost'] as String? ?? '').trim(),
      processingTime: (json['processingTime'] as String? ?? '').trim(),
      howToApply: (json['howToApply'] as String? ?? '').trim(),
      documents: _stringList(json['documents']),
      notes: _stringList(json['notes']),
    );
  }
}
