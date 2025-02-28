import 'package:analysis_ai/features/auth/data%20layer/data%20sources/user_local_data_source.dart';
import 'package:analysis_ai/features/auth/presentation%20layer/bloc/login_bloc/login_bloc.dart';
import 'package:analysis_ai/features/auth/presentation%20layer/bloc/signup_bloc/signup_bloc.dart';
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
import 'features/games/presentation layer/cubit/bnv cubit/bnv_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Bloc
  sl.registerFactory(() => LoginBloc(login: sl()));
  sl.registerFactory(() => SignupBloc(signup: sl()));

  // Cubit
  sl.registerFactory(() => BnvCubit());

  // ** UseCases **
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  // ** Repositories **
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      userRemoteDataSource: sl(),
      userLocalDataSource: sl(),
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
