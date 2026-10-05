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
- auditoría cruzada de sprites mediante Arcont.

## Validación

La validación automática usa Godot 4.7.2 oficial, verifica hashes, ejecuta importación/headless smoke test y exporta Android.

La prueba física confirmó ejecución estable alrededor de 60 fps en la primera sesión reportada, pero todavía faltan pruebas normalizadas de temperatura, latencia táctil, 90/120 Hz y sesiones sostenidas.

## Estado visual

El arte actualmente integrado sigue siendo placeholder/prototipo. No representa el objetivo final de Mortofe.

Dirección de producción fijada en `docs/ART_DIRECTION.md`:
- 2D HD no pixel-art;
- oscuro, medieval y barroco;
- mobile-first landscape;
- silueta y lectura de combate por encima de microdetalle;
- arquitectura por capas y profundidad atmosférica;
- personajes runtime en PNG con alpha a partir de masters de mayor calidad.

La especificación cuantitativa inicial vive en `art/production_sprite_spec.json`. El manifiesto actual de SVG permanece sólo para no romper el benchmark/CI y no define el arte final.

## Próximo gate: personaje de producción

No producir el reparto completo todavía.

1. crear una sola pose maestra del protagonista;
2. crear tres poses de lectura (neutral, carrera y ataque) manteniendo exactamente identidad, proporción, arma y cámara;
3. normalizarlas al canvas de producción;
4. auditar pivote, baseline, escala y deriva visual con Arcont;
5. integrarlas temporalmente y capturar el juego a escala móvil real;
6. aprobar/rechazar la dirección visual;
7. sólo si pasa, producir el set de animación del protagonista;
8. después repetir el proceso con un enemigo común.

## Backlog posterior

- normalizador automático de frames en Arcont;
- chequeo de alpha bounds y baseline drift;
- atlas determinista;
- adaptador de importación Godot;
- VFX de combate;
- primer kit arquitectónico barroco;
- iluminación/niebla/parallax;
- HUD final;
- parry y esquiva refinada.
