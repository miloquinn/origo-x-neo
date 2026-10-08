"""Copy the website's published bilingual legal source into the offline asset.

Run with --check in cross-repository release validation. The asset is generated;
legal edits belong in origo-x-platform/app/legal/content.json and its history.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source", type=Path,
        default=root.parent / "origo-x-platform/app/legal/content.json",
    )
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    raw = args.source.read_bytes()
    content = json.loads(raw)
    if content.get("schemaVersion") != 1:
        raise SystemExit("Unsupported legal content schema")
    receipts = []
    for locale in ("zh-CN", "en"):
        catalog = content["bundles"][locale]
        if catalog["locale"] != locale or catalog["schemaVersion"] != 1:
            raise SystemExit("Invalid legal catalog locale or schema")
        docs = catalog["documents"]
        if len({doc["id"] for doc in docs}) != len(docs):
            raise SystemExit("Duplicate legal document id")
        receipts.append({doc["id"]: doc["consentVersion"] for doc in docs
                         if doc["requiresAcceptance"]})
    if receipts[0] != receipts[1]:
        raise SystemExit("Acceptance versions differ between translations")
    target = root / "assets/legal/documents.json"
    if args.check:
        if not target.exists() or target.read_bytes() != raw:
            raise SystemExit("Offline legal asset is out of sync; run this tool without --check")
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(raw)
    print(f"Legal asset {'verified' if args.check else 'updated'}: sha256={hashlib.sha256(raw).hexdigest()}")


if __name__ == "__main__":
    main()
