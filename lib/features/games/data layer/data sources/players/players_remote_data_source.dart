// lib/features/players/data/datasources/players_remote_data_source.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../../core/error/exceptions.dart';
import '../../models/player_model.dart';

abstract class PlayersRemoteDataSource {
  Future<List<PlayerModel>> getPlayers(int teamId);
}

class PlayersRemoteDataSourceImpl implements PlayersRemoteDataSource {
  final http.Client client;

  PlayersRemoteDataSourceImpl({required this.client});

  @override
  Future<List<PlayerModel>> getPlayers(int teamId) async {
    final url = Uri.parse(
      'https://www.sofascore.com/api/v1/team/$teamId/players',
    );

    try {
      final response = await client
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final playersList = jsonData['players'] as List<dynamic>;
        return playersList
            .map(
              (playerJson) =>
                  PlayerModel.fromJson(playerJson as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw ServerException('Player load failed: ${response.statusCode}');
      }
    } on TimeoutException {
      throw ServerException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('Players error: $e');
    }
  }
}
