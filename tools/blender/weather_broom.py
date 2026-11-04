# Blender MCP: weather the approved broom without changing its silhouette.
import bpy, math, json
from array import array

obj = bpy.data.objects['CinemaBroomMesh']
bpy.ops.object.select_all(action='DESELECT')
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
mesh = obj.data
regions = mesh.attributes.get('broom_material_region')
if regions is None:
    regions = mesh.attributes.new('broom_material_region', 'INT', 'FACE')
    for poly in mesh.polygons:
        regions.data[poly.index].value = poly.material_index
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.012)
bpy.ops.object.mode_set(mode='OBJECT')
mesh.calc_loop_triangles()
uvs = mesh.uv_layers.active.data
size = 1024
pixels = array('f', [0.16, 0.17, 0.15, 1.0]) * (size * size)
occupied = bytearray(size * size)
palette = [(0.49,0.445,0.33), (0.40,0.355,0.25),
           (0.12,0.14,0.125), (0.265,0.325,0.295),
           (0.36,0.145,0.13)]
edge_palette = [(0.58,0.53,0.40), (0.49,0.43,0.30),
                (0.23,0.245,0.21), (0.43,0.455,0.38),
                (0.49,0.32,0.255)]
face_edges = {}
for poly in mesh.polygons:
    pts = [(uvs[i].uv.x*size, uvs[i].uv.y*size) for i in poly.loop_indices]
    edges = []
    for i,a in enumerate(pts):
        b=pts[(i+1)%len(pts)]
        dx,dy=b[0]-a[0],b[1]-a[1]
        edges.append((a[0],a[1],dx,dy,max(dx*dx+dy*dy,0.00001)))
    face_edges[poly.index]=edges
for tri in mesh.loop_triangles:
    uv = [(uvs[i].uv.x*size, uvs[i].uv.y*size) for i in tri.loops]
    coords = [mesh.vertices[i].co[:] for i in tri.vertices]
    a,b,c=uv
    det=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
    if abs(det)<0.000001: continue
    region=regions.data[tri.polygon_index].value
    base=palette[region]
    worn=edge_palette[region]
    edges=face_edges[tri.polygon_index]
    for py in range(max(0,int(min(v[1] for v in uv))),min(size,int(max(v[1] for v in uv))+1)):
        fy=py+0.5
        for px in range(max(0,int(min(v[0] for v in uv))),min(size,int(max(v[0] for v in uv))+1)):
            fx=px+0.5
            w0=((b[1]-c[1])*(fx-c[0])+(c[0]-b[0])*(fy-c[1]))/det
            w1=((c[1]-a[1])*(fx-c[0])+(a[0]-c[0])*(fy-c[1]))/det
            w2=1-w0-w1
            if min(w0,w1,w2)<-0.00001: continue
            x,y,z=[coords[0][i]*w0+coords[1][i]*w1+coords[2][i]*w2 for i in range(3)]
            broad=(math.sin(x*39+y*23+math.sin(z*13)*1.9)+math.sin(z*37-x*24)+math.sin(y*81+z*19)) / 3.0
            fine=math.sin(x*441+z*177+y*313)*math.sin(z*311-y*277)
            speck=math.sin(fx*12.9898+fy*78.233)*43758.5453
            speck=speck-math.floor(speck)
            shade=0.92+broad*0.13+fine*0.025+(speck-0.5)*0.035
            edge=1000000.0
            for ex,ey,dx,dy,denom in edges:
                t=max(0.0,min(1.0,((fx-ex)*dx+(fy-ey)*dy)/denom))
                edge=min(edge,(fx-ex-dx*t)**2+(fy-ey-dy*t)**2)
            edge=math.sqrt(edge)
            chip=max(0.0,1.0-edge/(1.15+0.65*math.sin(z*143+x*89+y*171)))
            chip*=max(0.0,min(1.0,0.50+broad*2.3+fine*0.35))
            if region in (3,4):
                # Broken longitudinal rub marks, with finer crosswise scratches.
                grain=abs(math.sin(x*413+y*367+0.32*math.sin(z*19)))
                scratch=max(0.0,1.0-grain/0.055)*max(0.0,math.sin(z*83+x*31)-0.28)
                cross=max(0.0,1.0-abs(math.sin(z*207+x*57+y*39))/0.045)*max(0.0,broad-0.12)
                chip=max(chip*0.78,scratch*0.48,cross*0.70)
                # Small irregular rubbed patches, not uniform noise.
                grime=max(0.0,broad-0.27)*0.32
                shade-=grime
            else:
                grain=abs(math.sin(x*965+y*773+math.sin(z*37)*0.3))
                shade-=max(0.0,1.0-grain/0.16)*0.16
                shade-=max(0.0,1.0-z/0.045)*0.13
                chip*=0.40
            offset=(py*size+px)*4
            for i in range(3):
                pixels[offset+i]=max(0.025,min(0.80,base[i]*shade*(1-chip)+worn[i]*chip))
            occupied[py*size+px]=1
# Dilate island colours by four texels to prevent dark seams in filtered mips.
for step in range(4):
    additions=[]
    for index in range(size*size):
        if occupied[index]: continue
        px=index%size
        neighbors=[]
        if px>0: neighbors.append(index-1)
        if px<size-1: neighbors.append(index+1)
        if index>=size: neighbors.append(index-size)
        if index<size*(size-1): neighbors.append(index+size)
        for other in neighbors:
            if occupied[other]:
                additions.append((index,other))
                break
    for index,other in additions:
        pixels[index*4:index*4+4]=pixels[other*4:other*4+4]
        occupied[index]=1
image=bpy.data.images.get('CinemaBroom_Wear_Albedo')
if image is None:
    image=bpy.data.images.new('CinemaBroom_Wear_Albedo',width=size,height=size,alpha=True)
image.colorspace_settings.name='sRGB'
image.pixels.foreach_set(pixels)
image.update()
image.filepath_raw='D:/Disco duro/GODOT/TFG_CINEMA/art_source/textures/props/cinema_broom_wear_albedo.png'
image.file_format='PNG'
image.save()
image.pack()
mat=bpy.data.materials.get('Broom_Weathered_Atlas') or bpy.data.materials.new('Broom_Weathered_Atlas')
mat.use_nodes=True
nodes=mat.node_tree.nodes
nodes.clear()
bsdf=nodes.new('ShaderNodeBsdfPrincipled')
bsdf.inputs['Roughness'].default_value=0.88
bsdf.inputs['Metallic'].default_value=0.05
out=nodes.new('ShaderNodeOutputMaterial')
tex=nodes.new('ShaderNodeTexImage')
tex.image=image
mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
mat.node_tree.links.new(bsdf.outputs['BSDF'],out.inputs['Surface'])
mat.diffuse_color=(0.06,0.085,0.07,1)
mesh.materials.clear()
mesh.materials.append(mat)
for poly in mesh.polygons: poly.material_index=0
obj['weathering_version']='2026-11-04: dark vacuum palette, edge scuffs, rubbed paint, aged bristles; one 1024 atlas'
mesh.update()
print(json.dumps({'triangles':len(mesh.loop_triangles),'vertices':len(mesh.vertices),'materials':len(mesh.materials),'atlas':[size,size],'dimensions':list(obj.dimensions),'scale':list(obj.scale),'location':list(obj.location)}))

