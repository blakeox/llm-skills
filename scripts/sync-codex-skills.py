#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
import tempfile
from pathlib import Path


ALLOWED_SOURCE_FIELDS = {"name", "description", "user-invocable", "argument-hint"}
CODEX_FIELDS = ("name", "description")
MARKER = ".llm-skills-source.json"
FRONTMATTER = re.compile(r"\A---\n(?P<header>.*?)\n---(?P<body>\n.*)\Z", re.DOTALL)
SKILL_NAME = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
LOCAL_MARKDOWN_REFERENCE = re.compile(r"`((?:\.\./|references/)[^`]+\.md)`")


def parse_scalar(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        if value[0] == '"':
            return json.loads(value)
        return value[1:-1].replace("''", "'")
    return value


def parse_skill(path: Path) -> tuple[dict[str, str], str]:
    text = path.read_text(encoding="utf-8")
    match = FRONTMATTER.match(text)
    if not match:
        raise ValueError(f"{path}: expected YAML frontmatter followed by a body")

    metadata: dict[str, str] = {}
    for line in match.group("header").splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        key, separator, value = line.partition(":")
        if not separator or not key or key != key.strip():
            raise ValueError(f"{path}: unsupported frontmatter line: {line!r}")
        if key in metadata:
            raise ValueError(f"{path}: duplicate frontmatter field {key!r}")
        metadata[key] = parse_scalar(value)

    unexpected = set(metadata) - ALLOWED_SOURCE_FIELDS
    if unexpected:
        names = ", ".join(sorted(unexpected))
        raise ValueError(f"{path}: unsupported source frontmatter field(s): {names}")
    for field in CODEX_FIELDS:
        if not metadata.get(field):
            raise ValueError(f"{path}: missing required frontmatter field {field!r}")
    if not SKILL_NAME.fullmatch(metadata["name"]):
        raise ValueError(f"{path}: invalid skill name {metadata['name']!r}")
    if len(metadata["name"]) > 64:
        raise ValueError(f"{path}: skill name exceeds 64 characters")
    description = metadata["description"]
    if len(description) > 1024 or "<" in description or ">" in description:
        raise ValueError(f"{path}: description violates Codex length or character constraints")
    if not any(phrase in description for phrase in ("Use when", "Use immediately", "Use after", "Use for")):
        raise ValueError(f"{path}: description must state when to use the skill")
    return metadata, match.group("body")


def display_name(name: str) -> str:
    replacements = {
        "a11y": "A11y",
        "api": "API",
        "aws": "AWS",
        "devex": "DevEx",
        "ui": "UI",
        "ux": "UX",
    }
    return " ".join(replacements.get(part, part.capitalize()) for part in name.split("-"))


def short_description(description: str) -> str:
    summary = description.split(". ", 1)[0].rstrip(".")
    if len(summary) <= 64:
        return summary
    clipped = summary[:61].rsplit(" ", 1)[0].rstrip(" ,;:-")
    return f"{clipped}..."


def render_invocations(text: str, skill_names: set[str]) -> str:
    invocation = re.compile(r"(?<![\w$])/((?:" + "|".join(re.escape(name) for name in sorted(skill_names, key=len, reverse=True)) + r"))\b")
    return invocation.sub(r"$\1", text)


def render_skill(metadata: dict[str, str], body: str, skill_names: set[str]) -> str:
    body = render_invocations(body, skill_names)
    return (
        "---\n"
        f"name: {metadata['name']}\n"
        f"description: {json.dumps(metadata['description'], ensure_ascii=False)}\n"
        f"---{body}"
    )


def render_openai_yaml(metadata: dict[str, str]) -> str:
    name = metadata["name"]
    hint = metadata.get("argument-hint", "the target")
    prompt = f"Use ${name} to work on {hint}."
    values = {
        "display_name": display_name(name),
        "short_description": short_description(metadata["description"]),
        "default_prompt": prompt,
    }
    return "interface:\n" + "".join(
        f"  {key}: {json.dumps(value, ensure_ascii=False)}\n" for key, value in values.items()
    )


def load_manifest(source_root: Path) -> list[str]:
    manifest = source_root / "skills" / "manifest.txt"
    skills = [line.strip() for line in manifest.read_text(encoding="utf-8").splitlines() if line.strip()]
    if len(skills) != len(set(skills)):
        raise ValueError(f"{manifest}: duplicate entries")
    invalid = [skill for skill in skills if skill != "_house-style" and not SKILL_NAME.fullmatch(skill)]
    if invalid:
        raise ValueError(f"{manifest}: invalid skill names: {', '.join(invalid)}")
    published = {skill for skill in skills if skill != "_house-style"}
    discovered = {path.parent.name for path in (source_root / "skills").glob("*/SKILL.md")}
    if published != discovered:
        missing = ", ".join(sorted(published - discovered)) or "none"
        unpublished = ", ".join(sorted(discovered - published)) or "none"
        raise ValueError(f"{manifest}: missing={missing}; unpublished={unpublished}")
    return skills


def prepare_skill(source_root: Path, skill: str, staging_root: Path, skill_names: set[str]) -> Path:
    source = source_root / "skills" / skill
    if not source.is_dir():
        raise ValueError(f"Missing source directory: {source}")

    staged = staging_root / skill
    shutil.copytree(source, staged)
    skill_md = staged / "SKILL.md"
    if skill == "_house-style":
        if skill_md.exists():
            raise ValueError(f"{source}: shared resources must not masquerade as a skill")
    else:
        metadata, body = parse_skill(source / "SKILL.md")
        if metadata["name"] != skill:
            raise ValueError(f"{source}: frontmatter name {metadata['name']!r} must match directory")
        for relative in LOCAL_MARKDOWN_REFERENCE.findall((source / "SKILL.md").read_text(encoding="utf-8")):
            referenced = (source / relative).resolve()
            if not referenced.is_file():
                raise ValueError(f"{source}: missing referenced file {relative}")
        rendered = render_skill(metadata, body, skill_names)
        unresolved = [name for name in skill_names if re.search(rf"(?<![\w$])/{re.escape(name)}\b", rendered)]
        if unresolved:
            raise ValueError(f"{source}: unresolved Codex skill invocation(s): {', '.join(sorted(unresolved))}")
        skill_md.write_text(rendered, encoding="utf-8")
        agents = staged / "agents"
        agents.mkdir(exist_ok=True)
        openai_yaml = render_openai_yaml(metadata)
        if not 25 <= len(short_description(metadata["description"])) <= 64:
            raise ValueError(f"{source}: generated short description must be 25-64 characters")
        if f"${skill}" not in openai_yaml:
            raise ValueError(f"{source}: generated default prompt must mention ${skill}")
        (agents / "openai.yaml").write_text(openai_yaml, encoding="utf-8")

    for markdown in staged.rglob("*.md"):
        rendered_markdown = render_invocations(markdown.read_text(encoding="utf-8"), skill_names)
        unresolved = [
            name
            for name in skill_names
            if re.search(rf"(?<![\w$])/{re.escape(name)}\b", rendered_markdown)
        ]
        if unresolved:
            raise ValueError(
                f"{source}: unresolved Codex skill invocation(s) in {markdown.relative_to(staged)}: "
                + ", ".join(sorted(unresolved))
            )
        markdown.write_text(rendered_markdown, encoding="utf-8")

    marker = {"repository": str(source_root.resolve()), "skill": skill}
    (staged / MARKER).write_text(json.dumps(marker, indent=2) + "\n", encoding="utf-8")
    return staged


def marker_data(target: Path) -> dict[str, str] | None:
    marker = target / MARKER
    if not marker.is_file():
        return None
    try:
        data = json.loads(marker.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None
    return data if isinstance(data, dict) else None


def owned_target(target: Path, source_root: Path, skill: str) -> bool:
    return marker_data(target) == {"repository": str(source_root.resolve()), "skill": skill}


def repository_symlink_group(target: Path, source_root: Path) -> str | None:
    if not target.is_symlink():
        return None
    resolved = target.resolve()
    roots = {
        "skills": (source_root / "skills").resolve(),
        "openclaw": (source_root / "openclaw" / "skills").resolve(),
    }
    for group, root in roots.items():
        try:
            relative = resolved.relative_to(root)
        except ValueError:
            continue
        if len(relative.parts) == 1 and relative.name == target.name:
            return group
    return None


def retired_owned_targets(destination: Path, source_root: Path, active_skills: set[str]) -> list[Path]:
    retired: list[Path] = []
    for target in destination.iterdir():
        symlink_group = repository_symlink_group(target, source_root)
        if symlink_group:
            if symlink_group == "openclaw" or target.name not in active_skills:
                retired.append(target)
            continue
        if not target.is_dir():
            continue
        data = marker_data(target)
        if not data or data.get("repository") != str(source_root.resolve()):
            continue
        skill = data.get("skill")
        if not isinstance(skill, str) or target.name != skill:
            continue
        if skill not in active_skills:
            retired.append(target)
    return sorted(retired)


def is_unowned_collision(target: Path, source_root: Path, skill: str) -> bool:
    if not target.exists() and not target.is_symlink():
        return False
    if target.is_symlink():
        return repository_symlink_group(target, source_root) != "skills"
    return not owned_target(target, source_root, skill)


def file_map(root: Path) -> dict[str, bytes]:
    return {
        str(path.relative_to(root)): path.read_bytes()
        for path in sorted(root.rglob("*"))
        if path.is_file()
    }


def verify(expected: Path, target: Path) -> list[str]:
    if not target.is_dir() or target.is_symlink():
        return [f"MISSING: {target}"]
    expected_files = file_map(expected)
    target_files = file_map(target)
    problems: list[str] = []
    for relative in sorted(expected_files.keys() - target_files.keys()):
        problems.append(f"MISSING: {target / relative}")
    for relative in sorted(target_files.keys() - expected_files.keys()):
        problems.append(f"STALE: {target / relative}")
    for relative in sorted(expected_files.keys() & target_files.keys()):
        if expected_files[relative] != target_files[relative]:
            problems.append(f"DRIFTED: {target / relative}")
    return problems


def install(staged: Path, target: Path, source_root: Path, skill: str) -> None:
    if target.exists() or target.is_symlink():
        if target.is_symlink():
            if repository_symlink_group(target, source_root) != "skills":
                raise ValueError(f"Refusing to overwrite unowned destination: {target}")
            target.unlink()
            staged.rename(target)
            return
        if not owned_target(target, source_root, skill):
            raise ValueError(f"Refusing to overwrite unowned destination: {target}")
        backup = target.with_name(f".{target.name}.previous")
        if backup.exists():
            shutil.rmtree(backup)
        target.rename(backup)
        try:
            staged.rename(target)
        except Exception:
            backup.rename(target)
            raise
        shutil.rmtree(backup)
    else:
        staged.rename(target)


def main() -> int:
    parser = argparse.ArgumentParser(description="Render shared LLM skills into Codex-compatible copies.")
    parser.add_argument("--source", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--dest", type=Path, default=Path.home() / ".codex" / "skills")
    parser.add_argument("--check", action="store_true", help="Verify installed copies without changing them.")
    args = parser.parse_args()

    source_root = args.source.resolve()
    destination = args.dest.expanduser().resolve()
    destination.mkdir(parents=True, exist_ok=True)
    skills = load_manifest(source_root)
    active_skills = set(skills)
    skill_names = {skill for skill in skills if skill != "_house-style"}
    failures: list[str] = []
    retired_targets = retired_owned_targets(destination, source_root, active_skills)

    if not args.check:
        collisions = [
            destination / skill
            for skill in skills
            if is_unowned_collision(destination / skill, source_root, skill)
        ]
        if collisions:
            for collision in collisions:
                print(f"ERROR: Refusing to overwrite unowned destination: {collision}", file=sys.stderr)
            return 1
    else:
        failures.extend(f"STALE: retired repository-owned skill {target}" for target in retired_targets)

    with tempfile.TemporaryDirectory(prefix="llm-skills-codex-") as temporary:
        staging_root = Path(temporary)
        staged_skills: dict[str, Path] = {}
        for skill in skills:
            try:
                staged_skills[skill] = prepare_skill(source_root, skill, staging_root, skill_names)
            except (OSError, ValueError) as error:
                failures.append(f"ERROR: {error}")

        if not failures:
            for skill, staged in staged_skills.items():
                target = destination / skill
                try:
                    if args.check:
                        failures.extend(verify(staged, target))
                    else:
                        install(staged, target, source_root, skill)
                        print(f"Installed {skill} -> {target}")
                except (OSError, ValueError) as error:
                    failures.append(f"ERROR: {error}")

        if not args.check and not failures:
            for target in retired_targets:
                if target.is_symlink():
                    target.unlink()
                else:
                    shutil.rmtree(target)
                print(f"Removed retired repository-owned skill -> {target}")

    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    action = "Verification" if args.check else "Installation"
    print(f"{action} passed for {len(skills) - 1} Codex skills plus shared house style.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
