import 'dart:io';

import 'package:flutter/material.dart';

import '../models/app_skin.dart';

ImageProvider<Object> appSkinImageProvider(
  AppSkinImage image,
  Brightness brightness,
) {
  final imagePath = image.pathFor(brightness);
  return switch (image.source) {
    AppSkinImageSource.bundledAsset => AssetImage(imagePath),
    AppSkinImageSource.installedFile => FileImage(File(imagePath)),
  };
}
