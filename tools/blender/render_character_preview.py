"""Render repeatable turntable previews for a character GLB.

Usage:
    blender --background --python tools/blender/render_character_preview.py -- input.glb output_dir
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def _look_at(camera: bpy.types.Object, target: Vector) -> None:
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()


def main() -> None:
    arguments = sys.argv[sys.argv.index("--") + 1 :]
    if len(arguments) != 2:
        raise SystemExit("Expected input GLB and output directory")

    input_path = Path(arguments[0]).resolve()
    output_dir = Path(arguments[1]).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(input_path))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    corners = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
    minimum = Vector((min(v.x for v in corners), min(v.y for v in corners), min(v.z for v in corners)))
    maximum = Vector((max(v.x for v in corners), max(v.y for v in corners), max(v.z for v in corners)))
    target = (minimum + maximum) * 0.5
    target.z = minimum.z + (maximum.z - minimum.z) * 0.53
    radius = max(maximum - minimum) * 1.65

    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.data.lens = 60
    bpy.context.scene.camera = camera

    bpy.ops.object.light_add(type="AREA", location=(3.0, -4.0, 5.0))
    key = bpy.context.object
    key.data.energy = 900
    key.data.shape = "DISK"
    key.data.size = 4.0
    _look_at(key, target)

    bpy.ops.object.light_add(type="AREA", location=(-3.0, 2.0, 3.0))
    fill = bpy.context.object
    fill.data.energy = 550
    fill.data.size = 3.0
    _look_at(fill, target)

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.world = bpy.data.worlds.new("PreviewWorld")
    scene.world.color = (0.035, 0.035, 0.045)

    views = {
        "front": Vector((0.0, -radius, target.z)),
        "three_quarter": Vector((radius * 0.7, -radius * 0.7, target.z)),
        "back": Vector((0.0, radius, target.z)),
    }
    for label, location in views.items():
        camera.location = location
        _look_at(camera, target)
        scene.render.filepath = str(output_dir / f"{input_path.stem}_{label}.png")
        bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    main()
