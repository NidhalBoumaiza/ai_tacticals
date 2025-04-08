import 'dart:async';
import 'dart:io';

import '../../../../../core/web view/web_view_api_call.dart'; // Adjust path to WebViewApiCall
import '../../../../../core/error/exceptions.dart';
import '../../models/player_statics_model.dart';

abstract class PlayerDetailsRemoteDataSource {
  Future<PlayerAttributesModel> getPlayerAttributes(int playerId);
  Future<NationalTeamModel> getNationalTeamStats(int playerId);
  Future<List<MatchPerformanceModel>> getLastYearSummary(int playerId);
  Future<List<TransferModel>> getTransferHistory(int playerId);
  Future<List<MediaModel>> getMedia(int playerId);
}

class PlayerDetailsRemoteDataSourceImpl implements PlayerDetailsRemoteDataSource {
  final WebViewApiCall webViewApiCall;
  static const String baseUrl = 'https://www.sofascore.com/api/v1/player';

  PlayerDetailsRemoteDataSourceImpl({required this.webViewApiCall});

  @override
  Future<PlayerAttributesModel> getPlayerAttributes(int playerId) async {
    final url = '$baseUrl/$playerId/attribute-overviews';

    try {
      final jsonData = await webViewApiCall
          .fetchJsonFromWebView(url)
          .timeout(const Duration(seconds: 30));

      if (jsonData == null || jsonData.isEmpty) {
        throw ServerException('Invalid player attributes data received');
      }

      final playerAttributes = PlayerAttributesModel.fromJson(jsonData);

      // Debug print to inspect player name
      // print('PlayerDetailsRemoteDataSource: Player name raw: ${playerAttributes.name}');
      // print('PlayerDetailsRemoteDataSource: Player name code units: ${playerAttributes.name?.codeUnits}');

      return playerAttributes;
    } on TimeoutException {
      throw ServerMessageException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('Failed to load player attributes: $e');
    }
  }

  @override
  Future<NationalTeamModel> getNationalTeamStats(int playerId) async {
    final url = '$baseUrl/$playerId/national-team-statistics';

    try {
      final jsonData = await webViewApiCall
          .fetchJsonFromWebView(url)
          .timeout(const Duration(seconds: 30));

      if (jsonData == null || jsonData.isEmpty) {
        throw ServerException('Invalid national team stats data received');
      }

      return NationalTeamModel.fromJson(jsonData);
    } on TimeoutException {
      throw ServerMessageException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('Failed to load national team stats: $e');
    }
  }

  @override
  Future<List<MatchPerformanceModel>> getLastYearSummary(int playerId) async {
    final url = '$baseUrl/$playerId/last-year-summary';

    try {
      final jsonData = await webViewApiCall
          .fetchJsonFromWebView(url)
          .timeout(const Duration(seconds: 30));

      if (jsonData == null || jsonData.isEmpty) {
        throw ServerException('Invalid last year summary data received');
      }

      final summaryList = jsonData['summary'] as List<dynamic>? ?? [];
      return summaryList
          .map(
            (json) => MatchPerformanceModel.fromJson(json as Map<String, dynamic>),
      )
          .toList();
    } on TimeoutException {
      throw ServerMessageException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('Failed to load last year summary: $e');
    }
  }

  @override
  Future<List<TransferModel>> getTransferHistory(int playerId) async {
    final url = '$baseUrl/$playerId/transfer-history';

    try {
      final jsonData = await webViewApiCall
          .fetchJsonFromWebView(url)
          .timeout(const Duration(seconds: 30));

      if (jsonData == null || jsonData.isEmpty) {
        throw ServerException('Invalid transfer history data received');
      }

      final transferList = jsonData['transferHistory'] as List<dynamic>? ?? [];
      final transfers = transferList
          .map((json) => TransferModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Debug print for a sample team name in transfer history
      if (transfers.isNotEmpty) {
       // final sampleTeamName = transfers.first.teamName ?? 'Unknown';
       //  print('PlayerDetailsRemoteDataSource: Transfer team raw: $sampleTeamName');
       //  print('PlayerDetailsRemoteDataSource: Transfer team code units: ${sampleTeamName.codeUnits}');
      }

      return transfers;
    } on TimeoutException {
      throw ServerMessageException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('Failed to load transfer history: $e');
    }
  }

  @override
  Future<List<MediaModel>> getMedia(int playerId) async {
    final url = '$baseUrl/$playerId/media';

    try {
      final jsonData = await webViewApiCall
          .fetchJsonFromWebView(url)
          .timeout(const Duration(seconds: 30));

      if (jsonData == null || jsonData.isEmpty) {
        throw ServerException('Invalid media data received');
      }

      final mediaList = jsonData['media'] as List<dynamic>? ?? [];
      return mediaList
          .map((json) => MediaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw ServerMessageException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('Failed to load media: $e');
    }
  }
}