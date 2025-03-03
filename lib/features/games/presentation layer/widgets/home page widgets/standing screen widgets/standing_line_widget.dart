// lib/features/standings/presentation_layer/widgets/standing_line_widget.dart
import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class StandingLineWidget extends StatelessWidget {
  final int position;
  final Color positionColor; // New parameter for position color
  final int teamId;
  final String teamName;
  final int played;
  final int difference;
  final int points;

  const StandingLineWidget({
    super.key,
    required this.position,
    required this.positionColor,
    required this.teamId,
    required this.teamName,
    required this.played,
    required this.difference,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 30.h),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: positionColor,
              shape: BoxShape.circle,
            ),
            width: 50.w,
            child: Center(
              child: ReusableText(
                text: position.toString(),
                textSize: 90.sp,
                textColor: Color(0xffe7eaec), // Use dynamic color
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
                    width: 25.w,
                    height: 25.w,
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
              textColor: Colors.white,
              textFontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(
            width: 150.w,
            child: ReusableText(
              text: played.toString(),
              textSize: 100.sp,
              textColor: Colors.white,
              textFontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(
            width: 150.w,
            child: ReusableText(
              text: difference.toString(),
              textSize: 100.sp,
              textColor: Colors.white,
              textFontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(
            width: 80.w,
            child: ReusableText(
              text: points.toString(),
              textSize: 100.sp,
              textColor: Colors.white,
              textFontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
