import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:analysis_ai/injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data layer/models/one_match_statics_entity.dart';
import '../../bloc/match details bloc/match_details_bloc.dart';

class OneMatchStaticsScreen extends StatefulWidget {
  final int matchId;
  final String homeTeamId;
  final String awayTeamId;
  final String homeShortName;
  final String awayShortName;

  const OneMatchStaticsScreen({
    super.key,
    required this.matchId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeShortName,
    required this.awayShortName,
  });

  @override
  State<OneMatchStaticsScreen> createState() => _OneMatchStaticsScreenState();
}

class _OneMatchStaticsScreenState extends State<OneMatchStaticsScreen> {
  late final MatchDetailsBloc matchDetailsBloc;

  @override
  void initState() {
    super.initState();
    matchDetailsBloc = di.sl<MatchDetailsBloc>();
    _initializeMatchData();
  }

  @override
  void didUpdateWidget(OneMatchStaticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId != widget.matchId) {
      _initializeMatchData();
    }
  }

  void _initializeMatchData() {
    // Check if data is already cached first
    if (matchDetailsBloc.isMatchCached(widget.matchId)) {
      final cachedMatch = matchDetailsBloc.getCachedMatch(widget.matchId);
      if (cachedMatch != null &&
          matchDetailsBloc.state is! MatchDetailsLoaded) {
        matchDetailsBloc.add(GetMatchDetailsEvent(matchId: widget.matchId));
      }
    } else {
      // Only fetch if not in cache
      matchDetailsBloc.add(GetMatchDetailsEvent(matchId: widget.matchId));
    }
  }

  @override
  void dispose() {
    // Don't close the bloc here since it's provided by dependency injection
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: matchDetailsBloc,
      child: BlocConsumer<MatchDetailsBloc, MatchDetailsState>(
        listener: (context, state) {
          if (state is MatchDetailsError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          // Always check cache first
          if (matchDetailsBloc.isMatchCached(widget.matchId)) {
            final cachedMatch =
                matchDetailsBloc.getCachedMatch(widget.matchId)!;
            return MatchDetailsContent(matchDetails: cachedMatch);
          }

          if (state is MatchDetailsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF3D07E)),
            );
          }

          if (state is MatchDetailsLoaded) {
            return MatchDetailsContent(matchDetails: state.matchDetails);
          }

          if (state is MatchDetailsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/images/Empty.png"),
                  ReusableText(
                    text: 'no_data_found'.tr,
                    textSize: 120.sp,
                    textColor: Colors.white,
                    textFontWeight: FontWeight.w900,
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class MatchDetailsContent extends StatelessWidget {
  final MatchDetails matchDetails;

  const MatchDetailsContent({super.key, required this.matchDetails});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          // Statistics
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReusableText(
                  text: 'match_statistics'.tr,
                  textSize: 150.sp,
                  textFontWeight: FontWeight.w900,
                  textColor: const Color(0xFFF3D07E),
                ),
                const SizedBox(height: 12),
                ...matchDetails.statistics
                    .where((stat) => stat.period == 'ALL')
                    .expand((stat) => stat.groups)
                    .map((group) => _buildStatsGroup(group)),
              ],
            ),
          ),
          // Match Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReusableText(
                  text: 'match_information'.tr,
                  textSize: 150.sp,
                  textFontWeight: FontWeight.w900,
                  textColor: const Color(0xFFF3D07E),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'tournament'.tr,
                  matchDetails.tournamentName,
                  Icons.emoji_events,
                ),
                _buildInfoRow(
                  'venue'.tr,
                  matchDetails.venueName,
                  Icons.location_on,
                ),
                _buildInfoRow(
                  'referee'.tr,
                  matchDetails.refereeName,
                  Icons.person,
                ),
                _buildInfoRow(
                  'date'.tr,
                  DateFormat(
                    'dd MMM yyyy, HH:mm',
                  ).format(matchDetails.startTime),
                  Icons.calendar_today,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF1D778), size: 20),
          const SizedBox(width: 8),
          ReusableText(
            text: '$label: ',
            textSize: 110.sp,
            textFontWeight: FontWeight.w900,
            textColor: const Color(0xFFF3D07E),
          ),
          Expanded(
            child: ReusableText(
              text: value,
              textSize: 110.sp,
              textFontWeight: FontWeight.w900,
              textColor: const Color(0xFFF3D07E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGroup(StatisticsGroup group) {
    return Card(
      color: const Color(0xFF33353B).withOpacity(0.9),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFF3D07E), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReusableText(
              text: group.groupName,
              textSize: 125.sp,
              textFontWeight: FontWeight.w900,
              textColor: const Color(0xFFF3D07E),
            ),
            const SizedBox(height: 12),
            ...group.items.map((item) => _buildStatsItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsItem(StatisticsItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ReusableText(
              text: item.homeValue,
              textSize: 110.sp,
              textFontWeight: FontWeight.w900,
              textColor:
                  item.compareCode == 1
                      ? const Color(0xFFF3D07E)
                      : Colors.white,
            ),
          ),
          Expanded(
            flex: 3,
            child: ReusableText(
              text: item.name,
              textSize: 110.sp,
              textFontWeight: FontWeight.w900,
              textColor: Colors.white,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: ReusableText(
              text: item.awayValue,
              textSize: 110.sp,
              textFontWeight: FontWeight.w900,
              textColor:
                  item.compareCode == 2
                      ? const Color(0xFFF3D07E)
                      : Colors.white,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
