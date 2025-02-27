import 'package:get_it/get_it.dart';

import 'features/games/presentation layer/cubit/bnv cubit/bnv_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Bloc

  // Cubit
  sl.registerFactory(() => BnvCubit());
}
