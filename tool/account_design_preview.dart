// Design-only prototype. No network, authentication, purchases, or stored state.
import 'package:flutter/material.dart';
import 'package:xxread/widgets/app_brand_icon.dart';

void main() => runApp(const AccountDesignApp());

class AccountDesignApp extends StatelessWidget {
  const AccountDesignApp({
    super.key,
    this.initialPage = 'login',
    this.dark = false,
  });
  final String initialPage;
  final bool dark;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'AccountPreview',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2),
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ),
    home: AccountDesignPage(page: initialPage),
  );
}

class AccountDesignPage extends StatelessWidget {
  const AccountDesignPage({super.key, required this.page});
  final String page;
  void go(BuildContext c, String next) => Navigator.of(c).push(
    MaterialPageRoute<void>(builder: (_) => AccountDesignPage(page: next)),
  );
  Widget gap([double n = 16]) => SizedBox(height: n);
  Widget title(BuildContext c, String text, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        text,
        style: Theme.of(c).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -.6,
        ),
      ),
      gap(8),
      Text(
        subtitle,
        style: Theme.of(c).textTheme.bodyMedium?.copyWith(
          color: Theme.of(c).colorScheme.onSurfaceVariant,
          height: 1.6,
        ),
      ),
      gap(28),
    ],
  );
  Widget field(
    String label, {
    bool secret = false,
    String? value,
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      initialValue: value,
      obscureText: secret,
      keyboardType: numeric ? TextInputType.number : null,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: secret
            ? const Icon(Icons.visibility_off_outlined, size: 20)
            : null,
      ),
    ),
  );
  Widget primary(BuildContext c, String label, String next) => FilledButton(
    onPressed: () => go(c, next),
    child: Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  );
  Widget link(BuildContext c, String text, String next) =>
      TextButton(onPressed: () => go(c, next), child: Text(text));
  Widget row(
    BuildContext c,
    IconData icon,
    String label,
    String value,
    String next,
  ) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    minLeadingWidth: 24,
    leading: Icon(icon, size: 22, color: Theme.of(c).colorScheme.primary),
    title: Text(
      label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value.isNotEmpty)
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(c).colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded, size: 18),
      ],
    ),
    onTap: () => go(c, next),
  );
  Widget group(BuildContext c, List<Widget> children) => Material(
    color: Theme.of(c).colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              indent: 54,
              endIndent: 16,
              color: Theme.of(
                c,
              ).colorScheme.outlineVariant.withValues(alpha: .45),
            ),
          children[i],
        ],
      ],
    ),
  );
  Widget caption(BuildContext c, String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10, left: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(c).colorScheme.onSurfaceVariant,
      ),
    ),
  );
  Widget identity(BuildContext c, {bool premium = false}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      color: premium ? null : Theme.of(c).colorScheme.surfaceContainerLow,
      gradient: premium
          ? const LinearGradient(colors: [Color(0xFF252B38), Color(0xFF121925)])
          : null,
      border: premium
          ? Border.all(color: const Color(0xFFAA9871).withValues(alpha: .5))
          : null,
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: premium
              ? const Color(0xFF454B55)
              : Theme.of(c).colorScheme.primaryContainer,
          child: Text(
            '林',
            style: TextStyle(
              fontSize: 21,
              color: premium ? const Color(0xFFE2D0AA) : null,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '林间读者',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: premium ? Colors.white : null,
                    ),
                  ),
                  if (premium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF464239),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        '高级版',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFE2D0AA),
                        ),
                      ),
                    ),
                ],
              ),
              gap(6),
              Text(
                'reader@example.com',
                style: TextStyle(
                  fontSize: 12,
                  color: premium
                      ? const Color(0xFFBEC3CD)
                      : Theme.of(c).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: '编辑资料',
          onPressed: () => go(c, 'profile'),
          icon: Icon(
            Icons.chevron_right_rounded,
            color: premium ? Colors.white70 : null,
          ),
        ),
      ],
    ),
  );
  List<Widget> content(BuildContext c) {
    switch (page) {
      case 'login':
        return [
          gap(24),
          const Align(
            alignment: Alignment.centerLeft,
            child: AppBrandIcon(size: 46),
          ),
          gap(26),
          title(c, '登录 Origo X', '管理你的账户与已购权益'),
          field('邮箱地址', value: 'reader@example.com'),
          primary(c, '继续', 'password'),
          gap(8),
          Center(child: link(c, '还没有账户？创建账户', 'register')),
          gap(32),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '或',
                  style: TextStyle(
                    color: Theme.of(c).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          gap(20),
          OutlinedButton.icon(
            onPressed: () => go(c, 'authorization'),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('使用 Google 登录'),
          ),
          Center(
            child: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: c,
                showDragHandle: true,
                builder: (context) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '其他登录方式',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        gap(),
                        row(c, Icons.code, 'GitHub', '', 'authorization'),
                        row(c, Icons.key_outlined, '通行密钥', '', 'authorization'),
                        row(c, Icons.mail_outline, '邮箱验证码', '', 'code'),
                      ],
                    ),
                  ),
                ),
              ),
              child: const Text('其他登录方式'),
            ),
          ),
        ];
      case 'password':
        return [
          gap(28),
          title(c, '欢迎回来', 'reader@example.com'),
          field('密码', secret: true, value: 'samplepassword'),
          primary(c, '登录', 'account'),
          gap(4),
          Align(
            alignment: Alignment.centerRight,
            child: link(c, '忘记密码', 'reset'),
          ),
          gap(20),
          Center(child: link(c, '使用邮箱验证码登录', 'code')),
          Center(child: link(c, '更换邮箱', 'login')),
        ];
      case 'register':
        return [
          gap(28),
          caption(c, '创建账户 · 1 / 3'),
          title(c, '从邮箱开始', '用于登录、恢复账户与接收验证码'),
          field('邮箱地址', value: 'reader@example.com'),
          primary(c, '发送验证码', 'register-code'),
          gap(8),
          Center(child: link(c, '已有账户？登录', 'login')),
        ];
      case 'register-code':
      case 'code':
        return [
          gap(28),
          if (page == 'register-code') caption(c, '创建账户 · 2 / 3'),
          title(c, '输入验证码', '验证码已发送至\nreader@example.com'),
          field('邮箱验证码', numeric: true, value: '128609'),
          primary(
            c,
            page == 'code' ? '登录' : '继续',
            page == 'code' ? 'account' : 'register-finish',
          ),
          gap(8),
          const Center(
            child: Text(
              '48 秒后可重新发送',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          gap(18),
          Center(child: link(c, '更换邮箱', 'register')),
        ];
      case 'register-finish':
        return [
          gap(28),
          caption(c, '创建账户 · 3 / 3'),
          title(c, '设置账户', '昵称和头像可以稍后在个人资料中修改'),
          field('用户名', value: 'forest_reader'),
          field('密码', secret: true),
          field('确认密码', secret: true),
          primary(c, '创建账户', 'account'),
        ];
      case 'reset':
        return [
          gap(28),
          title(c, '找回密码', '向你的账户邮箱发送验证码'),
          field('邮箱地址', value: 'reader@example.com'),
          primary(c, '发送验证码', 'reset-finish'),
        ];
      case 'reset-finish':
        return [
          gap(28),
          title(c, '设置新密码', 'reader@example.com'),
          field('邮箱验证码', numeric: true),
          field('新密码', secret: true),
          field('确认新密码', secret: true),
          primary(c, '保存并返回登录', 'password'),
        ];
      case 'account':
      case 'premium-account':
        return [
          gap(12),
          identity(c, premium: page == 'premium-account'),
          if (page == 'account') ...[
            gap(12),
            group(c, [
              row(
                c,
                Icons.auto_awesome_outlined,
                '阅读使用权',
                '试用剩余 12 天',
                'membership',
              ),
            ]),
          ],
          caption(c, '账户管理'),
          group(c, [
            row(c, Icons.person_outline, '个人资料', '', 'profile'),
            row(c, Icons.shield_outlined, '账户与安全', '', 'security'),
            row(c, Icons.receipt_long_outlined, '已购权益', '', 'membership'),
          ]),
          caption(c, '支持'),
          group(c, [row(c, Icons.help_outline, '帮助与反馈', '', 'help')]),
          gap(24),
          Center(
            child: TextButton(
              onPressed: () => showDialog<void>(
                context: c,
                builder: (d) => AlertDialog(
                  title: const Text('退出当前账户？'),
                  content: const Text('本地书籍会保留。账户权益需登录后重新校验。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(d),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(d);
                        go(c, 'login');
                      },
                      child: const Text('退出登录'),
                    ),
                  ],
                ),
              ),
              child: const Text('退出登录'),
            ),
          ),
        ];
      case 'security':
        return [
          gap(12),
          caption(c, '登录与验证'),
          group(c, [
            row(c, Icons.alternate_email, '登录邮箱', '已验证', 'change-email'),
            row(c, Icons.lock_outline, '密码', '已设置', 'reset'),
            row(c, Icons.phonelink_lock_outlined, '两步验证', '未开启', 'mfa'),
            row(c, Icons.login, '登录方式', '查看', 'methods'),
          ]),
          gap(14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '开启两步验证，为账户多一层保护。',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(c).colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ),
          gap(38),
          group(c, [row(c, Icons.person_off_outlined, '注销账户', '', 'delete')]),
        ];
      case 'profile':
        return [
          gap(24),
          const Center(
            child: CircleAvatar(
              radius: 36,
              child: Text('林', style: TextStyle(fontSize: 26)),
            ),
          ),
          Center(child: link(c, '更换头像', 'avatar')),
          gap(24),
          field('昵称', value: '林间读者'),
          field('用户名', value: 'forest_reader'),
          gap(8),
          primary(c, '保存', 'account'),
        ];
      case 'membership':
        return [
          gap(20),
          title(c, '安心读下去', '一次解锁，长期使用'),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(
                c,
              ).colorScheme.primaryContainer.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '永久解锁',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                gap(12),
                const Text(
                  'US\$9.99',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
                ),
                gap(6),
                const Text('一次性购买 · 无自动续费', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          gap(20),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.check_rounded),
            title: Text('持续使用本地阅读功能', style: TextStyle(fontSize: 15)),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.check_rounded),
            title: Text('兼容更多书源格式', style: TextStyle(fontSize: 15)),
            subtitle: Text('不包含书籍或书源内容', style: TextStyle(fontSize: 12)),
          ),
          gap(20),
          primary(c, '通过 Google Play 解锁', 'purchase-preview'),
          Center(child: link(c, '恢复购买', 'restore-preview')),
          gap(8),
          const Center(
            child: Text(
              '当前试用剩余 12 天',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ];
      case 'authorization':
        return [
          gap(44),
          const Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.open_in_new, size: 40),
          ),
          gap(24),
          title(c, '在浏览器中继续', '完成授权后，会自动回到 Origo X。'),
          primary(c, '重新打开授权页', 'authorization'),
          Center(child: link(c, '取消登录', 'login')),
        ];
      default:
        return [
          gap(28),
          title(
            c,
            switch (page) {
              'mfa' => '两步验证',
              'methods' => '登录方式',
              'change-email' => '更换邮箱',
              'delete' => '注销账户',
              _ => '设计演示',
            },
            switch (page) {
              'delete' => '保留现有风险说明、验证和最终确认流程。',
              'mfa' => '邮箱验证 → 绑定验证器 → 保存恢复码',
              _ => '此入口沿用现有功能，当前预览不发送请求。',
            },
          ),
          if (page == 'methods')
            group(c, [
              row(c, Icons.mail_outline, '邮箱', '已绑定', 'security'),
              row(c, Icons.code, 'GitHub', '已绑定', 'security'),
            ]),
          if (page == 'purchase-preview' || page == 'restore-preview')
            const Text('这是视觉方案，不会付款或修改账户权益。'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final heading = switch (page) {
      'account' || 'premium-account' => '账户',
      'security' => '账户与安全',
      'profile' => '个人资料',
      'membership' => '阅读使用权',
      _ => '',
    };
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              go(context, 'account');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          heading,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                ...content(context),
                if (page == 'login' || page == 'register-finish') ...[
                  gap(24),
                  Text(
                    '用户协议 · 隐私政策',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.6,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
