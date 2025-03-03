// lib/features/standings/presentation_layer/screens/standing_screen.dart
import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../bloc/standing bloc/standing_bloc.dart';
import '../../widgets/home page widgets/standing screen widgets/standing_line_widget.dart';

class StandingScreen extends StatefulWidget {
  final int seasonId;

  final int leagueId;

  const StandingScreen({
    super.key,
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
                    const Icon(Icons.access_alarm),
                    SizedBox(width: 50.w),
                    ReusableText(
                      text: "UEFA Champions League",
                      // Fixed typo: "Champios" -> "Champions"
                      textSize: 130.sp,
                      textColor: Colors.white,
                      textFontWeight: FontWeight.w800,
                    ),
                  ],
                ),
                SizedBox(height: 50.h),
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
                BlocBuilder<StandingBloc, StandingsState>(
                  builder: (context, state) {
                    if (state is StandingsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is StandingsSuccess) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: state.standings.rows.length,
                              itemBuilder: (context, index) {
                                final team = state.standings.rows[index];
                                print(team.id);
                                return StandingLineWidget(
                                  position: team.position,
                                  teamId: team.id,
                                  // Local asset
                                  teamName: team.shortName,
                                  played: team.matches,
                                  difference: int.parse(
                                    team.scoreDiffFormatted.replaceAll('+', ''),
                                  ),
                                  points: team.points,
                                );
                              },
                            ),
                          ),
                          Divider(),
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
                                  textColor: Color(0xff8a8e90),
                                ),
                              ],
                            ),
                          ),
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
                                  textColor: Color(0xff8a8e90),
                                ),
                              ],
                            ),
                          ),
                          ReusableText(
                            text: state.standings.tieBreakingRuleText,
                            textSize: 90.sp,
                          ),
                        ],
                      );
                    } else if (state is StandingsError) {
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
}
