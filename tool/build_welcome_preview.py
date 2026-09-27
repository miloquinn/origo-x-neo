#!/usr/bin/env python3
"""Build the actual welcome widget without registering unrelated app plugins."""

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path,
                        default=Path('/tmp/origo-welcome-preview-web'))
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    flutter = shutil.which('flutter')
    if flutter is None:
        raise SystemExit('flutter must be available on PATH')
    with tempfile.TemporaryDirectory(prefix='origo-welcome-build-') as directory:
        project = Path(directory)
        (project / 'lib/pages/onboarding').mkdir(parents=True)
        (project / 'web').mkdir()
        (project / 'pubspec.yaml').write_text('''name: xxread
publish_to: none
environment:
  sdk: '>=3.12.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2
flutter:
  uses-material-design: true
  assets:
    - assets/images/app_icon.png
''')
        (project / 'web/index.html').write_text('''<!DOCTYPE html>
<html lang="zh"><head><base href="$FLUTTER_BASE_HREF">
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Origo X · 欢迎</title></head>
<body style="margin:0;background:#F7F7F2">
<script src="flutter_bootstrap.js" async></script></body></html>''')
        shutil.copy2(repo / 'tool/welcome_preview.dart', project / 'lib/main.dart')
        sources = [
            'lib/pages/onboarding/reading_welcome_page.dart',
            'lib/pages/legal/agreement_summary.dart',
            'lib/utils/localization_extension.dart',
            'lib/utils/app_themes.dart',
            'lib/widgets/app_brand_icon.dart',
            'assets/images/app_icon.png',
        ]
        sources.extend(str(path.relative_to(repo))
                       for path in (repo / 'lib/l10n').glob('*.dart'))
        for source in sources:
            destination = project / source
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(repo / source, destination)
        subprocess.run([flutter, 'pub', 'get', '--offline'], cwd=project, check=True)
        subprocess.run([
            flutter, 'build', 'web', '--no-pub', '--no-wasm-dry-run',
            '--optimization-level=1',
            '--no-web-resources-cdn', '--output', str(args.output.resolve()),
        ], cwd=project, check=True)
    # Keep the machine's preview font local; it is not a distributable asset.
    font = Path('/System/Library/Fonts/Hiragino Sans GB.ttc')
    if font.exists():
        shutil.copyfile(font, args.output / 'assets/preview-font.otf')
    print(f'Preview built: {args.output.resolve()}')
    print(f'python3 -m http.server 8768 --bind 127.0.0.1 --directory {args.output.resolve()}')


if __name__ == '__main__':
    main()
