import 'package:flutter/material.dart';

class ColorFilteredImageAsset extends StatelessWidget {
  final String imageSource;
  final Color imageColor;

  const ColorFilteredImageAsset(
      {Key? key, required this.imageSource, required this.imageColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      key: ValueKey("ColorFilteredImageAsset-$key"),
      child: Image.asset(
        imageSource,
        scale: 1,
      ),
      colorFilter: ColorFilter.mode(imageColor, BlendMode.srcIn),
    );
  }
}
