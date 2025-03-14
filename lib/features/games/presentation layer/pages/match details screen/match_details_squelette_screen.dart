import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
      backgroundColor:
          Theme.of(
            context,
          ).scaffoldBackgroundColor, // Light: grey[50], Dark: 0xFF37383c
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, value) {
            return [
              SliverAppBar(
                pinned: true,
                floating: false,
                snap: false,
                expandedHeight: 500.h,
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                // 0xFFfbc02d
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color:
                        Theme.of(context).appBarTheme.foregroundColor, // Black
                    size: 60.sp, // Slightly larger for better touch target
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color:
                        Theme.of(context)
                            .colorScheme
                            .surface, // White (light) or grey[850] (dark)
                    padding: EdgeInsets.only(top: 50.h),
                    child: Column(
                      children: [
                        SizedBox(height: 100.h), // Adjusted for app bar overlap
                        ReusableText(
                          text: widget.leagueName,
                          textSize: 130.sp,
                          textFontWeight: FontWeight.w700,
                          textColor:
                              Theme.of(context)
                                  .colorScheme
                                  .onSurface, // Dark gray (light) or white (dark)
                        ),
                        SizedBox(height: 50.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(right: 15.w),
                                    child: CountryFlagWidget(
                                      flag: widget.homeTeamId,
                                      width: 100.w,
                                      height: 100.w,
                                    ),
                                  ),
                                  Flexible(
                                    child: ReusableText(
                                      text: widget.homeShortName,
                                      textSize: 120.sp,
                                      textFontWeight: FontWeight.w800,
                                      textColor:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.h),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ReusableText(
                                    text:
                                        '${widget.homeScore} - ${widget.awayScore}',
                                    textSize: 120.sp,
                                    textFontWeight: FontWeight.w900,
                                    textColor:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  SizedBox(height: 20.h),
                                  ReusableText(
                                    text: widget.matchStatus,
                                    textSize: 100.sp,
                                    textFontWeight: FontWeight.w900,
                                    textColor:
                                        widget.matchStatus.toLowerCase() ==
                                                'live'
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.error
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(width: 20.w),
                                  Flexible(
                                    child: ReusableText(
                                      text: widget.awayShortName,
                                      textSize: 120.sp,
                                      textFontWeight: FontWeight.w800,
                                      textColor:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 15.w),
                                    child: CountryFlagWidget(
                                      flag: widget.awayTeamId,
                                      width: 100.w,
                                      height: 100.w,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(100.h),
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: false,
                      indicatorPadding: EdgeInsets.symmetric(horizontal: 30.w),
                      labelPadding: EdgeInsets.zero,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      // 0xFFfbc02d
                      indicatorWeight: 4,
                      tabs: [
                        Tab(
                          child: ReusableText(
                            text: 'statistics'.tr,
                            textSize: 120.sp,
                            textFontWeight: FontWeight.w600,
                            textColor: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Tab(
                          child: ReusableText(
                            text: 'lineups'.tr,
                            textSize: 120.sp,
                            textFontWeight: FontWeight.w600,
                            textColor: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBarView(
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
      ),
    );
  }
}
