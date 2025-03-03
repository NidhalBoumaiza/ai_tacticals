// lib/features/standings/data_layer/data_sources/standings_local_data_source.dart
import 'dart:convert';

import 'package:analysis_ai/core/error/exceptions.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/standing_model.dart';
import '../../models/team_standing_model.dart';

abstract class StandingsLocalDataSource {
  Future<StandingsModel> getLastStandings(int leagueId, int seasonId);

  Future<void> cacheStandings(
    StandingsModel standings,
    int leagueId,
    int seasonId,
  );
}

class StandingsLocalDataSourceImpl implements StandingsLocalDataSource {
  final SharedPreferences sharedPreferences;

  StandingsLocalDataSourceImpl({required this.sharedPreferences});

  String _getCacheKey(int leagueId, int seasonId) =>
      'CACHED_STANDINGS_${leagueId}_$seasonId';

  @override
  Future<StandingsModel> getLastStandings(int leagueId, int seasonId) async {
    final jsonString = sharedPreferences.getString(
      _getCacheKey(leagueId, seasonId),
    );
    if (jsonString != null) {
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return StandingsModel.fromJson(jsonData);
    } else {
      throw EmptyCacheException("empty_cache_failure_message".tr);
    }
  }

  @override
  Future<void> cacheStandings(
    StandingsModel standings,
    int leagueId,
    int seasonId,
  ) async {
    final jsonString = json.encode(standings.toJson());
    await sharedPreferences.setString(
      _getCacheKey(leagueId, seasonId),
      jsonString,
    );
  }
}

// Updated JSON extensions
extension StandingsModelJson on StandingsModel {
  Map<String, dynamic> toJson() {
    return {
      'standings':
          groups.map((group) => (group as GroupModel).toJson()).toList(),
      'tournament': {
        'uniqueTournament': {'id': league?.id, 'name': league?.name},
      },
    };
  }
}

extension GroupModelJson on GroupModel {
  Map<String, dynamic> toJson() {
    return {
      'tournament': {
        'name': name,
        'isGroup': isGroup,
        'groupName': groupName,
        'uniqueTournament': {
          'id': null, // Not stored here; handled at StandingsModel level
          'name': null,
        },
      },
      'name': name,
      'tieBreakingRule': {'text': tieBreakingRuleText},
      'rows': rows.map((row) => (row as TeamStandingModel).toJson()).toList(),
    };
  }
}

extension TeamStandingModelJson on TeamStandingModel {
  Map<String, dynamic> toJson() {
    return {
      'team': {
        'shortName': shortName,
        'id': id,
        'teamColors':
            teamColors != null
                ? (teamColors as TeamColorsModel).toJson()
                : null,
        'fieldTranslations':
            fieldTranslations != null
                ? (fieldTranslations as FieldTranslationsModel).toJson()
                : null,
        'country': {'alpha2': countryAlpha2},
      },
      'position': position,
      'matches': matches,
      'wins': wins,
      'scoresFor': scoresFor,
      'scoresAgainst': scoresAgainst,
      'scoreDiffFormatted': scoreDiffFormatted,
      'points': points,
      'promotion':
          promotion != null
              ? {'text': promotion!.text, 'id': promotion!.id}
              : null,
    };
  }
}

extension TeamColorsModelJson on TeamColorsModel {
  Map<String, dynamic> toJson() {
    return {'primary': primary, 'secondary': secondary, 'text': text};
  }
}

extension FieldTranslationsModelJson on FieldTranslationsModel {
  Map<String, dynamic> toJson() {
    return {
      'nameTranslation': {'ar': nameTranslationAr},
      'shortNameTranslation': {'ar': shortNameTranslationAr},
    };
  }
}
