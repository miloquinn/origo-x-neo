import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Measure the fixed-size information text under the platform text scaler.
/// The default slots remain unchanged; large accessibility text gets its own
/// space instead of overflowing towards the body.
double readerInformationTextHeight(
  TextScaler textScaler,
  Locale? locale, {
  TextStyle? style,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: '章Ag09:05',
      style: (style ?? const TextStyle()).copyWith(
        fontSize: 10,
        height: 1,
        fontWeight: FontWeight.w600,
      ),
    ),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    locale: locale,
  )..layout();
  final height = painter.height.ceilToDouble() + 2;
  painter.dispose();
  return height;
}

/// 阅读正文相对系统安全区的统一布局指标。
///
/// 系统 inset 与用户选择的阅读边距各司其职：顶部确保正文落在刘海/灵动岛
/// 下方。页码可以落在系统底部安全区内、但保持在 Home Indicator 上方；
/// 正文边距与页眉页脚位移分别保存。分页和绘制共用实际正文区域，
/// 信息条始终留在该区域外；短视口只压缩实际留白，不改用户偏好。
class ReaderSafeAreaMetrics {
  static const double pageNumberReserve = 12.0;
  static const double pageNumberGap = 4.0;
  static const double readerTopBarHeight = 16.0;
  static const double readerTopBarGap = 8.0;
  static const double readerTopBarReserve =
      readerTopBarHeight + readerTopBarGap;
  static const double _pageNumberSafeAreaOverlap = 20.0;
  static const double _minimumPageNumberBottom = 8.0;

  /// 状态栏 inset 随隐藏一起归零的设备（无刘海直屏）上，灵动信息栏仍按
  /// 普通状态栏高度画在页面最顶端。
  static const double floatingStatusMinHeight = 24.0;

  final EdgeInsets viewPadding;
  final double topMargin;
  final double bottomMargin;
  final double topChromeReserve;
  final double headerOffset;
  final double footerOffset;
  final bool hasReaderHeader;
  final double headerHeight;
  final double footerHeight;
  final double headerContentGap;
  final double footerContentGap;
  final double viewportHeight;
  final double minimumContentHeight;

  const ReaderSafeAreaMetrics({
    required this.viewPadding,
    required this.topMargin,
    required this.bottomMargin,
    this.topChromeReserve = 0,
    this.headerOffset = 0,
    this.footerOffset = 0,
    this.hasReaderHeader = false,
    this.headerHeight = readerTopBarHeight,
    this.footerHeight = pageNumberReserve,
    this.headerContentGap = 4,
    this.footerContentGap = pageNumberGap,
    this.viewportHeight = double.infinity,
    this.minimumContentHeight = 120,
  });

  double get _baseHeaderTop => viewPadding.top + 4;

  double get _baseFooterBottom => math.max(
    _minimumPageNumberBottom,
    viewPadding.bottom - _pageNumberSafeAreaOverlap,
  );

  double get _minimumTop => math.max(
    viewPadding.top + topChromeReserve,
    hasReaderHeader ? _baseHeaderTop + headerHeight + headerContentGap : 0,
  );

  double get _minimumBottom => math.max(
    viewPadding.bottom,
    _baseFooterBottom + footerHeight + footerContentGap,
  );

  ({double top, double bottom, double headerTop, double footerBottom})
  get _geometry {
    final minimumTop = _minimumTop;
    final minimumBottom = _minimumBottom;
    final requestedTop = math.max(
      viewPadding.top + topChromeReserve + topMargin,
      hasReaderHeader
          ? _baseHeaderTop +
                math.max(0, headerOffset) +
                headerHeight +
                headerContentGap
          : minimumTop,
    );
    final requestedBottom = math.max(
      viewPadding.bottom + bottomMargin,
      _baseFooterBottom +
          math.max(0, footerOffset) +
          footerHeight +
          footerContentGap,
    );
    final topExtra = math.max(0, requestedTop - minimumTop);
    final bottomExtra = math.max(0, requestedBottom - minimumBottom);
    final extra = topExtra + bottomExtra;
    final availableExtra = math.max(
      0,
      viewportHeight - minimumTop - minimumBottom - minimumContentHeight,
    );
    final scale = extra > availableExtra ? availableExtra / extra : 1.0;
    final top = minimumTop + topExtra * scale;
    final bottom = minimumBottom + bottomExtra * scale;
    return (
      top: top,
      bottom: bottom,
      headerTop:
          _baseHeaderTop +
          (hasReaderHeader
              ? math.min(
                  math.max(0, headerOffset),
                  math.max(
                    0,
                    top - _baseHeaderTop - headerHeight - headerContentGap,
                  ),
                )
              : 0),
      footerBottom:
          _baseFooterBottom +
          math.min(
            math.max(0, footerOffset),
            math.max(
              0,
              bottom - _baseFooterBottom - footerHeight - footerContentGap,
            ),
          ),
    );
  }

  double get contentTop => _geometry.top;

  double get contentBottom => _geometry.bottom;

  double get readerTopBarTop => _geometry.headerTop;

  /// 灵动信息栏占用的区域高度：即被隐藏的系统状态栏区域。
  double get floatingStatusHeight =>
      math.max(viewPadding.top, floatingStatusMinHeight);

  double get pageNumberBottom => _geometry.footerBottom;

  String get paginationSignature =>
      '${contentTop.toStringAsFixed(2)}:${contentBottom.toStringAsFixed(2)}:'
      '${topChromeReserve.toStringAsFixed(2)}:'
      '${readerTopBarTop.toStringAsFixed(2)}:'
      '${pageNumberBottom.toStringAsFixed(2)}:'
      '${headerHeight.toStringAsFixed(2)}:${footerHeight.toStringAsFixed(2)}';
}
