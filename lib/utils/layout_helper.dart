// 文件说明：响应式布局工具，根据屏幕尺寸判断导航模式与布局类型。
// 技术要点：工具方法、Flutter。

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;

class LayoutHelper {
  static const double tabletContentMaxWidth = 1200;
  static const double tabletPagePadding = 28;

  static double tabletPageInsetForWidth(double width) =>
      ((width - tabletContentMaxWidth) / 2).clamp(0.0, double.infinity) +
      tabletPagePadding;

  /// 判断当前窗口是否使用顶部导航的宽屏布局。
  ///
  /// 触控设备保留高度门槛，避免手机横屏仅因宽度变大进入宽屏模式；
  /// 桌面窗口只按宽度切换，让 macOS / Windows / Linux 复用平板顶部导航、
  /// 标题动作、内容宽度和顶部背景。
  static bool usesTabletLayout(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final touchPlatform =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
    if (touchPlatform) {
      return size.width >= 600 && size.height >= 500;
    }
    final desktopPlatform =
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
    return desktopPlatform && size.width >= 600;
  }

  // 屏幕尺寸断点
  static const double largeMobileBreakpoint = 414.0; // iPhone Plus/Pro Max等大屏手机
  static const double tabletBreakpoint = 820.0; // 降低断点以支持小尺寸平板(7-8英寸)和折叠屏
  static const double desktopBreakpoint = 1200.0;

  /// 固定尺寸的书封框统一裁满，不能因平台或封面来源改变视觉尺寸。
  static const BoxFit bookCoverFit = BoxFit.cover;

  /// 兼容纯封面网格原有命名。
  static const BoxFit coverOnlyGridFit = bookCoverFit;

  // 判断是否为普通手机
  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < largeMobileBreakpoint;
  }

  // 判断是否为大屏手机
  static bool isLargeMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= largeMobileBreakpoint && width < tabletBreakpoint;
  }

  // 判断是否为手机（包括大屏手机）
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  // 判断是否为平板
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  // 判断是否为桌面
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  // 判断是否为宽屏设备（平板或桌面）
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // 获取屏幕类型
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      return ScreenType.desktop;
    } else if (width >= tabletBreakpoint) {
      return ScreenType.tablet;
    } else if (width >= largeMobileBreakpoint) {
      return ScreenType.largeMobile;
    } else {
      return ScreenType.mobile;
    }
  }

  // 根据屏幕类型返回不同的值
  static T getValue<T>(
    BuildContext context, {
    required T mobile,
    T? largeMobile,
    T? tablet,
    T? desktop,
  }) {
    switch (getScreenType(context)) {
      case ScreenType.desktop:
        return desktop ?? tablet ?? largeMobile ?? mobile;
      case ScreenType.tablet:
        return tablet ?? largeMobile ?? mobile;
      case ScreenType.largeMobile:
        return largeMobile ?? mobile;
      case ScreenType.mobile:
        return mobile;
    }
  }

  // 获取响应式边距
  static double getHorizontalPadding(BuildContext context) {
    return getValue(
      context,
      mobile: 16.0,
      largeMobile: 20.0,
      tablet: 32.0,
      desktop: 64.0,
    );
  }

  // 获取响应式列数
  static int getColumnCount(
    BuildContext context, {
    int mobileColumns = 1,
    int? tabletColumns,
    int? desktopColumns,
  }) {
    return getValue(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns ?? mobileColumns * 2,
      desktop: desktopColumns ?? tabletColumns ?? mobileColumns * 3,
    );
  }

  // 获取响应式字体大小
  static double getFontSize(
    BuildContext context, {
    required double baseFontSize,
    double? tabletScale,
    double? desktopScale,
  }) {
    final scale = getValue(
      context,
      mobile: 1.0,
      tablet: tabletScale ?? 1.1,
      desktop: desktopScale ?? 1.2,
    );
    return baseFontSize * scale;
  }

  // 书库网格按可用宽度推导列数（网格仅在平板/桌面显示）。
  // 目标是每个格子约 168 逻辑像素宽（封面 ~150），旋转屏幕时封面大小
  // 基本不变、只重排列数，避免大屏上封面过大。
  static int bookGridColumnsForWidth(double width) {
    const double targetItemExtent = 168.0;
    const double horizontalPadding = 32.0;
    if (width <= 0) return 3;
    return ((width - horizontalPadding) / targetItemExtent).round().clamp(
      3,
      10,
    );
  }

  /// 纯封面网格密度。
  ///
  /// [mobileColumns] 是用户的密度偏好，保存后不会因当前窗口变窄而被改写。
  /// 实际列数同时受容器净宽、64dp 最小封面宽度和文字缩放影响：
  /// 390dp 手机在标准字号下可排 5 列，320dp 会自动降为 4 列。
  /// 宽屏延续相同密度意图，但最多 8 列。
  static int coverOnlyGridColumnsForWidth(
    double width, {
    required int mobileColumns,
    bool? usesWideLayout,
    double? horizontalPadding,
    double? spacing,
    bool showDetails = false,
    bool hasFolders = false,
    double textScaleFactor = 1,
  }) {
    final preferredColumns = mobileColumns.clamp(2, 5).toInt();
    final wide = usesWideLayout ?? width >= tabletBreakpoint;
    final resolvedPadding = horizontalPadding ?? (wide ? 32.0 : 12.0);
    final resolvedSpacing = spacing ?? (wide ? 14.0 : 10.0);
    final availableWidth = (width - resolvedPadding * 2).clamp(
      0.0,
      double.infinity,
    );
    final accessibleScale = textScaleFactor < 1 ? 1.0 : textScaleFactor;
    final minimumCoverWidth = showDetails || hasFolders
        ? 64.0 + (accessibleScale - 1) * 32.0
        : 64.0;
    final fittingColumns =
        ((availableWidth + resolvedSpacing) /
                (minimumCoverWidth + resolvedSpacing))
            .floor()
            .clamp(1, wide ? 8 : 5)
            .toInt();

    if (!wide) {
      return preferredColumns.clamp(1, fittingColumns).toInt();
    }

    final preferredItemWidth = switch (preferredColumns) {
      2 => 184.0,
      3 => 148.0,
      4 => 116.0,
      _ => 96.0,
    };
    final targetItemWidth = preferredItemWidth.clamp(
      minimumCoverWidth,
      double.infinity,
    );
    final densityColumns =
        ((availableWidth + resolvedSpacing) /
                (targetItemWidth + resolvedSpacing))
            .round()
            .toInt();
    return densityColumns.clamp(1, fittingColumns).toInt();
  }

  // 判断是否应该显示双页布局
  static bool shouldShowDoublePage(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // 横屏且宽度足够时显示双页
    return width > height && width >= tabletBreakpoint;
  }

  // 获取导航栏类型
  static NavigationType getNavigationType(BuildContext context) {
    if (usesTabletLayout(context)) {
      return NavigationType.bottom;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android) {
      return NavigationType.bottom;
    }
    if (isDesktop(context) || isTablet(context)) {
      return NavigationType.rail;
    } else {
      return NavigationType.bottom;
    }
  }
}

enum ScreenType { mobile, largeMobile, tablet, desktop }

enum NavigationType { bottom, rail }
