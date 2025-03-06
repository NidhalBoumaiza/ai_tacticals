// stats_local_data_source_impl.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../domain layer/entities/statics_entity.dart';
import '../../models/statics_model.dart';

abstract class StatsLocalDataSource {
  Future<StatsEntity> getLastStats(int teamId, int tournamentId, int seasonId);

  Future<void> cacheStats(
    StatsModel stats,
    int teamId,
    int tournamentId,
    int seasonId,
  );
}

class StatsLocalDataSourceImpl implements StatsLocalDataSource {
  final SharedPreferences sharedPreferences;

  StatsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheStats(
    StatsModel stats,
    int teamId,
    int tournamentId,
    int seasonId,
  ) async {
    final key = _generateCacheKey(teamId, tournamentId, seasonId);
    await sharedPreferences.setString(key, json.encode(stats.toJson()));
  }

  @override
  Future<StatsEntity> getLastStats(
    int teamId,
    int tournamentId,
    int seasonId,
  ) async {
    final key = _generateCacheKey(teamId, tournamentId, seasonId);
    final jsonString = sharedPreferences.getString(key);

    if (jsonString == null) {
      throw EmptyCacheException(" Empry Cache error");
    }

    try {
      return StatsModel.fromJson(json.decode(jsonString)).toEntity();
    } catch (e) {
      throw EmptyCacheException(" Empry Cache error");
    }
  }

  String _generateCacheKey(int teamId, int tournamentId, int seasonId) {
    return 'cached_stats_${teamId}_${tournamentId}_$seasonId';
  }
}
