// lib/features/standings/domain_layer/entities/team_standing_entity.dart
class TeamStandingEntity {
  final String shortName;
  final int id;
  final TeamColorsEntity teamColors;
  final FieldTranslationsEntity fieldTranslations;
  final String countryAlpha2;
  final int position;
  final int matches;
  final int wins;
  final int scoresFor;
  final int scoresAgainst;
  final String scoreDiffFormatted;
  final int points;
  final PromotionEntity? promotion; // Made promotion nullable

  TeamStandingEntity({
    required this.shortName,
    required this.id,
    required this.teamColors,
    required this.fieldTranslations,
    required this.countryAlpha2,
    required this.position,
    required this.matches,
    required this.wins,
    required this.scoresFor,
    required this.scoresAgainst,
    required this.scoreDiffFormatted,
    required this.points,
    this.promotion, // Made promotion nullable
  });
}

class TeamColorsEntity {
  final String primary;
  final String secondary;
  final String text;

  TeamColorsEntity({
    required this.primary,
    required this.secondary,
    required this.text,
  });
}

class FieldTranslationsEntity {
  final String nameTranslationAr;
  final String shortNameTranslationAr;

  FieldTranslationsEntity({
    required this.nameTranslationAr,
    required this.shortNameTranslationAr,
  });
}

class PromotionEntity {
  final String text;
  final int id;

  PromotionEntity({required this.text, required this.id});
}
