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
    if (matchDetailsBloc.isMatchCached(widget.matchId)) {
      final cachedMatch = matchDetailsBloc.getCachedMatch(widget.matchId);
      if (cachedMatch != null &&
          matchDetailsBloc.state is! MatchDetailsLoaded) {
        matchDetailsBloc.add(GetMatchDetailsEvent(matchId: widget.matchId));
      }
    } else {
      matchDetailsBloc.add(GetMatchDetailsEvent(matchId: widget.matchId));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: matchDetailsBloc,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: BlocConsumer<MatchDetailsBloc, MatchDetailsState>(
          listener: (context, state) {
            if (state is MatchDetailsError) {
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(
              //     content: Text(
              //       state.message,
              //       style: TextStyle(
              //         color: Theme.of(context).colorScheme.onSurface,
              //       ),
              //     ),
              //     backgroundColor: Theme.of(context).colorScheme.surface,
              //   ),
              // );
            }
          },
          builder: (context, state) {
            if (matchDetailsBloc.isMatchCached(widget.matchId)) {
              final cachedMatch =
                  matchDetailsBloc.getCachedMatch(widget.matchId)!;
              return MatchDetailsContent(matchDetails: cachedMatch);
            }

            if (state is MatchDetailsLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                      textColor: Theme.of(context).colorScheme.onSurface,
                      textFontWeight: FontWeight.w900,
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class MatchDetailsContent extends StatelessWidget {
  final MatchDetails matchDetails;

  const MatchDetailsContent({super.key, required this.matchDetails});

  @override
  Widget build(BuildContext context) {
    print (matchDetails.statistics) ;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 17.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReusableText(
                  text: 'match_statistics'.tr,
                  textSize: 150.sp,
                  textFontWeight: FontWeight.w900,
                  textColor: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: 12.h),
                matchDetails.statistics == null || matchDetails.statistics.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/images/Empty.png"),
                      ReusableText(
                        text: 'there is no statics for this match yet'.tr,
                        textSize: 120.sp,
                        textColor: Theme.of(context).colorScheme.onSurface,
                        textFontWeight: FontWeight.w900,
                      ),
                    ],
                  ),
                )
                    : Column(
                  children: matchDetails.statistics
                      .where((stat) => stat.period == 'ALL')
                      .expand((stat) => stat.groups)
                      .map((group) => _buildStatsGroup(group, context))
                      .toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReusableText(
                  text: 'match_information'.tr,
                  textSize: 150.sp,
                  textFontWeight: FontWeight.w900,
                  textColor: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: 12.h),
                _buildInfoRow(
                  context,
                  'tournament'.tr,
                  matchDetails.tournamentName,
                  Icons.emoji_events,
                ),
                _buildInfoRow(
                  context,
                  'venue'.tr,
                  matchDetails.venueName,
                  Icons.location_on,
                ),
                _buildInfoRow(
                  context,
                  'referee'.tr,
                  matchDetails.refereeName,
                  Icons.person,
                ),
                _buildInfoRow(
                  context,
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

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          SizedBox(width: 8.w),
          ReusableText(
            text: '$label: ',
            textSize: 110.sp,
            textFontWeight: FontWeight.w900,
            textColor: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: ReusableText(
              text: value,
              textSize: 110.sp,
              textFontWeight: FontWeight.w900,
              textColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGroup(StatisticsGroup group, BuildContext context) {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReusableText(
              text: group.groupName,
              textSize: 125.sp,
              textFontWeight: FontWeight.w900,
              textColor: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 12.h),
            ...group.items.map((item) => _buildStatsItem(item, context)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsItem(StatisticsItem item, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
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
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Expanded(
            flex: 3,
            child: ReusableText(
              text: item.name,
              textSize: 110.sp,
              textFontWeight: FontWeight.w900,
              textColor: Theme.of(context).colorScheme.onSurface,
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
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
