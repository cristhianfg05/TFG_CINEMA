"""Render repeatable previews from a GLB or a draft Blender source.

Usage:
    blender --background --python tools/blender/render_character_preview.py -- input.glb output_dir [three_quarter_elevation_degrees] [frame]

Accepts .blend drafts so visual approval can precede the production GLB export.
The input is never saved or overwritten.
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
    if len(arguments) not in (2, 3, 4):
        raise SystemExit("Expected input GLB or BLEND, output directory and optional three-quarter elevation")

    input_path = Path(arguments[0]).resolve()
    output_dir = Path(arguments[1]).resolve()
    elevation = math.radians(float(arguments[2])) if len(arguments) >= 3 else 0.0
    output_dir.mkdir(parents=True, exist_ok=True)

    if input_path.suffix.lower() == ".blend":
        bpy.ops.wm.open_mainfile(filepath=str(input_path))
    elif input_path.suffix.lower() == ".glb":
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=str(input_path))
    else:
        raise SystemExit("Preview input must be a .glb or .blend file")
    if len(arguments) == 4:
        bpy.context.scene.frame_set(int(arguments[3]))
    bpy.context.view_layer.update()
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
    camera.data.sensor_fit = "HORIZONTAL"
    camera.data.clip_start = 0.001
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
        "side": Vector((radius, 0.0, target.z)),
        "three_quarter": Vector((radius * math.cos(elevation) / math.sqrt(2),
                                 -radius * math.cos(elevation) / math.sqrt(2),
                                 target.z + radius * math.sin(elevation))),
        "back": Vector((0.0, radius, target.z)),
    }
    for label, location in views.items():
        camera.location = location
        _look_at(camera, target)
        # Fit every bounds corner, including depth, instead of cropping bulky props.
        camera_basis = camera.rotation_euler.to_matrix().transposed()
        local_corners = [camera_basis @ (corner - target) for corner in corners]
        half_angle_tangent = math.tan(camera.data.angle / 2.0)
        distance = max(max(abs(v.x), abs(v.y)) / half_angle_tangent + v.z
                       for v in local_corners) * 1.15
        camera.location = target + (location - target).normalized() * distance
        scene.render.filepath = str(output_dir / f"{input_path.stem}_{label}.png")
        bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    main()
