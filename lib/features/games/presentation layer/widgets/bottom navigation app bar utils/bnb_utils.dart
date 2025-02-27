import 'package:analysis_ai/core/app_colors.dart';
import 'package:analysis_ai/features/games/presentation%20layer/pages/matches_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../pages/test2.dart';
import '../../pages/test3.dart';
import '../../pages/test4.dart';

List<Widget> buildScreens() {
  return [MatchesScreen(), Test2(), Test3(), Test4()];
}

List<PersistentBottomNavBarItem> navBarsItems() {
  return [
    PersistentBottomNavBarItem(
      icon: Icon(FontAwesomeIcons.clock, size: 25),
      title: ("Matchs"),
      activeColorPrimary: AppColor.primaryColor,
      inactiveColorPrimary: CupertinoColors.systemGrey,

      // scrollController: ScrollController.,
    ),
    PersistentBottomNavBarItem(
      icon: Icon(FontAwesomeIcons.trophy, size: 25),
      title: ("Ligues"),
      activeColorPrimary: AppColor.primaryColor,
      inactiveColorPrimary: CupertinoColors.systemGrey,

      // scrollController: ScrollController.,
    ),
    PersistentBottomNavBarItem(
      icon: Icon(FontAwesomeIcons.star, size: 25),
      title: ("Favoris"),
      activeColorPrimary: AppColor.primaryColor,
      inactiveColorPrimary: CupertinoColors.systemGrey,

      // scrollController: ScrollController.,
    ),
    PersistentBottomNavBarItem(
      icon: Icon(FontAwesomeIcons.circleUser, size: 25),
      title: ("Profile"),
      activeColorPrimary: AppColor.primaryColor,
      inactiveColorPrimary: CupertinoColors.systemGrey,

      // scrollController: _scrollController2,
    ),
  ];
}
