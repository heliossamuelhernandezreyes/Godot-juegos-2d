#!/usr/bin/env python3
"""Generate Mortofe production art and pass it through pinned ARCONT tooling."""
from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

ARCONT_COMMIT = "3dd31bd962999f36de264c5bb364f41624ca7f0b"
ARCONT_RAW = f"https://raw.githubusercontent.com/heliossamuelhernandezreyes/Arcont/{ARCONT_COMMIT}/tools"


def run(*args: str) -> None:
    print("+", " ".join(args), flush=True)
    subprocess.run(args, check=True)


def download(url: str, path: Path) -> None:
    print("+ fetch", url, flush=True)
    with urllib.request.urlopen(url, timeout=30) as response:
        path.write_bytes(response.read())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=Path("Mortofe"))
    parser.add_argument("--audit", action="store_true")
    parser.add_argument("--report-dir", type=Path, default=None)
    args = parser.parse_args()

    project_root = args.project_root.resolve()
    repo_root = project_root.parent
    generator = project_root / "tools" / "build_player_master.py"
    plan = project_root / "art" / "normalization_plan.json"
    manifest = project_root / "art" / "production_sprite_manifest.json"

    run(sys.executable, str(generator), "--output", str(project_root / "art/master/player/player_master_v1.png"))

    report_dir = args.report_dir.resolve() if args.report_dir else None
    if report_dir:
        report_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="mortofe-arcont-") as tmp:
        tmpdir = Path(tmp)
        normalizer = tmpdir / "png_sprite_normalize.py"
        auditor = tmpdir / "png_sprite_audit.py"
        download(f"{ARCONT_RAW}/png_sprite_normalize.py", normalizer)
        download(f"{ARCONT_RAW}/png_sprite_audit.py", auditor)

        normalize_cmd = [
            sys.executable,
            str(normalizer),
            str(plan),
            "--project-root",
            str(project_root),
        ]
        if report_dir:
            normalize_cmd.extend(["--report", str(report_dir / "normalization_report.json")])
        run(*normalize_cmd)

        if args.audit:
            if report_dir:
                audit_path = report_dir / "sprite_audit.json"
                print("+ audit ->", audit_path, flush=True)
                with audit_path.open("w", encoding="utf-8") as handle:
                    subprocess.run(
                        [sys.executable, str(auditor), str(manifest), "--project-root", str(project_root)],
                        check=True,
                        stdout=handle,
                        text=True,
                    )
                print(audit_path.read_text(encoding="utf-8"), end="")
            else:
                run(sys.executable, str(auditor), str(manifest), "--project-root", str(project_root))

    print(f"MORTOFE_PRODUCTION_ART_READY arcont={ARCONT_COMMIT} root={project_root.relative_to(repo_root)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
