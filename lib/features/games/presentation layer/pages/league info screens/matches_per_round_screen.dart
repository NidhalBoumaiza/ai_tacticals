import 'package:analysis_ai/core/utils/navigation_with_transition.dart';
import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:analysis_ai/features/games/domain%20layer/entities/matches_entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart'; // Added for translations

import '../../bloc/matches%20per%20round%20bloc/matches_per_round_bloc.dart';
import '../../widgets/home%20page%20widgets/standing%20screen%20widgets/country_flag_widget.dart';
import '../match%20details%20screen/match_details_squelette_screen.dart';

class MatchesPerRoundScreen extends StatefulWidget {
  final String leagueName;
  final int leagueId;
  final int seasonId;

  const MatchesPerRoundScreen({
    super.key,
    required this.leagueName,
    required this.leagueId,
    required this.seasonId,
  });

  @override
  State<MatchesPerRoundScreen> createState() => _MatchesPerRoundScreenState();
}

class _MatchesPerRoundScreenState extends State<MatchesPerRoundScreen> {
  late final MatchesPerRoundBloc _matchesBloc;

  @override
  void initState() {
    super.initState();
    _matchesBloc = context.read<MatchesPerRoundBloc>();
    _initializeData();
  }

  @override
  void didUpdateWidget(MatchesPerRoundScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leagueId != widget.leagueId ||
        oldWidget.seasonId != widget.seasonId) {
      _initializeData();
    }
  }

  void _initializeData() {
    _matchesBloc.add(
      FetchCurrentAndNextRounds(
        leagueId: widget.leagueId,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<MatchesPerRoundBloc, MatchesPerRoundState>(
        builder: (context, state) {
          final cachedMatches = _matchesBloc.getCachedMatches(
            widget.leagueId,
            widget.seasonId,
          );
          if (state is MatchesPerRoundInitial &&
              cachedMatches != null &&
              cachedMatches.isNotEmpty) {
            int? currentRound;
            int? nextRound;
            final currentTimestamp =
                DateTime.now().millisecondsSinceEpoch ~/ 1000;
            for (int round = 1; round <= cachedMatches.keys.length; round++) {
              if (cachedMatches.containsKey(round)) {
                final matches = cachedMatches[round]!;
                if (matches.isNotEmpty) {
                  bool allUnplayed = matches.every(
                    (match) =>
                        match.startTimestamp != null &&
                        match.startTimestamp! > currentTimestamp &&
                        (match.homeScore?.current == null ||
                            match.awayScore?.current == null) &&
                        match.status?.type != "finished",
                  );
                  if (allUnplayed) {
                    nextRound = round;
                    currentRound = round > 1 ? round - 1 : null;
                    break;
                  }
                }
              }
            }
            if (currentRound != null && nextRound != null) {
              final matchesToDisplay = {
                currentRound: cachedMatches[currentRound] ?? [],
                nextRound: cachedMatches[nextRound] ?? [],
              };
              return _buildMatchesContent(
                matchesToDisplay,
                currentRound,
                nextRound,
              );
            }
          }

          if (state is MatchesPerRoundLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          } else if (state is MatchesPerRoundLoaded) {
            return _buildMatchesContent(
              state.matches,
              state.currentRound,
              state.nextRound,
            );
          } else if (state is MatchesPerRoundError) {
            return Center(child: Image.asset("assets/images/Empty.png"));
          }
          return Container();
        },
      ),
    );
  }

  Widget _buildMatchesContent(
    Map<int, List<MatchEventEntity>> matchesByRound,
    int currentRound,
    int nextRound,
  ) {
    if (matchesByRound.isEmpty) {
      return Center(
        child: ReusableText(
          text: 'no_matches_available_generic'.tr,
          textSize: 100.sp,
          textColor: Theme.of(context).textTheme.bodyLarge!.color!,
          textFontWeight: FontWeight.w600,
        ),
      );
    }

    final roundsToDisplay = [currentRound, nextRound];

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              roundsToDisplay.map((round) {
                final matches = matchesByRound[round] ?? [];
                if (matches.isEmpty) return const SizedBox.shrink();

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
                      child: ReusableText(
                        text:
                            round == currentRound
                                ? 'current_round'.tr + ' - Round $currentRound'
                                : 'next_round'.tr + ' - Round $nextRound',
                        textSize: 110.sp,
                        textColor:
                            Theme.of(context).textTheme.bodyLarge!.color!,
                        textFontWeight: FontWeight.w700,
                      ),
                    ),
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
                                homeScore: match.homeScore?.current ?? 0,
                                awayScore: match.awayScore?.current ?? 0,
                                seasonId: widget.seasonId,
                                uniqueTournamentId: widget.leagueId,
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(12.r),
                              ),
                            ),
                            margin: EdgeInsets.only(bottom: 12.h),
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
                                            isTeamFlag: true,
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
                                            '${match.homeScore?.current ?? " VS "}${match.homeScore?.current != null ? " - " : ""}${match.awayScore?.current ?? ""}',
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
                                          SizedBox(
                                            width: 200.w,
                                            child: ReusableText(
                                              text:
                                                  match.awayTeam?.shortName ??
                                                  "Unknown",
                                              textSize: 100.sp,
                                              textColor:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodyLarge!.color!,
                                              textFontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          CountryFlagWidget(
                                            flag: match.awayTeam!.id.toString(),
                                            isTeamFlag: true,
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
                    SizedBox(height: 20.h),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}
