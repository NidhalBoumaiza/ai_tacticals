import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    // Delay data fetching until the widget tree is built
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
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            Container(
              width: 110.w,
              height: 110.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade800, // Fallback color
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
                          width: 110.w,
                          height: 110.w,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(55.w),
                          ),
                        ),
                      ),
                  errorWidget: (context, url, error) {
                    print(
                      'Error loading player ${widget.playerId} image: $error',
                    );
                    return Icon(
                      Icons.person,
                      size: 60.w,
                      color: Colors.grey.shade600,
                    );
                  },
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
              textColor: const Color(0xFFF1D778),
              textFontWeight: FontWeight.w700,
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF3D07E), Color(0xFF33353B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 6,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFF1D778),
        backgroundColor: const Color(0xFF33353B),
        child: CustomScrollView(
          controller: _scrollController,
          cacheExtent: 1000, // Cache offscreen items for better performance
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

  // Stats Summary Section
  Widget _buildStatsSummary() => SliverPadding(
    padding: const EdgeInsets.all(16),
    sliver: SliverToBoxAdapter(
      child: BlocBuilder<PlayerAttributesBloc, PlayerAttributesState>(
        buildWhen:
            (previous, current) =>
                current is PlayerAttributesLoading ||
                current is PlayerAttributesError ||
                current is PlayerAttributesLoaded,
        builder: (context, state) {
          if (state is PlayerAttributesLoading) {
            return const ShimmerLoading(width: double.infinity, height: 300);
          }
          if (state is PlayerAttributesError) {
            return _buildErrorWidget(state.message);
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

  // Performance Trend Section with Line Chart
  Widget _buildPerformanceSection() => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  side: const BorderSide(color: Color(0xFFF3D07E), width: 0.3),
                ),
                color: const Color(0xFF33353B).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Performance Trend',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF1D778),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.info_outline,
                              color: Color(0xFFF1D778),
                              size: 20,
                            ),
                            onPressed: () => _showPerformanceInfo(context),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 200,
                        child: ClipRect(child: _buildEnhancedLineChart(state)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    ),
  );

  Widget _buildEnhancedLineChart(LastYearSummaryState state) {
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
        return const Center(
          child: Text(
            'No valid data to display',
            style: TextStyle(color: Color(0xFFF1D778)),
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
                  color: const Color(0xFFF3D07E).withOpacity(0.3),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFF1D778),
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
                        //   axisSide: meta.axisSide,
                        meta: meta,
                        child: Text(
                          DateFormat('MM/yy').format(date),
                          style: const TextStyle(fontSize: 10),
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
            border: Border.all(color: const Color(0xFFF3D07E).withOpacity(0.5)),
          ),
          minY: 0,
          maxY: 10,
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 7,
                color: const Color(0xFFF3D07E).withOpacity(0.6),
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
                          const TextStyle(color: Color(0xFFF1D778)),
                          children: [
                            TextSpan(
                              text: '\nRating: ${spot.y.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: Color(0xFFF3D07E),
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
              color: const Color(0xFFF1D778),
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFF3D07E).withOpacity(0.15),
              ),
            ),
          ],
        ),
      );
    }
    return const ShimmerLoading(width: double.infinity, height: 200);
  }

  // National Team Stats Section
  Widget _buildNationalTeamSection() => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    sliver: BlocBuilder<NationalTeamStatsBloc, NationalTeamStatsState>(
      buildWhen:
          (previous, current) =>
              current is NationalTeamStatsLoading ||
              current is NationalTeamStatsError ||
              current is NationalTeamStatsLoaded,
      builder: (context, state) {
        if (state is NationalTeamStatsLoading) {
          return const SliverToBoxAdapter(child: ShimmerLoading(height: 150));
        }
        if (state is NationalTeamStatsError) {
          return _buildErrorWidget(state.message);
        }
        if (state is NationalTeamStatsLoaded) {
          return SliverToBoxAdapter(
            child: StatsGrid(
              items: [
                StatItem(
                  Icons.flag,
                  'Team',
                  state.stats.team?.name ?? '-',
                  color: const Color(0xFFF1D778),
                ),
                StatItem(
                  FontAwesomeIcons.personRunning,
                  'Appearences',
                  state.stats.appearances?.toString() ?? '-',
                  color: const Color(0xFFF1D778),
                ),
                StatItem(
                  Icons.sports_soccer,
                  'Goals',
                  state.stats.goals?.toString() ?? '-',
                  color: const Color(0xFFF1D778),
                ),
                StatItem(
                  Icons.calendar_today,
                  'Debut',
                  state.stats.debutDate != null
                      ? DateFormat('yyyy').format(state.stats.debutDate!)
                      : '-',
                  color: const Color(0xFFF1D778),
                ),
              ],
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    ),
  );

  // Transfer History Section
  Widget _buildTransferHistory() => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    sliver: BlocBuilder<TransferHistoryBloc, TransferHistoryState>(
      buildWhen:
          (previous, current) =>
              current is TransferHistoryLoading ||
              current is TransferHistoryError ||
              current is TransferHistoryLoaded,
      builder: (context, state) {
        if (state is TransferHistoryLoading) {
          return const SliverToBoxAdapter(child: ShimmerLoading(height: 100));
        }
        if (state is TransferHistoryError) {
          return _buildErrorWidget(state.message);
        }
        if (state is TransferHistoryLoaded) {
          if (state.transfers.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No transfer history available',
                  style: TextStyle(color: Color(0xFFF1D778)),
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

  // Media Section
  Widget _buildMediaSection() => SliverPadding(
    padding: const EdgeInsets.all(16),
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
          return _buildErrorWidget(state.message);
        }
        if (state is MediaLoaded) {
          if (state.media.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No media available',
                  style: TextStyle(color: Color(0xFFF1D778)),
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

  // Utility Widgets and Methods
  Widget _buildErrorWidget(String message) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'Error: $message',
        style: const TextStyle(color: Color(0xFFF1D778), fontSize: 14),
      ),
    ),
  );

  void _showPerformanceInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Performance Trend Info',
              style: TextStyle(color: Color(0xFFF1D778)),
            ),
            content: const Text(
              'This chart shows the player\'s rating trend over the last year. The orange line indicates a benchmark rating of 7.',
              style: TextStyle(color: Color(0xFFF3D07E)),
            ),
            backgroundColor: const Color(0xFF33353B),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFFF1D778)),
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
              media.title ?? 'Media Preview',
              style: const TextStyle(color: Color(0xFFF1D778)),
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
                        (context, url, error) =>
                            const Icon(Icons.error, color: Color(0xFFF1D778)),
                  ),
                const SizedBox(height: 8),
                if (media.url != null)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(media.url!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cannot launch URL',
                              style: TextStyle(color: Color(0xFF33353B)),
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      media.url!,
                      style: const TextStyle(
                        color: Color(0xFFF3D07E),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
            backgroundColor: const Color(0xFF33353B),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Color(0xFFF1D778)),
                ),
              ),
            ],
          ),
    );
  }
}

// Supporting Widgets
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF3D07E), Color(0xFF33353B)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF33353B),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Attributes Radar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF1D778),
                        ),
                      ),
                      Icon(Icons.expand_more, color: Color(0xFFF1D778)),
                    ],
                  ),
                  if (isExpanded)
                    SizedBox(
                      height: 250,
                      child: ClipRect(
                        child: RadarChart(
                          RadarChartData(
                            radarBackgroundColor: Colors.transparent,
                            radarBorderData: const BorderSide(
                              color: Color(0xFFF3D07E),
                              width: 0.5,
                            ),
                            gridBorderData: const BorderSide(
                              color: Color(0xFFF1D778),
                              width: 0.3,
                            ),
                            titleTextStyle: const TextStyle(
                              color: Color(0xFFF1D778),
                              fontSize: 14,
                            ),
                            tickCount: 5,
                            ticksTextStyle: const TextStyle(
                              color: Color(0xFFF3D07E),
                              fontSize: 10,
                            ),
                            dataSets: [
                              RadarDataSet(
                                fillColor: const Color(
                                  0xFFF1D778,
                                ).withOpacity(0.15),
                                borderColor: const Color(0xFFF3D07E),
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
                                'Attacking',
                                'Technical',
                                'Tactical',
                                'Defending',
                                'Creativity',
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
      margin: const EdgeInsets.only(left: 24),
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFFF3D07E), width: 2)),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.swap_horiz,
          color: Color(0xFFF1D778),
          size: 30,
        ),
        title: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 16),
            children: [
              TextSpan(
                text: transfer.fromTeam?.name ?? 'Unknown Team',
                style: const TextStyle(
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const TextSpan(text: ' → '),
              TextSpan(
                text: transfer.toTeam?.name ?? 'Unknown Team',
                style: const TextStyle(
                  color: Color(0xFFF1D778),
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
                  : 'N/A',
              style: const TextStyle(fontSize: 12, color: Color(0xFFF3D07E)),
            ),
            if (transfer.fee != null)
              Chip(
                label: Text(
                  '${NumberFormat.compactCurrency(symbol: transfer.currency ?? '').format(transfer.fee)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF33353B),
                  ),
                ),
                backgroundColor: const Color(0xFFF1D778).withOpacity(0.3),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            const Color(0xFF33353B).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: color, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: color,
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
                    color: const Color(0xFF33353B).withOpacity(0.3),
                  ),
              fadeInDuration: const Duration(milliseconds: 200),
              fadeOutDuration: const Duration(milliseconds: 200),
            ),
            Center(
              child: Icon(
                Icons.play_circle_filled,
                size: 40,
                color: const Color(0xFFF1D778).withOpacity(0.8),
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
      baseColor: const Color(0xFF33353B).withOpacity(0.3),
      highlightColor: const Color(0xFFF3D07E).withOpacity(0.2),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF33353B).withOpacity(0.1),
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
      children: const [
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
