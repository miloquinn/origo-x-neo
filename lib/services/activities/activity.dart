/// Public presentation data. Invitation eligibility and rewards remain owned
/// by the membership service and the participant's locked campaign snapshot.
class AppActivity {
  const AppActivity({
    required this.id,
    required this.revision,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.state,
    required this.channels,
    this.startsAt,
    this.endsAt,
  });

  factory AppActivity.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final revision = json['revision'];
    final kind = json['kind'];
    final title = json['title'];
    final subtitle = json['subtitle'];
    final accent = json['accent'];
    final state = json['state'];
    final channels = json['channels'];
    if (id is! String ||
        !RegExp(r'^[a-z][a-z0-9-]{0,63}$').hasMatch(id) ||
        revision is! int ||
        revision < 1 ||
        !const ['announcement', 'referral'].contains(kind) ||
        title is! String ||
        title.trim().isEmpty ||
        subtitle is! String ||
        !const ['sky', 'mint', 'amber'].contains(accent) ||
        !const ['active', 'upcoming', 'paused', 'ended'].contains(state) ||
        channels is! List ||
        channels.isEmpty ||
        channels.any((item) => !const ['official', 'store'].contains(item))) {
      throw const FormatException('Invalid activity presentation');
    }
    return AppActivity(
      id: id,
      revision: revision,
      kind: kind as String,
      title: title,
      subtitle: subtitle,
      accent: accent as String,
      state: state as String,
      channels: List<String>.unmodifiable(channels.cast<String>()),
      startsAt: _date(json['starts_at']),
      endsAt: _date(json['ends_at']),
    );
  }

  final String id;
  final int revision;
  final String kind;
  final String title;
  final String subtitle;
  final String accent;
  final String state;
  final List<String> channels;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool visibleFor(String channel) =>
      channels.contains(channel) &&
      (kind != 'referral' || channel == 'official');

  /// Construct a same-origin URL rather than trusting a remotely supplied URL.
  /// Never include access tokens, account identity, or invitation codes.
  Uri detailUri(
    Uri origin, {
    required String channel,
    String locale = 'zh-CN',
    bool dark = false,
  }) {
    if (!visibleFor(channel) ||
        !RegExp(r'^[a-z][a-z0-9-]{0,63}$').hasMatch(id) ||
        origin.userInfo.isNotEmpty ||
        origin.host.isEmpty ||
        !(origin.scheme == 'https' ||
            (origin.scheme == 'http' &&
                const [
                  'localhost',
                  '127.0.0.1',
                  '::1',
                ].contains(origin.host)))) {
      throw const FormatException('Invalid activity origin or channel');
    }
    final prefix = switch (locale) {
      'zh-TW' => '/zh-TW',
      'zh-CN' => '',
      _ => '/en',
    };
    return origin
        .replace(
          path: '$prefix/activities/$id',
          queryParameters: {
            'channel': channel,
            'v': '$revision',
            'embedded': '1',
            'theme': dark ? 'dark' : 'light',
          },
        )
        .removeFragment();
  }

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.parse(value as String);
}
