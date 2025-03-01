import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/year_drop_down_menu.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  final List<Map<String, dynamic>> standings = [
    // Your standings data here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 4,
        child: NestedScrollView(
          headerSliverBuilder: (context, value) {
            return [
              SliverAppBar(
                pinned: true,
                // Keep the app bar pinned at the top
                floating: false,
                // Disable floating behavior
                snap: false,
                // Disable snap effect
                expandedHeight: 360.h,
                // Height of the expanded app bar
                backgroundColor: Colors.red,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 50.sp, // Much larger back arrow
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: Colors.red,
                    padding: EdgeInsets.only(left: 0, top: 70.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(width: 120.w), // Increased spacing
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ReusableText(
                                      text: "UEFA Champions League",
                                      textSize: 120.sp, // Much larger text
                                      textFontWeight: FontWeight.w600,
                                      textColor: Colors.white,
                                    ),
                                    YearDropdownMenu(),
                                    SizedBox(height: 50.h), // Increased spacing
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(0),
                  child: TabBar(
                    isScrollable: true,
                    indicatorPadding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.symmetric(horizontal: 40.w),
                    tabs: [
                      Tab(
                        child: ReusableText(
                          text: 'Standings',
                          textSize: 120.sp, // Much larger text
                          textFontWeight: FontWeight.w600,
                          textColor: Colors.white,
                        ),
                      ),
                      Tab(
                        child: ReusableText(
                          text: 'Matches',
                          textSize: 120.sp, // Much larger text
                          textFontWeight: FontWeight.w600,
                          textColor: Colors.white,
                        ),
                      ),
                      Tab(
                        child: ReusableText(
                          text: 'Top Scorers',
                          textSize: 120.sp, // Much larger text
                          textFontWeight: FontWeight.w600,
                          textColor: Colors.white,
                        ),
                      ),
                      Tab(
                        child: ReusableText(
                          text: 'Top Assists',
                          textSize: 120.sp, // Much larger text
                          textFontWeight: FontWeight.w600,
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: standings.length,
                  itemBuilder: (context, index) {
                    return _buildStandingItem(standings[index], index + 1);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandingItem(Map<String, dynamic> standing, int rank) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 40.w),
      color: Colors.black,
      child: Row(
        children: [
          Container(
            width: 60.w, // Much larger flag icon
            height: 60.w,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/flags/${standing['flag']}.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 30.w), // Increased spacing
          ReusableText(
            text: '$rank',
            textSize: 120.sp, // Much larger text
            textFontWeight: FontWeight.w400,
            textColor: Colors.green,
          ),
          SizedBox(width: 30.w), // Increased spacing
          ReusableText(
            text: standing['team'],
            textSize: 120.sp, // Much larger text
            textFontWeight: FontWeight.w400,
            textColor: Colors.white,
          ),
          Spacer(),
          ReusableText(
            text: '${standing['played']}',
            textSize: 120.sp, // Much larger text
            textFontWeight: FontWeight.w400,
            textColor: Colors.white,
          ),
          SizedBox(width: 50.w), // Increased spacing
          ReusableText(
            text: '+${standing['goalDiff']}',
            textSize: 120.sp, // Much larger text
            textFontWeight: FontWeight.w400,
            textColor: Colors.white,
          ),
          SizedBox(width: 50.w), // Increased spacing
          ReusableText(
            text: '${standing['points']}',
            textSize: 120.sp, // Much larger text
            textFontWeight: FontWeight.w400,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
