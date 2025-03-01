import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/error/exceptions.dart';
import '../../models/league_model.dart';

abstract class LeaguesLocalDataSource {
  /// Caches the list of leagues for a specific country locally.
  Future<Unit> cacheLeagues(List<LeagueModel> leagues, int countryId);

  /// Retrieves the cached list of leagues for a specific country.
  Future<List<LeagueModel>> getCachedLeagues(int countryId);
}

class LeaguesLocalDataSourceImpl implements LeaguesLocalDataSource {
  final SharedPreferences sharedPreferences;

  LeaguesLocalDataSourceImpl({required this.sharedPreferences});

  static String _getLeaguesKey(int countryId) => 'CACHED_LEAGUES_$countryId';

  @override
  Future<Unit> cacheLeagues(List<LeagueModel> leagues, int countryId) async {
    final leaguesJson = jsonEncode(
      leagues.map((league) => league.toJson()).toList(),
    );
    await sharedPreferences.setString(_getLeaguesKey(countryId), leaguesJson);
    return unit;
  }

  @override
  Future<List<LeagueModel>> getCachedLeagues(int countryId) async {
    final leaguesJson = sharedPreferences.getString(_getLeaguesKey(countryId));
    if (leaguesJson != null) {
      try {
        final List<dynamic> decodedJson = jsonDecode(leaguesJson) as List;
        final List<LeagueModel> leagues =
            decodedJson
                .map(
                  (json) => LeagueModel.fromJson(json as Map<String, dynamic>),
                )
                .toList();
        return leagues;
      } catch (e) {
        throw EmptyCacheException(
          'Failed to parse cached leagues for country $countryId: $e',
        );
      }
    } else {
      throw EmptyCacheException(
        'No cached leagues found for country $countryId',
      );
    }
  }
}
