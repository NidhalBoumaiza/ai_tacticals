import 'dart:convert';

import 'package:analysis_ai/core/error/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/player_model.dart';

abstract class PlayerMatchStatsLocalDataSource {
  Future<void> cachePlayerMatchStats({
    required int matchId,
    required int playerId,
    required PlayerModel playerStats,
  });

  Future<PlayerModel> getCachedPlayerMatchStats({
    required int matchId,
    required int playerId,
  });
}

class PlayerMatchStatsLocalDataSourceImpl
    implements PlayerMatchStatsLocalDataSource {
  final SharedPreferences sharedPreferences;

  PlayerMatchStatsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cachePlayerMatchStats({
    required int matchId,
    required int playerId,
    required PlayerModel playerStats,
  }) async {
    final jsonString = json.encode(playerStats.toJson());
    await sharedPreferences.setString(
      'player_stats_${matchId}_$playerId',
      jsonString,
    );
  }

  @override
  Future<PlayerModel> getCachedPlayerMatchStats({
    required int matchId,
    required int playerId,
  }) async {
    final jsonString = sharedPreferences.getString(
      'player_stats_${matchId}_$playerId',
    );

    if (jsonString != null) {
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return PlayerModel.fromJson(jsonData);
    } else {
      throw EmptyCacheException('No cached player stats found');
    }
  }
}
