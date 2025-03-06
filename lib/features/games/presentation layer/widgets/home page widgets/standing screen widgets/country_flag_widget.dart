import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CountryFlagWidget extends StatelessWidget {
  final dynamic flag;
  late double height;
  late double width;

  CountryFlagWidget({
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

    if (isNumeric(flag)) {
      imageUrl =
          "https://api.sofascore.com/api/v1/unique-tournament/$flag/image/dark";
    } else {
      imageUrl =
          'https://www.sofascore.com/static/images/flags/${flag.toLowerCase()}.png';
    }

    print('Image URL: $imageUrl'); // Debugging: Print the URL
    return CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder:
          (context, url) => Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: width ?? 25,
              height: height ?? 25,

              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
      errorWidget: (context, url, error) {
        print('Error loading image: $error'); // Debugging: Print the error
        return Icon(Icons.error);
      },
      fit: BoxFit.cover,
      width: width ?? 25,

      cacheKey: flag,
      height: height ?? 25, // Increase height for better visibility
    );
  }
}
