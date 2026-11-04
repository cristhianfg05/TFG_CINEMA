# Manifiesto de assets

Registrar aquí cada asset que pase del concepto a producción. Los estados permitidos son: `concepto`, `generado`, `limpio`, `importado`, `aprobado` y `rechazado`.

| ID | Asset | Tipo | Archivo fuente | Archivo de juego | Estado | Responsable | Notas |
|---|---|---|---|---|---|---|---|
| P-TRASH-001 | Entrada | Primitiva provisional | — | Generada en ejecución | importado | Codex | FASE 2 |
| P-TRASH-002 | Servilleta | Primitiva provisional | — | Generada en ejecución | importado | Codex | FASE 2 |
| P-TRASH-003 | Vaso | Primitiva provisional | — | Generada en ejecución | importado | Codex | FASE 2 |
| P-TRASH-004 | Botella | Primitiva provisional | — | Generada en ejecución | importado | Codex | FASE 2 |
| P-TRASH-005 | Lata | Primitiva provisional | — | Generada en ejecución | importado | Codex | FASE 2 |
| P-TRASH-006 | Pajita | Primitiva provisional | — | Generada en ejecución | importado | Codex | FASE 2 |
| P-TRASH-007 | Palomitas | Primitiva provisional | — | Generada en ejecución | importado | Codex | FASE 2 |
| P-TRASH-008 | Cubo de palomitas | Primitiva provisional | — | Generada en ejecución | importado | Codex | FASE 2 |
| P-LOST-001 | Reloj barato | Primitiva procedural provisional | — | Generada en ejecución | importado | Codex | FASE 3; brillo emisivo pulsante |
| P-PROP-001 | Cajón de objetos perdidos | Primitiva provisional | — | `scenes/gameplay/lost_found_box.tscn` | importado | Codex | FASE 3 |
| P-CHAR-001 | Encargado | Personaje provisional con primitivas | — | `scenes/characters/manager_placeholder.tscn` | importado | Codex | FASE 3; sustituible en FASE 4 |
| P-CHAR-002 | Espectador base | Personaje provisional con primitivas | — | `scenes/characters/spectator_placeholder.tscn` | importado | Codex | FASE 3; dos variantes de color con idle |
| P-SCREEN-001 | Imagen de película provisional | Textura procedural | — | Generada en ejecución | importado | Codex | FASE 3; atardecer pixelado, no es película final |
| CHAR-001 | Encargado | Personaje Meshy/Blender | `source_assets/blender/characters/rigged/npc_manager_rig_v002.blend` | `assets/characters/production/npc_manager_rigged.glb` | importado | Usuario + Codex | 14.974 triángulos; 1 material; rig piloto de 23 huesos y HeadIdle de 6 s; originales sin rig conservados; revisión manual pendiente |
| CHAR-002 | Hombre corpulento | Personaje Meshy/Blender | `source_assets/blender/characters/npc_man_fat.blend` | `assets/characters/production/npc_man_fat.glb` | importado | Usuario + Codex | 14.975 triángulos; 1 material; contenedor listo; rig pendiente |
| CHAR-003 | Empleado de palomitas | Personaje Meshy/Blender | `source_assets/blender/characters/npc_popcorn.blend` | `assets/characters/production/npc_popcorn.glb` | importado | Usuario + Codex | 14.969 triángulos; 1 material; contenedor listo; rig pendiente |
| CHAR-004 | Chico joven | Personaje Meshy/Blender | `source_assets/blender/characters/npc_young.blend` | `assets/characters/production/npc_young.glb` | importado | Usuario + Codex | 14.975 triángulos; 1 material; contenedor listo; rig pendiente |
| TRASH-001 | Cubo de palomitas vacío | Modelado procedural Blender | `source_assets/blender/props/trash_popcorn_bucket.blend` | `assets/models/trash/production/trash_popcorn_bucket.glb` | importado | Codex | 384 triángulos; 1 material; 22 cm de alto, Ø superior 20 cm/base 14 cm; colores y medidas aprobados; recogible en la sala |
| TRASH-002 | Vaso abierto | Modelado procedural Blender | `source_assets/blender/props/trash_paper_cup.blend` | `assets/models/trash/production/trash_paper_cup.glb` | importado | Codex | 384 triángulos; 1 material; alto 14 cm, Ø superior 9 cm/base 6 cm; misma dirección aprobada; recogible |
| TRASH-003 | Lata | Modelado procedural Blender | `source_assets/blender/props/trash_drink_can.blend` | `assets/models/trash/production/trash_drink_can.glb` | importado | Codex | 524 triángulos; 1 material; alto 12 cm, Ø 6,6 cm; anilla geométrica; abertura simulada con inserto oscuro; recogible |
| UI-001 | Icono de moneda | Imagen de interfaz aportada | `assets/gptphoto_models/IconoMoneda.png` | `assets/gptphoto_models/IconoMoneda.png` | importado | Usuario | Usado en el contador y en la animación de depósito |
| UI-002 | Marco de monedas | Nine-patch aportado | `assets/gptphoto_models/ContainerMonedas_UsarNinePatchRect.png` | `assets/gptphoto_models/ContainerMonedas_UsarNinePatchRect.png` | referencia sin uso | Usuario | Sustituido en el HUD por la tarjeta visual común; se conserva la fuente |
| UI-003 | Referencia HUD CineSweep | Concepto de interfaz aportado | `assets/gptphoto_models/hud_gameplay_cinesweep.png` | — | concepto | Usuario | Referencia de jerarquía y distribución; no se muestra como textura en juego |
| UI-004 | Referencia menú de colección | Concepto de interfaz aportado | `assets/gptphoto_models/DiseñoMenuColeccionable_Habilidades_Notas.png` | — | concepto | Usuario | Referencia para Habilidades, Figuras y Documentos |
| UI-005 | Icono de capacidad de basura | PNG aportado | `assets/models/source/general/bolsa_icono.png` | Mismo archivo | importado | Usuario | Contador superior del inventario, `actual / capacidad` |
| UI-006 | Icono de objetos perdidos | PNG aportado | `assets/models/source/general/objetosPerdidos_icono.png` | Mismo archivo | importado | Usuario | Contador inferior de objetos encontrados |
| UI-007 | Icono de mano | PNG aportado | `assets/models/source/general/mano_icono.png` | Mismo archivo | importado | Usuario | Herramienta manual del HUD |
| UI-009 | Icono de aspiradora | PNG aportado | `assets/models/source/general/aspiradora_icono.png` | Mismo archivo | importado | Usuario | Herramienta Aspiradora del HUD tras comprarla |
| UI-010 | Iconos dorados de mejoras | PNG aportados | `assets/models/source/general/upgrade_icons/` | Mismos archivos | importado | Usuario | Sustituyen los iconos del Tab para Limpieza, Aspiradora y Boti; los recursos retirados no se exportan |
| PROP-BROOM-001 | Escoba manual | Modelado Blender MCP | `art_source/blender/props/cinema_broom.blend` | `assets/pipeline/props/cinema_broom.glb` | importado | Codex | 396 triángulos, 236 vértices de fuente / 780 exportados con UV y normales; 1 material y atlas albedo 1024²; 1,43 m, pivote en suelo; petróleo y granate oscuros, roces y cerdas envejecidas (2026-11-04). Textura: `art_source/textures/props/cinema_broom_wear_albedo.png`. Informe en `docs/balance/INCREMENTAL_PHASE_B_IMPLEMENTATION.md`. |
| UI-BROOM-001 | Icono de escoba del inventario | Imagen generada con referencia de aspiradora/mano | `assets/pipeline/ui/icons/broom_inventory_candidate_01.png` | `assets/pipeline/ui/icons/broom_inventory.png` | aprobado | Usuario + Codex | PNG RGBA 1254×1254, fondo transparente, acabado dorado facetado; aprobado e integrado en la casilla ESCOBA del HUD. |
