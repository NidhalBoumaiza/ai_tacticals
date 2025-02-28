import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'country_flag_widget.dart';

class LeaguesAndMatchesByCountryWidget extends StatelessWidget {
  const LeaguesAndMatchesByCountryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xff161d1f),
        borderRadius: BorderRadius.circular(6),
      ),
      width: double.infinity,
      height: 120.h,
      child: Padding(
        padding: EdgeInsets.fromLTRB(40.w, 0, 0, 20.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CountryFlagWidget(),
            SizedBox(width: 50.w),
            ReusableText(
              text: "Spain",
              textSize: 110.sp,
              textFontWeight: FontWeight.w400,
              textColor: Color(0xffececee),
            ),
            SizedBox(width: 600.w),
            ReusableText(
              text: "5",
              textSize: 100.sp,
              textFontWeight: FontWeight.w700,
              textColor: Colors.black,
            ),
            SizedBox(width: 30.w),
            Icon(FontAwesomeIcons.chevronDown, color: Colors.black, size: 15),
          ],
        ),
      ),
    );
  }
}
