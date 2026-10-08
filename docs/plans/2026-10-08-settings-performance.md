# Settings performance and maintenance

## Scope and behavior lock

Optimize the settings hub and its four categories, account-card invalidation,
and the account-to-global-settings notification boundary. Preserve navigation,
theme/glass appearance, translations, large text, membership access/revocation,
and existing preference keys/defaults. Preserve unrelated work in this checkout.

Baseline: settings_page_test + settings_page_preferences_test passed (22 tests).
No new dependencies, device installation, release, or visual redesign.

## Findings and ordered cleanup

1. Full ThemeNotifier/AppSettingsNotifier subscriptions invalidate every category.
   WebDAV transfer notifications also invalidate unrelated categories and the hub.
   Replace these with category-specific value selections and a selector for the
   hub's data-sync row. Keep live changes to displayed state observable.
2. Every account notification is forwarded by AppSettingsNotifier even when
   advanced-feature access is unchanged. Only broadcast membership access changes;
   project the account card's displayed values rather than the full controller.
3. Preferences and content-services each load both preferences and AI configuration.
   Separate category initialization. Preference switches must wait for their data;
   a slow/failed AI configuration must not delay or overwrite reading preferences.
4. Category ListView contains one large Column, so all sections are laid out as one
   item. Give sections independent lazy list items, retaining width/padding/spacing.
5. Hidden developer/cover/interval fields only mirror persistence. Keep these in
   the loaded immutable preference snapshot; remove duplicate page fields. A glass
   switch already saves through ThemeNotifier and must not save page preferences.

Avoid speculative font-service caching or a new generic settings architecture.
These widen invalidation/storage contracts beyond the demonstrated problem.

## Fallback inventory

- Default reader palette: grounded compatibility boundary; retain.
- Version fallback after platform-info failure: grounded display fail-safe; retain.
- Cache usage error: current loading state is cleared; retain existing behavior.
- Legacy preference defaults/migration and hidden values: persisted compatibility
  boundary; retain and verify preservation during visible switch saves.
- No new silent errors, skipped assertions, or alternate execution paths.

## Evaluator and acceptance

Command: flutter test --no-pub test/settings_performance_test.dart --reporter expanded

Count actual widget rebuilds under 30 notifications with a pump per event. The hub
and unrelated categories must have zero full-content rebuilds for unrelated app,
theme, account and WebDAV progress notifications. Account-card content must ignore
events that do not change displayed state. Global settings must ignore account
events that do not change advanced-feature access. Relevant busy/configuration,
theme and entitlement changes must still update the UI immediately.

Category IO must be hub=none; preferences=preferences only; content=AI only;
dataSync=cache only; about=version only. Delayed preference loading must not allow
default values to overwrite stored settings. Visible toggles preserve hidden values.
Section list items should avoid mounting the final preferences section before it
enters the viewport/cache extent, and remain reachable by scrolling.

Record baseline and optimized results. This is an unnecessary-work evaluator,
not a GPU/frame-rate benchmark. The connected phone does not substitute for the
reported tablet: physical scrolling, animation/raster timings remain a device gap.

Run settings/premium/tablet/navigation suites in separate processes, preference
and global settings suites, flutter analyze --no-pub, and scoped git diff --check.

## Architecture decision

Principles: preserve behavior; select immutable displayed values; load only owned
data; reuse existing Provider/preferences boundaries; prefer deletion.
Drivers: eliminate repeat work, prevent stale UI, keep changes locally maintainable.
Options: (A) scoped subscriptions/loaders/lazy sections within the existing design;
(B) replace the settings feature with new controllers/view models. Choose A because
B introduces migration risk and extra abstractions without measured benefit.
Tradeoff: explicit selected fields must be updated when a new displayed value is
added; regression tests cover relevant-state updates and irrelevant-state isolation.

## Execution guards and file ownership

- Select primitive records: font IDs/display labels/count, scale/locale/layout,
  theme mode/accent/style, advanced access and gated flags. Account projection uses
  effectiveName/username/avatarUrl/loading and effective membership tier. Never
  select regenerated FontOption or mutable MemberAccountSummary objects directly.
- Lazy sections are WidgetBuilder closures invoked only by ListView.itemBuilder,
  without constructing a list of widgets beforehand.
- Keep one loaded SettingsPagePreferences snapshot for hidden fields. Page-owned
  switches and the reader-style picker wait for readiness; glass persists only via
  ThemeNotifier. Retain the full-save storage interface and all preference keys.
- Explicit grant/revoke tests verify AdvancedFeatureAccess and
  BookSourceNetworkPolicy as well as zero broadcasts for 30 no-op account events.
  WebDAV configuration and busy transitions update the row; progress does not.

Modification map: settings_page.dart owns initialization/selection/readiness;
settings_hub_part.dart owns row selection and lazy categories;
settings_layout_part.dart owns the data-sync busy projection/reader-style readiness;
settings_appearance_part.dart removes glass save and duplicate font-count reads;
settings_about_part.dart permits disabling a loading preference action;
app_settings_service.dart owns membership notification gating;
settings_account_card.dart owns primitive account projection;
settings_performance_test.dart and app_settings_library_layout_test.dart own
regressions. settings_page_preferences.dart remains the existing, unchanged full
storage boundary. No home-shell or shader changes.

Review cycle 1: architecture approves scoped option A with the guards above;
critic requested these guards be explicit in this artifact. They are now recorded.

Review cycle 2: architecture APPROVE/CLEAR, followed by critic APPROVE.
The user's optimization instruction authorizes direct implementation of this
reviewed, reversible scope. Implementation and evaluator now pass; final code
review APPROVE. See docs/reviews/2026-10-08-settings-performance-validation.md
for exact results, remaining repository lint notices and device-validation gaps.
