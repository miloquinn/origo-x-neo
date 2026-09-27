import contextlib
import io
import plistlib
from pathlib import Path
import tempfile
import unittest

import prepare_release_entitlements as prepare


class PrepareReleaseEntitlementsTests(unittest.TestCase):
    def requested(self):
        return {
            'com.apple.developer.applesignin': ['Default'],
            'com.apple.developer.associated-domains': [
                'webcredentials:open.xxread.top',
            ],
            'com.apple.security.app-sandbox': True,
        }

    def profile(self):
        return {
            'Entitlements': {
                'com.apple.application-identifier': '2HD5836RZ2.com.niki.xxread',
                'com.apple.developer.team-identifier': '2HD5836RZ2',
                'com.apple.developer.applesignin': ['Default'],
                'com.apple.developer.associated-domains': [
                    'webcredentials:open.xxread.top',
                ],
            },
        }

    def test_prepares_authorized_entitlements_and_identity(self):
        result = prepare.prepare_entitlements(self.requested(), self.profile())
        self.assertEqual(result['com.apple.developer.applesignin'], ['Default'])
        self.assertTrue(result['com.apple.security.app-sandbox'])
        self.assertEqual(
            result['com.apple.application-identifier'],
            '2HD5836RZ2.com.niki.xxread',
        )
        self.assertEqual(result['com.apple.developer.team-identifier'], '2HD5836RZ2')

    def test_rejects_missing_sign_in_with_apple_authorization(self):
        profile = self.profile()
        del profile['Entitlements']['com.apple.developer.applesignin']
        with self.assertRaisesRegex(
            prepare.EntitlementsError,
            'does not authorize requested entitlement: com.apple.developer.applesignin',
        ):
            prepare.prepare_entitlements(self.requested(), profile)

    def test_rejects_mismatched_profile_value(self):
        profile = self.profile()
        profile['Entitlements']['com.apple.developer.applesignin'] = ['Secondary']
        with self.assertRaisesRegex(
            prepare.EntitlementsError,
            'value does not authorize requested entitlement: com.apple.developer.applesignin',
        ):
            prepare.prepare_entitlements(self.requested(), profile)

    def test_rejects_unprovisioned_keychain_group(self):
        requested = self.requested()
        requested['keychain-access-groups'] = ['2HD5836RZ2.com.niki.xxread']
        with self.assertRaisesRegex(
            prepare.EntitlementsError,
            'does not authorize requested entitlement: keychain-access-groups',
        ):
            prepare.prepare_entitlements(requested, self.profile())

    def test_accepts_profile_wildcard_but_keeps_narrow_requested_value(self):
        profile = self.profile()
        profile['Entitlements']['com.apple.developer.associated-domains'] = '*'
        result = prepare.prepare_entitlements(self.requested(), profile)
        self.assertEqual(
            result['com.apple.developer.associated-domains'],
            ['webcredentials:open.xxread.top'],
        )

    def test_command_does_not_write_output_when_validation_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            requested_path = root / 'requested.plist'
            profile_path = root / 'profile.plist'
            output_path = root / 'prepared.plist'
            requested_path.write_bytes(plistlib.dumps(self.requested()))
            profile = self.profile()
            del profile['Entitlements']['com.apple.developer.applesignin']
            profile_path.write_bytes(plistlib.dumps(profile))
            with contextlib.redirect_stderr(io.StringIO()):
                result = prepare.main([
                    '--requested', str(requested_path),
                    '--profile', str(profile_path),
                    '--output', str(output_path),
                ])
            self.assertEqual(result, 1)
            self.assertFalse(output_path.exists())


if __name__ == '__main__':
    unittest.main()
