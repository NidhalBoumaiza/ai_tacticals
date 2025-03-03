// lib/features/standings/data_layer/models/team_standing_model.dart
import '../../domain layer/entities/team_standing _entity.dart';

class TeamStandingModel extends TeamStandingEntity {
  TeamStandingModel({
    String? shortName,
    int? id,
    TeamColorsEntity? teamColors,
    FieldTranslationsEntity? fieldTranslations,
    String? countryAlpha2,
    int? position,
    int? matches,
    int? wins,
    int? scoresFor,
    int? scoresAgainst,
    String? scoreDiffFormatted,
    int? points,
    PromotionEntity? promotion,
  }) : super(
         shortName: shortName,
         id: id,
         teamColors: teamColors,
         fieldTranslations: fieldTranslations,
         countryAlpha2: countryAlpha2,
         position: position,
         matches: matches,
         wins: wins,
         scoresFor: scoresFor,
         scoresAgainst: scoresAgainst,
         scoreDiffFormatted: scoreDiffFormatted,
         points: points,
         promotion: promotion,
       );

  factory TeamStandingModel.fromJson(Map<String, dynamic> json) {
    final team = json['team'] as Map<String, dynamic>?;
    final teamColors =
        team != null ? team['teamColors'] as Map<String, dynamic>? : null;
    final fieldTranslations =
        team != null
            ? team['fieldTranslations'] as Map<String, dynamic>?
            : null;
    final country =
        team != null ? team['country'] as Map<String, dynamic>? : null;
    final promotion = json['promotion'] as Map<String, dynamic>?;

    return TeamStandingModel(
      shortName: team != null ? team['shortName'] as String? : null,
      id: team != null ? team['id'] as int? : null,
      teamColors:
          teamColors != null ? TeamColorsModel.fromJson(teamColors) : null,
      fieldTranslations:
          fieldTranslations != null
              ? FieldTranslationsModel.fromJson(fieldTranslations)
              : null,
      countryAlpha2: country != null ? country['alpha2'] as String? : null,
      position: json['position'] as int?,
      matches: json['matches'] as int?,
      wins: json['wins'] as int?,
      scoresFor: json['scoresFor'] as int?,
      scoresAgainst: json['scoresAgainst'] as int?,
      scoreDiffFormatted: json['scoreDiffFormatted'] as String?,
      points: json['points'] as int?,
      promotion: promotion != null ? PromotionModel.fromJson(promotion) : null,
    );
  }
}

class TeamColorsModel extends TeamColorsEntity {
  TeamColorsModel({String? primary, String? secondary, String? text})
    : super(primary: primary, secondary: secondary, text: text);

  factory TeamColorsModel.fromJson(Map<String, dynamic> json) {
    return TeamColorsModel(
      primary: json['primary'] as String?,
      secondary: json['secondary'] as String?,
      text: json['text'] as String?,
    );
  }
}

class FieldTranslationsModel extends FieldTranslationsEntity {
  FieldTranslationsModel({
    String? nameTranslationAr,
    String? shortNameTranslationAr,
  }) : super(
         nameTranslationAr: nameTranslationAr,
         shortNameTranslationAr: shortNameTranslationAr,
       );

  factory FieldTranslationsModel.fromJson(Map<String, dynamic> json) {
    final nameTranslation = json['nameTranslation'] as Map<String, dynamic>?;
    final shortNameTranslation =
        json['shortNameTranslation'] as Map<String, dynamic>?;

    return FieldTranslationsModel(
      nameTranslationAr:
          nameTranslation != null ? nameTranslation['ar'] as String? : null,
      shortNameTranslationAr:
          shortNameTranslation != null
              ? shortNameTranslation['ar'] as String?
              : null,
    );
  }
}

class PromotionModel extends PromotionEntity {
  PromotionModel({String? text, int? id}) : super(text: text, id: id);

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      text: json['text'] as String?,
      id: json['id'] as int?,
    );
  }
}
