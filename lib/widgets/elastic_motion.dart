import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

/// Keeps velocity when a pointer changes the destination between frames.
class ElasticSpring extends ChangeNotifier implements ValueListenable<double> {
  ElasticSpring(TickerProvider vsync, double initialValue)
    : _value = initialValue,
      _target = initialValue {
    _ticker = vsync.createTicker(_tick);
  }

  late final Ticker _ticker;
  double _value;
  double _target;
  double _elapsed = 0;
  double _started = 0;
  SpringSimulation? _simulation;

  @override
  double get value => _value;
  double get velocity => _simulation?.dx(_elapsed - _started) ?? 0;

  void animateTo(double target, SpringDescription spring) {
    if (target == _target && _simulation != null) return;
    _simulation = SpringSimulation(spring, value, target, velocity);
    _target = target;
    if (_ticker.isActive) {
      _started = _elapsed;
    } else {
      _elapsed = _started = 0;
      _ticker.start();
    }
  }

  void jumpTo(double value) {
    _ticker.stop();
    _simulation = null;
    _value = _target = value;
    notifyListeners();
  }

  void _tick(Duration elapsed) {
    _elapsed = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final simulation = _simulation!;
    final time = _elapsed - _started;
    _value = simulation.x(time);
    if (simulation.isDone(time)) {
      _value = _target;
      _simulation = null;
      _ticker.stop();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class ElasticSpringCurve extends Curve {
  ElasticSpringCurve({
    required Duration duration,
    required Duration settlingDuration,
    double bounce = 0,
  }) : _seconds = duration.inMicroseconds / Duration.microsecondsPerSecond,
       _simulation = SpringSimulation(
         SpringDescription.withDurationAndBounce(
           duration: settlingDuration,
           bounce: bounce,
         ),
         0,
         1,
         0,
       );

  final double _seconds;
  final SpringSimulation _simulation;

  @override
  double transformInternal(double t) =>
      _simulation.x(t * _seconds) + (1 - _simulation.x(_seconds)) * t;
}
