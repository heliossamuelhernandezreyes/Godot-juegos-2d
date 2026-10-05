#!/usr/bin/env python3
"""Build Mortofe's first production-player master as deterministic RGBA PNG.

The source is intentionally a compact, version-controlled procedural art recipe.
It avoids committing binary image data through connectors that may alter bytes.
The generated PNG is then normalized/audited by pinned ARCONT tooling in CI.
"""
from __future__ import annotations

import argparse
import binascii
import math
import struct
import zlib
from pathlib import Path

W = H = 512
TRANSPARENT = (0, 0, 0, 0)

PALETTE = {
    "edge": (8, 9, 12, 255),
    "black": (18, 20, 25, 255),
    "dark": (31, 34, 42, 255),
    "steel": (59, 64, 72, 255),
    "pale": (175, 170, 154, 255),
    "gold": (165, 116, 52, 255),
    "red": (112, 31, 35, 255),
    "red_dark": (74, 20, 25, 255),
    "red_glow": (194, 43, 38, 255),
}


def _blend(dst: tuple[int, int, int, int], src: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    sa = src[3] / 255.0
    da = dst[3] / 255.0
    oa = sa + da * (1.0 - sa)
    if oa <= 0:
        return TRANSPARENT
    return (
        round((src[0] * sa + dst[0] * da * (1.0 - sa)) / oa),
        round((src[1] * sa + dst[1] * da * (1.0 - sa)) / oa),
        round((src[2] * sa + dst[2] * da * (1.0 - sa)) / oa),
        round(oa * 255.0),
    )


class Canvas:
    def __init__(self, width: int = W, height: int = H):
        self.width = width
        self.height = height
        self.px = [TRANSPARENT] * (width * height)

    def put(self, x: int, y: int, color: tuple[int, int, int, int]) -> None:
        if 0 <= x < self.width and 0 <= y < self.height:
            idx = y * self.width + x
            self.px[idx] = _blend(self.px[idx], color)

    def ellipse(self, box: tuple[int, int, int, int], color: tuple[int, int, int, int]) -> None:
        x0, y0, x1, y1 = box
        cx = (x0 + x1) / 2.0
        cy = (y0 + y1) / 2.0
        rx = max(0.5, (x1 - x0) / 2.0)
        ry = max(0.5, (y1 - y0) / 2.0)
        for y in range(max(0, y0), min(self.height - 1, y1) + 1):
            ny = (y - cy) / ry
            for x in range(max(0, x0), min(self.width - 1, x1) + 1):
                nx = (x - cx) / rx
                if nx * nx + ny * ny <= 1.0:
                    self.put(x, y, color)

    def polygon(self, points: list[tuple[int, int]], fill: tuple[int, int, int, int], outline=None, outline_width: int = 2) -> None:
        ys = [p[1] for p in points]
        y_min, y_max = max(0, min(ys)), min(self.height - 1, max(ys))
        n = len(points)
        for y in range(y_min, y_max + 1):
            scan_y = y + 0.5
            hits: list[float] = []
            for i in range(n):
                x1, yy1 = points[i]
                x2, yy2 = points[(i + 1) % n]
                if yy1 == yy2:
                    continue
                if min(yy1, yy2) <= scan_y < max(yy1, yy2):
                    t = (scan_y - yy1) / (yy2 - yy1)
                    hits.append(x1 + t * (x2 - x1))
            hits.sort()
            for i in range(0, len(hits) - 1, 2):
                xa = max(0, math.ceil(hits[i]))
                xb = min(self.width - 1, math.floor(hits[i + 1]))
                for x in range(xa, xb + 1):
                    self.put(x, y, fill)
        if outline is not None:
            for i in range(n):
                self.line(points[i], points[(i + 1) % n], outline, outline_width)

    def line(self, p0: tuple[int, int], p1: tuple[int, int], color: tuple[int, int, int, int], width: int = 1) -> None:
        x0, y0 = p0
        x1, y1 = p1
        dx, dy = x1 - x0, y1 - y0
        steps = max(abs(dx), abs(dy), 1)
        radius = max(0, width // 2)
        for i in range(steps + 1):
            t = i / steps
            x = round(x0 + dx * t)
            y = round(y0 + dy * t)
            if radius == 0:
                self.put(x, y, color)
            else:
                self.ellipse((x - radius, y - radius, x + radius, y + radius), color)

    def rect(self, box: tuple[int, int, int, int], color: tuple[int, int, int, int]) -> None:
        x0, y0, x1, y1 = box
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.put(x, y, color)

    def png_bytes(self) -> bytes:
        raw = bytearray()
        for y in range(self.height):
            raw.append(0)
            for x in range(self.width):
                raw.extend(self.px[y * self.width + x])
        ihdr = struct.pack(">IIBBBBB", self.width, self.height, 8, 6, 0, 0, 0)
        return PNG_SIG + _chunk(b"IHDR", ihdr) + _chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + _chunk(b"IEND", b"")


PNG_SIG = b"\x89PNG\r\n\x1a\n"


def _chunk(kind: bytes, payload: bytes) -> bytes:
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", binascii.crc32(kind + payload) & 0xFFFFFFFF)


def build() -> bytes:
    c = Canvas()
    E = PALETTE["edge"]
    c.polygon([(225,170),(303,178),(343,243),(363,336),(345,438),(291,468),(237,443),(210,350),(200,252)], PALETTE["red_dark"], E, 3)
    c.polygon([(265,320),(330,342),(381,425),(345,469),(286,430)], (58,18,23,255), E, 3)
    c.polygon([(235,342),(263,344),(257,459),(227,459)], PALETTE["dark"], E, 3)
    c.polygon([(278,344),(306,340),(320,458),(290,459)], PALETTE["dark"], E, 3)
    c.polygon([(220,452),(260,452),(263,472),(216,472)], E, E, 2)
    c.polygon([(286,451),(325,450),(332,471),(288,472)], E, E, 2)
    c.polygon([(226,171),(294,170),(319,228),(308,351),(265,378),(221,350),(208,232)], PALETTE["black"], E, 3)
    c.polygon([(239,180),(280,179),(292,236),(284,326),(260,350),(236,327),(227,236)], PALETTE["steel"], E, 3)
    c.polygon([(250,211),(273,211),(279,341),(260,359),(243,341)], PALETTE["red"], E, 2)
    c.line((240,184),(232,241),PALETTE["gold"],5); c.line((232,241),(240,330),PALETTE["gold"],5)
    c.line((240,330),(260,352),PALETTE["gold"],5); c.line((260,352),(281,330),PALETTE["gold"],5)
    c.line((281,330),(289,241),PALETTE["gold"],5); c.line((289,241),(280,182),PALETTE["gold"],5)
    c.line((247,212),(272,212),PALETTE["gold"],4)
    c.polygon([(206,181),(234,160),(252,181),(230,213),(198,207)], PALETTE["steel"], E, 3)
    c.polygon([(286,181),(311,159),(334,184),(323,211),(297,213)], PALETTE["steel"], E, 3)
    c.polygon([(205,202),(225,213),(211,306),(191,313),(184,287)], PALETTE["dark"], E, 3)
    c.polygon([(188,288),(211,298),(202,328),(180,323)], PALETTE["steel"], E, 3)
    c.polygon([(317,204),(336,211),(344,285),(327,302),(316,272)], PALETTE["dark"], E, 3)
    c.polygon([(326,283),(345,278),(356,306),(337,318)], PALETTE["steel"], E, 3)
    c.rect((247,137,276,174), PALETTE["black"])
    c.polygon([(225,79),(252,56),(286,67),(303,96),(291,151),(260,173),(229,151),(217,105)], PALETTE["steel"], E, 3)
    c.polygon([(227,112),(291,104),(286,124),(231,130)], E, E, 2)
    c.line((236,118),(282,112),PALETTE["red_glow"],4)
    crown=[(231,87),(218,38),(241,54),(250,16),(263,55),(280,27),(281,67),(302,53),(290,93)]
    c.polygon(crown, PALETTE["dark"], E, 3)
    for a,b in zip(crown,crown[1:]): c.line(a,b,PALETTE["gold"],3)
    c.polygon([(220,154),(239,145),(260,171),(280,145),(304,157),(289,185),(229,185)], PALETTE["red"], E, 3)
    c.line((343,306),(433,95),E,15)
    c.line((343,306),(433,95),PALETTE["pale"],7)
    c.polygon([(420,110),(443,53),(454,29),(452,70),(449,101),(435,126)], PALETTE["pale"], E, 3)
    c.line((433,93),(452,43),PALETTE["gold"],4)
    c.line((329,292),(358,306),PALETTE["gold"],9)
    c.ellipse((330,292,350,312),PALETTE["steel"])
    c.line((224,268),(306,268),PALETTE["gold"],5)
    c.polygon([(218,271),(235,279),(228,323),(212,315)], PALETTE["gold"], E, 2)
    c.polygon([(299,273),(316,279),(322,318),(304,322)], PALETTE["gold"], E, 2)
    for x,y in [(241,198),(281,198),(260,244),(259,286)]: c.ellipse((x-4,y-4,x+4,y+4),PALETTE["gold"])
    c.ellipse((205,465,340,481),(0,0,0,70))
    return c.png_bytes()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=Path("Mortofe/art/master/player/player_master_v1.png"))
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    data = build()
    args.output.write_bytes(data)
    print(f"MORTOFE_MASTER {args.output} bytes={len(data)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
