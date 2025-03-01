import 'package:analysis_ai/features/games/domain%20layer/entities/country_entity.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/games_repository.dart';

class GetAllCountriesUseCase {
  final GamesRepository repository;

  GetAllCountriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CountryEntity>>> call() async {
    return await repository.getAllCountries();
  }
}
