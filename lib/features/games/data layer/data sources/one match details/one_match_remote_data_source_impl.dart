// one_match_remote_data_source.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../core/error/exceptions.dart';

import '../../../domain layer/entities/one_match_statics_entity.dart';


// Abstract class
abstract class OneMatchRemoteDataSource {
  Future<MatchEventEntity> getMatchEvent(int matchId);
  Future<MatchStatisticsEntity> getMatchStatistics(int matchId);
}

// Implementation
class OneMatchRemoteDataSourceImpl implements OneMatchRemoteDataSource {
  final http.Client client;

  OneMatchRemoteDataSourceImpl({required this.client});

  @override
  Future<MatchEventEntity> getMatchEvent(int matchId) async {
    try {
      final response = await client
          .get(
        Uri.parse('https://www.sofascore.com/api/v1/event/$matchId'),
      )
          .timeout(const Duration(seconds: 12), onTimeout: () {
        throw const TimeoutException('Match event request timed out after 12 seconds');
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return MatchEventEntity.fromJson(jsonData['event']);
      } else {
        throw ServerException('Failed to load match event: ${response.statusCode}');
      }
    } on TimeoutException {
      rethrow; // Pass the TimeoutException to the repository
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MatchStatisticsEntity> getMatchStatistics(int matchId) async {
    try {
      final response = await client
          .get(
        Uri.parse('https://www.sofascore.com/api/v1/event/$matchId/statistics'),
      )
          .timeout(const Duration(seconds: 12), onTimeout: () {
        throw const TimeoutException('Match statistics request timed out after 12 seconds');
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return MatchStatisticsEntity.fromJson(jsonData);
      } else {
        throw ServerException('Failed to load match statistics: ${response.statusCode}');
      }
    } on TimeoutException {
      rethrow; // Pass the TimeoutException to the repository
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}