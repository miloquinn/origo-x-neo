#!/usr/bin/env python3
"""Keep isolated Flutter test manifests complete and free of stale cases."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKFLOW_PATH = ROOT / ".github/workflows/pr-checks.yml"

SUITE_MANIFESTS = {
    "test/book_source_horizontal_page_commit_test.dart": "horizontal_tests",
    "test/book_source_management_page_test.dart": "management_tests",
    "test/book_source_management_organization_test.dart": "organization_tests",
    "test/native_reader_auto_page_turn_test.dart": "native_auto_turn_tests",
    "test/native_reader_txt_title_page_test.dart": "native_txt_tests",
    "test/native_reader_epub_chapter_transition_test.dart": "native_epub_tests",
    "test/native_reader_initial_progress_test.dart": "native_progress_tests",
    "test/book_source_reader_page_test.dart": "reader_tests",
    "test/book_source_discovery_page_test.dart": "discovery_tests",
}


@dataclass(frozen=True)
class DynamicContract:
    source_title: str
    workflow_fragments: tuple[str, ...] = ()
    manifest_titles: tuple[str, ...] = ()


DYNAMIC_CONTRACTS = {
    "test/native_reader_txt_title_page_test.dart": (
        DynamicContract(
            "continuous TXT chapters leave a body-scaled gap "
            "(fontSize=$fontSize, lineHeight=$lineHeight)",
            manifest_titles=(
                "continuous TXT chapters leave a body-scaled gap (fontSize=19.0, lineHeight=1.75)",
                "continuous TXT chapters leave a body-scaled gap (fontSize=28.0, lineHeight=2.0)",
            ),
        ),
        DynamicContract(
            "vertical TXT TOC jump aligns the chapter start "
            "(titlePage=$chapterTitlePageEnabled, scrollByChapter=$scrollByChapter)",
            workflow_fragments=(
                "for chapter_title_page_enabled in true false; do",
                "for scroll_by_chapter in true false; do",
                "vertical TXT TOC jump aligns the chapter start "
                "(titlePage=$chapter_title_page_enabled, "
                "scrollByChapter=$scroll_by_chapter)",
            ),
        ),
    ),
    "test/native_reader_epub_chapter_transition_test.dart": (
        DynamicContract(
            "EPUB TOC far-back jump mounts the cold target body on ${viewport.name}",
            manifest_titles=(
                "EPUB TOC far-back jump mounts the cold target body on phone",
                "EPUB TOC far-back jump mounts the cold target body on tablet",
            ),
        ),
    ),
    "test/native_reader_initial_progress_test.dart": (
        DynamicContract(
            "EPUB exit captures the final active scroll frame "
            "(scrollByChapter=$scrollByChapter)",
            workflow_fragments=(
                "for scroll_by_chapter in false true; do",
                "EPUB exit captures the final active scroll frame "
                "(scrollByChapter=$scroll_by_chapter)",
            ),
        ),
        DynamicContract(
            "EPUB scroll preserves its exact offset on background and exit "
            "(scrollByChapter=$scrollByChapter, initialOffset=$initialOffset)",
            workflow_fragments=(
                "for scroll_by_chapter in false true; do",
                "for initial_offset in 0 2400 1000000; do",
                "EPUB scroll preserves its exact offset on background and exit "
                "(scrollByChapter=$scroll_by_chapter, initialOffset=$initial_offset)",
            ),
        ),
    ),
    "test/book_source_reader_page_test.dart": (
        DynamicContract(
            "continuous source chapters leave a body-scaled gap "
            "(fontSize=$fontSize, lineHeight=$lineHeight)",
            manifest_titles=(
                "continuous source chapters leave a body-scaled gap (fontSize=19.0, lineHeight=1.75)",
                "continuous source chapters leave a body-scaled gap (fontSize=28.0, lineHeight=2.0)",
            ),
        ),
        DynamicContract(
            "vertical source catalog jump aligns the chapter beginning "
            "(scrollByChapter=$scrollByChapter, titlePage=$titlePage)",
            workflow_fragments=(
                "for scroll_by_chapter in false true; do",
                "for title_page in false true; do",
                "vertical source catalog jump aligns the chapter beginning "
                "(scrollByChapter=$scroll_by_chapter, titlePage=$title_page)",
            ),
        ),
        DynamicContract(
            "vertical source reopens at the saved text anchor "
            "(scrollByChapter=$scrollByChapter, titlePage=$titlePage)",
            workflow_fragments=(
                "for scroll_by_chapter in false true; do",
                "for title_page in false true; do",
                "vertical source reopens at the saved text anchor "
                "(scrollByChapter=$scroll_by_chapter, titlePage=$title_page)",
            ),
        ),
        DynamicContract(
            "exit confirmation returns after addToShelf=$addToShelf",
            workflow_fragments=(
                "for add_to_shelf in true false; do",
                "exit confirmation returns after addToShelf=$add_to_shelf",
            ),
        ),
        DynamicContract(
            "online chapter title preference is shared in ${mode.name} "
            "enabled=$titlePageEnabled",
            workflow_fragments=(
                "for page_mode in horizontalSlide coverSlide pageCurl "
                "instantPage verticalScroll; do",
                "for title_enabled in true false; do",
                "online chapter title preference is shared in $page_mode "
                "enabled=$title_enabled",
            ),
        ),
        DynamicContract(
            "naturally aligns source body text in ${mode.name} mode",
            manifest_titles=(
                "naturally aligns source body text in verticalScroll mode",
                "naturally aligns source body text in instantPage mode",
            ),
        ),
    ),
}


def _read_string(source: str, position: int) -> tuple[str, int]:
    if source[position] == "r" and position + 1 < len(source):
        position += 1
    quote = source[position]
    if quote not in {"'", '"'}:
        raise ValueError("test title must start with a string literal")
    position += 1
    result = []
    while position < len(source):
        character = source[position]
        if character == "\\" and position + 1 < len(source):
            result.extend((character, source[position + 1]))
            position += 2
            continue
        if character == quote:
            return "".join(result), position + 1
        result.append(character)
        position += 1
    raise ValueError("unterminated test title")


def extract_test_titles(source: str) -> list[tuple[str, int]]:
    titles = []
    call_pattern = re.compile(r"(?m)^[ \t]*(?:test|testWidgets)\s*\(")
    matches = list(call_pattern.finditer(source))
    for index, match in enumerate(matches):
        position = match.end()
        parts = []
        while True:
            while position < len(source) and source[position].isspace():
                position += 1
            if position >= len(source) or source[position] not in {"r", "'", '"'}:
                break
            if source[position] == "r" and (
                position + 1 >= len(source) or source[position + 1] not in {"'", '"'}
            ):
                break
            part, position = _read_string(source, position)
            parts.append(part)
        if not parts:
            raise ValueError(f"non-literal test title near byte {match.start()}")
        next_start = matches[index + 1].start() if index + 1 < len(matches) else len(source)
        titles.append(("".join(parts), next_start))
    return titles


def manifest_titles(workflow: str, manifest_name: str) -> set[str]:
    match = re.search(
        rf"(?ms)^\s*{re.escape(manifest_name)}=\(\s*$\n(.*?)^\s*\)\s*$",
        workflow,
    )
    if match is None:
        raise ValueError(f"missing workflow manifest: {manifest_name}")
    titles = set(re.findall(r"(?m)^\s*'([^']+)'\s*$", match.group(1)))
    if not titles:
        raise ValueError(f"empty workflow manifest: {manifest_name}")
    return titles


def core_exclusion_files(
    workflow: str, root: Path = ROOT
) -> tuple[set[str], list[str]]:
    excluded = set()
    errors = []
    for pattern in re.findall(r"! -name '([^']+)'", workflow):
        matches = sorted((root / "test").glob(pattern))
        if not matches:
            errors.append(f"dead Core exclusion: test/{pattern}")
            continue
        excluded.update(str(path.relative_to(root)) for path in matches)
    return excluded, errors


def workflow_runner_files(
    workflow: str, root: Path = ROOT
) -> tuple[set[str], list[str]]:
    covered = set(re.findall(r"flutter test (test/[^\s\\]+_test\.dart)", workflow))
    errors = []
    for runner_name in re.findall(r"python3 (tool/[^\s]+\.py)", workflow):
        runner_path = root / runner_name
        if not runner_path.is_file():
            continue
        runner = runner_path.read_text(encoding="utf-8")
        patterns = re.findall(r"tests\.glob\(['\"]([^'\"]+)['\"]\)", runner)
        patterns.extend(
            re.findall(r"tests\s*/\s*['\"]([^'\"]+_test\.dart)['\"]", runner)
        )
        for pattern in patterns:
            matches = sorted((root / "test").glob(pattern))
            if not matches:
                errors.append(f"dead isolated runner entry: {runner_name}: test/{pattern}")
                continue
            covered.update(str(path.relative_to(root)) for path in matches)
    return covered, errors


def verify() -> None:
    workflow = WORKFLOW_PATH.read_text(encoding="utf-8")
    errors = []

    excluded, exclusion_errors = core_exclusion_files(workflow)
    covered, runner_errors = workflow_runner_files(workflow)
    errors.extend(exclusion_errors)
    errors.extend(runner_errors)
    uncovered = excluded - covered
    if uncovered:
        errors.append(
            "Core exclusions without an isolated runner: " f"{sorted(uncovered)!r}"
        )

    for relative_path, manifest_name in SUITE_MANIFESTS.items():
        path = ROOT / relative_path
        if not path.is_file():
            errors.append(f"missing isolated suite: {relative_path}")
            continue
        if relative_path not in covered:
            errors.append(f"manifest suite has no workflow runner: {relative_path}")
        source_titles = {title for title, _ in extract_test_titles(path.read_text(encoding="utf-8"))}
        contracts = DYNAMIC_CONTRACTS.get(relative_path, ())
        dynamic_titles = {contract.source_title for contract in contracts}
        actual_dynamic_titles = {title for title in source_titles if "$" in title}
        if actual_dynamic_titles != dynamic_titles:
            errors.append(
                f"{relative_path}: untracked dynamic titles; "
                f"source={sorted(actual_dynamic_titles)!r}, contracts={sorted(dynamic_titles)!r}"
            )
        expected_manifest = {title for title in source_titles if "$" not in title}
        for contract in contracts:
            expected_manifest.update(contract.manifest_titles)
            for fragment in contract.workflow_fragments:
                if fragment not in workflow:
                    errors.append(
                        f"{relative_path}: missing dynamic workflow fragment: {fragment}"
                    )
        actual_manifest = manifest_titles(workflow, manifest_name)
        missing = expected_manifest - actual_manifest
        stale = actual_manifest - expected_manifest
        if missing:
            errors.append(f"{manifest_name}: missing titles: {sorted(missing)!r}")
        if stale:
            errors.append(f"{manifest_name}: stale titles: {sorted(stale)!r}")

    for path in sorted((ROOT / "test").glob("*_test.dart")):
        source = path.read_text(encoding="utf-8")
        relative_path = str(path.relative_to(ROOT))
        if re.search(r"@Tags\(\[['\"]isolated-process['\"]\]\)", source):
            if path.name not in workflow:
                errors.append(f"file-level isolated suite is not run: {relative_path}")
        calls = list(re.finditer(r"(?m)^[ \t]*(?:test|testWidgets)\s*\(", source))
        titles = extract_test_titles(source)
        for index, (title, next_start) in enumerate(titles):
            segment = source[calls[index].start() : next_start]
            if re.search(r"tags:\s*['\"]isolated-process['\"]", segment):
                if title not in workflow:
                    errors.append(f"isolated test is not manifested: {relative_path}: {title}")

    if errors:
        raise SystemExit("\n".join(errors))
    print("Stateful test manifests cover every isolated static and dynamic case.")


if __name__ == "__main__":
    verify()
