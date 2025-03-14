// games_per_round_screen.dart
import 'package:analysis_ai/core/utils/navigation_with_transition.dart';
import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart'; // Added for translations

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

  void _handleNotificationToggle(MatchEventEntity match) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Theme-based background
      body: BlocBuilder<MatchesBloc, MatchesState>(
        builder: (context, state) {
          // Check cache first
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
                color:
                    Theme.of(context).colorScheme.primary, // Theme-based color
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
          textColor:
              Theme.of(
                context,
              ).textTheme.bodyLarge!.color!, // Theme-based color
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
        (a, b) => (a.startTimestamp ?? 0).compareTo(b.startTimestamp ?? 0),
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
                int index = 0; // Reset index for each team
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
                        index++; // Increment index for conditional rendering
                        return Column(
                          children: [
                            if (index ==
                                1) // Show team header only for the first match
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 10.h,
                                  horizontal: 15.w,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context)
                                          .colorScheme
                                          .surface, // Theme-based surface
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(12.r),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    CountryFlagWidget(flag: teamId),
                                    SizedBox(width: 10.w),
                                    ReusableText(
                                      text: teamName,
                                      textSize: 110.sp,
                                      textColor:
                                          Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .color!, // Theme-based color
                                      textFontWeight: FontWeight.w700,
                                    ),
                                  ],
                                ),
                              ),
                            GestureDetector(
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
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(20.w),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant, // Theme-based variant
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
                                            textColor:
                                                Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .color!, // Theme-based color
                                          ),
                                          if (status.isNotEmpty)
                                            ReusableText(
                                              text: status,
                                              textSize: 80.sp,
                                              textColor:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant, // Theme-based color
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
                                      ).colorScheme.onSurface.withOpacity(
                                        0.5,
                                      ), // Theme-based divider
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          SizedBox(width: 30.w),
                                          CountryFlagWidget(
                                            flag: match.homeTeam!.id.toString(),
                                          ),
                                          SizedBox(width: 10.w),
                                          ReusableText(
                                            text:
                                                match.homeTeam?.shortName ??
                                                "Unknown",
                                            textSize: 100.sp,
                                            textColor:
                                                Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge!
                                                    .color!, // Theme-based color
                                            textFontWeight: FontWeight.w600,
                                          ),
                                          SizedBox(width: 20.w),
                                          ReusableText(
                                            text:
                                                '${match.homeScore?.current ?? "-"} - ${match.awayScore?.current ?? "-"}',
                                            textSize: 100.sp,
                                            textColor:
                                                Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge!
                                                    .color!, // Theme-based color
                                            textFontWeight: FontWeight.w600,
                                          ),
                                          SizedBox(width: 20.w),
                                          SizedBox(
                                            width: 200.w,
                                            child: ReusableText(
                                              text:
                                                  match.awayTeam?.shortName ??
                                                  "Unknown",
                                              textSize: 100.sp,
                                              textColor:
                                                  Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge!
                                                      .color!, // Theme-based color
                                              textFontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          CountryFlagWidget(
                                            flag: match.awayTeam!.id.toString(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
  }
}
