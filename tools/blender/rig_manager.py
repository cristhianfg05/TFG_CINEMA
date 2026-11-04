"""Build the manager pilot rig from its preserved, unrigged source.

blender --background --python tools/blender/rig_manager.py -- source.blend output.blend output.glb
Landmarks are specific to the audited manager; do not apply to other NPCs.
Godot humanoid bone names, T-pose rest, relaxed arms in the single head-idle action.
"""
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector, Quaternion


def smooth(value, start, end):
    t = max(0.0, min(1.0, (value-start)/(end-start)))
    return t*t*(3-2*t)


def blend_chain(value, joints):
    for i in range(len(joints)-1):
        a, name_a = joints[i]
        b, name_b = joints[i+1]
        if value < b:
            w = smooth(value, a, b)
            return {name_a: 1-w, name_b: w}
    return {joints[-1][1]: 1.0}


def main():
    args = sys.argv[sys.argv.index("--")+1:]
    if len(args) not in (3, 4):
        raise SystemExit("Expected source BLEND, new rigged BLEND and new rigged GLB")
    source, blend_path, glb_path = [Path(p).resolve() for p in args[:3]]
    replace_glb = len(args) == 4 and args[3] == "--replace-glb"
    if source in (blend_path, glb_path) or blend_path.exists() or (glb_path.exists() and not replace_glb):
        raise SystemExit("Use separate, new output paths; original sources are never overwritten")
    bpy.ops.wm.open_mainfile(filepath=str(source))
    scene = bpy.context.scene
    meshes = [o for o in scene.objects if o.type == "MESH"]
    if len(meshes) != 1 or any(o.type == "ARMATURE" for o in scene.objects):
        raise SystemExit("Expected the unrigged manager source")
    mesh = meshes[0]
    assert abs(mesh.dimensions.z-1.8) < 0.001
    skeleton = bpy.data.armatures.new("ManagerHumanoid")
    rig = bpy.data.objects.new("ManagerRig", skeleton)
    scene.collection.objects.link(rig)
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")

    def bone(name, head, tail, parent=None, deform=True):
        b = skeleton.edit_bones.new(name)
        b.head, b.tail = head, tail
        b.use_deform = deform
        if parent:
            b.parent = skeleton.edit_bones[parent]
        return b

    bone("Root", (0,0,0), (0,0,0.15), deform=False)
    bone("Hips", (0,0.055,0.88), (0,0.055,1.02), "Root")
    bone("Spine", (0,0.055,1.02), (0,0.055,1.14), "Hips")
    bone("Chest", (0,0.055,1.14), (0,0.050,1.27), "Spine")
    bone("UpperChest", (0,0.050,1.27), (0,0.032,1.385), "Chest")
    bone("Neck", (0,0.032,1.385), (-0.004,-0.035,1.51), "UpperChest")
    bone("Head", (-0.004,-0.035,1.51), (-0.004,-0.01,1.76), "Neck")
    for side, sign in (("Left",1), ("Right",-1)):
        bone(side+"Shoulder", (sign*0.045,0.055,1.355), (sign*0.14,0.055,1.355), "UpperChest")
        bone(side+"UpperArm", (sign*0.14,0.055,1.355), (sign*0.40,0.055,1.355), side+"Shoulder")
        bone(side+"LowerArm", (sign*0.40,0.055,1.355), (sign*0.65,0.03,1.355), side+"UpperArm")
        bone(side+"Hand", (sign*0.65,0.03,1.355), (sign*0.79,0.015,1.36), side+"LowerArm")
        bone(side+"UpperLeg", (sign*0.065,0.055,0.91), (sign*0.077,0.060,0.52), "Hips")
        bone(side+"LowerLeg", (sign*0.077,0.060,0.52), (sign*0.087,0.050,0.15), side+"UpperLeg")
        bone(side+"Foot", (sign*0.087,0.050,0.15), (sign*0.13,-0.060,0.06), side+"LowerLeg")
        bone(side+"Toes", (sign*0.13,-0.060,0.06), (sign*0.14,-0.155,0.055), side+"Foot")
    bpy.ops.object.mode_set(mode="OBJECT")

    groups = {b.name: mesh.vertex_groups.new(name=b.name) for b in skeleton.bones if b.use_deform}
    max_influences = 0
    for vertex in mesh.data.vertices:
        x,y,z = vertex.co
        ax = abs(x)
        side = "Left" if x >= 0 else "Right"
        if z >= 1.445 and ax < 0.16:
            # Keep jaw, face, eyes and hair rigid; blend only the actual neck.
            head = max(smooth(z,1.46,1.535), smooth(-y,0.045,0.085))
            weights = {"Neck":1-head, "Head":head}
        elif z > 1.27 and ax > 0.11:
            weights = blend_chain(ax, [(0.11,"UpperChest"),(0.15,side+"Shoulder"),
                                      (0.21,side+"UpperArm"),(0.35,side+"UpperArm"),
                                      (0.45,side+"LowerArm"),(0.62,side+"LowerArm"),
                                      (0.68,side+"Hand")])
        elif z < 0.90:
            weights = blend_chain(z, [(0.09,side+"Foot"),(0.20,side+"LowerLeg"),
                                     (0.46,side+"LowerLeg"),(0.58,side+"UpperLeg"),
                                     (0.80,side+"UpperLeg"),(0.90,"Hips")])
            if z < 0.10 and y < -0.05:
                toes = smooth(-y,0.05,0.12)
                weights = {side+"Foot":1-toes, side+"Toes":toes}
        else:
            weights = blend_chain(z, [(0.98,"Hips"),(1.08,"Spine"),
                                     (1.21,"Chest"),(1.34,"UpperChest"),(1.445,"Neck")])
        # Duplicate adjacent labels in the chains represent a rigid middle section.
        if len(weights) == 1:
            weights = {next(iter(weights)): 1.0}
        total = sum(weights.values())
        weights = {k:v/total for k,v in weights.items() if v > 1e-7}
        max_influences = max(max_influences,len(weights))
        for name, weight in weights.items():
            groups[name].add([vertex.index],weight,"REPLACE")

    mesh.parent = rig
    modifier = mesh.modifiers.new("ManagerSkin", "ARMATURE")
    modifier.object = rig
    modifier.use_deform_preserve_volume = False  # Matches glTF linear skinning.
    scene.render.fps = 30
    scene.frame_start, scene.frame_end = 0, 180
    rig.animation_data_create()
    for frame in range(0,181,3):
        phase = frame/180*2*math.pi
        for pose in rig.pose.bones:
            pose.rotation_mode = "QUATERNION"
            pose.rotation_quaternion = Quaternion()
            pose.location = (0,0,0)
            pose.scale = (1,1,1)
        for side, sign in (("Left",1),("Right",-1)):
            for suffix, angle in (("UpperArm",68),("LowerArm",5)):
                p = rig.pose.bones[side+suffix]
                local_axis = p.bone.matrix_local.to_3x3().inverted() @ Vector((0,1,0))
                p.rotation_quaternion = Quaternion(local_axis, math.radians(sign*angle))
        for name, yaw, pitch in (("Neck",0.55,0.15),("Head",2.0,0.65)):
            p = rig.pose.bones[name]
            basis = p.bone.matrix_local.to_3x3().inverted()
            q_yaw = Quaternion(basis @ Vector((0,0,1)), math.radians(yaw)*math.sin(phase))
            q_pitch = Quaternion(basis @ Vector((1,0,0)), math.radians(pitch)*math.sin(2*phase))
            p.rotation_quaternion = q_yaw @ q_pitch
        for pose in rig.pose.bones:
            pose.keyframe_insert("rotation_quaternion",frame=frame,group=pose.name)
    rig.animation_data.action.name = "Manager_HeadIdle"
    scene.frame_set(0)

    # Check every source vertex has normalized weights and no more than four influences.
    assert max_influences <= 4
    assert all(abs(sum(g.weight for g in v.groups)-1)<1e-5 for v in mesh.data.vertices)
    # Compare sampled skinning against the relaxed baseline, including seam vertices.
    depsgraph = bpy.context.evaluated_depsgraph_get()
    baseline = [v.co.copy() for v in mesh.evaluated_get(depsgraph).data.vertices]
    edges = [(e.vertices[0],e.vertices[1]) for e in mesh.data.edges]
    max_edge_change, max_foot_motion, max_seam_gap = 0.0, 0.0, 0.0
    seam_groups = {}
    for v in mesh.data.vertices:
        seam_groups.setdefault(tuple(round(c,6) for c in v.co),[]).append(v.index)
    for frame in (0,45,90,135,180):
        scene.frame_set(frame)
        evaluated = mesh.evaluated_get(depsgraph)
        points = [v.co.copy() for v in evaluated.data.vertices]
        assert all(math.isfinite(c) for v in points for c in v)
        for a,b in edges:
            length = (baseline[a]-baseline[b]).length
            if length > 0.0001:
                max_edge_change = max(max_edge_change,abs((points[a]-points[b]).length/length-1))
        for i,v in enumerate(mesh.data.vertices):
            if v.co.z < 0.20:
                max_foot_motion = max(max_foot_motion,(points[i]-baseline[i]).length)
        for indices in seam_groups.values():
            if len(indices)>1:
                max_seam_gap = max(max_seam_gap,max((points[i]-points[indices[0]]).length for i in indices))
    print("RIG_DEFORMATION " + json.dumps(dict(max_edge_length_change=max_edge_change,
          max_foot_motion_m=max_foot_motion,max_coincident_seam_gap_m=max_seam_gap)))
    assert max_foot_motion < 1e-5 and max_seam_gap < 1e-5
    assert max_edge_change < 0.15
    scene.frame_set(0)
    scene["rig_note"] = "Manager-specific pilot; humanoid names, T-pose rest; fingers rigid to Hand"
    scene["source_unrigged"] = str(source)
    scene["rig_status"] = "pilot_pending_manual_deformation_review"
    scene["idle_note"] = "Six-second head/neck idle; fixed relaxed-arm pose; no locomotion"
    for path in (blend_path,glb_path):
        path.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path),compress=True)
    bpy.ops.export_scene.gltf(filepath=str(glb_path),export_format="GLB",export_yup=True,
                              export_animations=True,export_animation_mode="ACTIONS",
                              export_frame_range=True,export_force_sampling=True,
                              export_skins=True,export_apply=False)
    print("MANAGER_RIG " + json.dumps(dict(bones=len(skeleton.bones),
          vertices=len(mesh.data.vertices),max_influences=max_influences,
          triangles=sum(len(p.vertices)-2 for p in mesh.data.polygons),
          action=rig.animation_data.action.name)))


if __name__ == "__main__":
    main()
