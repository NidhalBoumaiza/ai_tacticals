import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:analysis_ai/features/games/presentation layer/bloc/countries_bloc/countries_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../widgets/home page widgets/league_and_matches_by_country_widget.dart';

class Test2 extends StatefulWidget {
  const Test2({super.key});

  @override
  State<Test2> createState() => _Test2State();
}

class _Test2State extends State<Test2> {
  @override
  void initState() {
    super.initState();
    // Trigger fetching countries when the widget initializes
    context.read<CountriesBloc>().add(GetAllCountries());
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
                Icon(FontAwesomeIcons.bars, size: 60.sp, color: Colors.white),
                SizedBox(width: 765.w),
                Icon(
                  FontAwesomeIcons.calendar,
                  size: 50.sp,
                  color: Colors.white,
                ),
                SizedBox(width: 65.w),
                Icon(
                  FontAwesomeIcons.magnifyingGlass,
                  size: 50.sp,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xff010001), // Light yellow-ish background
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
                          leagues: _getLeaguesForCountry(
                            country.name,
                          ), // Simulated leagues
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

  List<String> _getLeaguesForCountry(String countryName) {
    switch (countryName) {
      case 'USA':
        return [
          'MLS',
          'USL Championship',
          'US Open Cup',
          'NPSL',
          'MLS Preseason',
          'MLS Next Pro',
          'NWSL',
        ];
      case 'Europe':
        return [
          'UEFA Champions League',
          'Europa League',
          'Premier League',
          'La Liga',
          'Serie A',
          'Bundesliga',
        ];
      case 'South America':
        return [
          'Copa Libertadores',
          'Brasileirão',
          'Argentine Primera División',
        ];
      case 'Asia':
        return ['AFC Champions League', 'J1 League', 'K League 1'];
      case 'Africa':
        return [
          'CAF Champions League',
          'Egyptian Premier League',
          'South African Premier Division',
        ];
      case 'North & Central America':
        return ['CONCACAF Champions League', 'Liga MX', 'Major League Soccer'];
      case 'Oceania':
        return ['OFC Champions League', 'A-League', 'National Premier Leagues'];
      default:
        return ['No leagues available'];
    }
  }
}
