"""Create a reproducible Blender source and production GLB from a character GLB.

Usage:
    blender --background --python tools/blender/prepare_character_asset.py -- \
        input.glb_or_blend output.blend output.glb asset_id [triangle_budget]

This script is deliberately conservative: it preserves UVs and materials, removes
only degenerate faces, applies object transforms, recentres the feet at the origin,
and uses a very small decimation only when the configured budget is exceeded.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector


def _triangles(mesh_objects: list[bpy.types.Object]) -> int:
    return sum(len(poly.vertices) - 2 for obj in mesh_objects for poly in obj.data.polygons)


def _world_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    corners = [obj.matrix_world @ Vector(corner) for obj in objects for corner in obj.bound_box]
    return (
        Vector((min(v.x for v in corners), min(v.y for v in corners), min(v.z for v in corners))),
        Vector((max(v.x for v in corners), max(v.y for v in corners), max(v.z for v in corners))),
    )


def _activate(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def _clean_degenerate_faces(obj: bpy.types.Object) -> None:
    mesh = bmesh.new()
    mesh.from_mesh(obj.data)
    bmesh.ops.dissolve_degenerate(mesh, dist=1e-7, edges=list(mesh.edges))
    zero_area_faces = [face for face in mesh.faces if face.calc_area() < 1e-10]
    if zero_area_faces:
        bmesh.ops.delete(mesh, geom=zero_area_faces, context="FACES")
    bmesh.ops.recalc_face_normals(mesh, faces=list(mesh.faces))
    mesh.to_mesh(obj.data)
    mesh.free()
    obj.data.update()


def main() -> None:
    arguments = sys.argv[sys.argv.index("--") + 1 :]
    if len(arguments) not in (4, 5):
        raise SystemExit("Expected input GLB, output BLEND, output GLB, asset id and optional triangle budget")

    input_path = Path(arguments[0]).resolve()
    blend_path = Path(arguments[1]).resolve()
    glb_path = Path(arguments[2]).resolve()
    if input_path in (blend_path, glb_path):
        raise SystemExit("Source must be separate from production outputs")
    asset_id = arguments[3]
    triangle_budget = int(arguments[4]) if len(arguments) == 5 else 15_000
    blend_path.parent.mkdir(parents=True, exist_ok=True)
    glb_path.parent.mkdir(parents=True, exist_ok=True)

    if input_path.suffix.lower() == ".blend":
        bpy.ops.wm.open_mainfile(filepath=str(input_path))
    else:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=str(input_path))
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0

    meshes = [obj for obj in scene.objects if obj.type == "MESH"]
    armatures = [obj for obj in scene.objects if obj.type == "ARMATURE"]
    if len(meshes) != 1 or armatures:
        raise RuntimeError(
            f"Conservative pipeline expects one unrigged mesh; found {len(meshes)} meshes and {len(armatures)} armatures"
        )

    obj = meshes[0]
    obj.name = asset_id.upper()
    obj.data.name = f"{asset_id}_mesh"
    for index, slot in enumerate(obj.material_slots):
        if slot.material is not None:
            slot.material.name = f"{asset_id}_material" if index == 0 else f"{asset_id}_material_{index + 1}"

    _activate(obj)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    _clean_degenerate_faces(obj)

    triangles_before_decimate = _triangles(meshes)
    if triangles_before_decimate > triangle_budget:
        modifier = obj.modifiers.new(name="Phase4TriangleBudget", type="DECIMATE")
        modifier.ratio = max(0.01, (triangle_budget - 25) / triangles_before_decimate)
        modifier.use_collapse_triangulate = True
        _activate(obj)
        bpy.ops.object.modifier_apply(modifier=modifier.name)

    minimum, maximum = _world_bounds(meshes)
    horizontal_centre = (minimum + maximum) * 0.5
    obj.location -= Vector((horizontal_centre.x, horizontal_centre.y, minimum.z))
    _activate(obj)
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)

    triangles_after = _triangles(meshes)
    if triangles_after > triangle_budget:
        raise RuntimeError(f"Triangle budget still exceeded: {triangles_after} > {triangle_budget}")

    scene["pipeline_phase"] = 4
    scene["asset_id"] = asset_id
    scene["source_glb"] = input_path.as_posix()
    scene["asset_status"] = "production_candidate"
    scene["triangle_budget"] = triangle_budget
    scene["front_axis"] = "-Y in Blender / +Z after Godot import; container rotates visual to -Z"
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path), compress=True)

    bpy.ops.export_scene.gltf(
        filepath=str(glb_path),
        export_format="GLB",
        export_yup=True,
        export_apply=True,
        export_animations=True,
    )

    minimum, maximum = _world_bounds(meshes)
    print(
        "PHASE4_PREPARED "
        + json.dumps(
            {
                "asset_id": asset_id,
                "source": input_path.as_posix(),
                "blend": blend_path.as_posix(),
                "glb": glb_path.as_posix(),
                "triangles_before": triangles_before_decimate,
                "triangles_after": triangles_after,
                "dimensions_m": [round(value, 5) for value in maximum - minimum],
                "materials": len([slot for slot in obj.material_slots if slot.material]),
            },
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
