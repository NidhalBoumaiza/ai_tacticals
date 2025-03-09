import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/error/exceptions.dart';
import '../../../domain layer/entities/player_per_match_entity.dart';
import '../../models/player_per_match_model.dart';

abstract class OneMatchRemoteDataSource {
  Future<Map<String, dynamic>> getMatchEvent(int matchId);

  Future<Map<String, dynamic>> getMatchStatistics(int matchId);

  Future<Map<String, List<PlayerPerMatchEntity>>> getPlayersPerMatch(
    int matchId,
  );

  Future<Map<String, dynamic>> getManagersPerMatch(int matchId);
}

class OneMatchRemoteDataSourceImpl implements OneMatchRemoteDataSource {
  final http.Client client;

  OneMatchRemoteDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> getMatchEvent(int matchId) async {
    final response = await _fetchData(
      'https://www.sofascore.com/api/v1/event/$matchId',
    );
    if (response == null || response.isEmpty) {
      throw ServerException('Invalid match event data received');
    }
    // Unwrap the 'event' key from the response
    final eventData = response['event'] as Map<String, dynamic>?;
    if (eventData == null) {
      throw ServerException('No event data found in response');
    }
    return eventData; // Return the inner event object
  }

  @override
  Future<Map<String, dynamic>> getMatchStatistics(int matchId) async {
    final response = await _fetchData(
      'https://www.sofascore.com/api/v1/event/$matchId/statistics',
    );
    if (response == null || response.isEmpty) {
      throw ServerException('Invalid match statistics data received');
    }
    return response; // Statistics API response is already in the correct format
  }

  @override
  Future<Map<String, List<PlayerPerMatchEntity>>> getPlayersPerMatch(
    int matchId,
  ) async {
    final response = await _fetchData(
      'https://api.sofascore.com/api/v1/event/$matchId/lineups',
    );
    if (response == null) {
      throw ServerException('Invalid players data received');
    }

    // Extract home and away players, handling null or invalid data
    final homePlayersRaw =
        (response['home']?['players'] as List<dynamic>?) ?? [];
    final awayPlayersRaw =
        (response['away']?['players'] as List<dynamic>?) ?? [];

    final homePlayers =
        homePlayersRaw
            .where((player) => player != null) // Filter out null entries
            .map(
              (player) =>
                  PlayerPerMatchModel.fromJson(player as Map<String, dynamic>),
            )
            .toList();

    final awayPlayers =
        awayPlayersRaw
            .where((player) => player != null) // Filter out null entries
            .map(
              (player) =>
                  PlayerPerMatchModel.fromJson(player as Map<String, dynamic>),
            )
            .toList();

    return {'home': homePlayers, 'away': awayPlayers};
  }

  @override
  Future<Map<String, dynamic>> getManagersPerMatch(int matchId) async {
    final response = await _fetchData(
      'https://api.sofascore.com/api/v1/event/$matchId/managers',
    );
    if (response == null ||
        !response.containsKey('homeManager') ||
        !response.containsKey('awayManager')) {
      throw ServerException('Invalid managers data received');
    }
    return {
      'homeManager': response['homeManager'],
      'awayManager': response['awayManager'],
    };
  }

  // Helper method to fetch data from the API
  Future<Map<String, dynamic>> _fetchData(String url) async {
    final response = await client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decodedResponse =
          json.decode(response.body) as Map<String, dynamic>;
      return decodedResponse;
    } else if (response.statusCode == 404) {
      throw ServerMessageException('Match not found');
    } else if (response.statusCode == 500) {
      throw ServerException(
        'Server error: ${response.statusCode} - ${response.reasonPhrase}',
      );
    } else {
      throw ServerException(
        'Server error: ${response.statusCode} - ${response.reasonPhrase}',
      );
    }
  }
}
