"""Audit character GLBs with Blender's importer.

Usage:
    blender --background --python tools/blender/audit_glb.py -- file.glb [...]

The script is intentionally read-only: it imports each file into a fresh scene and
prints one JSON object per input so the report can be saved or diffed in CI.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy
import bmesh
from mathutils import Vector


def _arguments() -> list[Path]:
    if "--" not in sys.argv:
        return []
    return [Path(value).resolve() for value in sys.argv[sys.argv.index("--") + 1 :]]


def _world_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    corners = [obj.matrix_world @ Vector(corner) for obj in objects for corner in obj.bound_box]
    return (
        Vector((min(v.x for v in corners), min(v.y for v in corners), min(v.z for v in corners))),
        Vector((max(v.x for v in corners), max(v.y for v in corners), max(v.z for v in corners))),
    )


def audit(path: Path) -> dict[str, object]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))

    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    materials = {
        slot.material.name
        for obj in meshes
        for slot in obj.material_slots
        if slot.material is not None
    }
    images = [image for image in bpy.data.images if image.source != "VIEWER"]
    triangles = sum(len(poly.vertices) - 2 for obj in meshes for poly in obj.data.polygons)

    geometry_checks = []
    for obj in meshes:
        mesh_copy = obj.data.copy()
        check_mesh = bmesh.new()
        check_mesh.from_mesh(mesh_copy)
        loose_vertices = sum(1 for vertex in check_mesh.verts if not vertex.link_edges)
        boundary_edges = sum(1 for edge in check_mesh.edges if edge.is_boundary)
        non_manifold_edges = sum(1 for edge in check_mesh.edges if not edge.is_manifold)
        degenerate_faces = sum(1 for face in check_mesh.faces if face.calc_area() < 1e-10)
        geometry_checks.append(
            {
                "object": obj.name,
                "loose_vertices": loose_vertices,
                "boundary_edges": boundary_edges,
                "non_manifold_edges": non_manifold_edges,
                "degenerate_faces": degenerate_faces,
            }
        )
        check_mesh.free()
        bpy.data.meshes.remove(mesh_copy)

    minimum, maximum = _world_bounds(meshes)
    dimensions = maximum - minimum
    non_unit_scale = [
        obj.name
        for obj in bpy.context.scene.objects
        if any(abs(component - 1.0) > 0.0001 for component in obj.scale)
    ]
    non_zero_rotation = [
        obj.name
        for obj in bpy.context.scene.objects
        if any(abs(component) > 0.0001 for component in obj.rotation_euler)
    ]

    return {
        "file": path.as_posix(),
        "bytes": path.stat().st_size,
        "objects": len(bpy.context.scene.objects),
        "mesh_objects": len(meshes),
        "vertices": sum(len(obj.data.vertices) for obj in meshes),
        "triangles": triangles,
        "geometry_checks": geometry_checks,
        "materials": sorted(materials),
        "material_count": len(materials),
        "images": [
            {
                "name": image.name,
                "size": list(image.size),
                "packed": image.packed_file is not None,
            }
            for image in images
        ],
        "armatures": [
            {"name": obj.name, "bones": len(obj.data.bones)} for obj in armatures
        ],
        "actions": [action.name for action in bpy.data.actions],
        "bounds_m": {
            "min": [round(value, 5) for value in minimum],
            "max": [round(value, 5) for value in maximum],
            "dimensions": [round(value, 5) for value in dimensions],
        },
        "non_unit_scale_objects": non_unit_scale,
        "non_zero_rotation_objects": non_zero_rotation,
        "scene_units": {
            "system": bpy.context.scene.unit_settings.system,
            "scale_length": bpy.context.scene.unit_settings.scale_length,
        },
    }


def main() -> None:
    paths = _arguments()
    if not paths:
        raise SystemExit("Pass at least one GLB after --")
    for input_path in paths:
        print("PHASE4_AUDIT " + json.dumps(audit(input_path), ensure_ascii=False))


if __name__ == "__main__":
    main()
