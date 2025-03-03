// lib/features/standings/presentation_layer/screens/standing_screen.dart
import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../domain layer/entities/standing_entity.dart';
import '../../bloc/standing bloc/standing_bloc.dart';
import '../../widgets/home page widgets/standing screen widgets/country_flag_widget.dart';
import '../../widgets/home page widgets/standing screen widgets/standing_line_widget.dart';

class StandingScreen extends StatefulWidget {
  final String leagueName;
  final int seasonId;
  final int leagueId;

  const StandingScreen({
    super.key,

    required this.leagueName,
    required this.leagueId,
    required this.seasonId,
  });

  @override
  State<StandingScreen> createState() => _StandingScreenState();
}

class _StandingScreenState extends State<StandingScreen> {
  @override
  void initState() {
    super.initState();
    print(
      'Fetching standings for leagueId: ${widget.leagueId}, seasonId: ${widget.seasonId}',
    );
    context.read<StandingBloc>().add(
      GetStanding(leagueId: widget.leagueId, seasonId: widget.seasonId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 20.h),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xff161d1f),
            borderRadius: BorderRadius.circular(55.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 30.w),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(width: 10.w),
                    CountryFlagWidget(flag: widget.leagueId.toString()),
                    SizedBox(width: 50.w),
                    BlocBuilder<StandingBloc, StandingsState>(
                      builder: (context, state) {
                        if (state is StandingsSuccess) {
                          return ReusableText(
                            text:
                                state.standings.league?.name ??
                                widget.leagueName,
                            textSize: 130.sp,
                            textColor: Colors.white,
                            textFontWeight: FontWeight.w800,
                          );
                        }
                        return ReusableText(
                          text: widget.leagueName,
                          textSize: 130.sp,
                          textColor: Colors.white,
                          textFontWeight: FontWeight.w600,
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 50.h),
                BlocBuilder<StandingBloc, StandingsState>(
                  builder: (context, state) {
                    print('Current state: $state');
                    if (state is StandingsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is StandingsSuccess) {
                      print('Groups count: ${state.standings.groups.length}');
                      if (state.standings.groups.isEmpty) {
                        return Center(
                          child: ReusableText(
                            text: 'No standings data available for this season',
                            textSize: 100.sp,
                            textColor: Colors.white,
                            textFontWeight: FontWeight.w600,
                          ),
                        );
                      }

                      final isGroupBased = state.standings.groups.any(
                        (g) => g.isGroup == true,
                      );
                      print('Is group-based: $isGroupBased');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Total standings (no groups)
                          if (!isGroupBased &&
                              state.standings.groups.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ReusableText(
                                  text:
                                      state.standings.groups[0].name ??
                                      'Total Standings',
                                  textSize: 110.sp,
                                  textColor: Colors.white,
                                  textFontWeight: FontWeight.w600,
                                ),
                                SizedBox(height: 10.h),
                                _buildStandingsTable(state.standings.groups[0]),
                              ],
                            )
                          // Multi-group standings
                          else if (isGroupBased)
                            ...state.standings.groups.map((group) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (group.name != null ||
                                      group.groupName != null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 10.h),
                                      child: ReusableText(
                                        text:
                                            group.name ??
                                            group.groupName ??
                                            "Unnamed Group",
                                        textSize: 110.sp,
                                        textColor: Colors.white,
                                        textFontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  SizedBox(height: 10.h),
                                  _buildStandingsTable(group),
                                ],
                              );
                            }).toList(),
                        ],
                      );
                    } else if (state is StandingsError) {
                      print('Error: ${state.message}');
                      return Center(
                        child: ReusableText(
                          text: state.message,
                          textSize: 100.sp,
                          textColor: Colors.red,
                          textFontWeight: FontWeight.w600,
                        ),
                      );
                    }
                    return Center(
                      child: ReusableText(
                        text: 'No data available',
                        textSize: 100.sp,
                        textColor: Colors.white,
                        textFontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandingsTable(GroupEntity group) {
    print(
      'Building table for group: ${group.name ?? group.groupName}, Rows: ${group.rows.length}',
    );

    // State to toggle tieBreakingRuleText visibility
    bool _isExpanded = false;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        // Count lines in tieBreakingRuleText (approximate by splitting on newlines)
        final tieBreakingLines =
            group.tieBreakingRuleText != null
                ? group.tieBreakingRuleText!.split('\n').length
                : 0;
        final showToggleButton = tieBreakingLines > 4;

        return Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 50.w,
                  child: ReusableText(
                    text: "#",
                    textSize: 100.sp,
                    textColor: const Color(0xff8a8e90),
                    textFontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 25.w),
                SizedBox(
                  width: 510.w,
                  child: ReusableText(
                    text: "Team",
                    textSize: 100.sp,
                    textColor: const Color(0xff8a8e90),
                    textFontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  width: 150.w,
                  child: ReusableText(
                    text: "P",
                    textSize: 100.sp,
                    textColor: const Color(0xff8a8e90),
                    textFontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  width: 150.w,
                  child: ReusableText(
                    text: "DIFF",
                    textSize: 100.sp,
                    textColor: const Color(0xff8a8e90),
                    textFontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  width: 80.w,
                  child: ReusableText(
                    text: "PTS",
                    textSize: 100.sp,
                    textColor: const Color(0xff8a8e90),
                    textFontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: group.rows.length,
              itemBuilder: (context, index) {
                final team = group.rows[index];
                print(
                  'Team: ${team.shortName}, ID: ${team.id}, Position: ${team.position}',
                );
                final hasPromotion = team.promotion?.text != null;
                final positionColor =
                    hasPromotion
                        ? (team.promotion!.text == "Relegation" ||
                                team.promotion!.text == "Relegation Playoffs"
                            ? const Color(0xffef5056)
                            : team.promotion!.text == 'UEFA Europa League'
                            ? const Color(0xff278eea)
                            : team.promotion!.text == 'Playoffs' ||
                                team.promotion!.text == 'Champions League' ||
                                team.promotion!.text == 'Promotion' ||
                                team.promotion!.text == 'Promotion round' ||
                                team.promotion!.text == 'Promotion playoffs'
                            ? const Color(0xff38b752) // Green for Playoffs
                            : const Color(
                              0xff80ec7b,
                            )) // Lighter green for Qualification Playoffs
                        : const Color(0xff161d1f); // Default grey

                return StandingLineWidget(
                  position: team.position ?? 0,
                  positionColor: positionColor,
                  teamId: team.id ?? 0,
                  teamName: team.shortName ?? 'Unknown',
                  played: team.matches ?? 0,
                  difference:
                      team.scoreDiffFormatted != null
                          ? int.tryParse(
                                team.scoreDiffFormatted!.replaceAll('+', ''),
                              ) ??
                              0
                          : 0,
                  points: team.points ?? 0,
                );
              },
            ),
            SizedBox(height: 20.h),
            const Divider(),
            if (group.rows.any((team) => team.promotion?.text == 'Playoffs'))
              Padding(
                padding: EdgeInsets.only(left: 40.w, top: 15.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      height: 20.w,
                      width: 20.w,
                      decoration: BoxDecoration(
                        color: const Color(0xff38b752),
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                    ),
                    ReusableText(
                      textSize: 90.sp,
                      text: '    Playoffs',
                      textColor: const Color(0xff8a8e90),
                    ),
                  ],
                ),
              ),
            if (group.rows.any(
              (team) => team.promotion?.text == 'Qualification Playoffs',
            ))
              Padding(
                padding: EdgeInsets.only(left: 40.w, top: 15.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      height: 20.w,
                      width: 20.w,
                      decoration: BoxDecoration(
                        color: const Color(0xff80ec7b),
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                    ),
                    ReusableText(
                      textSize: 90.sp,
                      text: '    Qualification playoffs',
                      textColor: const Color(0xff8a8e90),
                    ),
                  ],
                ),
              ),
            if (group.tieBreakingRuleText != null)
              Padding(
                padding: EdgeInsets.only(top: 15.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReusableText(
                      text:
                          _isExpanded || !showToggleButton
                              ? group.tieBreakingRuleText!
                              : group.tieBreakingRuleText!
                                  .split('\n')
                                  .take(3)
                                  .join('\n'),
                      textSize: 90.sp,
                      textColor: Colors.white,
                    ),
                    if (showToggleButton)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: ReusableText(
                          text: _isExpanded ? 'Show Less' : 'Show More',
                          textSize: 90.sp,
                          textColor: const Color(
                            0xff38b752,
                          ), // Green for button
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
