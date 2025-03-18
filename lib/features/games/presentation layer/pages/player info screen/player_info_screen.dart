import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/widgets/reusable_text.dart';
import '../../../domain layer/entities/player_statics_entity.dart';
import '../../bloc/last year summery bloc/last_year_summary_bloc.dart';
import '../../bloc/media bloc/media_bloc.dart';
import '../../bloc/national team bloc/national_team_stats_bloc.dart';
import '../../bloc/player statics bloc/player_attributes_bloc.dart';
import '../../bloc/transfert history bloc/transfer_history_bloc.dart';

class PlayerStatsScreen extends StatefulWidget {
  final String playerName;
  final int playerId;

  const PlayerStatsScreen({
    super.key,
    required this.playerId,
    String? playerName,
  }) : playerName = playerName ?? '';

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  final _scrollController = ScrollController();
  final _expandedSection = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();

      _scrollController.addListener(() {});
    });
  }

  Future<void> _refreshData() async {
    context.read<PlayerAttributesBloc>().add(
      FetchPlayerAttributes(widget.playerId),
    );
    context.read<LastYearSummaryBloc>().add(
      FetchLastYearSummary(widget.playerId),
    );
    context.read<NationalTeamStatsBloc>().add(
      FetchNationalTeamStats(widget.playerId),
    );
    context.read<TransferHistoryBloc>().add(
      FetchTransferHistory(widget.playerId),
    );
    context.read<MediaBloc>().add(FetchMedia(widget.playerId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _expandedSection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 110.w,
              height: 110.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surfaceVariant,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  width: 2,
                ),
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
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 25.w),
            Expanded(
              child: ReusableText(
                text: widget.playerName,
                textSize: 130.sp,
                textColor: Theme.of(context).colorScheme.onSurface,
                textFontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 4,
        shadowColor: Theme.of(context).shadowColor.withOpacity(0.3),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          // Ensure scrolling is always enabled
          slivers: [
            _buildStatsSummary(),
            _buildPerformanceSection(),
            _buildNationalTeamSection(),
            _buildTransferHistory(),
            _buildMediaSection(),
            // Replace SliverFillRemaining with a small spacer to avoid consuming all space
            SliverToBoxAdapter(child: SizedBox(height: 50.h)),
            // Minimum spacer
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary() => SliverPadding(
    padding: EdgeInsets.all(30.w),
    sliver: SliverToBoxAdapter(
      child: BlocBuilder<PlayerAttributesBloc, PlayerAttributesState>(
        builder: (context, state) {
          if (state is PlayerAttributesLoading) {
            return ShimmerLoading(
              width: double.infinity,
              height: 250.h,
            ); // Increased height
          }
          if (state is PlayerAttributesError) {
            return ErrorCard(message: state.message, onRetry: _refreshData);
          }
          if (state is PlayerAttributesLoaded) {
            return AnimatedStatsCard(
              attributes: state.attributes,
              expanded: _expandedSection,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  Widget _buildPerformanceSection() => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
    sliver: SliverToBoxAdapter(
      child: BlocBuilder<LastYearSummaryBloc, LastYearSummaryState>(
        builder: (context, state) {
          if (state is LastYearSummaryLoading) {
            return ShimmerLoading(
              width: double.infinity,
              height: 350.h,
            ); // Increased height
          }
          if (state is LastYearSummaryError) {
            return ErrorCard(message: state.message, onRetry: _refreshData);
          }
          if (state is LastYearSummaryLoaded) {
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ReusableText(
                          text: 'performance_trend'.tr,
                          textSize: 120.sp,
                          textColor: Theme.of(context).colorScheme.onSurface,
                          textFontWeight: FontWeight.bold,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 50.sp,
                          ),
                          onPressed: () => _showPerformanceInfo(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _buildEnhancedLineChart(state, context),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  Widget _buildEnhancedLineChart(
    LastYearSummaryState state,
    BuildContext context,
  ) {
    if (state is LastYearSummaryLoaded) {
      final sortedSummary = List<MatchPerformanceEntity>.from(state.summary)
        ..sort(
          (a, b) => (a.date ?? DateTime(0)).compareTo(b.date ?? DateTime(0)),
        );

      final validSpots =
          sortedSummary
              .asMap()
              .entries
              .where(
                (entry) =>
                    entry.value.rating != null &&
                    entry.value.date != null &&
                    entry.value.rating! >= 0 &&
                    entry.value.rating! <= 10,
              )
              .map((entry) => FlSpot(entry.key.toDouble(), entry.value.rating!))
              .toList();

      if (validSpots.length < 2) {
        return Center(
          child: ReusableText(
            text:
                validSpots.isEmpty
                    ? 'no_valid_data_to_display'.tr
                    : 'insufficient_data_for_trend'.tr,
            textSize: 100.sp,
            textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        );
      }

      return ClipRect(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 500.h),
          child: Padding(
            padding: EdgeInsets.only(top: 25.0.h),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40, // Increased for better label visibility
                      getTitlesWidget:
                          (value, meta) => Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedSummary.length) {
                          final date = sortedSummary[index].date;
                          if (date != null) {
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                DateFormat('MM/yy').format(date),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            );
                          }
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 10,
                extraLinesData: const ExtraLinesData(horizontalLines: []),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems:
                        (spots) =>
                            spots.map((spot) {
                              final date = sortedSummary[spot.x.toInt()].date;
                              return LineTooltipItem(
                                '${DateFormat('MMM dd').format(date!)}\n',
                                TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 23.sp,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        '${'rating'.tr}: ${spot.y.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 23.sp,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: validSpots,
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 5,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                    ),
                    dotData: FlDotData(show: true),
                    preventCurveOverShooting: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return ShimmerLoading(
      width: double.infinity,
      height: 350.h,
    ); // Increased height
  }

  Widget _buildNationalTeamSection() => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
    sliver: SliverToBoxAdapter(
      child: BlocBuilder<NationalTeamStatsBloc, NationalTeamStatsState>(
        builder: (context, state) {
          if (state is NationalTeamStatsLoading) {
            return ShimmerLoading(height: 250.h); // Increased height
          }
          if (state is NationalTeamStatsError) {
            return ErrorCard(message: state.message, onRetry: _refreshData);
          }
          if (state is NationalTeamStatsLoaded) {
            return StatsGrid(
              items: [
                StatItem(
                  Icons.flag,
                  'team'.tr,
                  state.stats.team?.name ?? '-',
                  color: Theme.of(context).colorScheme.primary,
                ),
                StatItem(
                  FontAwesomeIcons.personRunning,
                  'appearances'.tr,
                  state.stats.appearances?.toString() ?? '-',
                  color: Theme.of(context).colorScheme.primary,
                ),
                StatItem(
                  Icons.sports_soccer,
                  'goals'.tr,
                  state.stats.goals?.toString() ?? '-',
                  color: Theme.of(context).colorScheme.primary,
                ),
                StatItem(
                  Icons.calendar_today,
                  'debut'.tr,
                  state.stats.debutDate != null
                      ? DateFormat('yyyy').format(state.stats.debutDate!)
                      : '-',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  Widget _buildTransferHistory() => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
    sliver: SliverToBoxAdapter(
      child: BlocBuilder<TransferHistoryBloc, TransferHistoryState>(
        builder: (context, state) {
          if (state is TransferHistoryLoading) {
            return ShimmerLoading(height: 250.h); // Increased height
          }
          if (state is TransferHistoryError) {
            return ErrorCard(message: state.message, onRetry: _refreshData);
          }
          if (state is TransferHistoryLoaded) {
            if (state.transfers.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(20.w),
                child: ReusableText(
                  text: 'no_transfer_history_available'.tr,
                  textSize: 120.sp,
                  textColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReusableText(
                  text: 'transfer_history'.tr,
                  textSize: 140.sp,
                  textColor: Theme.of(context).colorScheme.onSurface,
                  textFontWeight: FontWeight.bold,
                ),
                SizedBox(height: 20.h),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.transfers.length,
                  itemBuilder:
                      (context, index) => TransferTimelineItem(
                        transfer: state.transfers[index],
                        isFirst: index == 0,
                        isLast: index == state.transfers.length - 1,
                      ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  Widget _buildMediaSection() => SliverPadding(
    padding: EdgeInsets.all(30.w),
    sliver: SliverToBoxAdapter(
      child: BlocBuilder<MediaBloc, MediaState>(
        builder: (context, state) {
          if (state is MediaLoading) {
            return ShimmerGridLoading();
          }
          if (state is MediaError) {
            return ErrorCard(message: state.message, onRetry: _refreshData);
          }
          if (state is MediaLoaded) {
            if (state.media.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(20.w),
                child: ReusableText(
                  text: 'no_media_available'.tr,
                  textSize: 100.sp,
                  textColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReusableText(
                  text: 'media'.tr,
                  textSize: 120.sp,
                  textColor: Theme.of(context).colorScheme.onSurface,
                  textFontWeight: FontWeight.bold,
                ),
                SizedBox(height: 20.h),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 15.w,
                    mainAxisSpacing: 15.h,
                    childAspectRatio: 1,
                  ),
                  itemCount: state.media.length,
                  itemBuilder:
                      (context, index) => MediaThumbnail(
                        media: state.media[index],
                        onTap: () async {
                          if (state.media[index].url == null ||
                              state.media[index].url!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: ReusableText(
                                  text: 'invalid_url'.tr,
                                  textSize: 100.sp,
                                  textColor:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                              ),
                            );
                            return;
                          }
                          final uri = Uri.parse(state.media[index].url!);
                          try {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: ReusableText(
                                  text: 'an_error_occurred'.tr,
                                  textSize: 100.sp,
                                  textColor:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                backgroundColor:
                                    Theme.of(context).colorScheme.surface,
                              ),
                            );
                          }
                        },
                      ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  void _showPerformanceInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: ReusableText(
              text: 'performance_trend_info'.tr,
              textSize: 120.sp,
              textColor: Theme.of(context).colorScheme.onSurface,
              textFontWeight: FontWeight.bold,
            ),
            content: ReusableText(
              text: 'performance_trend_description'.tr,
              textSize: 100.sp,
              textColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.7),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: ReusableText(
                  text: 'close'.tr,
                  textSize: 100.sp,
                  textColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
    );
  }

  void _showMediaPreview(BuildContext context, MediaEntity media) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: ReusableText(
              text: media.title ?? 'media_preview'.tr,
              textSize: 120.sp,
              textColor: Theme.of(context).colorScheme.onSurface,
              textFontWeight: FontWeight.bold,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (media.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: media.thumbnailUrl!,
                    height: 200.h,
                    fit: BoxFit.cover,
                    errorWidget:
                        (_, __, ___) => Icon(
                          Icons.error,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 60.sp,
                        ),
                  ),
                SizedBox(height: 20.h),
                if (media.url != null)
                  GestureDetector(
                    onTap: () async {
                      if (media.url == null || media.url!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: ReusableText(
                              text: 'invalid_url'.tr,
                              textSize: 100.sp,
                              textColor:
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                          ),
                        );
                        return;
                      }
                      final uri = Uri.parse(media.url!);
                      try {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: ReusableText(
                              text: 'an_error_occurred'.tr,
                              textSize: 100.sp,
                              textColor:
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                          ),
                        );
                      }
                    },
                    child: ReusableText(
                      text: media.url!,
                      textSize: 90.sp,
                      textColor: Theme.of(context).colorScheme.primary,
                      textDecoration: TextDecoration.underline,
                    ),
                  ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: ReusableText(
                  text: 'close'.tr,
                  textSize: 100.sp,
                  textColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
    );
  }
}

// [Rest of the widget classes (ErrorCard, AnimatedStatsCard, TransferTimelineItem, StatItem, StatsGrid, MediaThumbnail, ShimmerLoading, ShimmerGridLoading) remain unchanged]

// Reusable Error Card Widget
class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorCard({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 60.sp,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 15.h),
            ReusableText(
              text: 'error'.tr,
              textSize: 120.sp,
              textColor: Theme.of(context).colorScheme.onSurface,
              textFontWeight: FontWeight.bold,
            ),
            SizedBox(height: 10.h),
            ReusableText(
              text: message,
              textSize: 100.sp,
              textColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.7),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: ReusableText(
                text: 'retry'.tr,
                textSize: 100.sp,
                textColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep other widgets (AnimatedStatsCard, TransferTimelineItem, StatItem, StatsGrid, MediaThumbnail, ShimmerLoading, ShimmerGridLoading) as they are
class AnimatedStatsCard extends StatelessWidget {
  final PlayerAttributesEntity attributes;
  final ValueNotifier<bool> expanded;

  const AnimatedStatsCard({
    super.key,
    required this.attributes,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final averageAttributes = attributes.averageAttributes?.first;
    final data =
        averageAttributes != null
            ? [
              averageAttributes.attacking?.toDouble() ?? 0,
              averageAttributes.technical?.toDouble() ?? 0,
              averageAttributes.tactical?.toDouble() ?? 0,
              averageAttributes.defending?.toDouble() ?? 0,
              averageAttributes.creativity?.toDouble() ?? 0,
            ]
            : [0.0, 0.0, 0.0, 0.0, 0.0];

    return GestureDetector(
      onTap: () => expanded.value = !expanded.value,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: ValueListenableBuilder<bool>(
            valueListenable: expanded,
            builder:
                (context, isExpanded, child) => Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ReusableText(
                          text: 'attributes_radar'.tr,
                          textSize: 130.sp,
                          textColor: Theme.of(context).colorScheme.onSurface,
                          textFontWeight: FontWeight.bold,
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 60.sp,
                        ),
                      ],
                    ),
                    SizedBox(height: 50.h),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child:
                          isExpanded
                              ? SizedBox(
                                height: 500.h,
                                child: RadarChart(
                                  RadarChartData(
                                    radarBackgroundColor: Colors.transparent,
                                    radarBorderData: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.2),
                                      width: 0.5,
                                    ),
                                    gridBorderData: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.2),
                                      width: 0.3,
                                    ),
                                    titleTextStyle: TextStyle(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                      fontSize: 35.sp,
                                    ),
                                    tickCount: 5,
                                    ticksTextStyle: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    dataSets: [
                                      RadarDataSet(
                                        fillColor: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.1),
                                        borderColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        borderWidth: 2,
                                        entryRadius: 2,
                                        dataEntries:
                                            data
                                                .map(
                                                  (value) =>
                                                      RadarEntry(value: value),
                                                )
                                                .toList(),
                                      ),
                                    ],
                                    radarShape: RadarShape.polygon,
                                    titlePositionPercentageOffset: 0.2,
                                    getTitle: (index, angle) {
                                      final titles = [
                                        'attacking'.tr,
                                        'technical'.tr,
                                        'tactical'.tr,
                                        'defending'.tr,
                                        'creativity'.tr,
                                      ];
                                      return RadarChartTitle(
                                        text: titles[index],
                                      );
                                    },
                                  ),
                                ),
                              )
                              : const SizedBox.shrink(),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

class TransferTimelineItem extends StatelessWidget {
  final TransferEntity transfer;
  final bool isFirst;
  final bool isLast;

  const TransferTimelineItem({
    super.key,
    required this.transfer,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20.h),
      child: Stack(
        children: [
          // Vertical line for the timeline, positioned on the left
          Positioned(
            left: 20.w,
            // Align with the icon's center
            top: isFirst ? 25.h : 0,
            // Start from the middle of the icon for the first item
            bottom: isLast ? 0 : -20.h,
            // Extend slightly to connect with the next item
            child: Container(
              width: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          // Content of the item
          ListTile(
            leading: Icon(
              Icons.swap_horiz,
              color: Theme.of(context).colorScheme.primary,
              size: 50.sp,
            ),
            title: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 80.sp,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: transfer.fromTeam?.name ?? 'unknown_team'.tr,
                    style: TextStyle(
                      fontSize: 40.sp,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  TextSpan(
                    text: ' → ',
                    style: TextStyle(
                      fontSize: 40.sp,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: transfer.toTeam?.name ?? 'unknown_team'.tr,
                    style: TextStyle(
                      fontSize: 40.sp,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReusableText(
                  text:
                      transfer.date != null
                          ? DateFormat('MMM yyyy').format(transfer.date!)
                          : 'n_a'.tr,
                  textSize: 90.sp,
                  textColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                if (transfer.fee != null)
                  Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Chip(
                      label: ReusableText(
                        text: NumberFormat.compactCurrency(
                          symbol: transfer.currency ?? '',
                        ).format(transfer.fee),
                        textSize: 60.sp,
                        textColor: Theme.of(context).colorScheme.onSurface,
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.2),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const StatItem(
    this.icon,
    this.title,
    this.value, {
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50.sp, color: Theme.of(context).colorScheme.primary),
          SizedBox(height: 15.h),
          ReusableText(
            text: title,
            textSize: 90.sp,
            textColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          ReusableText(
            text: value,
            textSize: 110.sp,
            textColor: Theme.of(context).colorScheme.onSurface,
            textFontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }
}

class StatsGrid extends StatelessWidget {
  final List<StatItem> items;

  const StatsGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReusableText(
          text: 'national_team'.tr,
          textSize: 120.sp,
          textColor: Theme.of(context).colorScheme.onSurface,
          textFontWeight: FontWeight.bold,
        ),
        SizedBox(height: 20.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.2,
          children: items,
        ),
      ],
    );
  }
}

class MediaThumbnail extends StatelessWidget {
  final MediaEntity media;
  final VoidCallback onTap;

  const MediaThumbnail({super.key, required this.media, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: media.thumbnailUrl ?? '',
                fit: BoxFit.cover,
                errorWidget:
                    (_, __, ___) => Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                fadeInDuration: const Duration(milliseconds: 200),
                fadeOutDuration: const Duration(milliseconds: 200),
              ),
              Center(
                child: Icon(
                  Icons.play_circle_filled,
                  size: 60.sp,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerLoading({super.key, this.width = 100, this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
      highlightColor: Theme.of(
        context,
      ).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}

class ShimmerGridLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 15.w,
      mainAxisSpacing: 15.h,
      childAspectRatio: 1,
      children: List.generate(
        6,
        (_) => ShimmerLoading(width: double.infinity, height: double.infinity),
      ),
    );
  }
}
