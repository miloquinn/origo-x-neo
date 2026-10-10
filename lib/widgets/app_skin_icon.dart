import 'package:flutter/material.dart';

import '../models/app_skin.dart';
import '../utils/app_skin_theme.dart';
import '../utils/app_skin_image_provider.dart';

/// A semantic skin slot with the original glyph as its compatibility contract.
/// Images keep their own colors; the caller still owns size, motion and actions.
class AppSkinIcon extends StatelessWidget {
  const AppSkinIcon({
    super.key,
    this.slot,
    required this.fallback,
    this.selected = false,
  });

  final AppSkinIconSlot? slot;
  final Icon fallback;
  final bool selected;

  /// Shared action adapters can infer only these established action glyphs.
  /// Navigation always supplies a destination slot, independent of its order.
  static AppSkinIconSlot? commonSlot(IconData? icon) => switch (icon) {
    Icons.arrow_back ||
    Icons.arrow_back_rounded ||
    Icons.arrow_back_ios ||
    Icons.arrow_back_ios_new ||
    Icons.arrow_back_ios_new_rounded => AppSkinIconSlot.back,
    Icons.search ||
    Icons.search_rounded ||
    Icons.search_outlined => AppSkinIconSlot.search,
    Icons.more_vert ||
    Icons.more_vert_rounded ||
    Icons.more_horiz ||
    Icons.more_horiz_rounded => AppSkinIconSlot.more,
    Icons.close || Icons.close_rounded || Icons.clear => AppSkinIconSlot.close,
    Icons.arrow_forward ||
    Icons.arrow_forward_rounded ||
    Icons.arrow_forward_ios ||
    Icons.chevron_right ||
    Icons.chevron_right_rounded => AppSkinIconSlot.forward,
    Icons.settings ||
    Icons.settings_rounded ||
    Icons.settings_outlined => AppSkinIconSlot.settings,
    Icons.refresh || Icons.refresh_rounded => AppSkinIconSlot.refresh,
    Icons.add || Icons.add_rounded => AppSkinIconSlot.add,
    Icons.share ||
    Icons.share_rounded ||
    Icons.ios_share => AppSkinIconSlot.share,
    Icons.delete ||
    Icons.delete_rounded ||
    Icons.delete_outline => AppSkinIconSlot.delete,
    Icons.check ||
    Icons.check_rounded ||
    Icons.done ||
    Icons.done_rounded => AppSkinIconSlot.check,
    _ => null,
  };

  /// Preserve bespoke widgets and all original Icon properties in shared tools.
  static Widget adapt(Widget icon) =>
      icon is Icon && commonSlot(icon.icon) != null
      ? AppSkinIcon(fallback: icon)
      : icon;

  @override
  Widget build(BuildContext context) {
    final asset = AppSkinTheme.of(
      context,
    ).skin.icons[slot ?? commonSlot(fallback.icon)]?.resolve(selected);
    if (asset == null) return fallback;

    final iconTheme = IconTheme.of(context);
    final size = fallback.size ?? iconTheme.size ?? 24;
    final opacity =
        (iconTheme.opacity ?? 1) *
        (fallback.color ?? iconTheme.color ?? Colors.black).a;
    return Image(
      image: appSkinImageProvider(asset, Theme.of(context).brightness),
      width: size,
      height: size,
      fit: BoxFit.contain,
      opacity: AlwaysStoppedAnimation(opacity.clamp(0.0, 1.0)),
      semanticLabel: fallback.semanticLabel,
      excludeFromSemantics: fallback.semanticLabel == null,
      errorBuilder: (context, error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'app skin',
            context: ErrorDescription('loading skin icon ${asset.asset}'),
          ),
        );
        return fallback;
      },
    );
  }
}
