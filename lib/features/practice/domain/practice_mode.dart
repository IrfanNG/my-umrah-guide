enum PracticeMode {
  manual,
  locationBased;

  String get label {
    switch (this) {
      case PracticeMode.manual:
        return 'Manual';
      case PracticeMode.locationBased:
        return 'Location-Based';
    }
  }

  String get description {
    switch (this) {
      case PracticeMode.manual:
        return 'Open practice flow for demo and revision.';
      case PracticeMode.locationBased:
        return 'Follow Miqat, Tawaf, then Sa\'i sequence.';
    }
  }

  static PracticeMode fromValue(String? value) {
    return PracticeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => PracticeMode.manual,
    );
  }
}
