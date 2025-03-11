// features/games/data layer/models/player_model.dart
import '../../domain layer/entities/player_entity.dart';

class PlayerModel extends PlayerEntityy {
  const PlayerModel({
    super.id,
    super.name,
    super.slug,
    super.shortName,
    super.position,
    super.shirtNumber,
    super.jerseyNumber,
    super.age,
    super.height,
    super.userCount,
    super.countryAlpha2,
    super.countryAlpha2Lower,
    super.countryAlpha3,
    super.marketValueCurrency,
    super.dateOfBirthTimestamp,
    super.proposedMarketValue,
    super.fieldTranslations,
    super.teamId,
    super.substitute,
    super.statistics,
  });

  factory PlayerModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlayerModel();

    final playerData = json['player'] as Map<String, dynamic>? ?? {};
    final country = playerData['country'] as Map<String, dynamic>? ?? {};
    final alpha2 = country['alpha2'] as String? ?? '';
    final alpha3 = country['alpha3'] as String? ?? '';
    final proposedMarketValueRaw =
        playerData['proposedMarketValueRaw'] as Map<String, dynamic>? ?? {};
    final fieldTranslations =
        playerData['fieldTranslations'] as Map<String, dynamic>? ?? {};
    final statistics = json['statistics'] as Map<String, dynamic>? ?? {};
    final ratingVersions =
        statistics['ratingVersions'] as Map<String, dynamic>? ?? {};

    return PlayerModel(
      id: playerData['id'] as int?,
      name: playerData['name'] as String?,
      slug: playerData['slug'] as String?,
      shortName: playerData['shortName'] as String?,
      position: _mapPosition(playerData['position'] as String?),
      shirtNumber: playerData['shirtNumber'] as int?,
      jerseyNumber: playerData['jerseyNumber'] as String?,
      age: _calculateAge(playerData['dateOfBirthTimestamp'] as int?),
      height: playerData['height'] as int?,
      userCount: playerData['userCount'] as int?,
      countryAlpha2: alpha2,
      countryAlpha2Lower: alpha2.toLowerCase(),
      countryAlpha3: getProperAlpha3(alpha2, alpha3),
      marketValueCurrency: playerData['marketValueCurrency'] as String?,
      dateOfBirthTimestamp: playerData['dateOfBirthTimestamp'] as int?,
      proposedMarketValue: ProposedMarketValue(
        value: proposedMarketValueRaw['value'] as int? ?? 0,
        currency: proposedMarketValueRaw['currency'] as String? ?? '',
      ),
      fieldTranslations: FieldTranslations(
        nameTranslation: Map<String, String>.from(
          fieldTranslations['nameTranslation'] as Map? ?? {},
        ),
        shortNameTranslation: Map<String, String>.from(
          fieldTranslations['shortNameTranslation'] as Map? ?? {},
        ),
      ),
      teamId: json['teamId'] as int?,
      substitute: json['substitute'] as bool? ?? false,
      statistics: PlayerStatistics(
        totalPass: statistics['totalPass'] as int? ?? 0,
        accuratePass: statistics['accuratePass'] as int? ?? 0,
        totalLongBalls: statistics['totalLongBalls'] as int? ?? 0,
        accurateLongBalls: statistics['accurateLongBalls'] as int? ?? 0,
        goalAssist: statistics['goalAssist'] as int? ?? 0,
        totalCross: statistics['totalCross'] as int? ?? 0,
        duelLost: statistics['duelLost'] as int? ?? 0,
        duelWon: statistics['duelWon'] as int? ?? 0,
        challengeLost: statistics['challengeLost'] as int? ?? 0,
        dispossessed: statistics['dispossessed'] as int? ?? 0,
        totalClearance: statistics['totalClearance'] as int? ?? 0,
        lastManTackle: statistics['lastManTackle'] as int? ?? 0,
        totalTackle: statistics['totalTackle'] as int? ?? 0,
        wasFouled: statistics['wasFouled'] as int? ?? 0,
        fouls: statistics['fouls'] as int? ?? 0,
        minutesPlayed: statistics['minutesPlayed'] as int? ?? 0,
        touches: statistics['touches'] as int? ?? 0,
        rating: (statistics['rating'] as num?)?.toDouble() ?? 0.0,
        possessionLostCtrl: statistics['possessionLostCtrl'] as int? ?? 0,
        ratingVersions: RatingVersions(
          original: (ratingVersions['original'] as num?)?.toDouble() ?? 0.0,
          alternative: (ratingVersions['alternative'] as num?)?.toDouble(),
        ),
        goalsPrevented: (statistics['goalsPrevented'] as num?)?.toDouble(),
        expectedAssists: (statistics['expectedAssists'] as num?)?.toDouble(),
      ),
    );
  }

  static String? _mapPosition(String? shortCode) {
    if (shortCode == null) return null;
    return switch (shortCode.toUpperCase()) {
      'F' => 'Forward',
      'M' => 'Midfield',
      'D' => 'Defense',
      'G' => 'Goalkeeper',
      _ => 'Other Position',
    };
  }

  static int? _calculateAge(int? timestamp) {
    if (timestamp == null) return null;
    final dob = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    return now.year -
        dob.year -
        (now.isBefore(DateTime(now.year, dob.month, dob.day)) ? 1 : 0);
  }

  static String? getProperAlpha3(String? alpha2, String? originalAlpha3) {
    if (alpha2 == null || originalAlpha3 == null) return null;
    return alpha2 == 'ES' ? 'ESP' : originalAlpha3;
  }

  Map<String, dynamic> toJson() => {
    'player': {
      'id': id,
      'name': name,
      'slug': slug,
      'shortName': shortName,
      'position': position,
      'shirtNumber': shirtNumber,
      'jerseyNumber': jerseyNumber,
      'height': height,
      'userCount': userCount,
      'dateOfBirthTimestamp': dateOfBirthTimestamp,
      'marketValueCurrency': marketValueCurrency,
      'proposedMarketValueRaw': {
        'value': proposedMarketValue?.value,
        'currency': proposedMarketValue?.currency,
      },
      'fieldTranslations': {
        'nameTranslation': fieldTranslations?.nameTranslation,
        'shortNameTranslation': fieldTranslations?.shortNameTranslation,
      },
      'country': {'alpha2': countryAlpha2, 'alpha3': countryAlpha3},
    },
    'teamId': teamId,
    'substitute': substitute,
    'statistics': {
      'totalPass': statistics?.totalPass,
      'accuratePass': statistics?.accuratePass,
      'totalLongBalls': statistics?.totalLongBalls,
      'accurateLongBalls': statistics?.accurateLongBalls,
      'goalAssist': statistics?.goalAssist,
      'totalCross': statistics?.totalCross,
      'duelLost': statistics?.duelLost,
      'duelWon': statistics?.duelWon,
      'challengeLost': statistics?.challengeLost,
      'dispossessed': statistics?.dispossessed,
      'totalClearance': statistics?.totalClearance,
      'lastManTackle': statistics?.lastManTackle,
      'totalTackle': statistics?.totalTackle,
      'wasFouled': statistics?.wasFouled,
      'fouls': statistics?.fouls,
      'minutesPlayed': statistics?.minutesPlayed,
      'touches': statistics?.touches,
      'rating': statistics?.rating,
      'possessionLostCtrl': statistics?.possessionLostCtrl,
      'ratingVersions': {
        'original': statistics?.ratingVersions.original,
        'alternative': statistics?.ratingVersions.alternative,
      },
      'goalsPrevented': statistics?.goalsPrevented,
      'expectedAssists': statistics?.expectedAssists,
    },
  };

  /// Converts the PlayerModel to a PlayerEntity
  PlayerEntityy toEntity() => PlayerEntityy(
    id: id,
    name: name,
    slug: slug,
    shortName: shortName,
    position: position,
    shirtNumber: shirtNumber,
    jerseyNumber: jerseyNumber,
    age: age,
    height: height,
    userCount: userCount,
    countryAlpha2: countryAlpha2,
    countryAlpha2Lower: countryAlpha2?.toLowerCase(),
    // Ensure this is derived if needed
    countryAlpha3: countryAlpha3,
    marketValueCurrency: marketValueCurrency,
    dateOfBirthTimestamp: dateOfBirthTimestamp,
    proposedMarketValue: proposedMarketValue,
    fieldTranslations: fieldTranslations,
    teamId: teamId,
    substitute: substitute,
    statistics: statistics,
  );

  /// Converts a PlayerEntity back to a PlayerModel
  static PlayerModel fromEntity(PlayerEntityy entity) => PlayerModel(
    id: entity.id,
    name: entity.name,
    slug: entity.slug,
    shortName: entity.shortName,
    position: entity.position,
    shirtNumber: entity.shirtNumber,
    jerseyNumber: entity.jerseyNumber,
    age: entity.age,
    height: entity.height,
    userCount: entity.userCount,
    countryAlpha2: entity.countryAlpha2,
    countryAlpha2Lower: entity.countryAlpha2?.toLowerCase(),
    countryAlpha3: entity.countryAlpha3,
    marketValueCurrency: entity.marketValueCurrency,
    dateOfBirthTimestamp: entity.dateOfBirthTimestamp,
    proposedMarketValue: entity.proposedMarketValue,
    fieldTranslations: entity.fieldTranslations,
    teamId: entity.teamId,
    substitute: entity.substitute,
    statistics: entity.statistics,
  );
}
