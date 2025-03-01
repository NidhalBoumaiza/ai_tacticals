import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain layer/entities/league_entity.dart';
import '../../domain layer/repositories/league_repository.dart';
import '../models/league_model.dart';

class LeaguesRepositoryImpl implements LeaguesRepository {
  final http.Client client;

  LeaguesRepositoryImpl({required this.client});

  @override
  Future<Either<Failure, List<LeagueEntity>>> getLeaguesByCountryId(
    int countryId,
  ) async {
    const baseUrl = 'https://www.sofascore.com/api/v1/category';
    final url = '$baseUrl/$countryId/unique-tournaments';

    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12)); // Match your timeout

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> groups = responseBody['groups'] as List;
        final List<LeagueEntity> leagues = [];

        for (var group in groups) {
          final uniqueTournaments = group['uniqueTournaments'] as List;
          for (var tournament in uniqueTournaments) {
            final league = LeagueModel.fromJson(
              tournament as Map<String, dynamic>,
            );
            leagues.add(league);
          }
        }
        return Right(leagues);
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage =
            responseBody['message'] as String? ?? 'Failed to fetch leagues';
        throw UnauthorizedException(errorMessage);
      } else if (response.statusCode == 404) {
        throw ServerMessageException('Resource not found');
      } else {
        throw ServerException('Server error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw ServerMessageException('Something very wrong happened');
    } on SocketException {
      throw OfflineException('No Internet connection');
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }
}
