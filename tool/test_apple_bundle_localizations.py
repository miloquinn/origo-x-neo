"""Keep Apple's bundle metadata aligned with Flutter's shipped translations."""

import json
from pathlib import Path
import plistlib
import shutil
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
APPLE_LOCALE = {"zh": "zh-Hans", "zh_TW": "zh-Hant"}


class AppleBundleLocalizationsTest(unittest.TestCase):
    def test_declared_languages_match_flutter_translations(self):
        locales = {
            APPLE_LOCALE.get(path.stem.removeprefix("app_"),
                             path.stem.removeprefix("app_"))
            for path in (ROOT / "lib/l10n").glob("app_*.arb")
        }
        for platform in ("ios", "macos"):
            with self.subTest(platform=platform):
                runner = ROOT / platform / "Runner"
                info = plistlib.loads((runner / "Info.plist").read_bytes())
                self.assertEqual(set(info["CFBundleLocalizations"]), locales)
                self.assertEqual(info["CFBundleDisplayName"], "Origo X")
                self.assertEqual(info["CFBundleName"], "Origo X")
                for locale in locales | {"Base"}:
                    strings = (runner / f"{locale}.lproj/InfoPlist.strings").read_text()
                    name = {"zh-Hans": "开元阅读", "zh-Hant": "開元閱讀"}.get(locale, "Origo X")
                    for key in ("CFBundleDisplayName", "CFBundleName"):
                        self.assertIn(f'{key} = "{name}";', strings)

    @unittest.skipUnless(shutil.which("plutil"), "Xcode project parsing needs plutil")
    def test_localized_names_are_in_runner_resources(self):
        for platform in ("ios", "macos"):
            with self.subTest(platform=platform):
                project_dir = ROOT / platform
                project = json.loads(subprocess.check_output([
                    "plutil", "-convert", "json", "-o", "-",
                    str(project_dir / "Runner.xcodeproj/project.pbxproj"),
                ]))
                objects = project["objects"]
                target = next(obj for obj in objects.values()
                              if obj.get("isa") == "PBXNativeTarget"
                              and obj.get("name") == "Runner")
                resources = next(objects[ref] for ref in target["buildPhases"]
                                 if objects[ref]["isa"] == "PBXResourcesBuildPhase")
                groups = [objects[objects[ref]["fileRef"]]
                          for ref in resources["files"]]
                names = next(group for group in groups
                             if group.get("name") == "InfoPlist.strings")
                self.assertEqual(names["isa"], "PBXVariantGroup")
                locales = plistlib.loads(
                    (project_dir / "Runner/Info.plist").read_bytes()
                )["CFBundleLocalizations"]
                self.assertEqual(
                    {objects[ref]["name"] for ref in names["children"]},
                    set(locales) | {"Base"},
                )
                for ref in names["children"]:
                    self.assertTrue((project_dir / "Runner" / objects[ref]["path"]).is_file())


if __name__ == "__main__":
    unittest.main()
