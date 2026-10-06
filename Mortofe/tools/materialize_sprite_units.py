#!/usr/bin/env python3
"""Materialize Mortofe per-sprite production units from encoded review sources.

Each sprite unit is self-contained:
  metadata.json
  source.webp.b64 OR source.webp.b64.partNN
  master.png
  normalized.png
  build_report.json

Chunked sources exist because some Git transports are text-oriented. When chunks
exist they always take precedence over the legacy single source file. This
script does not approve art; it materializes and normalizes the exact review
source deterministically.
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


def read_encoded_source(unit_dir: Path) -> tuple[bytes, str, int]:
    source_path = unit_dir / "source.webp.b64"
    source_parts = sorted(unit_dir.glob("source.webp.b64.part*"))

    if source_parts:
        encoded = "".join(
            "".join(part.read_text(encoding="ascii").split())
            for part in source_parts
        )
        source_encoding = "webp-base64-parts"
        source_part_count = len(source_parts)
    elif source_path.exists():
        encoded = "".join(source_path.read_text(encoding="ascii").split())
        source_encoding = "webp-base64"
        source_part_count = 1
    else:
        raise FileNotFoundError(f"sprite unit has no encoded source: {unit_dir}")

    try:
        payload = base64.b64decode(encoded, validate=True)
    except Exception as exc:
        raise ValueError(f"invalid base64 sprite source in {unit_dir}: {exc}") from exc

    return payload, source_encoding, source_part_count


def materialize_unit(unit_dir: Path) -> dict[str, Any]:
    metadata_path = unit_dir / "metadata.json"
    if not metadata_path.exists():
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

    webp_bytes, source_encoding, source_part_count = read_encoded_source(unit_dir)
    source_sha = sha256_bytes(webp_bytes)
    expected_source_sha = metadata.get("source", {}).get("sha256")
    if expected_source_sha and source_sha != expected_source_sha:
        raise ValueError(
            f"{metadata['id']}: source sha256 mismatch: expected={expected_source_sha}, actual={source_sha}"
        )

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
        "schema_version": 2,
        "id": metadata["id"],
        "status": metadata.get("status", "unknown"),
        "source_encoding": source_encoding,
        "source_part_count": source_part_count,
        "source_webp_sha256": source_sha,
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
    metadata_files = sorted(root.rglob("metadata.json"))
    unit_dirs = [
        path.parent
        for path in metadata_files
        if (path.parent / "source.webp.b64").exists()
        or any(path.parent.glob("source.webp.b64.part*"))
    ]
    if not unit_dirs:
        raise SystemExit("no encoded sprite units found")

    reports = []
    for unit_dir in unit_dirs:
        report = materialize_unit(unit_dir)
        reports.append(report)
        print(
            f"{report['id']}: source={report['source_size']} "
            f"normalized bbox={report['normalized_alpha_bbox']} "
            f"baseline drift={report['baseline_drift_px']} "
            f"pivot drift={report['pivot_center_drift_px']}"
        )

    print(f"materialized {len(reports)} sprite unit(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
