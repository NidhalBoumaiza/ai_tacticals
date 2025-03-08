class PlayerPerMatchEntity {
  final String name;
  final String slug;
  final String shortName;
  final String position;
  final String jerseyNumber;
  final int height;
  final int userCount;
  final int id;
  final Map<String, dynamic> country;
  final String marketValueCurrency;
  final int dateOfBirthTimestamp;
  final Map<String, dynamic> proposedMarketValueRaw;
  final Map<String, dynamic> fieldTranslations;
  final int teamId; // New field
  final int shirtNumber; // New field
  final bool substitute; // New field
  final Map<String, dynamic>? statistics; // New field

  PlayerPerMatchEntity({
    required this.name,
    required this.slug,
    required this.shortName,
    required this.position,
    required this.jerseyNumber,
    required this.height,
    required this.userCount,
    required this.id,
    required this.country,
    required this.marketValueCurrency,
    required this.dateOfBirthTimestamp,
    required this.proposedMarketValueRaw,
    required this.fieldTranslations,
    required this.teamId,
    required this.shirtNumber,
    required this.substitute,
    this.statistics,
  });
}
