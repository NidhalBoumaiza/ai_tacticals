import 'package:analysis_ai/core/utils/cache_manager.dart'; // Ensure this import is correct
import 'package:analysis_ai/core/utils/navigation_with_transition.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // Add this for fallback
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/widgets/reusable_text.dart';
import '../../../domain layer/entities/player_entity.dart';
import '../../bloc/players_bloc/players_bloc.dart';
import '../../widgets/home page widgets/standing screen widgets/country_flag_widget.dart';
import '../player info screen/player_info_screen.dart';

// Fallback definition if customCacheManager is not found
final customCacheManagerFallback = CacheManager(
  Config(
    'customCacheKey',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 200,
    repo: JsonCacheInfoRepository(databaseName: 'customCacheKey'),
    fileService: HttpFileService(),
  ),
);

class SquadScreen extends StatefulWidget {
  final int teamId;

  const SquadScreen({super.key, required this.teamId});

  @override
  State<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends State<SquadScreen> {
  late final PlayersBloc _playersBloc;

  @override
  void initState() {
    super.initState();
    _playersBloc = context.read<PlayersBloc>();
    _initializeData();
  }

  @override
  void didUpdateWidget(SquadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teamId != widget.teamId) {
      _initializeData();
    }
  }

  void _initializeData() {
    if (!_playersBloc.isTeamCached(widget.teamId)) {
      _playersBloc.add(GetAllPlayersEvent(teamId: widget.teamId));
    }
  }

  Color _getPositionColor(String position) {
    return switch (position) {
      'Goalkeeper' => Theme.of(context).colorScheme.primary, // 0xFFfbc02d
      'Defense' => Colors.blueAccent,
      'Midfield' => Colors.green,
      'Forward' => Colors.redAccent,
      _ => Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(
            context,
          ).scaffoldBackgroundColor, // Light: grey[50], Dark: 0xFF37383c
      body: BlocBuilder<PlayersBloc, PlayersState>(
        builder: (context, state) {
          if (_playersBloc.isTeamCached(widget.teamId)) {
            final cachedPlayers = _playersBloc.getCachedPlayers(widget.teamId)!;
            return _buildGroupedPlayersList(cachedPlayers);
          }

          if (state is PlayersLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary, // 0xFFfbc02d
              ),
            );
          } else if (state is PlayersError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(30.w),
                child: ReusableText(
                  text: state.message.tr,
                  textSize: 100.sp,
                  textColor: Theme.of(context).colorScheme.error,
                  textFontWeight: FontWeight.w600,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (state is PlayersLoaded) {
            return _buildGroupedPlayersList(state.players);
          }
          return Center(
            child: ReusableText(
              text: 'no_players_available'.tr,
              textSize: 100.sp,
              textColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.7),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupedPlayersList(List<PlayerEntityy> players) {
    final groupedPlayers = <String, List<PlayerEntityy>>{};
    for (var player in players) {
      final position = player.position ?? 'Other Position';
      groupedPlayers.putIfAbsent(position, () => []).add(player);
    }

    const positionOrder = [
      'Goalkeeper',
      'Defense',
      'Midfield',
      'Forward',
      'Other Position',
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 30.h),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          color:
              Theme.of(
                context,
              ).colorScheme.surface, // White (light) or grey[850] (dark)
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  positionOrder
                      .where((pos) => groupedPlayers.containsKey(pos))
                      .map((position) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: 20.h,
                                top: position == positionOrder.first ? 0 : 30.h,
                              ),
                              child: ReusableText(
                                text: position.tr.toLowerCase(),
                                textSize: 120.sp,
                                textColor: _getPositionColor(position),
                                textFontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 15.h),
                            _buildPositionGroup(groupedPlayers[position]!),
                          ],
                        );
                      })
                      .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionGroup(List<PlayerEntityy> players) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: players.length,
      separatorBuilder:
          (context, index) => Divider(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            height: 30.h,
          ),
      itemBuilder: (context, index) {
        final player = players[index];
        return GestureDetector(
          onTap: () {
            if (player.id != null && player.name != null) {
              navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                context,
                PlayerStatsScreen(
                  playerId: player.id!,
                  playerName: player.name!,
                ),
              );
            }
          },
          child: _buildPlayerRow(player),
        );
      },
    );
  }

  Widget _buildPlayerRow(PlayerEntityy player) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 110.w,
            height: 110.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.7), // 0xFFfbc02d border
                width: 2,
              ),
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl:
                    'https://img.sofascore.com/api/v1/player/${player.id}/image',
                cacheManager: customCacheManager ?? customCacheManagerFallback,
                // Use fallback if undefined
                fit: BoxFit.cover,
                width: 110.w,
                height: 110.w,
                cacheKey: 'player-${player.id}',
                // e.g., 'player-123' for unique caching
                placeholder:
                    (context, url) => Shimmer.fromColors(
                      baseColor: Theme.of(context).colorScheme.surface,
                      highlightColor:
                          Theme.of(context).colorScheme.surfaceVariant,
                      child: Container(
                        width: 110.w,
                        height: 110.w,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                errorWidget:
                    (context, url, error) => Icon(
                      Icons.person,
                      size: 60.w,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 300),
              ),
            ),
          ),
          SizedBox(width: 30.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReusableText(
                  text: player.name ?? 'na'.tr,
                  textSize: 100.sp,
                  textColor: Theme.of(context).colorScheme.onSurface,
                  textFontWeight: FontWeight.w700,
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    SizedBox(
                      width: 60.w,
                      child: ReusableText(
                        text:
                            player.shirtNumber != null
                                ? player.shirtNumber.toString()
                                : player.jerseyNumber != null
                                ? player.jerseyNumber.toString()
                                : 'na'.tr,
                        textSize: 90.sp,
                        textColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(
                      width: 115.w,
                      child: ReusableText(
                        text:
                            player.age != null
                                ? 'years'.tr.replaceAll(
                                  '{age}',
                                  player.age.toString(),
                                )
                                : 'na'.tr,
                        textSize: 90.sp,
                        textColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    CountryFlagWidget(
                      flag: player.countryAlpha2,
                      height: 50.sp,
                      width: 50.sp,
                    ),
                    SizedBox(width: 10.w),
                    ReusableText(
                      text: player.countryAlpha3 ?? 'na'.tr,
                      textSize: 90.sp,
                      textColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
