// lib/features/standings/presentation_layer/screens/standing_screen.dart
import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/utils/navigation_with_transition.dart';
import '../../../domain layer/entities/standing_entity.dart';
import '../../bloc/standing bloc/standing_bloc.dart';
import '../../widgets/home page widgets/standing screen widgets/country_flag_widget.dart';
import '../../widgets/home page widgets/standing screen widgets/standing_line_widget.dart';
import '../team info screens/team_info_screen_squelette.dart';

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
          height:
              context.read<StandingBloc>().state is StandingsSuccess
                  ? null
                  : MediaQuery.of(context).size.height * 0.8,
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
                        child: Image.asset("assets/images/Empty.png"),
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

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        bool isExpanded = false; // Renamed to avoid shadowing

        // Count lines in tieBreakingRuleText with more robust splitting
        final tieBreakingLines =
            group.tieBreakingRuleText != null
                ? group.tieBreakingRuleText!
                    .split(RegExp(r'\n|\r\n|\r'))
                    .where((line) => line.trim().isNotEmpty)
                    .length
                : 0;
        print('Raw TieBreakingRuleText: "${group.tieBreakingRuleText}"');
        print('TieBreakingRule Lines: $tieBreakingLines');
        final showToggleButton =
            tieBreakingLines > 3; // Adjusted to match take(3)

        // Extract unique promotion types and their colors
        final promotionTypes =
            group.rows
                .where((team) => team.promotion?.text != null)
                .map((team) => team.promotion!.text!)
                .toSet()
                .toList();
        print('Unique Promotion Types: $promotionTypes');

        final promotionColors =
            promotionTypes.map((promotion) {
              if (promotion == "Relegation" ||
                  promotion == "Relegation Playoffs") {
                return const Color(0xffef5056); // Red for relegation
              } else if (promotion == "UEFA Europa League") {
                return const Color(0xff278eea); // Blue for Europa League
              } else if (promotion == "Playoffs" ||
                  promotion == "Champions League" ||
                  promotion == "Promotion" ||
                  promotion == "Promotion round" ||
                  promotion == "Promotion playoffs") {
                return const Color(0xff38b752); // Green for Playoffs/Promotion
              } else {
                return const Color(0xff80ec7b); // Lighter green for others
              }
            }).toList();

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
                            : team.promotion!.text == "UEFA Europa League"
                            ? const Color(0xff278eea)
                            : team.promotion!.text == "Playoffs" ||
                                team.promotion!.text == "Champions League" ||
                                team.promotion!.text == "Promotion" ||
                                team.promotion!.text == "Promotion round" ||
                                team.promotion!.text == "Promotion playoffs"
                            ? const Color(0xff38b752)
                            : const Color(0xff80ec7b))
                        : const Color(0xff161d1f);

                return GestureDetector(
                  onTap: () {
                    navigateToAnotherScreenWithBottomToTopTransition(
                      context,
                      TeamInfoScreenSquelette(
                        teamId: team.id!,
                        teamName: team.shortName!,
                        seasonId: widget.seasonId,
                        leagueId: widget.leagueId,
                      ),
                    );
                  },
                  child: StandingLineWidget(
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
                  ),
                );
              },
            ),
            SizedBox(height: 20.h),
            const Divider(),
            if (group.tieBreakingRuleText != null)
              Padding(
                padding: EdgeInsets.only(top: 15.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReusableText(
                      text:
                          isExpanded || !showToggleButton
                              ? group.tieBreakingRuleText!
                              : group.tieBreakingRuleText!
                                  .split(RegExp(r'\n|\r\n|\r'))
                                  .where((line) => line.trim().isNotEmpty)
                                  .take(3)
                                  .join('\n'),
                      textSize: 90.sp,
                      textColor: Colors.white,
                    ),
                    if (showToggleButton)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isExpanded = !isExpanded;
                            print('Toggle pressed, isExpanded: $isExpanded');
                          });
                        },
                        child: ReusableText(
                          text: isExpanded ? 'Show Less' : 'Show More',
                          textSize: 90.sp,
                          textColor: const Color(0xff38b752),
                        ),
                      ),
                  ],
                ),
              ),
            if (promotionTypes.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 15.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      promotionTypes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final promotion = entry.value;
                        final color = promotionColors[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 5.h),
                          child: Row(
                            children: [
                              Container(
                                height: 20.w,
                                width: 20.w,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(100.r),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              ReusableText(
                                text: promotion,
                                textSize: 90.sp,
                                textColor: const Color(0xff8a8e90),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}
