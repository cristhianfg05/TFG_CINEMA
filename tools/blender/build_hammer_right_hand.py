"""Rebuild the authorized hammer hand in live Blender through Blender MCP.
Canonical hand: dorsal +Z, fingertips +Y, thumb -X (right hand).
The final grip uses a proper rotation: canonical X -> Godot -Y,
canonical Y -> Godot -Z, canonical Z -> Godot +X. No mirroring.
"""
import bpy
import bmesh
import math
from mathutils import Vector, Quaternion

# Keep the imported hammer as a reference, never export or modify its source.
ref = bpy.data.objects.get("HandGripReference")
if ref is None:
    ref = bpy.data.objects.new("HandGripReference", None)
    bpy.context.collection.objects.link(ref)
    for ob in list(bpy.context.scene.objects):
        if ob.name.startswith("GripReferenceMallet"):
            ob.scale = (1, 1, 1)
            ob.parent = ref
    ref.scale = (0.45, 0.45, 0.45)

verts = []
faces = []
face_tiles = []
origin = Vector((0.040, 0.157, 0.025))
def canonical(x, y, z):
    return origin + Vector((z, -x, -y))
def vertex(p):
    verts.append(tuple(p))
    return len(verts)-1
def face(indices, tile=0):
    faces.append(tuple(indices))
    face_tiles.append(tile)

# A flattened palm cage with four finger sockets and a side thumb socket.
xs = [-0.048, -0.025, -0.023, 0.001, 0.003, 0.026, 0.028, 0.046]
roots_y = [0.032,0.032,0.038,0.038,0.032,0.032,0.020,0.020]
grid = {}
for layer in range(2):
    for row in range(3):
        for col in range(8):
            width_factor = [0.58,0.94,1.0][row]
            x = xs[col]*width_factor
            y = [-0.053,-0.010,roots_y[col]][row]
            convex = 1.0 - min(1.0,abs(x)/0.050)**2
            if layer == 0:
                z = [0.006,0.013,0.010][row] + 0.002*convex
            else:
                z = -[0.007,0.014,0.012][row]
                if row == 1 and col < 3:
                    z -= 0.002
            grid[layer,row,col] = vertex(canonical(x,y,z))
for layer in range(2):
    for row in range(2):
        for col in range(7):
            face([grid[layer,row,col],grid[layer,row+1,col],
                  grid[layer,row+1,col+1],grid[layer,row,col+1]],0 if layer == 0 else 3)
for col in range(7):
    face([grid[0,0,col],grid[0,0,col+1],grid[1,0,col+1],grid[1,0,col]])
for row in range(2):
    face([grid[0,row,7],grid[0,row+1,7],grid[1,row+1,7],grid[1,row,7]])
# Leave the left heel-to-mid side face open for the anatomically rooted thumb.
face([grid[0,1,0],grid[0,2,0],grid[1,2,0],grid[1,1,0]],3)
for col in (1,3,5):
    face([grid[0,2,col],grid[0,2,col+1],grid[1,2,col+1],grid[1,2,col]],3)

def digit(socket, centers, widths, depths, across, nail_segment):
    ring = socket
    points = [sum((Vector(verts[i]) for i in socket),Vector())/4] + [Vector(p) for p in centers]
    u0 = Vector(across).normalized()
    for k,p in enumerate(points[1:]):
        tangent = (points[min(k+2,len(points)-1)]-points[k]).normalized()
        u = (u0-tangent*u0.dot(tangent)).normalized()
        v = u.cross(tangent).normalized()
        w,d = widths[k]*0.5,depths[k]*0.5
        new = [vertex(p-u*w+v*d),vertex(p+u*w+v*d),
               vertex(p+u*w-v*d),vertex(p-u*w-v*d)]
        for side in range(4):
            tile = 2 if side==0 and k==nail_segment else (1 if k in (1,2) and side==0 else 0)
            face([ring[side],ring[(side+1)%4],new[(side+1)%4],new[side]],tile)
        ring = new
    face(ring,0)

for finger,col in enumerate((0,2,4,6)):
    socket = [grid[0,2,col],grid[0,2,col+1],grid[1,2,col+1],grid[1,2,col]]
    start = sum((Vector(verts[i]) for i in socket),Vector())/4
    cy=start.y
    # Different lengths, knuckle heights and taper; all curl toward the palm.
    small = finger==3
    xz = [(0.039,-0.021 if small else -0.025),
          (0.019,-0.037 if small else -0.043),
          (-0.010 if small else -0.016,-0.035 if small else -0.039),
          (-0.025 if small else -0.032,-0.016),
          (-0.029 if small else -0.036,0.002 if small else 0.008),
          (-0.028 if small else -0.035,0.007 if small else 0.013)]
    centers=[(x,cy-0.001*k/5,z) for k,(x,z) in enumerate(xz)]
    width=xs[col+1]-xs[col]
    widths=[width*1.0,width*0.95,width*0.86,width*0.79,width*0.68,width*0.50]
    depths=[0.023,0.022,0.019,0.017,0.014,0.010]
    if small:
        depths=[d*0.85 for d in depths]
    digit(socket,centers,widths,depths,(0,-1,0),4)

thumb_socket=[grid[0,0,0],grid[0,1,0],grid[1,1,0],grid[1,0,0]]
digit(thumb_socket,
      [(0.033,0.207,0.057),(0.010,0.216,0.046),
       (-0.009,0.214,0.033),(-0.019,0.204,0.028),
       (-0.023,0.191,0.030),(-0.023,0.187,0.032)],
      [0.038,0.030,0.025,0.023,0.019,0.014],
      [0.027,0.026,0.023,0.021,0.017,0.012],
      (0,0,-1),4)

# Convert Godot Y-up coordinates to Blender Z-up without changing chirality.
mesh=bpy.data.meshes.new("RightHandContinuousCage")
mesh.from_pydata([(x,-z,y) for x,y,z in verts],[],faces)
mesh.update()
obj=bpy.data.objects.new("HammerGripHand",mesh)
bpy.context.collection.objects.link(obj)
obj["handedness"]="right"
obj["design"]="Continuous quad palm, rooted thumb, articulated tapering digits; no wrist"
bm=bmesh.new()
bm.from_mesh(mesh)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
bm.to_mesh(mesh)
bm.free()

# A tiny painted atlas: skin, knuckle warmth, actual surface nails, palm creases.
size=256
img=bpy.data.images.new("RightHandSkinAtlas",width=size,height=size,alpha=True)
pixels=[0.0]*(size*size*4)
base=(0.69,0.51,0.415)
def mix(a,b,t):
    return tuple(a[i]*(1-t)+b[i]*t for i in range(3))
for y in range(size):
    for x in range(size):
        tile=(y//128)*2+x//128
        u=(x%128+0.5)/128
        v=(y%128+0.5)/128
        grain=0.004*math.sin(x*1.37+y*0.91)*math.sin(x*0.67-y*1.79)
        color=base
        if tile==0:
            broad=0.010*math.sin(u*4.5+v*1.2)+0.004*math.cos(v*9)
            color=tuple(c+broad for c in base)
        elif tile==1:
            blush=0.19*math.exp(-((u-0.5)/0.40)**2-((v-0.5)/0.44)**2)
            color=mix(base,(0.69,0.405,0.345),blush)
            crease=0.045*math.exp(-((v-0.42-0.04*math.cos(u*6.28))/0.023)**2)
            color=tuple(c-crease for c in color)
        elif tile==2:
            # Rounded nail embedded in the skin texture; no floating nail pieces.
            ax=abs((u-0.5)/0.34)
            ay=abs((v-0.52)/0.40)
            dist=ax**4+ay**4
            edge=max(0,min(1,(1.05-dist)*14))
            nail=mix((0.77,0.603,0.513),(0.84,0.707,0.617),max(0,(v-0.69)/0.25))
            color=mix(base,nail,edge)
            cuticle=0.026*math.exp(-((v-0.17)/0.015)**2)*edge
            color=tuple(c-cuticle for c in color)
        else:
            color=mix(base,(0.76,0.555,0.455),0.22)
            crease=0.027*math.exp(-((v-(0.37+0.13*(u-0.5)**2))/0.020)**2)
            color=tuple(c-crease for c in color)
        i=(y*size+x)*4
        pixels[i:i+4]=[max(0,min(1,c+grain)) for c in color]+[1]
img.pixels.foreach_set(pixels)
img.update()
mat=bpy.data.materials.new("RightHandPaintedSkin")
mat.use_nodes=True
mat.diffuse_color=(*base,1)
shader=next(n for n in mat.node_tree.nodes if n.type=="BSDF_PRINCIPLED")
shader.inputs["Roughness"].default_value=0.87
shader.inputs["Metallic"].default_value=0
tex=mat.node_tree.nodes.new("ShaderNodeTexImage")
tex.image=img
mat.node_tree.links.new(tex.outputs["Color"],shader.inputs["Base Color"])
mesh.materials.append(mat)
uv=mesh.uv_layers.new(name="SkinUV")
for poly in mesh.polygons:
    tile=face_tiles[poly.index]
    center_u=(tile%2)*0.5
    center_v=(tile//2)*0.5
    for n,li in enumerate(poly.loop_indices):
        # Quad side order traverses base-left, base-right, tip-right, tip-left.
        corners=[(0.03,0.03),(0.97,0.03),(0.97,0.97),(0.03,0.97)]
        u,v=corners[n%4]
        uv.data[li].uv=(center_u+u*0.5,center_v+v*0.5)
mesh.uv_layers.active_index=0
bpy.ops.object.select_all(action="DESELECT")
obj.select_set(True)
bpy.context.view_layer.objects.active=obj
sub=obj.modifiers.new("OneLevelAnatomicalRounding","SUBSURF")
sub.levels=1
sub.render_levels=1
bpy.ops.object.modifier_apply(modifier=sub.name)
for poly in obj.data.polygons:
    poly.use_smooth=True
print({"mesh":obj.name,"vertices":len(obj.data.vertices),
       "triangles":sum(len(p.vertices)-2 for p in obj.data.polygons),
       "materials":len(obj.data.materials),"handedness":obj["handedness"],
       "dimensions":tuple(round(v,4) for v in obj.dimensions)})

