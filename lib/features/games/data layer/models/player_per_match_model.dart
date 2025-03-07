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
       );

  factory PlayerPerMatchModel.fromJson(Map<String, dynamic> json) {
    return PlayerPerMatchModel(
      name: json['name'] as String,
      slug: json['slug'] as String,
      shortName: json['shortName'] as String,
      position: json['position'] as String,
      jerseyNumber: json['jerseyNumber'] as String,
      height: json['height'] as int,
      userCount: json['userCount'] as int,
      id: json['id'] as int,
      country: json['country'] as Map<String, dynamic>,
      marketValueCurrency: json['marketValueCurrency'] as String,
      dateOfBirthTimestamp: json['dateOfBirthTimestamp'] as int,
      proposedMarketValueRaw:
          json['proposedMarketValueRaw'] as Map<String, dynamic>,
      fieldTranslations: json['fieldTranslations'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
  }

  static List<PlayerPerMatchModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map(
          (json) => PlayerPerMatchModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }
}
