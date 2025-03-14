import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
  late final StatsBloc _statsBloc;

  @override
  void initState() {
    super.initState();
    _statsBloc = context.read<StatsBloc>();
    _initializeData();
  }

  @override
  void didUpdateWidget(StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teamId != widget.teamId ||
        oldWidget.tournamentId != widget.tournamentId ||
        oldWidget.seasonId != widget.seasonId) {
      _initializeData();
    }
  }

  void _initializeData() {
    if (!_statsBloc.isStatsCached(
      widget.teamId,
      widget.tournamentId,
      widget.seasonId,
    )) {
      _statsBloc.add(
        GetStats(
          teamId: widget.teamId,
          tournamentId: widget.tournamentId,
          seasonId: widget.seasonId,
        ),
      );
    }
  }

  String _formatStat(dynamic value) {
    if (value == null) return 'na'.tr;
    if (value is double) return value.toStringAsFixed(1);
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<StatsBloc, StatsState>(
        builder: (context, state) {
          if (_statsBloc.isStatsCached(
            widget.teamId,
            widget.tournamentId,
            widget.seasonId,
          )) {
            final cachedStats =
                _statsBloc.getCachedStats(
                  widget.teamId,
                  widget.tournamentId,
                  widget.seasonId,
                )!;
            return _buildStatsContent(cachedStats);
          }

          if (state is StatsLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          } else if (state is StatsLoaded) {
            return _buildStatsContent(state.stats);
          } else if (state is StatsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/images/Empty.png"),
                  ReusableText(
                    text: 'no_data_found_for_this'.tr,
                    textSize: 120.sp,
                    textColor: Theme.of(context).colorScheme.onSurface,
                    textFontWeight: FontWeight.w900,
                  ),
                ],
              ),
            );
          }
          return Center(
            child: Text(
              'no_stats_available'.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsContent(StatsEntity stats) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatSection('general'.tr, [
            {'matches'.tr: stats.general?.matches},
            {'possession'.tr: stats.general?.posession},
            {'rating'.tr: stats.general?.avgRating},
          ]),
          _buildStatSection('attacking'.tr, [
            {'goals'.tr: stats.attacking?.goalsScored},
            {'shots'.tr: stats.attacking?.shots},
            {'on_target'.tr: stats.attacking?.shotsOnTarget},
            {'big_chances'.tr: stats.attacking?.bigChances},
          ]),
          _buildStatSection('defensive'.tr, [
            {'conceded'.tr: stats.defensive?.goalsConceded},
            {'tackles'.tr: stats.defensive?.tackles},
            {'interceptions'.tr: stats.defensive?.interceptions},
            {'clean_sheets'.tr: stats.defensive?.cleanSheets},
          ]),
          _buildStatSection('passing'.tr, [
            {'accuracy'.tr: stats.passing?.passAccuracy},
            {'total'.tr: stats.passing?.totalPasses},
            {'cross_accuracy'.tr: stats.passing?.crossAccuracy},
            {'long_balls'.tr: stats.passing?.longBalls},
          ]),
          _buildStatSection('discipline'.tr, [
            {'fouls'.tr: stats.discipline?.fouls},
            {'yellows'.tr: stats.discipline?.yellowCards},
            {'reds'.tr: stats.discipline?.redCards},
            {'offsides'.tr: stats.discipline?.offsides},
          ]),
          _buildStatSection('set_pieces'.tr, [
            {'corners'.tr: stats.setPieces?.corners},
            {'free_kicks'.tr: stats.setPieces?.freeKicks},
            {'pens_scored'.tr: stats.setPieces?.penaltyGoals},
            {'pens_taken'.tr: stats.setPieces?.penaltiesTaken},
          ]),
        ],
      ),
    );
  }

  Widget _buildStatSection(String title, List<Map<String, dynamic?>> stats) {
    return Container(
      margin: EdgeInsets.only(bottom: 30.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 25.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReusableText(
              text: title,
              textSize: 110.sp,
              textColor: Theme.of(context).colorScheme.onSurface,
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
            ? 'na'.tr
            : value is double
            ? '${value.toStringAsFixed(1)}%'
            : value.toString();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
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
              textColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.7),
              textFontWeight: FontWeight.w500,
            ),
          ),
          ReusableText(
            text: displayValue,
            textSize: 110.sp,
            textColor: Theme.of(context).colorScheme.onSurface,
            textFontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}
