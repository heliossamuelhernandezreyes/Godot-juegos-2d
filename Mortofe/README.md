# Mortofe

**Mortofe** es un action-RPG / metroidvania 2D de fantasía medieval oscura y barroca desarrollado con Godot 4.7.2-stable.

Este proyecto es también el primer consumidor 2D de ARCONT: cada bloqueo técnico debe auditar primero las capacidades existentes de ARCONT y sólo después producir conocimiento, contratos o herramientas reutilizables nuevas.

## Dirección

- Arte: oscuro, barroco, medieval; piedra, metal envejecido, telas pesadas, arquitectura monumental y luz dramática.
- Combate: rápido y preciso, con melee, dash y posteriormente parry/habilidades.
- Mundo: zonas interconectadas con verticalidad, secretos, enemigos y jefes.
- Plataformas objetivo iniciales: PC y Android.

## Primer vertical slice

La primera meta no es contenido masivo. Es demostrar un bucle jugable sólido:

1. locomoción 2D;
2. salto con coyote time y jump buffer;
3. dash;
4. ataque melee;
5. daño y enemigos;
6. cámara;
7. una arena de prueba;
8. HUD/telemetría básica;
9. validación de rendimiento y controles;
10. reemplazo progresivo de placeholders por arte final.

## Regla ARCONT

El código de producción de Mortofe vive aquí. ARCONT conserva sólo conocimiento, evidencia, contratos, benchmarks y herramientas generalizables. Si una capacidad razonable del juego no puede realizarse con la capa pública de Godot, se investiga en este orden: API pública -> plugin/editor tool -> GDExtension -> módulo del motor -> fork, usando el snapshot canónico de Godot fijado por ARCONT para trazabilidad.
