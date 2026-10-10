// 文件说明：首页导航项数据与表现组件，描述单个导航入口。
// 技术要点：Flutter UI。

import 'package:flutter/material.dart';
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/models/home_navigation_destination.dart';
import 'package:xxread/widgets/floating_pill_navigation_item.dart';

/// 首页导航项模型。
///
/// 壳层只依赖这个结构来绘制导航，不关心页面内部实现。
class HomeNavigationItem extends FloatingPillNavigationItem {
  final HomeNavigationDestination destination;
  final Widget page;

  const HomeNavigationItem({
    required this.destination,
    required super.icon,
    required super.selectedIcon,
    required super.label,
    required this.page,
  });

  @override
  AppSkinIconSlot get skinSlot => switch (destination) {
    HomeNavigationDestination.home => AppSkinIconSlot.home,
    HomeNavigationDestination.library => AppSkinIconSlot.library,
    HomeNavigationDestination.discover => AppSkinIconSlot.discover,
    HomeNavigationDestination.ai => AppSkinIconSlot.ai,
    HomeNavigationDestination.settings => AppSkinIconSlot.profile,
  };
}
