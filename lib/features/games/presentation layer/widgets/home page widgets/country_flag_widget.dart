import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CountryFlagWidget extends StatelessWidget {
  final dynamic flag;

  const CountryFlagWidget({super.key, required this.flag});

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
              width: 25,
              height: 25,
              color: Colors.grey.shade300,
            ),
          ),
      errorWidget: (context, url, error) {
        print('Error loading image: $error'); // Debugging: Print the error
        return Icon(Icons.error);
      },
      fit: BoxFit.cover,
      width: 25,

      cacheKey: flag,
      height: 25, // Increase height for better visibility
    );
  }
}
