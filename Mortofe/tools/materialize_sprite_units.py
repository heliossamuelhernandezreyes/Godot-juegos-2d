#!/usr/bin/env python3
"""Materialize Mortofe per-sprite production units from compact encoded sources.

Each sprite unit is self-contained:
  metadata.json
  source.webp.b64   (review/source payload; text-safe for Git tooling)
  master.png        (materialized RGBA source pixels)
  normalized.png    (runtime canvas)
  build_report.json (reproducibility/evidence)

This script does not approve art. It only materializes and normalizes the exact
review source into deterministic runtime assets.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import io
import json
from pathlib import Path
from typing import Any

from PIL import Image


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def alpha_bbox(image: Image.Image, threshold: int) -> tuple[int, int, int, int]:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > threshold else 0)
    bbox = mask.getbbox()
    if bbox is None:
        raise ValueError("sprite has no visible pixels above alpha threshold")
    return tuple(int(v) for v in bbox)


def write_png(image: Image.Image, path: Path) -> bytes:
    buf = io.BytesIO()
    image.convert("RGBA").save(buf, format="PNG", optimize=True, compress_level=9)
    data = buf.getvalue()
    path.write_bytes(data)
    return data


def materialize_unit(unit_dir: Path) -> dict[str, Any]:
    metadata_path = unit_dir / "metadata.json"
    source_path = unit_dir / "source.webp.b64"
    if not metadata_path.exists() or not source_path.exists():
        raise FileNotFoundError(f"incomplete sprite unit: {unit_dir}")

    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    runtime = metadata["runtime"]
    canvas_w, canvas_h = [int(v) for v in runtime["canvas"]]
    pivot_x, pivot_y = [float(v) for v in runtime["pivot"]]
    baseline_y = float(runtime["baseline_y"])
    target_visual_height = float(runtime["target_visual_height"])
    alpha_threshold = int(runtime.get("alpha_threshold", 8))

    if abs(pivot_y - baseline_y) > 1e-6:
        raise ValueError(f"{metadata['id']}: pivot y must equal baseline y for feet-anchored sprites")

    encoded = "".join(source_path.read_text(encoding="ascii").split())
    webp_bytes = base64.b64decode(encoded, validate=True)
    source = Image.open(io.BytesIO(webp_bytes)).convert("RGBA")
    source_bbox = alpha_bbox(source, alpha_threshold)
    source_visual_height = source_bbox[3] - source_bbox[1]
    if source_visual_height <= 0:
        raise ValueError(f"{metadata['id']}: invalid visual height")

    master_bytes = write_png(source, unit_dir / "master.png")

    scale = target_visual_height / float(source_visual_height)
    scaled_size = (
        max(1, round(source.width * scale)),
        max(1, round(source.height * scale)),
    )
    scaled = source.resize(scaled_size, Image.Resampling.LANCZOS)
    scaled_bbox = alpha_bbox(scaled, alpha_threshold)
    scaled_center_x = (scaled_bbox[0] + scaled_bbox[2]) / 2.0
    scaled_bottom_y = float(scaled_bbox[3])

    offset_x = round(pivot_x - scaled_center_x)
    offset_y = round(baseline_y - scaled_bottom_y)

    projected = (
        scaled_bbox[0] + offset_x,
        scaled_bbox[1] + offset_y,
        scaled_bbox[2] + offset_x,
        scaled_bbox[3] + offset_y,
    )
    if projected[0] < 0 or projected[1] < 0 or projected[2] > canvas_w or projected[3] > canvas_h:
        raise ValueError(
            f"{metadata['id']}: normalized sprite would crop: projected={projected}, canvas={(canvas_w, canvas_h)}"
        )

    canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    canvas.alpha_composite(scaled, (offset_x, offset_y))
    normalized_bbox = alpha_bbox(canvas, alpha_threshold)
    normalized_bytes = write_png(canvas, unit_dir / "normalized.png")

    report = {
        "schema_version": 1,
        "id": metadata["id"],
        "status": metadata.get("status", "unknown"),
        "source_encoding": "webp-base64",
        "source_webp_sha256": sha256_bytes(webp_bytes),
        "master_png_sha256": sha256_bytes(master_bytes),
        "normalized_png_sha256": sha256_bytes(normalized_bytes),
        "source_size": [source.width, source.height],
        "source_alpha_bbox": list(source_bbox),
        "target_canvas": [canvas_w, canvas_h],
        "target_pivot": [pivot_x, pivot_y],
        "target_baseline_y": baseline_y,
        "target_visual_height": target_visual_height,
        "alpha_threshold": alpha_threshold,
        "scale": scale,
        "scaled_size": list(scaled_size),
        "offset": [offset_x, offset_y],
        "normalized_alpha_bbox": list(normalized_bbox),
        "normalized_visual_size": [
            normalized_bbox[2] - normalized_bbox[0],
            normalized_bbox[3] - normalized_bbox[1],
        ],
        "baseline_drift_px": abs(normalized_bbox[3] - baseline_y),
        "pivot_center_drift_px": abs(((normalized_bbox[0] + normalized_bbox[2]) / 2.0) - pivot_x),
    }
    (unit_dir / "build_report.json").write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default="Mortofe/art/production")
    args = parser.parse_args()

    root = Path(args.root)
    sources = sorted(root.rglob("source.webp.b64"))
    if not sources:
        raise SystemExit("no sprite source.webp.b64 files found")

    reports = []
    for source in sources:
        report = materialize_unit(source.parent)
        reports.append(report)
        print(
            f"{report['id']}: normalized bbox={report['normalized_alpha_bbox']} "
            f"baseline drift={report['baseline_drift_px']} "
            f"pivot drift={report['pivot_center_drift_px']}"
        )

    print(f"materialized {len(reports)} sprite unit(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
