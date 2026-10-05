# Mortofe — Art Direction

Status: production target for the mobile vertical slice.

Arcont references:
- `docs/knowledge/GODOT_2D_SPRITE_PIPELINE.md`
- `docs/knowledge/GODOT_2D_MOBILE_BASELINE.md`
- `schemas/sprite-animation-manifest.schema.json`

## Product read

Mortofe is a landscape, mobile-first, non-pixel-art 2D action game. The target visual language is dark medieval/baroque rather than generic gothic fantasy.

The visual priority order is:
1. gameplay readability on a phone,
2. strong silhouette,
3. animation readability,
4. atmosphere and depth,
5. ornamental detail.

Detail that disappears at gameplay scale is secondary to silhouette, value separation and motion clarity.

## Display target

- logical design size: 1280x720,
- stretch: `canvas_items` + `expand`,
- landscape,
- primary target: 60 fps on baseline Android hardware,
- high-refresh modes are optional and must be benchmarked,
- composition must remain readable on wider phones and tablet/foldable aspect ratios.

At the 720p logical height, the normal player combat silhouette should occupy roughly 18–22% of visible screen height. Common enemies should remain in the same readability class; elites and bosses may exceed it intentionally.

## Character style

### Player

The player must read immediately as the visual focal point even against dark architecture.

Required visual anchors:
- a unique head/helmet or face silhouette,
- a clearly readable primary weapon,
- one major secondary shape such as cloak, coat-tail or mantle,
- restrained baroque ornament concentrated at focal zones,
- dark metal/cloth masses separated by controlled warm or pale accents,
- no micro-detail used as a substitute for silhouette design.

The player should not look like a generic heavy knight. The shape language should be elegant, severe and slightly ceremonial: tall verticals, controlled asymmetry, layered cloth/metal and deliberate negative spaces.

### Enemies

Common enemies must use simpler silhouettes and lower visual hierarchy than the player. Their faction identity should come from repeated shape motifs rather than copying the protagonist's detail density.

Enemy attacks must telegraph through pose and silhouette before relying on particles or UI indicators.

## Baroque environment language

The environment should move away from rectangles + triangular roofs. Reusable modules should include:
- pointed and round arches,
- buttresses,
- columns and pilasters,
- broken cornices,
- balconies,
- statues and niches,
- bells, towers and domes,
- tall windows and stained glass,
- bridges, stairs and retaining walls,
- ruined ornament that still preserves architectural rhythm.

Darkness must contain information. Use layered silhouettes, fog, distant emissive windows, moonlight, firelight and atmospheric depth instead of large uniform black areas.

## Depth model

Gameplay scenes should be composed in layers:
1. foreground occluders/details,
2. gameplay plane,
3. near architecture,
4. distant city/monuments,
5. sky/moon/fog.

Parallax should support depth without making collision readability ambiguous.

## Lighting and value hierarchy

- Player and enemies require clear local contrast against the gameplay plane.
- Important combat silhouettes should survive desaturation.
- Warm accents (fire, gold, oxidized red) should be sparse and meaningful.
- Moon/cold ambient light may carry the broader scene.
- Avoid uniformly crushing every midtone into black.
- Rim light is allowed as a readability tool, not as a permanent neon outline.

## Sprite philosophy

Mortofe runtime character art should be raster PNG with alpha, produced from higher-quality master artwork. SVG may remain useful for UI, debug or vector source work, but it is not the default runtime character format.

The first production candidate must be validated in-game before producing a full cast.

Generated artwork must be treated as source material that still has to pass Arcont's consistency, baseline, pivot, silhouette and mobile-readability checks.

## Animation language

Motion should feel fast enough for mobile action but carry weight:
- clear anticipation,
- decisive active pose,
- readable recovery,
- cloak/cloth follow-through,
- weapon arcs that match the gameplay hit window,
- no excessive smear that hides weapon reach.

The gameplay collider does not follow decorative cloth or weapon trails.

## HUD and touch controls

Touch controls are gameplay infrastructure, not decorative foreground art. They should remain legible but visually subordinate to the scene.

The combat area must not routinely occur underneath opaque control art. Idle controls should use restrained opacity and safe-area-aware placement. Interactive target sizes must remain mobile-appropriate even if visible icons are smaller.

## First vertical-slice art gate

Do not mass-produce sprites until a single player candidate passes all of these checks:
- strong silhouette at gameplay scale,
- correct baseline/pivot,
- weapon reach visually agrees with combat reach,
- readable over at least three representative background values,
- readable underneath the mobile HUD,
- no costume/proportion drift across test poses,
- acceptable memory/import behavior on Android,
- no visible jitter when changing states.

After the player passes, produce one common enemy using the same pipeline. Only then expand animation and environment production.
