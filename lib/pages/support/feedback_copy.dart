import 'package:flutter/widgets.dart';

class FeedbackCopy {
  const FeedbackCopy._(this.isChinese);

  factory FeedbackCopy.of(BuildContext context) => FeedbackCopy._(
    Localizations.localeOf(context).languageCode.toLowerCase() == 'zh',
  );

  final bool isChinese;

  String get title => isChinese ? '意见反馈' : 'Feedback';
  String get intro => isChinese
      ? '告诉我们哪里需要改进。登录后可直接提交，反馈会附带版本和平台信息。'
      : 'Tell us what could be better. Sign in to send feedback with app version and platform details.';
  String get signInTitle => isChinese ? '登录后提交反馈' : 'Sign in to send feedback';
  String get signInBody => isChinese
      ? '反馈与账号关联，方便确认问题和后续处理。'
      : 'Feedback is linked to your account so we can investigate and follow up.';
  String get signIn => isChinese ? '前往登录' : 'Sign in';
  String get category => isChinese ? '反馈类型' : 'Category';
  String get message => isChinese ? '详细描述' : 'Details';
  String get messageHint => isChinese
      ? '请描述遇到的问题、发生场景或你的建议（1–4000 字）'
      : 'Describe the issue, when it happens, or your suggestion (1–4000 characters)';
  String get messageRequired => isChinese ? '请填写反馈内容' : 'Enter your feedback';
  String get messageTooLong =>
      isChinese ? '反馈内容不能超过 4000 字' : 'Feedback cannot exceed 4000 characters';
  String get attachDiagnostics =>
      isChinese ? '附带本次诊断摘要' : 'Attach current diagnostics';
  String get attachDiagnosticsBody => isChinese
      ? '仅在性能统计已开启时附带，不会因为勾选而自动开启。'
      : 'Available only when performance sharing is on. Selecting this never turns collection on.';
  String get diagnosticsUnavailable => isChinese
      ? '当前设备暂不支持性能统计。'
      : 'Performance reporting is not supported on this device.';
  String get improvePerformance =>
      isChinese ? '帮助改善耗电与性能' : 'Help improve battery and performance';
  String get improvePerformanceBody => isChinese
      ? '关闭时不采集。开启后只记录性能、耗电估算、机型和版本，不包含书籍、正文、书源内容或账号凭据。'
      : 'Nothing is collected while off. When on, only performance, estimated battery use, device model, and app version are recorded—never books, reading text, source content, or credentials.';
  String get submitting => isChinese ? '正在提交…' : 'Sending…';
  String get submit => isChinese ? '提交反馈' : 'Send feedback';
  String get failed => isChinese
      ? '提交失败，内容已保留。请检查网络后重试。'
      : 'Could not send. Your feedback was kept; check the network and try again.';
  String get accountChanged => isChinese
      ? '登录账号已变化，请重新填写后提交。'
      : 'The signed-in account changed. Please enter the feedback again.';
  String get successTitle => isChinese ? '反馈已收到' : 'Feedback received';
  String successBody(String id) => isChinese
      ? '感谢你的反馈。反馈编号：$id'
      : 'Thanks for helping improve Origo X. Feedback ID: $id';
  String get sendAnother => isChinese ? '再写一条' : 'Send another';

  String categoryLabel(FeedbackCategory category) => switch (category) {
    FeedbackCategory.bug => isChinese ? '功能问题' : 'Bug',
    FeedbackCategory.performance => isChinese ? '卡顿与性能' : 'Performance',
    FeedbackCategory.battery => isChinese ? '耗电与发热' : 'Battery & heat',
    FeedbackCategory.suggestion => isChinese ? '功能建议' : 'Suggestion',
    FeedbackCategory.other => isChinese ? '其他' : 'Other',
  };
}

enum FeedbackCategory {
  bug,
  performance,
  battery,
  suggestion,
  other;

  String get apiValue => name;
}
