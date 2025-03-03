// lib/features/standings/data_layer/models/team_standing_model.dart
import '../../../../core/error/exceptions.dart';
import '../../domain layer/entities/team_standing _entity.dart';

class TeamStandingModel extends TeamStandingEntity {
  TeamStandingModel({
    required String shortName,
    required int id,
    required TeamColorsEntity teamColors,
    required FieldTranslationsEntity fieldTranslations,
    required String countryAlpha2,
    required int position,
    required int matches,
    required int wins,
    required int scoresFor,
    required int scoresAgainst,
    required String scoreDiffFormatted,
    required int points,
    required PromotionEntity promotion,
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
    final team = json['team'] as Map<String, dynamic>?; // Allow null
    if (team == null) {
      throw ServerException('Team data is missing in standings JSON');
    }

    final teamColors =
        team['teamColors'] as Map<String, dynamic>? ??
        {'primary': '#000000', 'secondary': '#000000', 'text': '#000000'};
    final fieldTranslations =
        team['fieldTranslations'] as Map<String, dynamic>? ??
        {
          'nameTranslation': {'ar': ''},
          'shortNameTranslation': {'ar': ''},
        };
    final country =
        team['country'] as Map<String, dynamic>? ?? {'alpha2': 'UNKNOWN'};
    final promotion =
        json['promotion'] as Map<String, dynamic>? ??
        {'text': 'Unknown', 'id': 0};

    return TeamStandingModel(
      shortName: team['shortName'] as String? ?? 'Unknown Team',
      id: team['id'] as int? ?? 0,
      teamColors: TeamColorsModel.fromJson(teamColors),
      fieldTranslations: FieldTranslationsModel.fromJson(fieldTranslations),
      countryAlpha2: country['alpha2'] as String? ?? 'UNKNOWN',
      position: json['position'] as int? ?? 0,
      matches: json['matches'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      scoresFor: json['scoresFor'] as int? ?? 0,
      scoresAgainst: json['scoresAgainst'] as int? ?? 0,
      scoreDiffFormatted: json['scoreDiffFormatted'] as String? ?? '0',
      points: json['points'] as int? ?? 0,
      promotion: PromotionModel.fromJson(promotion),
    );
  }
}

class TeamColorsModel extends TeamColorsEntity {
  TeamColorsModel({
    required String primary,
    required String secondary,
    required String text,
  }) : super(primary: primary, secondary: secondary, text: text);

  factory TeamColorsModel.fromJson(Map<String, dynamic> json) {
    return TeamColorsModel(
      primary: json['primary'] as String? ?? '#000000',
      secondary: json['secondary'] as String? ?? '#000000',
      text: json['text'] as String? ?? '#000000',
    );
  }
}

class FieldTranslationsModel extends FieldTranslationsEntity {
  FieldTranslationsModel({
    required String nameTranslationAr,
    required String shortNameTranslationAr,
  }) : super(
         nameTranslationAr: nameTranslationAr,
         shortNameTranslationAr: shortNameTranslationAr,
       );

  factory FieldTranslationsModel.fromJson(Map<String, dynamic> json) {
    final nameTranslation =
        json['nameTranslation'] as Map<String, dynamic>? ?? {'ar': ''};
    final shortNameTranslation =
        json['shortNameTranslation'] as Map<String, dynamic>? ?? {'ar': ''};

    return FieldTranslationsModel(
      nameTranslationAr: nameTranslation['ar'] as String? ?? '',
      shortNameTranslationAr: shortNameTranslation['ar'] as String? ?? '',
    );
  }
}

class PromotionModel extends PromotionEntity {
  PromotionModel({required String text, required int id})
    : super(text: text, id: id);

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      text: json['text'] as String? ?? 'Unknown',
      id: json['id'] as int? ?? 0,
    );
  }
}
