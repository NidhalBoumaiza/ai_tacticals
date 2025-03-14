import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:analysis_ai/features/games/presentation%20layer/pages/team%20info%20screens/squad_screen.dart';
import 'package:analysis_ai/features/games/presentation%20layer/pages/team%20info%20screens/statics_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class TeamInfoScreenSquelette extends StatefulWidget {
  final int teamId;
  final String teamName;
  final int seasonId;
  final int leagueId;

  const TeamInfoScreenSquelette({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.seasonId,
    required this.leagueId,
  });

  @override
  State<TeamInfoScreenSquelette> createState() => _LeagueInfosScreenState();
}

class _LeagueInfosScreenState extends State<TeamInfoScreenSquelette>
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                backgroundColor: Theme.of(context).colorScheme.surface,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 50.sp,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: Theme.of(context).colorScheme.surface,
                    padding: EdgeInsets.only(left: 0, top: 70.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(width: 120.w),
                            CachedNetworkImage(
                              imageUrl:
                                  "https://img.sofascore.com/api/v1/team/${widget.teamId}/image/small",
                              placeholder:
                                  (context, url) => Shimmer.fromColors(
                                    baseColor:
                                        Theme.of(context).colorScheme.surface,
                                    highlightColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.surfaceVariant,
                                    child: Container(
                                      width: 45,
                                      height: 45,
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Icon(
                                    Icons.error,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                              fit: BoxFit.cover,
                              width: 45,
                              height: 45,
                              cacheKey: widget.teamId.toString(),
                            ),
                            SizedBox(width: 20.w),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ReusableText(
                                      text: widget.teamName,
                                      textSize: 120.sp,
                                      textFontWeight: FontWeight.w600,
                                      textColor:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
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
                  preferredSize: const Size.fromHeight(0),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorPadding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.symmetric(horizontal: 0.w),
                    tabs: [
                      Tab(
                        iconMargin: EdgeInsets.zero,
                        child: ReusableText(
                          text: 'squad'.tr,
                          textSize: 120.sp,
                          textFontWeight: FontWeight.w600,
                          textColor: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Tab(
                        child: ReusableText(
                          text: 'statics'.tr,
                          textSize: 120.sp,
                          textFontWeight: FontWeight.w600,
                          textColor: Theme.of(context).colorScheme.onSurface,
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
              SquadScreen(teamId: widget.teamId),
              StatsScreen(
                teamId: widget.teamId,
                tournamentId: widget.leagueId,
                seasonId: widget.seasonId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
