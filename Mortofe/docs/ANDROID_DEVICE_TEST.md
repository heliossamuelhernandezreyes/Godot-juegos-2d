# Mortofe — Android device validation protocol

Este protocolo convierte una prueba manual en evidencia reproducible para Mortofe y ARCONT.

## Build bajo prueba

- Motor: Godot 4.7.2-stable.
- Plataforma primaria: Android arm64-v8a.
- Renderer baseline: Compatibility / OpenGL.
- Orientación: horizontal.
- Controles: multitouch virtual joystick + ataque + salto + dash.
- Locomoción actual: salto variable + coyote time + jump buffer + doble salto + dash.
- Combate actual: Hitbox2D/Hurtbox2D con detección por señal y escaneo de solapamientos durante la ventana activa.

## Secuencia mínima

1. Instalar el APK debug generado por CI.
2. Abrir Mortofe en horizontal y confirmar que HUD y controles no queden debajo de notch/cutout.
3. Esperar al menos 10 segundos para que aparezca la primera muestra de telemetría en el HUD.
4. Mantener movimiento con el joystick y, sin soltarlo, probar ataque, salto y dash con dedos distintos.
5. Probar 20 saltos normales variando cuánto tiempo se mantiene el botón para confirmar salto corto/largo.
6. Probar al menos 20 dobles saltos: segundo toque en subida, cerca del ápice y durante la caída.
7. Caminar fuera de una plataforma sin saltar, esperar a que termine coyote time y comprobar que sólo quede un salto aéreo utilizable.
8. Hacer al menos 20 dashes y recorrer la arena, incluida pendiente, plataforma one-way y plataforma móvil.
9. Golpear a cada enemigo varias veces y confirmar tres señales visuales: reducción de marcas de vida, flash/hurt sprite y knockback/hit-stun.
10. Confirmar que un enemigo desaparece al agotar su vida y que el contador de enemigos disminuye.
11. Dejar que un enemigo golpee al jugador y confirmar pérdida de HP, knockback e invulnerabilidad breve.
12. Jugar de forma continua durante al menos 5 minutos para detectar stutter, pérdida de input o calentamiento temprano.

## Evidencia a capturar

- Modelo del dispositivo.
- Resolución visible reportada.
- Renderer y vendor si se obtiene por log.
- p50, p95 y p99 observados en el HUD después de actividad real.
- Si movimiento + ataque funciona simultáneamente.
- Si movimiento + salto funciona simultáneamente.
- Si movimiento + dash funciona simultáneamente.
- Si ataque + salto o ataque + dash accidentalmente interfieren entre sí.
- Si salto variable y doble salto se sienten distinguibles y consistentes.
- Si el daño del jugador al enemigo se registra en todos los rangos razonables del ataque.
- Si algún control invade la zona segura del sistema.
- Captura de pantalla del HUD y controles.
- Observaciones de ergonomía: botones demasiado grandes/pequeños, demasiado juntos o fuera del alcance cómodo del pulgar.

## Criterios iniciales

No se promueve `touch_controls_2d` a READY sólo porque el APK abra. Se requiere evidencia de dispositivo real y multitouch correcto.

`combat_2d` tampoco se promueve sólo por pasar parsing: debe demostrarse en dispositivo que las ventanas de ataque registran solapamientos existentes, no duplican impactos por ventana y que el feedback coincide con el cambio real de vida.

El rendimiento tampoco se considera validado con una sola cifra. La primera meta es una sesión estable a 60 fps; después se construirá una matriz 60/90/120 Hz y perfiles de calidad según dispositivo.

## Salida para ARCONT

La evidencia debe convertirse en un registro normalizado que incluya build/commit, dispositivo, renderer, resolución, frame-time percentiles, resultado de multitouch, doble salto, combate y notas de ergonomía. Los problemas generales se corrigen en ARCONT; los ajustes artísticos o de diseño específicos permanecen en Mortofe.
