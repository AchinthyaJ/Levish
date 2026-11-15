"""Release guards: the version strings agree, and shipped files hold no machine-specific paths."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


class VersionTests(unittest.TestCase):
    def test_version_file_matches_qml_constant(self):
        file_version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
        js = (ROOT / "quickshell" / "common" / "Version.js").read_text(encoding="utf-8")
        match = re.search(r'var version = "([^"]+)"', js)
        self.assertIsNotNone(match, "Version.js has no `var version` line")
        self.assertEqual(file_version, match.group(1))

    def test_version_is_semver(self):
        file_version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
        self.assertRegex(file_version, r"^\d+\.\d+\.\d+$")


class ShippedDefaultsTests(unittest.TestCase):
    """Files in the repository must not contain one user's home directory."""

    SHIPPED = [
        ROOT / "config" / "config.json",
        ROOT / "config" / "pinned-apps.json",
    ]

    def test_no_home_directory_paths_in_shipped_config(self):
        for path in self.SHIPPED:
            text = path.read_text(encoding="utf-8")
            self.assertNotIn("/home/", text, f"{path.name} contains a home-directory path")

    def test_no_home_directory_paths_in_quickshell_sources(self):
        offenders = []
        for path in (ROOT / "quickshell").rglob("*.qml"):
            if "/home/" in path.read_text(encoding="utf-8"):
                offenders.append(str(path.relative_to(ROOT)))
        self.assertEqual(offenders, [], "hard-coded home-directory paths found")


if __name__ == "__main__":
    unittest.main()
