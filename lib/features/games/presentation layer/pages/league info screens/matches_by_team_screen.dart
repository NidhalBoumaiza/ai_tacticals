import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../domain layer/entities/matches_entities.dart';
import '../../bloc/matches_bloc/matches_bloc.dart';
import '../../widgets/home page widgets/standing screen widgets/country_flag_widget.dart';

class GamesPerRoundScreen extends StatefulWidget {
  final int uniqueTournamentId;
  final int seasonId;

  const GamesPerRoundScreen({
    super.key,
    required this.uniqueTournamentId,
    required this.seasonId,
  });

  @override
  State<GamesPerRoundScreen> createState() => _GamesPerRoundScreenState();
}

class _GamesPerRoundScreenState extends State<GamesPerRoundScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MatchesBloc>().add(
      GetMatchesEvent(
        uniqueTournamentId: widget.uniqueTournamentId,
        seasonId: widget.seasonId,
      ),
    );
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

  void _handleNotificationToggle(MatchEventEntity match) {
    print('Toggling notification for match ID: ${match.id}');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchesBloc, MatchesState>(
      builder: (context, state) {
        if (state is MatchesLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        } else if (state is MatchesLoaded) {
          final matchesPerTeam = state.matches.tournamentTeamEvents;
          if (matchesPerTeam == null || matchesPerTeam.isEmpty) {
            return Center(
              child: ReusableText(
                text: 'No matches available',
                textSize: 100.sp,
                textColor: Colors.white,
                textFontWeight: FontWeight.w600,
              ),
            );
          }

          // Flatten all matches correctly from the nested Map structure
          final allMatches = <MatchEventEntity>[];
          for (var tournamentEntry in matchesPerTeam.entries) {
            final teamMatches = tournamentEntry.value;
            for (var match in teamMatches) {
              allMatches.add(match);
            }
          }

          // Group matches by team ID
          final uniqueMatchesByTeam = <String, List<MatchEventEntity>>{};
          final seenMatchIds = <int>{};

          for (var match in allMatches) {
            if (match.homeTeam?.id != null) {
              final teamId = match.homeTeam!.id.toString();
              if (!uniqueMatchesByTeam.containsKey(teamId)) {
                uniqueMatchesByTeam[teamId] = [];
              }
              if (!seenMatchIds.contains(match.id)) {
                uniqueMatchesByTeam[teamId]!.add(match);
                seenMatchIds.add(match.id!);
              }
            }
            if (match.awayTeam?.id != null) {
              final teamId = match.awayTeam!.id.toString();
              if (!uniqueMatchesByTeam.containsKey(teamId)) {
                uniqueMatchesByTeam[teamId] = [];
              }
              if (!seenMatchIds.contains(match.id)) {
                uniqueMatchesByTeam[teamId]!.add(match);
                seenMatchIds.add(match.id!);
              }
            }
          }

          // Sort teams alphabetically by team name (shortName)
          final sortedTeams =
              uniqueMatchesByTeam.entries.toList()..sort(
                (a, b) => (a.value.first.homeTeam?.shortName ?? '').compareTo(
                  b.value.first.homeTeam?.shortName ?? '',
                ),
              );

          // Sort matches within each team by startTimestamp (ascending)
          for (var entry in sortedTeams) {
            entry.value.sort(
              (a, b) =>
                  (a.startTimestamp ?? 0).compareTo(b.startTimestamp ?? 0),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    sortedTeams.map((entry) {
                      final teamId = entry.key;
                      final matches = entry.value;
                      final teamName =
                          matches.first.homeTeam?.shortName ?? "Unknown Team";
                      late int index = 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: matches.length,
                            itemBuilder: (context, index) {
                              final match = matches[index];
                              final date =
                                  match.startTimestamp != null
                                      ? DateTime.fromMillisecondsSinceEpoch(
                                        match.startTimestamp! * 1000,
                                      )
                                      : null;
                              final status = _getMatchStatus(match);
                              index++;
                              return Column(
                                children: [
                                  index == 1
                                      ? Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10.h,
                                          horizontal: 15.w,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade800,
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(12.r),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            CountryFlagWidget(flag: teamId),
                                            SizedBox(width: 10.w),
                                            ReusableText(
                                              text: teamName,
                                              textSize: 110.sp,
                                              textColor: Colors.white,
                                              textFontWeight: FontWeight.w700,
                                            ),
                                          ],
                                        ),
                                      )
                                      : SizedBox.shrink(),
                                  Container(
                                    padding: EdgeInsets.all(20.w),
                                    decoration: BoxDecoration(
                                      color: const Color(0xff161d1f),
                                      borderRadius: BorderRadius.vertical(
                                        bottom: Radius.circular(12.r),
                                      ),
                                    ),
                                    margin: EdgeInsets.only(bottom: 12.h),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        SizedBox(
                                          width: 180.w,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              ReusableText(
                                                text:
                                                    date != null
                                                        ? "${date.day}.${date.month}.${date.year}"
                                                        : "N/A",
                                                textSize: 90.sp,
                                                textColor: Colors.white,
                                              ),
                                              if (status.isNotEmpty)
                                                ReusableText(
                                                  text: status,
                                                  textSize: 80.sp,
                                                  textColor: Colors.grey,
                                                ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 20.w),
                                        Container(
                                          width: 2.w,
                                          height: 80.h,
                                          color: Colors.grey.shade600,
                                        ),
                                        Expanded(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              SizedBox(width: 30.w),
                                              CountryFlagWidget(
                                                flag:
                                                    match.homeTeam!.id
                                                        .toString(),
                                              ),
                                              SizedBox(width: 10.w),
                                              ReusableText(
                                                text:
                                                    match.homeTeam?.shortName ??
                                                    "Unknown",
                                                textSize: 100.sp,
                                                textColor: Colors.white,
                                                textFontWeight: FontWeight.w600,
                                              ),
                                              SizedBox(width: 20.w),
                                              ReusableText(
                                                text:
                                                    '${match.homeScore?.current ?? "-"} - ${match.awayScore?.current ?? "-"}',
                                                textSize: 100.sp,
                                                textColor: Colors.white,
                                                textFontWeight: FontWeight.w600,
                                              ),
                                              SizedBox(width: 20.w),
                                              SizedBox(
                                                width: 200.w,
                                                child: ReusableText(
                                                  text:
                                                      match
                                                          .awayTeam
                                                          ?.shortName ??
                                                      "Unknown",
                                                  textSize: 100.sp,
                                                  textColor: Colors.white,
                                                  textFontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(width: 10.w),
                                              CountryFlagWidget(
                                                flag:
                                                    match.awayTeam!.id
                                                        .toString(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          );
        } else if (state is MatchesError) {
          return Center(child: Image.asset("assets/images/Empty.png"));
        }
        return Container();
      },
    );
  }
}
