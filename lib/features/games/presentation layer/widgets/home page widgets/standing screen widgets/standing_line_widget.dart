import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../../core/widgets/reusable_text.dart';

class StandingLineWidget extends StatelessWidget {
  final int position;

  final String teamName;
  final int played;
  final int difference;
  final int points;
  final int teamId;

  const StandingLineWidget({
    super.key,
    required this.teamId,
    required this.position,

    required this.teamName,
    required this.played,
    required this.difference,
    required this.points,
  });

  Color chooseColor(position) {
    if (position >= 1 && position <= 8) {
      return Color(0xff38b752);
    } else if (position >= 9 && position <= 24) {
      return Color(0xff7eeb76);
    } else {
      return Color(0xff8a8e90);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 40.h, top: 0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: chooseColor(position),
              borderRadius: BorderRadius.circular(100.r),
            ),
            width: 50.w,
            height: 50.w,
            child: Center(
              child: ReusableText(
                text: position.toString(),
                textSize: 100.sp,
                textColor: Colors.black,
                textFontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 25.w),
          // IMAGE CLUB
          CachedNetworkImage(
            imageUrl:
                "https://img.sofascore.com/api/v1/team/$teamId/image/small",
            placeholder:
                (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: 25,
                    height: 25,
                    color: Colors.grey.shade300,
                  ),
                ),
            errorWidget: (context, url, error) {
              print(
                'Error loading image: $error',
              ); // Debugging: Print the error
              return Icon(Icons.error);
            },
            fit: BoxFit.cover,
            width: 25,

            cacheKey: teamId.toString(),
            height: 25, // Increase height for better visibility
          ),
          SizedBox(
            width: 440.w,
            child: ReusableText(
              text: "  $teamName",
              textSize: 100.sp,
              textColor: Color(0xffe9ebef),
              textFontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            width: 150.w,
            child: ReusableText(
              text: "8",
              textSize: 100.sp,
              textColor: Color(0xffe9ebef),
              textFontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            width: 150.w,
            child: ReusableText(
              text:
                  difference > 0
                      ? "+${difference.toString()}"
                      : difference.toString(),
              textSize: 100.sp,
              textColor: Color(0xffe9ebef),
              textFontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            width: 80.w,
            child: ReusableText(
              text: points.toString(),
              textSize: 100.sp,
              textColor: Color(0xffe9ebef),
              textFontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
