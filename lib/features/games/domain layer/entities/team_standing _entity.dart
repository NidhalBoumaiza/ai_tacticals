// lib/features/standings/domain_layer/entities/team_standing_entity.dart
class TeamStandingEntity {
  final String? shortName;
  final int? id;
  final TeamColorsEntity? teamColors;
  final FieldTranslationsEntity? fieldTranslations;
  final String? countryAlpha2;
  final int? position;
  final int? matches;
  final int? wins;
  final int? scoresFor;
  final int? scoresAgainst;
  final String? scoreDiffFormatted;
  final int? points;
  final PromotionEntity? promotion;

  TeamStandingEntity({
    this.shortName,
    this.id,
    this.teamColors,
    this.fieldTranslations,
    this.countryAlpha2,
    this.position,
    this.matches,
    this.wins,
    this.scoresFor,
    this.scoresAgainst,
    this.scoreDiffFormatted,
    this.points,
    this.promotion,
  });
}

class TeamColorsEntity {
  final String? primary;
  final String? secondary;
  final String? text;

  TeamColorsEntity({this.primary, this.secondary, this.text});
}

class FieldTranslationsEntity {
  final String? nameTranslationAr;
  final String? shortNameTranslationAr;

  FieldTranslationsEntity({
    this.nameTranslationAr,
    this.shortNameTranslationAr,
  });
}

class PromotionEntity {
  final String? text;
  final int? id;

  PromotionEntity({this.text, this.id});
}
