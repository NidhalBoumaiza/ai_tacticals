import 'package:analysis_ai/core/widgets/my_customed_button.dart';
import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:analysis_ai/features/auth/presentation%20layer/bloc/login_bloc/login_bloc.dart';
import 'package:analysis_ai/features/auth/presentation%20layer/pages/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/utils/custom_snack_bar.dart';
import '../../../../core/utils/navigation_with_transition.dart';
import '../../../../core/widgets/reusable_text_field_widget.dart';
import '../../../games/presentation layer/pages/bottom app bar screens/home_screen_squelette.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late bool obscureText = true;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffffffc2),
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
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 50.h),
                        ReusableText(
                          text: "email_label".tr,
                          textSize: 100.sp,
                          textFontWeight: FontWeight.w800,
                        ),
                        ReusableTextFieldWidget(
                          borderSide: const BorderSide(
                            color: Color(0xfff3f6f9),
                            width: 3,
                            style: BorderStyle.solid,
                          ),
                          hintText: "email_hint".tr,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          errorMessage: "empty_field_error".tr,
                        ),
                        ReusableText(
                          text: "password_label".tr,
                          textSize: 100.sp,
                          textFontWeight: FontWeight.w800,
                        ),
                        ReusableTextFieldWidget(
                          obsecureText: obscureText,
                          controller: _passwordController,
                          onPressedSuffixIcon: () {
                            setState(() {
                              obscureText = !obscureText;
                            });
                          },
                          borderSide: const BorderSide(
                            color: Color(0xfff3f6f9),
                            width: 3,
                            style: BorderStyle.solid,
                          ),
                          hintText: "password_hint".tr,
                          keyboardType: TextInputType.emailAddress,
                          errorMessage: "empty_field_error".tr,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 50.h),
                  Center(
                    child: BlocConsumer<LoginBloc, LoginState>(
                      listener: (context, state) async {
                        if (state is LoginSuccess) {
                          // Set FIRST_LOGIN_DONE flag after first successful login
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('FIRST_LOGIN_DONE', true);

                          navigateToAnotherScreenWithFadeTransition(
                            context,
                            const HomeScreenSquelette(),
                          );
                        } else if (state is LoginError) {
                          showErrorSnackBar(context, "invalid_credentials".tr);
                        }
                      },
                      builder: (context, state) {
                        return MyCustomButton(
                          width: 540.w,
                          height: 150.h,
                          function: state is LoginLoading
                              ? () {}
                              : () {
                            FocusScope.of(context).unfocus();
                            if (_formKey.currentState!.validate()) {
                              context.read<LoginBloc>().add(
                                LoginWithEmailAndPassword(
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                ),
                              );
                            }
                          },
                          buttonColor: AppColor.primaryColor,
                          text: state is LoginLoading ? ''.tr : 'login_button'.tr,
                          circularRadious: 5,
                          textButtonColor: Colors.black,
                          fontSize: 40.sp,
                          fontWeight: FontWeight.w800,
                          widget: state is LoginLoading
                              ? Lottie.asset(
                            'assets/lottie/animationBallLoading.json',
                            height: 150.h,
                          )
                              : null,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 50.h),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ReusableText(
                          text: "no_account".tr,
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
                              const SignUpScreen(),
                            );
                          },
                          child: ReusableText(
                            text: "sign_up_link".tr,
                            textSize: 100.sp,
                            textFontWeight: FontWeight.w800,
                            textColor: AppColor.primaryColor,
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
      ),
    );
  }
}