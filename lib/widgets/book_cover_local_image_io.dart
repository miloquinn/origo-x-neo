import 'dart:io';

import 'package:flutter/material.dart';

Widget buildLocalBookCoverImage({
  required String path,
  required Widget fallback,
  required Widget loadingPlaceholder,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  int? cacheWidth,
  int? cacheHeight,
  AlignmentGeometry alignment = Alignment.center,
  bool gaplessPlayback = true,
}) {
  return Image.file(
    File(path),
    width: width,
    height: height,
    fit: fit,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
    alignment: alignment,
    gaplessPlayback: gaplessPlayback,
    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
        wasSynchronouslyLoaded || frame != null ? child : loadingPlaceholder,
    errorBuilder: (_, _, _) => fallback,
  );
}
