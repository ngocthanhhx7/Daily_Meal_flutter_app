class SearchFilters {
  const SearchFilters({
    this.maxCalories,
    this.saved = false,
    this.premiumSticker = false,
    this.personalized = true,
  });

  final int? maxCalories;
  final bool saved;
  final bool premiumSticker;
  final bool personalized;

  SearchFilters copyWith({
    int? maxCalories,
    bool clearMaxCalories = false,
    bool? saved,
    bool? premiumSticker,
    bool? personalized,
  }) => SearchFilters(
    maxCalories: clearMaxCalories ? null : maxCalories ?? this.maxCalories,
    saved: saved ?? this.saved,
    premiumSticker: premiumSticker ?? this.premiumSticker,
    personalized: personalized ?? this.personalized,
  );

  Map<String, Object> postQuery(String query) => {
    'q': query.trim(),
    'maxCalories': ?maxCalories,
    if (saved) 'saved': true,
    if (premiumSticker) 'premiumSticker': true,
    'personalized': personalized,
  };

  Map<String, Object> userQuery(String query) => {
    'q': query.trim(),
    'personalized': personalized,
  };
}
