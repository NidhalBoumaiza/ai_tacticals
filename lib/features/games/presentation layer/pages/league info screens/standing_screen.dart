import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/utils/navigation_with_transition.dart';
import '../../../../../core/widgets/reusable_text.dart';
import '../../../../../core/widgets/team_web_image_widget.dart';
import '../../../domain layer/entities/standing_entity.dart';
import '../../bloc/standing bloc/standing_bloc.dart';
import '../../cubit/team image loading cubit/team_image_loading_cubit.dart';
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
  late final StandingBloc _standingBloc;

  @override
  void initState() {
    super.initState();
    _standingBloc = context.read<StandingBloc>();
    _initializeData();
  }

  @override
  void didUpdateWidget(StandingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leagueId != widget.leagueId || oldWidget.seasonId != widget.seasonId) {
      _initializeData();
    }
  }

  void _initializeData() {
    if (!_standingBloc.isStandingCached(widget.leagueId, widget.seasonId)) {
      _standingBloc.add(GetStanding(leagueId: widget.leagueId, seasonId: widget.seasonId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TeamImageLoadingCubit(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 20.h),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
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
                                    text: state.standings.league?.name ?? widget.leagueName,
                                    textSize: 130.sp,
                                    textColor: Theme.of(context).textTheme.bodyLarge!.color!,
                                    textFontWeight: FontWeight.w800,
                                  );
                                }
                                return ReusableText(
                                  text: widget.leagueName,
                                  textSize: 130.sp,
                                  textColor: Theme.of(context).textTheme.bodyLarge!.color!,
                                  textFontWeight: FontWeight.w600,
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 50.h),
                        BlocBuilder<StandingBloc, StandingsState>(
                          builder: (context, state) {
                            // Pre-queue images when data is available
                            if (state is StandingsSuccess) {
                              Future.microtask(() {
                                for (var group in state.standings.groups) {
                                  for (var team in group.rows) {
                                    final url = "https://img.sofascore.com/api/v1/team/${team.id}/image/small";
                                    print('Queuing team image for ${team.shortName}: ${team.id}');
                                    context.read<TeamImageLoadingCubit>().addImageToQueue(url);
                                  }
                                }
                              });
                            }

                            if (_standingBloc.isStandingCached(widget.leagueId, widget.seasonId)) {
                              final cachedStanding = _standingBloc.getCachedStanding(widget.leagueId, widget.seasonId)!;
                              return _buildStandingsContent(cachedStanding);
                            }

                            if (state is StandingsLoading) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              );
                            } else if (state is StandingsSuccess) {
                              return _buildStandingsContent(state.standings);
                            } else if (state is StandingsError) {
                              return Center(
                                child: Image.asset("assets/images/Empty.png"),
                              );
                            }
                            return Center(
                              child: ReusableText(
                                text: 'no_data_available'.tr,
                                textSize: 100.sp,
                                textColor: Theme.of(context).textTheme.bodyLarge!.color!,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildStandingsContent(StandingsEntity standings) {
    if (standings.groups.isEmpty) {
      return Center(
        child: ReusableText(
          text: 'no_standings_data_available'.tr,
          textSize: 100.sp,
          textColor: Theme.of(context).textTheme.bodyLarge!.color!,
          textFontWeight: FontWeight.w600,
        ),
      );
    }

    final isGroupBased = standings.groups.any((g) => g.isGroup == true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isGroupBased && standings.groups.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReusableText(
                text: standings.groups[0].name ?? 'total_standings'.tr,
                textSize: 110.sp,
                textColor: Theme.of(context).textTheme.bodyLarge!.color!,
                textFontWeight: FontWeight.w600,
              ),
              SizedBox(height: 10.h),
              _buildStandingsTable(standings.groups[0]),
            ],
          )
        else if (isGroupBased)
          ...standings.groups.map((group) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (group.name != null || group.groupName != null)
                  Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: ReusableText(
                      text: group.name ?? group.groupName ?? "Unnamed Group",
                      textSize: 110.sp,
                      textColor: Theme.of(context).textTheme.bodyLarge!.color!,
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
  }

  Widget _buildStandingsTable(GroupEntity group) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        bool isExpanded = false;

        final tieBreakingLines = group.tieBreakingRuleText != null
            ? group.tieBreakingRuleText!.split(RegExp(r'\n|\r\n|\r')).where((line) => line.trim().isNotEmpty).length
            : 0;

        final showToggleButton = tieBreakingLines > 3;

        final promotionTypes = group.rows.where((team) => team.promotion?.text != null).map((team) => team.promotion!.text!).toSet().toList();

        final promotionColors = promotionTypes.map((promotion) {
          if (promotion == "Relegation" || promotion == "Relegation Playoffs") {
            return const Color(0xffef5056);
          } else if (promotion == "UEFA Europa League") {
            return const Color(0xff278eea);
          } else if (promotion == "Playoffs" ||
              promotion == "Champions League" ||
              promotion == "Promotion" ||
              promotion == "Promotion round" ||
              promotion == "Promotion playoffs") {
            return const Color(0xff38b752);
          } else {
            return const Color(0xff80ec7b);
          }
        }).toList();

        return Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 50.w,
                  child: ReusableText(
                    text: 'position_short'.tr,
                    textSize: 100.sp,
                    textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    textFontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 25.w),
                SizedBox(
                  width: 510.w,
                  child: ReusableText(
                    text: 'team'.tr,
                    textSize: 100.sp,
                    textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    textFontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  width: 150.w,
                  child: ReusableText(
                    text: 'played_short'.tr,
                    textSize: 100.sp,
                    textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    textFontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  width: 150.w,
                  child: ReusableText(
                    text: 'difference_short'.tr,
                    textSize: 100.sp,
                    textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    textFontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  width: 80.w,
                  child: ReusableText(
                    text: 'points_short'.tr,
                    textSize: 100.sp,
                    textColor: Theme.of(context).colorScheme.onSurfaceVariant,
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

                final hasPromotion = team.promotion?.text != null;
                final positionColor = hasPromotion
                    ? (team.promotion!.text == "Relegation" || team.promotion!.text == "Relegation Playoffs"
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
                    : Theme.of(context).colorScheme.surface;

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
                    difference: team.scoreDiffFormatted != null
                        ? int.tryParse(team.scoreDiffFormatted!.replaceAll('+', '')) ?? 0
                        : 0,
                    points: team.points ?? 0,
                  ),
                );
              },
            ),
            SizedBox(height: 20.h),
            Divider(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            if (group.tieBreakingRuleText != null)
              Padding(
                padding: EdgeInsets.only(top: 15.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReusableText(
                      text: isExpanded || !showToggleButton
                          ? group.tieBreakingRuleText!
                          : group.tieBreakingRuleText!.split(RegExp(r'\n|\r\n|\r')).where((line) => line.trim().isNotEmpty).take(3).join('\n'),
                      textSize: 90.sp,
                      textColor: Theme.of(context).textTheme.bodyMedium!.color!,
                    ),
                    if (showToggleButton)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        child: ReusableText(
                          text: isExpanded ? 'show_less'.tr : 'show_more'.tr,
                          textSize: 90.sp,
                          textColor: Theme.of(context).colorScheme.primary,
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
                  children: promotionTypes.asMap().entries.map((entry) {
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
                            textColor: Theme.of(context).colorScheme.onSurfaceVariant,
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