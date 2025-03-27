import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../domain layer/entities/player_entity.dart';
import '../../bloc/player match stats bloc/player_match_stats_bloc.dart';

class PlayerStatsModal extends StatefulWidget {
  final int matchId;
  final int playerId;
  final String playerName;
  final int? jerseyNumber;
  final String? position;

  const PlayerStatsModal({
    super.key,
    required this.matchId,
    required this.playerId,
    required this.playerName,
    this.jerseyNumber,
    this.position,
  });

  @override
  State<PlayerStatsModal> createState() => _PlayerStatsModalState();
}

class _PlayerStatsModalState extends State<PlayerStatsModal> {
  @override
  void initState() {
    super.initState();
    context.read<PlayerMatchStatsBloc>().add(
      FetchPlayerMatchStats(widget.matchId, widget.playerId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color:
            Theme.of(
              context,
            ).colorScheme.surface, // White (light) or grey[850] (dark)
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: BlocBuilder<PlayerMatchStatsBloc, PlayerMatchStatsState>(
          builder: (context, state) {
            if (state is PlayerMatchStatsLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ), // 0xFFfbc02d
              );
            } else if (state is PlayerMatchStatsError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(30.w),
                  child: ReusableText(
                    text: "No Stats Available for now.",
                    textSize: 100.sp,
                    textColor: Theme.of(context).colorScheme.onSurface,
                    textFontWeight: FontWeight.w600,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            } else if (state is PlayerMatchStatsLoaded) {
              return _buildStatsContent(context, state.playerStats);
            }
            return Center(
              child: ReusableText(
                text: 'waiting_for_stats'.tr,
                textSize: 100.sp,
                textColor: Theme.of(context).colorScheme.onSurface,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context, PlayerEntityy playerStats) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 30.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 15.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ReusableText(
                  text: 'player_statistics'.tr,
                  textSize: 160.sp,
                  textFontWeight: FontWeight.bold,
                  textColor: Theme.of(context).colorScheme.onSurface,
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 60.sp, // Slightly larger for better touch target
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Row(
              children: [
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.7),
                      width: 2,
                    ), // 0xFFfbc02d border
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl:
                          'https://img.sofascore.com/api/v1/player/${widget.playerId}/image',
                      placeholder:
                          (context, url) => Shimmer.fromColors(
                            baseColor: Theme.of(context).colorScheme.surface,
                            highlightColor:
                                Theme.of(context).colorScheme.surfaceVariant,
                            child: Container(
                              width: 120.w,
                              height: 120.w,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Icon(
                            Icons.person,
                            size: 60.w,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 30.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReusableText(
                        text: widget.playerName,
                        textSize: 140.sp,
                        textFontWeight: FontWeight.bold,
                        textColor: Theme.of(context).colorScheme.onSurface,
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          if (widget.jerseyNumber != null)
                            ReusableText(
                              text: '#${widget.jerseyNumber}',
                              textSize: 100.sp,
                              textColor: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          if (widget.jerseyNumber != null &&
                              widget.position != null)
                            SizedBox(width: 20.w),
                          if (widget.position != null)
                            ReusableText(
                              text: widget.position!,
                              textSize: 100.sp,
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
          ),
          Divider(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow(
                      context,
                      'minutes_played'.tr,
                      playerStats.statistics?.minutesPlayed ?? 0,
                    ),
                    _buildStatRow(
                      context,
                      'rating'.tr,
                      playerStats.statistics?.rating?.toStringAsFixed(1) ??
                          '0.0',
                    ),
                    _buildStatRow(
                      context,
                      'total_passes'.tr,
                      playerStats.statistics?.totalPass ?? 0,
                    ),
                    _buildStatRow(
                      context,
                      'accurate_passes'.tr,
                      playerStats.statistics?.accuratePass ?? 0,
                    ),
                    _buildStatRow(
                      context,
                      'total_crosses'.tr,
                      playerStats.statistics?.totalCross ?? 0,
                    ),
                    _buildStatRow(
                      context,
                      'duels_won'.tr,
                      playerStats.statistics?.duelWon ?? 0,
                    ),
                    _buildStatRow(
                      context,
                      'duels_lost'.tr,
                      playerStats.statistics?.duelLost ?? 0,
                    ),
                    _buildStatRow(
                      context,
                      'total_tackles'.tr,
                      playerStats.statistics?.totalTackle ?? 0,
                    ),
                    _buildStatRow(
                      context,
                      'fouls'.tr,
                      playerStats.statistics?.fouls ?? 0,
                    ),
                    _buildStatRow(
                      context,
                      'touches'.tr,
                      playerStats.statistics?.touches ?? 0,
                    ),
                    _buildStatRow(
                      context,
                      'possession_lost'.tr,
                      playerStats.statistics?.possessionLostCtrl ?? 0,
                    ),
                    _buildStatRow(
                      context,
                      'expected_assists'.tr,
                      playerStats.statistics?.expectedAssists?.toStringAsFixed(
                            2,
                          ) ??
                          '0.00',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, dynamic value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ReusableText(
            text: label,
            textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            textSize: 110.sp,
            textFontWeight: FontWeight.w500,
          ),
          ReusableText(
            text: value.toString(),
            textColor: Theme.of(context).colorScheme.onSurface,
            textSize: 110.sp,
            textFontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }
}
