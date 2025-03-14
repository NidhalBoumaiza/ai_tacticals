import 'dart:async';

import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../../core/cubit/theme cubit/theme_cubit.dart';
import '../../../domain%20layer/entities/matches_entities.dart';
import '../../bloc/home%20match%20bloc/home_matches_bloc.dart';
import '../../widgets/home%20page%20widgets/standing%20screen%20widgets/country_flag_widget.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  bool _showLiveMatchesOnly = false;
  late DateTime _selectedDate;
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  bool _isCalendarVisible = false;
  bool _isFirstLoad = true;
  Timer? _liveUpdateTimer;
  late ScrollController _scrollController;

  static const List<int> priorityLeagueIds = [
    17,
    7,
    679,
    17015,
    465,
    27,
    10783,
    19,
    211054,
    35,
    34,
    8,
    329,
    213,
    984,
    1682,
    23,
    328,
    341,
  ];

  static final CustomCacheManager _cacheManager = CustomCacheManager(
    Config(
      'teamLogosCache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
    ),
  );

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedDay = _selectedDate;
    _calendarFormat = CalendarFormat.month;
    _scrollController = ScrollController();
    _fetchMatchesForDate(_selectedDate, isInitial: true);

    _liveUpdateTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) _fetchLiveUpdates(_selectedDate);
    });

    _preloadPriorityImages();
  }

  @override
  void dispose() {
    _liveUpdateTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchMatchesForDate(DateTime date, {bool isInitial = false}) {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    context.read<HomeMatchesBloc>().add(
      FetchHomeMatches(date: formattedDate, isInitial: isInitial),
    );
  }

  void _fetchLiveUpdates(DateTime date) {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    context.read<HomeMatchesBloc>().add(
      FetchLiveMatchUpdates(date: formattedDate),
    );
  }

  Future<void> _preloadPriorityImages() async {
    if (!mounted) return;
    final state = context.read<HomeMatchesBloc>().state;
    if (state is HomeMatchesLoaded) {
      final matches =
          state.matches.tournamentTeamEvents?.values
              .expand((m) => m)
              .toList() ??
          [];
      final priorityMatches = matches.where(
        (match) => priorityLeagueIds.contains(match.tournament?.id),
      );
      for (final match in priorityMatches) {
        final homeUrl =
            "https://img.sofascore.com/api/v1/team/${match.homeTeam!.id}/image/small";
        final awayUrl =
            "https://img.sofascore.com/api/v1/team/${match.awayTeam!.id}/image/small";
        await _cacheManager.downloadFile(homeUrl);
        await _cacheManager.downloadFile(awayUrl);
      }
    }
  }

  String _getMatchStatus(MatchEventEntity match) {
    if (match.status == null) return '';
    final statusType = match.status!.type?.toLowerCase() ?? '';
    final statusDescription = match.status!.description?.toLowerCase() ?? '';
    if (statusType == 'inprogress') return 'LIVE';
    if (statusType == 'finished') {
      if (statusDescription.contains('penalties') ||
          statusDescription.contains('extra time'))
        return 'FT (ET/AP)';
      return 'FT';
    }
    if (statusType == 'notstarted' || statusType == 'scheduled') return 'NS';
    return '';
  }

  Map<String, List<MatchEventEntity>> _groupMatchesByLeague(
    List<MatchEventEntity> matches,
  ) {
    final groupedMatches = <String, List<MatchEventEntity>>{};
    for (var match in matches) {
      final leagueName = match.tournament?.name ?? 'Unknown League';
      groupedMatches.putIfAbsent(leagueName, () => []).add(match);
    }
    groupedMatches.forEach((league, matchList) {
      matchList.sort(
        (a, b) => (a.startTimestamp ?? 0).compareTo(b.startTimestamp ?? 0),
      );
    });
    return groupedMatches;
  }

  Widget _buildMatchItem(MatchEventEntity match) {
    final date =
        match.startTimestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(match.startTimestamp! * 1000)
            : null;
    final status = _getMatchStatus(match);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 180.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocSelector<HomeMatchesBloc, HomeMatchesState, String>(
                  selector: (state) {
                    if (state is HomeMatchesLoaded) {
                      final updatedMatch = state
                          .matches
                          .tournamentTeamEvents
                          ?.values
                          .expand((matches) => matches)
                          .firstWhere(
                            (m) => m.id == match.id,
                            orElse: () => match,
                          );
                      final isLive = updatedMatch?.isLive ?? false;
                      final currentMinutes = updatedMatch?.currentLiveMinutes;
                      if (isLive && currentMinutes != null)
                        return "$currentMinutes'";
                      return date != null
                          ? "${DateFormat('MMM d').format(date)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}"
                          : "N/A";
                    }
                    return date != null
                        ? "${DateFormat('MMM d').format(date)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}"
                        : "N/A";
                  },
                  builder: (context, timeText) {
                    return ReusableText(
                      text: timeText,
                      textSize: 90.sp,
                      textColor:
                          match.isLive ?? false
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurface,
                    );
                  },
                ),
                BlocSelector<HomeMatchesBloc, HomeMatchesState, String>(
                  selector: (state) {
                    if (state is HomeMatchesLoaded) {
                      final updatedMatch = state
                          .matches
                          .tournamentTeamEvents
                          ?.values
                          .expand((matches) => matches)
                          .firstWhere(
                            (m) => m.id == match.id,
                            orElse: () => match,
                          );
                      return _getMatchStatus(updatedMatch!);
                    }
                    return status;
                  },
                  builder: (context, statusText) {
                    return statusText.isNotEmpty
                        ? ReusableText(
                          text: statusText,
                          textSize: 80.sp,
                          textColor:
                              statusText == 'LIVE'
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                          textFontWeight: FontWeight.bold,
                        )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: 7.w),
          Container(
            width: 2.w,
            height: 80.h,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 20.w),
                CachedNetworkImage(
                  imageUrl:
                      "https://img.sofascore.com/api/v1/team/${match.homeTeam!.id}/image/small",
                  cacheManager: _cacheManager,
                  fadeInDuration: Duration(milliseconds: 300),
                  placeholder:
                      (context, url) => Container(
                        width: 50.w,
                        height: 50.w,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                  errorWidget:
                      (context, url, error) => Icon(
                        Icons.error,
                        color: Theme.of(context).colorScheme.error,
                      ),
                  fit: BoxFit.cover,
                  width: 50.w,
                  height: 50.w,
                ),
                SizedBox(width: 10.w),
                SizedBox(
                  width: 250.w,
                  child: ReusableText(
                    text: match.homeTeam?.shortName ?? "Unknown",
                    textSize: 100.sp,
                    textColor: Theme.of(context).colorScheme.onSurface,
                    textFontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 20.w),
                BlocSelector<HomeMatchesBloc, HomeMatchesState, String>(
                  selector: (state) {
                    if (state is HomeMatchesLoaded) {
                      final updatedMatch = state
                          .matches
                          .tournamentTeamEvents
                          ?.values
                          .expand((matches) => matches)
                          .firstWhere(
                            (m) => m.id == match.id,
                            orElse: () => match,
                          );
                      return updatedMatch?.homeScore?.current == null &&
                              updatedMatch?.awayScore?.current == null
                          ? "VS"
                          : '${updatedMatch?.homeScore?.current ?? "-"} - ${updatedMatch?.awayScore?.current ?? "-"}';
                    }
                    return match.homeScore?.current == null &&
                            match.awayScore?.current == null
                        ? "VS"
                        : '${match.homeScore?.current ?? "-"} - ${match.awayScore?.current ?? "-"}';
                  },
                  builder: (context, scoreText) {
                    return ReusableText(
                      text: scoreText,
                      textSize: 100.sp,
                      textColor:
                          match.isLive ?? false
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.onSurface,
                      textFontWeight: FontWeight.w600,
                    );
                  },
                ),
                SizedBox(width: 20.w),
                SizedBox(
                  width: 260.w,
                  child: ReusableText(
                    text: match.awayTeam?.shortName ?? "Unknown",
                    textSize: 100.sp,
                    textColor: Theme.of(context).colorScheme.onSurface,
                    textFontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 10.w),
                CachedNetworkImage(
                  imageUrl:
                      "https://img.sofascore.com/api/v1/team/${match.awayTeam!.id}/image/small",
                  cacheManager: _cacheManager,
                  fadeInDuration: Duration(milliseconds: 300),
                  placeholder:
                      (context, url) => Container(
                        width: 50.w,
                        height: 50.w,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                  errorWidget:
                      (context, url, error) => Icon(
                        Icons.error,
                        color: Theme.of(context).colorScheme.error,
                      ),
                  fit: BoxFit.cover,
                  width: 50.w,
                  height: 50.w,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMatchSection(List<MatchEventEntity> matches) {
    final groupedMatches = _groupMatchesByLeague(matches);
    final priorityLeagues = <MapEntry<String, List<MatchEventEntity>>>[];
    final otherLeagues = <MapEntry<String, List<MatchEventEntity>>>[];

    groupedMatches.entries.forEach((entry) {
      final leagueId = entry.value.first.tournament?.id;
      if (leagueId != null && priorityLeagueIds.contains(leagueId)) {
        priorityLeagues.add(entry);
      } else {
        otherLeagues.add(entry);
      }
    });

    priorityLeagues.sort((a, b) {
      final aId = a.value.first.tournament?.id ?? 0;
      final bId = b.value.first.tournament?.id ?? 0;
      final aIndex = priorityLeagueIds.indexOf(aId);
      final bIndex = priorityLeagueIds.indexOf(bId);
      return aIndex.compareTo(bIndex);
    });

    otherLeagues.sort((a, b) => a.key.compareTo(b.key));

    final sortedLeagues = [...priorityLeagues, ...otherLeagues];

    return sortedLeagues.map((entry) {
      final leagueName = entry.key;
      final leagueMatches = entry.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CountryFlagWidget(
                  flag: leagueMatches.first.tournament?.id.toString() ?? '',
                  height: 80.w,
                  width: 80.w,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ReusableText(
                    text: leagueName,
                    textSize: 110.sp,
                    textColor: Theme.of(context).colorScheme.onSurface,
                    textFontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...leagueMatches.map((match) => _buildMatchItem(match)).toList(),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120.h),
        child: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          // 0xFFfbc02d
          elevation: 0,
          title: ReusableText(
            text: 'matches'.tr,
            textSize: 130.sp,
            textColor: Theme.of(context).appBarTheme.foregroundColor, // Black
            textFontWeight: FontWeight.w800,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    size: 60.sp,
                    Icons.calendar_today,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                  Positioned(
                    bottom: 10.h,
                    child: ReusableText(
                      text: _selectedDate.day.toString(),
                      textSize: 60.sp,
                      textColor: Theme.of(context).appBarTheme.foregroundColor,
                      textFontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              onPressed:
                  () =>
                      setState(() => _isCalendarVisible = !_isCalendarVisible),
            ),
            IconButton(
              icon: Icon(
                size: 60.sp,
                _showLiveMatchesOnly
                    ? Icons.watch_later
                    : Icons.watch_later_outlined,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
              onPressed:
                  () => setState(
                    () => _showLiveMatchesOnly = !_showLiveMatchesOnly,
                  ),
            ),
            IconButton(
              onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              icon: Icon(
                size: 60.sp,
                Icons.brightness_6,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
            ),
          ],
        ),
      ),
      backgroundColor:
          Theme.of(
            context,
          ).scaffoldBackgroundColor, // Light: grey[50], Dark: 0xFF37383c
      body: Stack(
        children: [
          BlocBuilder<HomeMatchesBloc, HomeMatchesState>(
            builder: (context, state) {
              if (state is HomeMatchesLoading && _isFirstLoad) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              } else if (state is HomeMatchesError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/images/Empty.png", height: 300.h),
                      SizedBox(height: 20.h),
                      ReusableText(
                        text: 'error_loading_matches'.tr,
                        textSize: 100.sp,
                        textColor: Theme.of(context).colorScheme.onSurface,
                        textFontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                );
              } else if (state is HomeMatchesLoaded) {
                _isFirstLoad = false;
                final matchesPerTeam = state.matches.tournamentTeamEvents;
                if (matchesPerTeam == null || matchesPerTeam.isEmpty) {
                  return Center(
                    child: ReusableText(
                      text: 'no_matches_available'.tr,
                      textSize: 100.sp,
                      textColor: Theme.of(context).colorScheme.onSurface,
                      textFontWeight: FontWeight.w600,
                    ),
                  );
                }

                final allMatches = <MatchEventEntity>[];
                matchesPerTeam.forEach(
                  (teamId, matchList) => allMatches.addAll(matchList),
                );
                final matchesToDisplay =
                    _showLiveMatchesOnly
                        ? allMatches
                            .where((match) => match.isLive ?? false)
                            .toList()
                        : allMatches;

                if (matchesToDisplay.isEmpty) {
                  return Center(
                    child: ReusableText(
                      text:
                          _showLiveMatchesOnly
                              ? 'no_live_matches_available'.tr
                              : 'no_matches_available'.tr,
                      textSize: 100.sp,
                      textColor: Theme.of(context).colorScheme.onSurface,
                      textFontWeight: FontWeight.w600,
                    ),
                  );
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(30.w, 150.h, 30.w, 60.h),
                    // Adjusted for app bar
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildMatchSection(matchesToDisplay),
                    ),
                  ),
                );
              }
              return Center(
                child: ReusableText(
                  text: 'waiting_for_matches'.tr,
                  textSize: 100.sp,
                  textColor: Theme.of(context).colorScheme.onSurface,
                ),
              );
            },
          ),
          if (_isCalendarVisible)
            Positioned(
              top: 120.h, // Position below app bar
              left: 30.w,
              right: 30.w,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12.r),
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  child: TableCalendar(
                    firstDay: DateTime(2000),
                    lastDay: DateTime(2050),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate:
                        (day) => isSameDay(day, _selectedDate),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;
                        _focusedDay = focusedDay;
                        _isCalendarVisible = false;
                      });
                      _fetchMatchesForDate(selectedDay, isInitial: true);
                    },
                    onFormatChanged:
                        (format) => setState(() => _calendarFormat = format),
                    onPageChanged:
                        (focusedDay) =>
                            setState(() => _focusedDay = focusedDay),
                    locale: Get.locale?.toString(),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      weekendTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      titleTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 100.sp,
                      ),
                      formatButtonTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension IterableIndexed<T> on Iterable<T> {
  Iterable<E> mapIndexed<E>(E Function(int index, T item) f) sync* {
    var index = 0;
    for (final item in this) {
      yield f(index++, item);
    }
  }
}

class CustomCacheManager extends CacheManager {
  CustomCacheManager(Config config) : super(config);
  static const key = 'teamLogosCache';
}
