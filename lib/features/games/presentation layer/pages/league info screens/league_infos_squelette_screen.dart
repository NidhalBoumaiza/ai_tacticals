// features/games/presentation layer/pages/league info screens/league_infos_squelette_screen.dart

import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:analysis_ai/features/games/presentation layer/pages/league info screens/standing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../domain layer/entities/season_entity.dart';
import '../../bloc/matches_bloc/matches_bloc.dart';
import '../../bloc/standing bloc/standing_bloc.dart';
import '../../widgets/year_drop_down_menu.dart';
import 'matches_by_team_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    selectedSeasonId = widget.seasons[0].id; // Default to the first season
    // Dispatch initial events for the default season
    context.read<StandingBloc>().add(
      GetStanding(leagueId: widget.leagueId, seasonId: selectedSeasonId),
    );
    context.read<MatchesBloc>().add(
      GetMatchesEvent(
        uniqueTournamentId: widget.leagueId,
        seasonId: selectedSeasonId,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onYearChanged(int newSeasonId) {
    setState(() {
      selectedSeasonId = newSeasonId;
    });
    // Dispatch new events to update the data for the selected season
    context.read<StandingBloc>().add(
      GetStanding(leagueId: widget.leagueId, seasonId: selectedSeasonId),
    );
    context.read<MatchesBloc>().add(
      GetMatchesEvent(
        uniqueTournamentId: widget.leagueId,
        seasonId: selectedSeasonId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
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
                        Row(
                          children: [
                            SizedBox(width: 120.w),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        iconMargin: EdgeInsets.zero,
                        child: ReusableText(
                          text: 'Standings',
                          textSize: 120.sp,
                          textFontWeight: FontWeight.w600,
                          textColor: Colors.white,
                        ),
                      ),
                      Tab(
                        child: ReusableText(
                          text: 'Matches',
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
                leagueName: widget.leagueName,
                uniqueTournamentId: widget.leagueId,
                seasonId: selectedSeasonId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
