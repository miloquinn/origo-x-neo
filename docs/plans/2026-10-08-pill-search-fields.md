# Shared pill search fields

## Evidence and scope

The user asks every search/filter field to share the rounded appearance of the AI reader input and floating navigation. The AI input uses a 52 px starting height and centered icons/text; navigation uses a full-height rounded superellipse. Inventory found 18 real search/filter fields: 15 in source/settings screens, plus Library, reader catalog and reader full-text search. Debug URL/keyword parameters and ordinary forms retain their distinct jobs. The user subsequently requested both AI composers to adopt the same glass pill shell while retaining their message-editing and sending behavior.

## Cleanup plan before edits

1. Lock search behavior with existing page regressions before migrations; run stateful suites in separate Flutter processes. Preserve keys on native TextField, focus, submit, debounce/cancellation, controller listeners, counters, resubmit actions and selection scope.
2. Add one native `PillSearchField`. Use a fully rounded superellipse, minimum height 52 with room to grow for large text, centered search icon, editable content and minimum 44 px clear/action targets. Reuse GlassControlSurface and material configuration; keep reader palette overrides explicit and do not add a whole-field press gesture that interferes with editing.
3. Replace decorative wrappers/duplicates by lane: sources; settings; Library/reader. Pages keep business query state, timers and async work. The field owns only optional editing/focus nodes and clear-button visibility; it never performs or debounces a query. Custom clear callbacks retain their existing side effects.
4. Verify native interaction, caller/controller replacement ownership, programmatic edits, disabled state, keyboard/RTL, glass modes, dark reader inside light app and narrow/large-text layout. Re-run affected page suites after replacement and inspect production-widget Impeller scenes.
5. Validate the bounded diff without unrelated folder/cache edits. Build the current shared main source for device delivery, compare pre/post source manifests, install in place on SloanePro and verify identity/launch. Preserve the three previously combined features.

## Fallback inventory

Shared glass has narrow existing compatibility branches for unsupported shaders, accessibility/performance controls and explicit material/solid mode. Reuse these tested boundaries. No new silent defaults, swallowed query errors, alternate query paths or dependencies are introduced. Default clearing updates native editing and calls onChanged once; supplied clear callbacks retain ownership of query reset/cancellation.

## Ownership

Root owns the shared field, Library/reader adapters, design/validation records and final delivery. Native agents handle bounded source/settings migration or read-only inventory. Unrelated nested-bookshelf and online-cache working changes remain intact and outside this task's commit.

## AI composer extension

Before edits, lock the reader AI and tablet AI layouts with their existing regressions. Extract only the shared background/minimum-height/shape/focus-border into `PillInputSurface`; search fields and both original AI rows use it. Preserve native multiline bounds, send keyboard action, enabled/sending state, attachment picker, keys, context and callbacks. Keep AI shadows and reader colors, remove the duplicated blur/26px wrapper. Recheck search ownership/layout tests and real Impeller captures, including multiline composer growth and glass-off branch.

## 复核中的动态避让修复

- 多行/大字号回归先复现 Reader 固定 72px 留白不足，以及全局 AI 仅父 build 时测量、漏掉原生编辑器内部增高的问题。
- 共享 `MeasuredSize` 从实际 RenderProxyBox 布局变化报告整个悬浮输入区尺寸；两 AI 列表按实际高度避让，沿用贴底时跟随最新消息、阅读历史时不强制跳转的行为。
- 长 Markdown 回答滚到底后必须完全位于输入区上方；补充到已有大字号多行和键盘回归中。
