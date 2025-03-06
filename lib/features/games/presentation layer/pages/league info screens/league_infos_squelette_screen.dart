import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:analysis_ai/features/games/presentation%20layer/pages/league%20info%20screens/standing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../domain layer/entities/season_entity.dart';
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
  late int index = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                // Keep the app bar pinned at the top
                floating: false,
                // Disable floating behavior
                snap: false,
                // Disable snap effect
                expandedHeight: 360.h,
                // Height of the expanded app bar
                backgroundColor: Colors.red,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 50.sp, // Much larger back arrow
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: Colors.red,
                    padding: EdgeInsets.only(left: 0, top: 70.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(width: 120.w), // Increased spacing
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ReusableText(
                                      text: widget.leagueName,
                                      textSize: 120.sp, // Much larger text
                                      textFontWeight: FontWeight.w600,
                                      textColor: Colors.white,
                                    ),
                                    YearDropdownMenu(seasons: widget.seasons),
                                    SizedBox(height: 50.h),
                                    // Increased spacing
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
                  preferredSize: Size.fromHeight(0),
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
                          textSize: 120.sp, // Much larger text
                          textFontWeight: FontWeight.w600,
                          textColor: Colors.white,
                        ),
                      ),
                      Tab(
                        child: ReusableText(
                          text: 'Matches',
                          textSize: 120.sp, // Much larger text
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
                seasonId: widget.seasons[0].id,
              ),
              GamesPerRoundScreen(
                uniqueTournamentId: widget.leagueId,
                seasonId: widget.seasons[0].id,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// List<Widget> tabBarScreens = [
//   StandingsScreen(leagueName: ''),
//   GamesPerRoundScreen(),
//   Test1(),
//   Test2(),
// ];
