import 'package:analysis_ai/core/utils/navigation_with_transition.dart';
import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:analysis_ai/features/auth/presentation%20layer/pages/login_screen.dart';
import 'package:analysis_ai/features/games/presentation layer/bloc/countries_bloc/countries_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/home page widgets/league_and_matches_by_country_widget.dart';

class LeagueScreen extends StatefulWidget {
  const LeagueScreen({super.key});

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger fetching countries when the widget initializes
    context.read<CountriesBloc>().add(GetAllCountries());
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120.h),
        child: Container(
          height: 120.h,
          decoration: BoxDecoration(color: Colors.grey.shade900),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 35.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.remove('TOKEN');
                    navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
                      context,
                      LoginScreen(),
                    );
                  },
                  child: Icon(
                    FontAwesomeIcons.rightFromBracket,
                    size: 60.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 765.w),
                Icon(
                  FontAwesomeIcons.calendar,
                  size: 50.sp,
                  color: Colors.white,
                ),
                SizedBox(width: 65.w),
                GestureDetector(
                  onTap: () {
                    SharedPreferences.getInstance().then((prefs) {
                      final token = prefs.getString('TOKEN');
                      print(token);
                    });
                  },
                  child: Icon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 50.sp,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xff010001), // Dark background
      body: BlocConsumer<CountriesBloc, CountriesState>(
        listener: (context, state) {
          if (state is CountriesError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is CountriesLoading) {
            return Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          } else if (state is CountriesSuccess) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(30.w, 20.h, 30.w, 60.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReusableText(
                      text: "Categories",
                      textSize: 120.sp,
                      textFontWeight: FontWeight.w700,
                      textColor: const Color(0xffececee),
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
                          countryId: country.id, // Pass the country ID
                        ); // Pass country data
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return SizedBox(height: 12.h);
                      },
                    ),
                  ],
                ),
              ),
            );
          } else if (state is CountriesError) {
            final message = state.message;
            if (message == 'offline_failure_message'.tr ||
                message == 'No Internet connection') {
              return Center(
                child: Text(
                  'No Internet Connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
            );
          }
          return Center(
            child: Text(
              "Press a button or wait to load countries",
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
            ),
          );
        },
      ),
    );
  }
}
