import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain layer/entities/country_entity.dart';
import '../../domain layer/repositories/games_repository.dart';
import '../data sources/countries/games_local_data_source.dart';
import '../data sources/countries/games_remote_data_source.dart';
import '../models/country_model.dart';

class GamesRepositoryImpl implements GamesRepository {
  final GamesRemoteDataSource gamesRemoteDataSource;
  final GamesLocalDataSource gamesLocalDataSource;
  final NetworkInfo networkInfo;

  GamesRepositoryImpl({
    required this.gamesRemoteDataSource,
    required this.gamesLocalDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CountryEntity>>> getAllCountries() async {
    if (await networkInfo.isConnected) {
      try {
        final List<CountryModel> countryModels =
            await gamesRemoteDataSource.getAllCountries();
        await gamesLocalDataSource.cacheCountries(
          countryModels,
        ); // Cache remotely fetched data
        final List<CountryEntity> countries =
            countryModels
                .map(
                  (countryModel) => CountryEntity(
                    name: countryModel.name,
                    slug: countryModel.slug,
                    priority: countryModel.priority,
                    id: countryModel.id,
                    flag: countryModel.flag,
                    alpha2: countryModel.alpha2,
                  ),
                )
                .toList();
        return Right(countries);
      } on ServerException {
        return Left(ServerFailure());
      } on ServerMessageException catch (e) {
        return Left(ServerMessageFailure(e.message));
      } on OfflineException catch (e) {
        return Left(OfflineFailure());
      }
    } else {
      try {
        final List<CountryModel> cachedCountries =
            await gamesLocalDataSource.getCachedCountries();
        final List<CountryEntity> countries =
            cachedCountries
                .map(
                  (countryModel) => CountryEntity(
                    name: countryModel.name,
                    slug: countryModel.slug,
                    priority: countryModel.priority,
                    id: countryModel.id,
                    flag: countryModel.flag,
                    alpha2: countryModel.alpha2,
                  ),
                )
                .toList();
        return Right(countries);
      } on EmptyCacheException catch (e) {
        return Left(EmptyCacheFailure());
      }
    }
  }
}
