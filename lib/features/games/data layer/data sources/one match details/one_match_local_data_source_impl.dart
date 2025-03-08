import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/error/exceptions.dart';

// Abstract class
abstract class OneMatchLocalDataSource {
  Future<void> cacheMatchDetails(
    Map<String, dynamic> event,
    Map<String, dynamic> stats,
    int matchId,
  );

  Future<Map<String, dynamic>> getLastMatchEvent(int matchId);

  Future<Map<String, dynamic>> getLastMatchStatistics(int matchId);

  Future<void> cachePlayersPerMatch(
    List<Map<String, dynamic>> players,
    int matchId,
  );

  Future<List<Map<String, dynamic>>> getLastPlayersPerMatch(int matchId);

  // New methods for managers
  Future<void> cacheManagersPerMatch(
    Map<String, dynamic> managers,
    int matchId,
  );

  Future<Map<String, dynamic>> getLastManagersPerMatch(int matchId);
}

// Implementation
class OneMatchLocalDataSourceImpl implements OneMatchLocalDataSource {
  final SharedPreferences sharedPreferences;

  OneMatchLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheMatchDetails(
    Map<String, dynamic> event,
    Map<String, dynamic> stats,
    int matchId,
  ) async {
    final eventJson = json.encode(event);
    final statsJson = json.encode(stats);
    await sharedPreferences.setString('match_event_$matchId', eventJson);
    await sharedPreferences.setString('match_stats_$matchId', statsJson);
  }

  @override
  Future<Map<String, dynamic>> getLastMatchEvent(int matchId) async {
    final jsonString = sharedPreferences.getString('match_event_$matchId');
    if (jsonString != null) {
      return json.decode(jsonString) as Map<String, dynamic>;
    } else {
      throw EmptyCacheException(
        'No cached match event found for matchId: $matchId',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getLastMatchStatistics(int matchId) async {
    final jsonString = sharedPreferences.getString('match_stats_$matchId');
    if (jsonString != null) {
      return json.decode(jsonString) as Map<String, dynamic>;
    } else {
      throw EmptyCacheException(
        'No cached match statistics found for matchId: $matchId',
      );
    }
  }

  @override
  Future<void> cachePlayersPerMatch(
    List<Map<String, dynamic>> players,
    int matchId,
  ) async {
    final playersJson = json.encode(players);
    await sharedPreferences.setString('players_$matchId', playersJson);
  }

  @override
  Future<List<Map<String, dynamic>>> getLastPlayersPerMatch(int matchId) async {
    final jsonString = sharedPreferences.getString('players_$matchId');
    if (jsonString != null) {
      return (json.decode(jsonString) as List<dynamic>)
          .map((player) => player as Map<String, dynamic>)
          .toList();
    } else {
      throw EmptyCacheException(
        'No cached players found for matchId: $matchId',
      );
    }
  }

  @override
  Future<void> cacheManagersPerMatch(
    Map<String, dynamic> managers,
    int matchId,
  ) async {
    final managersJson = json.encode(managers);
    await sharedPreferences.setString('managers_$matchId', managersJson);
  }

  @override
  Future<Map<String, dynamic>> getLastManagersPerMatch(int matchId) async {
    final jsonString = sharedPreferences.getString('managers_$matchId');
    if (jsonString != null) {
      return json.decode(jsonString) as Map<String, dynamic>;
    } else {
      throw EmptyCacheException(
        'No cached managers found for matchId: $matchId',
      );
    }
  }
}
