// entities.dart

class MatchEventEntity {
  final TournamentEntity tournament;
  final SeasonEntity season;
  final RoundInfoEntity roundInfo;
  final StatusEntity status;
  final int winnerCode;
  final int attendance;
  final VenueEntity venue;
  final RefereeEntity referee;
  final TeamEntity homeTeam;
  final TeamEntity awayTeam;
  final ScoreEntity homeScore;
  final ScoreEntity awayScore;
  final TimeEntity time;
  final int id;
  final int startTimestamp;

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

  factory MatchEventEntity.fromJson(Map<String, dynamic> json) {
    return MatchEventEntity(
      tournament: TournamentEntity.fromJson(json['tournament']),
      season: SeasonEntity.fromJson(json['season']),
      roundInfo: RoundInfoEntity.fromJson(json['roundInfo']),
      status: StatusEntity.fromJson(json['status']),
      winnerCode: json['winnerCode'],
      attendance: json['attendance'],
      venue: VenueEntity.fromJson(json['venue']),
      referee: RefereeEntity.fromJson(json['referee']),
      homeTeam: TeamEntity.fromJson(json['homeTeam']),
      awayTeam: TeamEntity.fromJson(json['awayTeam']),
      homeScore: ScoreEntity.fromJson(json['homeScore']),
      awayScore: ScoreEntity.fromJson(json['awayScore']),
      time: TimeEntity.fromJson(json['time']),
      id: json['id'],
      startTimestamp: json['startTimestamp'],
    );
  }
}

class TournamentEntity {
  final String name;
  final UniqueTournamentEntity uniqueTournament;

  TournamentEntity({required this.name, required this.uniqueTournament});

  factory TournamentEntity.fromJson(Map<String, dynamic> json) {
    return TournamentEntity(
      name: json['name'],
      uniqueTournament: UniqueTournamentEntity.fromJson(json['uniqueTournament']),
    );
  }
}

class UniqueTournamentEntity {
  final String name;
  final int id;

  UniqueTournamentEntity({required this.name, required this.id});

  factory UniqueTournamentEntity.fromJson(Map<String, dynamic> json) {
    return UniqueTournamentEntity(
      name: json['name'],
      id: json['id'],
    );
  }
}

class SeasonEntity {
  final String name;
  final String year;

  SeasonEntity({required this.name, required this.year});

  factory SeasonEntity.fromJson(Map<String, dynamic> json) {
    return SeasonEntity(
      name: json['name'],
      year: json['year'],
    );
  }
}

class RoundInfoEntity {
  final int round;

  RoundInfoEntity({required this.round});

  factory RoundInfoEntity.fromJson(Map<String, dynamic> json) {
    return RoundInfoEntity(round: json['round']);
  }
}

class StatusEntity {
  final int code;
  final String description;
  final String type;

  StatusEntity({required this.code, required this.description, required this.type});

  factory StatusEntity.fromJson(Map<String, dynamic> json) {
    return StatusEntity(
      code: json['code'],
      description: json['description'],
      type: json['type'],
    );
  }
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
}

class CityEntity {
  final String name;

  CityEntity({required this.name});

  factory CityEntity.fromJson(Map<String, dynamic> json) {
    return CityEntity(name: json['name']);
  }
}

class RefereeEntity {
  final String name;

  RefereeEntity({required this.name});

  factory RefereeEntity.fromJson(Map<String, dynamic> json) {
    return RefereeEntity(name: json['name']);
  }
}

class TeamEntity {
  final String name;
  final String shortName;
  final ManagerEntity manager;
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
      manager: ManagerEntity.fromJson(json['manager']),
      venue: VenueEntity.fromJson(json['venue']),
      nameCode: json['nameCode'],
    );
  }
}

class ManagerEntity {
  final String name;

  ManagerEntity({required this.name});

  factory ManagerEntity.fromJson(Map<String, dynamic> json) {
    return ManagerEntity(name: json['name']);
  }
}

class ScoreEntity {
  final int current;
  final int period1;
  final int period2;
  final int normaltime;

  ScoreEntity({
    required this.current,
    required this.period1,
    required this.period2,
    required this.normaltime,
  });

  factory ScoreEntity.fromJson(Map<String, dynamic> json) {
    return ScoreEntity(
      current: json['current'],
      period1: json['period1'],
      period2: json['period2'],
      normaltime: json['normaltime'],
    );
  }
}

class TimeEntity {
  final int injuryTime1;
  final int injuryTime2;

  TimeEntity({required this.injuryTime1, required this.injuryTime2});

  factory TimeEntity.fromJson(Map<String, dynamic> json) {
    return TimeEntity(
      injuryTime1: json['injuryTime1'],
      injuryTime2: json['injuryTime2'],
    );
  }
}

class MatchStatisticsEntity {
  final List<StatisticsPeriodEntity> statistics;

  MatchStatisticsEntity({required this.statistics});

  factory MatchStatisticsEntity.fromJson(Map<String, dynamic> json) {
    return MatchStatisticsEntity(
      statistics: (json['statistics'] as List)
          .map((e) => StatisticsPeriodEntity.fromJson(e))
          .toList(),
    );
  }
}

class StatisticsPeriodEntity {
  final String period;
  final List<StatisticsGroupEntity> groups;

  StatisticsPeriodEntity({required this.period, required this.groups});

  factory StatisticsPeriodEntity.fromJson(Map<String, dynamic> json) {
    return StatisticsPeriodEntity(
      period: json['period'],
      groups: (json['groups'] as List)
          .map((e) => StatisticsGroupEntity.fromJson(e))
          .toList(),
    );
  }
}

class StatisticsGroupEntity {
  final String groupName;
  final List<StatisticsItemEntity> statisticsItems;

  StatisticsGroupEntity({required this.groupName, required this.statisticsItems});

  factory StatisticsGroupEntity.fromJson(Map<String, dynamic> json) {
    return StatisticsGroupEntity(
      groupName: json['groupName'],
      statisticsItems: (json['statisticsItems'] as List)
          .map((e) => StatisticsItemEntity.fromJson(e))
          .toList(),
    );
  }
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
}