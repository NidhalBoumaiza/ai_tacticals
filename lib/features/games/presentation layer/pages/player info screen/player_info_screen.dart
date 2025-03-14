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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 110.w,
              height: 110.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surfaceVariant,
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
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(55.w),
                          ),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Icon(
                        Icons.person,
                        size: 60.w,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  fit: BoxFit.cover,
                  width: 110.w,
                  height: 110.w,
                  cacheKey: widget.playerId.toString(),
                ),
              ),
            ),
            SizedBox(width: 25.w),
            ReusableText(
              text: widget.playerName,
              textSize: 130.sp,
              textColor: Theme.of(context).colorScheme.primary,
              textFontWeight: FontWeight.w700,
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 6,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: CustomScrollView(
          controller: _scrollController,
          cacheExtent: 1000,
          slivers: [
            _buildStatsSummary(),
            _buildPerformanceSection(),
            _buildNationalTeamSection(),
            _buildTransferHistory(),
            _buildMediaSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary() => SliverPadding(
    padding: EdgeInsets.all(16.w),
    sliver: SliverToBoxAdapter(
      child: BlocBuilder<PlayerAttributesBloc, PlayerAttributesState>(
        buildWhen:
            (previous, current) =>
                current is PlayerAttributesLoading ||
                current is PlayerAttributesError ||
                current is PlayerAttributesLoaded,
        builder: (context, state) {
          if (state is PlayerAttributesLoading) {
            return ShimmerLoading(width: double.infinity, height: 300.h);
          }
          if (state is PlayerAttributesError) {
            return _buildErrorWidget(state.message, context);
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
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    sliver: SliverToBoxAdapter(
      child: BlocBuilder<LastYearSummaryBloc, LastYearSummaryState>(
        buildWhen:
            (previous, current) =>
                current is LastYearSummaryLoading ||
                current is LastYearSummaryError ||
                current is LastYearSummaryLoaded,
        builder:
            (context, state) => ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                    width: 0.3,
                  ),
                ),
                color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'performance_trend'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            onPressed: () => _showPerformanceInfo(context),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 200.h,
                        child: ClipRect(
                          child: _buildEnhancedLineChart(state, context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                    entry.value.rating != null && entry.value.date != null,
              )
              .map((entry) => FlSpot(entry.key.toDouble(), entry.value.rating!))
              .toList();

      if (validSpots.isEmpty) {
        return Center(
          child: Text(
            'no_valid_data_to_display'.tr,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        );
      }

      return LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine:
                (value) => FlLine(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  strokeWidth: 0.5,
                ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget:
                    (value, meta) => Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
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
                            color: Theme.of(context).colorScheme.onSurface,
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
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
          ),
          minY: 0,
          maxY: 10,
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 7,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ],
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems:
                  (spots) =>
                      spots.map((spot) {
                        final date = sortedSummary[spot.x.toInt()].date;
                        return LineTooltipItem(
                          '${DateFormat('MMM dd').format(date!)}',
                          TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '\n${'rating'.tr}: ${spot.y.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
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
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              ),
            ),
          ],
        ),
      );
    }
    return ShimmerLoading(width: double.infinity, height: 200.h);
  }

  Widget _buildNationalTeamSection() => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
    sliver: BlocBuilder<NationalTeamStatsBloc, NationalTeamStatsState>(
      buildWhen:
          (previous, current) =>
              current is NationalTeamStatsLoading ||
              current is NationalTeamStatsError ||
              current is NationalTeamStatsLoaded,
      builder: (context, state) {
        if (state is NationalTeamStatsLoading) {
          return SliverToBoxAdapter(child: ShimmerLoading(height: 150.h));
        }
        if (state is NationalTeamStatsError) {
          return _buildErrorWidget(state.message, context);
        }
        if (state is NationalTeamStatsLoaded) {
          return SliverToBoxAdapter(
            child: StatsGrid(
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
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    ),
  );

  Widget _buildTransferHistory() => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
    sliver: BlocBuilder<TransferHistoryBloc, TransferHistoryState>(
      buildWhen:
          (previous, current) =>
              current is TransferHistoryLoading ||
              current is TransferHistoryError ||
              current is TransferHistoryLoaded,
      builder: (context, state) {
        if (state is TransferHistoryLoading) {
          return SliverToBoxAdapter(child: ShimmerLoading(height: 100.h));
        }
        if (state is TransferHistoryError) {
          return _buildErrorWidget(state.message, context);
        }
        if (state is TransferHistoryLoaded) {
          if (state.transfers.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'no_transfer_history_available'.tr,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => TransferTimelineItem(
                transfer: state.transfers[index],
                isFirst: index == 0,
                isLast: index == state.transfers.length - 1,
              ),
              childCount: state.transfers.length,
              semanticIndexOffset: 2,
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    ),
  );

  Widget _buildMediaSection() => SliverPadding(
    padding: EdgeInsets.all(16.w),
    sliver: BlocBuilder<MediaBloc, MediaState>(
      buildWhen:
          (previous, current) =>
              current is MediaLoading ||
              current is MediaError ||
              current is MediaLoaded,
      builder: (context, state) {
        if (state is MediaLoading) {
          return SliverToBoxAdapter(child: ShimmerGridLoading());
        }
        if (state is MediaError) {
          return _buildErrorWidget(state.message, context);
        }
        if (state is MediaLoaded) {
          if (state.media.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'no_media_available'.tr,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }
          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MediaThumbnail(
                  media: state.media[index],
                  onTap: () => _showMediaPreview(context, state.media[index]),
                ),
              ),
              childCount: state.media.length,
              semanticIndexOffset: 2,
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    ),
  );

  Widget _buildErrorWidget(String message, BuildContext context) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Text(
            '${'error'.tr}: $message',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
      );

  void _showPerformanceInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'performance_trend_info'.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            content: Text(
              'performance_trend_description'.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'close'.tr,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
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
            title: Text(
              media.title ?? 'media_preview'.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (media.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: media.thumbnailUrl!,
                    height: 200,
                    fit: BoxFit.cover,
                    errorWidget:
                        (context, url, error) => Icon(
                          Icons.error,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                SizedBox(height: 8.h),
                if (media.url != null)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(media.url!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'cannot_launch_url'.tr,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                          ),
                        );
                      }
                    },
                    child: Text(
                      media.url!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'close'.tr,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

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
      child: ValueListenableBuilder<bool>(
        valueListenable: expanded,
        builder: (context, isExpanded, child) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'attributes_radar'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Icon(
                        Icons.expand_more,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                  if (isExpanded)
                    SizedBox(
                      height: 250.h,
                      child: ClipRect(
                        child: RadarChart(
                          RadarChartData(
                            radarBackgroundColor: Colors.transparent,
                            radarBorderData: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 0.5,
                            ),
                            gridBorderData: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 0.3,
                            ),
                            titleTextStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                            ),
                            tickCount: 5,
                            ticksTextStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 10,
                            ),
                            dataSets: [
                              RadarDataSet(
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.15),
                                borderColor:
                                    Theme.of(context).colorScheme.primary,
                                borderWidth: 2,
                                entryRadius: 2,
                                dataEntries:
                                    data
                                        .map(
                                          (value) => RadarEntry(value: value),
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
                              return RadarChartTitle(text: titles[index]);
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
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
    return Container(
      margin: EdgeInsets.only(left: 24.w),
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.swap_horiz,
          color: Theme.of(context).colorScheme.primary,
          size: 30,
        ),
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            children: [
              TextSpan(
                text: transfer.fromTeam?.name ?? 'unknown_team'.tr,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const TextSpan(text: ' → '),
              TextSpan(
                text: transfer.toTeam?.name ?? 'unknown_team'.tr,
                style: TextStyle(
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
            Text(
              transfer.date != null
                  ? DateFormat('MMM yyyy').format(transfer.date!)
                  : 'n_a'.tr,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (transfer.fee != null)
              Chip(
                label: Text(
                  NumberFormat.compactCurrency(
                    symbol: transfer.currency ?? '',
                  ).format(transfer.fee),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.3),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
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
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.2),
            Theme.of(context).colorScheme.surface.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: items,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            CachedNetworkImage(
              imageUrl: media.thumbnailUrl ?? '',
              fit: BoxFit.cover,
              errorWidget:
                  (_, __, ___) => Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.3),
                  ),
              fadeInDuration: const Duration(milliseconds: 200),
              fadeOutDuration: const Duration(milliseconds: 200),
            ),
            Center(
              child: Icon(
                Icons.play_circle_filled,
                size: 40,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ),
            ),
          ],
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
      highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
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
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1,
      children: [
        ShimmerLoading(width: double.infinity, height: double.infinity),
        ShimmerLoading(width: double.infinity, height: double.infinity),
        ShimmerLoading(width: double.infinity, height: double.infinity),
        ShimmerLoading(width: double.infinity, height: double.infinity),
        ShimmerLoading(width: double.infinity, height: double.infinity),
        ShimmerLoading(width: double.infinity, height: double.infinity),
      ],
    );
  }
}
