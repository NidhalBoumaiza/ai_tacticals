import 'package:flutter/material.dart'; // Added for ThemeData access
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../pages/bottom app bar screens/editing_video_screen.dart';
import '../../pages/bottom app bar screens/leagues_screen.dart';
import '../../pages/bottom app bar screens/matches_screen.dart';
import '../../pages/bottom app bar screens/test4.dart';

List<Widget> buildScreens() {
  return [MatchesScreen(), LeagueScreen(), EditingVideoScreen(), ProfilePage()];
}

List<PersistentBottomNavBarItem> navBarsItems(BuildContext context) {
  // Determine the inactive color based on the theme's brightness
  final inactiveColor =
      Theme.of(context).brightness == Brightness.light
          ? Colors
              .white // Use white in light mode
          : Theme.of(
            context,
          ).colorScheme.onSurface; // Use onSurface (white) in dark mode

  return [
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.futbol, size: 25),
      title: 'matches'.tr,
      activeColorPrimary: Theme.of(context).colorScheme.primary,
      inactiveColorPrimary: inactiveColor,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.trophy, size: 25),
      title: 'leagues'.tr,
      activeColorPrimary: Theme.of(context).colorScheme.primary,
      inactiveColorPrimary: inactiveColor,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.pencil, size: 25),
      title: 'Drawer tool'.tr,
      activeColorPrimary: Theme.of(context).colorScheme.primary,
      inactiveColorPrimary: inactiveColor,
    ),
    PersistentBottomNavBarItem(
      icon: const Icon(FontAwesomeIcons.circleUser, size: 25),
      title: 'profile'.tr,
      activeColorPrimary: Theme.of(context).colorScheme.primary,
      inactiveColorPrimary: inactiveColor,
    ),
  ];
}
