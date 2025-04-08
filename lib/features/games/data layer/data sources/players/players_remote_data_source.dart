import 'dart:async';
import 'dart:io';

import 'package:analysis_ai/core/web view/web_view_api_call.dart'; // Adjust path to WebViewApiCall
import 'package:analysis_ai/core/error/exceptions.dart';

import '../../models/player_model.dart';

abstract class PlayersRemoteDataSource {
  Future<List<PlayerModel>> getPlayers(int teamId);
}

class PlayersRemoteDataSourceImpl implements PlayersRemoteDataSource {
  final WebViewApiCall webViewApiCall;

  PlayersRemoteDataSourceImpl({required this.webViewApiCall});

  @override
  Future<List<PlayerModel>> getPlayers(int teamId) async {
    final url = 'https://www.sofascore.com/api/v1/team/$teamId/players';

    try {
      final jsonData = await webViewApiCall
          .fetchJsonFromWebView(url)
          .timeout(const Duration(seconds: 30));

      if (jsonData == null || jsonData.isEmpty) {
        throw ServerException('Invalid players data received');
      }

      final playersList = jsonData['players'] as List<dynamic>? ?? [];
      final players = playersList
          .map(
            (playerJson) => PlayerModel.fromJson(playerJson as Map<String, dynamic>),
      )
          .toList();

      // Debug print for a sample player name
      if (players.isNotEmpty) {
        final samplePlayerName = players.first.name ?? 'Unknown';
        print('PlayersRemoteDataSource: Player name raw: $samplePlayerName');
        print('PlayersRemoteDataSource: Player name code units: ${samplePlayerName.codeUnits}');
      }

      return players;
    } on TimeoutException {
      throw ServerException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('Failed to load players: $e');
    }
  }
}