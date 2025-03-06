import 'package:analysis_ai/features/games/domain%20layer/entities/team_standing%20_entity.dart';

import 'league_entity.dart';

class MatchEventsPerTeamEntity {
  final Map<String, List<MatchEventEntity>>? tournamentTeamEvents;

  const MatchEventsPerTeamEntity({this.tournamentTeamEvents});
}

class MatchEventEntity {
  final LeagueEntity?
  tournament; // Reusing LeagueEntity instead of TournamentEntity
  final String? customId;
  final StatusEntity? status;
  final int? winnerCode;
  final TeamStandingEntity? homeTeam; // Reusing TeamStandingEntity
  final TeamStandingEntity? awayTeam; // Reusing TeamStandingEntity
  final ScoreEntity? homeScore;
  final ScoreEntity? awayScore;
  final bool? hasXg;
  final int? id;
  final int? startTimestamp;
  final String? slug;
  final bool? finalResultOnly;

  const MatchEventEntity({
    this.tournament,
    this.customId,
    this.status,
    this.winnerCode,
    this.homeTeam,
    this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.hasXg,
    this.id,
    this.startTimestamp,
    this.slug,
    this.finalResultOnly,
  });
}

// lib/features/matches/domain/entities/status_entity.dart
class StatusEntity {
  final int? code;
  final String? description;
  final String? type;

  const StatusEntity({this.code, this.description, this.type});
}

// lib/features/matches/domain/entities/score_entity.dart
class ScoreEntity {
  final int? current;
  final int? display;
  final int? period1;
  final int? period2;
  final int? normaltime;

  const ScoreEntity({
    this.current,
    this.display,
    this.period1,
    this.period2,
    this.normaltime,
  });
}
