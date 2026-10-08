# Shared spring glass controls

The user wants the floating navigation bar's spring response on other chrome controls, especially header back and trailing actions. Reuse shared controls by role and size, retain frosted and liquid materials and the existing liquid opacity preference.

## Bounded cleanup plan

1. Lock current behavior before replacing callers. Baseline: elastic press, floating subpage scaffold, glass surface, app menu, reader chrome, tablet shell and library suites run in separate Flutter processes; 44 assertions passed.
2. Reuse `ElasticPress` and `GlassControlSurface` in shared native button implementations. Keep the existing 48 px `FloatingSubpageAction` role, introduce the 44 px toolbar role and a text capsule role; retain the reader palette adapter. Keep tap, disabled, focus, keyboard, tooltip and menu anchor contracts.
3. Replace duplicated header/library controls and uncovered header actions. Do not migrate ordinary form controls, selection chips or navigation indicators. Moving popup menu surfaces stay opaque, and menu triggers retain a single spring wrapper. Already-filtered headers must not add another backdrop filter.
4. Repair liquid shader geometry at the compositing boundary: collect the actual layer transform plus paint offset. Preserve paint-only spring layout, hit testing, semantics and resting popup coordinates; do not mutate RenderObject coordinate semantics.
5. Test dimensions, activation, disabled/reduced motion, palette/material choices and stationary anchors. Run stateful suites in isolated processes. Inspect actual Impeller captures of frosted/liquid/light/dark controls at rest, while pressed and pulled, and at different liquid opacity values.
6. Build the final iOS application sequentially after simulator work stops, install in place on SloanePro, verify identity and successful launch, then commit and push the bounded change using Lore trailers.

## Fallback inventory

The liquid renderer keeps its documented lightweight blur when a backend cannot support shader image filters, an asset load fails, high contrast is requested, or an affine matrix is singular. These are narrow compatibility/readability boundaries with existing fallback tests and diagnostics; retain them. App material style and the glass-off preference deliberately select a solid surface. This migration adds no swallowed errors, silent action defaults or alternate gesture paths.

## Contract

- Header/back control: 48 px target; preserve existing 28 px back and 30 px action icons.
- Toolbar control: 44 px target and 20 px icons; highlighted state remains visible through both glass modes.
- Text capsule: minimum 44 px target, content-driven width; respect text scaling.
- Reader icon control: 44 px target, 22 px icon and reader-derived palette.
- All controls share spring timing; role adapters determine size and color. Native interactive widgets retain semantic, focus and keyboard behavior.
- Optical coordinates follow the composited visual transform. Layout and popup anchors remain at rest.
- No new dependencies; remove replaced decoration/gesture duplication and avoid stacked spring wrappers.

## Ownership and evidence

Unrelated nested-bookshelf work appeared during this task in DESIGN.md, book/database files and shelf folder files. Preserve it and exclude it from this task's commit. Validation and delivery evidence will be recorded in a separate review document.

## Reader completion and coordinated delivery

The reader audit found two remaining groups: image-reader bottom actions and the text-selection toolbar. Run their existing regressions before replacing their InkResponse/InkWell decoration with the existing text capsule. Preserve compact padding, the 72 px selection-action minimum width, reader palette, disabled actions and menu callbacks. The selection overflow trigger uses the existing menu spring and a non-interactive glass surface; avoid a second spring. Add targeted assertions for role dimensions, palette/material, single motion wrapper and callbacks.

The user authorized coordination with the nested-bookshelf and online-loading chats after a separate installation overwrote newer features. Those chats must finish code in the shared main checkout and stop individual device deliveries. Build the final combined main checkout once all three changes are ready, compare source manifests before and after the build, then install in place and verify version and launch on SloanePro. The task-only worktree remains the source of the bounded button commit; unrelated changes are included in device acceptance but excluded from this task's commit.
