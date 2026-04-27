#!/usr/bin/env python3
"""Static content-architecture linter for Software Factory Intensive lessons."""

from __future__ import annotations

import argparse
import json
import re
import sys
import tomllib
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any


CONTRACT_DIR = Path(__file__).with_name("lesson-contracts")

PROMPT_SECTIONS = [
    "Role",
    "Inputs",
    "Graph Work Process",
    "Output Format",
    "Close Behavior",
]

STAGE_LABELS = [
    "needs-plan",
    "needs-architecture",
    "needs-design",
    "needs-tests",
    "ready-to-build",
    "needs-review",
    "ready-to-ship",
]

ROLE_NAMES = [
    "planner",
    "architect",
    "designer",
    "builder",
    "validator",
    "reviewer",
    "release-gate",
]

PACK_RUNTIME_LEAKAGE = re.compile(
    r"\b(?:lesson|workshop|student|lab|curriculum|SFI|Software Factory Intensive|L[0-9]+|C[0-9]+)\b",
    re.IGNORECASE,
)

BANNED_PATTERNS = [
    ("SFI001", re.compile(r"gc all wake-downstream"), "old label scheduler command"),
    ("SFI002", re.compile(r"bd ready --label"), "label queue polling"),
    ("SFI003", re.compile(r"bd create .*--labels?"), "manual stage-labelled bead creation"),
    ("SFI004", re.compile(r"default_rig_includes"), "legacy default rig include wiring"),
    ("SFI005", re.compile(r"packs/all"), "old composition pack dependency"),
    ("SFI006", re.compile(r"append_fragments\s*=\s*\[\"graph-worker\"\]"), "graph-worker as template fragment"),
    ("SFI007", re.compile(r"bd dep graph"), "nonexistent dependency graph command"),
    ("SFI008", re.compile(r"scope\s*=\s*\"workspace\"|workspace scope"), "workspace scope terminology"),
]

TEXT_FILE_SUFFIXES = {
    ".md",
    ".toml",
    ".template",
    ".sh",
    ".bash",
    ".txt",
    ".yaml",
    ".yml",
}


@dataclass
class Finding:
    code: str
    severity: str
    path: str
    line: int | None
    message: str
    hint: str = ""

    def sort_key(self) -> tuple[str, str, int, str]:
        return (self.severity, self.path, self.line or 0, self.code)


def relpath(root: Path, path: Path) -> str:
    try:
        return path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def load_toml(path: Path) -> dict[str, Any]:
    with path.open("rb") as f:
        return tomllib.load(f)


def line_number(text: str, pattern: str | re.Pattern[str]) -> int | None:
    if isinstance(pattern, str):
        for i, line in enumerate(text.splitlines(), start=1):
            if pattern in line:
                return i
    else:
        for i, line in enumerate(text.splitlines(), start=1):
            if pattern.search(line):
                return i
    return None


def add(
    findings: list[Finding],
    code: str,
    path: Path | str,
    message: str,
    *,
    root: Path,
    line: int | None = None,
    severity: str = "ERROR",
    hint: str = "",
) -> None:
    path_text = path if isinstance(path, str) else relpath(root, path)
    findings.append(Finding(code, severity, path_text, line, message, hint))


def contract_files(selected: list[str]) -> list[Path]:
    files = sorted(CONTRACT_DIR.glob("*.toml"))
    if not selected:
        return files
    wanted = {s.upper() for s in selected}
    return [p for p in files if p.stem.upper() in wanted]


def load_contract(path: Path) -> dict[str, Any]:
    data = load_toml(path)
    lesson = data.get("lesson", {})
    if "id" not in lesson:
        raise ValueError(f"{path} missing [lesson].id")
    return data


def active_text_files(root: Path) -> list[Path]:
    roots = [
        root / "README.md",
        root / "activities",
        root / "curriculum",
        root / "my-factory",
        root / "packs",
        root / "reference-project",
    ]
    files: list[Path] = []
    for entry in roots:
        if entry.is_file():
            files.append(entry)
            continue
        if not entry.exists():
            continue
        for path in entry.rglob("*"):
            if not path.is_file():
                continue
            if path.suffix in TEXT_FILE_SUFFIXES or path.name.endswith(".toml.template"):
                files.append(path)
    return sorted(files)


def check_root_factory(root: Path, findings: list[Finding]) -> None:
    city_files = [root / "my-factory" / "city.toml.template", root / "my-factory" / "city.toml"]
    for path in city_files:
        if not path.exists():
            add(findings, "SFI100", path, "city config is missing", root=root)
            continue
        text = read_text(path)
        try:
            data = load_toml(path)
        except tomllib.TOMLDecodeError as exc:
            add(findings, "SFI101", path, f"city config is not valid TOML: {exc}", root=root)
            continue
        if data.get("daemon", {}).get("formula_v2") is not True:
            add(
                findings,
                "SFI102",
                path,
                "FormulaV2 is not permanently enabled",
                root=root,
                hint='add [daemon] formula_v2 = true',
            )
        if "default_rig_includes" in text:
            add(
                findings,
                "SFI103",
                path,
                "city config still uses default_rig_includes",
                root=root,
                line=line_number(text, "default_rig_includes"),
                hint="move active lesson selection to my-factory/pack.toml [defaults.rig.imports.factory]",
            )

    pack_files = [root / "my-factory" / "pack.toml.template", root / "my-factory" / "pack.toml"]
    for path in pack_files:
        if not path.exists():
            add(findings, "SFI110", path, "root pack config is missing", root=root)
            continue
        text = read_text(path)
        try:
            data = load_toml(path)
        except tomllib.TOMLDecodeError as exc:
            add(findings, "SFI111", path, f"root pack config is not valid TOML: {exc}", root=root)
            continue
        factory = (
            data.get("defaults", {})
            .get("rig", {})
            .get("imports", {})
            .get("factory")
        )
        if not isinstance(factory, dict) or "../packs/lessons/" not in str(factory.get("source", "")):
            add(
                findings,
                "SFI112",
                path,
                "root pack does not define the active factory default rig import",
                root=root,
                hint='expected [defaults.rig.imports.factory] source = "../packs/lessons/<lesson>"',
            )
        imports = data.get("imports", {})
        if "all" in imports:
            add(
                findings,
                "SFI113",
                path,
                "root pack still imports packs/all",
                root=root,
                line=line_number(text, re.compile(r"^\[imports\.all\]")),
                hint="use the factory binding instead of the old composition pack",
            )


def check_stale_patterns(root: Path, findings: list[Finding], max_per_pattern: int) -> None:
    counts: dict[str, int] = {code: 0 for code, _, _ in BANNED_PATTERNS}
    suppressed: dict[str, int] = {code: 0 for code, _, _ in BANNED_PATTERNS}
    for path in active_text_files(root):
        text = read_text(path)
        for code, pattern, label in BANNED_PATTERNS:
            for i, line in enumerate(text.splitlines(), start=1):
                if not pattern.search(line):
                    continue
                if counts[code] >= max_per_pattern:
                    suppressed[code] += 1
                    continue
                counts[code] += 1
                add(
                    findings,
                    code,
                    path,
                    f"active content contains {label}",
                    root=root,
                    line=i,
                    hint="rewrite active content to the self-contained FormulaV2 lesson-pack model",
                )
    for code, hidden in suppressed.items():
        if hidden:
            add(
                findings,
                code,
                "active content scan",
                f"{hidden} additional {code} match(es) suppressed",
                root=root,
                severity="WARN",
                hint=f"increase --max-per-pattern above {max_per_pattern} to show more",
            )


def check_lesson(root: Path, contract: dict[str, Any], findings: list[Finding]) -> None:
    lesson = contract["lesson"]
    lesson_id = str(lesson["id"])
    pack_dir = root / str(lesson["pack_dir"])
    formula_name = str(lesson["entry_formula"])
    roles = [str(r) for r in lesson.get("roles", [])]
    docs = [str(d) for d in lesson.get("docs", [])]
    steps = contract.get("steps", [])

    if not pack_dir.exists():
        add(
            findings,
            "SFI200",
            pack_dir,
            f"{lesson_id} lesson pack is missing",
            root=root,
            hint=f"create {relpath(root, pack_dir)} as a self-contained lesson pack",
        )
        check_docs(root, lesson_id, docs, findings)
        return

    pack_toml = pack_dir / "pack.toml"
    if not pack_toml.exists():
        add(findings, "SFI201", pack_toml, f"{lesson_id} pack is missing pack.toml", root=root)
    else:
        pack_text = read_text(pack_toml)
        try:
            pack = load_toml(pack_toml)
        except tomllib.TOMLDecodeError as exc:
            add(findings, "SFI202", pack_toml, f"pack.toml is not valid TOML: {exc}", root=root)
            pack = {}
        if re.search(r"^\s*\[imports(?:\.|\])|^\s*\[\[imports", pack_text, flags=re.MULTILINE):
            add(
                findings,
                "SFI203",
                pack_toml,
                f"{lesson_id} pack imports another pack",
                root=root,
                line=line_number(pack_text, re.compile(r"^\s*\[imports")),
                hint="lesson packs must be self-contained; duplicate definitions instead",
            )
        if pack.get("pack", {}).get("schema") != 2:
            add(
                findings,
                "SFI204",
                pack_toml,
                f"{lesson_id} pack schema is not 2",
                root=root,
                hint="set [pack] schema = 2",
            )

    if (pack_dir / "examples").exists():
        add(
            findings,
            "SFI205",
            pack_dir / "examples",
            "lesson pack contains examples/, which is not a Gas City convention directory",
            root=root,
            severity="WARN",
            hint="remove it or document clearly that it is inert reference material",
        )

    check_roles(root, lesson_id, pack_dir, roles, formula_name, findings)
    check_formula(root, lesson_id, pack_dir, formula_name, steps, findings)
    check_pack_runtime_language(root, lesson_id, pack_dir, findings)
    check_docs(root, lesson_id, docs, findings)


def check_pack_runtime_language(root: Path, lesson_id: str, pack_dir: Path, findings: list[Finding]) -> None:
    for path in sorted(pack_dir.rglob("*")):
        if not path.is_file():
            continue
        if path.name == "pack.toml":
            continue
        if path.suffix not in TEXT_FILE_SUFFIXES and not path.name.endswith(".toml.template"):
            continue
        text = read_text(path)
        for i, line in enumerate(text.splitlines(), start=1):
            if PACK_RUNTIME_LEAKAGE.search(line):
                add(
                    findings,
                    "SFI320",
                    path,
                    f"{lesson_id} pack runtime file contains workshop/lesson-specific language",
                    root=root,
                    line=i,
                    hint="keep lesson framing in tutorials; pack internals should read like a portable small factory",
                )
                break


def check_roles(
    root: Path,
    lesson_id: str,
    pack_dir: Path,
    roles: list[str],
    formula_name: str,
    findings: list[Finding],
) -> None:
    for role in roles:
        agent_dir = pack_dir / "agents" / role
        agent_toml = agent_dir / "agent.toml"
        prompt = agent_dir / "prompt.template.md"
        if not agent_toml.exists():
            add(findings, "SFI300", agent_toml, f"{lesson_id} {role} agent.toml is missing", root=root)
            continue
        try:
            agent = load_toml(agent_toml)
        except tomllib.TOMLDecodeError as exc:
            add(findings, "SFI301", agent_toml, f"{role} agent.toml is not valid TOML: {exc}", root=root)
            agent = {}
        if agent.get("scope") != "rig":
            add(
                findings,
                "SFI302",
                agent_toml,
                f"{lesson_id} {role} agent is not rig-scoped",
                root=root,
                hint='set scope = "rig"',
            )
        default_formula = agent.get("default_sling_formula")
        if default_formula not in (None, formula_name):
            add(
                findings,
                "SFI303",
                agent_toml,
                f"{lesson_id} {role} default_sling_formula points at {default_formula!r}",
                root=root,
                hint=f"expected {formula_name!r} or a pack-level default",
            )
        nudge = str(agent.get("nudge", ""))
        if any(label in nudge for label in STAGE_LABELS) or "bd ready --label" in nudge:
            add(
                findings,
                "SFI304",
                agent_toml,
                f"{lesson_id} {role} nudge still points at label polling",
                root=root,
                line=line_number(read_text(agent_toml), re.compile(r"nudge\s*=")),
                hint="nudge should tell the agent to work the routed formula step",
            )

        if not prompt.exists():
            add(findings, "SFI310", prompt, f"{lesson_id} {role} prompt.template.md is missing", root=root)
            continue
        prompt_text = read_text(prompt)
        for section in PROMPT_SECTIONS:
            if not re.search(rf"^##?\s+{re.escape(section)}\b", prompt_text, flags=re.MULTILINE):
                add(
                    findings,
                    "SFI311",
                    prompt,
                    f"{lesson_id} {role} prompt is missing '{section}' section",
                    root=root,
                    hint="use the shared graph-worker prompt scaffold",
                )
        if "bd ready --label" in prompt_text or "Never stop polling" in prompt_text:
            add(
                findings,
                "SFI312",
                prompt,
                f"{lesson_id} {role} prompt still teaches label polling",
                root=root,
                line=line_number(prompt_text, re.compile(r"bd ready --label|Never stop polling")),
                hint="agents should drain when no routed formula work is ready",
            )


def check_formula(
    root: Path,
    lesson_id: str,
    pack_dir: Path,
    formula_name: str,
    expected_steps: list[dict[str, Any]],
    findings: list[Finding],
) -> None:
    formula_path = pack_dir / "formulas" / f"{formula_name}.toml"
    if not formula_path.exists():
        add(findings, "SFI400", formula_path, f"{lesson_id} entry formula is missing", root=root)
        return

    text = read_text(formula_path)
    try:
        formula = load_toml(formula_path)
    except tomllib.TOMLDecodeError as exc:
        add(findings, "SFI401", formula_path, f"formula is not valid TOML: {exc}", root=root)
        return

    if formula.get("formula") != formula_name:
        add(
            findings,
            "SFI402",
            formula_path,
            f"{lesson_id} formula name does not match the contract",
            root=root,
            hint=f'expected formula = "{formula_name}"',
        )
    if formula.get("version") != 2:
        add(findings, "SFI403", formula_path, f"{lesson_id} formula is not FormulaV2", root=root)
    if formula.get("contract") != "graph.v2":
        add(
            findings,
            "SFI404",
            formula_path,
            f"{lesson_id} formula does not use graph.v2 contract",
            root=root,
            hint='set contract = "graph.v2"',
        )

    for label in STAGE_LABELS:
        if label in text:
            add(
                findings,
                "SFI405",
                formula_path,
                f"{lesson_id} formula contains stage-routing label {label!r}",
                root=root,
                line=line_number(text, label),
                hint="stage order belongs in graph steps, not labels",
            )
            break
    if "gc all wake-downstream" in text:
        add(
            findings,
            "SFI406",
            formula_path,
            f"{lesson_id} formula calls wake-downstream",
            root=root,
            line=line_number(text, "gc all wake-downstream"),
        )

    actual_steps = {str(step.get("id")): step for step in formula.get("steps", []) if "id" in step}
    for expected in expected_steps:
        step_id = str(expected["id"])
        actual = actual_steps.get(step_id)
        if actual is None:
            add(findings, "SFI410", formula_path, f"{lesson_id} formula missing step {step_id!r}", root=root)
            continue

        expected_needs = [str(n) for n in expected.get("needs", [])]
        actual_needs = [str(n) for n in actual.get("needs", [])]
        if actual_needs != expected_needs:
            add(
                findings,
                "SFI411",
                formula_path,
                f"{lesson_id} step {step_id!r} has needs {actual_needs}, expected {expected_needs}",
                root=root,
            )

        metadata = actual.get("metadata", {})
        target = metadata.get("gc.run_target") if isinstance(metadata, dict) else None
        if target != expected.get("target"):
            add(
                findings,
                "SFI412",
                formula_path,
                f"{lesson_id} step {step_id!r} routes to {target!r}",
                root=root,
                hint=f"expected gc.run_target = {expected.get('target')!r}",
            )
        if target in ROLE_NAMES:
            add(
                findings,
                "SFI413",
                formula_path,
                f"{lesson_id} step {step_id!r} uses unqualified target {target!r}",
                root=root,
                hint=f"use factory.{target}",
            )

        expected_artifact = expected.get("artifact")
        if expected_artifact:
            artifact = None
            if isinstance(metadata, dict):
                artifact = (
                    metadata.get("artifact")
                    or metadata.get("artifact_path")
                    or metadata.get("gc.artifact_path")
                )
            if artifact != expected_artifact:
                add(
                    findings,
                    "SFI414",
                    formula_path,
                    f"{lesson_id} step {step_id!r} lacks the expected artifact contract",
                    root=root,
                    hint=f"add metadata artifact_path/artifact = {expected_artifact!r}",
                )


def check_docs(root: Path, lesson_id: str, docs: list[str], findings: list[Finding]) -> None:
    for doc in docs:
        path = root / doc
        if not path.exists():
            add(findings, "SFI500", path, f"{lesson_id} expected doc is missing", root=root)
            continue
        text = read_text(path)
        if "[defaults.rig.imports.factory]" not in text:
            add(
                findings,
                "SFI501",
                path,
                f"{lesson_id} docs omit city-wide active lesson selection",
                root=root,
                hint="show [defaults.rig.imports.factory]",
            )
        if not re.search(r"gc\s+--rig\s+\S+\s+import\s+(?:add|remove)\b", text):
            add(
                findings,
                "SFI502",
                path,
                f"{lesson_id} docs omit existing-rig factory import sync",
                root=root,
                hint="show gc --rig <rig> import remove/add factory",
            )
        if not re.search(r"gc\s+sling\s+\S*/factory\.", text):
            add(
                findings,
                "SFI503",
                path,
                f"{lesson_id} docs omit a binding-qualified gc sling entrypoint",
                root=root,
                hint="show gc sling <rig>/factory.<agent> ...",
            )


def render_text(findings: list[Finding], max_findings: int) -> None:
    errors = sum(1 for f in findings if f.severity == "ERROR")
    warnings = sum(1 for f in findings if f.severity == "WARN")
    print("== lesson-pack-lint ==")
    print(f"Findings: {errors} error(s), {warnings} warning(s)")
    print()

    shown = findings[:max_findings]
    for finding in shown:
        where = finding.path
        if finding.line is not None:
            where += f":{finding.line}"
        print(f"{finding.severity} {finding.code} {where}")
        print(f"  {finding.message}")
        if finding.hint:
            print(f"  hint: {finding.hint}")
    hidden = len(findings) - len(shown)
    if hidden > 0:
        print()
        print(f"... {hidden} finding(s) hidden; increase --max-findings to show more")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", default=".", help="repository root to lint")
    parser.add_argument("--lesson", action="append", default=[], help="lesson id to check, e.g. L2")
    parser.add_argument("--no-repo-scan", action="store_true", help="skip root/stale active-content checks")
    parser.add_argument("--list-lessons", action="store_true", help="list available lesson contracts")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    parser.add_argument("--max-findings", type=int, default=120)
    parser.add_argument("--max-per-pattern", type=int, default=8)
    args = parser.parse_args(argv)

    root = Path(args.repo_root).resolve()
    selected_files = contract_files(args.lesson)
    if args.list_lessons:
        for path in selected_files:
            print(path.stem)
        return 0
    if args.lesson and not selected_files:
        print(f"no matching lesson contracts for: {', '.join(args.lesson)}", file=sys.stderr)
        return 2

    findings: list[Finding] = []
    if not args.no_repo_scan:
        check_root_factory(root, findings)
        check_stale_patterns(root, findings, args.max_per_pattern)

    for path in selected_files:
        try:
            contract = load_contract(path)
        except (OSError, tomllib.TOMLDecodeError, ValueError) as exc:
            add(findings, "SFI900", path, f"invalid lesson contract: {exc}", root=root)
            continue
        check_lesson(root, contract, findings)

    findings.sort(key=lambda f: (f.path, f.line or 0, f.code))
    if args.format == "json":
        print(json.dumps([asdict(f) for f in findings], indent=2))
    else:
        render_text(findings, args.max_findings)

    return 1 if any(f.severity == "ERROR" for f in findings) else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
