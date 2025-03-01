import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'country_flag_widget.dart';

class LeaguesAndMatchesByCountryWidget extends StatefulWidget {
  final String countryName;
  final String countryFlag;
  final List<String> leagues;

  const LeaguesAndMatchesByCountryWidget({
    super.key,
    required this.countryName,
    required this.countryFlag,
    required this.leagues,
  });

  @override
  State<LeaguesAndMatchesByCountryWidget> createState() =>
      _LeaguesAndMatchesByCountryWidgetState();
}

class _LeaguesAndMatchesByCountryWidgetState
    extends State<LeaguesAndMatchesByCountryWidget> {
  bool _isExpanded = false; // Track expansion state

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Collapsed/Expanded Header
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded; // Toggle expansion
            });
          },
          child: Container(
            height: 115.h, // Fixed height
            padding: EdgeInsets.symmetric(
              vertical: 10.h,
              horizontal: 25.w,
            ), // Tighter padding
            decoration: BoxDecoration(
              color: const Color(0xff161d1f),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
                bottomLeft:
                    _isExpanded
                        ? Radius.zero
                        : Radius.circular(12.r), // Rounded bottom corners
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
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  // Toggle icon
                  color: Color(0xffececee),
                  size: 80.sp, // Small icon
                ),
              ],
            ),
          ),
        ),
        // Animated Expansion for Leagues
        AnimatedContainer(
          duration: const Duration(milliseconds: 500), // Smooth animation
          curve: Curves.easeInOut, // Animation curve
          child:
              _isExpanded
                  ? Container(
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
                      itemCount: widget.leagues.length,
                      itemBuilder: (context, index) {
                        return Container(
                          height: 100.h, // Fixed height per league
                          padding: EdgeInsets.symmetric(
                            vertical: 2.h,
                            horizontal: 10.w,
                          ), // Tighter padding
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: ReusableText(
                                  text: widget.leagues[index],
                                  textSize: 100.sp, // Compact text size
                                  textFontWeight: FontWeight.w400,
                                  textColor: const Color(0xffececee),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                  : null, // No child when collapsed
        ),
      ],
    );
  }
}
