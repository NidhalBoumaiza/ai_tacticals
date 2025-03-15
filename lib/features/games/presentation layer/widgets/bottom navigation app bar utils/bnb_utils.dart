import 'package:flutter/material.dart'; // Added for ThemeData access
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../pages/bottom app bar screens/leagues_screen.dart';
import '../../pages/bottom app bar screens/matches_screen.dart';
import '../../pages/bottom app bar screens/test3.dart';
import '../../pages/bottom app bar screens/test4.dart';

List<Widget> buildScreens() {
  return [MatchesScreen(), LeagueScreen(), Test3(), Test4()];
}

List<PersistentBottomNavBarItem> navBarsItems(BuildContext context) {
  return [
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.futbol, size: 25),
      title: 'matches'.tr,
      activeColorPrimary: Theme.of(context).colorScheme.primary,
      inactiveColorPrimary: Theme.of(context).colorScheme.onSurface,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.trophy, size: 25),
      title: 'leagues'.tr,
      activeColorPrimary: Theme.of(context).colorScheme.primary,
      inactiveColorPrimary: Theme.of(context).colorScheme.onSurface,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.star, size: 25),
      title: 'Drawer tool'.tr,
      activeColorPrimary: Theme.of(context).colorScheme.primary,
      inactiveColorPrimary: Theme.of(context).colorScheme.onSurface,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.circleUser, size: 25),
      title: 'profile'.tr,
      activeColorPrimary: Theme.of(context).colorScheme.primary,
      inactiveColorPrimary: Theme.of(context).colorScheme.onSurface,
    ),
  ];
}
