import 'package:analysis_ai/features/auth/data%20layer/data%20sources/user_local_data_source.dart';
import 'package:analysis_ai/features/auth/presentation%20layer/bloc/login_bloc/login_bloc.dart';
import 'package:analysis_ai/features/auth/presentation%20layer/bloc/signup_bloc/signup_bloc.dart';
import 'package:analysis_ai/features/games/domain%20layer/repositories/league_repository.dart';
import 'package:analysis_ai/features/games/domain%20layer/repositories/players_repository.dart';
import 'package:analysis_ai/features/games/domain%20layer/repositories/standing_repository.dart';
import 'package:analysis_ai/features/games/domain%20layer/usecases/get_match_details_use_case.dart';
import 'package:analysis_ai/features/games/presentation%20layer/bloc/leagues_bloc/leagues_bloc.dart';
import 'package:analysis_ai/features/games/presentation%20layer/bloc/matches_bloc/matches_bloc.dart';
import 'package:analysis_ai/features/games/presentation%20layer/bloc/standing%20bloc/standing_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/cubit/theme cubit/theme_cubit.dart';
import 'core/network/network_info.dart';
import 'core/web view/web_view_api_call.dart';
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
import 'features/games/data layer/data sources/one match details/one_match_local_data_source_impl.dart';
import 'features/games/data layer/data sources/one match details/one_match_remote_data_source_impl.dart';
import 'features/games/data layer/data sources/player details/player_details_local_data_source.dart';
import 'features/games/data layer/data sources/player details/player_details_remote_data_source.dart';
import 'features/games/data layer/data sources/player match stats/player_match_stats_local_data_source.dart';
import 'features/games/data layer/data sources/player match stats/player_match_stats_remote_data_source.dart';
import 'features/games/data layer/data sources/players/player_local_data_source.dart';
import 'features/games/data layer/data sources/players/players_remote_data_source.dart';
import 'features/games/data layer/data sources/standing/standing_local_data_source.dart';
import 'features/games/data layer/data sources/standing/standing_remote_date_source.dart';
import 'features/games/data layer/data sources/statics/statics_local_data_source.dart';
import 'features/games/data layer/data sources/statics/statics_remote_data_source.dart';
import 'features/games/data layer/repositories/games_repository_impl.dart';
import 'features/games/data layer/repositories/league_repository_impl.dart';
import 'features/games/data layer/repositories/matches_repository_impl.dart';
import 'features/games/data layer/repositories/one_match_stats_repository_impl.dart';
import 'features/games/data layer/repositories/player_details_repository_impl.dart';
import 'features/games/data layer/repositories/player_match_stats_repository_impl.dart';
import 'features/games/data layer/repositories/players_repository_impl.dart';
import 'features/games/data layer/repositories/standing_repository_impl.dart';
import 'features/games/data layer/repositories/statics_repository_impl.dart';
import 'features/games/domain layer/repositories/games_repository.dart';
import 'features/games/domain layer/repositories/matches_repository.dart';
import 'features/games/domain layer/repositories/one_match_stats_repository.dart';
import 'features/games/domain layer/repositories/player_details_repository.dart';
import 'features/games/domain layer/repositories/player_match_stats_repository.dart';
import 'features/games/domain layer/repositories/statics_repository.dart';
import 'features/games/domain layer/usecases/get _last_year_summary_use_case.dart';
import 'features/games/domain layer/usecases/get_all_countries_use_case.dart';
import 'features/games/domain layer/usecases/get_all_players_infos_use_case.dart';
import 'features/games/domain layer/usecases/get_home_matches_use_case.dart';
import 'features/games/domain layer/usecases/get_leagues_by_country_use_case.dart';
import 'features/games/domain layer/usecases/get_matches_by_team_use_case.dart';
import 'features/games/domain layer/usecases/get_matches_per_round_use_case.dart';
import 'features/games/domain layer/usecases/get_media_use_case.dart';
import 'features/games/domain layer/usecases/get_national_team_stats_use_case.dart';
import 'features/games/domain layer/usecases/get_player_attributes_use_case.dart';
import 'features/games/domain layer/usecases/get_player_match_stats.dart';
import 'features/games/domain layer/usecases/get_season_use_case.dart';
import 'features/games/domain layer/usecases/get_standing_use_case.dart';
import 'features/games/domain layer/usecases/get_statics_use_case.dart';
import 'features/games/domain layer/usecases/get_transfert_history_use_case.dart';
import 'features/games/presentation layer/bloc/countries_bloc/countries_bloc.dart';
import 'features/games/presentation layer/bloc/home match bloc/home_matches_bloc.dart';
import 'features/games/presentation layer/bloc/last year summery bloc/last_year_summary_bloc.dart';
import 'features/games/presentation layer/bloc/manager bloc/manager_bloc.dart';
import 'features/games/presentation layer/bloc/match details bloc/match_details_bloc.dart';
import 'features/games/presentation layer/bloc/matches per round bloc/matches_per_round_bloc.dart';
import 'features/games/presentation layer/bloc/media bloc/media_bloc.dart';
import 'features/games/presentation layer/bloc/national team bloc/national_team_stats_bloc.dart';
import 'features/games/presentation layer/bloc/player match stats bloc/player_match_stats_bloc.dart';
import 'features/games/presentation layer/bloc/player per match bloc/player_per_match_bloc.dart';
import 'features/games/presentation layer/bloc/player statics bloc/player_attributes_bloc.dart';
import 'features/games/presentation layer/bloc/players_bloc/players_bloc.dart';
import 'features/games/presentation layer/bloc/stats bloc/stats_bloc.dart';
import 'features/games/presentation layer/bloc/transfert history bloc/transfer_history_bloc.dart';
import 'features/games/presentation layer/cubit/bnv cubit/bnv_cubit.dart';
import 'features/games/presentation layer/cubit/seasons cubit/seasons_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Blocs
  sl.registerFactory(() => LoginBloc(login: sl()));
  sl.registerFactory(() => SignupBloc(signup: sl()));
  sl.registerFactory(() => CountriesBloc(gamesRepository: sl()));
  sl.registerFactory(() => LeaguesBloc(getLeaguesByCountry: sl()));
  sl.registerFactory(() => StandingBloc(getStandings: sl()));
  sl.registerFactory(() => MatchesBloc(getMatchesPerTeam: sl()));
  sl.registerFactory(() => BnvCubit());
  sl.registerFactory(() => SeasonsCubit(getSeasonsUseCase: sl()));
  sl.registerFactory(() => PlayersBloc(getAllPlayersInfos: sl()));
  sl.registerFactory(() => StatsBloc(repository: sl()));
  sl.registerLazySingleton(
    () => MatchDetailsBloc(getMatchDetailsUseCase: sl()),
  );
  sl.registerFactory(
    () => PlayerAttributesBloc(getPlayerAttributesUseCase: sl()),
  );
  sl.registerFactory(
    () => NationalTeamStatsBloc(getNationalTeamStatsUseCase: sl()),
  );
  sl.registerFactory(
    () => LastYearSummaryBloc(getLastYearSummaryUseCase: sl()),
  );
  sl.registerFactory(
    () => TransferHistoryBloc(getTransferHistoryUseCase: sl()),
  );
  sl.registerFactory(() => MediaBloc(getMediaUseCase: sl()));

  // New Player and Manager Blocs
  sl.registerFactory(
    () => PlayerPerMatchBloc(repository: sl()),
  ); // Added PlayerPerMatchBloc
  sl.registerFactory(() => ManagerBloc(repository: sl())); // Added ManagerBloc
  sl.registerFactory(() => PlayerMatchStatsBloc(getPlayerMatchStats: sl()));

  sl.registerFactory(() => HomeMatchesBloc(getHomeMatchesUseCase: sl()));
  sl.registerFactory(() => MatchesPerRoundBloc(getMatchesPerRound: sl()));
  sl.registerLazySingleton(() => ThemeCubit());
  //********************** Use Cases **********************//
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => GetAllCountriesUseCase(sl()));
  sl.registerLazySingleton(() => GetLeaguesByCountryUseCase(sl()));
  sl.registerLazySingleton(() => GetStandingsUseCase(sl()));
  sl.registerLazySingleton(() => GetSeasonsUseCase(sl()));
  sl.registerLazySingleton(() => GetMatchesPerTeam(sl()));
  sl.registerLazySingleton(() => GetAllPlayersInfos(sl()));
  sl.registerLazySingleton(() => GetTeamStatsUseCAse(sl()));
  sl.registerLazySingleton(() => GetMatchDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetPlayerMatchStats(sl()));
  sl.registerLazySingleton(() => GetMatchesPerRound(sl()));
  // New Player Use Cases
  sl.registerLazySingleton(() => GetPlayerAttributesUseCase(sl()));
  sl.registerLazySingleton(() => GetNationalTeamStatsUseCase(sl()));
  sl.registerLazySingleton(() => GetLastYearSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetTransferHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetMediaUseCase(sl()));
  sl.registerLazySingleton(() => GetHomeMatchesUseCase(sl()));
  // Repositories
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
    () => StatsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<OneMatchStatsRepository>(
    () => OneMatchStatsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<PlayerDetailsRepository>(
    () => PlayerDetailsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<PlayerMatchStatsRepository>(
    () => PlayerMatchStatsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<WebViewApiCall>(() => WebViewApiCall());



  // Data Sources
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(client: sl(), localDataSource: sl()),
  );
  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<GamesRemoteDataSource>(
    () => GamesRemoteDataSourceImpl(webViewApiCall: sl()),
  );

  sl.registerLazySingleton<GamesLocalDataSource>(
    () => GamesLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<LeaguesRemoteDataSource>(
    () => LeaguesRemoteDataSourceImpl(webViewApiCall: sl()),
  );

  sl.registerLazySingleton<LeaguesLocalDataSource>(
    () => LeaguesLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<StandingsRemoteDataSource>(
    () => StandingsRemoteDataSourceImpl(webViewApiCall: sl()),
  );

  sl.registerLazySingleton<StandingsLocalDataSource>(
    () => StandingsLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<MatchesRemoteDataSource>(
    () => MatchesRemoteDataSourceImpl(webViewApiCall: sl()),
  );

  sl.registerLazySingleton<MatchesLocalDataSource>(
    () => MatchesLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<PlayersRemoteDataSource>(
    () => PlayersRemoteDataSourceImpl(webViewApiCall: sl()),
  );

  sl.registerLazySingleton<PlayersLocalDataSource>(
    () => PlayersLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<StatsRemoteDataSource>(
    () => StatsRemoteDataSourceImpl(webViewApiCall: sl()),
  );

  sl.registerLazySingleton<StatsLocalDataSource>(
    () => StatsLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<OneMatchRemoteDataSource>(
    () => OneMatchRemoteDataSourceImpl( webViewApiCall: sl()),
  );

  sl.registerLazySingleton<OneMatchLocalDataSource>(
    () => OneMatchLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton<PlayerDetailsRemoteDataSource>(
    () => PlayerDetailsRemoteDataSourceImpl(webViewApiCall: sl()),
  );

  sl.registerLazySingleton<PlayerDetailsLocalDataSource>(
    () => PlayerDetailsLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<PlayerMatchStatsRemoteDataSource>(
    () => PlayerMatchStatsRemoteDataSourceImpl(webViewApiCall: sl()),
  );

  sl.registerLazySingleton<PlayerMatchStatsLocalDataSource>(
    () => PlayerMatchStatsLocalDataSourceImpl(sharedPreferences: sl()),
  );

  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker.instance,
  );
}
