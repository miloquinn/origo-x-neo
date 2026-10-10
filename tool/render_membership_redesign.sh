#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
output_dir="${1:-$repo_root/build/membership-redesign-preview}"
preview_font="${MEMBERSHIP_PREVIEW_FONT:-}"

if [[ -z "$preview_font" ]]; then
  print -u2 "MEMBERSHIP_PREVIEW_FONT must point to a readable CJK preview font."
  exit 64
fi

if [[ ! -f "$preview_font" || ! -r "$preview_font" ]]; then
  print -u2 "MEMBERSHIP_PREVIEW_FONT is not a readable file: $preview_font"
  exit 66
fi

mkdir -p "$output_dir/reader" "$output_dir/premium" "$output_dir/account"

cd "$repo_root"

SPLIT_BILLING_PREVIEW_FONT="$preview_font" \
SPLIT_BILLING_SCREENSHOT_DIR="$output_dir/reader" \
  flutter test test/store_reader_unlock_page_test.dart --no-pub \
  --plain-name 'exports App Store reader and Premium purchase frames when requested'

PREMIUM_PREVIEW_FONT="$preview_font" \
PREMIUM_SCREENSHOT_DIR="$output_dir/premium" \
  flutter test test/premium_membership_page_test.dart --no-pub \
  --name 'exports (the phone light membership review image when requested|active phone membership|the tablet dark membership review image when requested)'

PROFILE_PREVIEW_FONT="$preview_font" \
PROFILE_SCREENSHOT_DIR="$output_dir/account" \
  flutter test test/store_account_entry_test.dart --no-pub \
  --plain-name 'separate account and glass membership'

print "Membership previews: $output_dir"
