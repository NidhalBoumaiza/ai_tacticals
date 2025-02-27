import 'package:analysis_ai/core/app_colors.dart';
import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../widgets/home page widgets/league_and_matches_by_country_widget.dart';

class Test1 extends StatefulWidget {
  const Test1({super.key});

  @override
  State<Test1> createState() => _Test1State();
}

class _Test1State extends State<Test1> {
  bool isOn = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(120.h),
          child: Container(
            height: 120.h,
            decoration: BoxDecoration(color: Colors.grey.shade900),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 35.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(FontAwesomeIcons.bars, size: 60.sp, color: Colors.white),
                  SizedBox(width: 615.w),
                  SizedBox(
                    width: 120.w, // Adjusted for better fit
                    height: 45.h,
                    child: AnimatedToggleSwitch<bool>.dual(
                      current: isOn,
                      first: false,
                      // "Off" state
                      second: true,
                      // "On" state
                      spacing: 10.w,
                      // Reasonable spacing
                      height: 40.h,
                      // Matches SizedBox height
                      borderWidth: 1.0,
                      style: ToggleStyle(
                        backgroundColor: AppColor.primaryColor,
                        indicatorColor: Colors.white,
                        borderColor: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        indicatorBorderRadius: BorderRadius.circular(100.r),
                      ),
                      styleBuilder:
                          (value) => ToggleStyle(
                            indicatorColor:
                                value ? Colors.red : Colors.grey.shade400,
                          ),
                      textBuilder:
                          (value) => Center(
                            child: ReusableText(
                              text: value ? "Live" : "Off",
                              textSize: 16.sp, // Reasonable text size
                              textColor: value ? Colors.red : Colors.white,
                              textFontWeight: FontWeight.w800,
                            ),
                          ),
                      onChanged: (newValue) {
                        setState(() => isOn = newValue);
                        return Future.delayed(
                          Duration(milliseconds: 300),
                        ); // Smooth transition
                      },
                    ),
                  ),
                  SizedBox(width: 35.w),
                  Icon(
                    FontAwesomeIcons.calendar,
                    size: 50.sp,
                    color: Colors.white,
                  ),
                  SizedBox(width: 65.w),
                  Icon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 50.sp,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Color(0xffffffc2), // Light yellow-ish background
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ReusableText(
                text: "Categories",
                textSize: 120.sp,
                textFontWeight: FontWeight.w700,
                textColor: Colors.black,
              ),
              Expanded(
                child: ListView.separated(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: 20,
                  itemBuilder: (context, index) {
                    return LeaguesAndMatchesByCountryWidget();
                  },
                  separatorBuilder: (BuildContext context, int index) {
                    return SizedBox(height: 12.h);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
