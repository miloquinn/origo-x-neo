# Shared spring glass button validation

历史记录：本文描述标题日期对应的实现与交付，不作为当前待办或配置说明。当前维护入口为 [共用玻璃材质](../glass-material.md)。

The existing floating navigation spring is now reused by chrome actions. This change preserves role sizes and native interaction, replaces duplicate toolbar decoration/gesture code, and repairs liquid refraction coordinates while retaining stationary layout and popup anchors.

## Scope and simplifications

- `glass_buttons.dart`: common native icon and content-width text controls, one material/motion frame, compact 44 px toolbar role. Existing `FloatingSubpageAction` is the 48 px role; `ReaderControlIconButton` is the reader palette adapter.
- Home and Library chrome: toolbar, filter, import/add, close and select-all share these controls; filter menu anchors remain based on resting layout rectangles.
- Secondary pages: debug, clear, selection close, save and reset use the shared header controls. Reader more/locate/auto-page actions, image page jump, and loading/error back controls also reuse them.
- Image-reader bottom actions and text-selection actions also reuse the text capsule with compact role padding. Selection actions retain their 72 px minimum width and disabled foreground; selection overflow uses a glass surface under the existing menu spring.
- Popup circular triggers reuse the native glass icon implementation with its inner spring disabled; the route keeps one outer spring. Moving menus remain opaque.
- Custom menu triggers retain button/enabled/tap accessibility semantics. Menu item projection preserves explicit and inherited ListTile foreground colors, keeping a dark reader's popup readable inside a light application theme.
- `GlassTopBar` uses Flutter `NavigationToolbar` to reserve actual text action widths rather than estimating every action at 48 px.
- Liquid backdrop geometry uses the real Layer transform chain and paint offset. Shader coordinates include device scale and paint-only spring transforms; RenderObject coordinates, hit targets and popup anchors do not move.
- Glass background is an ignored visual layer below the full-size native control. Native minimum sizes are explicit, including full 44/48 px edge activation and centered icons. Reader borders remain derived from `ReaderThemePalette`, independent of an outer App theme.
- No dependencies added. Unsupported shader/high-contrast/singular-matrix lightweight blur and glass-off/material solid branches remain intentional compatibility/readability behavior.

Ordinary form buttons, source choice chips and navigation selection lens interactions are outside this migration.

## Verification

The pre-edit baseline passed 44 tests in seven isolated Flutter processes. The additional reader controls passed 23 existing assertions before migration. Final verification in the task-only worktree passed **158 tests in 25 isolated processes**:

| Area | Passed |
| --- | ---: |
| Glass button interaction, targets, keyboard/cancel, reduced motion, materials and text scaling | 7 |
| Subpage navigation and measured text action width | 6 |
| Popup menus, spring count, resting anchors, semantics, foreground projection and disabled/focus/keyboard | 20 |
| Shared glass and liquid surfaces | 11 |
| Elastic press and composited coordinate geometry | 6 |
| Reader chrome/palette and auto-page controls | 13 |
| Tablet shell, library, detailed stats, source glass controls | 14 |
| Source edit/debug, replace rules, TXT editor, custom themes, image reader | 37 |
| Native reader auto-page scenarios | 11 |
| Shared/standalone navigation selection lens regressions | 18 |
| Annotated text selection and four-action image chrome, including 320 px / 2x text | 15 |

`flutter analyze --no-pub --no-fatal-infos` exited 0. The same three existing informational diagnostics remain in source chapter state, cookie rethrow handling, and an offline reader license test import. Formatting and `git diff --check` passed.

A native auto-page suite still exhibits an existing process-state leak: the last continuous EPUB test can time out loading after the preceding ten tests, then passes alone. All eleven assertions remain active: the final scenario ran in its own Flutter process, and the preceding ten ran with an explicit complementary name filter. This is test infrastructure evidence, not a product-build failure.

The shared working checkout also experienced a native-assets manifest collision during simultaneous Flutter commands. Final tests ran serially in `/Users/xiaoyuan/.codex/worktrees/shared-glass-buttons/origo-x`, containing only this task's changes, to avoid unrelated edits and build-directory interference.

## Actual GPU evidence

Nineteen captures under `docs/previews/shared-glass-buttons-20261008/` came from production widgets on iOS 27 / iPhone 18 Pro Max simulator / Impeller. PointerDown/Move/Up drove actual spring states. Final screenshots cover liquid opacity 0/0.5/1, light/dark, frosted light/dark, solid mode, reduced motion and 1.8x text. Seven reader captures add the full image chrome and selection toolbar at 390/320 px, with a dark reader inside a light application and the overflow menu pressed/open/dismissed.

Final visual verdict: pass. Native icons are centered. Pressed/pulled liquid rim and refraction follow the visible button, and the released image equals the resting image byte for byte. Disabled foreground is dimmed once; reader custom dark colors remain readable. An intermediate native icon paint-size regression was rejected and corrected with explicit native minimum dimensions before the final captures.

The real reader captures exposed a menu projection that discarded ListTile foreground colors. The shared menu projection now honors explicit/inherited colors, and actual RenderParagraph/IconTheme regressions lock readability. Flutter's native selection overflow button also receives the reader foreground through IconButtonTheme. The final popup uses readable light glyphs on the pure-black reader surface; dismiss returns to the original image without residual route pixels.

Task changes were projected into the isolated checkout from exact owned hunks. Unrelated nested-bookshelf/cache work in the shared checkout is preserved and excluded from the task commit. The device acceptance build must use the current shared source so it retains the latest database schema; product build and device receipts are recorded below after delivery.

## Coordinated device delivery

The user authorized coordination after another task's old installation replaced newer features. Both `新增书架嵌套分组` and `优化在线书籍加载速度` confirmed their final changes are present in the shared main checkout, with no remaining product changes or independent device installations. The combined build includes the shared glass controls, nested bookshelf v28 migration/backup, and online startup/shared cache improvements. The task-only checkout supplies only the button commit.

- Product build: iOS Release succeeded (90.5 s, 58.8 MB) from shared `lib/main.dart`, direct channel, build `261008003`. The 679-file source manifest was identical before and after compilation: `a0b19e21e29392c118b104bcc907ed0eb77b6fba5acf72f7859efa1f7c878c02`.
- Signature: deep/strict codesign verification passed. AOT SHA-256: `669ae7b79c327b01c1a7fda58b78db513b95fd57b869716d61363e411a50b91f`. The liquid shader asset is included (3888 bytes).
- Device: SloanePro, iPhone 16 Pro, `00008140-001979421E93001C`. Before installation it reported `261008001`; in-place installation succeeded and readback confirms `com.niki.xxread / 2.7.3 / 261008003 / builtByDeveloper=true`. No uninstall or data clear was performed.
- Channel: local development-signed Release for acceptance, separate from TestFlight/App Store distribution.
- Launch: the initial attempt was blocked by iOS `Locked`. After the user unlocked the device, foreground launch succeeded (`activatedWhenStarted=true`, PID `14018`). Process readback matches the exact installed bundle URL and PID.
- Receipts and immutable signed bundle: local ignored `build/device-ios/shared-glass-buttons-20261008/`. Physical touch/gesture acceptance, real-source loading latency and multi-device folder backup remain manual acceptance boundaries.
