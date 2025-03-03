import 'package:analysis_ai/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/utils/navigation_with_transition.dart';
import '../../../../core/widgets/my_customed_button.dart';
import 'login_screen.dart';

class StarterScreen extends StatefulWidget {
  const StarterScreen({super.key});

  @override
  _StarterScreenState createState() => _StarterScreenState();
}

class _StarterScreenState extends State<StarterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _topToBottomAnimation; // For bayrem.png
  late Animation<Offset> _rightToLeftAnimation; // For ball.png

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // Animation duration
      vsync: this,
    )..repeat(reverse: true); // Repeat indefinitely, reversing direction

    // Animation for bayrem.png: Top to Bottom
    _topToBottomAnimation = Tween<Offset>(
      begin: Offset(0, -25.h / 1100.h), // Move 5 pixels up relative to height
      end: const Offset(0, 0), // Back to initial position
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Animation for ball.png: Right to Left
    _rightToLeftAnimation = Tween<Offset>(
      begin: Offset(25.w / 200.w, 0), // Move 5 pixels right relative to width
      end: const Offset(0, 0), // Back to initial position
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/HD.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 500.h), // Kept your original value
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the row
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SlideTransition(
                  position: _topToBottomAnimation,
                  child: Image.asset(
                    'assets/images/bayrem.png',
                    width: 700.w, // Your original value
                    height: 1100.h, // Your original value
                  ),
                ),
                SizedBox(width: 0.w), // Kept your original value
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlideTransition(
                      position: _rightToLeftAnimation,
                      child: Image.asset(
                        'assets/images/ball.png',
                        width: 200.w, // Your original value
                        height: 150.h, // Your original value
                      ),
                    ),
                    SizedBox(height: 50.h), // Kept your original value
                  ],
                ),
                SizedBox(width: 120.w),
              ],
            ),
            SizedBox(height: 400.h), // Kept your original value
            MyCustomButton(
              width: 540.w,
              // Your original value
              height: 150.h,
              // Your original value
              function: () {
                navigateToAnotherScreenWithBottomToTopTransition(
                  context,
                  LoginScreen(),
                );
              },
              buttonColor: AppColor.primaryColor,
              text: 'explore_now'.tr,
              circularRadious: 5,
              textButtonColor: Colors.black,
              fontSize: 40.sp,
              fontWeight: FontWeight.w800,
            ),
          ],
        ),
      ),
    );
  }
}
