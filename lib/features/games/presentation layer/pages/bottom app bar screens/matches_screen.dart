import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../../core/widgets/reusable_text.dart';
import '../../../../../core/widgets/web_image_widget.dart'; // Correct import
import '../../../domain layer/entities/matches_entities.dart';
import '../../bloc/home match bloc/home_matches_bloc.dart';

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
  Timer? _liveUpdateTimer;
  final ScrollController _scrollController = ScrollController();

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

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedDay = _selectedDate;
    _calendarFormat = CalendarFormat.week;
    _fetchMatchesForDate(_selectedDate);

    _liveUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchLiveUpdates(_selectedDate);
    });
  }

  void _fetchMatchesForDate(DateTime date) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    context.read<HomeMatchesBloc>().add(FetchHomeMatches(date: formattedDate));
  }

  void _fetchLiveUpdates(DateTime date) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    context.read<HomeMatchesBloc>().add(
      FetchLiveMatchUpdates(date: formattedDate),
    );
  }

  String _getMatchStatus(MatchEventEntity match) {
    final statusType = match.status?.type?.toLowerCase() ?? '';
    final statusDescription = match.status?.description?.toLowerCase() ?? '';

    if (statusType == 'inprogress') return 'LIVE';
    if (statusType == 'finished') {
      if (statusDescription.contains('penalties') ||
          statusDescription.contains('extra time')) {
        return 'FT (ET/AP)';
      }
      return 'FT';
    }
    if (statusType == 'notstarted' || statusType == 'scheduled') return 'NS';
    return '';
  }

  List<MatchEventEntity> _deduplicateMatches(List<MatchEventEntity> matches) {
    final seenIds = <String>{};
    return matches.where((match) {
      final id = '${match.id}-${match.homeTeam?.id}-${match.awayTeam?.id}';
      return seenIds.add(id);
    }).toList();
  }

  Map<String, List<MatchEventEntity>> _groupMatchesByLeague(
    List<MatchEventEntity> matches,
  ) {
    final groupedMatches = <String, List<MatchEventEntity>>{};
    for (var match in matches) {
      final leagueName = match.tournament?.name ?? 'Unknown League';
      groupedMatches.putIfAbsent(leagueName, () => []).add(match);
    }
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
                WebImageWidget(
                  // Updated to WebImageWidget
                  imageUrl:
                      "https://img.sofascore.com/team/${match.homeTeam?.id ?? 'default'}/image",
                  width: 60.w,
                  height: 60.w,

                  onLoaded: () {
                    print('Home team image loaded for ${match.homeTeam?.id}');
                  },
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
                  width: 200.w,
                  child: ReusableText(
                    text: match.awayTeam?.shortName ?? "Unknown",
                    textSize: 100.sp,
                    textColor: Theme.of(context).colorScheme.onSurface,
                    textFontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 10.w),
                WebImageWidget(
                  // Updated to WebImageWidget
                  imageUrl:
                      "https://img.sofascore.com/team/${match.awayTeam?.id ?? 'default'}/image",
                  width: 60.w,
                  height: 60.w,
                  // uniqueKey:
                  //     'away_${match.id}_${match.awayTeam?.id ?? 'default'}',
                  // Fixed uniqueKey
                  onLoaded: () {
                    print('Away team image loaded for ${match.awayTeam?.id}');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueSection(
    String leagueName,
    List<MatchEventEntity> matches,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
          ),
          child: Row(
            children: [
              WebImageWidget(
                // Updated to WebImageWidget
                imageUrl:
                    "https://img.sofascore.com/tournament/${matches.first.tournament?.id ?? 'default'}/image",
                width: 85.w,
                height: 85.w,

                onLoaded: () {
                  print(
                    'League image loaded for ${matches.first.tournament?.id}',
                  );
                },
              ),
              SizedBox(width: 30.w),
              Expanded(
                child: ReusableText(
                  text: leagueName,
                  textSize: 120.sp,
                  textColor: Theme.of(context).colorScheme.onSurface,
                  textFontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        ...matches.map(_buildMatchItem).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed:
                () => setState(() => _isCalendarVisible = !_isCalendarVisible),
          ),
          IconButton(
            icon: Icon(
              _showLiveMatchesOnly ? Icons.live_tv : Icons.live_tv_outlined,
            ),
            onPressed:
                () => setState(
                  () => _showLiveMatchesOnly = !_showLiveMatchesOnly,
                ),
          ),
        ],
      ),
      body: BlocBuilder<HomeMatchesBloc, HomeMatchesState>(
        builder: (context, state) {
          if (state is HomeMatchesLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HomeMatchesError) {
            return const Center(child: Text('Error loading matches'));
          } else if (state is HomeMatchesLoaded) {
            final allMatches =
                state.matches.tournamentTeamEvents?.values
                    .expand((matches) => matches)
                    .toList() ??
                [];

            final filteredMatches =
                _showLiveMatchesOnly
                    ? allMatches
                        .where((match) => match.isLive ?? false)
                        .toList()
                    : allMatches;

            if (filteredMatches.isEmpty) {
              return const Center(child: Text('No matches available'));
            }

            final groupedMatches = _groupMatchesByLeague(
              _deduplicateMatches(filteredMatches),
            );
            final priorityLeagues = <String, List<MatchEventEntity>>{};
            final otherLeagues = <String, List<MatchEventEntity>>{};

            groupedMatches.forEach((league, matches) {
              final leagueId = matches.first.tournament?.id;
              if (leagueId != null && priorityLeagueIds.contains(leagueId)) {
                priorityLeagues[league] = matches;
              } else {
                otherLeagues[league] = matches;
              }
            });

            final sortedLeagues = {...priorityLeagues, ...otherLeagues};

            return ListView(
              controller: _scrollController,
              children: [
                if (_isCalendarVisible)
                  TableCalendar(
                    firstDay: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate:
                        (day) => isSameDay(day, _selectedDate),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;
                        _focusedDay = focusedDay;
                        _isCalendarVisible = false;
                      });
                      _fetchMatchesForDate(selectedDay);
                    },
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      setState(() => _calendarFormat = format);
                    },
                  ),
                ...sortedLeagues.entries
                    .map((entry) => _buildLeagueSection(entry.key, entry.value))
                    .toList(),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  @override
  void dispose() {
    _liveUpdateTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}
