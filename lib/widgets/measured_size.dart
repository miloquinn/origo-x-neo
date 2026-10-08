import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Reports actual layout changes, including changes within a native editor.
class MeasuredSize extends SingleChildRenderObjectWidget {
  const MeasuredSize({
    super.key,
    required this.onChanged,
    required super.child,
  });

  final ValueChanged<Size> onChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasuredSize(onChanged);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderObject renderObject,
  ) {
    (renderObject as _RenderMeasuredSize).onChanged = onChanged;
  }
}

class _RenderMeasuredSize extends RenderProxyBox {
  _RenderMeasuredSize(this.onChanged);

  ValueChanged<Size> onChanged;
  Size? _lastSize;

  @override
  void performLayout() {
    super.performLayout();
    final measured = size;
    if (measured == _lastSize) return;
    _lastSize = measured;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached && size == measured) onChanged(measured);
    });
  }
}
