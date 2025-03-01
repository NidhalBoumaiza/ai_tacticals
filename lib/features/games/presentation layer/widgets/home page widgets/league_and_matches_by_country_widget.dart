import 'package:analysis_ai/core/utils/navigation_with_transition.dart';
import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:analysis_ai/features/games/presentation layer/bloc/leagues_bloc/leagues_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../pages/standing_screen.dart';
import 'country_flag_widget.dart';

class LeaguesAndMatchesByCountryWidget extends StatefulWidget {
  final String countryName;
  final String countryFlag;
  final int countryId; // Added to fetch leagues dynamically

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
  bool _isExpanded = false; // Track expansion state

  @override
  void initState() {
    super.initState();
    // No initial fetch; fetch only when expanded
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _isExpanded = false; // Reset expansion state
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Collapsed/Expanded Header
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded; // Toggle expansion
              if (_isExpanded) {
                context.read<LeaguesBloc>().add(
                  GetLeaguesByCountry(countryId: widget.countryId),
                );
              }
            });
          },
          child: Container(
            height: 115.h,
            // Fixed height
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 25.w),
            // Tighter padding
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
                // Show loading indicator or arrow based on LeaguesBloc state
                BlocBuilder<LeaguesBloc, LeaguesState>(
                  builder: (context, state) {
                    if (state is LeaguesLoading && _isExpanded) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 35.sp, // Match icon size
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
                      // Toggle icon
                      color: const Color(0xffececee),
                      size: 80.sp, // Small icon
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Animated Expansion for Leagues (Dynamic Height)
        BlocBuilder<LeaguesBloc, LeaguesState>(
          builder: (context, state) {
            if (state is LeaguesLoading && _isExpanded) {
              return const SizedBox.shrink(); // Hide content while loading (optional, can show a placeholder)
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
                duration: const Duration(milliseconds: 500), // Smooth animation
                curve: Curves.easeInOut, // Animation curve
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
                      return GestureDetector(
                        onTap: () {
                          navigateToAnotherScreenWithBottomToTopTransition(
                            context,
                            StandingsScreen(),
                          );
                        },
                        child: Container(
                          height: 105.h, // Fixed height per league
                          padding: EdgeInsets.symmetric(
                            vertical: 2.h,
                            horizontal: 30.w,
                          ), // Tighter padding
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(width: 10.w),
                              CountryFlagWidget(
                                flag: state.leagues[index].id.toString(),
                              ),
                              SizedBox(width: 30.w),
                              Expanded(
                                child: ReusableText(
                                  text: state.leagues[index].name,
                                  textSize: 100.sp, // Compact text size
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
            return const SizedBox.shrink(); // No content when collapsed or not loaded
          },
        ),
      ],
    );
  }
}
