import 'package:analysis_ai/core/widgets/reusable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../../../../../core/widgets/league_web_image_widget.dart';
import '../../../bloc/leagues_bloc/leagues_bloc.dart';
import '../../../cubit/League Image Loading Cubit/league_image_loading_cubit.dart';
import '../../../cubit/seasons cubit/seasons_cubit.dart';
import '../../../pages/league info screens/league_infos_squelette_screen.dart';

class LeaguesAndMatchesByCountryWidget extends StatefulWidget {
  final String countryName;
  final String countryFlag;
  final int countryId;

  const LeaguesAndMatchesByCountryWidget({
    super.key,
    required this.countryName,
    required this.countryFlag,
    required this.countryId,
  });

  @override
  State<LeaguesAndMatchesByCountryWidget> createState() =>
      _LeaguesAndMatchesByCountryWidgetState();
}

class _LeaguesAndMatchesByCountryWidgetState
    extends State<LeaguesAndMatchesByCountryWidget> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    context.read<LeagueImageLoadingCubit>().addImageToQueue(
      "https://www.sofascore.com/static/images/flags/${widget.countryFlag.toLowerCase()}.png",
    );
  }

  @override
  void dispose() {
    WebImageWidget.pool.releaseController(
      // Update to new class name
      "https://www.sofascore.com/static/images/flags/${widget.countryFlag.toLowerCase()}.png",
    );
    super.dispose();
  }

  String _getLeagueImageUrl(int leagueId) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeVariant = isDarkMode ? 'dark' : 'light';
    return "https://api.sofascore.com/api/v1/unique-tournament/$leagueId/image/$themeVariant";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (_isExpanded) {
                context.read<LeaguesBloc>().add(
                  GetLeaguesByCountry(countryId: widget.countryId),
                );
              }
            });
          },
          child: Container(
            height: 125.h,
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 25.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25.r),
                topRight: Radius.circular(25.r),
                bottomLeft: _isExpanded ? Radius.zero : Radius.circular(25.r),
                bottomRight: _isExpanded ? Radius.zero : Radius.circular(25.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      WebImageWidget(
                        // Replace LeagueWebImageWidget
                        imageUrl:
                            "https://www.sofascore.com/static/images/flags/${widget.countryFlag.toLowerCase()}.png",
                        height: 80.w,
                        width: 80.w,
                        onLoaded: () {
                          print(
                            'Country flag loaded for ${widget.countryFlag}',
                          );
                        },
                      ),
                      SizedBox(width: 60.w),
                      ReusableText(
                        text: widget.countryName,
                        textSize: 110.sp,
                        textFontWeight: FontWeight.w500,
                        textColor: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
                BlocBuilder<LeaguesBloc, LeaguesState>(
                  builder: (context, state) {
                    if (state is LeaguesLoading && _isExpanded) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 35.sp,
                            height: 35.sp,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onSurface,
                              strokeWidth: 2.0,
                            ),
                          ),
                          SizedBox(width: 20.w),
                        ],
                      );
                    }
                    return Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 80.sp,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        BlocListener<LeaguesBloc, LeaguesState>(
          listener: (context, state) {
            if (state is LeaguesSuccess && _isExpanded) {
              for (var league in state.leagues) {
                context.read<LeagueImageLoadingCubit>().addImageToQueue(
                  _getLeagueImageUrl(league.id!),
                );
              }
            }
          },
          child: BlocBuilder<LeaguesBloc, LeaguesState>(
            builder: (context, state) {
              if (state is LeaguesLoading && _isExpanded) {
                return const SizedBox.shrink();
              } else if (state is LeaguesError && _isExpanded) {
                return Container(
                  padding: EdgeInsets.all(8.h),
                  color: Theme.of(context).colorScheme.surface,
                  child: Center(
                    child: Text(
                      state.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                );
              } else if (state is LeaguesSuccess && _isExpanded) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10.r),
                        bottomRight: Radius.circular(10.r),
                      ),
                    ),
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: state.leagues.length,
                      itemBuilder: (context, index) {
                        final league = state.leagues[index];
                        return GestureDetector(
                          onTap: () {
                            context.read<SeasonsCubit>().getSeasons(league.id);
                            _showSeasonsDialog(
                              context,
                              league.id!,
                              league.name!,
                            );
                          },
                          child: Container(
                            height: 105.h,
                            padding: EdgeInsets.symmetric(
                              vertical: 2.h,
                              horizontal: 30.w,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(width: 10.w),
                                WebImageWidget(
                                  imageUrl: _getLeagueImageUrl(league.id!),
                                  height: 80.w,
                                  width: 80.w,
                                  onLoaded: () {
                                    print(
                                      'League image loaded for ${league.name}',
                                    );
                                  },
                                ),
                                SizedBox(width: 30.w),
                                Expanded(
                                  child: ReusableText(
                                    text: league.name!,
                                    textSize: 100.sp,
                                    textFontWeight: FontWeight.w400,
                                    textColor:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  void _showSeasonsDialog(
    BuildContext context,
    int leagueId,
    String leagueName,
  ) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocConsumer<SeasonsCubit, SeasonsState>(
            listener: (context, state) {
              if (state is SeasonsError) {
                showErrorSnackBar(context, "Error while loading seasons");
              }
            },
            builder: (context, state) {
              if (state is SeasonsLoading) {
                return Container(
                  height: 200.h,
                  width: 200.h,
                  child: AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    contentPadding: EdgeInsets.zero,
                    insetPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    content: SizedBox(
                      height: 200.h,
                      width: 200.h,
                      child: Lottie.asset(
                        'assets/lottie/animationBallLoading.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              } else if (state is SeasonsLoaded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(dialogContext);
                  PersistentNavBarNavigator.pushNewScreen(
                    context,
                    screen: LeagueInfosSqueletteScreen(
                      leagueId: leagueId,
                      leagueName: leagueName,
                      seasons: state.seasons,
                    ),
                    withNavBar: false,
                    pageTransitionAnimation: PageTransitionAnimation.slideRight,
                  );
                });
                return const SizedBox.shrink();
              } else if (state is SeasonsError) {
                return AlertDialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  content: Center(
                    child: Text(
                      state.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
    );
  }
}
