# Style Bible — CinemaCleaner

## Propósito y fuente

Esta primera versión consolida las convenciones ya documentadas en `docs/ART_BIBLE.md` y `docs/PHASE_4_ASSET_REPORT.md`. Describe el estilo existente; no define una dirección de arte nueva. Se aplica solo a assets nuevos del pipeline.

## Identidad visual actual

- 3D estilizado, low-poly, barato, gracioso y ligeramente incómodo.
- Formas claras, algo exageradas y con una imperfección deliberada pero cuidada.
- No fotorrealismo: evitar materiales, suciedad o microdetalle que pretendan simular realidad física precisa.
- Siluetas fáciles de reconocer durante el juego; los detalles deben ser lo bastante grandes para leerse a distancia jugable.
- Materiales simples y coherentes entre props, con texturas solo cuando aporten lectura real.
- Superficies algo gastadas y suciedad legible sin resultar desagradable o hiperrealista.
- Paletas apagadas con uno o dos colores de acento por zona, según la dirección existente.

## Forma, escala y orientación

- Trabajar en metros: una unidad de Godot equivale a un metro.
- Mantener escala coherente: personaje aproximado de 1,8 m y puerta aproximada de 2 m, salvo que el diseño justifique una exageración.
- Priorizar lectura, proporción y silueta antes que la geometría perfecta.
- Aplicar transforms antes de exportar y definir el pivote según el uso del asset.
- Para personajes nuevos, confirmar frente, rotación de importación y escena contenedora contra el estándar del proyecto antes de entregar.

## Materiales e integración

- Reutilizar materiales cuando resulte coherente y reduzca complejidad.
- No añadir mallas visuales complejas como colisión; usar colliders simples y separados cuando sea necesario.
- El GLB es el formato de entrega preferido para nuevos modelos 3D del pipeline.

## TODO de dirección artística

- TODO: confirmar una paleta de referencia por zona y los colores de acento prioritarios.
- TODO: confirmar el nivel de desgaste aceptable en arquitectura y props narrativos.
- TODO: confirmar si todos los props nuevos deben usar color por vértice, texturas simples o una combinación por categoría.
