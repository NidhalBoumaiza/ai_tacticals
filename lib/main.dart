// main.dart
import 'package:analysis_ai/features/auth/presentation%20layer/bloc/login_bloc/login_bloc.dart';
import 'package:analysis_ai/features/auth/presentation%20layer/bloc/signup_bloc/signup_bloc.dart';
import 'package:analysis_ai/features/games/presentation%20layer/bloc/countries_bloc/countries_bloc.dart';
import 'package:analysis_ai/features/games/presentation%20layer/bloc/leagues_bloc/leagues_bloc.dart';
import 'package:analysis_ai/features/games/presentation%20layer/bloc/matches_bloc/matches_bloc.dart';
import 'package:analysis_ai/features/games/presentation%20layer/bloc/players_bloc/players_bloc.dart';
import 'package:analysis_ai/features/games/presentation%20layer/bloc/standing%20bloc/standing_bloc.dart';
import 'package:analysis_ai/features/games/presentation%20layer/bloc/stats%20bloc/stats_bloc.dart';
import 'package:analysis_ai/features/games/presentation%20layer/cubit/bnv%20cubit/bnv_cubit.dart';
import 'package:analysis_ai/features/games/presentation%20layer/cubit/seasons%20cubit/seasons_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/presentation%20layer/pages/starter_screen.dart';
import 'features/games/presentation layer/bloc/last year summery bloc/last_year_summary_bloc.dart';
import 'features/games/presentation layer/bloc/media bloc/media_bloc.dart';
import 'features/games/presentation layer/bloc/national team bloc/national_team_stats_bloc.dart';
import 'features/games/presentation layer/bloc/player statics bloc/player_attributes_bloc.dart';
import 'features/games/presentation layer/bloc/transfert history bloc/transfer_history_bloc.dart';
import 'features/games/presentation layer/pages/bottom app bar screens/home_screen_squelette.dart';
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
        BlocProvider(create: (create) => di.sl<MatchesBloc>()),
        BlocProvider(create: (create) => di.sl<PlayersBloc>()),
        BlocProvider(create: (create) => di.sl<StatsBloc>()),
        // New Player Blocs
        BlocProvider(create: (create) => di.sl<PlayerAttributesBloc>()),
        BlocProvider(create: (create) => di.sl<NationalTeamStatsBloc>()),
        BlocProvider(create: (create) => di.sl<LastYearSummaryBloc>()),
        BlocProvider(create: (create) => di.sl<TransferHistoryBloc>()),
        BlocProvider(create: (create) => di.sl<MediaBloc>()),
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
      CachedNetworkImage.evictFromCache('', cacheKey: "flag");
      print('Cache cleared on app close');
    }
  }
}
