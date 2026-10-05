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
- dash;
- melee con `Area2D`;
- daño, invulnerabilidad y knockback;
- enemigo perseguidor/atacante;
- cámara con smoothing y límites;
- HUD de depuración.

## Validación

La validación automática usa el binario oficial `Godot_v4.7.2-stable_linux.x86_64.zip` y verifica SHA-256 antes de ejecutar importación headless y un smoke run.

El arte actual es placeholder dibujado por código. No representa el arte final; la dirección final sigue siendo medieval, barroca y oscura.

## Próximo bloque

1. resolver cualquier error que detecte CI;
2. instrumentar locomoción y combate;
3. controles táctiles Android;
4. pipeline de sprites/atlas;
5. primer escenario con assets 2D;
6. enemigo con estados y telegraph de ataque;
7. parry y esquiva refinada.
