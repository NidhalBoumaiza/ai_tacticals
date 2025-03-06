import 'package:analysis_ai/features/auth/data%20layer/data%20sources/user_local_data_source.dart';
import 'package:analysis_ai/features/auth/presentation%20layer/bloc/login_bloc/login_bloc.dart';
import 'package:analysis_ai/features/auth/presentation%20layer/bloc/signup_bloc/signup_bloc.dart';
import 'package:analysis_ai/features/games/domain%20layer/repositories/league_repository.dart';
import 'package:analysis_ai/features/games/domain%20layer/repositories/players_repository.dart';
import 'package:analysis_ai/features/games/domain%20layer/repositories/standing_repository.dart';
import 'package:analysis_ai/features/games/presentation%20layer/bloc/leagues_bloc/leagues_bloc.dart';
import 'package:analysis_ai/features/games/presentation%20layer/bloc/matches_bloc/matches_bloc.dart';
import 'package:analysis_ai/features/games/presentation%20layer/bloc/standing%20bloc/standing_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/network_info.dart';
import 'features/auth/data layer/data sources/user_remote_data_source.dart';
import 'features/auth/data layer/repositories/user_repository_impl.dart';
import 'features/auth/domain layer/repositories/user_repository.dart';
import 'features/auth/domain layer/usecases/login_usecase.dart';
import 'features/auth/domain layer/usecases/signup_usecase.dart';
import 'features/games/data layer/data sources/countries/games_local_data_source.dart';
import 'features/games/data layer/data sources/countries/games_remote_data_source.dart';
import 'features/games/data layer/data sources/leagues/leagues_local_data_source.dart';
import 'features/games/data layer/data sources/leagues/leagues_remote_data_source.dart';
import 'features/games/data layer/data sources/matches/matches_local_data_source.dart';
import 'features/games/data layer/data sources/matches/matches_remote_data_source.dart';
import 'features/games/data layer/data sources/players/player_local_data_source.dart';
import 'features/games/data layer/data sources/players/players_remote_data_source.dart';
import 'features/games/data layer/data sources/standing/standing_local_data_source.dart';
import 'features/games/data layer/data sources/standing/standing_remote_date_source.dart';
import 'features/games/data layer/data sources/statics/statics_local_data_source.dart';
import 'features/games/data layer/data sources/statics/statics_remote_data_source.dart';
import 'features/games/data layer/repositories/games_repository_impl.dart';
import 'features/games/data layer/repositories/league_repository_impl.dart';
import 'features/games/data layer/repositories/matches_repository_impl.dart';
import 'features/games/data layer/repositories/players_repository_impl.dart';
import 'features/games/data layer/repositories/standing_repository_impl.dart';
import 'features/games/data layer/repositories/statics_repository_impl.dart';
import 'features/games/domain layer/repositories/games_repository.dart';
import 'features/games/domain layer/repositories/matches_repository.dart';
import 'features/games/domain layer/repositories/statics_repository.dart';
import 'features/games/domain layer/usecases/get_all_countries_use_case.dart';
import 'features/games/domain layer/usecases/get_all_players_infos_use_case.dart';
import 'features/games/domain layer/usecases/get_leagues_by_country_use_case.dart';
import 'features/games/domain layer/usecases/get_matches_by_team_use_case.dart';
import 'features/games/domain layer/usecases/get_season_use_case.dart';
import 'features/games/domain layer/usecases/get_standing_use_case.dart';
import 'features/games/domain layer/usecases/get_statics_use_case.dart';
import 'features/games/presentation layer/bloc/countries_bloc/countries_bloc.dart';
import 'features/games/presentation layer/bloc/players_bloc/players_bloc.dart';
import 'features/games/presentation layer/bloc/stats bloc/stats_bloc.dart';
import 'features/games/presentation layer/cubit/bnv cubit/bnv_cubit.dart';
import 'features/games/presentation layer/cubit/seasons cubit/seasons_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Bloc
  sl.registerFactory(() => LoginBloc(login: sl()));
  sl.registerFactory(() => SignupBloc(signup: sl()));
  sl.registerFactory(() => CountriesBloc(gamesRepository: sl()));
  sl.registerFactory(() => LeaguesBloc(getLeaguesByCountry: sl()));
  sl.registerFactory(() => StandingBloc(getStandings: sl()));
  sl.registerFactory(() => MatchesBloc(getMatchesPerTeam: sl())); // Cubit
  sl.registerFactory(() => BnvCubit());
  sl.registerFactory(() => SeasonsCubit(getSeasonsUseCase: sl()));
  sl.registerFactory(() => PlayersBloc(getAllPlayersInfos: sl()));
  sl.registerFactory(() => StatsBloc(repository: sl())); // Added StatsBloc
  // ** UseCases **
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => GetAllCountriesUseCase(sl()));
  sl.registerLazySingleton(() => GetLeaguesByCountryUseCase(sl()));
  sl.registerLazySingleton(() => GetStandingsUseCase(sl()));
  sl.registerLazySingleton(() => GetSeasonsUseCase(sl()));
  sl.registerLazySingleton(() => GetMatchesPerTeam(sl()));
  sl.registerLazySingleton(() => GetAllPlayersInfos(sl()));
  sl.registerLazySingleton(() => GetTeamStatsUseCAse(sl())); // Added
  // ** Repositories **
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      userRemoteDataSource: sl(),
      userLocalDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<GamesRepository>(
    () => GamesRepositoryImpl(
      gamesRemoteDataSource: sl(),
      gamesLocalDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<LeaguesRepository>(
    () => LeaguesRepositoryImpl(
      leaguesRemoteDataSource: sl(),
      leaguesLocalDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<StandingsRepository>(
    () => StandingsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<MatchesRepository>(
    () => MatchesRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<PlayersRepository>(
    () => PlayersRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<StaticsRepository>(
    // Added
    () => StatsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // ** Data Sources **
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(client: sl(), localDataSource: sl()),
  );
  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<GamesRemoteDataSource>(
    () => GamesRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<GamesLocalDataSource>(
    () => GamesLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<LeaguesRemoteDataSource>(
    () => LeaguesRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<LeaguesLocalDataSource>(
    () => LeaguesLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<StandingsRemoteDataSource>(
    () => StandingsRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<StandingsLocalDataSource>(
    () => StandingsLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<MatchesRemoteDataSource>(
    () => MatchesRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<MatchesLocalDataSource>(
    () => MatchesLocalDataSourceImpl(sharedPreferences: sl()),
  );
  sl.registerLazySingleton<PlayersRemoteDataSource>(
    () => PlayersRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<PlayersLocalDataSource>(
    () => PlayersLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<StatsRemoteDataSource>(
    // Added
    () => StatsRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<StatsLocalDataSource>(
    // Added
    () => StatsLocalDataSourceImpl(sharedPreferences: sl()),
  );
  // ** Core **

  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // ** External **

  final sharedPreferences = await SharedPreferences.getInstance();

  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker.instance,
  );
}
