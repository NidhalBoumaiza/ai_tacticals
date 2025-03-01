import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/country_entity.dart';

abstract class GamesRepository {
  Future<Either<Failure, List<CountryEntity>>> getAllCountries();
}
