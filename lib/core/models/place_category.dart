/// The kinds of things a traveler searches for in a location — attractions,
/// somewhere to stay, somewhere to eat, and so on. Drives both the label
/// shown on the home screen's filter chips and the phrasing sent to the AI
/// place lookup (see [AiAssistantRepository.fetchPlaces]).
enum PlaceCategory {
  attractions('Attractions', 'top attractions and sights worth visiting'),
  hotels('Hotels', 'well-reviewed hotels and places to stay'),
  shortlets(
    'Shortlets',
    'short-let and serviced apartments for a short stay',
  ),
  restaurants('Restaurants', 'popular restaurants to eat at'),
  cafes('Cafés', 'notable cafés, bakeries and coffee shops'),
  thingsToDo('Things to do', 'fun activities, tours and experiences to book'),
  nightlife('Nightlife', 'bars, clubs and nightlife spots'),
  shopping('Shopping', 'shopping streets, markets and malls');

  const PlaceCategory(this.label, this.promptNoun);

  /// Short, user-facing chip label.
  final String label;

  /// Noun phrase dropped into `List <promptNoun> in <location>.` — the
  /// message the AI place lookup answers with a structured list.
  final String promptNoun;

  /// The default category shown before the user picks another.
  static const PlaceCategory initial = attractions;

  /// Section heading for a resolved [location].
  String headingFor(String location) => this == attractions
      ? 'Places to Visit in $location'
      : '$label in $location';
}
