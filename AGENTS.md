# CinemaCleaner: instrucciones para agentes

## Proyecto

**CinemaCleaner: La última sesión** es un juego 3D en primera persona creado con Godot 4. Su estética es estilizada, low-poly, deliberadamente graciosa y ligeramente imperfecta; no es fotorrealista.

## Reglas generales

- Antes de introducir arquitectura nueva, inspecciona la arquitectura existente y busca sistemas equivalentes.
- No modifiques sistemas funcionales sin una razón explícita y documentada.
- Mantén los cambios pequeños, aislados y revisables mediante Git/diffs.
- No añadas dependencias sin justificar su necesidad y su impacto.
- Ejecuta el proyecto después de cambios relevantes, revisa los errores de Godot y no des una tarea por terminada mientras existan errores nuevos sin explicar.
- Cuando estén disponibles, usa Godot MCP para validar escenas y runtime, y Blender MCP para crear o modificar assets 3D.

## Assets legacy: protección estricta

- Todo asset, fuente, escena, recurso o ruta que ya exista al inicio de este pipeline es **LEGACY**.
- No muevas, renombres, sustituyas, regeneres ni optimices assets legacy automáticamente.
- No muevas GLB existentes ni cambies referencias de rutas existentes.
- No refactorices código o escenas existentes para adoptar este pipeline, salvo que una tarea posterior lo autorice de forma explícita.
- `assets/pipeline/` y `art_source/` son exclusivamente para assets creados a partir de este momento. Los directorios legacy, incluido `assets/` fuera de `assets/pipeline/` y `source_assets/`, se conservan tal cual.

## Dirección artística y producción 3D

- En todas las salas, las butacas rotas deben ser minoría (objetivo: ~20 %); prioriza ~60 % estándar y ~20 % plegadas, reutilizando los modelos existentes.
- Blender es el DCC principal. Los props sencillos y no orgánicos se crean primero con Blender MCP cuando esté disponible.
- Meshy u otra generación externa no es el pipeline por defecto. Los assets Meshy existentes son válidos y permanecen intactos.
- Reserva generación externa para objetos orgánicos o complejos. Cualquier asset externo debe limpiarse y validarse en Blender antes de ser production-ready.
- Lee `docs/pipeline/STYLE_BIBLE.md` y `docs/pipeline/ASSET_BUDGETS.md` antes de crear assets nuevos.
- Prioriza silueta y legibilidad sobre microdetalle, reutiliza materiales cuando sea razonable y evita geometría innecesariamente densa.
- Aplica transforms, define pivote de forma intencionada, conserva una escala coherente con Godot y entrega GLB cuando corresponda.

## Validación obligatoria de assets nuevos

Un asset no termina al generar el modelo. Debe completar:

`modelado → inspección → optimización → materiales → escala → pivote → exportación GLB → importación Godot → escena de prueba → inspección visual → validación de rendimiento`

Sigue las Skills de `.agents/skills/` aplicables a cada tarea. Ante la falta de una herramienta MCP requerida, detente, explica el requisito faltante y no sustituyas el workflow por generación externa automática.
