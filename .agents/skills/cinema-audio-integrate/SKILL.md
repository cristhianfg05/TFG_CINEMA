---
name: cinema-audio-integrate
description: Integra una familia de audio ya aprobada en Godot sin perder una reversión legacy.
---

# Integración de audio

1. Lee la Biblia, el pipeline y el plan de migración.
2. Comprueba que cada WAV fue validado y está dentro de `assets/audio/`.
3. Elige el bus correcto: `Player`, `Trash`, `Tools`, `Machines`, `World`, `Ambience`, `Music` o `UI`.
4. Para acciones repetidas configura `AudioStreamRandomizer` con el número de variantes indicado por la Biblia y variación leve de pitch/volumen.
5. Conserva el audio o código legacy hasta ejecutar la escena, revisar errores y comprobar gameplay.
6. Sustituye una sola referencia por vez y retira legacy únicamente si no hay referencias restantes y la prueba fue aprobada.
