"""Build, audit, render, export, and reload the kit in a FRESH Blender process.

blender --background --factory-startup --python-exit-code 1 --python models/leg-lg01/src/test_board.py
Uses system python3 for Pillow. All intermediates stay in work/; JPEGs and the
GLB-reload report go to output/kit/. -- --reload is an internal subprocess mode.
"""
import json
import math
import shutil
import struct
import subprocess
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
import bmesh
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
import kit
import materials
from common import init_scene, setup_studio, export_glb, ROOT, WORK, OUT

KIT_OUT=OUT/'kit'


def system_python(*args):
    executable=shutil.which('python3')
    if not executable: raise RuntimeError('System python3 with Pillow is required')
    subprocess.run([executable,str(Path(__file__).with_name('make_decals.py')),*args],check=True)


def build_board(ctx):
    m=ctx.materials
    objects=[]
    labels=[]
    def add(obj,name,origin=(0,0,0)):
        # All feature construction happens around the local origin before this
        # translation; this includes integral machining in receiver coordinates.
        obj.location+=Vector(origin)
        ctx.register(obj,'KIT-'+str(len(objects)+1).zfill(3),name,'Kit samples','reference',
                     'P2 style-guide sample',1)
        objects.append(obj)
        return obj
    centers=[(-3.05,1.55,0),(0,1.55,0),(3.05,1.55,0),
             (-3.05,-1.55,0),(0,-1.55,0),(3.05,-1.55,0)]
    titles=['01  FACETS / GROOVES / WELLS','02  ACCESS HATCH / STENCILS',
            '03  GRAB RAIL / UNIT MARK','04  VERTICAL LOUVER INTAKE',
            '05  TWIN BRONZE-LINED BELLS','06  CYLINDER / CLEVIS / CABLES']
    panels=[]
    for i,(x,y,z) in enumerate(centers):
        obj=kit.plate(kit.chamfered_rect(2.55,2.30,.18),.18,
                      chamfer=[.07,.09,.075,.09,.07,.09,.075,.09],
                      material=m['armor'],name='Sample armor')
        panels.append(obj)
        labels.append((titles[i],(x,y-1.38,0)))
    # Tile 1: real slots and octagonal wells, with an articulated faceted edge.
    p=panels[0]
    kit.panel_line(p,[(-1.3,.37),(-.4,.37),(-.13,.10),(.92,.10)],.18,material=m['recess'])
    kit.panel_line(p,[(-.13,.10),(-.13,-1.2)],.18,material=m['recess'])
    bolts=kit.bolt_group(p,[(-.92,.78,.18),(-.62,.78,.18),(.85,-.72,.18),(.85,-.40,.18)],
                         .075,material=m['steel'])
    add(bolts,'Octagonal well bolt group',centers[0])
    nose=kit.faceted_nose(.80,.50,.16,m['ochre'])
    nose.location=(.58,.69,.18)
    add(nose,'Faceted ochre nose',centers[0])
    # Tile 2: closed ring topology surrounds a genuinely inset hatch.
    hatch=kit.access_hatch(1.54,1.65,.16,material=m['armor'],dark=m['recess'],steel=m['steel'])
    hatch.location.z=.181
    add(hatch,'Inset service hatch',centers[1])
    caution=materials.decal('caution',.81)
    caution.location=(-.12,.40,.321)
    add(caution,'CAUTION stencil',centers[1])
    # Tile 3: raised rail feet, small red marks, grey unit number.
    rail=kit.grab_rail(1.47,.25,.065,m['ochre'],m['gunmetal'])
    rail.location=(0,.35,.18)
    add(rail,'Bent grab rail with bolted feet',centers[2])
    unit=materials.decal('unit01',.36)
    unit.location=(-.72,-.55,.1807)
    add(unit,'Unit 01 stencil',centers[2])
    marks=materials.decal('red_marks',.45)
    marks.location=(.65,-.47,.1807)
    add(marks,'Red caution bars',centers[2])
    # Tile 4: actual open aperture and vertical blades, unlike turnaround slots.
    intake=kit.louvered_intake(1.39,1.85,.29,5,m['ochre'],m['gunmetal'])
    intake.location.z=.18
    add(intake,'Ochre intake frame and vertical louvers',centers[3])
    # Tile 5: two calf mouths with separate lining material; open throat bores.
    recess=kit.plate(kit.chamfered_rect(1.3,2.06,.20),.08,.025,material=m['recess'])
    recess.location.z=.18
    add(recess,'Calf nozzle recess',centers[4])
    for y in (-.52,.52):
        bell=kit.bell_nozzle(.16,.43,.52,.027,m['gunmetal'],m['bronze'])
        kit.place(bell,(0,y,.27),(0,.20,1))
        add(bell,'Calf bell nozzle',centers[4])
    # Tile 6: aimed mechanism with transverse spherical bores and a small loom.
    actuator=kit.hydraulic_cylinder((-.66,-.69,.40),(-.43,.89,.55),1.22,
                                    .135,.061,m['gunmetal'],m['chrome'],m['steel'],
                                    eye_axis=(0,0,1))
    add(actuator,'Aimed hydraulic cylinder',centers[5])
    clevis=kit.clevis(.38,.16,.32,.31,.048,m['steel'])
    kit.place(clevis,(-.66,-.70,.20))
    add(clevis,'Clevis with pin bores',centers[5])
    cables=kit.cable_bundle([(.15,-.90,.23),(.42,-.5,.30),(.66,-.05,.33),(.62,.6,.28),(.90,.91,.23)],
                            4,.026,material=m['rubber'])
    add(cables,'Four swept service cables',centers[5])
    for x,y in ((.32,-.65),(.65,.65)):
        collar=kit.chamfered_box((.33,.08,.09),(x,y,.30),.015,m['steel'])
        add(collar,'Cable restraint',centers[5])
    sensor=kit.chamfered_box((.18,.10,.05),(.93,-.90,.205),.009,m['amber'])
    add(sensor,'Amber service sensor',centers[5])
    mark=kit.chamfered_box((.27,.055,.009),(.87,-.72,.185),.002,m['red'])
    add(mark,'Caution red paint sample',centers[5])
    for i,p in enumerate(panels): add(p,'Chamfered armor sample',centers[i])
    return objects,labels


def geometry_audit(objects):
    rows=[]
    for obj in objects:
        bm=bmesh.new(); bm.from_mesh(obj.data)
        bad=sum(not e.is_manifold for e in bm.edges)
        # Check each disconnected shell independently: a positive total could
        # otherwise hide an inverted inner feature in a larger positive shell.
        unseen=set(bm.faces); volumes=[]
        while unseen:
            todo=[unseen.pop()]; component=[]
            while todo:
                face=todo.pop(); component.append(face)
                for edge in face.edges:
                    for neighbor in edge.link_faces:
                        if neighbor in unseen: unseen.remove(neighbor); todo.append(neighbor)
            volumes.append(sum(f.calc_area()*f.calc_center_median().dot(f.normal)/3 for f in component))
        bm.free()
        obj.data.calc_loop_triangles()
        row={'name':obj.name,'triangles':len(obj.data.loop_triangles),'non_manifold_edges':bad,
             'closed_shells':len(volumes),'all_shells_outward':all(v>1e-12 for v in volumes),
             'unapplied_modifiers':len(obj.modifiers),'has_wear':bool(obj.data.color_attributes.get('Wear'))}
        rows.append(row)
        if bad or not row['all_shells_outward'] or obj.modifiers:
            raise AssertionError(row)
    if len({o.data.as_pointer() for o in objects})!=len(objects):
        raise AssertionError('Shared mesh datablocks')
    return {'passed':True,'objects':rows,'triangles':sum(r['triangles'] for r in rows),
            'independent_mesh_datablocks':len(objects)}


def glb_json(path):
    data=path.read_bytes()
    size,kind=struct.unpack_from('<II',data,12)
    if kind!=0x4e4f534a: raise ValueError('First GLB chunk is not JSON')
    return json.loads(data[20:20+size])


def reload_report():
    expected=json.loads((WORK/'board-expected.json').read_text())
    gltf=glb_json(WORK/'test-board.glb')
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(WORK/'test-board.glb'))
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    imported={m.name:m for o in objects for m in o.data.materials}
    gltf_mats={m['name']:m for m in gltf.get('materials',[])}
    report={'blender':bpy.app.version_string,'fresh_factory_startup':True,
            'object_count':len(objects),'expected_object_count':expected['objects'],
            'objects':[{'name':o.name,'instance_id':o.get('instance_id'),
                        'part_id':o.get('part_id'),'part_name':o.get('part_name'),
                        'materials':[m.name for m in o.data.materials]} for o in objects],
            'materials':[],'geometry':expected['geometry']}
    close=lambda a,b: len(a)==len(b) and all(abs(x-y)<.0002 for x,y in zip(a,b))
    for entry in expected['materials']:
        name=entry['name']; src=gltf_mats.get(name,{})
        pbr=src.get('pbrMetallicRoughness',{})
        mat=imported.get(name)
        bsdf=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None) if mat else None
        images=[n.image.name for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image] if mat else []
        base=pbr.get('baseColorFactor',[1,1,1,1])
        metal=pbr.get('metallicFactor',1); rough=pbr.get('roughnessFactor',1)
        # Compare actual glTF factors AND the reconstructed shader. A linked
        # vertex-color base is checked by its constant multiply operand.
        imported_base=list(bsdf.inputs['Base Color'].default_value) if bsdf else []
        if bsdf and bsdf.inputs['Base Color'].is_linked:
            for node in mat.node_tree.nodes:
                if node.type=='MIX' and node.data_type=='RGBA' and node.blend_type=='MULTIPLY':
                    for inp in node.inputs:
                        if inp.type=='RGBA' and not inp.is_linked and close(list(inp.default_value),entry['base_color']):
                            imported_base=list(inp.default_value)
                if node.type=='MIX_RGB' and node.blend_type=='MULTIPLY':
                    for inp in list(node.inputs)[1:]:
                        if not inp.is_linked and close(list(inp.default_value),entry['base_color']):
                            imported_base=list(inp.default_value)
        is_decal=entry['decal']
        checks={'name':mat is not None,'base_color':close(base,entry['base_color']),
                'metallic':abs(metal-entry['metallic'])<.0002,
                'roughness':abs(rough-entry['roughness'])<.0002,
                'imported_base_color':is_decal or close(imported_base,entry['base_color']),
                'imported_metallic':bool(bsdf) and abs(bsdf.inputs['Metallic'].default_value-entry['metallic'])<.0002,
                'imported_roughness':bool(bsdf) and abs(bsdf.inputs['Roughness'].default_value-entry['roughness'])<.0002,
                'decal_image':not is_decal or (bool(images) and 'baseColorTexture' in pbr),
                'decal_alpha':not is_decal or (src.get('alphaMode') in {'BLEND','MASK'} and bool(bsdf.inputs['Alpha'].is_linked))}
        report['materials'].append({'name':name,'base_color':base,'metallic':metal,'roughness':rough,
                                    'imported_base_color':imported_base,'decal_images':images,
                                    'checks':checks,'intact':all(checks.values())})
    primitives=[p for m in gltf.get('meshes',[]) for p in m['primitives']]
    report['color_0_primitives']=sum('COLOR_0' in p.get('attributes',{}) for p in primitives)
    report['imported_color_attribute_objects']=sum(bool(o.data.color_attributes) for o in objects)
    report['extras_intact']=sorted(o.get('instance_id','') for o in objects)==sorted(expected['instance_ids'])
    report['presentation_excluded']=not any(o.type in {'LIGHT','CAMERA'} for o in bpy.context.scene.objects)
    report['passed']=(len(objects)==expected['objects'] and all(m['intact'] for m in report['materials'])
                      and report['color_0_primitives']>0 and report['imported_color_attribute_objects']>0
                      and report['extras_intact'] and report['presentation_excluded'])
    (KIT_OUT/'glb-reload.json').write_text(json.dumps(report,indent=2)+'\n')
    if not report['passed']:
        raise AssertionError('GLB round-trip failed: '+str([m for m in report['materials'] if not m['intact']]))
    print('GLB ROUND TRIP PASSED:',len(objects),'objects,',len(report['materials']),'materials',flush=True)


def main():
    KIT_OUT.mkdir(parents=True,exist_ok=True)
    WORK.mkdir(parents=True,exist_ok=True)
    system_python()
    ctx=init_scene()
    objects,labels=build_board(ctx)
    geometry=geometry_audit(objects)
    camera=setup_studio(target=(0,0,.1),camera_location=(0,-8.5,16),scale=10.8)
    # White studio floor; excluded from exports along with labels/camera/lights.
    ground=kit.chamfered_box((200,200,.05),(0,0,-.065),0,
                            materials.principled('Studio white','#FFFFFF',0,.8),'White studio floor')
    for col in list(ground.users_collection): col.objects.unlink(ground)
    ctx.collections['presentation'].objects.link(ground)
    # Preserve the studio world for reflections but composite the camera
    # background onto pure white in Pillow (AgX would tone-map it to grey).
    ground.hide_render=True
    bpy.context.scene.render.film_transparent=True
    bpy.context.view_layer.update()
    pixel_labels=[]
    for text,point in labels:
        p=world_to_camera_view(bpy.context.scene,camera,Vector(point))
        pixel_labels.append({'text':text,'pixel':[round(p.x*1600),round((1-p.y)*1000)]})
    (WORK/'board-labels.json').write_text(json.dumps(pixel_labels,indent=2))
    used={mat.name:mat for obj in objects for mat in obj.data.materials}
    expected={'objects':len(objects),'instance_ids':[o['instance_id'] for o in objects],
              'geometry':geometry,'materials':[{'name':name,'base_color':list(mat['expected_base_color']),
                'metallic':mat['expected_metallic'],'roughness':mat['expected_roughness'],
                'decal':name.startswith('LG01 Decal')} for name,mat in sorted(used.items())]}
    (WORK/'board-expected.json').write_text(json.dumps(expected,indent=2)+'\n')
    export_glb(WORK/'test-board.glb',objects+[ground,camera])
    scene=bpy.context.scene
    scene.render.image_settings.file_format='PNG'
    scene.render.image_settings.color_mode='RGBA'
    scene.render.filepath=str(WORK/'test-board.png')
    bpy.ops.wm.save_as_mainfile(filepath=str(WORK/'test-board.blend'))
    print('RENDERING TEST BOARD',flush=True)
    bpy.ops.render.render(write_still=True)
    system_python('--compose')
    # Start another Blender executable with factory startup, not a reset of this
    # process. Log goes to scratch and exceptions make the acceptance command fail.
    with (WORK/'glb-reload.log').open('w') as log:
        result=subprocess.run([bpy.app.binary_path,'--background','--factory-startup','--python-exit-code','1',
                               '--python',str(Path(__file__).resolve()),'--','--reload'],stdout=log,stderr=subprocess.STDOUT)
    if result.returncode:
        print((WORK/'glb-reload.log').read_text()[-12000:])
        raise RuntimeError('Fresh Blender GLB reload failed')
    print('TEST BOARD PASSED:',geometry['triangles'],'triangles;',len(objects),'objects',flush=True)


if __name__=='__main__':
    reload_report() if '--reload' in sys.argv else main()
