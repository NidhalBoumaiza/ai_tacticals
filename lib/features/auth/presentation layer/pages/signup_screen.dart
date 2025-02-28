import 'package:analysis_ai/core/utils/custom_snack_bar.dart';
import 'package:analysis_ai/core/widgets/my_customed_button.dart';
import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:analysis_ai/features/auth/domain%20layer/entities/userEntity.dart';
import 'package:analysis_ai/features/auth/presentation%20layer/bloc/signup_bloc/signup_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/widgets/reusable_text_field_widget.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  late bool isObsecurePassword = true;
  late bool isObsecureConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffc2), // Matching LoginScreen
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 180.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Lottie.asset(
                    "assets/lottie/AnimationSignUp.json",
                    // Reuse or replace with a sign-up animation
                    height: 600.h,
                  ),
                ),
                Center(
                  child: ReusableText(
                    text: "sign_up_link".tr, // Using "Sign Up" as title
                    textSize: 200.sp,
                    textFontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 50.h),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReusableText(
                        text: "name_label".tr,
                        textSize: 100.sp,
                        textFontWeight: FontWeight.w800,
                      ),
                      ReusableTextFieldWidget(
                        borderSide: const BorderSide(
                          color: Color(0xfff3f6f9),
                          width: 3,
                          style: BorderStyle.solid,
                        ),
                        hintText: "name_hint".tr,
                        controller: _nameController,
                        keyboardType: TextInputType.text,
                        errorMessage: "empty_field_error".tr,
                      ),
                      SizedBox(height: 20.h),
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
                      SizedBox(height: 20.h),
                      ReusableText(
                        text: "password_label".tr,
                        textSize: 100.sp,
                        textFontWeight: FontWeight.w800,
                      ),
                      ReusableTextFieldWidget(
                        borderSide: const BorderSide(
                          color: Color(0xfff3f6f9),
                          width: 3,
                          style: BorderStyle.solid,
                        ),
                        hintText: "password_hint".tr,
                        controller: _passwordController,
                        keyboardType: TextInputType.text,
                        obsecureText: isObsecurePassword,
                        onPressedSuffixIcon: () {
                          setState(() {
                            isObsecurePassword = !isObsecurePassword;
                          });
                        },
                        // Hide password
                        errorMessage: "empty_field_error".tr,
                      ),
                      SizedBox(height: 20.h),
                      ReusableText(
                        text: "confirm_password_label".tr,
                        // New translation needed
                        textSize: 100.sp,
                        textFontWeight: FontWeight.w800,
                      ),
                      ReusableTextFieldWidget(
                        borderSide: const BorderSide(
                          color: Color(0xfff3f6f9),
                          width: 3,
                          style: BorderStyle.solid,
                        ),
                        hintText: "confirm_password_hint".tr,
                        controller: _confirmPasswordController,
                        keyboardType: TextInputType.text,
                        obsecureText: isObsecureConfirmPassword,
                        errorMessage: "empty_field_error".tr,
                        onPressedSuffixIcon: () {
                          setState(() {
                            isObsecureConfirmPassword =
                                !isObsecureConfirmPassword;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50.h),
                Center(
                  child: BlocConsumer<SignupBloc, SignupState>(
                    listener: (context, state) {
                      if (state is SignupSuccess) {
                        showSuccessSnackBar(
                          context,
                          'signup_sucess_message'.tr,
                        );
                        Future.delayed(
                          const Duration(seconds: 2),
                          () => Get.back(),
                        );
                      } else if (state is SignupError) {
                        showErrorSnackBar(context, state.message);
                      }
                    },
                    builder: (context, state) {
                      return MyCustomButton(
                        width: 540.w,
                        height: 150.h,
                        function:
                            state is SignupLoading
                                ? () {}
                                : () {
                                  if (_formKey.currentState!.validate()) {
                                    UserEntity user = UserEntity(
                                      '',
                                      _nameController.text,
                                      _emailController.text,
                                      _passwordController.text,
                                      _confirmPasswordController.text,
                                    );
                                    context.read<SignupBloc>().add(
                                      SignupEventWithAllInfos(user: user),
                                    );
                                  }
                                },
                        buttonColor: AppColor.primaryColor,
                        text: state is SignupLoading ? "" : "sign_up_link".tr,
                        widget:
                            state is SignupLoading
                                ? Lottie.asset(
                                  'assets/lottie/animationBallLoading.json',
                                  height: 150.h,
                                )
                                : null,

                        circularRadious: 5,
                        textButtonColor: Colors.black,
                        fontSize: 40.sp,
                        fontWeight: FontWeight.w800,
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
                        text: "have_account".tr,
                        // New translation: "Already have an account?"
                        textSize: 100.sp,
                        textFontWeight: FontWeight.w600,
                        textColor: Colors.black,
                      ),
                      SizedBox(width: 10.w),
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          Get.back();
                        },
                        child: ReusableText(
                          text: "login_button".tr, // "Log In" as link
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
    );
  }
}
