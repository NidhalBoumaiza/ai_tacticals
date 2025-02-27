import 'package:analysis_ai/core/widgets/my_customed_button.dart';
import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:analysis_ai/features/auth/presentation%20layer/pages/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/utils/navigation_with_transition.dart';
import '../../../../core/widgets/reusable_text_field_widget.dart';
import '../../../games/presentation layer/pages/home_screen_squelette.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffffffc2),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 200.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Lottie.asset(
                    "assets/lottie/AnimationLogin.json",
                    height: 700.h,
                  ),
                ),
                Center(
                  child: ReusableText(
                    text: "login_title".tr,
                    textSize: 200.sp,
                    textFontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 50.h),
                ReusableText(
                  text: "email_label".tr,
                  textSize: 100.sp,
                  textFontWeight: FontWeight.w800,
                ),
                ReusableTextFieldWidget(
                  hintText: "email_hint".tr,
                  controller: TextEditingController(),
                  keyboardType: TextInputType.emailAddress,
                  errorMessage: "empty_field_error".tr,
                ),
                ReusableText(
                  text: "password_label".tr,
                  textSize: 100.sp,
                  textFontWeight: FontWeight.w800,
                ),
                ReusableTextFieldWidget(
                  hintText: "password_hint".tr,
                  controller: TextEditingController(),
                  keyboardType: TextInputType.emailAddress,
                  errorMessage: "empty_field_error".tr,
                ),
                SizedBox(height: 50.h),
                Center(
                  child: MyCustomButton(
                    width: 540.w,
                    // Your original value
                    height: 150.h,
                    // Your original value
                    function: () {
                      navigateToAnotherScreenWithFadeTransition(
                        context,
                        HomeScreenSquelette(),
                      );
                    },
                    buttonColor: AppColor.primaryColor,
                    text: 'login_button'.tr,
                    circularRadious: 5,
                    textButtonColor: Colors.black,
                    fontSize: 40.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 50.h),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ReusableText(
                        text: "no_account".tr, // "Don't have an account?"
                        textSize: 100.sp,
                        textFontWeight: FontWeight.w600,
                        textColor: Colors.black,
                      ),
                      SizedBox(width: 10.w),
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          navigateToAnotherScreenWithSlideTransitionFromRightToLeft(
                            context,
                            SignUpScreen(),
                          );
                        },
                        child: ReusableText(
                          text: "sign_up_link".tr, // "Sign Up"
                          textSize: 100.sp,
                          textFontWeight: FontWeight.w800,
                          textColor:
                              AppColor.primaryColor, // Highlighted as clickable
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
