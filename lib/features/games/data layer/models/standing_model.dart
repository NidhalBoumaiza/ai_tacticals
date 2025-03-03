// lib/features/standings/data_layer/models/standings_model.dart
import 'package:analysis_ai/features/games/data%20layer/models/team_standing_model.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain layer/entities/league_entity.dart';
import '../../domain layer/entities/standing_entity.dart';
import '../../domain layer/entities/team_standing _entity.dart';
import 'league_model.dart';

class StandingsModel extends StandingsEntity {
  StandingsModel({
    required LeagueEntity league,
    required String name,
    required String tieBreakingRuleText,
    required List<TeamStandingEntity> rows,
  }) : super(
         league: league,
         name: name,
         tieBreakingRuleText: tieBreakingRuleText,
         rows: rows,
       );

  factory StandingsModel.fromJson(Map<String, dynamic> json) {
    final tournament =
        json['tournament'] as Map<String, dynamic>?; // Allow null
    if (tournament == null) {
      throw ServerException('Tournament data is missing in standings JSON');
    }

    final uniqueTournament =
        tournament['uniqueTournament'] as Map<String, dynamic>? ??
        {'id': 0, 'name': 'Unknown'};
    final tieBreakingRule =
        json['tieBreakingRule'] as Map<String, dynamic>? ?? {'text': ''};
    final rowsJson = json['rows'] as List<dynamic>? ?? [];

    return StandingsModel(
      league: LeagueModel.fromJson(uniqueTournament),
      name: json['name'] as String? ?? 'Unknown',
      tieBreakingRuleText: tieBreakingRule['text'] as String? ?? '',
      rows:
          rowsJson
              .map(
                (row) =>
                    TeamStandingModel.fromJson(row as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  static List<StandingsModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => StandingsModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
