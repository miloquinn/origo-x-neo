import 'package:xxread/services/activities/activity.dart';

Map<String, dynamic> activityFixture({
  String id = 'referral',
  String kind = 'referral',
  String title = '邀请好友，一起探元',
  List<String> channels = const ['official'],
  String state = 'active',
  String accent = 'mint',
}) => {
  'id': id,
  'revision': 3,
  'kind': kind,
  'title': title,
  'subtitle': kind == 'referral'
      ? '邀请真实使用的好友，领取限时或永久探元。'
      : '每天留一点时间，读完想读的那本书。',
  'accent': accent,
  'state': state,
  'channels': channels,
  'starts_at': '2026-10-08T03:00:00Z',
  'ends_at': null,
};

List<AppActivity> sampleActivities() => [
  AppActivity.fromJson(activityFixture()),
  AppActivity.fromJson(
    activityFixture(
      id: 'autumn-reading',
      kind: 'announcement',
      title: '秋日阅读计划',
      accent: 'amber',
      channels: ['official', 'store'],
      state: 'upcoming',
    ),
  ),
];
