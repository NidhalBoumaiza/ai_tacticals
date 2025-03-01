import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../../core/error/exceptions.dart';
import '../../models/league_model.dart';

abstract class LeaguesRemoteDataSource {
  Future<List<LeagueModel>> getLeaguesByCountryId(int countryId);
}

class LeaguesRemoteDataSourceImpl implements LeaguesRemoteDataSource {
  final http.Client client;

  LeaguesRemoteDataSourceImpl({required this.client});

  @override
  Future<List<LeagueModel>> getLeaguesByCountryId(int countryId) async {
    const baseUrl = 'https://www.sofascore.com/api/v1/category';
    final url = '$baseUrl/$countryId/unique-tournaments';

    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> groups = responseBody['groups'] as List;
        final List<LeagueModel> leagues = [];

        for (var group in groups) {
          final uniqueTournaments = group['uniqueTournaments'] as List;
          for (var tournament in uniqueTournaments) {
            final league = LeagueModel.fromJson(
              tournament as Map<String, dynamic>,
            );
            leagues.add(league);
          }
        }
        return leagues;
      } else {
        throw ServerException(
          'Failed to fetch leagues: ${response.statusCode}',
        );
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
