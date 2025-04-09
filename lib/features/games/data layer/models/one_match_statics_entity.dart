import '../../domain layer/entities/one_match_statics_entity.dart';

class MatchDetails {
  final String tournamentName;
  final String seasonName;
  final int round;
  final String status;
  final String winner;
  final int? attendance;  // Changed to nullable
  final String venueName;
  final String refereeName;
  final Team homeTeam;
  final Team awayTeam;
  final Score homeScore;
  final Score awayScore;
  final DateTime startTime;  // Remains DateTime, but we'll handle null safely
  final List<MatchStatistics> statistics;

  MatchDetails({
    required this.tournamentName,
    required this.seasonName,
    required this.round,
    required this.status,
    required this.winner,
    required this.attendance,
    required this.venueName,
    required this.refereeName,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.startTime,
    required this.statistics,
  });

  factory MatchDetails.fromEntities(
      MatchEventEntity event,
      MatchStatisticsEntity stats,
      ) {
    return MatchDetails(
      tournamentName: event.tournament.name,
      seasonName: event.season.name,
      round: event.roundInfo.round,
      status: event.status.description,
      winner: event.winnerCode == 1
          ? event.homeTeam.name
          : event.winnerCode == 2
          ? event.awayTeam.name
          : 'Draw',
      attendance: event.attendance,  // Now int? matches
      venueName: event.venue.name,
      refereeName: event.referee.name,
      homeTeam: Team.fromEntity(event.homeTeam),
      awayTeam: Team.fromEntity(event.awayTeam),
      homeScore: Score.fromEntity(event.homeScore),
      awayScore: Score.fromEntity(event.awayScore),
      startTime: DateTime.fromMillisecondsSinceEpoch(
        (event.startTimestamp ?? 0) * 1000,  // Default to 0 if null
      ),
      statistics: stats.statistics.map(MatchStatistics.fromEntity).toList(),
    );
  }
}

class Team {
  final String name;
  final String shortName;
  final String managerName;
  final String venueName;
  final String nameCode;

  Team({
    required this.name,
    required this.shortName,
    required this.managerName,
    required this.venueName,
    required this.nameCode,
  });

  factory Team.fromEntity(TeamEntity entity) {
    return Team(
      name: entity.name,
      shortName: entity.shortName,
      managerName: entity.manager.name,
      venueName: entity.venue.name,
      nameCode: entity.nameCode,
    );
  }
}

class Score {
  final int? current;  // Already nullable
  final int? period1;
  final int? period2;

  Score({
    required this.current,
    required this.period1,
    required this.period2,
  });

  factory Score.fromEntity(ScoreEntity entity) {
    return Score(
      current: entity.current,
      period1: entity.period1,
      period2: entity.period2,
    );
  }
}

class MatchStatistics {
  final String period;
  final List<StatisticsGroup> groups;

  MatchStatistics({required this.period, required this.groups});

  factory MatchStatistics.fromEntity(StatisticsPeriodEntity entity) {
    return MatchStatistics(
      period: entity.period,
      groups: entity.groups.map(StatisticsGroup.fromEntity).toList(),
    );
  }
}

class StatisticsGroup {
  final String groupName;
  final List<StatisticsItem> items;

  StatisticsGroup({required this.groupName, required this.items});

  factory StatisticsGroup.fromEntity(StatisticsGroupEntity entity) {
    return StatisticsGroup(
      groupName: entity.groupName,
      items: entity.statisticsItems.map(StatisticsItem.fromEntity).toList(),
    );
  }
}

class StatisticsItem {
  final String name;
  final String homeValue;
  final String awayValue;
  final int compareCode;
  final bool isPositive;
  final String valueType;

  StatisticsItem({
    required this.name,
    required this.homeValue,
    required this.awayValue,
    required this.compareCode,
    required this.isPositive,
    required this.valueType,
  });

  factory StatisticsItem.fromEntity(StatisticsItemEntity entity) {
    return StatisticsItem(
      name: entity.name,
      homeValue: entity.home,
      awayValue: entity.away,
      compareCode: entity.compareCode,
      isPositive: entity.statisticsType == 'positive',
      valueType: entity.valueType,
    );
  }
}