import 'package:analysis_ai/core/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart'; // Added for translations
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../pages/bottom app bar screens/leagues_screen.dart';
import '../../pages/bottom app bar screens/matches_screen.dart';
import '../../pages/bottom app bar screens/test3.dart';
import '../../pages/bottom app bar screens/test4.dart';

List<Widget> buildScreens() {
  return [MatchesScreen(), LeagueScreen(), Test3(), Test4()];
}

List<PersistentBottomNavBarItem> navBarsItems() {
  return [
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.futbol, size: 25),
      title: 'matches'.tr, // Translated
      activeColorPrimary: AppColor.primaryColor,
      inactiveColorPrimary: CupertinoColors.systemGrey,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.trophy, size: 25),
      title: 'leagues'.tr, // Translated
      activeColorPrimary: AppColor.primaryColor,
      inactiveColorPrimary: CupertinoColors.systemGrey,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.star, size: 25),
      title: 'favorites'.tr, // Translated
      activeColorPrimary: AppColor.primaryColor,
      inactiveColorPrimary: CupertinoColors.systemGrey,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.circleUser, size: 25),
      title: 'profile'.tr, // Translated
      activeColorPrimary: AppColor.primaryColor,
      inactiveColorPrimary: CupertinoColors.systemGrey,
    ),
  ];
}
