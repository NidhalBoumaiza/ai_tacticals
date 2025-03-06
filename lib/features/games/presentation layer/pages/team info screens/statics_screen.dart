import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/widgets/reusable_text.dart';
import '../../../domain layer/entities/statics_entity.dart';
import '../../bloc/stats bloc/stats_bloc.dart';

class StatsScreen extends StatefulWidget {
  final int teamId;
  final int tournamentId;
  final int seasonId;

  const StatsScreen({
    super.key,
    required this.teamId,
    required this.tournamentId,
    required this.seasonId,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StatsBloc>().add(
      GetStats(
        teamId: widget.teamId,
        tournamentId: widget.tournamentId,
        seasonId: widget.seasonId,
      ),
    );
  }

  String _formatStat(dynamic value) {
    if (value == null) return 'N/A';
    if (value is double) return value.toStringAsFixed(1);
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatsBloc, StatsState>(
      builder: (context, state) {
        if (state is StatsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        } else if (state is StatsLoaded) {
          return _buildStatsContent(state.stats);
        } else if (state is StatsError) {
          return Center(
            child: ReusableText(
              text: state.message,
              textSize: 100.sp,
              textColor: Colors.red,
              textFontWeight: FontWeight.w600,
            ),
          );
        }
        return const Center(child: Text('No stats available'));
      },
    );
  }

  Widget _buildStatsContent(StatsEntity stats) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatSection('📊 General', [
            {'🥅 Matches': stats.general?.matches},
            {'⏳ Possession': stats.general?.posession},
            {'⭐ Rating': stats.general?.avgRating},
          ]),
          _buildStatSection('⚽ Attacking', [
            {'🥅 Goals': stats.attacking?.goalsScored},
            {'🎯 Shots': stats.attacking?.shots},
            {'🎯 On Target': stats.attacking?.shotsOnTarget},
            {'🔥 Big Chances': stats.attacking?.bigChances},
          ]),
          _buildStatSection('🛡️ Defensive', [
            {'🥅 Conceded': stats.defensive?.goalsConceded},
            {'🤺 Tackles': stats.defensive?.tackles},
            {'🛑 Interceptions': stats.defensive?.interceptions},
            {'🧼 Clean Sheets': stats.defensive?.cleanSheets},
          ]),
          _buildStatSection('🎯 Passing', [
            {'🎯 Accuracy': stats.passing?.passAccuracy},
            {'🔀 Total': stats.passing?.totalPasses},
            {'✈️ Cross Accuracy': stats.passing?.crossAccuracy},
            {'🚀 Long Balls': stats.passing?.longBalls},
          ]),
          _buildStatSection('📝 Discipline', [
            {'⚠️ Fouls': stats.discipline?.fouls},
            {'🟨 Yellows': stats.discipline?.yellowCards},
            {'🟥 Reds': stats.discipline?.redCards},
            {'🚫 Offsides': stats.discipline?.offsides},
          ]),
          _buildStatSection('🎯 Set Pieces', [
            {'🔄 Corners': stats.setPieces?.corners},
            {'🎯 Free Kicks': stats.setPieces?.freeKicks},
            {'✅ Pens Scored': stats.setPieces?.penaltyGoals},
            {'🎯 Pens Taken': stats.setPieces?.penaltiesTaken},
          ]),
        ],
      ),
    );
  }

  Widget _buildStatSection(String title, List<Map<String, dynamic?>> stats) {
    return Container(
      margin: EdgeInsets.only(bottom: 30.h),
      decoration: BoxDecoration(
        color: const Color(0xff1E2629),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 25.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReusableText(
              text: title,
              textSize: 110.sp,
              textColor: Colors.white,
              textFontWeight: FontWeight.w700,
            ),
            SizedBox(height: 25.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 30.w,
                mainAxisSpacing: 25.h,
                childAspectRatio: 3.2,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final entry = stats[index];
                return _buildStatItem(
                  label: entry.keys.first,
                  value: entry.values.first,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required String label, required dynamic value}) {
    final displayValue =
        value == null
            ? 'N/A'
            : value is double
            ? '${value.toStringAsFixed(1)}%'
            : value.toString();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff161D1F),
        borderRadius: BorderRadius.circular(12.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 18.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: ReusableText(
              text: label,
              textSize: 100.sp,
              textColor: Colors.white70,
              textFontWeight: FontWeight.w500,
            ),
          ),
          ReusableText(
            text: displayValue,
            textSize: 110.sp,
            textColor: Colors.white,
            textFontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}
