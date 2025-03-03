import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

navigateToAnotherScreenWithFadeTransition(context, newScreen) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => newScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

navigateToAnotherScreenWithSlideTransitionFromRightToLeft(context, newScreen) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => newScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    ),
  );
}

navigateToAnotherScreenWithSlideTransitionFromBottomToTop(context, newScreen) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => newScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1), // Start from bottom
            end: Offset.zero, // End at top
          ).animate(animation),
          child: child,
        );
      },
    ),
  );
}

navigateToAnotherScreenWithSlideTransitionFromRightToLeftPushReplacement(
  context,
  newScreen,
) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => newScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    ),
  );
}

navigateToAnotherScreenWithBottomToTopTransition(context, newScreen) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => newScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    ),
  );
}

// Fade Transition with pushReplacement
navigateToAnotherScreenWithFadeTransitionPushReplacement(context, newScreen) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => newScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

// Slide Transition from Bottom to Top with pushReplacement
navigateToAnotherScreenWithSlideTransitionFromBottomToTopPushReplacement(
  context,
  newScreen,
) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => newScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1), // Start from bottom
            end: Offset.zero, // End at top
          ).animate(animation),
          child: child,
        );
      },
    ),
  );
}

// Bottom to Top Transition with pushReplacement (same as Slide from Bottom to Top)
navigateToAnotherScreenWithBottomToTopTransitionPushReplacement(
  context,
  newScreen,
) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => newScreen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    ),
  );
}

class PersistentNavBarNavigatorrr {
  static void pushNewScreenWithRouteSettings({
    required BuildContext context,
    required Widget screen,
    bool withNavBar = true,
    PageTransitionAnimation pageTransitionAnimation =
        PageTransitionAnimation.slideRight,
    RouteSettings? settings,
    bool replace = false, // Add a replace flag
  }) {
    if (replace) {
      // Replace the current screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen, settings: settings),
      );
    } else {
      // Push a new screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen, settings: settings),
      );
    }
  }
}
