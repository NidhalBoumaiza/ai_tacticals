import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CountryFlagWidget extends StatelessWidget {
  final dynamic flag;
  final double height;
  final double width;

  const CountryFlagWidget({
    super.key,
    required this.flag,
    this.height = 25.0,
    this.width = 25.0,
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

    if (isNumeric(flag.toString())) {
      imageUrl =
          "https://api.sofascore.com/api/v1/unique-tournament/$flag/image/$themeVariant";
    } else {
      imageUrl =
          'https://www.sofascore.com/static/images/flags/${flag.toLowerCase()}.png';
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
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
      cacheKey: flag.toString(),
    );
  }
}
