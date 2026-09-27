import contextlib
import io
from pathlib import Path
import plistlib
import tempfile
import unittest
from unittest.mock import patch

import build_website as build
import distribution as dist


class BuildWebsiteTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / 'repo'
        (self.root / 'macos/Runner.xcworkspace').mkdir(parents=True)
        (self.root / 'pubspec.yaml').write_text('version: 2.6.7+260908001\n')
        self.write_entitlements()
        for context in [
            patch.object(build, 'ROOT', self.root),
            patch.object(dist, 'ROOT', self.root),
            patch.object(
                dist,
                'GENERATED_XCCONFIG',
                self.root / 'macos/Flutter/ephemeral/Flutter-Generated.xcconfig',
            ),
            patch.object(build.shutil, 'which', return_value='/fake/flutter'),
        ]:
            context.start()
            self.addCleanup(context.stop)

    def write_entitlements(self, *, website_native_sign_in=False, website_extra=None):
        runner = self.root / 'macos/Runner'
        runner.mkdir(parents=True, exist_ok=True)
        common = {
            'com.apple.developer.associated-domains': [
                'webcredentials:open.xxread.top',
            ],
            'com.apple.security.app-sandbox': True,
            'com.apple.security.network.client': True,
        }
        store = dict(common)
        store[build.NATIVE_SIGN_IN_ENTITLEMENT] = ['Default']
        website = dict(common)
        if website_native_sign_in:
            website[build.NATIVE_SIGN_IN_ENTITLEMENT] = ['Default']
        if website_extra:
            website.update(website_extra)
        (self.root / build.STORE_ENTITLEMENTS).write_bytes(plistlib.dumps(store))
        (self.root / build.WEBSITE_ENTITLEMENTS).write_bytes(plistlib.dumps(website))

    def write_defines(self, *assignments):
        xcconfig = dist.GENERATED_XCCONFIG
        xcconfig.parent.mkdir(parents=True, exist_ok=True)
        encoded = ','.join(dist.encode_dart_define(item) for item in assignments)
        xcconfig.write_text(f'DART_DEFINES={encoded}\n')

    def test_flutter_command_is_website_distribution(self):
        command = build.flutter_build_command()
        self.assertEqual(command[:4], ['flutter', 'build', 'macos', '--release'])
        self.assertIn(dist.MACOS_WEBSITE_DART_DEFINE, command)
        self.assertIn(dist.DIRECT_DISTRIBUTION_DART_DEFINE, command)
        self.assertIn(dist.READER_LICENSE_DISABLED_DART_DEFINE, command)
        self.assertFalse(dist.command_has_macos_app_store_define(command))

    def test_check_does_not_build(self):
        with patch.object(build, 'run_step') as run, contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(build.execute(build.parser().parse_args(['--check'])), 0)
            run.assert_not_called()

    def test_website_entitlements_remove_only_unsupported_native_sign_in(self):
        build.verify_website_entitlements()
        store = build.read_entitlements(build.STORE_ENTITLEMENTS)
        website = build.read_entitlements(build.WEBSITE_ENTITLEMENTS)
        self.assertIn(build.NATIVE_SIGN_IN_ENTITLEMENT, store)
        self.assertNotIn(build.NATIVE_SIGN_IN_ENTITLEMENT, website)

    def test_website_entitlements_reject_native_sign_in(self):
        self.write_entitlements(website_native_sign_in=True)
        with self.assertRaisesRegex(build.BuildError, 'except for unsupported'):
            build.verify_website_entitlements()

    def test_website_entitlements_reject_other_channel_drift(self):
        self.write_entitlements(website_extra={'com.example.unexpected': True})
        with self.assertRaisesRegex(build.BuildError, 'except for unsupported'):
            build.verify_website_entitlements()

    def test_rejects_store_define_in_command(self):
        with self.assertRaisesRegex(build.BuildError, 'must not pass'):
            build.run_step(
                'bad',
                ['flutter', 'build', 'macos', dist.MACOS_APP_STORE_DART_DEFINE],
            )

    def test_build_verifies_website_defines_and_app(self):
        calls = []

        def fake_step(label, command, log=None, cwd=None):
            calls.append(command)
            if command[:3] == ['flutter', 'build', 'macos']:
                products = self.root / 'build/macos/Build/Products/Release'
                products.mkdir(parents=True)
                (products / '开元阅读.app').mkdir()
                self.write_defines(
                    'FLUTTER_VERSION=3.44.7',
                    dist.MACOS_WEBSITE_ASSIGNMENT,
                    dist.DIRECT_DISTRIBUTION_ASSIGNMENT,
                    dist.READER_LICENSE_DISABLED_ASSIGNMENT,
                )

        with patch.object(build, 'run_step', side_effect=fake_step), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(build.execute(build.parser().parse_args(['--no-pub'])), 0)
        self.assertEqual(calls, [build.flutter_build_command()])

    def test_missing_website_define_is_rejected(self):
        def fake_step(label, command, log=None, cwd=None):
            self.write_defines('FLUTTER_VERSION=3.44.7')
            products = self.root / 'build/macos/Build/Products/Release'
            products.mkdir(parents=True)
            (products / '开元阅读.app').mkdir()

        with patch.object(build, 'run_step', side_effect=fake_step):
            with self.assertRaisesRegex(build.BuildError, 'require'):
                build.execute(build.parser().parse_args(['--no-pub']))

    def test_store_define_in_generated_config_is_rejected(self):
        def fake_step(label, command, log=None, cwd=None):
            self.write_defines(dist.MACOS_APP_STORE_ASSIGNMENT)
            products = self.root / 'build/macos/Build/Products/Release'
            products.mkdir(parents=True)
            (products / '开元阅读.app').mkdir()

        with patch.object(build, 'run_step', side_effect=fake_step):
            with self.assertRaisesRegex(build.BuildError, 'must not set'):
                build.execute(build.parser().parse_args(['--no-pub']))


if __name__ == '__main__':
    unittest.main()
