// lib/features/standings/data_layer/models/standings_model.dart
import 'package:analysis_ai/features/games/data%20layer/models/team_standing_model.dart';

import '../../domain layer/entities/league_entity.dart';
import '../../domain layer/entities/standing_entity.dart';
import '../../domain layer/entities/team_standing _entity.dart';
import 'league_model.dart';

class StandingsModel extends StandingsEntity {
  StandingsModel({LeagueEntity? league, required List<GroupEntity> groups})
    : super(league: league, groups: groups);

  factory StandingsModel.fromJson(Map<String, dynamic> json) {
    // Check if the JSON has a top-level "standings" array
    List<dynamic>? standingsJson = json['standings'] as List<dynamic>?;
    Map<String, dynamic>? singleStandingsJson;

    if (standingsJson == null) {
      // If no "standings" array, assume the entire JSON is a single standings object
      singleStandingsJson = json;
      standingsJson = [json]; // Treat it as a single-entry array
    } else if (standingsJson.isEmpty) {
      return StandingsModel(groups: []);
    }

    final firstStandings = standingsJson[0] as Map<String, dynamic>;
    final tournament = firstStandings['tournament'] as Map<String, dynamic>?;
    final uniqueTournament =
        tournament != null
            ? tournament['uniqueTournament'] as Map<String, dynamic>?
            : null;
    final isGroup =
        tournament != null ? tournament['isGroup'] as bool? ?? false : false;

    List<GroupModel> groups;
    if (isGroup) {
      // Multi-group case
      groups =
          standingsJson.map((groupJson) {
            final groupTournament =
                groupJson['tournament'] as Map<String, dynamic>?;
            final tieBreakingRule =
                groupJson['tieBreakingRule'] as Map<String, dynamic>?;
            final rowsJson = groupJson['rows'] as List<dynamic>? ?? [];

            return GroupModel(
              name: groupJson['name'] as String?,
              tieBreakingRuleText:
                  tieBreakingRule != null
                      ? tieBreakingRule['text'] as String?
                      : null,
              rows:
                  rowsJson
                      .map(
                        (row) => TeamStandingModel.fromJson(
                          row as Map<String, dynamic>? ?? {},
                        ),
                      )
                      .toList(),
              isGroup:
                  groupTournament != null
                      ? groupTournament['isGroup'] as bool?
                      : null,
              groupName:
                  groupTournament != null
                      ? groupTournament['groupName'] as String?
                      : null,
            );
          }).toList();
    } else {
      // Total standings case
      final tieBreakingRule =
          firstStandings['tieBreakingRule'] as Map<String, dynamic>?;
      final rowsJson = firstStandings['rows'] as List<dynamic>? ?? [];

      groups = [
        GroupModel(
          name: firstStandings['name'] as String?,
          tieBreakingRuleText:
              tieBreakingRule != null
                  ? tieBreakingRule['text'] as String?
                  : null,
          rows:
              rowsJson
                  .map(
                    (row) => TeamStandingModel.fromJson(
                      row as Map<String, dynamic>? ?? {},
                    ),
                  )
                  .toList(),
          isGroup: false,
          groupName: null,
        ),
      ];
    }

    return StandingsModel(
      league:
          uniqueTournament != null
              ? LeagueModel.fromJson(uniqueTournament)
              : null,
      groups: groups,
    );
  }

  static List<StandingsModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => StandingsModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

class GroupModel extends GroupEntity {
  GroupModel({
    String? name,
    String? tieBreakingRuleText,
    List<TeamStandingEntity> rows = const [],
    bool? isGroup,
    String? groupName,
  }) : super(
         name: name,
         tieBreakingRuleText: tieBreakingRuleText,
         rows: rows,
         isGroup: isGroup,
         groupName: groupName,
       );
}
