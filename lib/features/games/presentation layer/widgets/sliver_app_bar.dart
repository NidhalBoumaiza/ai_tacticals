// import 'package:analysis_ai/core/widgets/reusable_text.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// import '../widgets/year_drop_down_menu.dart';
//
// class StandingsAppBar extends StatelessWidget {
//   final int initialTabIndex;
//
//   const StandingsAppBar({super.key, required this.initialTabIndex});
//
//   @override
//   Widget build(BuildContext context) {
//     return SliverAppBar(
//       pinned: true,
//       floating: false,
//       snap: false,
//       expandedHeight: 360.h,
//       backgroundColor: Colors.red,
//       leading: IconButton(
//         icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 50.sp),
//         onPressed: () => Navigator.pop(context),
//       ),
//       flexibleSpace: FlexibleSpaceBar(
//         background: Container(
//           color: Colors.red,
//           padding: EdgeInsets.only(left: 0, top: 0.h),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   SizedBox(width: 120.w),
//                   Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           ReusableText(
//                             text: "UEFA Champions League",
//                             textSize: 120.sp,
//                             textFontWeight: FontWeight.w600,
//                             textColor: Colors.white,
//                           ),
//                           YearDropdownMenu(seasons: ,),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//       bottom: PreferredSize(
//         preferredSize: Size.fromHeight(100.h),
//         child: TabBar(
//           isScrollable: true,
//           indicatorPadding: EdgeInsets.zero,
//           labelPadding: EdgeInsets.symmetric(horizontal: 40.w),
//           tabs: [
//             Tab(
//               child: ReusableText(
//                 text: 'Standings',
//                 textSize: 120.sp,
//                 textFontWeight: FontWeight.w600,
//                 textColor: Colors.white,
//               ),
//             ),
//             Tab(
//               child: ReusableText(
//                 text: 'Matches',
//                 textSize: 120.sp,
//                 textFontWeight: FontWeight.w600,
//                 textColor: Colors.white,
//               ),
//             ),
//             Tab(
//               child: ReusableText(
//                 text: 'Top Scorers',
//                 textSize: 120.sp,
//                 textFontWeight: FontWeight.w600,
//                 textColor: Colors.white,
//               ),
//             ),
//             Tab(
//               child: ReusableText(
//                 text: 'Top Assists',
//                 textSize: 120.sp,
//                 textFontWeight: FontWeight.w600,
//                 textColor: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
