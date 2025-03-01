import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/league_entity.dart';
import '../repositories/league_repository.dart';

class GetLeaguesByCountryUseCase {
  final LeaguesRepository leaguesRepository;

  GetLeaguesByCountryUseCase(this.leaguesRepository);

  Future<Either<Failure, List<LeagueEntity>>> call(int countryId) async {
    return await leaguesRepository.getLeaguesByCountryId(countryId);
  }
}
