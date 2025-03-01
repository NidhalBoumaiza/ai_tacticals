import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/league_entity.dart';

abstract class LeaguesRepository {
  Future<Either<Failure, List<LeagueEntity>>> getLeaguesByCountryId(
    int countryId,
  );
}
