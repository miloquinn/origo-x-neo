#!/usr/bin/env python3
"""Build the GitHub / website Developer ID macOS app (redemption codes, no Apple tax)."""
from __future__ import annotations

import argparse
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys

import distribution as dist

ROOT = dist.ROOT


class BuildError(Exception):
    pass


STORE_ENTITLEMENTS = Path('macos/Runner/Release.entitlements')
WEBSITE_ENTITLEMENTS = Path('macos/Runner/WebsiteRelease.entitlements')
NATIVE_SIGN_IN_ENTITLEMENT = 'com.apple.developer.applesignin'


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument('--check', action='store_true', help='Read-only local prerequisite check')
    result.add_argument('--no-pub', action='store_true', help='Skip flutter pub get; CI already resolved deps')
    return result


def read_entitlements(relative_path):
    path = ROOT / relative_path
    try:
        with path.open('rb') as stream:
            value = plistlib.load(stream)
    except (OSError, plistlib.InvalidFileException) as error:
        raise BuildError(f'Unable to read macOS entitlements: {relative_path}') from error
    if not isinstance(value, dict):
        raise BuildError(f'macOS entitlements must contain a dictionary: {relative_path}')
    return value


def verify_website_entitlements():
    store = read_entitlements(STORE_ENTITLEMENTS)
    website = read_entitlements(WEBSITE_ENTITLEMENTS)
    if store.get(NATIVE_SIGN_IN_ENTITLEMENT) != ['Default']:
        raise BuildError('Mac App Store release entitlements must keep native Sign in with Apple')
    expected = dict(store)
    del expected[NATIVE_SIGN_IN_ENTITLEMENT]
    if website != expected:
        raise BuildError(
            'Website release entitlements must match Mac App Store release entitlements '
            'except for unsupported native Sign in with Apple'
        )


def check_inputs():
    if shutil.which('flutter') is None:
        raise BuildError('Required tool is missing: flutter')
    if not (ROOT / 'macos/Runner.xcworkspace').is_dir():
        raise BuildError('macos/Runner.xcworkspace is missing')
    verify_website_entitlements()


def run_step(label, command, log=None, cwd=ROOT):
    print(label, flush=True)
    if dist.command_has_macos_app_store_define(command):
        raise BuildError('Website macOS build command must not pass OPEN_READING_MACOS_APP_STORE')
    if log is None:
        try:
            subprocess.run(command, cwd=cwd, check=True)
        except (OSError, subprocess.CalledProcessError) as error:
            raise BuildError(f'{label} failed') from error
        return
    with log.open('a') as stream:
        stream.write('\n' + label + '\n')
        stream.flush()
        try:
            subprocess.run(command, cwd=cwd, stdout=stream, stderr=subprocess.STDOUT, check=True)
        except (OSError, subprocess.CalledProcessError):
            raise BuildError(f'{label} failed; inspect private log: {log}') from None


def flutter_build_command():
    return [
        'flutter',
        'build',
        'macos',
        '--release',
        '--no-pub',
        dist.MACOS_WEBSITE_DART_DEFINE,
        dist.DIRECT_DISTRIBUTION_DART_DEFINE,
        dist.READER_LICENSE_DISABLED_DART_DEFINE,
    ]


def verify_website_defines():
    try:
        dist.assert_website_distribution(dist.read_generated_dart_defines())
    except dist.DistributionError as error:
        raise BuildError(str(error)) from error


def execute(args):
    check_inputs()
    if args.check:
        print(
            'Website macOS prerequisites passed. This path sets '
            f'{dist.DIRECT_DISTRIBUTION_DART_DEFINE} and rejects store billing.'
        )
        return 0
    if not args.no_pub:
        run_step('Core Flutter validation: locked dependencies',
                 ['flutter', 'pub', 'get', '--enforce-lockfile'])
    run_step('Product build: website / notarized macOS', flutter_build_command())
    verify_website_defines()
    try:
        app = dist.find_release_app()
    except dist.DistributionError as error:
        raise BuildError(str(error)) from error
    print(f'Website macOS app: {app}')
    print('Billing: website redemption codes. Do not submit this binary to Mac App Store.')
    return 0


def main(argv=None):
    try:
        return execute(parser().parse_args(argv))
    except BuildError as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
