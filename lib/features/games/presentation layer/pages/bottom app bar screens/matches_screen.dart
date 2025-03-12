import 'package:analysis_ai/core/utils/navigation_with_transition.dart';
import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart'; // Import the package

import '../../../domain layer/entities/matches_entities.dart';
import '../../bloc/home match bloc/home_matches_bloc.dart';
import '../../widgets/home page widgets/standing screen widgets/country_flag_widget.dart';
import '../match details screen/match_details_squelette_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  bool _showLiveMatchesOnly = false; // Toggle state
  late DateTime _selectedDate;
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  bool _isCalendarVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedDay = _selectedDate;
    _calendarFormat = CalendarFormat.month;
    _fetchMatchesForDate(_selectedDate);
  }

  void _fetchMatchesForDate(DateTime date) {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    context.read<HomeMatchesBloc>().add(FetchHomeMatches(date: formattedDate));
  }

  String _getMatchStatus(MatchEventEntity match) {
    if (match.status == null) return '';
    final statusType = match.status!.type?.toLowerCase() ?? '';
    final statusDescription = match.status!.description?.toLowerCase() ?? '';

    if (statusType == 'live') return 'LIVE';
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

  Map<String, List<MatchEventEntity>> _groupMatchesByLeague(
    List<MatchEventEntity> matches,
  ) {
    final groupedMatches = <String, List<MatchEventEntity>>{};
    for (var match in matches) {
      final leagueName = match.tournament?.name ?? 'Unknown League';
      if (!groupedMatches.containsKey(leagueName)) {
        groupedMatches[leagueName] = [];
      }
      groupedMatches[leagueName]!.add(match);
    }
    // Sort matches within each league by startTimestamp
    groupedMatches.forEach((league, matchList) {
      matchList.sort(
        (a, b) => (a.startTimestamp ?? 0).compareTo(b.startTimestamp ?? 0),
      );
    });
    return groupedMatches;
  }

  List<Widget> _buildMatchSection(List<MatchEventEntity> matches) {
    final groupedMatches = _groupMatchesByLeague(matches);
    final sortedLeagues =
        groupedMatches.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return sortedLeagues.map((entry) {
      final leagueName = entry.key;
      final leagueMatches = entry.value;

      if (leagueName == "UEFA Champions League, Knockout Phase") {
        print("*************************************************************");
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // League Logo
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
                    textColor: Colors.white,
                    textFontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...leagueMatches.mapIndexed((index, match) {
            final date =
                match.startTimestamp != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                      match.startTimestamp! * 1000,
                    )
                    : null;
            final status = _getMatchStatus(match);
            final isLive = status == 'LIVE';

            return GestureDetector(
              onTap: () {
                navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                  context,
                  MatchDetailsSqueletteScreen(
                    matchId: match.id!,
                    homeTeamId: match.homeTeam!.id.toString(),
                    awayTeamId: match.awayTeam!.id.toString(),
                    homeShortName: match.homeTeam!.shortName!,
                    awayShortName: match.awayTeam!.shortName!,
                    leagueName: match.tournament?.name ?? 'Unknown League',
                    matchDate: date!,
                    matchStatus: status,
                    homeScore: match.homeScore?.current ?? 0,
                    awayScore: match.awayScore?.current ?? 0,
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.only(bottom: 20.w, top: 20.w),
                decoration: BoxDecoration(
                  color: const Color(0xff161d1f),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(
                      index == leagueMatches.length - 1 ? 12.r : 0,
                    ),
                  ),
                ),
                margin: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 180.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ReusableText(
                            text:
                                date != null
                                    ? "${date.day}.${date.month}.${date.year}"
                                    : "N/A",
                            textSize: 90.sp,
                            textColor: Colors.white,
                          ),
                          if (isLive)
                            ReusableText(
                              text: 'LIVE',
                              textSize: 80.sp,
                              textColor: Colors.red,
                              textFontWeight: FontWeight.bold,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 7.w),
                    Container(
                      width: 2.w,
                      height: 80.h,
                      color: Colors.grey.shade600,
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 20.w),
                          // Home Team Logo
                          CachedNetworkImage(
                            imageUrl:
                                "https://img.sofascore.com/api/v1/team/${match.homeTeam!.id}/image/small",
                            placeholder:
                                (context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    width: 60.w,
                                    height: 60.w,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                            errorWidget: (context, url, error) {
                              print('Error loading image: $error');
                              return Icon(Icons.error);
                            },
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
                              textColor: Colors.white,
                              textFontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 20.w),
                          // Score (in red if live)
                          SizedBox(
                            child: ReusableText(
                              text:
                                  match.homeScore?.current == null &&
                                          match.awayScore?.current == null
                                      ? "VS"
                                      : '${match.homeScore?.current ?? "-"} - ${match.awayScore?.current ?? "-"}',
                              textSize: 100.sp,
                              textColor: isLive ? Colors.red : Colors.white,
                              textFontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 20.w),
                          SizedBox(
                            width: 260.w,
                            child: ReusableText(
                              text: match.awayTeam?.shortName ?? "Unknown",
                              textSize: 100.sp,
                              textColor: Colors.white,
                              textFontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          // Away Team Logo
                          CachedNetworkImage(
                            imageUrl:
                                "https://img.sofascore.com/api/v1/team/${match.awayTeam!.id}/image/small",
                            placeholder:
                                (context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    width: 50.w,
                                    height: 50.w,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                            errorWidget: (context, url, error) {
                              print('Error loading image: $error');
                              return Icon(Icons.error);
                            },
                            fit: BoxFit.cover,
                            width: 50.w,
                            height: 50.w,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF33353B),
        title: ReusableText(
          text: 'Matches',
          textSize: 120.sp,
          textColor: Colors.white,
          textFontWeight: FontWeight.w600,
        ),
        centerTitle: true,
        actions: [
          // Calendar Icon with Day Number
          IconButton(
            icon: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.calendar_today, color: Colors.white),
                Positioned(
                  bottom: 10.h,
                  child: ReusableText(
                    text: _selectedDate.day.toString(),
                    textSize: 60.sp,
                    textColor: Colors.white,
                    textFontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            onPressed: () {
              setState(() {
                _isCalendarVisible = !_isCalendarVisible;
              });
            },
          ),
          // Toggle Button
          IconButton(
            icon: Icon(
              _showLiveMatchesOnly ? Icons.filter_list : Icons.filter_list_off,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showLiveMatchesOnly = !_showLiveMatchesOnly;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Matches List
          BlocBuilder<HomeMatchesBloc, HomeMatchesState>(
            builder: (context, state) {
              if (state is HomeMatchesLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              } else if (state is HomeMatchesError) {
                return Center(child: Image.asset("assets/images/Empty.png"));
              } else if (state is HomeMatchesLoaded) {
                final matchesPerTeam = state.matches.tournamentTeamEvents;
                if (matchesPerTeam == null || matchesPerTeam.isEmpty) {
                  return Center(
                    child: ReusableText(
                      text: 'No matches available for selected date',
                      textSize: 100.sp,
                      textColor: Colors.white,
                      textFontWeight: FontWeight.w600,
                    ),
                  );
                }

                // Flatten all matches
                final allMatches = <MatchEventEntity>[];
                matchesPerTeam.forEach((teamId, matchList) {
                  allMatches.addAll(matchList);
                });

                // Filter matches if toggle is on
                final matchesToDisplay =
                    _showLiveMatchesOnly
                        ? allMatches
                            .where((match) => _getMatchStatus(match) == 'LIVE')
                            .toList()
                        : allMatches;

                if (matchesToDisplay.isEmpty) {
                  return Center(
                    child: ReusableText(
                      text:
                          _showLiveMatchesOnly
                              ? 'No live matches available'
                              : 'No matches available for selected date',
                      textSize: 100.sp,
                      textColor: Colors.white,
                      textFontWeight: FontWeight.w600,
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 30.w,
                      vertical: 20.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildMatchSection(matchesToDisplay),
                    ),
                  ),
                );
              }
              return Container();
            },
          ),
          // Calendar (overlay)
          if (_isCalendarVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: const Color(0xFF33353B),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: TableCalendar(
                  firstDay: DateTime(2000),
                  lastDay: DateTime(2050),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDate = selectedDay;
                      _focusedDay = focusedDay;
                      _isCalendarVisible =
                          false; // Hide calendar after selection
                    });
                    _fetchMatchesForDate(
                      selectedDay,
                    ); // Fetch matches for the selected date
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Extension for indexed mapping
extension IterableIndexed<T> on Iterable<T> {
  Iterable<E> mapIndexed<E>(E Function(int index, T item) f) sync* {
    var index = 0;
    for (final item in this) {
      yield f(index++, item);
    }
  }
}
