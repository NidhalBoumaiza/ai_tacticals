import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/cubit/theme cubit/theme_cubit.dart';
import '../../../../../core/widgets/reusable_text.dart';
import '../../../../../features/auth/presentation layer/pages/starter_screen.dart';
import '../../../../auth/presentation layer/pages/login_screen.dart'; // Adjust path to StarterScreen

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ReusableText(
          text: 'Profile'.tr,
          textSize: 100.sp,
          textColor: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
          textFontWeight: FontWeight.bold,
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.9),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header with Avatar
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40.r,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Icon(Icons.person, size: 50.sp, color: Colors.white),
                    ),
                    SizedBox(width: 16.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ReusableText(
                          text: 'Settings'.tr,
                          textSize: 100.sp,
                          textColor: Theme.of(context).textTheme.headlineSmall!.color!,
                          textFontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: 4.h),
                        ReusableText(
                          text: 'Customize your experience'.tr,
                          textSize: 100.sp,
                          textColor: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.7),
                          textFontWeight: FontWeight.normal,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 40.h),

                // Theme Card
                _buildSettingsCard(
                  context,
                  title: 'Theme'.tr,
                  icon: Icons.brightness_6,
                  child: _buildThemeSelector(context),
                ),
                SizedBox(height: 20.h),

                // Language Card
                _buildSettingsCard(
                  context,
                  title: 'Language'.tr,
                  icon: Icons.language,
                  child: _buildLanguageSelector(context),
                ),
                SizedBox(height: 20.h),

                // Logout Card
                _buildSettingsCard(
                  context,
                  title: 'Logout'.tr,
                  icon: Icons.exit_to_app,
                  child: _buildLogoutButton(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required String title, required IconData icon, required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 28.sp, color: Theme.of(context).primaryColor),
              SizedBox(width: 12.w),
              ReusableText(
                text: title,
                textSize: 100.sp,
                textColor: Theme.of(context).textTheme.titleLarge!.color!,
                textFontWeight: FontWeight.w600,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return DropdownButtonFormField<ThemeMode>(
      value: context.watch<ThemeCubit>().state,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey[200],
        prefixIcon: Icon(Icons.brightness_6, color: Theme.of(context).primaryColor, size: 20.sp),
      ),
      items: [
        DropdownMenuItem(
          value: ThemeMode.light,
          child: ReusableText(
            text: 'Light'.tr,
            textSize: 100.sp,
            textColor: Theme.of(context).textTheme.bodyLarge!.color!,
            textFontWeight: FontWeight.normal,
          ),
        ),
        DropdownMenuItem(
          value: ThemeMode.dark,
          child: ReusableText(
            text: 'Dark'.tr,
            textSize: 100.sp,
            textColor: Theme.of(context).textTheme.bodyLarge!.color!,
            textFontWeight: FontWeight.normal,
          ),
        ),
        DropdownMenuItem(
          value: ThemeMode.system,
          child: ReusableText(
            text: 'System'.tr,
            textSize: 100.sp,
            textColor: Theme.of(context).textTheme.bodyLarge!.color!,
            textFontWeight: FontWeight.normal,
          ),
        ),
      ],
      onChanged: (ThemeMode? newMode) {
        if (newMode != null) {
          context.read<ThemeCubit>().toggleTheme(specificMode: newMode);
        }
      },
      dropdownColor: Theme.of(context).cardColor,
      icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final List<Map<String, String>> languages = [
      {'code': 'fr_FR', 'name': 'French'},
      {'code': 'en_US', 'name': 'English'},
      {'code': 'ar_AR', 'name': 'Arabic'},
    ];

    return DropdownButtonFormField<String>(
      value: Get.locale.toString(),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey[200],
        prefixIcon: Icon(Icons.language, color: Theme.of(context).primaryColor, size: 20.sp),
      ),
      items: languages.map((lang) {
        return DropdownMenuItem(
          value: lang['code'],
          child: ReusableText(
            text: lang['name']!.tr,
            textSize: 100.sp,
            textColor: Theme.of(context).textTheme.bodyLarge!.color!,
            textFontWeight: FontWeight.normal,
          ),
        );
      }).toList(),
      onChanged: (String? newLang) async {
        if (newLang != null) {
          final localeParts = newLang.split('_');
          Get.updateLocale(Locale(localeParts[0], localeParts[1]));
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('LANGUAGE', newLang);
        }
      },
      dropdownColor: Theme.of(context).cardColor,
      icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // Clear the token from SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('TOKEN');

        // Navigate to StarterScreen and remove all previous routes
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: const LoginScreen(),
          withNavBar: false,
          pageTransitionAnimation: PageTransitionAnimation.slideRight,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent, // Red color for logout
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        elevation: 2,
      ),
      child: ReusableText(
        text: 'Logout'.tr,
        textSize: 100.sp,
        textColor: Colors.white,
        textFontWeight: FontWeight.bold,
      ),
    );
  }
}