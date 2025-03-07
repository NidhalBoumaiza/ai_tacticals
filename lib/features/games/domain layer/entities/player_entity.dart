// features/games/domain layer/entities/player_entity.dart
import 'package:equatable/equatable.dart';

class PlayerEntityy extends Equatable {
  final int? id;
  final String? name;
  final String? slug; // Added
  final String? shortName; // Added
  final String? position;
  final int? shirtNumber;
  final String? jerseyNumber; // Added
  final int? age;
  final int? height; // Added
  final int? userCount; // Added
  final String? countryAlpha2;
  final String? countryAlpha2Lower;
  final String? countryAlpha3;
  final String? marketValueCurrency; // Added
  final int? dateOfBirthTimestamp; // Added
  final ProposedMarketValue? proposedMarketValue; // Added
  final FieldTranslations? fieldTranslations; // Added
  final int? teamId; // Added
  final bool? substitute; // Added
  final PlayerStatistics? statistics; // Added

  const PlayerEntityy({
    this.id,
    this.name,
    this.slug,
    this.shortName,
    this.position,
    this.shirtNumber,
    this.jerseyNumber,
    this.age,
    this.height,
    this.userCount,
    this.countryAlpha2,
    this.countryAlpha2Lower,
    this.countryAlpha3,
    this.marketValueCurrency,
    this.dateOfBirthTimestamp,
    this.proposedMarketValue,
    this.fieldTranslations,
    this.teamId,
    this.substitute,
    this.statistics,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    shortName,
    position,
    shirtNumber,
    jerseyNumber,
    age,
    height,
    userCount,
    countryAlpha2,
    countryAlpha2Lower,
    countryAlpha3,
    marketValueCurrency,
    dateOfBirthTimestamp,
    proposedMarketValue,
    fieldTranslations,
    teamId,
    substitute,
    statistics,
  ];
}

class ProposedMarketValue extends Equatable {
  final int value;
  final String currency;

  const ProposedMarketValue({required this.value, required this.currency});

  @override
  List<Object?> get props => [value, currency];
}

class FieldTranslations extends Equatable {
  final Map<String, String> nameTranslation;
  final Map<String, String> shortNameTranslation;

  const FieldTranslations({
    required this.nameTranslation,
    required this.shortNameTranslation,
  });

  @override
  List<Object?> get props => [nameTranslation, shortNameTranslation];
}

class PlayerStatistics extends Equatable {
  final int totalPass;
  final int accuratePass;
  final int totalLongBalls;
  final int accurateLongBalls;
  final int goalAssist;
  final int totalCross;
  final int duelLost;
  final int duelWon;
  final int challengeLost;
  final int dispossessed;
  final int totalClearance;
  final int lastManTackle;
  final int totalTackle;
  final int wasFouled;
  final int fouls;
  final int minutesPlayed;
  final int touches;
  final double rating;
  final int possessionLostCtrl;
  final RatingVersions ratingVersions;
  final double? goalsPrevented; // Optional
  final double? expectedAssists; // Optional

  const PlayerStatistics({
    required this.totalPass,
    required this.accuratePass,
    required this.totalLongBalls,
    required this.accurateLongBalls,
    required this.goalAssist,
    required this.totalCross,
    required this.duelLost,
    required this.duelWon,
    required this.challengeLost,
    required this.dispossessed,
    required this.totalClearance,
    required this.lastManTackle,
    required this.totalTackle,
    required this.wasFouled,
    required this.fouls,
    required this.minutesPlayed,
    required this.touches,
    required this.rating,
    required this.possessionLostCtrl,
    required this.ratingVersions,
    this.goalsPrevented,
    this.expectedAssists,
  });

  @override
  List<Object?> get props => [
    totalPass,
    accuratePass,
    totalLongBalls,
    accurateLongBalls,
    goalAssist,
    totalCross,
    duelLost,
    duelWon,
    challengeLost,
    dispossessed,
    totalClearance,
    lastManTackle,
    totalTackle,
    wasFouled,
    fouls,
    minutesPlayed,
    touches,
    rating,
    possessionLostCtrl,
    ratingVersions,
    goalsPrevented,
    expectedAssists,
  ];
}

class RatingVersions extends Equatable {
  final double original;
  final double? alternative;

  const RatingVersions({required this.original, this.alternative});

  @override
  List<Object?> get props => [original, alternative];
}
