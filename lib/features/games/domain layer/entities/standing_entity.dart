import 'package:analysis_ai/features/games/domain%20layer/entities/team_standing%20_entity.dart';

import 'league_entity.dart';

class StandingsEntity {
  final LeagueEntity league; // Changed from TournamentEntity
  final String name;
  final String tieBreakingRuleText;
  final List<TeamStandingEntity> rows;

  StandingsEntity({
    required this.league,
    required this.name,
    required this.tieBreakingRuleText,
    required this.rows,
  });
}
