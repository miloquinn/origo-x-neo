// 文件说明：登录方式摘要、账号操作、会员支持与推荐关系界面。
// 技术要点：同一账号功能库内的私有实现拆分，不扩大公开 API。

part of '../account_page.dart';

class _LoginMethodsCard extends StatelessWidget {
  const _LoginMethodsCard({required this.user});

  final MemberUser user;

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: context.l10n.accountSignInMethodsTitle,
    icon: Icons.shield_outlined,
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: user.authMethods
          .map(
            (method) => Chip(
              avatar: const Icon(Icons.check_circle_rounded, size: 17),
              label: Text(_methodLabel(context, method)),
            ),
          )
          .toList(growable: false),
    ),
  );

  String _methodLabel(BuildContext context, String method) => switch (method) {
    'github' => 'GitHub',
    'google' => 'Google',
    'apple' => 'Apple',
    'passkey' => 'Passkey',
    'password' => context.l10n.accountPassword,
    'email_code' => context.l10n.accountEmail,
    _ => method,
  };
}

class _AccountActionsCard extends StatelessWidget {
  const _AccountActionsCard({
    required this.user,
    required this.onEditProfile,
    required this.onOpenSecurity,
    required this.onOpenReferral,
    required this.onOpenActivities,
    required this.onOpenSupport,
  });

  final MemberUser user;
  final VoidCallback onEditProfile;
  final VoidCallback onOpenSecurity;
  final VoidCallback onOpenReferral;
  final VoidCallback onOpenActivities;
  final VoidCallback onOpenSupport;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: user.effectiveName,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AccountActionTile(
                key: const ValueKey('account-edit-profile'),
                icon: Icons.person_outline_rounded,
                title: context.l10n.accountEditProfile,
                onTap: onEditProfile,
              ),
              const Divider(height: 1),
              _AccountActionTile(
                key: const ValueKey('account-security'),
                icon: Icons.shield_outlined,
                title: context.l10n.accountSecurityTitle,
                onTap: onOpenSecurity,
              ),
              if (!AppDistribution.usesStoreBilling) ...[
                const Divider(height: 1),
                _AccountActionTile(
                  key: const ValueKey('account-referral'),
                  icon: Icons.group_add_rounded,
                  title: context.l10n.accountInviteTitle,
                  onTap: onOpenReferral,
                ),
              ],
              const Divider(height: 1),
              _AccountActionTile(
                key: const ValueKey('account-activities'),
                icon: Icons.local_activity_outlined,
                title: context.l10n.activityCenterTitle,
                onTap: onOpenActivities,
              ),
              const Divider(height: 1),
              _AccountActionTile(
                key: const ValueKey('account-support'),
                icon: Icons.receipt_long_outlined,
                title: context.l10n.premiumAccountBindingTitle,
                onTap: onOpenSupport,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountReferralPage extends StatefulWidget {
  const _AccountReferralPage();

  @override
  State<_AccountReferralPage> createState() => _AccountReferralPageState();
}

class _AccountReferralPageState extends State<_AccountReferralPage>
    with WidgetsBindingObserver {
  bool _refreshing = true;
  String? _error;
  int _refreshRequest = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final request = ++_refreshRequest;
    setState(() {
      _refreshing = true;
      _error = null;
    });
    try {
      await context.read<MemberAccountController>().loadReferral();
    } catch (error) {
      if (mounted && request == _refreshRequest) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted && request == _refreshRequest) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<MemberAccountController>(
    builder: (context, account, child) {
      final campaign = account.referral?.campaign;
      return FloatingSubpageScaffold(
        title: context.l10n.accountInviteTitle,
        body: ListView(
          padding: floatingSubpagePadding(context, bottom: 40),
          children: [
            if (_refreshing)
              const Center(child: CircularProgressIndicator())
            else if (_error != null || campaign == null)
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_error ?? context.l10n.accountInviteUnavailable),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const ValueKey('account-invite-retry'),
                      onPressed: _refreshing ? null : _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(context.l10n.retry),
                    ),
                  ],
                ),
              )
            else
              _ReferralCard(account: account, campaign: campaign),
          ],
        ),
      );
    },
  );
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  /// 破坏性入口用错误色标出来，避免和普通设置项看起来一样。
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = destructive
        ? scheme.errorContainer
        : scheme.primaryContainer;
    final foreground = destructive
        ? scheme.onErrorContainer
        : scheme.onPrimaryContainer;
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        minTileHeight: 58,
        minLeadingWidth: 38,
        horizontalTitleGap: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        leading: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: foreground),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: destructive ? scheme.error : null,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _ReferralCard extends StatefulWidget {
  const _ReferralCard({required this.account, required this.campaign});

  final MemberAccountController account;
  final MemberReferralCampaign campaign;

  @override
  State<_ReferralCard> createState() => _ReferralCardState();
}

class _ReferralCardState extends State<_ReferralCard> {
  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) showSideToast(context, context.l10n.accountInviteCopied);
  }

  @override
  Widget build(BuildContext context) {
    final referral = widget.account.referral;
    if (referral == null) return const SizedBox.shrink();
    final campaign = widget.campaign;
    final colors = Theme.of(context).colorScheme;
    final groups = <String, List<MemberReferralTier>>{};
    for (final tier in campaign.tiers.where((tier) => tier.enabled)) {
      groups.putIfAbsent(tier.metric, () => []).add(tier);
    }
    final tracks = groups.entries
        .map(
          (entry) => _ReferralProgressTrack(
            key: ValueKey('account-invite-track-${entry.key}'),
            metric: entry.key,
            tiers: entry.value,
            referral: referral,
          ),
        )
        .toList(growable: false);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              campaign.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _CampaignStateBadge(state: campaign.state),
            const SizedBox(height: 18),
            _SectionCard(
              key: const ValueKey('account-invite-ticket'),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final code = Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.accountInviteMyCode,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 3),
                            SelectableText(
                              referral.inviteCode,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        key: const ValueKey('account-copy-invite-code'),
                        tooltip: context.l10n.accountInviteCopyCode,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        onPressed: () => _copy(referral.inviteCode),
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ],
                  );
                  final share = FilledButton.icon(
                    key: const ValueKey('account-share-invite'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(44, 48),
                    ),
                    onPressed: () => _copy(referral.inviteUrl.toString()),
                    icon: const Icon(Icons.ios_share_rounded, size: 20),
                    label: Text(context.l10n.accountInviteShareAction),
                  );
                  if (constraints.maxWidth >= 600 &&
                      MediaQuery.textScalerOf(context).scale(14) <= 20) {
                    return Row(
                      children: [
                        Expanded(child: code),
                        const SizedBox(width: 24),
                        share,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [code, const SizedBox(height: 12), share],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 720 && tracks.length == 2) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: tracks.first),
                        const SizedBox(width: 16),
                        Expanded(child: tracks.last),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final track in tracks) ...[
                      track,
                      const SizedBox(height: 14),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 2),
            _SectionCard(
              child: Column(
                children: [
                  _AccountActionTile(
                    key: const ValueKey('account-invite-records'),
                    icon: Icons.receipt_long_outlined,
                    title: context.l10n.accountInviteRecordsTitle,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) =>
                            _AccountInviteRecordsPage(account: widget.account),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _AccountActionTile(
                    key: const ValueKey('account-invite-rules'),
                    icon: Icons.rule_rounded,
                    title: context.l10n.accountInviteHowItWorks,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) =>
                            _AccountInviteRulesPage(account: widget.account),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _AccountActionTile(
                    key: const ValueKey('account-invite-binding'),
                    icon: Icons.person_add_alt_1_rounded,
                    title: context.l10n.accountInviteMyBinding,
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) =>
                            _AccountInviteBindingPage(account: widget.account),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountInviteRecordsPage extends StatelessWidget {
  const _AccountInviteRecordsPage({required this.account});
  final MemberAccountController account;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: account,
    builder: (context, _) {
      final referral = account.referral;
      return FloatingSubpageScaffold(
        title: context.l10n.accountInviteRecordsTitle,
        body: ListView(
          padding: floatingSubpagePadding(context, bottom: 40),
          children: [
            if (referral == null)
              _SectionCard(child: Text(context.l10n.accountInviteUnavailable))
            else ...[
              if (referral.rewards.isNotEmpty) ...[
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.accountInviteRewards,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 14),
                      for (final (index, reward)
                          in referral.rewards.indexed) ...[
                        if (index > 0) const Divider(height: 28),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              reward.metric == 'paid'
                                  ? context.l10n.accountInvitePaidReward
                                  : context.l10n.accountInviteActiveReward,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              reward.revokedAt != null
                                  ? context.l10n.accountInviteRewardRevoked
                                  : context.l10n.accountInviteRewardReceived,
                              style: TextStyle(
                                color: reward.revokedAt != null
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          reward.rewardDays == null
                              ? context.l10n.accountInviteRewardPermanent
                              : context.l10n.accountInviteCumulativeRewardDays(
                                  reward.rewardDays!,
                                ),
                        ),
                        Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatCompactDate(reward.grantedAt.toLocal()),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (reward.expiresAt != null)
                          Text(
                            context.l10n.accountInviteRewardUntil(
                              MaterialLocalizations.of(
                                context,
                              ).formatCompactDate(reward.expiresAt!.toLocal()),
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.accountInviteBoundCount(
                        referral.invitedCount,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    for (final item in referral.recentInvites)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 17,
                          child: Text(
                            item.name.isEmpty
                                ? '?'
                                : item.name.characters.first.toUpperCase(),
                          ),
                        ),
                        title: Text(item.name),
                        subtitle: Text(
                          '${MaterialLocalizations.of(context).formatCompactDate(item.boundAt.toLocal())} · ${item.status == 'rewarded' ? context.l10n.accountInviteHistoricalReward : context.l10n.accountInviteBound}',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _AccountInviteRulesPage extends StatelessWidget {
  const _AccountInviteRulesPage({required this.account});

  final MemberAccountController account;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: account,
    builder: (context, _) {
      final campaign = account.referral?.campaign;
      return FloatingSubpageScaffold(
        title: context.l10n.accountInviteHowItWorks,
        body: ListView(
          padding: floatingSubpagePadding(context, bottom: 40),
          children: [
            _SectionCard(
              child: campaign == null
                  ? Text(context.l10n.accountInviteUnavailable)
                  : Column(
                      children: campaign.rules.indexed
                          .map(
                            (entry) => _InviteStep(
                              number: entry.$1 + 1,
                              title: entry.$2,
                              last: entry.$1 == campaign.rules.length - 1,
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
        ),
      );
    },
  );
}

class _AccountInviteBindingPage extends StatefulWidget {
  const _AccountInviteBindingPage({required this.account});

  final MemberAccountController account;

  @override
  State<_AccountInviteBindingPage> createState() =>
      _AccountInviteBindingPageState();
}

class _AccountInviteBindingPageState extends State<_AccountInviteBindingPage> {
  final controller = TextEditingController();
  MemberAccountController get account => widget.account;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> onBind() async {
    try {
      await account.bindReferral(controller.text);
      if (!mounted) return;
      controller.clear();
      showSideToast(context, context.l10n.accountInviteBound);
    } catch (error) {
      if (mounted) {
        showSideToast(context, error.toString(), kind: SideToastKind.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: account,
    builder: (context, _) {
      final inviter = account.referral?.inviter;
      final colors = Theme.of(context).colorScheme;
      return FloatingSubpageScaffold(
        title: context.l10n.accountInviteMyBinding,
        body: ListView(
          padding: floatingSubpagePadding(context, bottom: 40),
          children: [
            _SectionCard(
              child: account.referral?.campaign == null
                  ? Text(context.l10n.accountInviteUnavailable)
                  : inviter != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          key: const ValueKey('account-inviter-bound'),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest.withValues(
                              alpha: 0.58,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.link_rounded, color: colors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n.accountInviterBound(
                                        inviter.name,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${inviter.code} · ${context.l10n.accountInviteBound}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (account.referral?.canEnroll == true &&
                            account.referral?.enrolled == false &&
                            account.referral?.campaign?.state == 'active') ...[
                          const SizedBox(height: 14),
                          FilledButton(
                            key: const ValueKey('account-join-invite-campaign'),
                            onPressed: account.loading
                                ? null
                                : () {
                                    controller.text = inviter.code;
                                    onBind();
                                  },
                            child: Text(context.l10n.accountInviteJoinCampaign),
                          ),
                        ],
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.l10n.accountInviteBindIntro,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          key: const ValueKey('account-invite-code'),
                          controller: controller,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: context.l10n.accountInviteBindLabel,
                            helperText: context.l10n.accountInviteBindHint,
                            prefixIcon: const Icon(
                              Icons.person_add_alt_1_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          key: const ValueKey('account-bind-invite'),
                          onPressed:
                              account.loading ||
                                  account.referral?.canEnroll != true ||
                                  account.referral?.campaign?.state != 'active'
                              ? null
                              : onBind,
                          child: Text(context.l10n.accountInviteBindAction),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    },
  );
}

class _ReferralProgressTrack extends StatelessWidget {
  const _ReferralProgressTrack({
    super.key,
    required this.metric,
    required this.tiers,
    required this.referral,
  });
  final String metric;
  final List<MemberReferralTier> tiers;
  final MemberReferral referral;

  bool _received(MemberReferralTier tier) => referral.rewards.any(
    (reward) => reward.tierId == tier.id && reward.revokedAt == null,
  );
  bool _revoked(MemberReferralTier tier) =>
      !_received(tier) &&
      referral.rewards.any(
        (reward) => reward.tierId == tier.id && reward.revokedAt != null,
      );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ordered = [...tiers]..sort((a, b) => a.target.compareTo(b.target));
    final value = metric == 'paid' ? referral.paidCount : referral.activeCount;
    final next = ordered
        .where(
          (tier) => !referral.rewards.any((reward) => reward.tierId == tier.id),
        )
        .firstOrNull;
    final target = (next ?? ordered.last).target;
    final permanentEarned = ordered.any(
      (tier) => tier.rewardDays == null && _received(tier),
    );
    final label = metric == 'paid'
        ? context.l10n.accountInvitePaidProgress
        : context.l10n.accountInviteActiveProgress;
    final nextReward = next?.rewardDays == null
        ? context.l10n.accountInviteRewardPermanent
        : context.l10n.accountInviteCumulativeRewardDays(next!.rewardDays!);
    final status = permanentEarned
        ? context.l10n.accountInvitePermanentEarned
        : next == null
        ? _received(ordered.last)
              ? context.l10n.accountInviteRewardReceived
              : context.l10n.accountInviteRewardRevoked
        : value >= target
        ? context.l10n.accountInviteTargetMet
        : context.l10n.accountInviteRemaining(target - value);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                metric == 'paid'
                    ? Icons.workspace_premium_outlined
                    : Icons.people_outline_rounded,
                color: colors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '$value / $target',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              Text(
                status,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (next != null && !permanentEarned) ...[
            const SizedBox(height: 7),
            Text(
              '${context.l10n.accountInviteNextReward} · $nextReward',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: ordered.last.target <= 0
                ? 0
                : (value / ordered.last.target).clamp(0, 1).toDouble(),
            borderRadius: BorderRadius.circular(99),
            minHeight: 7,
            backgroundColor: colors.surfaceContainerHighest,
            semanticsLabel: '$label $value / ${ordered.last.target}',
            semanticsValue:
                '${ordered.last.target <= 0 ? 0 : (100 * value / ordered.last.target).clamp(0, 100).round()}%',
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final large = MediaQuery.textScalerOf(context).scale(12) > 18;
              final width = large
                  ? constraints.maxWidth
                  : (constraints.maxWidth / ordered.length)
                        .clamp(96.0, constraints.maxWidth)
                        .toDouble();
              return Wrap(
                spacing: 0,
                runSpacing: 10,
                children: [
                  for (final tier in ordered)
                    SizedBox(
                      key: ValueKey('account-invite-tier-${tier.id}'),
                      width: width,
                      child: Semantics(
                        label:
                            '${context.l10n.accountInvitePeople(tier.target)}，${tier.rewardDays == null ? context.l10n.accountInviteRewardPermanent : context.l10n.accountInviteCumulativeRewardDays(tier.rewardDays!)}，${_received(tier)
                                ? context.l10n.accountInviteRewardReceived
                                : _revoked(tier)
                                ? context.l10n.accountInviteRewardRevoked
                                : context.l10n.accountInviteRemaining((tier.target - value).clamp(0, tier.target))}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _received(tier)
                                      ? Icons.check_circle_rounded
                                      : _revoked(tier)
                                      ? Icons.undo_rounded
                                      : value >= tier.target
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  key: ValueKey(
                                    'account-invite-tier-${_received(tier)
                                        ? 'received'
                                        : _revoked(tier)
                                        ? 'revoked'
                                        : 'pending'}-${tier.id}',
                                  ),
                                  size: 17,
                                  color: _received(tier)
                                      ? colors.primary
                                      : colors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    context.l10n.accountInvitePeople(
                                      tier.target,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tier.rewardDays == null
                                  ? context.l10n.accountInviteRewardPermanent
                                  : context.l10n.accountInviteRewardDays(
                                      tier.rewardDays!,
                                    ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CampaignStateBadge extends StatelessWidget {
  const _CampaignStateBadge({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, icon, active) = switch (state) {
      'active' => (
        context.l10n.accountInviteCampaignActive,
        Icons.play_circle_outline_rounded,
        true,
      ),
      'upcoming' => (
        context.l10n.accountInviteCampaignUpcoming,
        Icons.schedule_rounded,
        false,
      ),
      'ended' => (
        context.l10n.accountInviteCampaignEnded,
        Icons.event_busy_rounded,
        false,
      ),
      _ => (
        context.l10n.accountInviteCampaignPaused,
        Icons.pause_circle_outline_rounded,
        false,
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: active ? colors.primary : colors.outline),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: active ? colors.primary : colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InviteStep extends StatelessWidget {
  const _InviteStep({
    required this.number,
    required this.title,
    this.last = false,
  });

  final int number;
  final String title;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colors.outlineVariant.withValues(alpha: 0.72),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.user, required this.size});

  final MemberUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        (user.effectiveName.trim().isEmpty ? user.username : user.effectiveName)
            .characters
            .first
            .toUpperCase(),
        style: TextStyle(fontSize: size * 0.34, fontWeight: FontWeight.w800),
      ),
    );
    return ClipOval(
      child: user.avatarUrl == null
          ? fallback
          : AccountAvatarImage(
              url: Uri.parse(user.avatarUrl!),
              fallback: fallback,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
    );
  }
}
