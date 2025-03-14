import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:analysis_ai/features/games/presentation%20layer/bloc/countries_bloc/countries_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/cubit/theme cubit/theme_cubit.dart';
import '../../../../auth/presentation%20layer/pages/login_screen.dart';
import '../../widgets/home%20page%20widgets/standing%20screen%20widgets/league_and_matches_by_country_widget.dart';

class LeagueScreen extends StatefulWidget {
  const LeagueScreen({super.key});

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CountriesBloc>().add(GetAllCountries());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        // Uses primaryColor (0xFFfbc02d)
        elevation: 0,
        toolbarHeight: 120.h,
        leadingWidth: 80.w,
        leading: IconButton(
          icon: Icon(
            FontAwesomeIcons.rightFromBracket,
            size: 60.sp,
            color:
                Theme.of(
                  context,
                ).appBarTheme.foregroundColor, // Black in both themes
          ),
          onPressed: () async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.remove('TOKEN');
            PersistentNavBarNavigator.pushNewScreen(
              context,
              screen: const LoginScreen(),
              withNavBar: false,
              pageTransitionAnimation: PageTransitionAnimation.slideRight,
            );
          },
        ),
        title: ReusableText(
          text: 'leagues'.tr, // Translated title
          textSize: 130.sp,
          textFontWeight: FontWeight.w900,
          textColor: Theme.of(context).appBarTheme.foregroundColor,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.brightness_6,
              size: 60.sp,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
        ],
      ),
      backgroundColor:
          Theme.of(
            context,
          ).scaffoldBackgroundColor, // Light: grey[50], Dark: 0xFF37383c
      body: BlocConsumer<CountriesBloc, CountriesState>(
        listener: (context, state) {
          if (state is CountriesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: ReusableText(
                  text: state.message.tr,
                  textSize: 90.sp,
                  textColor: Theme.of(context).colorScheme.onSurface,
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CountriesLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary, // 0xFFfbc02d
              ),
            );
          } else if (state is CountriesSuccess) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(30.w, 150.h, 30.w, 60.h),
                // Adjusted top padding for app bar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReusableText(
                      text: "categories".tr,
                      textSize: 120.sp,
                      textFontWeight: FontWeight.w700,
                      textColor:
                          Theme.of(context)
                              .colorScheme
                              .onSurface, // Dark gray (light) or white (dark)
                    ),
                    SizedBox(height: 25.h),
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: state.countries.length,
                      itemBuilder: (context, index) {
                        final country = state.countries[index];
                        return LeaguesAndMatchesByCountryWidget(
                          countryName: country.name,
                          countryFlag: country.alpha2 ?? country.flag,
                          countryId: country.id,
                        );
                      },
                      separatorBuilder:
                          (context, index) => SizedBox(height: 12.h),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is CountriesError) {
            final message = state.message;
            return Center(
              child: Padding(
                padding: EdgeInsets.all(30.w),
                child: ReusableText(
                  text:
                      message == 'offline_failure_message'.tr ||
                              message == 'No Internet connection'
                          ? 'no_internet_connection'.tr
                          : state.message.tr,
                  textSize: message.contains('internet') ? 120.sp : 100.sp,
                  textFontWeight:
                      message.contains('internet')
                          ? FontWeight.bold
                          : FontWeight.normal,
                  textColor: Theme.of(context).colorScheme.onSurface,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return Center(
            child: ReusableText(
              text: 'wait_to_load_countries'.tr,
              textSize: 100.sp,
              textColor: Theme.of(context).colorScheme.onSurface,
            ),
          );
        },
      ),
    );
  }
}
