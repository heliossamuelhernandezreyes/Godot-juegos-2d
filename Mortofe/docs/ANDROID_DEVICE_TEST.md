# Mortofe — Android device validation protocol

Este protocolo convierte una prueba manual en evidencia reproducible para Mortofe y ARCONT.

## Build bajo prueba

- Motor: Godot 4.7.2-stable.
- Plataforma primaria: Android arm64-v8a.
- Renderer baseline: Compatibility / OpenGL.
- Orientación: horizontal.
- Controles: multitouch virtual joystick + ataque + salto + dash.

## Secuencia mínima

1. Instalar el APK debug generado por CI.
2. Abrir Mortofe en horizontal y confirmar que HUD y controles no queden debajo de notch/cutout.
3. Esperar al menos 10 segundos para que aparezca la primera muestra de telemetría en el HUD.
4. Mantener movimiento con el joystick y, sin soltarlo, probar ataque, salto y dash con dedos distintos.
5. Hacer al menos 20 saltos, 20 dashes y 30 ataques mientras se recorre toda la arena.
6. Combatir a los tres enemigos y provocar al menos una recepción de daño.
7. Jugar de forma continua durante al menos 5 minutos para detectar stutter, pérdida de input o calentamiento temprano.

## Evidencia a capturar

- Modelo del dispositivo.
- Resolución visible reportada.
- Renderer y vendor si se obtiene por log.
- p50, p95 y p99 observados en el HUD después de actividad real.
- Si movimiento + ataque funciona simultáneamente.
- Si movimiento + salto funciona simultáneamente.
- Si movimiento + dash funciona simultáneamente.
- Si ataque + salto o ataque + dash accidentalmente interfieren entre sí.
- Si algún control invade la zona segura del sistema.
- Captura de pantalla del HUD y controles.
- Observaciones de ergonomía: botones demasiado grandes/pequeños, demasiado juntos o fuera del alcance cómodo del pulgar.

## Criterios iniciales

No se promueve `touch_controls_2d` a READY sólo porque el APK abra. Se requiere evidencia de dispositivo real y multitouch correcto.

El rendimiento tampoco se considera validado con una sola cifra. La primera meta es una sesión estable a 60 fps; después se construirá una matriz 60/90/120 Hz y perfiles de calidad según dispositivo.

## Salida para ARCONT

La evidencia debe convertirse en un registro normalizado que incluya build/commit, dispositivo, renderer, resolución, frame-time percentiles, resultado de multitouch y notas de ergonomía. Los problemas generales se corrigen en ARCONT; los ajustes artísticos o de diseño específicos permanecen en Mortofe.
