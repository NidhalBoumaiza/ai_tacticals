// lib/features/standings/data_layer/data_sources/standings_remote_data_source.dart
import 'dart:async';
import 'dart:convert';

import 'package:analysis_ai/core/error/exceptions.dart';
import 'package:http/http.dart' as http;

import '../../models/season_model.dart';
import '../../models/standing_model.dart';

abstract class StandingsRemoteDataSource {
  Future<StandingsModel> getStandings(int leagueId, int seasonId);

  Future<List<SeasonModel>> getSeasonsByTournamentId(int uniqueTournamentId);
}

class StandingsRemoteDataSourceImpl implements StandingsRemoteDataSource {
  final http.Client client;

  StandingsRemoteDataSourceImpl({required this.client});

  @override
  Future<StandingsModel> getStandings(int leagueId, int seasonId) async {
    final url =
        'https://www.sofascore.com/api/v1/unique-tournament/$leagueId/season/$seasonId/standings/total';
    final response = await client.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      return StandingsModel.fromJson(jsonData);
    } else {
      throw ServerException("Server Exception: ${response.statusCode}");
    }
  }

  @override
  Future<List<SeasonModel>> getSeasonsByTournamentId(
    int uniqueTournamentId,
  ) async {
    final url =
        'https://www.sofascore.com/api/v1/unique-tournament/$uniqueTournamentId/seasons';
    final response = await client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> seasonsJson =
          responseBody['seasons'] as List<dynamic>;
      return seasonsJson
          .map((season) => SeasonModel.fromJson(season as Map<String, dynamic>))
          .toList();
    } else {
      throw ServerException('Failed to fetch seasons: ${response.statusCode}');
    }
  }
}
