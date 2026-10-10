import 'package:flutter/material.dart';

import '../models/app_skin.dart';

ImageProvider<Object> appSkinImageProvider(
  AppSkinImage image,
  Brightness brightness,
) {
  if (image.source == AppSkinImageSource.installedFile) {
    throw UnsupportedError('Installed theme images are unavailable on web.');
  }
  return AssetImage(image.pathFor(brightness));
}
