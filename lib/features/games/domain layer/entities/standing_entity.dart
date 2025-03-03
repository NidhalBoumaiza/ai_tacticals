// lib/features/standings/domain_layer/entities/standings_entity.dart
import 'package:analysis_ai/features/games/domain%20layer/entities/team_standing%20_entity.dart';
import 'league_entity.dart';

class StandingsEntity {
  final LeagueEntity? league; // Nullable to handle null tournament data
  final List<GroupEntity> groups; // List of groups (can be 1 or many)

  StandingsEntity({
    this.league, // Nullable
    required this.groups, // Required, but can be empty
  });
}

class GroupEntity {
  final String? name; // e.g., "Group A" or "UEFA Champions League"
  final String? tieBreakingRuleText;
  final List<TeamStandingEntity> rows; // Can be empty if null
  final bool? isGroup; // Indicates if this is a group standings
  final String? groupName; // Specific group name (e.g., "Group A")

  GroupEntity({
    this.name,
    this.tieBreakingRuleText,
    this.rows = const [], // Default to empty list
    this.isGroup,
    this.groupName,
  });
}
