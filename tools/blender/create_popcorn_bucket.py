"""Create the Phase 4 popcorn bucket draft, without exporting or integrating it.

Usage: blender --background --python tools/blender/create_popcorn_bucket.py -- output.blend [bucket|cup]
Approved dimensions: height 0.22 m, maximum top diameter 0.20 m, base diameter 0.14 m.
Cup variant: height 0.14 m, maximum top diameter 0.09 m, base diameter 0.06 m.
"""

import math
import sys
from pathlib import Path

import bpy


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    if len(args) not in (1, 2):
        raise SystemExit("Expected a new output .blend path")
    kind = args[1] if len(args) == 2 else "bucket"
    if kind not in ("bucket", "cup"):
        raise SystemExit("Choose bucket or cup")
    asset_id = "trash_popcorn_bucket" if kind == "bucket" else "trash_paper_cup"
    output = Path(args[0]).resolve()
    if output.suffix.lower() != ".blend" or output.exists():
        raise SystemExit("Output must be a new .blend file; existing sources are never overwritten")

    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0

    # Closed cross-section: underside, printed exterior, rolled lip, interior floor.
    profile = [
        (0.070, 0.000), (0.070, 0.005), (0.083, 0.105),
        (0.096, 0.210), (0.100, 0.213), (0.100, 0.217),
        (0.098, 0.220), (0.094, 0.220), (0.092, 0.217),
        (0.092, 0.211), (0.079, 0.105), (0.066, 0.006),
    ]
    if kind == "cup":
        profile = [
            (0.030, 0.000), (0.030, 0.003), (0.036, 0.065),
            (0.043, 0.134), (0.045, 0.136), (0.045, 0.138),
            (0.044, 0.140), (0.042, 0.140), (0.041, 0.138),
            (0.041, 0.134), (0.034, 0.065), (0.028, 0.003),
        ]
    sides = 16
    vertices = [(radius * math.cos(2 * math.pi * i / sides),
                 radius * math.sin(2 * math.pi * i / sides), height)
                for radius, height in profile for i in range(sides)]
    faces, colors = [], []
    red = (0.29, 0.060, 0.065, 1.0)
    cream = (0.77, 0.65, 0.45, 1.0)
    inside = (0.62, 0.51, 0.35, 1.0)

    def face(indices, color, variation=1.0):
        faces.append(indices)
        colors.append(tuple(c * variation for c in color[:3]) + (1.0,))

    for band in range(len(profile) - 1):
        for i in range(sides):
            j = (i + 1) % sides
            a, b = band * sides + i, band * sides + j
            c, d = (band + 1) * sides + j, (band + 1) * sides + i
            color = (red if i % 2 == 0 else cream) if band in (1, 2) else (inside if band >= 8 else cream)
            # Small deterministic changes give paper facets without random geometry.
            shade = 1.0 + (((i * 7 + band * 3) % 7) - 3) * 0.008
            face((a, b, c), color, shade)
            face((a, c, d), color, shade * (0.99 if band in (1, 2) else 1.0))

    bottom_center = len(vertices)
    vertices.append((0, 0, profile[0][1]))
    floor_center = len(vertices)
    vertices.append((0, 0, profile[-1][1]))
    for i in range(sides):
        j = (i + 1) % sides
        face((bottom_center, j, i), inside)
        face((floor_center, (len(profile) - 1) * sides + i,
              (len(profile) - 1) * sides + j), inside)

    mesh = bpy.data.meshes.new(f"{asset_id}_draft_mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(f"{asset_id}_draft", mesh)
    scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    attribute = mesh.color_attributes.new(name="PaperColor", type="FLOAT_COLOR", domain="CORNER")
    for poly, color in zip(mesh.polygons, colors):
        for loop_index in poly.loop_indices:
            attribute.data[loop_index].color = color

    material = bpy.data.materials.new(f"{asset_id}_paper_draft")
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value = 0.88
    shader.inputs["Specular IOR Level"].default_value = 0.22
    color_node = material.node_tree.nodes.new("ShaderNodeVertexColor")
    color_node.layer_name = "PaperColor"
    material.node_tree.links.new(color_node.outputs["Color"], shader.inputs["Base Color"])
    mesh.materials.append(material)

    # An editable initial unwrap; final UV/material review follows preview approval.
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(island_margin=0.03)
    bpy.ops.object.mode_set(mode="OBJECT")
    scene["pipeline_phase"] = 4
    scene["asset_status"] = "draft_pending_visual_approval"
    scene["reference"] = "assets/gptphoto_models/04_despacho_manager_basura.png"
    scene["approved_dimensions_m"] = ("height=0.22; top_diameter=0.20; base_diameter=0.14"
                                      if kind == "bucket" else
                                      "height=0.14; top_diameter=0.09; base_diameter=0.06")
    scene["authoring"] = "Reproducible Blender geometry; no generated 3D or external textures"
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(output), compress=True)
    print(f"PAPER_PROP_DRAFT_OK asset={asset_id} triangles={len(faces)} materials=1 source={output}")


if __name__ == "__main__":
    main()
