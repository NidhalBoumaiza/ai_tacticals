import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    context.read<MatchDetailsBloc>().add(
      GetMatchDetailsEvent(matchId: widget.matchId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchDetailsBloc, MatchDetailsState>(
      builder: (context, state) {
        if (state is MatchDetailsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF3D07E)),
          );
        } else if (state is MatchDetailsLoaded) {
          return MatchDetailsContent(matchDetails: state.matchDetails);
        } else if (state is MatchDetailsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/images/Empty.png"),
                ReusableText(
                  text: "No Data Found For This ",
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
                  text: 'Match Statistics',
                  textSize: 150.sp,
                  textFontWeight: FontWeight.w900,
                  textColor: Color(0xFFF3D07E),
                ),

                const SizedBox(height: 12),
                ...matchDetails.statistics
                    .where(
                      (stat) => stat.period == 'ALL',
                    ) // Show only overall stats for simplicity
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
                  text: 'Match Information',
                  textSize: 150.sp,
                  textFontWeight: FontWeight.w900,
                  textColor: Color(0xFFF3D07E),
                ),

                const SizedBox(height: 12),
                _buildInfoRow(
                  'Tournament',
                  matchDetails.tournamentName,
                  Icons.emoji_events,
                ),
                _buildInfoRow(
                  'Venue',
                  matchDetails.venueName,
                  Icons.location_on,
                ),
                _buildInfoRow(
                  'Referee',
                  matchDetails.refereeName,
                  Icons.person,
                ),
                _buildInfoRow(
                  'Date',
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
          Icon(icon, color: Color(0xFFF1D778), size: 20),
          const SizedBox(width: 8),
          ReusableText(
            text: '$label: ',
            textSize: 110.sp,
            textFontWeight: FontWeight.w900,
            textColor: Color(0xFFF3D07E),
          ),

          Expanded(
            child: ReusableText(
              text: value,
              textSize: 110.sp,
              textFontWeight: FontWeight.w900,
              textColor: Color(0xFFF3D07E),
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
              textColor: Color(0xFFF3D07E),
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
            // Text(
            //   item.homeValue,
            //   style: TextStyle(
            //     color:
            //         item.compareCode == 1
            //             ? const Color(0xFFF3D07E)
            //             : Colors.white,
            //     fontSize: 16,
            //   ),
            // ),
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
            // Text(
            //   item.name,
            //   style: const TextStyle(color: Colors.white, fontSize: 16),
            //   textAlign: TextAlign.center,
            // ),
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
            // Text(
            //   item.awayValue,
            //   style: TextStyle(
            //     color:
            //         item.compareCode == 2
            //             ? const Color(0xFFF3D07E)
            //             : Colors.white,
            //     fontSize: 16,
            //   ),
            //   textAlign: TextAlign.right,
            // ),
          ),
        ],
      ),
    );
  }
}
