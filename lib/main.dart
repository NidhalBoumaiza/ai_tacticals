import 'package:analysis_ai/features/auth/presentation%20layer/pages/login_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'features/auth/presentation layer/bloc/login_bloc/login_bloc.dart';
import 'features/auth/presentation layer/bloc/signup_bloc/signup_bloc.dart';
import 'features/games/presentation layer/bloc/countries_bloc/countries_bloc.dart';
import 'features/games/presentation layer/cubit/bnv cubit/bnv_cubit.dart';
import 'i18n/app_translations.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  final AppLifecycleObserver observer = AppLifecycleObserver();
  WidgetsBinding.instance.addObserver(observer); // Attach the observer
  // await dotenv.load(fileName: ".env");
  // await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (create) => di.sl<BnvCubit>()..changeIndex(0)),
        BlocProvider(create: (create) => di.sl<LoginBloc>()),
        BlocProvider(create: (create) => di.sl<SignupBloc>()),
        BlocProvider(create: (create) => di.sl<CountriesBloc>()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(1080, 2400),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            ),
            home: LoginScreen(),
            translations: AppTranslations(),
            darkTheme: ThemeData.dark(),
            themeMode: ThemeMode.system,
            locale: const Locale('fr', 'FR'),
            fallbackLocale: const Locale('fr', 'FR'),
          );
        },
      ),
    );
  }
}

class AppLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Clear the cache when the app is paused or detached
      CachedNetworkImage.evictFromCache(
        '',
        cacheKey: "flag",
      ); // Clear the entire cache
      print('Cache cleared on app close');
    }
  }
}
