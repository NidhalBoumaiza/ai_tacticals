import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

class Test4 extends StatelessWidget {
  const Test4({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffffffc2),
      body: Center(
        child: Lottie.asset(
          'assets/lottie/AnimationConstruction.json',
          width: 1200.w,
          height: 800.h,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
