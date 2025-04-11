import 'package:analysis_ai/features/auth/presentation%20layer/pages/login_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_themes.dart';
import 'core/cubit/theme cubit/theme_cubit.dart';
import 'features/auth/presentation layer/bloc/login_bloc/login_bloc.dart';
import 'features/auth/presentation layer/bloc/signup_bloc/signup_bloc.dart';
import 'features/auth/presentation layer/pages/starter_screen.dart';
import 'features/games/presentation layer/bloc/countries_bloc/countries_bloc.dart';
import 'features/games/presentation layer/bloc/home match bloc/home_matches_bloc.dart';
import 'features/games/presentation layer/bloc/last year summery bloc/last_year_summary_bloc.dart';
import 'features/games/presentation layer/bloc/leagues_bloc/leagues_bloc.dart';
import 'features/games/presentation layer/bloc/manager bloc/manager_bloc.dart';
import 'features/games/presentation layer/bloc/matches per round bloc/matches_per_round_bloc.dart';
import 'features/games/presentation layer/bloc/matches_bloc/matches_bloc.dart';
import 'features/games/presentation layer/bloc/media bloc/media_bloc.dart';
import 'features/games/presentation layer/bloc/national team bloc/national_team_stats_bloc.dart';
import 'features/games/presentation layer/bloc/player match stats bloc/player_match_stats_bloc.dart';
import 'features/games/presentation layer/bloc/player per match bloc/player_per_match_bloc.dart';
import 'features/games/presentation layer/bloc/player statics bloc/player_attributes_bloc.dart';
import 'features/games/presentation layer/bloc/players_bloc/players_bloc.dart';
import 'features/games/presentation layer/bloc/standing bloc/standing_bloc.dart';
import 'features/games/presentation layer/bloc/stats bloc/stats_bloc.dart';
import 'features/games/presentation layer/bloc/transfert history bloc/transfer_history_bloc.dart';
import 'features/games/presentation layer/cubit/bnv cubit/bnv_cubit.dart';
import 'features/games/presentation layer/cubit/seasons cubit/seasons_cubit.dart';
import 'features/games/presentation layer/cubit/video editing cubit/video_editing_cubit.dart';
import 'features/games/presentation layer/pages/bottom app bar screens/home_screen_squelette.dart';
import 'i18n/app_translations.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  if (kDebugMode) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  await initializeDateFormatting('fr_FR', null);
  await di.init();

  final AppLifecycleObserver observer = AppLifecycleObserver();
  WidgetsBinding.instance.addObserver(observer);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('TOKEN');
  final savedTheme = prefs.getString('THEME_MODE') ?? 'system'; // Default to system
  final savedLanguage = prefs.getString('LANGUAGE') ?? 'fr_FR'; // Default to French
  final isFirstLoginDone = prefs.getBool('FIRST_LOGIN_DONE') ?? false; // New flag

  // Map saved theme to ThemeMode
  ThemeMode initialThemeMode;
  switch (savedTheme) {
    case 'light':
      initialThemeMode = ThemeMode.light;
      break;
    case 'dark':
      initialThemeMode = ThemeMode.dark;
      break;
    default:
      initialThemeMode = ThemeMode.system;
  }

  // Set initial locale
  Get.updateLocale(Locale(savedLanguage.split('_')[0], savedLanguage.split('_')[1]));

  // Decide initial screen
  Widget screen;
  if (!isFirstLoginDone) {
    screen = const StarterScreen(); // Show StarterScreen only on first launch
  } else {
    screen = token != null && token.isNotEmpty ? const HomeScreenSquelette() : const LoginScreen();
  }

  runApp(MyApp(screen: screen, initialThemeMode: initialThemeMode));
}

class MyApp extends StatelessWidget {
  final Widget screen;
  final ThemeMode initialThemeMode;

  const MyApp({super.key, required this.screen, required this.initialThemeMode});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ThemeCubit(initialThemeMode)),
        BlocProvider(create: (context) => di.sl<BnvCubit>()..changeIndex(0)),
        BlocProvider(create: (context) => di.sl<LoginBloc>()),
        BlocProvider(create: (context) => di.sl<SignupBloc>()),
        BlocProvider(create: (context) => di.sl<CountriesBloc>()),
        BlocProvider(create: (context) => di.sl<LeaguesBloc>()),
        BlocProvider(create: (context) => di.sl<StandingBloc>()),
        BlocProvider(create: (context) => di.sl<SeasonsCubit>()),
        BlocProvider(create: (context) => di.sl<MatchesBloc>()),
        BlocProvider(create: (context) => di.sl<PlayersBloc>()),
        BlocProvider(create: (context) => di.sl<StatsBloc>()),
        BlocProvider(create: (context) => di.sl<PlayerAttributesBloc>()),
        BlocProvider(create: (context) => di.sl<NationalTeamStatsBloc>()),
        BlocProvider(create: (context) => di.sl<LastYearSummaryBloc>()),
        BlocProvider(create: (context) => di.sl<TransferHistoryBloc>()),
        BlocProvider(create: (context) => di.sl<MediaBloc>()),
        BlocProvider(create: (context) => di.sl<PlayerPerMatchBloc>()),
        BlocProvider(create: (context) => di.sl<ManagerBloc>()),
        BlocProvider(create: (context) => di.sl<PlayerMatchStatsBloc>()),
        BlocProvider(create: (context) => di.sl<HomeMatchesBloc>()),
        BlocProvider(create: (context) => di.sl<MatchesPerRoundBloc>()),
        BlocProvider(create: (_) => VideoEditingCubit()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(1080, 2400),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return GetMaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppThemes.lightTheme,
                darkTheme: AppThemes.darkTheme,
                themeMode: themeMode,
                home: screen,
                translations: AppTranslations(),
                locale: Get.locale ?? const Locale('fr', 'FR'),
                fallbackLocale: const Locale('fr', 'FR'),
              );
            },
          );
        },
      ),
    );
  }
}

class AppLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      CachedNetworkImage.evictFromCache('', cacheKey: "flag");
    }
  }
}