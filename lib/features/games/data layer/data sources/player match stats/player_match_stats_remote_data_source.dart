// features/games/data layer/data sources/player match stats/player_match_stats_remote_data_source.dart

import 'dart:convert';

import 'package:analysis_ai/core/error/exceptions.dart';
import 'package:http/http.dart' as http;

import '../../models/player_model.dart';

abstract class PlayerMatchStatsRemoteDataSource {
  Future<PlayerModel> getPlayerMatchStats({
    required int matchId,
    required int playerId,
  });
}

class PlayerMatchStatsRemoteDataSourceImpl
    implements PlayerMatchStatsRemoteDataSource {
  final http.Client client;

  PlayerMatchStatsRemoteDataSourceImpl({required this.client});

  @override
  Future<PlayerModel> getPlayerMatchStats({
    required int matchId,
    required int playerId,
  }) async {
    final url =
        'https://www.sofascore.com/api/v1/event/$matchId/player/$playerId/statistics';
    final response = await client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decodedResponse =
          json.decode(response.body) as Map<String, dynamic>;
      // Add teamId to match PlayerModel.fromJson expectation
      decodedResponse['teamId'] = decodedResponse['team']?['id'];
      return PlayerModel.fromJson(decodedResponse);
    } else if (response.statusCode == 404) {
      throw ServerMessageException('Player statistics not found');
    } else {
      throw ServerException(
        'Server error: ${response.statusCode} - ${response.reasonPhrase}',
      );
    }
  }
}
