// features/players/presentation/screens/player_stats_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain layer/entities/player_statics_entity.dart';
import '../../bloc/last year summery bloc/last_year_summary_bloc.dart';
import '../../bloc/media bloc/media_bloc.dart';
import '../../bloc/national team bloc/national_team_stats_bloc.dart';
import '../../bloc/player statics bloc/player_attributes_bloc.dart';
import '../../bloc/transfert history bloc/transfer_history_bloc.dart';

class PlayerStatsScreen extends StatefulWidget {
  final int playerId;

  const PlayerStatsScreen({super.key, required this.playerId});

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  final _scrollController = ScrollController();
  final _expandedSection = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    context.read<PlayerAttributesBloc>().add(FetchPlayerAttributes(159665));
    context.read<LastYearSummaryBloc>().add(FetchLastYearSummary(159665));
    context.read<NationalTeamStatsBloc>().add(FetchNationalTeamStats(159665));
    context.read<TransferHistoryBloc>().add(FetchTransferHistory(159665));
    context.read<MediaBloc>().add(FetchMedia(159665));
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Player Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '#${widget.playerId}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          controller: _scrollController,
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
    padding: const EdgeInsets.all(16),
    sliver: SliverToBoxAdapter(
      child: BlocBuilder<PlayerAttributesBloc, PlayerAttributesState>(
        builder: (context, state) {
          if (state is PlayerAttributesLoading) {
            return ShimmerLoading(width: double.infinity, height: 300);
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

  Widget _buildPerformanceSection() => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    sliver: SliverToBoxAdapter(
      child: BlocBuilder<LastYearSummaryBloc, LastYearSummaryState>(
        builder:
            (context, state) => Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Performance Trend',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline, size: 20),
                          onPressed: () => _showPerformanceInfo(context),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 200,
                      child: _buildEnhancedLineChart(state),
                    ),
                  ],
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
        return const Center(child: Text('No valid data to display'));
      }

      return LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  );
                },
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
                        meta: meta, // Make sure to pass this from TitleMeta
                        fitInside: SideTitleFitInsideData.fromTitleMeta(
                          meta,
                          enabled: true, // Enable fit inside
                          distanceFromEdge: 6, // Maintain some spacing
                        ),
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
          borderData: FlBorderData(show: true),
          minY: 0,
          maxY: 10,
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 7,
                color: Colors.orange.withOpacity(0.4),
                strokeWidth: 1,
                dashArray: [5, 5],
              ),
            ],
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              //tooltipBgColor: Colors.deepPurple.shade100,
              getTooltipItems:
                  (spots) =>
                      spots.map((spot) {
                        final date = sortedSummary[spot.x.toInt()].date;
                        return LineTooltipItem(
                          '${DateFormat('MMM dd').format(date!)}',
                          const TextStyle(color: Colors.black87),
                          children: [
                            TextSpan(
                              text: '\nRating: ${spot.y.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Colors.deepPurple.shade800,
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
              color: Colors.deepPurple,
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.deepPurple.withOpacity(0.15),
              ),
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      );
    }
    return ShimmerLoading(width: double.infinity, height: 200);
  }

  Widget _buildNationalTeamSection() => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    sliver: BlocBuilder<NationalTeamStatsBloc, NationalTeamStatsState>(
      builder: (context, state) {
        if (state is NationalTeamStatsLoading) {
          return SliverToBoxAdapter(child: ShimmerLoading(height: 150));
        }
        if (state is NationalTeamStatsError) {
          return SliverToBoxAdapter(child: _buildErrorWidget(state.message));
        }
        if (state is NationalTeamStatsLoaded) {
          return SliverToBoxAdapter(
            child: StatsGrid(
              items: [
                StatItem(Icons.flag, 'Team', state.stats.team?.name ?? '-'),
                StatItem(
                  Icons.emoji_events,
                  'Caps',
                  state.stats.appearances?.toString() ?? '-',
                ),
                StatItem(
                  Icons.sports_soccer,
                  'Goals',
                  state.stats.goals?.toString() ?? '-',
                ),
                StatItem(
                  Icons.calendar_today,
                  'Debut',
                  state.stats.debutDate != null
                      ? DateFormat('yyyy').format(state.stats.debutDate!)
                      : '-',
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
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    sliver: BlocBuilder<TransferHistoryBloc, TransferHistoryState>(
      builder: (context, state) {
        if (state is TransferHistoryLoading) {
          return SliverToBoxAdapter(child: ShimmerLoading(height: 100));
        }
        if (state is TransferHistoryError) {
          return SliverToBoxAdapter(child: _buildErrorWidget(state.message));
        }
        if (state is TransferHistoryLoaded) {
          if (state.transfers.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No transfer history available'),
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
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    ),
  );

  Widget _buildMediaSection() => SliverPadding(
    padding: const EdgeInsets.all(16),
    sliver: BlocBuilder<MediaBloc, MediaState>(
      builder: (context, state) {
        if (state is MediaLoading) {
          return SliverToBoxAdapter(child: ShimmerGridLoading());
        }
        if (state is MediaError) {
          return SliverToBoxAdapter(child: _buildErrorWidget(state.message));
        }
        if (state is MediaLoaded) {
          if (state.media.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No media available'),
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
              (context, index) => MediaThumbnail(
                media: state.media[index],
                onTap: () => _showMediaPreview(context, state.media[index]),
              ),
              childCount: state.media.length,
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    ),
  );

  Widget _buildErrorWidget(String message) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 14),
      ),
    );
  }

  void _showPerformanceInfo(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Performance Trend Info'),
            content: const Text(
              'This chart shows the player\'s rating trend over the last year. The orange line indicates a benchmark rating of 7.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
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
            title: Text(media.title ?? 'Media Preview'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (media.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: media.thumbnailUrl!,
                    height: 200,
                    fit: BoxFit.cover,
                    errorWidget:
                        (context, url, error) => const Icon(Icons.error),
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
                          const SnackBar(content: Text('Cannot launch URL')),
                        );
                      }
                    },
                    child: Text(
                      media.url!,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
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
        builder:
            (context, isExpanded, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade100,
                    Colors.deepPurple.shade50,
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
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
                    children: [
                      Text(
                        'Attributes Radar',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.deepPurple.shade600,
                      ),
                    ],
                  ),
                  if (isExpanded)
                    SizedBox(
                      height: 250,
                      child: RadarChart(
                        RadarChartData(
                          radarBackgroundColor: Colors.transparent,
                          radarBorderData: BorderSide(
                            color: Colors.deepPurple.shade300,
                          ),
                          gridBorderData: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                          titleTextStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                          tickCount: 5,
                          ticksTextStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                          dataSets: [
                            RadarDataSet(
                              fillColor: Colors.deepPurple.withOpacity(0.15),
                              borderColor: Colors.deepPurple,
                              borderWidth: 2,
                              entryRadius: 2,
                              dataEntries:
                                  data
                                      .map((value) => RadarEntry(value: value))
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
                ],
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
    return Container(
      margin: const EdgeInsets.only(left: 24),
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade300, width: 2)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.deepPurple.shade100,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.swap_horiz, color: Colors.deepPurple),
        ),
        title: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: transfer.fromTeam?.name ?? 'Unknown Team',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const TextSpan(text: ' → '),
              TextSpan(
                text: transfer.toTeam?.name ?? 'Unknown Team',
                style: TextStyle(
                  color: Colors.deepPurple.shade800,
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
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (transfer.fee != null)
              Chip(
                label: Text(
                  '${NumberFormat.compactCurrency(symbol: transfer.currency ?? '').format(transfer.fee)}',
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.deepPurple.shade50,
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

  const StatItem(this.icon, this.title, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.deepPurple.shade50,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.deepPurple.shade600),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.labelSmall),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple.shade800,
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
          children: [
            CachedNetworkImage(
              imageUrl: media.thumbnailUrl ?? '',
              fit: BoxFit.cover,
              errorWidget:
                  (_, __, ___) => Container(color: Colors.grey.shade200),
            ),
            Center(
              child: Icon(
                Icons.play_circle_filled,
                size: 40,
                color: Colors.white.withOpacity(0.8),
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
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
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
      children: List.generate(
        6,
        (index) =>
            ShimmerLoading(width: double.infinity, height: double.infinity),
      ),
    );
  }
}
