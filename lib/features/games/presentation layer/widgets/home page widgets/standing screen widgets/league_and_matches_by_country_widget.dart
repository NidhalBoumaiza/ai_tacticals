// lib/features/standings/presentation_layer/widgets/leagues_and_matches_by_country_widget.dart
import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../../bloc/leagues_bloc/leagues_bloc.dart';
import '../../../cubit/seasons cubit/seasons_cubit.dart';
import '../../../pages/league_infos_screen.dart';
import 'country_flag_widget.dart';

class LeaguesAndMatchesByCountryWidget extends StatefulWidget {
  final String countryName;
  final String countryFlag;
  final int countryId;

  const LeaguesAndMatchesByCountryWidget({
    super.key,
    required this.countryName,
    required this.countryFlag,
    required this.countryId,
  });

  @override
  State<LeaguesAndMatchesByCountryWidget> createState() =>
      _LeaguesAndMatchesByCountryWidgetState();
}

class _LeaguesAndMatchesByCountryWidgetState
    extends State<LeaguesAndMatchesByCountryWidget> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _isExpanded = false;
    super.dispose();
  }

  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (_isExpanded) {
                context.read<LeaguesBloc>().add(
                  GetLeaguesByCountry(countryId: widget.countryId),
                );
              }
            });
          },
          child: Container(
            height: 115.h,
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 25.w),
            decoration: BoxDecoration(
              color: const Color(0xff161d1f),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
                bottomLeft: _isExpanded ? Radius.zero : Radius.circular(12.r),
                bottomRight: _isExpanded ? Radius.zero : Radius.circular(12.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CountryFlagWidget(flag: widget.countryFlag),
                      SizedBox(width: 70.w),
                      ReusableText(
                        text: widget.countryName,
                        textSize: 110.sp,
                        textFontWeight: FontWeight.w400,
                        textColor: const Color(0xffececee),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<LeaguesBloc, LeaguesState>(
                  builder: (context, state) {
                    if (state is LeaguesLoading && _isExpanded) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 35.sp,
                            height: 35.sp,
                            child: CircularProgressIndicator(
                              color: const Color(0xffececee),
                              strokeWidth: 2.0,
                            ),
                          ),
                          SizedBox(width: 20.w),
                        ],
                      );
                    }
                    return Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xffececee),
                      size: 80.sp,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        BlocBuilder<LeaguesBloc, LeaguesState>(
          builder: (context, state) {
            if (state is LeaguesLoading && _isExpanded) {
              return const SizedBox.shrink();
            } else if (state is LeaguesError && _isExpanded) {
              return Container(
                padding: EdgeInsets.all(8.h),
                color: const Color(0xff161d1f),
                child: Center(
                  child: Text(
                    state.message,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                ),
              );
            } else if (state is LeaguesSuccess && _isExpanded) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff161d1f),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10.r),
                      bottomRight: Radius.circular(10.r),
                    ),
                  ),
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: state.leagues.length,
                    itemBuilder: (context, index) {
                      final league = state.leagues[index];
                      return GestureDetector(
                        onTap: () {
                          context.read<SeasonsCubit>().getSeasons(league.id);
                          _showSeasonsDialog(context, league.id, league.name);
                        },
                        child: Container(
                          height: 105.h,
                          padding: EdgeInsets.symmetric(
                            vertical: 2.h,
                            horizontal: 30.w,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(width: 10.w),
                              CountryFlagWidget(flag: league.id.toString()),
                              SizedBox(width: 30.w),
                              Expanded(
                                child: ReusableText(
                                  text: league.name,
                                  textSize: 100.sp,
                                  textFontWeight: FontWeight.w400,
                                  textColor: const Color(0xffececee),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  void _showSeasonsDialog(
    BuildContext context,
    int leagueId,
    String leagueName,
  ) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocConsumer<SeasonsCubit, SeasonsState>(
            listener: (context, state) {
              if (state is SeasonsError) {
                showErrorSnackBar(context, "Error while loading seasons");
              }
            },
            builder: (context, state) {
              if (state is SeasonsLoading) {
                return AlertDialog(
                  contentPadding: EdgeInsets.all(16.h), // Reduced padding
                  content: SizedBox(
                    width: 100.w, // Small width
                    height: 100.h, // Small height
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0, // Thinner stroke for smaller size
                      ),
                    ),
                  ),
                );
              } else if (state is SeasonsLoaded) {
                print("Seasons loaded: ${state.seasons.length}");
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(dialogContext); // Close dialog
                  PersistentNavBarNavigator.pushNewScreen(
                    context,
                    screen: LeagueInfosScreen(
                      leagueId: leagueId,
                      leagueName: leagueName,
                      seasons: state.seasons,
                    ),
                    withNavBar: false,
                    pageTransitionAnimation: PageTransitionAnimation.slideRight,
                  );
                });
                return const SizedBox.shrink(); // Temporary placeholder while navigating
              } else if (state is SeasonsError) {
                return AlertDialog(content: Center(child: Text(state.message)));
              }
              return const SizedBox.shrink();
            },
          ),
    );
  }
}
