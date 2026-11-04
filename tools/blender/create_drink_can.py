"""Model a 12 cm high, 6.6 cm diameter can from the user's approved trash reference.

Usage: blender --background --python tools/blender/create_drink_can.py -- new_output.blend
No external textures, generated 3D, or writes to existing source files.
"""
import math
import sys
from pathlib import Path

import bpy
import bmesh


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    if len(args) != 1:
        raise SystemExit("Expected a new .blend output")
    output = Path(args[0]).resolve()
    if output.exists() or output.suffix.lower() != ".blend":
        raise SystemExit("Existing sources may not be overwritten")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1
    vertices, faces, colors = [], [], []
    silver = (0.48, 0.47, 0.42, 1)
    red = (0.29, 0.060, 0.065, 1)
    dark = (0.025, 0.020, 0.018, 1)

    def face(indices, color):
        faces.append(indices)
        colors.append(color)

    profile = [(0.026, 0), (0.030, 0.002), (0.030, 0.006),
               (0.033, 0.016), (0.033, 0.057), (0.033, 0.103),
               (0.029, 0.113), (0.030, 0.115), (0.030, 0.119),
               (0.029, 0.120), (0.026, 0.120), (0.026, 0.116)]
    sides = 16
    for radius, z in profile:
        vertices.extend((radius * math.cos(2*math.pi*i/sides),
                         radius * math.sin(2*math.pi*i/sides), z) for i in range(sides))
    for band in range(len(profile)-1):
        for i in range(sides):
            j = (i+1) % sides
            a,b,c,d = band*sides+i, band*sides+j, (band+1)*sides+j, (band+1)*sides+i
            color = red if 2 <= band <= 5 else silver
            shade = 1 + ((i*3+band)%5-2)*0.012
            color = tuple(v*shade for v in color[:3])+(1,)
            face((a,b,c), color)
            face((a,c,d), color)
    bottom, top = len(vertices), len(vertices)+1
    vertices.extend(((0,0,0), (0,0,0.116)))
    for i in range(sides):
        j=(i+1)%sides
        face((bottom,j,i), silver)
        face((top,(len(profile)-1)*sides+i,(len(profile)-1)*sides+j), silver)

    # Thin, closed dark inset suggests the opening without fragile boolean topology.
    start = len(vertices)
    for z in (0.11605, 0.1163):
        vertices.extend((0.009*math.cos(2*math.pi*i/12),
                         -0.012+0.006*math.sin(2*math.pi*i/12),z) for i in range(12))
    for i in range(12):
        j=(i+1)%12
        face((start+i,start+j,start+12+j,start+12+i),dark)
    face(tuple(start+i for i in reversed(range(12))),dark)
    face(tuple(start+12+i for i in range(12)),dark)

    # Pull-tab: closed oval annulus, still below the upper rim.
    start = len(vertices)
    for rx,ry,z in ((0.006,0.010,0.117),(0.006,0.010,0.119),
                    (0.003,0.006,0.119),(0.003,0.006,0.117)):
        vertices.extend((rx*math.cos(2*math.pi*i/12),
                         0.004+ry*math.sin(2*math.pi*i/12),z) for i in range(12))
    for band in range(4):
        for i in range(12):
            j=(i+1)%12
            face((start+band*12+i,start+band*12+j,
                  start+((band+1)%4)*12+j,start+((band+1)%4)*12+i),silver)

    mesh = bpy.data.meshes.new("trash_drink_can_mesh")
    mesh.from_pydata(vertices,[],faces)
    mesh.update()
    obj = bpy.data.objects.new("TrashDrinkCan_Draft",mesh)
    scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active=obj
    obj.select_set(True)
    attribute=mesh.color_attributes.new(name="CanColor",type="FLOAT_COLOR",domain="CORNER")
    for poly,color in zip(mesh.polygons,colors):
        for index in poly.loop_indices:
            attribute.data[index].color=color
    material=bpy.data.materials.new("can_painted_metal")
    material.use_nodes=True
    shader=material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Metallic"].default_value=0.6
    shader.inputs["Roughness"].default_value=0.48
    color=material.node_tree.nodes.new("ShaderNodeVertexColor")
    color.layer_name="CanColor"
    material.node_tree.links.new(color.outputs["Color"],shader.inputs["Base Color"])
    mesh.materials.append(material)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(island_margin=0.03)
    bpy.ops.object.mode_set(mode="OBJECT")
    bm=bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    assert not any(not e.is_manifold for e in bm.edges)
    bm.to_mesh(mesh)
    bm.free()
    scene["pipeline_phase"]=4
    scene["reference"]="assets/gptphoto_models/04_despacho_manager_basura.png"
    scene["approved_dimensions_m"]="height=0.12; diameter=0.066"
    scene["asset_status"]="draft_pending_technical_review"
    scene["detail_note"]="Opening is a dark closed inset, not a through-hole"
    output.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(output),compress=True)
    print("CAN_DRAFT_OK triangles=",sum(len(p.vertices)-2 for p in mesh.polygons))


if __name__=="__main__":
    main()
