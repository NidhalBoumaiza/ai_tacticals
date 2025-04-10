import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shimmer/shimmer.dart';

class CountryFlagWidget extends StatelessWidget {
  final dynamic
  flag; // Can be teamId (int/String), tournamentId (int), or country code (String)
  final double height;
  final double width;
  final bool isTeamFlag; // New parameter to specify if it's a team flag

  const CountryFlagWidget({
    super.key,
    required this.flag,
    this.height = 25.0,
    this.width = 25.0,
    this.isTeamFlag = false, // Default to false (tournament/country flag)
  });

  @override
  Widget build(BuildContext context) {
    late String imageUrl;
    bool isNumeric(String str) {
      final numericRegex = RegExp(r'^\d+$');
      return numericRegex.hasMatch(str);
    }

    // Determine if the app is in light or dark mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeVariant = isDarkMode ? 'dark' : 'light';

    if (isTeamFlag && isNumeric(flag.toString())) {
      // Use team logo endpoint for team IDs
      imageUrl =
          "https://img.sofascore.com/api/v1/team/${flag.toString()}/image/small";
    } else if (isNumeric(flag.toString())) {
      // Use tournament image endpoint for tournament IDs
      imageUrl =
          "https://api.sofascore.com/api/v1/unique-tournament/${flag.toString()}/image/dark";
    } else {
      // Use country flag endpoint for country codes
      imageUrl =
          'https://www.sofascore.com/static/images/flags/${flag.toLowerCase()}.png';
    }

    // Reuse the CustomCacheManager from MatchesScreen for consistency
    final cacheManager = CustomCacheManager(
      Config(
        'teamLogosCache',
        stalePeriod: const Duration(days: 30),
        maxNrOfCacheObjects: 500,
      ),
    );

    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: cacheManager,
      placeholder:
          (context, url) => Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.surface,
            highlightColor: Theme.of(context).colorScheme.surfaceVariant,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
      errorWidget:
          (context, url, error) =>
              Icon(Icons.error, color: Theme.of(context).colorScheme.error),
      fit: BoxFit.cover,
      width: width,
      height: height,
      cacheKey:
          '${flag.toString()}${isTeamFlag ? 'team' : 'flag'}$themeVariant',
    );
  }
}

// CustomCacheManager class (already defined in MatchesScreen)
class CustomCacheManager extends CacheManager {
  CustomCacheManager(Config config) : super(config);
  static const key = 'teamLogosCache';
}
