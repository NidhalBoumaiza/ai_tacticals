import 'package:analysis_ai/core/utils/navigation_with_transition.dart';
import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart'; // For translations

import '../../../domain%20layer/entities/matches_entities.dart';
import '../../bloc/matches_bloc/matches_bloc.dart';
import '../../widgets/home%20page%20widgets/standing%20screen%20widgets/country_flag_widget.dart';
import '../match%20details%20screen/match_details_squelette_screen.dart';

class GamesPerRoundScreen extends StatefulWidget {
  final String leagueName;
  final int uniqueTournamentId;
  final int seasonId;

  const GamesPerRoundScreen({
    super.key,
    required this.uniqueTournamentId,
    required this.seasonId,
    required this.leagueName,
  });

  @override
  State<GamesPerRoundScreen> createState() => _GamesPerRoundScreenState();
}

class _GamesPerRoundScreenState extends State<GamesPerRoundScreen> {
  late final MatchesBloc _matchesBloc;

  @override
  void initState() {
    super.initState();
    _matchesBloc = context.read<MatchesBloc>();
    _initializeData();
  }

  @override
  void didUpdateWidget(GamesPerRoundScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uniqueTournamentId != widget.uniqueTournamentId ||
        oldWidget.seasonId != widget.seasonId) {
      _initializeData();
    }
  }

  void _initializeData() {
    if (!_matchesBloc.isMatchesCached(
      widget.uniqueTournamentId,
      widget.seasonId,
    )) {
      _matchesBloc.add(
        GetMatchesEvent(
          uniqueTournamentId: widget.uniqueTournamentId,
          seasonId: widget.seasonId,
        ),
      );
    }
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
    // Placeholder for notification toggle logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<MatchesBloc, MatchesState>(
        builder: (context, state) {
          if (_matchesBloc.isMatchesCached(
            widget.uniqueTournamentId,
            widget.seasonId,
          )) {
            final cachedMatches =
                _matchesBloc.getCachedMatches(
                  widget.uniqueTournamentId,
                  widget.seasonId,
                )!;
            return _buildMatchesContent(cachedMatches);
          }

          if (state is MatchesLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          } else if (state is MatchesLoaded) {
            return _buildMatchesContent(state.matches);
          } else if (state is MatchesError) {
            return Center(child: Image.asset("assets/images/Empty.png"));
          }
          return Container();
        },
      ),
    );
  }

  Widget _buildMatchesContent(MatchEventsPerTeamEntity matches) {
    final matchesPerTeam = matches.tournamentTeamEvents;
    if (matchesPerTeam == null || matchesPerTeam.isEmpty) {
      return Center(
        child: ReusableText(
          text: 'no_matches_available_generic'.tr,
          textSize: 100.sp,
          textColor: Theme.of(context).textTheme.bodyLarge!.color!,
          textFontWeight: FontWeight.w600,
        ),
      );
    }

    // Log the processed data for debugging

    // Build a map of teamId to teamName for consistent naming
    final Map<String, String> teamIdToName = {};
    matchesPerTeam.forEach((teamId, matchList) {
      if (matchList.isNotEmpty) {
        final team =
            matchList.first.homeTeam?.id.toString() == teamId
                ? matchList.first.homeTeam
                : matchList.first.awayTeam?.id.toString() == teamId
                ? matchList.first.awayTeam
                : null;
        teamIdToName[teamId] = team?.shortName ?? 'Unknown Team';
      }
    });

    // Deduplicate matches within each team
    final Map<String, List<MatchEventEntity>> deduplicatedMatches = {};
    matchesPerTeam.forEach((teamId, matchList) {
      deduplicatedMatches[teamId] = [];
      final uniqueMatches = <String, MatchEventEntity>{};
      for (var match in matchList) {
        final matchKey =
            '${match.homeTeam?.id}_${match.awayTeam?.id}_${match.startTimestamp}_${match.status?.type}';
        if (!uniqueMatches.containsKey(matchKey)) {
          uniqueMatches[matchKey] = match;
        }
      }
      deduplicatedMatches[teamId]!.addAll(uniqueMatches.values);
      // Sort by startTimestamp and limit to 5 matches
      deduplicatedMatches[teamId]!.sort(
        (a, b) => (a.startTimestamp ?? 0).compareTo(b.startTimestamp ?? 0),
      );
      deduplicatedMatches[teamId] =
          deduplicatedMatches[teamId]!.take(5).toList();
    });

    // Sort teams alphabetically by team name
    final teamEntries =
        deduplicatedMatches.entries.toList()..sort(
          (a, b) =>
              (teamIdToName[a.key] ?? '').compareTo(teamIdToName[b.key] ?? ''),
        );

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              teamEntries.map((entry) {
                final teamId = entry.key;
                final teamMatches = entry.value;
                final teamName = teamIdToName[teamId] ?? 'Unknown Team';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 10.h,
                        horizontal: 15.w,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12.r),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CountryFlagWidget(
                            flag: teamId, // Use teamId for the team's flag
                            height: 80.w,
                            width: 80.w,
                            isTeamFlag:
                                true, // Specify that this is a team flag
                          ),
                          SizedBox(width: 10.w),
                          ReusableText(
                            text: teamName,
                            textSize: 110.sp,
                            textColor:
                                Theme.of(context).textTheme.bodyLarge!.color!,
                            textFontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: teamMatches.length,
                      itemBuilder: (context, index) {
                        final match = teamMatches[index];
                        final date =
                            match.startTimestamp != null
                                ? DateTime.fromMillisecondsSinceEpoch(
                                  match.startTimestamp! * 1000,
                                )
                                : null;
                        final status = _getMatchStatus(match);

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
                                leagueName: widget.leagueName,
                                matchDate: date!,
                                matchStatus: status,
                                homeScore: match.homeScore!.current!,
                                awayScore: match.awayScore!.current!,
                                seasonId: widget.seasonId,
                                uniqueTournamentId: widget.uniqueTournamentId,
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(20.w),
                            margin: EdgeInsets.only(bottom: 12.h),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius:
                                  index == teamMatches.length - 1
                                      ? BorderRadius.vertical(
                                        bottom: Radius.circular(12.r),
                                      )
                                      : BorderRadius.zero,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        textColor:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium!.color!,
                                      ),
                                      if (status.isNotEmpty)
                                        ReusableText(
                                          text: status,
                                          textSize: 80.sp,
                                          textColor:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 20.w),
                                Container(
                                  width: 2.w,
                                  height: 80.h,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.5),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 30.w),
                                      Row(
                                        children: [
                                          CountryFlagWidget(
                                            flag: match.homeTeam!.id.toString(),
                                            height: 50.w,
                                            width: 50.w,
                                            isTeamFlag:
                                                true, // Specify that this is a team flag
                                          ),
                                          SizedBox(width: 10.w),
                                          ReusableText(
                                            text:
                                                match.homeTeam?.shortName ??
                                                "Unknown",
                                            textSize: 100.sp,
                                            textColor:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge!.color!,
                                            textFontWeight: FontWeight.w600,
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 20.w),
                                      ReusableText(
                                        text:
                                            '${match.homeScore?.current ?? "-"} - ${match.awayScore?.current ?? "-"}',
                                        textSize: 100.sp,
                                        textColor:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge!.color!,
                                        textFontWeight: FontWeight.w600,
                                      ),
                                      SizedBox(width: 20.w),
                                      Row(
                                        children: [
                                          Row(
                                            children: [
                                              ReusableText(
                                                text:
                                                    match
                                                        .awayTeam
                                                        ?.shortName ??
                                                    "Unknown",
                                                textSize: 100.sp,
                                                textColor:
                                                    Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge!
                                                        .color!,
                                                textFontWeight:
                                                    FontWeight.w600,
                                              ),
                                              SizedBox(width: 10.w),
                                              CountryFlagWidget(
                                                flag:
                                                    match.awayTeam!.id
                                                        .toString(),
                                                height: 50.w,
                                                width: 50.w,
                                                isTeamFlag:
                                                    true, // Specify that this is a team flag
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 55.h),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}
