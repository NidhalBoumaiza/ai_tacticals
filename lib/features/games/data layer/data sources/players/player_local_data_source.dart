// lib/features/players/data/datasources/players_local_data_source.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../domain layer/entities/player_entity.dart';
import '../../models/player_model.dart';

abstract class PlayersLocalDataSource {
  Future<List<PlayerEntityy>> getLastPlayers(int teamId);

  Future<void> cachePlayers(List<PlayerModel> players, int teamId);
}

class PlayersLocalDataSourceImpl implements PlayersLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const _cacheKeyPrefix = 'CACHED_PLAYERS_TEAM_';

  PlayersLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<PlayerEntityy>> getLastPlayers(int teamId) async {
    final key = _getCacheKey(teamId);
    final jsonString = sharedPreferences.getString(key);

    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList
            .map(
              (playerJson) =>
                  PlayerModel.fromJson(
                    playerJson as Map<String, dynamic>,
                  ).toEntity(),
            )
            .toList();
      } catch (e) {
        throw EmptyCacheException('Failed to parse cached players');
      }
    }
    throw EmptyCacheException('No cached players for team $teamId');
  }

  @override
  Future<void> cachePlayers(List<PlayerModel> players, int teamId) async {
    final key = _getCacheKey(teamId);
    try {
      final jsonList = players.map((p) => p.toJson()).toList();
      await sharedPreferences.setString(key, jsonEncode(jsonList));
    } catch (e) {
      throw EmptyCacheException('Failed to cache players');
    }
  }

  String _getCacheKey(int teamId) => '$_cacheKeyPrefix$teamId';
}
