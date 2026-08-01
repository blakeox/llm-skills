#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


REPO_DIR = Path(__file__).resolve().parent.parent
README_PATH = REPO_DIR / "README.md"
VERSION_PATH = REPO_DIR / "VERSION"
MANIFEST_PATH = REPO_DIR / "skills" / "manifest.txt"


def replace_block(text: str, name: str, replacement: str) -> str:
    pattern = re.compile(
        rf"(<!-- BEGIN generated:{re.escape(name)} -->\n)(.*?)(\n<!-- END generated:{re.escape(name)} -->)",
        re.DOTALL,
    )
    match = pattern.search(text)
    if not match:
        raise ValueError(f"Missing generated block: {name}")
    return text[: match.start()] + match.group(1) + replacement + match.group(3) + text[match.end() :]


def load_version() -> str:
    return VERSION_PATH.read_text(encoding="utf-8").strip()


def load_skills() -> list[str]:
    return [
        line.strip()
        for line in MANIFEST_PATH.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def build_version_block() -> str:
    return f"Current bundle version: `{load_version()}`"


def build_skill_block() -> str:
    return "\n".join(f"- `{skill}`" for skill in load_skills())


def render_readme() -> str:
    readme = README_PATH.read_text(encoding="utf-8")
    readme = replace_block(readme, "bundle-version", build_version_block())
    readme = replace_block(readme, "included-skills", build_skill_block())
    return readme


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync generated README sections.")
    parser.add_argument("--check", action="store_true", help="Fail if README is out of sync.")
    args = parser.parse_args()

    rendered = render_readme()

    if args.check:
        current = README_PATH.read_text(encoding="utf-8")
        if current != rendered:
            print("README.md is out of sync. Run scripts/sync-readme.py.", file=sys.stderr)
            return 1
        return 0

    README_PATH.write_text(rendered, encoding="utf-8")
    print(f"Updated {README_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
