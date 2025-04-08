import 'dart:async';
import 'dart:io';

import 'package:analysis_ai/core/web view/web_view_api_call.dart'; // Adjust path to WebViewApiCall
import 'package:analysis_ai/core/error/exceptions.dart';

import '../../models/statics_model.dart';

abstract class StatsRemoteDataSource {
  Future<StatsModel> getTeamStats(int teamId, int tournamentId, int seasonId);
}

class StatsRemoteDataSourceImpl implements StatsRemoteDataSource {
  static const _baseUrl = 'https://www.sofascore.com/api/v1';
  final WebViewApiCall webViewApiCall;

  StatsRemoteDataSourceImpl({required this.webViewApiCall});

  @override
  Future<StatsModel> getTeamStats(
      int teamId,
      int tournamentId,
      int seasonId,
      ) async {
    final url = '$_baseUrl/team/$teamId/unique-tournament/$tournamentId/season/$seasonId/statistics/overall';

    try {
      final jsonData = await webViewApiCall
          .fetchJsonFromWebView(url)
          .timeout(const Duration(seconds: 30));

      if (jsonData == null || jsonData.isEmpty) {
        throw ServerException('Invalid team stats data received');
      }

      final stats = StatsModel.fromJson(jsonData);

      // Debug print for team-related data (assuming StatsModel has team info)
      // final teamName = stats.teamName ?? 'Unknown'; // Adjust based on actual field
      // print('StatsRemoteDataSource: Team name raw: $teamName');
      // print('StatsRemoteDataSource: Team name code units: ${teamName.codeUnits}');

      return stats;
    } on TimeoutException {
      throw ServerException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('Failed to load team stats: $e');
    }
  }
}