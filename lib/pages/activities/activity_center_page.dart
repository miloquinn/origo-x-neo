import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/account/member_account_controller.dart';
import '../../services/activities/activity.dart';
import '../../services/activities/activity_browser.dart';
import '../../services/core/app_distribution.dart';
import '../../utils/localization_extension.dart';
import '../../widgets/floating_subpage_scaffold.dart';
import '../account/account_page.dart';

class ActivityCenterPage extends StatefulWidget {
  const ActivityCenterPage({super.key, this.openDetail = openActivityDetail});

  final Future<bool> Function(Uri) openDetail;

  @override
  State<ActivityCenterPage> createState() => _ActivityCenterPageState();
}

class _ActivityCenterPageState extends State<ActivityCenterPage>
    with WidgetsBindingObserver {
  List<AppActivity>? _activities;
  bool _failed = false;
  int _generation = 0;
  String? _opening;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final request = ++_generation;
    setState(() {
      _activities = null;
      _failed = false;
    });
    try {
      final activities = await context
          .read<MemberAccountController>()
          .loadActivities();
      if (!mounted || request != _generation) return;
      final channel = AppDistribution.usesStoreBilling ? 'store' : 'official';
      setState(() {
        _activities = activities
            .where((activity) => activity.visibleFor(channel))
            .toList(growable: false);
      });
    } catch (_) {
      if (mounted && request == _generation) setState(() => _failed = true);
    }
  }

  Future<void> _openDetail(AppActivity activity) async {
    if (_opening != null) return;
    setState(() => _opening = activity.id);
    try {
      final locale = Localizations.localeOf(context);
      final traditional =
          locale.languageCode == 'zh' &&
          (locale.scriptCode == 'Hant' ||
              const ['TW', 'HK', 'MO'].contains(locale.countryCode));
      final uri = context.read<MemberAccountController>().activityDetailUri(
        activity,
        locale: traditional
            ? 'zh-TW'
            : locale.languageCode == 'zh'
            ? 'zh-CN'
            : 'en',
        dark: Theme.of(context).brightness == Brightness.dark,
      );
      if (!await widget.openDetail(uri)) {
        throw StateError('Browser unavailable');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.activityCenterOpenError)),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activities = _activities;
    return FloatingSubpageScaffold(
      title: l10n.activityCenterTitle,
      maxHeaderWidth: 760,
      actions: [
        FloatingSubpageAction(
          key: const ValueKey('activities-refresh'),
          tooltip: l10n.activityCenterRefresh,
          icon: Icons.refresh_rounded,
          onPressed: () => unawaited(_refresh()),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: floatingSubpagePadding(context, bottom: 40),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 24),
                      child: Text(
                        l10n.activityCenterSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                    if (_failed)
                      _ActivityFeedback(
                        icon: Icons.cloud_off_outlined,
                        title: l10n.activityCenterLoadError,
                        action: TextButton.icon(
                          key: const ValueKey('activities-retry'),
                          onPressed: () => unawaited(_refresh()),
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.retry),
                        ),
                      )
                    else if (activities == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (activities.isEmpty)
                      _ActivityFeedback(
                        icon: Icons.event_note_outlined,
                        title: l10n.activityCenterEmptyTitle,
                        message: l10n.activityCenterEmptyMessage,
                      )
                    else
                      for (final activity in activities) ...[
                        _ActivityCard(
                          activity: activity,
                          opening: _opening == activity.id,
                          onDetail: _opening == null
                              ? () => unawaited(_openDetail(activity))
                              : null,
                          onProgress: () => AccountPage.openReferral(context),
                        ),
                        const SizedBox(height: 20),
                      ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityFeedback extends StatelessWidget {
  const _ActivityFeedback({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
      child: Column(
        children: [
          Icon(icon, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.opening,
    required this.onDetail,
    required this.onProgress,
  });

  final AppActivity activity;
  final bool opening;
  final VoidCallback? onDetail;
  final VoidCallback onProgress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final dark = theme.brightness == Brightness.dark;
    final accent = switch (activity.accent) {
      'mint' => dark ? const Color(0xFF91D2B2) : const Color(0xFF28664F),
      'amber' => dark ? const Color(0xFFE5C282) : const Color(0xFF865D1A),
      _ => scheme.primary,
    };
    final state = switch (activity.state) {
      'upcoming' => l10n.activityCenterUpcoming,
      'paused' => l10n.activityCenterPaused,
      'ended' => l10n.activityCenterEnded,
      _ => l10n.activityCenterActive,
    };
    final date = activity.state == 'upcoming'
        ? activity.startsAt
        : activity.endsAt;
    final dateLabel = date == null
        ? null
        : DateFormat.yMMMd(l10n.localeName).format(date.toLocal());
    return Container(
      key: ValueKey('activity-${activity.id}'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    activity.kind == 'referral'
                        ? Icons.group_add_outlined
                        : Icons.campaign_outlined,
                    color: accent,
                    size: 28,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  state,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            activity.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -.5,
            ),
          ),
          if (activity.subtitle.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              activity.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
          if (dateLabel != null) ...[
            const SizedBox(height: 18),
            Text(
              activity.state == 'upcoming'
                  ? l10n.activityCenterStartsOn(dateLabel)
                  : l10n.activityCenterEndsOn(dateLabel),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final progress =
                  activity.kind == 'referral' &&
                  !AppDistribution.usesStoreBilling;
              final stacked =
                  constraints.maxWidth < 400 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3;
              final details = OutlinedButton.icon(
                key: ValueKey('activity-detail-${activity.id}'),
                onPressed: onDetail,
                icon: opening
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_outward_rounded, size: 18),
                label: Text(l10n.activityCenterLearnMore),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              );
              final progressButton = FilledButton.icon(
                key: ValueKey('activity-progress-${activity.id}'),
                onPressed: onProgress,
                icon: const Icon(Icons.trending_up_rounded, size: 19),
                label: Text(l10n.activityCenterProgress),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              );
              if (!progress) {
                return SizedBox(width: double.infinity, child: details);
              }
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    progressButton,
                    const SizedBox(height: 10),
                    details,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: progressButton),
                  const SizedBox(width: 12),
                  Expanded(child: details),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
