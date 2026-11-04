# Plan de migración de audio

1. Crear y escuchar variantes de recogida de basura; procesarlas y validarlas.
2. Integrar el conjunto en `Trash` mediante `AudioStreamRandomizer`, probar recogida y conservar el tono legacy como reversión inmediata.
3. Repetir para vaciado de bolsa y rechazo de recogida.
4. Crear un loop de aspiradora, probar transición start/stop y continuidad antes de reemplazar el loop procedural.
5. Preparar candidatos de música arcade y de intro; la música principal espera selección humana.
6. Añadir ambiente, máquinas, herramientas y UI por familias pequeñas, con una prueba jugable por familia.

Cada paso sigue esta secuencia: generar → procesar → validar → escuchar → integrar → ejecutar → verificar log → sustituir referencia → retirar legacy solo si ya no se usa.
