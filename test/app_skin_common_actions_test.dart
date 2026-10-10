import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/widgets/app_skin_icon.dart';

void main() {
  test('shared title and reader controls resolve semantic artwork slots', () {
    final actions = <IconData, String>{
      Icons.bookmark_border_rounded: 'bookmark',
      Icons.format_list_bulleted: 'catalog',
      Icons.headphones: 'readAloud',
      Icons.graphic_eq: 'readAloud',
      Icons.auto_awesome_outlined: 'ai',
      Icons.my_location: 'locate',
      Icons.play_arrow_rounded: 'play',
      Icons.pause_rounded: 'pause',
      Icons.stop_rounded: 'stop',
      Icons.skip_previous_rounded: 'previous',
      Icons.skip_next_rounded: 'next',
      Icons.replay_10_rounded: 'rewind',
      Icons.forward_10_rounded: 'fastForward',
      Icons.speed: 'speed',
      Icons.timer_outlined: 'timer',
      Icons.volume_up_rounded: 'volume',
      Icons.volume_off_rounded: 'volumeOff',
      Icons.expand_more: 'expand',
      Icons.expand_less: 'collapse',
      Icons.remove_rounded: 'remove',
      Icons.filter_alt_outlined: 'filter',
      Icons.sort: 'sort',
      Icons.dashboard: 'layoutGrid',
      Icons.view_list: 'layoutList',
      Icons.downloading: 'download',
      Icons.upload_file: 'upload',
      Icons.create_new_folder: 'createFolder',
      Icons.drive_file_move: 'moveFolder',
      Icons.edit_outlined: 'edit',
      Icons.content_copy: 'copy',
      Icons.note_add_outlined: 'note',
      Icons.note_alt_rounded: 'note',
      Icons.highlight: 'highlight',
      Icons.history: 'history',
      Icons.question_mark: 'help',
      Icons.info_outline: 'info',
      Icons.cloud_outlined: 'cloud',
      Icons.sync: 'sync',
      Icons.save_outlined: 'save',
      Icons.restore: 'restore',
      Icons.link: 'link',
      Icons.palette_outlined: 'palette',
      Icons.text_fields: 'font',
      Icons.image_outlined: 'image',
      Icons.devices: 'device',
      Icons.phone_android_rounded: 'device',
      Icons.key: 'key',
      Icons.extension: 'extension',
      Icons.language: 'network',
    };
    for (final action in actions.entries) {
      expect(
        AppSkinIcon.commonSlot(action.key)?.name,
        action.value,
        reason: 'Control ${action.key} must not silently keep a platform glyph',
      );
    }
  });

  test('explicit selection takes priority over filled-glyph inference', () {
    const filled = Icon(Icons.bookmark_rounded);
    expect((AppSkinIcon.adapt(filled) as AppSkinIcon).selected, isTrue);
    expect(
      (AppSkinIcon.adapt(filled, selected: false) as AppSkinIcon).selected,
      isFalse,
    );
    expect(
      (AppSkinIcon.adapt(const Icon(Icons.graphic_eq)) as AppSkinIcon).selected,
      isTrue,
    );
    expect(
      (AppSkinIcon.adapt(const Icon(Icons.bookmark_border)) as AppSkinIcon)
          .selected,
      isFalse,
    );
  });

  test(
    'specialized reader modes keep their precise glyph until a slot exists',
    () {
      for (final glyph in [
        Icons.south,
        Icons.vertical_align_top,
        Icons.vertical_align_bottom,
        Icons.keyboard_double_arrow_down,
        Icons.touch_app,
        Icons.animation,
        Icons.folder_copy,
        Icons.title_rounded,
        Icons.swap_calls,
        Icons.format_underlined_rounded,
      ]) {
        final icon = Icon(glyph);
        expect(AppSkinIcon.commonSlot(glyph), isNull);
        expect(AppSkinIcon.adapt(icon), same(icon));
      }
    },
  );

  test('bespoke provider and progress widgets keep their identity', () {
    const provider = Icon(IconData(0x1234, fontFamily: 'ProviderIdentity'));
    const loading = CircularProgressIndicator();
    expect(AppSkinIcon.adapt(provider), same(provider));
    expect(AppSkinIcon.adapt(loading), same(loading));
  });
}
