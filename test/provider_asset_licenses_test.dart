import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/app_skin_licenses.dart';
import 'package:xxread/utils/provider_asset_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'startup includes full MIT and separate brand notice exactly once',
    () async {
      registerAppSkinLicenses();
      registerAppSkinLicenses();
      registerProviderAssetLicenses();
      final entries = await LicenseRegistry.licenses.toList();
      final icons = entries.where(
        (entry) => entry.packages.contains('Lobe Icons'),
      );
      final marks = entries.where(
        (entry) => entry.packages.contains('Third-party service marks'),
      );
      expect(icons, hasLength(1));
      expect(marks, hasLength(1));
      final license = icons.single.paragraphs.map((p) => p.text).join('\n');
      final bundled = await rootBundle.loadString(
        'assets/ai_providers/LICENSE-MIT.txt',
      );
      for (final clause in [
        'Copyright (c) 2023 LobeHub',
        'The above copyright notice and this permission notice',
        'THE SOFTWARE IS PROVIDED "AS IS"',
        'OUT OF OR IN CONNECTION WITH THE SOFTWARE',
      ]) {
        expect(license, contains(clause));
        expect(bundled, contains(clause));
      }
      final statement = marks.single.paragraphs.map((p) => p.text).join('\n');
      for (final provider in [
        'OpenAI',
        'Anthropic',
        'Google Gemini',
        'DeepSeek',
        'Qwen',
        'Z.ai',
        'MiniMax',
        'Moonshot AI',
        'Groq',
        'SiliconFlow',
        'Doubao',
        'Xiaomi MiMo',
      ]) {
        expect(statement, contains(provider));
      }
      expect(statement, contains('does not grant blanket permission'));
      expect(statement, contains('does not imply partnership'));
      expect(
        entries.where((e) => e.packages.contains('App skin artwork')),
        hasLength(1),
      );
      expect(
        entries.where((e) => e.packages.contains('IconPark graphics')),
        hasLength(1),
      );
    },
  );
}
