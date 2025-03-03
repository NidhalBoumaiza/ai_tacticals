import 'package:analysis_ai/features/games/presentation%20layer/cubit/seasons%20cubit/seasons_cubit.dart';
import 'package:analysis_ai/features/games/presentation%20layer/pages/bottom%20app%20bar%20screens/home_screen_squelette.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/presentation layer/bloc/login_bloc/login_bloc.dart';
import 'features/auth/presentation layer/bloc/signup_bloc/signup_bloc.dart';
import 'features/auth/presentation layer/pages/starter_screen.dart';
import 'features/games/presentation layer/bloc/countries_bloc/countries_bloc.dart';
import 'features/games/presentation layer/bloc/leagues_bloc/leagues_bloc.dart';
import 'features/games/presentation layer/bloc/standing bloc/standing_bloc.dart';
import 'features/games/presentation layer/cubit/bnv cubit/bnv_cubit.dart';
import 'i18n/app_translations.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  final AppLifecycleObserver observer = AppLifecycleObserver();
  WidgetsBinding.instance.addObserver(observer);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('TOKEN');
  Widget screen;
  if (token != null && token.isNotEmpty) {
    print('Token: $token');
    screen = HomeScreenSquelette();
  } else {
    screen = StarterScreen();
  }
  // await dotenv.load(fileName: ".env");
  // await dotenv.load(fileName: ".env");
  runApp(MyApp(screen: screen));
}

class MyApp extends StatelessWidget {
  final Widget screen;

  MyApp({super.key, required this.screen});

  @override
  Widget build(BuildContext context) {
    print(screen);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (create) => di.sl<BnvCubit>()..changeIndex(0)),
        BlocProvider(create: (create) => di.sl<LoginBloc>()),
        BlocProvider(create: (create) => di.sl<SignupBloc>()),
        BlocProvider(create: (create) => di.sl<CountriesBloc>()),
        BlocProvider(create: (create) => di.sl<LeaguesBloc>()),
        BlocProvider(create: (create) => di.sl<StandingBloc>()),
        BlocProvider(create: (create) => di.sl<SeasonsCubit>()),
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
            home: screen,
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
