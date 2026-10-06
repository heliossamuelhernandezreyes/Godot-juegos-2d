# Mortofe — estado técnico

## Slice 0.1

Implementado en código:

- proyecto Godot 4.7.2;
- arena de prueba procedural;
- `CharacterBody2D` del jugador;
- aceleración y frenado;
- coyote time;
- jump buffer;
- salto de altura variable;
- doble salto;
- dash;
- melee con hitbox/hurtbox;
- daño, invulnerabilidad, hit-stun y knockback;
- enemigo perseguidor/atacante;
- cámara con smoothing y límites;
- controles táctiles multitouch;
- HUD/telemetría de depuración;
- exportación Android arm64-v8a;
- captura visual automatizada;
- normalización y auditoría cruzada de sprites mediante Arcont.

## Validación

La validación automática usa Godot 4.7.2 oficial, verifica hashes, ejecuta importación/headless smoke test y exporta Android.

La prueba física confirmó ejecución estable alrededor de 60 fps en la primera sesión reportada, pero todavía faltan pruebas normalizadas de temperatura, latencia táctil, 90/120 Hz y sesiones sostenidas.

El pipeline de arte fija Arcont al commit `3dd31bd962999f36de264c5bb364f41624ca7f0b`, reconstruye los masters deterministas, normaliza a canvas/pivote/baseline comunes, audita los PNG y repite la construcción para detectar cualquier pérdida de determinismo.

## Estado visual

Dirección de producción fijada en `docs/ART_DIRECTION.md`:

- 2D HD no pixel-art;
- oscuro, medieval y barroco;
- mobile-first landscape;
- silueta y lectura de combate por encima de microdetalle;
- arquitectura por capas y profundidad atmosférica;
- personajes runtime en PNG con alpha a partir de masters de mayor calidad.

El gate v1 del protagonista aprobó la pose neutral como candidato para prototipado de animación: canvas 384×384, pivote `[192, 350]`, baseline 350 y altura visual objetivo de 300 px antes de la escala runtime 0.5.

## Gate actual: player readability v2

El siguiente gate ya no reutiliza una sola imagen para todo. Produce tres poses deterministas del mismo protagonista:

1. neutral/reference;
2. carrera/readability;
3. ataque/reach.

Las tres pasan por el mismo normalizador y auditor de Arcont. `art/player_pose_gate.json` añade comprobaciones específicas del juego:

- las tres poses deben tener contenido de píxeles distinto;
- baseline común en `y=350`;
- deriva de altura visual entre poses ≤2%;
- la punta visual del ataque no puede sobresalir del hitbox;
- la diferencia entre alcance visual y alcance físico no puede superar 6 px a escala runtime.

El runtime usa la pose de carrera en `run` y la pose ofensiva en `attack`; salto y daño conservan temporalmente la pose neutral hasta que existan sus propios frames. El hitbox de ataque se reposicionó a `center=(44,-50)`, `size=(82,58)` para corresponder con la altura y alcance de la nueva arma.

La captura automatizada `06_player_pose_gate.png` presenta neutral/carrera/ataque lado a lado e incluye el hitbox ofensivo superpuesto para revisión visual.

## Próximo gate después de aprobar v2

No producir todavía todo el reparto.

1. convertir carrera en una secuencia temporal real de 8–10 frames;
2. producir ataque con anticipación, contacto y recuperación dentro de 6–8 frames;
3. comprobar continuidad de identidad, pivote, baseline, silueta y alcance durante toda la secuencia;
4. probar lectura a escala móvil, HUD y fondos de valores distintos;
5. sólo después completar salto, doble salto, dash, hurt y death del protagonista;
6. repetir el mismo procedimiento con el enemigo común.

## Backlog posterior

- atlas determinista de producción;
- adaptador de importación Godot para sets completos;
- VFX de combate;
- primer kit arquitectónico barroco;
- iluminación/niebla/parallax;
- HUD final;
- parry y esquiva refinada;
- benchmarks Android de memoria, temperatura, 90/120 Hz y latencia táctil.
