import '../../domain layer/entities/player_per_match_entity.dart';

class PlayerPerMatchModel extends PlayerPerMatchEntity {
  PlayerPerMatchModel({
    required String name,
    required String slug,
    required String shortName,
    required String position,
    required String jerseyNumber,
    required int height,
    required int userCount,
    required int id,
    required Map<String, dynamic> country,
    required String marketValueCurrency,
    required int dateOfBirthTimestamp,
    required Map<String, dynamic> proposedMarketValueRaw,
    required Map<String, dynamic> fieldTranslations,
    required int teamId,
    required int shirtNumber,
    required bool substitute,
    Map<String, dynamic>? statistics,
  }) : super(
         name: name,
         slug: slug,
         shortName: shortName,
         position: position,
         jerseyNumber: jerseyNumber,
         height: height,
         userCount: userCount,
         id: id,
         country: country,
         marketValueCurrency: marketValueCurrency,
         dateOfBirthTimestamp: dateOfBirthTimestamp,
         proposedMarketValueRaw: proposedMarketValueRaw,
         fieldTranslations: fieldTranslations,
         teamId: teamId,
         shirtNumber: shirtNumber,
         substitute: substitute,
         statistics: statistics,
       );

  factory PlayerPerMatchModel.fromJson(Map<String, dynamic> json) {
    // Safely handle the 'player' field
    final playerJson = json['player'] as Map<String, dynamic>? ?? {};

    return PlayerPerMatchModel(
      name: playerJson['name'] as String? ?? 'Unknown',
      slug: playerJson['slug'] as String? ?? 'unknown',
      shortName: playerJson['shortName'] as String? ?? 'Unknown',
      position: playerJson['position'] as String? ?? 'N/A',
      jerseyNumber: playerJson['jerseyNumber'] as String? ?? '0',
      height: playerJson['height'] as int? ?? 0,
      userCount: playerJson['userCount'] as int? ?? 0,
      id: playerJson['id'] as int? ?? 0,
      country: playerJson['country'] as Map<String, dynamic>? ?? {},
      marketValueCurrency:
          playerJson['marketValueCurrency'] as String? ?? 'N/A',
      dateOfBirthTimestamp: playerJson['dateOfBirthTimestamp'] as int? ?? 0,
      proposedMarketValueRaw:
          playerJson['proposedMarketValueRaw'] as Map<String, dynamic>? ?? {},
      fieldTranslations:
          playerJson['fieldTranslations'] as Map<String, dynamic>? ?? {},
      teamId: json['teamId'] as int? ?? 0,
      shirtNumber: json['shirtNumber'] as int? ?? 0,
      substitute: json['substitute'] as bool? ?? false,
      statistics: json['statistics'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player': {
        'name': name,
        'slug': slug,
        'shortName': shortName,
        'position': position,
        'jerseyNumber': jerseyNumber,
        'height': height,
        'userCount': userCount,
        'id': id,
        'country': country,
        'marketValueCurrency': marketValueCurrency,
        'dateOfBirthTimestamp': dateOfBirthTimestamp,
        'proposedMarketValueRaw': proposedMarketValueRaw,
        'fieldTranslations': fieldTranslations,
      },
      'teamId': teamId,
      'shirtNumber': shirtNumber,
      'substitute': substitute,
      'statistics': statistics,
    };
  }

  static List<PlayerPerMatchModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .where((json) => json != null) // Filter out null entries
        .map(
          (json) => PlayerPerMatchModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }
}
