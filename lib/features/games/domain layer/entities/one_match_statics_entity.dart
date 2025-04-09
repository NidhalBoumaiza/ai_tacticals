// features/games/domain layer/entities/one_match_statics_entity.dart

class MatchEventEntity {
  final TournamentEntity tournament;
  final SeasonEntity season;
  final RoundInfoEntity roundInfo;
  final StatusEntity status;
  final int? winnerCode;         // Changed to nullable
  final int? attendance;         // Changed to nullable
  final VenueEntity venue;
  final RefereeEntity referee;
  final TeamEntity homeTeam;
  final TeamEntity awayTeam;
  final ScoreEntity homeScore;
  final ScoreEntity awayScore;
  final TimeEntity time;
  final int? id;                 // Changed to nullable
  final int? startTimestamp;     // Changed to nullable

  MatchEventEntity({
    required this.tournament,
    required this.season,
    required this.roundInfo,
    required this.status,
    required this.winnerCode,
    required this.attendance,
    required this.venue,
    required this.referee,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.time,
    required this.id,
    required this.startTimestamp,
  });

  factory MatchEventEntity.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw const FormatException(
        'Null JSON provided to MatchEventEntity.fromJson',
      );
    }
    return MatchEventEntity(
      tournament: TournamentEntity.fromJson(json['tournament']),
      season: SeasonEntity.fromJson(json['season']),
      roundInfo: RoundInfoEntity.fromJson(json['roundInfo']),
      status: StatusEntity.fromJson(json['status']),
      winnerCode: json['winnerCode'] ?? 0,
      // Provide a default value
      attendance: json['attendance'] ?? 0,
      // Provide a default value
      venue: VenueEntity.fromJson(json['venue']),
      referee: RefereeEntity.fromJson(json['referee']),
      homeTeam: TeamEntity.fromJson(json['homeTeam']),
      awayTeam: TeamEntity.fromJson(json['awayTeam']),
      homeScore: ScoreEntity.fromJson(json['homeScore']),
      awayScore: ScoreEntity.fromJson(json['awayScore']),
      time: TimeEntity.fromJson(json['time'] ?? {}),  // Already handles null
      id: json['id'] ?? 0,
      // Provide a default value
      startTimestamp: json['startTimestamp'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'tournament': tournament.toJson(),
    'season': season.toJson(),
    'roundInfo': roundInfo.toJson(),
    'status': status.toJson(),
    'winnerCode': winnerCode,
    'attendance': attendance,
    'venue': venue.toJson(),
    'referee': referee.toJson(),
    'homeTeam': homeTeam.toJson(),
    'awayTeam': awayTeam.toJson(),
    'homeScore': homeScore.toJson(),
    'awayScore': awayScore.toJson(),
    'time': time.toJson(),
    'id': id,
    'startTimestamp': startTimestamp,
  };
}

class TournamentEntity {
  final String name;
  final UniqueTournamentEntity uniqueTournament;

  TournamentEntity({required this.name, required this.uniqueTournament});

  factory TournamentEntity.fromJson(Map<String, dynamic> json) {
    return TournamentEntity(
      name: json['name'],
      uniqueTournament: UniqueTournamentEntity.fromJson(
        json['uniqueTournament'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'uniqueTournament': uniqueTournament.toJson(),
  };
}

class UniqueTournamentEntity {
  final String name;
  final int id;

  UniqueTournamentEntity({required this.name, required this.id});

  factory UniqueTournamentEntity.fromJson(Map<String, dynamic> json) {
    return UniqueTournamentEntity(name: json['name'], id: json['id']);
  }

  Map<String, dynamic> toJson() => {'name': name, 'id': id};
}

class SeasonEntity {
  final String name;
  final String year;

  SeasonEntity({required this.name, required this.year});

  factory SeasonEntity.fromJson(Map<String, dynamic> json) {
    return SeasonEntity(name: json['name'], year: json['year']);
  }

  Map<String, dynamic> toJson() => {'name': name, 'year': year};
}

class RoundInfoEntity {
  final int round;

  RoundInfoEntity({required this.round});

  factory RoundInfoEntity.fromJson(Map<String, dynamic> json) {
    return RoundInfoEntity(round: json['round']);
  }

  Map<String, dynamic> toJson() => {'round': round};
}

class StatusEntity {
  final int code;
  final String description;
  final String type;

  StatusEntity({
    required this.code,
    required this.description,
    required this.type,
  });

  factory StatusEntity.fromJson(Map<String, dynamic> json) {
    return StatusEntity(
      code: json['code'],
      description: json['description'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'description': description,
    'type': type,
  };
}

class VenueEntity {
  final CityEntity city;
  final String name;
  final int capacity;

  VenueEntity({required this.city, required this.name, required this.capacity});

  factory VenueEntity.fromJson(Map<String, dynamic> json) {
    return VenueEntity(
      city: CityEntity.fromJson(json['city']),
      name: json['name'],
      capacity: json['capacity'],
    );
  }

  Map<String, dynamic> toJson() => {
    'city': city.toJson(),
    'name': name,
    'capacity': capacity,
  };
}

class CityEntity {
  final String name;

  CityEntity({required this.name});

  factory CityEntity.fromJson(Map<String, dynamic> json) {
    return CityEntity(name: json['name']);
  }

  Map<String, dynamic> toJson() => {'name': name};
}

class RefereeEntity {
  final String name;

  RefereeEntity({required this.name});

  factory RefereeEntity.fromJson(Map<String, dynamic> json) {
    return RefereeEntity(name: json['name']);
  }

  Map<String, dynamic> toJson() => {'name': name};
}

class TeamEntity {
  final String name;
  final String shortName;
  final ManagerEntityy manager;
  final VenueEntity venue;
  final String nameCode;

  TeamEntity({
    required this.name,
    required this.shortName,
    required this.manager,
    required this.venue,
    required this.nameCode,
  });

  factory TeamEntity.fromJson(Map<String, dynamic> json) {
    return TeamEntity(
      name: json['name'],
      shortName: json['shortName'],
      manager: ManagerEntityy.fromJson(json['manager']),
      venue: VenueEntity.fromJson(json['venue']),
      nameCode: json['nameCode'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'shortName': shortName,
    'manager': manager.toJson(),
    'venue': venue.toJson(),
    'nameCode': nameCode,
  };
}

class ManagerEntityy {
  final String name;

  ManagerEntityy({required this.name});

  factory ManagerEntityy.fromJson(Map<String, dynamic> json) {
    return ManagerEntityy(name: json['name']);
  }

  Map<String, dynamic> toJson() => {'name': name};
}

class ScoreEntity {
  final int? current;     // Changed to nullable
  final int? period1;     // Changed to nullable
  final int? period2;     // Changed to nullable
  final int? normaltime;  // Changed to nullable

  ScoreEntity({
    required this.current,
    required this.period1,
    required this.period2,
    required this.normaltime,
  });

  factory ScoreEntity.fromJson(Map<String, dynamic> json) {
    return ScoreEntity(
      current: json['current'] as int?,  // Explicit cast with null handling
      period1: json['period1'] as int?,
      period2: json['period2'] as int?,
      normaltime: json['normaltime'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'current': current,
    'period1': period1,
    'period2': period2,
    'normaltime': normaltime,
  };
}

class TimeEntity {
  final int? injuryTime1;  // Changed to nullable
  final int? injuryTime2;  // Changed to nullable

  TimeEntity({required this.injuryTime1, required this.injuryTime2});

  factory TimeEntity.fromJson(Map<String, dynamic> json) {
    return TimeEntity(
      injuryTime1: json['injuryTime1'] as int?,  // Handle null
      injuryTime2: json['injuryTime2'] as int?,  // Handle null
    );
  }

  Map<String, dynamic> toJson() => {
    'injuryTime1': injuryTime1,
    'injuryTime2': injuryTime2,
  };
}

class MatchStatisticsEntity {
  final List<StatisticsPeriodEntity> statistics;

  MatchStatisticsEntity({required this.statistics});

  factory MatchStatisticsEntity.fromJson(Map<String, dynamic> json) {
    if (json == null || json['statistics'] == null) {
      return MatchStatisticsEntity(statistics: []);
    }
    return MatchStatisticsEntity(
      statistics: (json['statistics'] as List<dynamic>)
          .map((e) => StatisticsPeriodEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'statistics': statistics.map((e) => e.toJson()).toList(),
  };
}

class StatisticsPeriodEntity {
  final String period;
  final List<StatisticsGroupEntity> groups;

  StatisticsPeriodEntity({required this.period, required this.groups});

  factory StatisticsPeriodEntity.fromJson(Map<String, dynamic> json) {
    return StatisticsPeriodEntity(
      period: json['period'],
      groups:
          (json['groups'] as List)
              .map((e) => StatisticsGroupEntity.fromJson(e))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'period': period,
    'groups': groups.map((e) => e.toJson()).toList(),
  };
}

class StatisticsGroupEntity {
  final String groupName;
  final List<StatisticsItemEntity> statisticsItems;

  StatisticsGroupEntity({
    required this.groupName,
    required this.statisticsItems,
  });

  factory StatisticsGroupEntity.fromJson(Map<String, dynamic> json) {
    return StatisticsGroupEntity(
      groupName: json['groupName'],
      statisticsItems:
          (json['statisticsItems'] as List)
              .map((e) => StatisticsItemEntity.fromJson(e))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'groupName': groupName,
    'statisticsItems': statisticsItems.map((e) => e.toJson()).toList(),
  };
}

class StatisticsItemEntity {
  final String name;
  final String home;
  final String away;
  final int compareCode;
  final String statisticsType;
  final String valueType;
  final double? homeValue;
  final double? awayValue;
  final int? homeTotal;
  final int? awayTotal;

  StatisticsItemEntity({
    required this.name,
    required this.home,
    required this.away,
    required this.compareCode,
    required this.statisticsType,
    required this.valueType,
    this.homeValue,
    this.awayValue,
    this.homeTotal,
    this.awayTotal,
  });

  factory StatisticsItemEntity.fromJson(Map<String, dynamic> json) {
    return StatisticsItemEntity(
      name: json['name'],
      home: json['home'],
      away: json['away'],
      compareCode: json['compareCode'],
      statisticsType: json['statisticsType'],
      valueType: json['valueType'],
      homeValue: json['homeValue']?.toDouble(),
      awayValue: json['awayValue']?.toDouble(),
      homeTotal: json['homeTotal'],
      awayTotal: json['awayTotal'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'home': home,
    'away': away,
    'compareCode': compareCode,
    'statisticsType': statisticsType,
    'valueType': valueType,
    'homeValue': homeValue,
    'awayValue': awayValue,
    'homeTotal': homeTotal,
    'awayTotal': awayTotal,
  };
}
