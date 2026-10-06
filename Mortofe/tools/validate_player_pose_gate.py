#!/usr/bin/env python3
"""Validate Mortofe's three-pose readability and attack-reach production gate."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from statistics import median
from typing import Any


def _pair(value: Any, name: str) -> tuple[float, float]:
    if not (isinstance(value, list) and len(value) == 2 and all(isinstance(v, (int, float)) for v in value)):
        raise ValueError(f"{name} must be [x, y]")
    return float(value[0]), float(value[1])


def validate(contract_path: Path, normalization_report_path: Path) -> tuple[int, dict[str, Any]]:
    contract = json.loads(contract_path.read_text(encoding="utf-8"))
    normalization = json.loads(normalization_report_path.read_text(encoding="utf-8"))
    errors: list[str] = []
    warnings: list[str] = []

    frames = normalization.get("frames")
    if not normalization.get("ok") or not isinstance(frames, list):
        return 1, {"ok": False, "errors": ["normalization report is not successful"], "warnings": []}

    by_output = {frame.get("output"): frame for frame in frames if isinstance(frame, dict)}
    poses = contract.get("poses")
    if not isinstance(poses, dict) or set(poses) != {"idle", "run", "attack"}:
        return 1, {"ok": False, "errors": ["contract.poses must define idle, run and attack"], "warnings": []}

    pivot_x, pivot_y = _pair(contract.get("pivot"), "pivot")
    baseline_y = float(contract.get("baseline_y", pivot_y))
    runtime_scale = float(contract.get("runtime_scale", 0.5))
    max_height_drift = float(contract.get("max_cross_pose_visual_height_drift_pct", 2.0))

    pose_report: dict[str, Any] = {}
    heights: list[float] = []
    hashes: list[str] = []
    for pose, output in poses.items():
        frame = by_output.get(output)
        if frame is None:
            errors.append(f"{pose}: missing normalization result for {output}")
            continue
        bbox = frame.get("output_alpha_bbox")
        if not (isinstance(bbox, list) and len(bbox) == 4 and all(isinstance(v, int) for v in bbox)):
            errors.append(f"{pose}: invalid output_alpha_bbox")
            continue
        x0, y0, x1, y1 = bbox
        height = y1 - y0 + 1
        heights.append(float(height))
        content_hash = frame.get("content_sha256")
        if not isinstance(content_hash, str) or not content_hash:
            errors.append(f"{pose}: missing content_sha256")
        else:
            hashes.append(content_hash)
        if y1 != round(baseline_y):
            errors.append(f"{pose}: alpha bottom {y1} != baseline {baseline_y:g}")
        pose_report[pose] = {
            "path": output,
            "alpha_bbox": bbox,
            "visual_height_px": height,
            "content_sha256": content_hash,
        }

    if len(hashes) == 3 and len(set(hashes)) != 3:
        errors.append("idle/run/attack must be three distinct pixel poses")

    if len(heights) == 3:
        reference = median(heights)
        for pose, data in pose_report.items():
            drift = abs(data["visual_height_px"] - reference) / reference * 100.0
            data["height_drift_pct"] = round(drift, 4)
            if drift > max_height_drift:
                errors.append(f"{pose}: cross-pose visual height drift {drift:.3f}% > {max_height_drift:g}%")

    attack = pose_report.get("attack")
    hitbox = contract.get("attack_hitbox", {})
    reach_report: dict[str, Any] | None = None
    if attack is not None:
        center_x, center_y = _pair(hitbox.get("center"), "attack_hitbox.center")
        size_x, size_y = _pair(hitbox.get("size"), "attack_hitbox.size")
        if size_x <= 0 or size_y <= 0:
            errors.append("attack_hitbox.size values must be > 0")
        else:
            visual_tip = (attack["alpha_bbox"][2] - pivot_x) * runtime_scale
            hitbox_tip = center_x + size_x / 2.0
            gap = hitbox_tip - visual_tip
            max_gap = float(hitbox.get("max_visual_tip_gap_px", 6.0))
            require_cover = bool(hitbox.get("require_hitbox_covers_visual_tip", True))
            if require_cover and gap < 0:
                errors.append(f"attack: visual reach {visual_tip:.3f}px exceeds hitbox reach {hitbox_tip:.3f}px")
            if gap > max_gap:
                errors.append(f"attack: hitbox/visual reach gap {gap:.3f}px > {max_gap:g}px")
            reach_report = {
                "runtime_scale": runtime_scale,
                "visual_tip_from_pivot_px": round(visual_tip, 4),
                "hitbox_tip_from_origin_px": round(hitbox_tip, 4),
                "tip_gap_px": round(gap, 4),
                "hitbox_center": [center_x, center_y],
                "hitbox_size": [size_x, size_y],
            }

    result = {
        "ok": not errors,
        "candidate": contract.get("candidate"),
        "poses": pose_report,
        "attack_reach": reach_report,
        "errors": errors,
        "warnings": warnings,
    }
    return (0 if not errors else 1), result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("contract", type=Path)
    parser.add_argument("normalization_report", type=Path)
    parser.add_argument("--report", type=Path, default=None)
    args = parser.parse_args()
    code, result = validate(args.contract.resolve(), args.normalization_report.resolve())
    payload = json.dumps(result, ensure_ascii=False, indent=2)
    print(payload)
    if args.report is not None:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(payload + "\n", encoding="utf-8")
    return code


if __name__ == "__main__":
    sys.exit(main())
