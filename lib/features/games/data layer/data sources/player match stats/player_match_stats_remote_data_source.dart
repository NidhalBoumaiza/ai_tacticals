import 'dart:async';
import 'dart:io';

import 'package:analysis_ai/core/web view/web_view_api_call.dart'; // Adjust path to WebViewApiCall
import 'package:analysis_ai/core/error/exceptions.dart';

import '../../models/player_model.dart';

abstract class PlayerMatchStatsRemoteDataSource {
  Future<PlayerModel> getPlayerMatchStats({
    required int matchId,
    required int playerId,
  });
}

class PlayerMatchStatsRemoteDataSourceImpl implements PlayerMatchStatsRemoteDataSource {
  final WebViewApiCall webViewApiCall;

  PlayerMatchStatsRemoteDataSourceImpl({required this.webViewApiCall});

  @override
  Future<PlayerModel> getPlayerMatchStats({
    required int matchId,
    required int playerId,
  }) async {
    final url = 'https://www.sofascore.com/api/v1/event/$matchId/player/$playerId/statistics';

    try {
      final jsonData = await webViewApiCall
          .fetchJsonFromWebView(url)
          .timeout(const Duration(seconds: 30));

      if (jsonData == null || jsonData.isEmpty) {
        throw ServerException('Invalid player statistics data received');
      }

      // Add teamId to match PlayerModel.fromJson expectation
      jsonData['teamId'] = jsonData['team']?['id'];
      final playerModel = PlayerModel.fromJson(jsonData);

      // Debug print to inspect player name or team name
      final playerName = playerModel.name ?? 'Unknown';
      final teamName = jsonData['team']?['name'] as String? ?? 'Unknown';
      print('PlayerMatchStatsRemoteDataSource: Player name raw: $playerName');
      print('PlayerMatchStatsRemoteDataSource: Player name code units: ${playerName.codeUnits}');
      print('PlayerMatchStatsRemoteDataSource: Team name raw: $teamName');
      print('PlayerMatchStatsRemoteDataSource: Team name code units: ${teamName.codeUnits}');

      return playerModel;
    } on TimeoutException {
      throw ServerMessageException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      if (e is ServerException && e.toString().contains('404')) {
        throw ServerMessageException('Player statistics not found');
      }
      throw ServerException('Failed to load player statistics: $e');
    }
  }
}