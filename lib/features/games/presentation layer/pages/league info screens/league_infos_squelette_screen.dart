import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:analysis_ai/features/games/presentation%20layer/pages/league%20info%20screens/standing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart'; // Added for translations

import '../../../domain%20layer/entities/season_entity.dart';
import '../../bloc/matches_bloc/matches_bloc.dart';
import '../../bloc/standing%20bloc/standing_bloc.dart';
import '../../widgets/year_drop_down_menu.dart';
import 'matches_by_team_screen.dart';
import 'matches_per_round_screen.dart';

class LeagueInfosSqueletteScreen extends StatefulWidget {
  final int leagueId;
  final String leagueName;
  final List<SeasonEntity> seasons;

  const LeagueInfosSqueletteScreen({
    super.key,
    required this.leagueName,
    required this.leagueId,
    required this.seasons,
  });

  @override
  State<LeagueInfosSqueletteScreen> createState() =>
      _LeagueInfosSqueletteScreenState();
}

class _LeagueInfosSqueletteScreenState extends State<LeagueInfosSqueletteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int selectedSeasonId;
  late StandingBloc _standingBloc;
  late MatchesBloc _matchesBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    selectedSeasonId = widget.seasons[0].id;
    _standingBloc = context.read<StandingBloc>();
    _matchesBloc = context.read<MatchesBloc>();
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeData() {
    if (!_standingBloc.isStandingCached(widget.leagueId, selectedSeasonId)) {
      _standingBloc.add(
        GetStanding(leagueId: widget.leagueId, seasonId: selectedSeasonId),
      );
    }
    if (!_matchesBloc.isMatchesCached(widget.leagueId, selectedSeasonId)) {
      _matchesBloc.add(
        GetMatchesEvent(
          uniqueTournamentId: widget.leagueId,
          seasonId: selectedSeasonId,
        ),
      );
    }
    // Note: MatchesPerRoundBloc doesn't need initialization here since MatchesPerRoundScreen handles it
  }

  void _onYearChanged(int newSeasonId) {
    setState(() {
      selectedSeasonId = newSeasonId;
    });
    if (!_standingBloc.isStandingCached(widget.leagueId, selectedSeasonId)) {
      _standingBloc.add(
        GetStanding(leagueId: widget.leagueId, seasonId: selectedSeasonId),
      );
    }
    if (!_matchesBloc.isMatchesCached(widget.leagueId, selectedSeasonId)) {
      _matchesBloc.add(
        GetMatchesEvent(
          uniqueTournamentId: widget.leagueId,
          seasonId: selectedSeasonId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, value) {
            return [
              SliverAppBar(
                pinned: true,
                floating: false,
                snap: false,
                expandedHeight: 360.h,
                backgroundColor: const Color(0xFF33353B),
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 50.sp,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: const Color(0xFF33353B),
                    padding: EdgeInsets.only(left: 0, top: 70.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 120.w),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ReusableText(
                              text: widget.leagueName,
                              textSize: 120.sp,
                              textFontWeight: FontWeight.w600,
                              textColor: Colors.white,
                            ),
                            YearDropdownMenu(
                              seasons: widget.seasons,
                              onYearChanged: _onYearChanged,
                            ),
                            SizedBox(height: 50.h),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(0),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorPadding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.symmetric(horizontal: 0.w),
                    tabs: [
                      Tab(
                        child: ReusableText(
                          text: 'standings'.tr,
                          textSize: 120.sp,
                          textFontWeight: FontWeight.w600,
                          textColor: Colors.white,
                        ),
                      ),
                      Tab(
                        child: ReusableText(
                          text: 'matches'.tr,
                          textSize: 120.sp,
                          textFontWeight: FontWeight.w600,
                          textColor: Colors.white,
                        ),
                      ),
                      Tab(
                        child: ReusableText(
                          text: 'rounds'.tr,
                          textSize: 120.sp,
                          textFontWeight: FontWeight.w600,
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              StandingScreen(
                leagueName: widget.leagueName,
                leagueId: widget.leagueId,
                seasonId: selectedSeasonId,
              ),
              GamesPerRoundScreen(
                // Assuming this is the correct widget name
                leagueName: widget.leagueName,
                uniqueTournamentId: widget.leagueId,
                seasonId: selectedSeasonId,
              ),
              MatchesPerRoundScreen(
                leagueName: widget.leagueName,
                leagueId: widget.leagueId,
                seasonId: selectedSeasonId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
