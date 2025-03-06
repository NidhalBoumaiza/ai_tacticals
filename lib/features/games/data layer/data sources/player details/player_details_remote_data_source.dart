import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../../core/error/exceptions.dart';
import '../../models/player_statics_model.dart';

abstract class PlayerDetailsRemoteDataSource {
  Future<PlayerAttributesModel> getPlayerAttributes(int playerId);

  Future<NationalTeamModel> getNationalTeamStats(int playerId);

  Future<List<MatchPerformanceModel>> getLastYearSummary(int playerId);

  Future<List<TransferModel>> getTransferHistory(int playerId);

  Future<List<MediaModel>> getMedia(int playerId);
}

class PlayerDetailsRemoteDataSourceImpl
    implements PlayerDetailsRemoteDataSource {
  final http.Client client;
  static const String baseUrl = 'https://www.sofascore.com/api/v1/player';

  PlayerDetailsRemoteDataSourceImpl({required this.client});

  @override
  Future<PlayerAttributesModel> getPlayerAttributes(int playerId) async {
    final url = '$baseUrl/$playerId/attribute-overviews';

    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        return PlayerAttributesModel.fromJson(responseBody);
      } else {
        throw ServerException(
          'Failed to fetch player attributes: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw ServerMessageException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<NationalTeamModel> getNationalTeamStats(int playerId) async {
    final url = '$baseUrl/$playerId/national-team-statistics';

    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        return NationalTeamModel.fromJson(responseBody);
      } else {
        throw ServerException(
          'Failed to fetch national team stats: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw ServerMessageException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<List<MatchPerformanceModel>> getLastYearSummary(int playerId) async {
    final url = '$baseUrl/$playerId/last-year-summary';

    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final summaryList = responseBody['summary'] as List<dynamic>? ?? [];
        return summaryList
            .map(
              (json) =>
                  MatchPerformanceModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw ServerException(
          'Failed to fetch last year summary: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw ServerMessageException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<List<TransferModel>> getTransferHistory(int playerId) async {
    final url = '$baseUrl/$playerId/transfer-history';

    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final transferList =
            responseBody['transferHistory'] as List<dynamic>? ?? [];
        return transferList
            .map((json) => TransferModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Failed to fetch transfer history: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw ServerMessageException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<List<MediaModel>> getMedia(int playerId) async {
    final url = '$baseUrl/$playerId/media'; // Inferred endpoint

    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final mediaList = responseBody['media'] as List<dynamic>? ?? [];
        return mediaList
            .map((json) => MediaModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException('Failed to fetch media: ${response.statusCode}');
      }
    } on TimeoutException {
      throw ServerMessageException('Request timed out');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }
}
