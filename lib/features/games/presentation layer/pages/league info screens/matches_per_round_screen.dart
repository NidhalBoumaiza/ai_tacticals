// matches_per_round_screen.dart
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
  final ScrollController _scrollController = ScrollController();
  int _currentRound = 10; // Start with round 10
  late final MatchesPerRoundBloc _matchesBloc;

  @override
  void initState() {
    super.initState();
    _matchesBloc = context.read<MatchesPerRoundBloc>();
    _initializeData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(MatchesPerRoundScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leagueId != widget.leagueId ||
        oldWidget.seasonId != widget.seasonId) {
      _currentRound = 10; // Reset to initial round on league/season change
      _initializeData();
    }
  }

  void _initializeData() {
    if (!_matchesBloc.isRoundCached(
      widget.leagueId,
      widget.seasonId,
      _currentRound,
    )) {
      _matchesBloc.add(
        FetchMatchesPerRound(
          leagueId: widget.leagueId,
          seasonId: widget.seasonId,
          round: _currentRound,
        ),
      );
    }
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200.h &&
        _matchesBloc.state is MatchesPerRoundLoaded) {
      final currentState = _matchesBloc.state as MatchesPerRoundLoaded;
      if (!currentState.isLoadingMore) {
        _currentRound++;
        if (!_matchesBloc.isRoundCached(
          widget.leagueId,
          widget.seasonId,
          _currentRound,
        )) {
          _matchesBloc.add(
            FetchMatchesPerRound(
              leagueId: widget.leagueId,
              seasonId: widget.seasonId,
              round: _currentRound,
            ),
          );
        }
      }
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Theme-based background
      body: BlocBuilder<MatchesPerRoundBloc, MatchesPerRoundState>(
        builder: (context, state) {
          // Check cache first and initialize with cached data if available
          final cachedMatches = _matchesBloc.getCachedMatches(
            widget.leagueId,
            widget.seasonId,
          );
          if (state is MatchesPerRoundInitial &&
              cachedMatches != null &&
              cachedMatches.isNotEmpty) {
            return _buildMatchesContent(cachedMatches);
          }

          if (state is MatchesPerRoundLoading) {
            return Center(
              child: CircularProgressIndicator(
                color:
                    Theme.of(context).colorScheme.primary, // Theme-based color
              ),
            );
          } else if (state is MatchesPerRoundLoaded) {
            return _buildMatchesContent(state.matches);
          } else if (state is MatchesPerRoundError) {
            return Center(child: Image.asset("assets/images/Empty.png"));
          }
          return Container();
        },
      ),
    );
  }

  Widget _buildMatchesContent(Map<int, List<MatchEventEntity>> matchesByRound) {
    if (matchesByRound.isEmpty) {
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

    final sortedRounds = matchesByRound.keys.toList()..sort();

    return SingleChildScrollView(
      controller: _scrollController,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...sortedRounds.map((round) {
              final matches = matchesByRound[round]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 10.h,
                      horizontal: 15.w,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(
                            context,
                          ).colorScheme.surface, // Theme-based surface
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12.r),
                      ),
                    ),
                    child: ReusableText(
                      text: 'round'.tr.replaceAll('{number}', round.toString()),
                      textSize: 110.sp,
                      textColor:
                          Theme.of(
                            context,
                          ).textTheme.bodyLarge!.color!, // Theme-based color
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                color: Theme.of(context).colorScheme.onSurface
                                    .withOpacity(0.5), // Theme-based divider
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
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
                      );
                    },
                  ),
                ],
              );
            }).toList(),
            if (_matchesBloc.state is MatchesPerRoundLoaded &&
                (_matchesBloc.state as MatchesPerRoundLoaded).isLoadingMore)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color:
                        Theme.of(
                          context,
                        ).colorScheme.primary, // Theme-based color
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
