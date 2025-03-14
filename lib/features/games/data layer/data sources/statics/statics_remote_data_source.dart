// stats_remote_data_source_impl.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/error/exceptions.dart';
import '../../models/statics_model.dart';

abstract class StatsRemoteDataSource {
  Future<StatsModel> getTeamStats(int teamId, int tournamentId, int seasonId);
}

class StatsRemoteDataSourceImpl implements StatsRemoteDataSource {
  static const _baseUrl = 'https://www.sofascore.com/api/v1';
  final http.Client client;

  StatsRemoteDataSourceImpl({required this.client});

  @override
  Future<StatsModel> getTeamStats(
    int teamId,
    int tournamentId,
    int seasonId,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/team/$teamId/unique-tournament/$tournamentId/season/$seasonId/statistics/overall',
    );

    final response = await client.get(
      uri,
      headers: {'authority': 'api.sofascore.com'},
    );

    if (response.statusCode != 200) {
      throw ServerException(" Server message error is not 200 status code ");
    }

    try {
      final jsonMap = json.decode(response.body);
      return StatsModel.fromJson(jsonMap);
    } catch (e) {
      throw ServerException(" Error in parsing data ");
    }
  }
}
