import 'package:flutter/widgets.dart';

class DiagnosticsConsentCopy {
  const DiagnosticsConsentCopy._(this.isChinese);

  factory DiagnosticsConsentCopy.of(BuildContext context) =>
      DiagnosticsConsentCopy._(
        Localizations.localeOf(context).languageCode.toLowerCase() == 'zh',
      );

  final bool isChinese;

  String get title =>
      isChinese ? '帮助改善耗电与性能' : 'Help improve battery and performance';
  String get introduction => isChinese
      ? '这项可选统计默认关闭。同意后，APP 仅在前台低频记录下列技术摘要：'
      : 'This optional reporting is off by default. If you agree, the app records only these low-frequency technical summaries while in the foreground:';
  String get fields => isChinese
      ? '• CPU 时间与内存占用\n'
            '• 帧性能与热状态\n'
            '• 有效前台时段的整机掉电估算\n'
            '• 机型、系统版本、APP 版本与构建号'
      : '• CPU time and memory use\n'
            '• Frame performance and thermal state\n'
            '• Estimated whole-device battery drop during valid foreground periods\n'
            '• Device model, OS version, app version, and build number';
  String get useAndLinking => isChinese
      ? '自动摘要用于发现版本性能和耗电问题，登录后上传到我们的服务，与当前账号关联并最长保留 30 天。掉电估算是使用期间的整机电量下降，不代表 APP 独占耗电。'
      : 'Automatic summaries help find version-specific performance and battery issues. After sign-in, they are uploaded to our service, linked to the current account, and retained for up to 30 days. The battery estimate is the whole device’s drop during use, not power consumed exclusively by the app.';
  String get exclusions => isChinese
      ? '不收集书名、阅读正文、书源内容、自由日志或账号凭据。你可随时在设置中关闭；关闭后立即停止并清除待上传摘要。'
      : 'It never collects book titles, reading text, source content, free-form logs, or account credentials. You can turn it off in Settings at any time; turning it off stops collection and clears pending summaries.';
  String get privacyPolicy => isChinese ? '查看隐私政策' : 'Read privacy policy';
  String get notNow => isChinese ? '暂不开启' : 'Not now';
  String get agreeAndEnable => isChinese ? '同意并开启' : 'Agree and enable';
  String get saveFailed => isChinese
      ? '未能保存这次选择，性能统计仍保持关闭。请重试。'
      : 'Your choice could not be saved. Performance reporting remains off. Try again.';
}
