// features/games/presentation layer/widgets/player_stats_modal.dart

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
  final int? jerseyNumber; // Add jersey number
  final String? position; // Add position

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
    // Dispatch the event once when the widget is initialized
    context.read<PlayerMatchStatsBloc>().add(
      FetchPlayerMatchStats(widget.matchId, widget.playerId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xff011f28), // Match the dark theme of MatchLineupsScreen
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: BlocBuilder<PlayerMatchStatsBloc, PlayerMatchStatsState>(
          builder: (context, state) {
            if (state is PlayerMatchStatsLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is PlayerMatchStatsError) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: Colors.white, fontSize: 60.sp),
                ),
              );
            } else if (state is PlayerMatchStatsLoaded) {
              return _buildStatsContent(context, state.playerStats);
            }
            return const SizedBox.shrink(); // Initial state
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
          // Header with close button
          Padding(
            padding: EdgeInsets.symmetric(vertical: 15.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ReusableText(
                  text: 'player_statistics'.tr, // Translated
                  textSize: 160.sp,
                  textFontWeight: FontWeight.bold,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  iconSize: 55.w,
                ),
              ],
            ),
          ),
          // Player Info Header (unchanged)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade800,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl:
                          'https://img.sofascore.com/api/v1/player/${widget.playerId}/image',
                      placeholder:
                          (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              width: 120.w,
                              height: 120.w,
                              color: Colors.grey.shade300,
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Icon(
                            Icons.person,
                            size: 120.w,
                            color: Colors.grey.shade600,
                          ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 25.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReusableText(
                      text: widget.playerName,
                      textSize: 140.sp,
                      textFontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        if (widget.jerseyNumber != null)
                          Text(
                            '#${widget.jerseyNumber}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 60.sp,
                            ),
                          ),
                        if (widget.jerseyNumber != null &&
                            widget.position != null)
                          SizedBox(width: 8.w),
                        if (widget.position != null)
                          Text(
                            widget.position!,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 60.sp,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white30),
          // Stats List
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow(
                      'minutes_played'.tr, // Translated
                      playerStats.statistics?.minutesPlayed ?? 0,
                    ),
                    _buildStatRow(
                      'rating'.tr, // Translated
                      playerStats.statistics?.rating?.toStringAsFixed(1) ??
                          '0.0',
                    ),
                    _buildStatRow(
                      'total_passes'.tr, // Translated
                      playerStats.statistics?.totalPass ?? 0,
                    ),
                    _buildStatRow(
                      'accurate_passes'.tr, // Translated
                      playerStats.statistics?.accuratePass ?? 0,
                    ),
                    _buildStatRow(
                      'total_crosses'.tr, // Translated
                      playerStats.statistics?.totalCross ?? 0,
                    ),
                    _buildStatRow(
                      'duels_won'.tr, // Translated
                      playerStats.statistics?.duelWon ?? 0,
                    ),
                    _buildStatRow(
                      'duels_lost'.tr, // Translated
                      playerStats.statistics?.duelLost ?? 0,
                    ),
                    _buildStatRow(
                      'total_tackles'.tr, // Translated
                      playerStats.statistics?.totalTackle ?? 0,
                    ),
                    _buildStatRow(
                      'fouls'.tr, // Translated
                      playerStats.statistics?.fouls ?? 0,
                    ),
                    _buildStatRow(
                      'touches'.tr, // Translated
                      playerStats.statistics?.touches ?? 0,
                    ),
                    _buildStatRow(
                      'possession_lost'.tr, // Translated
                      playerStats.statistics?.possessionLostCtrl ?? 0,
                    ),
                    _buildStatRow(
                      'expected_assists'.tr, // Translated
                      playerStats.statistics?.expectedAssists?.toStringAsFixed(
                            4,
                          ) ??
                          '0.0',
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

  Widget _buildStatRow(String label, dynamic value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ReusableText(
            text: label,
            textColor: Colors.white70,
            textSize: 125.sp,
            textFontWeight: FontWeight.w500,
          ),
          ReusableText(
            text: value.toString(),
            textColor: Colors.white,
            textSize: 110.sp,
            textFontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }
}
