// Build a plugin-free web preview: python3 tool/build_welcome_preview.py
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/legal/agreement_summary.dart';
import 'package:xxread/pages/onboarding/reading_welcome_page.dart';
import 'package:xxread/widgets/app_brand_icon.dart';
import 'package:xxread/utils/app_themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Optional local preview font, placed into the preview build by the capture
  // script. No font asset or font dependency is added to the shipping app.
  var hasPreviewFont = false;
  try {
    final data = await rootBundle.load('preview-font.otf');
    await (FontLoader('WelcomePreview')..addFont(Future.value(data))).load();
    hasPreviewFont = true;
  } catch (_) {
    // Flutter's normal font fallback is sufficient when running from source.
  }
  runApp(
    WelcomePreviewApp(fontFamily: hasPreviewFont ? 'WelcomePreview' : null),
  );
}

class WelcomePreviewApp extends StatelessWidget {
  const WelcomePreviewApp({super.key, this.fontFamily});
  final String? fontFamily;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Origo X · 欢迎',
    locale: const Locale('zh'),
    supportedLocales: const [Locale('zh')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: ThemeData(
      fontFamily: fontFamily,
      colorScheme: AppThemes.fromAccentColor(
        AppThemes.defaultAccentColor,
      ).lightColorScheme,
      useMaterial3: true,
    ),
    home: const _PreviewHost(),
  );
}

class _PreviewHost extends StatefulWidget {
  const _PreviewHost();
  @override
  State<_PreviewHost> createState() => _PreviewHostState();
}

class _PreviewHostState extends State<_PreviewHost> {
  bool _complete = false;

  @override
  Widget build(BuildContext context) {
    if (!_complete) {
      return ReadingWelcomePage(
        finalContent: const AgreementSummary(),
        completionLabel: '同意并开始阅读',
        // Preview only: no real agreement record is written.
        onComplete: () => setState(() => _complete = true),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBrandIcon(size: 56, borderRadius: 14),
            const SizedBox(height: 24),
            const Text('故事，从这里开始。', style: TextStyle(fontSize: 26)),
            const SizedBox(height: 28),
            TextButton.icon(
              onPressed: () => setState(() {
                _complete = false;
              }),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('再看一次'),
            ),
          ],
        ),
      ),
    );
  }
}
