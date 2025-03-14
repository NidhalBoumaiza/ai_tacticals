import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../widgets/bottom navigation app bar utils/bnb_utils.dart';

class HomeScreenSquelette extends StatefulWidget {
  const HomeScreenSquelette({super.key});

  @override
  State<HomeScreenSquelette> createState() => _HomeScreenSqueletteState();
}

class _HomeScreenSqueletteState extends State<HomeScreenSquelette> {
  bool isOn = false;

  @override
  Widget build(BuildContext context) {
    PersistentTabController _controller;

    _controller = PersistentTabController(initialIndex: 0);
    return SafeArea(
      child: Scaffold(
        body: PersistentTabView(
          context,
          controller: _controller,
          screens: buildScreens(),
          items: navBarsItems(context),
          handleAndroidBackButtonPress: true,
          // Default is true.
          resizeToAvoidBottomInset: true,
          // This needs to be true if you want to move up the screen on a non-scrollable screen when keyboard appears. Default is true.
          stateManagement: true,
          // Default is true.
          hideNavigationBarWhenKeyboardAppears: true,
          //   popBehaviorOnSelectedNavBarItemPress: PopActionScreensType.all,
          padding: EdgeInsets.only(top: 0.h),
          backgroundColor: Colors.grey.shade900,
          isVisible: true,
          animationSettings: const NavBarAnimationSettings(
            navBarItemAnimation: ItemAnimationSettings(
              // Navigation Bar's items animation properties.
              duration: Duration(milliseconds: 400),
              curve: Curves.ease,
            ),
            screenTransitionAnimation: ScreenTransitionAnimationSettings(
              // Screen transition animation on change of selected tab.
              animateTabTransition: true,
              duration: Duration(milliseconds: 200),
              screenTransitionAnimationType:
                  ScreenTransitionAnimationType.fadeIn,
            ),
          ),
          confineToSafeArea: true,
          navBarHeight: kBottomNavigationBarHeight,
          navBarStyle:
              NavBarStyle.style3, // Choose the nav bar style with this property
        ),
      ),
    );
  }
}
