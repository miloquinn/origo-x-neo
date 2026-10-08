// Native Profile diagnostic. Runs the real app and navigates without changing
// preferences. Restore lib/main.dart for the final device acceptance install.
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xxread/main.dart' as application;
import 'package:xxread/models/home_navigation_destination.dart';
import 'package:xxread/pages/home/widgets/home_bounce_navigation_item.dart';
import 'package:xxread/pages/settings/settings_page.dart';

const _label = String.fromEnvironment(
  'SETTINGS_RETURN_LABEL',
  defaultValue: 'baseline',
);
const _iterations = int.fromEnvironment(
  'SETTINGS_RETURN_ITERATIONS',
  defaultValue: 12,
);

void main(List<String> arguments) {
  application.main(arguments);
  unawaited(_measure());
}

Element? _find(bool Function(Widget) predicate) {
  Element? result;
  void visit(Element element) {
    if (result != null) return;
    if (predicate(element.widget)) {
      result = element;
      return;
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return result;
}

Future<Element> _waitFor(bool Function(Widget) predicate) async {
  for (var i = 0; i < 600; i++) {
    final element = _find(predicate);
    if (element != null) return element;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw StateError('Benchmark page did not become ready');
}

Future<void> _measure() async {
  final frames = <FrameTiming>[];
  void record(List<FrameTiming> batch) => frames.addAll(batch);
  try {
    final item = await _waitFor(
      (widget) =>
          widget is HomeBounceNavigationItem &&
          widget.item.destination == HomeNavigationDestination.settings,
    );
    (item.widget as HomeBounceNavigationItem).onTap();
    await Future<void>.delayed(const Duration(seconds: 2));
    final hub = await _waitFor(
      (widget) => widget is SettingsPage && widget.category == null,
    );
    if (!(ModalRoute.isCurrentOf(hub) ?? true)) {
      throw StateError('Settings hub is covered by another route');
    }
    final navigator = Navigator.of(hub);
    final display = View.of(hub).display;
    WidgetsBinding.instance.addTimingsCallback(record);
    final windows = <(int, int)>[];
    for (var i = 0; i < _iterations; i++) {
      final entry = await _waitFor(
        (widget) =>
            widget is InkWell &&
            widget.key == const ValueKey('settings-category-preferences'),
      );
      (entry.widget as InkWell).onTap!();
      final preferences = await _waitFor(
        (widget) =>
            widget is SettingsPage &&
            widget.category == SettingsCategory.preferences,
      );
      final route = ModalRoute.of(preferences)!;
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      final start = developer.Timeline.now;
      navigator.pop();
      await route.completed;
      windows.add((start, developer.Timeline.now));
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    await Future<void>.delayed(const Duration(seconds: 2));
    final returns = frames
        .where(
          (frame) => windows.any((window) {
            final timestamp = frame.timestampInMicroseconds(
              FramePhase.vsyncStart,
            );
            return timestamp >= window.$1 && timestamp <= window.$2;
          }),
        )
        .toList();
    if (returns.isEmpty) throw StateError('No return frames recorded');
    final refreshRate = display.refreshRate;
    if (refreshRate <= 0) throw StateError('Display refresh rate unavailable');
    final budget = 1000000 / refreshRate;
    final samples = <Map<String, int>>[];
    for (var iteration = 0; iteration < windows.length; iteration++) {
      final window = windows[iteration];
      final run = returns.where((frame) {
        final timestamp = frame.timestampInMicroseconds(FramePhase.vsyncStart);
        return timestamp >= window.$1 && timestamp <= window.$2;
      }).toList();
      if (run.isEmpty) throw StateError('No frames for return $iteration');
      for (var index = 0; index < run.length; index++) {
        final frame = run[index];
        samples.add({
          'iteration': iteration,
          'frameIndex': index,
          'vsyncUs': frame.timestampInMicroseconds(FramePhase.vsyncStart),
          'uiUs': frame.buildDuration.inMicroseconds,
          'rasterUs': frame.rasterDuration.inMicroseconds,
          'totalSpanUs': frame.totalSpan.inMicroseconds,
        });
      }
    }
    final report = <String, Object>{
      'label': _label,
      'iterations': _iterations,
      'refreshRate': refreshRate,
      'frames': returns.length,
      'uniqueOverBudget': returns
          .where(
            (frame) =>
                frame.buildDuration.inMicroseconds > budget ||
                frame.rasterDuration.inMicroseconds > budget,
          )
          .length,
      'uiRasterOverlap': returns
          .where(
            (frame) =>
                frame.buildDuration.inMicroseconds > budget &&
                frame.rasterDuration.inMicroseconds > budget,
          )
          .length,
      'ui': _summary(
        returns.map((frame) => frame.buildDuration.inMicroseconds),
        refreshRate,
      ),
      'raster': _summary(
        returns.map((frame) => frame.rasterDuration.inMicroseconds),
        refreshRate,
      ),
      'totalSpan': _summary(
        returns.map((frame) => frame.totalSpan.inMicroseconds),
        refreshRate,
      ),
      'firstFrames': samples
          .where((sample) => sample['frameIndex']! < 2)
          .toList(),
      'samples': samples,
    };
    // Keep the entire record on one line for extraction from flutter run logs.
    await _save(report);
    stdout.writeln('SETTINGS_RETURN_RESULT ${jsonEncode(report)}');
  } catch (error, stack) {
    await _save({'label': _label, 'error': '$error', 'stack': '$stack'});
    stdout.writeln('SETTINGS_RETURN_FAILURE $error\n$stack');
  } finally {
    WidgetsBinding.instance.removeTimingsCallback(record);
  }
}

Future<void> _save(Map<String, Object> report) async {
  final directory = await getApplicationDocumentsDirectory();
  await File(
    '${directory.path}/settings-return-$_label.json',
  ).writeAsString(jsonEncode(report));
}

Map<String, Object> _summary(Iterable<int> values, double refreshRate) {
  final samples = values.toList()..sort();
  final budget = 1000000 / refreshRate;
  return {
    'p50Us': samples[samples.length ~/ 2],
    'p90Us': samples[((samples.length - 1) * .9).round()],
    'maxUs': samples.last,
    'overDisplayBudget': samples.where((value) => value > budget).length,
    'over16ms': samples.where((value) => value > 16667).length,
  };
}
