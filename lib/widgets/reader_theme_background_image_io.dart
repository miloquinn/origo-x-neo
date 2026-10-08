import 'dart:io';

import 'package:flutter/material.dart';

import '../services/core/reader_theme_background_service_io.dart';

Widget buildReaderThemeBackgroundImage(String imagePath) {
  return _ReaderThemeBackgroundImage(imagePath: imagePath);
}

class _ReaderThemeBackgroundImage extends StatefulWidget {
  const _ReaderThemeBackgroundImage({required this.imagePath});

  final String imagePath;

  @override
  State<_ReaderThemeBackgroundImage> createState() =>
      _ReaderThemeBackgroundImageState();
}

class _ReaderThemeBackgroundImageState
    extends State<_ReaderThemeBackgroundImage> {
  final _service = ReaderThemeBackgroundService();
  late Future<String> _resolvedPath;

  @override
  void initState() {
    super.initState();
    _resolvedPath = _service.resolvePath(widget.imagePath);
  }

  @override
  void didUpdateWidget(_ReaderThemeBackgroundImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _resolvedPath = _service.resolvePath(widget.imagePath);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _resolvedPath,
    builder: (context, snapshot) {
      if (snapshot.hasError || !snapshot.hasData) {
        return const SizedBox.shrink();
      }
      return Image.file(
        File(snapshot.data!),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    },
  );
}
