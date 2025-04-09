import 'dart:async';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/web view/web_view_api_call.dart';
import '../../../domain layer/entities/player_per_match_entity.dart';
import '../../models/player_per_match_model.dart';

abstract class OneMatchRemoteDataSource {
  Future<Map<String, dynamic>> getMatchEvent(int matchId);
  Future<Map<String, dynamic>> getMatchStatistics(int matchId);
  Future<Map<String, List<PlayerPerMatchEntity>>> getPlayersPerMatch(int matchId);
  Future<Map<String, dynamic>> getManagersPerMatch(int matchId);
}

class OneMatchRemoteDataSourceImpl implements OneMatchRemoteDataSource {
  final WebViewApiCall webViewApiCall;

  OneMatchRemoteDataSourceImpl({required this.webViewApiCall});

  @override
  Future<Map<String, dynamic>> getMatchEvent(int matchId) async {
    final url = 'https://www.sofascore.com/api/v1/event/$matchId';

    try {
      final json = await webViewApiCall.fetchJsonFromWebView(url);
      final eventData = json['event'] as Map<String, dynamic>?;

      if (eventData == null) {
        throw ServerException('No event data found in response');
      }
      return eventData;
    } catch (e) {
      throw ServerException('Failed to load match event: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getMatchStatistics(int matchId) async {
    final url = 'https://www.sofascore.com/api/v1/event/$matchId/statistics';

    try {
      final json = await webViewApiCall.fetchJsonFromWebView(url);
      print ("********************************************") ;
      print ('Match Statistics JSON: $json'); // Debugging line
      if (json.isEmpty) {
        throw ServerException('Invalid match statistics data received');
      }
      return json;
    } catch (e) {
      throw ServerException('Failed to load match statistics: $e');
    }
  }

  @override
  Future<Map<String, List<PlayerPerMatchEntity>>> getPlayersPerMatch(int matchId) async {
    final url = 'https://api.sofascore.com/api/v1/event/$matchId/lineups';

    try {
      final json = await webViewApiCall.fetchJsonFromWebView(url);

      // Extract home and away players, handling null or invalid data
      final homePlayersRaw = (json['home']?['players'] as List<dynamic>?) ?? [];
      final awayPlayersRaw = (json['away']?['players'] as List<dynamic>?) ?? [];

      final homePlayers = homePlayersRaw
          .where((player) => player != null)
          .map((player) => PlayerPerMatchModel.fromJson(player as Map<String, dynamic>))
          .toList();

      final awayPlayers = awayPlayersRaw
          .where((player) => player != null)
          .map((player) => PlayerPerMatchModel.fromJson(player as Map<String, dynamic>))
          .toList();

      return {'home': homePlayers, 'away': awayPlayers};
    } catch (e) {
      throw ServerException('Failed to load players per match: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getManagersPerMatch(int matchId) async {
    final url = 'https://api.sofascore.com/api/v1/event/$matchId/managers';

    try {
      final json = await webViewApiCall.fetchJsonFromWebView(url);

      if (!json.containsKey('homeManager') || !json.containsKey('awayManager')) {
        throw ServerException('Invalid managers data received');
      }

      return {
        'homeManager': json['homeManager'],
        'awayManager': json['awayManager'],
      };
    } catch (e) {
      throw ServerException('Failed to load managers: $e');
    }
  }
}