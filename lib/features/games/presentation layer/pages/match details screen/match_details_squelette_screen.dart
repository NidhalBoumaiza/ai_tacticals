import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/widgets/reusable_text.dart';
import '../../widgets/home page widgets/standing screen widgets/country_flag_widget.dart';
import 'one_match_squad_screen.dart';
import 'one_match_statics_screen.dart';

class MatchDetailsSqueletteScreen extends StatefulWidget {
  final int matchId;
  final String homeTeamId;
  final String awayTeamId;
  final String homeShortName;

  final String awayShortName;

  final String leagueName;

  final DateTime matchDate;

  final String matchStatus;
  final int homeScore;

  final int awayScore;

  const MatchDetailsSqueletteScreen({
    super.key,
    required this.matchId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeShortName,
    required this.awayShortName,
    required this.leagueName,
    required this.matchDate,
    required this.matchStatus,
    required this.homeScore,
    required this.awayScore,
  });

  @override
  State<MatchDetailsSqueletteScreen> createState() =>
      _MatchDetailsSqueletteScreenState();
}

class _MatchDetailsSqueletteScreenState
    extends State<MatchDetailsSqueletteScreen>
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
                expandedHeight: 500.h,
                // Height of the expanded app bar
                backgroundColor: Color(0xFF33353B),
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
                    color: Color(0xFF33353B),
                    padding: EdgeInsets.only(left: 0, top: 50.h),
                    child: Column(
                      children: [
                        SizedBox(height: 140.h),
                        ReusableText(
                          text: widget.leagueName,
                          textSize: 130.sp,
                          textFontWeight: FontWeight.w700,
                          textColor: Colors.white,
                        ),
                        SizedBox(height: 50.h),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(right: 15.w),
                                      child: CountryFlagWidget(
                                        flag: widget.homeTeamId,
                                        width: 100.w,
                                        height: 100.w,
                                      ),
                                    ),

                                    ReusableText(
                                      text: widget.homeShortName,
                                      textSize: 120.sp,
                                      textFontWeight: FontWeight.w800,
                                    ),
                                    SizedBox(width: 50.w),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 20.h),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ReusableText(
                                        text:
                                            '${widget.homeScore} - ${widget.awayScore}',
                                        textSize: 120.sp,
                                        textFontWeight: FontWeight.w900,
                                        textColor: Colors.white,
                                      ),
                                      SizedBox(height: 20.h),
                                      ReusableText(
                                        text: widget.matchStatus,
                                        textSize: 100.sp,
                                        textFontWeight: FontWeight.w900,
                                        textColor: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    SizedBox(width: 50.w),
                                    ReusableText(
                                      text: widget.awayShortName,
                                      textSize: 120.sp,
                                      textFontWeight: FontWeight.w800,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: 15.w,
                                        bottom: 10.h,
                                      ),
                                      child: CountryFlagWidget(
                                        flag: widget.awayTeamId,
                                        width: 100.w,
                                        height: 100.w,
                                      ),
                                    ),
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
                          text: 'Statistics',
                          textSize: 120.sp, // Much larger text
                          textFontWeight: FontWeight.w600,
                          textColor: Colors.white,
                        ),
                      ),
                      Tab(
                        child: ReusableText(
                          text: 'Lineups',
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
              OneMatchStaticsScreen(
                matchId: widget.matchId,
                homeTeamId: widget.homeTeamId,
                awayTeamId: widget.awayTeamId,
                homeShortName: widget.homeShortName,
                awayShortName: widget.awayShortName,
              ),
              MatchLineupsScreen(matchId: widget.matchId),
            ],
          ),
        ),
      ),
    );
  }
}
