import 'package:flutter/material.dart';

import '../models/app_skin.dart';
import '../utils/app_skin_theme.dart';
import '../utils/app_skin_image_provider.dart';

/// A semantic skin slot with the original glyph as its compatibility contract.
/// Images keep their own colors; the caller owns layout, motion and actions.
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

  // Reserve room for larger artwork so neighboring labels can lay out around it.
  static const _artworkScale = 1.5;

  /// Shared controls resolve glyph aliases by meaning; navigation supplies its slot.
  static AppSkinIconSlot? commonSlot(IconData? icon) => switch (icon) {
    Icons.home ||
    Icons.home_rounded ||
    Icons.home_outlined ||
    Icons.home_sharp => AppSkinIconSlot.home,
    Icons.library_books ||
    Icons.library_books_rounded ||
    Icons.library_books_outlined ||
    Icons.library_books_sharp ||
    Icons.auto_stories ||
    Icons.auto_stories_rounded ||
    Icons.auto_stories_outlined ||
    Icons.auto_stories_sharp ||
    Icons.local_library ||
    Icons.local_library_rounded ||
    Icons.local_library_outlined ||
    Icons.local_library_sharp ||
    Icons.book ||
    Icons.book_rounded ||
    Icons.book_outlined ||
    Icons.book_sharp => AppSkinIconSlot.library,
    Icons.explore ||
    Icons.explore_rounded ||
    Icons.explore_outlined ||
    Icons.explore_sharp ||
    Icons.travel_explore ||
    Icons.travel_explore_rounded ||
    Icons.travel_explore_outlined ||
    Icons.travel_explore_sharp => AppSkinIconSlot.discover,
    Icons.auto_awesome ||
    Icons.auto_awesome_rounded ||
    Icons.auto_awesome_outlined ||
    Icons.auto_awesome_sharp ||
    Icons.smart_toy ||
    Icons.smart_toy_rounded ||
    Icons.smart_toy_outlined ||
    Icons.smart_toy_sharp ||
    Icons.auto_fix_high ||
    Icons.auto_fix_high_rounded ||
    Icons.auto_fix_high_outlined ||
    Icons.auto_fix_high_sharp => AppSkinIconSlot.ai,
    Icons.person ||
    Icons.person_rounded ||
    Icons.person_outlined ||
    Icons.person_sharp ||
    Icons.account_circle ||
    Icons.account_circle_rounded ||
    Icons.account_circle_outlined ||
    Icons.account_circle_sharp ||
    Icons.manage_accounts ||
    Icons.manage_accounts_rounded ||
    Icons.manage_accounts_outlined ||
    Icons.manage_accounts_sharp => AppSkinIconSlot.profile,
    Icons.arrow_back ||
    Icons.arrow_back_rounded ||
    Icons.arrow_back_outlined ||
    Icons.arrow_back_sharp ||
    Icons.arrow_back_ios ||
    Icons.arrow_back_ios_rounded ||
    Icons.arrow_back_ios_outlined ||
    Icons.arrow_back_ios_sharp ||
    Icons.arrow_back_ios_new ||
    Icons.arrow_back_ios_new_rounded ||
    Icons.arrow_back_ios_new_outlined ||
    Icons.arrow_back_ios_new_sharp ||
    Icons.chevron_left ||
    Icons.chevron_left_rounded ||
    Icons.chevron_left_outlined ||
    Icons.chevron_left_sharp => AppSkinIconSlot.back,
    Icons.search ||
    Icons.search_rounded ||
    Icons.search_outlined ||
    Icons.search_sharp ||
    Icons.manage_search ||
    Icons.manage_search_rounded ||
    Icons.manage_search_outlined ||
    Icons.manage_search_sharp => AppSkinIconSlot.search,
    Icons.more_vert ||
    Icons.more_vert_rounded ||
    Icons.more_vert_outlined ||
    Icons.more_vert_sharp ||
    Icons.more_horiz ||
    Icons.more_horiz_rounded ||
    Icons.more_horiz_outlined ||
    Icons.more_horiz_sharp => AppSkinIconSlot.more,
    Icons.close ||
    Icons.close_rounded ||
    Icons.close_outlined ||
    Icons.close_sharp ||
    Icons.clear ||
    Icons.clear_rounded ||
    Icons.clear_outlined ||
    Icons.clear_sharp ||
    Icons.cancel ||
    Icons.cancel_rounded ||
    Icons.cancel_outlined ||
    Icons.cancel_sharp => AppSkinIconSlot.close,
    Icons.arrow_forward ||
    Icons.arrow_forward_rounded ||
    Icons.arrow_forward_outlined ||
    Icons.arrow_forward_sharp ||
    Icons.arrow_forward_ios ||
    Icons.arrow_forward_ios_rounded ||
    Icons.arrow_forward_ios_outlined ||
    Icons.arrow_forward_ios_sharp ||
    Icons.chevron_right ||
    Icons.chevron_right_rounded ||
    Icons.chevron_right_outlined ||
    Icons.chevron_right_sharp => AppSkinIconSlot.forward,
    Icons.settings ||
    Icons.settings_rounded ||
    Icons.settings_outlined ||
    Icons.settings_sharp ||
    Icons.tune ||
    Icons.tune_rounded ||
    Icons.tune_outlined ||
    Icons.tune_sharp => AppSkinIconSlot.settings,
    Icons.refresh ||
    Icons.refresh_rounded ||
    Icons.refresh_outlined ||
    Icons.refresh_sharp => AppSkinIconSlot.refresh,
    Icons.add ||
    Icons.add_rounded ||
    Icons.add_outlined ||
    Icons.add_sharp ||
    Icons.add_circle ||
    Icons.add_circle_rounded ||
    Icons.add_circle_outlined ||
    Icons.add_circle_sharp ||
    Icons.add_circle_outline ||
    Icons.add_circle_outline_rounded ||
    Icons.add_circle_outline_outlined ||
    Icons.add_circle_outline_sharp => AppSkinIconSlot.add,
    Icons.share ||
    Icons.share_rounded ||
    Icons.share_outlined ||
    Icons.share_sharp ||
    Icons.ios_share ||
    Icons.ios_share_rounded ||
    Icons.ios_share_outlined ||
    Icons.ios_share_sharp => AppSkinIconSlot.share,
    Icons.delete ||
    Icons.delete_rounded ||
    Icons.delete_outlined ||
    Icons.delete_sharp ||
    Icons.delete_outline ||
    Icons.delete_outline_rounded ||
    Icons.delete_outline_outlined ||
    Icons.delete_outline_sharp ||
    Icons.delete_forever ||
    Icons.delete_forever_rounded ||
    Icons.delete_forever_outlined ||
    Icons.delete_forever_sharp => AppSkinIconSlot.delete,
    Icons.check ||
    Icons.check_rounded ||
    Icons.check_outlined ||
    Icons.check_sharp ||
    Icons.done ||
    Icons.done_rounded ||
    Icons.done_outlined ||
    Icons.done_sharp ||
    Icons.check_circle ||
    Icons.check_circle_rounded ||
    Icons.check_circle_outlined ||
    Icons.check_circle_sharp ||
    Icons.check_circle_outline ||
    Icons.check_circle_outline_rounded ||
    Icons.check_circle_outline_outlined ||
    Icons.check_circle_outline_sharp ||
    Icons.done_all ||
    Icons.done_all_rounded ||
    Icons.done_all_outlined ||
    Icons.done_all_sharp => AppSkinIconSlot.check,
    Icons.bookmark ||
    Icons.bookmark_rounded ||
    Icons.bookmark_outlined ||
    Icons.bookmark_sharp ||
    Icons.bookmark_border ||
    Icons.bookmark_border_rounded ||
    Icons.bookmark_border_outlined ||
    Icons.bookmark_border_sharp ||
    Icons.bookmark_added ||
    Icons.bookmark_added_rounded ||
    Icons.bookmark_added_outlined ||
    Icons.bookmark_added_sharp ||
    Icons.bookmarks ||
    Icons.bookmarks_rounded ||
    Icons.bookmarks_outlined ||
    Icons.bookmarks_sharp ||
    Icons.bookmark_add ||
    Icons.bookmark_add_rounded ||
    Icons.bookmark_add_outlined ||
    Icons.bookmark_add_sharp => AppSkinIconSlot.bookmark,
    Icons.format_list_bulleted ||
    Icons.format_list_bulleted_rounded ||
    Icons.format_list_bulleted_outlined ||
    Icons.format_list_bulleted_sharp ||
    Icons.list_alt ||
    Icons.list_alt_rounded ||
    Icons.list_alt_outlined ||
    Icons.list_alt_sharp ||
    Icons.menu ||
    Icons.menu_rounded ||
    Icons.menu_outlined ||
    Icons.menu_sharp ||
    Icons.menu_book ||
    Icons.menu_book_rounded ||
    Icons.menu_book_outlined ||
    Icons.menu_book_sharp => AppSkinIconSlot.catalog,
    Icons.headphones ||
    Icons.headphones_rounded ||
    Icons.headphones_outlined ||
    Icons.headphones_sharp ||
    Icons.headset ||
    Icons.headset_rounded ||
    Icons.headset_outlined ||
    Icons.headset_sharp ||
    Icons.graphic_eq ||
    Icons.graphic_eq_rounded ||
    Icons.graphic_eq_outlined ||
    Icons.graphic_eq_sharp ||
    Icons.record_voice_over ||
    Icons.record_voice_over_rounded ||
    Icons.record_voice_over_outlined ||
    Icons.record_voice_over_sharp => AppSkinIconSlot.readAloud,
    Icons.my_location ||
    Icons.my_location_rounded ||
    Icons.my_location_outlined ||
    Icons.my_location_sharp ||
    Icons.gps_fixed ||
    Icons.gps_fixed_rounded ||
    Icons.gps_fixed_outlined ||
    Icons.gps_fixed_sharp ||
    Icons.location_searching ||
    Icons.location_searching_rounded ||
    Icons.location_searching_outlined ||
    Icons.location_searching_sharp ||
    Icons.numbers ||
    Icons.numbers_rounded ||
    Icons.numbers_outlined ||
    Icons.numbers_sharp => AppSkinIconSlot.locate,
    Icons.play_arrow ||
    Icons.play_arrow_rounded ||
    Icons.play_arrow_outlined ||
    Icons.play_arrow_sharp ||
    Icons.play_circle ||
    Icons.play_circle_rounded ||
    Icons.play_circle_outlined ||
    Icons.play_circle_sharp ||
    Icons.play_circle_outline ||
    Icons.play_circle_outline_rounded ||
    Icons.play_circle_outline_outlined ||
    Icons.play_circle_outline_sharp => AppSkinIconSlot.play,
    Icons.pause ||
    Icons.pause_rounded ||
    Icons.pause_outlined ||
    Icons.pause_sharp ||
    Icons.pause_circle ||
    Icons.pause_circle_rounded ||
    Icons.pause_circle_outlined ||
    Icons.pause_circle_sharp ||
    Icons.pause_circle_outline ||
    Icons.pause_circle_outline_rounded ||
    Icons.pause_circle_outline_outlined ||
    Icons.pause_circle_outline_sharp => AppSkinIconSlot.pause,
    Icons.stop ||
    Icons.stop_rounded ||
    Icons.stop_outlined ||
    Icons.stop_sharp ||
    Icons.stop_circle ||
    Icons.stop_circle_rounded ||
    Icons.stop_circle_outlined ||
    Icons.stop_circle_sharp => AppSkinIconSlot.stop,
    Icons.skip_previous ||
    Icons.skip_previous_rounded ||
    Icons.skip_previous_outlined ||
    Icons.skip_previous_sharp => AppSkinIconSlot.previous,
    Icons.skip_next ||
    Icons.skip_next_rounded ||
    Icons.skip_next_outlined ||
    Icons.skip_next_sharp => AppSkinIconSlot.next,
    Icons.replay ||
    Icons.replay_rounded ||
    Icons.replay_outlined ||
    Icons.replay_sharp ||
    Icons.replay_5 ||
    Icons.replay_5_rounded ||
    Icons.replay_5_outlined ||
    Icons.replay_5_sharp ||
    Icons.replay_10 ||
    Icons.replay_10_rounded ||
    Icons.replay_10_outlined ||
    Icons.replay_10_sharp ||
    Icons.replay_30 ||
    Icons.replay_30_rounded ||
    Icons.replay_30_outlined ||
    Icons.replay_30_sharp ||
    Icons.fast_rewind ||
    Icons.fast_rewind_rounded ||
    Icons.fast_rewind_outlined ||
    Icons.fast_rewind_sharp => AppSkinIconSlot.rewind,
    Icons.forward_5 ||
    Icons.forward_5_rounded ||
    Icons.forward_5_outlined ||
    Icons.forward_5_sharp ||
    Icons.forward_10 ||
    Icons.forward_10_rounded ||
    Icons.forward_10_outlined ||
    Icons.forward_10_sharp ||
    Icons.forward_30 ||
    Icons.forward_30_rounded ||
    Icons.forward_30_outlined ||
    Icons.forward_30_sharp ||
    Icons.fast_forward ||
    Icons.fast_forward_rounded ||
    Icons.fast_forward_outlined ||
    Icons.fast_forward_sharp => AppSkinIconSlot.fastForward,
    Icons.speed ||
    Icons.speed_rounded ||
    Icons.speed_outlined ||
    Icons.speed_sharp => AppSkinIconSlot.speed,
    Icons.timer ||
    Icons.timer_rounded ||
    Icons.timer_outlined ||
    Icons.timer_sharp ||
    Icons.timer_off ||
    Icons.timer_off_rounded ||
    Icons.timer_off_outlined ||
    Icons.timer_off_sharp ||
    Icons.hourglass_empty ||
    Icons.hourglass_empty_rounded ||
    Icons.hourglass_empty_outlined ||
    Icons.hourglass_empty_sharp ||
    Icons.hourglass_bottom ||
    Icons.hourglass_bottom_rounded ||
    Icons.hourglass_bottom_outlined ||
    Icons.hourglass_bottom_sharp ||
    Icons.bedtime ||
    Icons.bedtime_rounded ||
    Icons.bedtime_outlined ||
    Icons.bedtime_sharp ||
    Icons.av_timer ||
    Icons.av_timer_rounded ||
    Icons.av_timer_outlined ||
    Icons.av_timer_sharp => AppSkinIconSlot.timer,
    Icons.volume_up ||
    Icons.volume_up_rounded ||
    Icons.volume_up_outlined ||
    Icons.volume_up_sharp ||
    Icons.volume_down ||
    Icons.volume_down_rounded ||
    Icons.volume_down_outlined ||
    Icons.volume_down_sharp => AppSkinIconSlot.volume,
    Icons.volume_off ||
    Icons.volume_off_rounded ||
    Icons.volume_off_outlined ||
    Icons.volume_off_sharp ||
    Icons.volume_mute ||
    Icons.volume_mute_rounded ||
    Icons.volume_mute_outlined ||
    Icons.volume_mute_sharp => AppSkinIconSlot.volumeOff,
    Icons.expand_more ||
    Icons.expand_more_rounded ||
    Icons.expand_more_outlined ||
    Icons.expand_more_sharp ||
    Icons.keyboard_arrow_down ||
    Icons.keyboard_arrow_down_rounded ||
    Icons.keyboard_arrow_down_outlined ||
    Icons.keyboard_arrow_down_sharp ||
    Icons.unfold_more ||
    Icons.unfold_more_rounded ||
    Icons.unfold_more_outlined ||
    Icons.unfold_more_sharp => AppSkinIconSlot.expand,
    Icons.expand_less ||
    Icons.expand_less_rounded ||
    Icons.expand_less_outlined ||
    Icons.expand_less_sharp ||
    Icons.keyboard_arrow_up ||
    Icons.keyboard_arrow_up_rounded ||
    Icons.keyboard_arrow_up_outlined ||
    Icons.keyboard_arrow_up_sharp ||
    Icons.unfold_less ||
    Icons.unfold_less_rounded ||
    Icons.unfold_less_outlined ||
    Icons.unfold_less_sharp => AppSkinIconSlot.collapse,
    Icons.remove ||
    Icons.remove_rounded ||
    Icons.remove_outlined ||
    Icons.remove_sharp ||
    Icons.remove_circle ||
    Icons.remove_circle_rounded ||
    Icons.remove_circle_outlined ||
    Icons.remove_circle_sharp ||
    Icons.remove_circle_outline ||
    Icons.remove_circle_outline_rounded ||
    Icons.remove_circle_outline_outlined ||
    Icons.remove_circle_outline_sharp => AppSkinIconSlot.remove,
    Icons.filter_alt ||
    Icons.filter_alt_rounded ||
    Icons.filter_alt_outlined ||
    Icons.filter_alt_sharp ||
    Icons.filter_alt_off ||
    Icons.filter_alt_off_rounded ||
    Icons.filter_alt_off_outlined ||
    Icons.filter_alt_off_sharp ||
    Icons.filter_list ||
    Icons.filter_list_rounded ||
    Icons.filter_list_outlined ||
    Icons.filter_list_sharp => AppSkinIconSlot.filter,
    Icons.sort ||
    Icons.sort_rounded ||
    Icons.sort_outlined ||
    Icons.sort_sharp ||
    Icons.sort_by_alpha ||
    Icons.sort_by_alpha_rounded ||
    Icons.sort_by_alpha_outlined ||
    Icons.sort_by_alpha_sharp ||
    Icons.swap_vert ||
    Icons.swap_vert_rounded ||
    Icons.swap_vert_outlined ||
    Icons.swap_vert_sharp => AppSkinIconSlot.sort,
    Icons.dashboard ||
    Icons.dashboard_rounded ||
    Icons.dashboard_outlined ||
    Icons.dashboard_sharp ||
    Icons.grid_view ||
    Icons.grid_view_rounded ||
    Icons.grid_view_outlined ||
    Icons.grid_view_sharp ||
    Icons.view_module ||
    Icons.view_module_rounded ||
    Icons.view_module_outlined ||
    Icons.view_module_sharp => AppSkinIconSlot.layoutGrid,
    Icons.view_list ||
    Icons.view_list_rounded ||
    Icons.view_list_outlined ||
    Icons.view_list_sharp => AppSkinIconSlot.layoutList,
    Icons.download ||
    Icons.download_rounded ||
    Icons.download_outlined ||
    Icons.download_sharp ||
    Icons.file_download ||
    Icons.file_download_rounded ||
    Icons.file_download_outlined ||
    Icons.file_download_sharp ||
    Icons.downloading ||
    Icons.downloading_rounded ||
    Icons.downloading_outlined ||
    Icons.downloading_sharp ||
    Icons.download_done ||
    Icons.download_done_rounded ||
    Icons.download_done_outlined ||
    Icons.download_done_sharp ||
    Icons.offline_pin ||
    Icons.offline_pin_rounded ||
    Icons.offline_pin_outlined ||
    Icons.offline_pin_sharp => AppSkinIconSlot.download,
    Icons.upload ||
    Icons.upload_rounded ||
    Icons.upload_outlined ||
    Icons.upload_sharp ||
    Icons.file_upload ||
    Icons.file_upload_rounded ||
    Icons.file_upload_outlined ||
    Icons.file_upload_sharp ||
    Icons.upload_file ||
    Icons.upload_file_rounded ||
    Icons.upload_file_outlined ||
    Icons.upload_file_sharp ||
    Icons.cloud_upload ||
    Icons.cloud_upload_rounded ||
    Icons.cloud_upload_outlined ||
    Icons.cloud_upload_sharp => AppSkinIconSlot.upload,
    Icons.folder ||
    Icons.folder_rounded ||
    Icons.folder_outlined ||
    Icons.folder_sharp ||
    Icons.folder_open ||
    Icons.folder_open_rounded ||
    Icons.folder_open_outlined ||
    Icons.folder_open_sharp => AppSkinIconSlot.folder,
    Icons.create_new_folder ||
    Icons.create_new_folder_rounded ||
    Icons.create_new_folder_outlined ||
    Icons.create_new_folder_sharp => AppSkinIconSlot.createFolder,
    Icons.drive_file_move ||
    Icons.drive_file_move_rounded ||
    Icons.drive_file_move_outlined ||
    Icons.drive_file_move_sharp => AppSkinIconSlot.moveFolder,
    Icons.edit ||
    Icons.edit_rounded ||
    Icons.edit_outlined ||
    Icons.edit_sharp ||
    Icons.mode_edit ||
    Icons.mode_edit_rounded ||
    Icons.mode_edit_outlined ||
    Icons.mode_edit_sharp ||
    Icons.drive_file_rename_outline ||
    Icons.drive_file_rename_outline_rounded ||
    Icons.drive_file_rename_outline_outlined ||
    Icons.drive_file_rename_outline_sharp ||
    Icons.border_color ||
    Icons.border_color_rounded ||
    Icons.border_color_outlined ||
    Icons.border_color_sharp => AppSkinIconSlot.edit,
    Icons.content_copy ||
    Icons.content_copy_rounded ||
    Icons.content_copy_outlined ||
    Icons.content_copy_sharp ||
    Icons.copy_all ||
    Icons.copy_all_rounded ||
    Icons.copy_all_outlined ||
    Icons.copy_all_sharp => AppSkinIconSlot.copy,
    Icons.note ||
    Icons.note_rounded ||
    Icons.note_outlined ||
    Icons.note_sharp ||
    Icons.note_add ||
    Icons.note_add_rounded ||
    Icons.note_add_outlined ||
    Icons.note_add_sharp ||
    Icons.note_alt ||
    Icons.note_alt_rounded ||
    Icons.note_alt_outlined ||
    Icons.note_alt_sharp ||
    Icons.sticky_note_2 ||
    Icons.sticky_note_2_rounded ||
    Icons.sticky_note_2_outlined ||
    Icons.sticky_note_2_sharp ||
    Icons.add_comment ||
    Icons.add_comment_rounded ||
    Icons.add_comment_outlined ||
    Icons.add_comment_sharp ||
    Icons.comment ||
    Icons.comment_rounded ||
    Icons.comment_outlined ||
    Icons.comment_sharp ||
    Icons.edit_note ||
    Icons.edit_note_rounded ||
    Icons.edit_note_outlined ||
    Icons.edit_note_sharp ||
    Icons.mode_comment ||
    Icons.mode_comment_rounded ||
    Icons.mode_comment_outlined ||
    Icons.mode_comment_sharp ||
    Icons.notes ||
    Icons.notes_rounded ||
    Icons.notes_outlined ||
    Icons.notes_sharp => AppSkinIconSlot.note,
    Icons.highlight ||
    Icons.highlight_rounded ||
    Icons.highlight_outlined ||
    Icons.highlight_sharp ||
    Icons.format_color_fill ||
    Icons.format_color_fill_rounded ||
    Icons.format_color_fill_outlined ||
    Icons.format_color_fill_sharp => AppSkinIconSlot.highlight,
    Icons.history ||
    Icons.history_rounded ||
    Icons.history_outlined ||
    Icons.history_sharp ||
    Icons.update ||
    Icons.update_rounded ||
    Icons.update_outlined ||
    Icons.update_sharp => AppSkinIconSlot.history,
    Icons.help ||
    Icons.help_rounded ||
    Icons.help_outlined ||
    Icons.help_sharp ||
    Icons.help_outline ||
    Icons.help_outline_rounded ||
    Icons.help_outline_outlined ||
    Icons.help_outline_sharp ||
    Icons.question_mark ||
    Icons.question_mark_rounded ||
    Icons.question_mark_outlined ||
    Icons.question_mark_sharp ||
    Icons.live_help ||
    Icons.live_help_rounded ||
    Icons.live_help_outlined ||
    Icons.live_help_sharp => AppSkinIconSlot.help,
    Icons.info ||
    Icons.info_rounded ||
    Icons.info_outlined ||
    Icons.info_sharp ||
    Icons.info_outline ||
    Icons.info_outline_rounded ||
    Icons.info_outline_sharp => AppSkinIconSlot.info,
    Icons.cloud ||
    Icons.cloud_rounded ||
    Icons.cloud_outlined ||
    Icons.cloud_sharp ||
    Icons.cloud_queue ||
    Icons.cloud_queue_rounded ||
    Icons.cloud_queue_outlined ||
    Icons.cloud_queue_sharp => AppSkinIconSlot.cloud,
    Icons.sync ||
    Icons.sync_rounded ||
    Icons.sync_outlined ||
    Icons.sync_sharp ||
    Icons.cloud_sync ||
    Icons.cloud_sync_rounded ||
    Icons.cloud_sync_outlined ||
    Icons.cloud_sync_sharp ||
    Icons.sync_alt ||
    Icons.sync_alt_rounded ||
    Icons.sync_alt_outlined ||
    Icons.sync_alt_sharp => AppSkinIconSlot.sync,
    Icons.save ||
    Icons.save_rounded ||
    Icons.save_outlined ||
    Icons.save_sharp ||
    Icons.save_alt ||
    Icons.save_alt_rounded ||
    Icons.save_alt_outlined ||
    Icons.save_alt_sharp => AppSkinIconSlot.save,
    Icons.restore ||
    Icons.restore_rounded ||
    Icons.restore_outlined ||
    Icons.restore_sharp ||
    Icons.settings_backup_restore ||
    Icons.settings_backup_restore_rounded ||
    Icons.settings_backup_restore_outlined ||
    Icons.settings_backup_restore_sharp ||
    Icons.restart_alt ||
    Icons.restart_alt_rounded ||
    Icons.restart_alt_outlined ||
    Icons.restart_alt_sharp => AppSkinIconSlot.restore,
    Icons.link ||
    Icons.link_rounded ||
    Icons.link_outlined ||
    Icons.link_sharp ||
    Icons.insert_link ||
    Icons.insert_link_rounded ||
    Icons.insert_link_outlined ||
    Icons.insert_link_sharp ||
    Icons.open_in_new ||
    Icons.open_in_new_rounded ||
    Icons.open_in_new_outlined ||
    Icons.open_in_new_sharp ||
    Icons.launch ||
    Icons.launch_rounded ||
    Icons.launch_outlined ||
    Icons.launch_sharp => AppSkinIconSlot.link,
    Icons.palette ||
    Icons.palette_rounded ||
    Icons.palette_outlined ||
    Icons.palette_sharp ||
    Icons.color_lens ||
    Icons.color_lens_rounded ||
    Icons.color_lens_outlined ||
    Icons.color_lens_sharp => AppSkinIconSlot.palette,
    Icons.text_fields ||
    Icons.text_fields_rounded ||
    Icons.text_fields_outlined ||
    Icons.text_fields_sharp ||
    Icons.format_size ||
    Icons.format_size_rounded ||
    Icons.format_size_outlined ||
    Icons.format_size_sharp ||
    Icons.font_download ||
    Icons.font_download_rounded ||
    Icons.font_download_outlined ||
    Icons.font_download_sharp ||
    Icons.text_format ||
    Icons.text_format_rounded ||
    Icons.text_format_outlined ||
    Icons.text_format_sharp => AppSkinIconSlot.font,
    Icons.image ||
    Icons.image_rounded ||
    Icons.image_outlined ||
    Icons.image_sharp ||
    Icons.photo ||
    Icons.photo_rounded ||
    Icons.photo_outlined ||
    Icons.photo_sharp ||
    Icons.wallpaper ||
    Icons.wallpaper_rounded ||
    Icons.wallpaper_outlined ||
    Icons.wallpaper_sharp => AppSkinIconSlot.image,
    Icons.devices ||
    Icons.devices_rounded ||
    Icons.devices_outlined ||
    Icons.devices_sharp ||
    Icons.smartphone ||
    Icons.smartphone_rounded ||
    Icons.smartphone_outlined ||
    Icons.smartphone_sharp ||
    Icons.phone_android ||
    Icons.phone_android_rounded ||
    Icons.phone_android_outlined ||
    Icons.phone_android_sharp ||
    Icons.phone_iphone ||
    Icons.phone_iphone_rounded ||
    Icons.phone_iphone_outlined ||
    Icons.phone_iphone_sharp ||
    Icons.tablet ||
    Icons.tablet_rounded ||
    Icons.tablet_outlined ||
    Icons.tablet_sharp ||
    Icons.computer ||
    Icons.computer_rounded ||
    Icons.computer_outlined ||
    Icons.computer_sharp => AppSkinIconSlot.device,
    Icons.key ||
    Icons.key_rounded ||
    Icons.key_outlined ||
    Icons.key_sharp ||
    Icons.vpn_key ||
    Icons.vpn_key_rounded ||
    Icons.vpn_key_outlined ||
    Icons.vpn_key_sharp ||
    Icons.password ||
    Icons.password_rounded ||
    Icons.password_outlined ||
    Icons.password_sharp => AppSkinIconSlot.key,
    Icons.extension ||
    Icons.extension_rounded ||
    Icons.extension_outlined ||
    Icons.extension_sharp => AppSkinIconSlot.extension,
    Icons.language ||
    Icons.language_rounded ||
    Icons.language_outlined ||
    Icons.language_sharp ||
    Icons.public ||
    Icons.public_rounded ||
    Icons.public_outlined ||
    Icons.public_sharp ||
    Icons.wifi ||
    Icons.wifi_rounded ||
    Icons.wifi_outlined ||
    Icons.wifi_sharp ||
    Icons.network_check ||
    Icons.network_check_rounded ||
    Icons.network_check_outlined ||
    Icons.network_check_sharp => AppSkinIconSlot.network,
    _ => null,
  };

  /// Adapt only an Icon leaf; bespoke content and its ownership stay intact.
  static Widget adapt(Widget icon, {bool? selected}) =>
      icon is Icon && commonSlot(icon.icon) != null
      ? AppSkinIcon(
          fallback: icon,
          selected: selected ?? _selectedGlyph(icon.icon),
        )
      : icon;

  static bool _selectedGlyph(IconData? icon) => switch (icon) {
    Icons.bookmark ||
    Icons.bookmark_rounded ||
    Icons.bookmark_sharp ||
    Icons.bookmark_added ||
    Icons.bookmark_added_rounded ||
    Icons.bookmark_added_sharp ||
    Icons.graphic_eq ||
    Icons.graphic_eq_rounded ||
    Icons.graphic_eq_outlined ||
    Icons.graphic_eq_sharp => true,
    _ => false,
  };

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
    final image = Image(
      image: appSkinImageProvider(asset, Theme.of(context).brightness),
      width: size * _artworkScale,
      height: size * _artworkScale,
      fit: BoxFit.contain,
      matchTextDirection: fallback.icon?.matchTextDirection ?? false,
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
    return fallback.textDirection == null
        ? image
        : Directionality(textDirection: fallback.textDirection!, child: image);
  }
}
