import 'package:analysis_ai/core/utils/cache_manager.dart'; // Add this import for customCacheManager
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
                expandedHeight: 320.h,
                backgroundColor: Theme.of(context).colorScheme.primary,
                // 0xFFfbc02d
                elevation: 2,
                shadowColor: Theme.of(context).shadowColor.withOpacity(0.3),
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color:
                        Theme.of(context)
                            .colorScheme
                            .onPrimary, // White or contrasting color on yellow
                    size: 50.sp,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: EdgeInsets.only(
                      top: 150.h,
                      left: 70.w,
                      bottom: 20.h,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 100.w,
                          height: 100.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.7),
                              width: 2,
                            ), // White border on yellow
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl:
                                  "https://img.sofascore.com/api/v1/team/${widget.teamId}/image/small",
                              cacheManager: customCacheManager,
                              // Use customCacheManager for consistent caching
                              fit: BoxFit.cover,
                              width: 120.w,
                              height: 120.w,
                              cacheKey: 'team-${widget.teamId}-small',
                              // Unique cache key (e.g., 'team-123-small')
                              placeholder:
                                  (context, url) => Shimmer.fromColors(
                                    baseColor:
                                        Theme.of(context).colorScheme.primary,
                                    highlightColor: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.7),
                                    child: Container(
                                      width: 120.w,
                                      height: 120.w,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Icon(
                                    Icons.error,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    size: 60.sp,
                                  ),
                              fadeInDuration: const Duration(milliseconds: 300),
                              // Smooth fade in
                              fadeOutDuration: const Duration(
                                milliseconds: 300,
                              ), // Smooth fade out
                            ),
                          ),
                        ),
                        SizedBox(width: 30.w),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ReusableText(
                                text: widget.teamName,
                                textSize: 130.sp,
                                textFontWeight: FontWeight.bold,
                                textColor:
                                    Theme.of(context)
                                        .colorScheme
                                        .onPrimary, // White or contrasting color on yellow
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  indicatorColor: Theme.of(context).colorScheme.onPrimary,
                  // White indicator on yellow
                  indicatorWeight: 3,
                  labelPadding: EdgeInsets.symmetric(horizontal: 20.w),
                  tabs: [
                    Tab(
                      child: ReusableText(
                        text: 'squad'.tr,
                        textSize: 110.sp,
                        textFontWeight: FontWeight.bold,
                        textColor:
                            Theme.of(
                              context,
                            ).colorScheme.onPrimary, // White on yellow
                      ),
                    ),
                    Tab(
                      child: ReusableText(
                        text: 'statics'.tr,
                        textSize: 110.sp,
                        textFontWeight: FontWeight.bold,
                        textColor:
                            Theme.of(
                              context,
                            ).colorScheme.onPrimary, // White on yellow
                      ),
                    ),
                  ],
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
