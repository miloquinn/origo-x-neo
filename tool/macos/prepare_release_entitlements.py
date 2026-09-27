#!/usr/bin/env python3
"""Validate and prepare entitlements for a Developer ID signed macOS release."""
from __future__ import annotations

import argparse
import fnmatch
from pathlib import Path
import plistlib
import sys


IDENTITY_ENTITLEMENTS = (
    'com.apple.application-identifier',
    'com.apple.developer.team-identifier',
)
PROFILE_CONTROLLED_ENTITLEMENTS = {
    'aps-environment',
    'com.apple.security.application-groups',
    'keychain-access-groups',
}


class EntitlementsError(Exception):
    pass


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument('--requested', required=True, type=Path)
    result.add_argument('--profile', required=True, type=Path)
    result.add_argument('--output', required=True, type=Path)
    return result


def read_plist(path, label):
    try:
        with path.open('rb') as stream:
            value = plistlib.load(stream)
    except (OSError, plistlib.InvalidFileException) as error:
        raise EntitlementsError(f'Unable to read {label} plist: {path}') from error
    if not isinstance(value, dict):
        raise EntitlementsError(f'{label} plist must contain a dictionary: {path}')
    return value


def value_is_authorized(requested, granted):
    if isinstance(requested, list):
        allowed_values = granted if isinstance(granted, list) else [granted]
        return all(
            any(value_is_authorized(item, allowed) for allowed in allowed_values)
            for item in requested
        )
    if isinstance(granted, list):
        return any(value_is_authorized(requested, allowed) for allowed in granted)
    if isinstance(requested, str) and isinstance(granted, str):
        return fnmatch.fnmatchcase(requested, granted)
    if isinstance(requested, dict) and isinstance(granted, dict):
        return all(
            key in granted and value_is_authorized(value, granted[key])
            for key, value in requested.items()
        )
    return requested == granted


def requires_profile_authorization(key):
    return (
        key.startswith('com.apple.developer.')
        or key in PROFILE_CONTROLLED_ENTITLEMENTS
    )


def prepare_entitlements(requested, profile):
    granted = profile.get('Entitlements')
    if not isinstance(granted, dict):
        raise EntitlementsError(
            'Provisioning profile does not contain an Entitlements dictionary'
        )

    for key, value in requested.items():
        if not requires_profile_authorization(key):
            continue
        if key not in granted:
            raise EntitlementsError(
                f'Provisioning profile does not authorize requested entitlement: {key}'
            )
        if not value_is_authorized(value, granted[key]):
            raise EntitlementsError(
                f'Provisioning profile value does not authorize requested entitlement: {key}'
            )

    prepared = dict(requested)
    for key in IDENTITY_ENTITLEMENTS:
        if key not in granted:
            raise EntitlementsError(
                f'Provisioning profile is missing required identity entitlement: {key}'
            )
        prepared[key] = granted[key]
    return prepared


def execute(args):
    requested = read_plist(args.requested, 'Requested entitlements')
    profile = read_plist(args.profile, 'Provisioning profile')
    prepared = prepare_entitlements(requested, profile)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open('wb') as stream:
        plistlib.dump(prepared, stream, fmt=plistlib.FMT_XML, sort_keys=False)
    return 0


def main(argv=None):
    try:
        return execute(parser().parse_args(argv))
    except EntitlementsError as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
