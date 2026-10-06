#!/usr/bin/env python3
"""Build Mortofe's run/attack readability-gate masters from the approved v1 visual language.

The neutral master remains owned by build_player_master.py. This module imports its
Canvas and palette so the v2 gate extends, rather than silently replaces, the approved
player reference.
"""
from __future__ import annotations

import argparse
from pathlib import Path

from build_player_master import Canvas, PALETTE


def _head(c: Canvas, dx: int = 0, dy: int = 0) -> None:
    e = PALETTE["edge"]
    c.rect((247 + dx, 137 + dy, 276 + dx, 174 + dy), PALETTE["black"])
    c.polygon([(225+dx,79+dy),(252+dx,56+dy),(286+dx,67+dy),(303+dx,96+dy),(291+dx,151+dy),(260+dx,173+dy),(229+dx,151+dy),(217+dx,105+dy)], PALETTE["steel"], e, 3)
    c.polygon([(227+dx,112+dy),(291+dx,104+dy),(286+dx,124+dy),(231+dx,130+dy)], e, e, 2)
    c.line((236+dx,118+dy),(282+dx,112+dy), PALETTE["red_glow"], 4)
    crown = [(231+dx,87+dy),(218+dx,38+dy),(241+dx,54+dy),(250+dx,16+dy),(263+dx,55+dy),(280+dx,27+dy),(281+dx,67+dy),(302+dx,53+dy),(290+dx,93+dy)]
    c.polygon(crown, PALETTE["dark"], e, 3)
    for a, b in zip(crown, crown[1:]):
        c.line(a, b, PALETTE["gold"], 3)
    c.polygon([(220+dx,154+dy),(239+dx,145+dy),(260+dx,171+dy),(280+dx,145+dy),(304+dx,157+dy),(289+dx,185+dy),(229+dx,185+dy)], PALETTE["red"], e, 3)


def _chest(c: Canvas, lean: int = 0) -> None:
    e = PALETTE["edge"]
    c.polygon([(226+lean,171),(294+lean,170),(319+lean,228),(308+lean,351),(265+lean,378),(221+lean,350),(208+lean,232)], PALETTE["black"], e, 3)
    c.polygon([(239+lean,180),(280+lean,179),(292+lean,236),(284+lean,326),(260+lean,350),(236+lean,327),(227+lean,236)], PALETTE["steel"], e, 3)
    c.polygon([(250+lean,211),(273+lean,211),(279+lean,341),(260+lean,359),(243+lean,341)], PALETTE["red"], e, 2)
    c.line((240+lean,184),(232+lean,241), PALETTE["gold"], 5); c.line((232+lean,241),(240+lean,330), PALETTE["gold"], 5)
    c.line((240+lean,330),(260+lean,352), PALETTE["gold"], 5); c.line((260+lean,352),(281+lean,330), PALETTE["gold"], 5)
    c.line((281+lean,330),(289+lean,241), PALETTE["gold"], 5); c.line((289+lean,241),(280+lean,182), PALETTE["gold"], 5)
    c.line((247+lean,212),(272+lean,212), PALETTE["gold"], 4)
    c.line((224+lean,268),(306+lean,268), PALETTE["gold"], 5)
    for x, y in [(241,198),(281,198),(260,244),(259,286)]:
        c.ellipse((x+lean-4,y-4,x+lean+4,y+4), PALETTE["gold"])


def build_run() -> bytes:
    c = Canvas(); e = PALETTE["edge"]
    c.polygon([(219,174),(304,181),(342,245),(358,329),(336,414),(294,448),(232,425),(185,362),(150,286),(199,248)], PALETTE["red_dark"], e, 3)
    c.polygon([(231,306),(184,337),(137,395),(192,421),(251,386)], (58,18,23,255), e, 3)
    c.polygon([(239,336),(266,341),(244,421),(198,459),(176,449),(218,398)], PALETTE["dark"], e, 3)
    c.polygon([(277,339),(305,335),(337,420),(372,451),(348,466),(310,438)], PALETTE["dark"], e, 3)
    c.polygon([(166,442),(207,449),(207,470),(159,465)], e, e, 2)
    c.polygon([(342,450),(382,446),(390,465),(348,472)], e, e, 2)
    _chest(c, lean=5)
    c.polygon([(211,183),(239,162),(257,184),(235,214),(202,210)], PALETTE["steel"], e, 3)
    c.polygon([(291,184),(317,164),(340,188),(329,214),(301,215)], PALETTE["steel"], e, 3)
    c.polygon([(211,205),(232,217),(214,284),(183,314),(172,299),(193,270)], PALETTE["dark"], e, 3)
    c.polygon([(174,292),(195,307),(177,332),(157,316)], PALETTE["steel"], e, 3)
    c.polygon([(323,208),(342,218),(361,278),(350,302),(332,276)], PALETTE["dark"], e, 3)
    c.polygon([(345,286),(365,279),(379,304),(359,319)], PALETTE["steel"], e, 3)
    _head(c, dx=4)
    c.line((358,300),(432,105), e, 15); c.line((358,300),(432,105), PALETTE["pale"], 7)
    c.polygon([(419,121),(443,65),(454,38),(452,78),(448,109),(434,137)], PALETTE["pale"], e, 3)
    c.line((432,105),(451,51), PALETTE["gold"], 4)
    c.line((344,287),(372,302), PALETTE["gold"], 9); c.ellipse((345,286,365,307), PALETTE["steel"])
    c.polygon([(222,273),(240,282),(231,324),(214,315)], PALETTE["gold"], e, 2)
    c.polygon([(304,276),(321,283),(329,319),(310,324)], PALETTE["gold"], e, 2)
    c.ellipse((164,465,374,481), (0,0,0,70))
    return c.png_bytes()


def build_attack() -> bytes:
    c = Canvas(); e = PALETTE["edge"]
    c.polygon([(216,174),(299,181),(337,242),(349,326),(328,421),(284,455),(226,431),(184,354),(171,278),(199,240)], PALETTE["red_dark"], e, 3)
    c.polygon([(225,315),(176,350),(145,421),(203,440),(258,394)], (58,18,23,255), e, 3)
    c.polygon([(236,341),(264,344),(248,428),(214,466),(186,462),(220,414)], PALETTE["dark"], e, 3)
    c.polygon([(276,344),(306,340),(332,425),(361,459),(337,470),(299,439)], PALETTE["dark"], e, 3)
    c.polygon([(181,454),(224,457),(224,473),(177,473)], e, e, 2)
    c.polygon([(333,454),(373,450),(382,468),(338,473)], e, e, 2)
    _chest(c, lean=4)
    c.polygon([(208,183),(236,161),(254,183),(232,214),(199,209)], PALETTE["steel"], e, 3)
    c.polygon([(289,184),(314,164),(337,187),(327,213),(299,215)], PALETTE["steel"], e, 3)
    c.polygon([(207,205),(228,217),(211,285),(187,310),(174,295),(190,267)], PALETTE["dark"], e, 3)
    c.polygon([(176,290),(198,303),(184,328),(163,315)], PALETTE["steel"], e, 3)
    c.polygon([(320,205),(340,214),(371,246),(361,265),(327,247)], PALETTE["dark"], e, 3)
    c.polygon([(357,242),(381,244),(390,260),(369,272)], PALETTE["steel"], e, 3)
    _head(c, dx=3)
    c.line((373,257),(499,239), e, 15); c.line((373,257),(499,239), PALETTE["pale"], 7)
    c.polygon([(486,232),(503,239),(490,251),(465,253)], PALETTE["pale"], e, 3)
    c.line((480,245),(501,241), PALETTE["gold"], 4)
    c.line((356,254),(388,249), PALETTE["gold"], 9); c.ellipse((354,245,374,265), PALETTE["steel"])
    c.polygon([(218,274),(236,282),(228,324),(211,315)], PALETTE["gold"], e, 2)
    c.polygon([(301,276),(318,282),(326,319),(307,324)], PALETTE["gold"], e, 2)
    c.ellipse((176,465,366,481), (0,0,0,70))
    return c.png_bytes()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=Path("Mortofe/art/master/player"))
    args = parser.parse_args()
    outputs = {
        "run": ("player_run_master_v1.png", build_run()),
        "attack": ("player_attack_master_v1.png", build_attack()),
    }
    for pose, (name, data) in outputs.items():
        path = args.output_dir / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        print(f"MORTOFE_MASTER pose={pose} path={path} bytes={len(data)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
