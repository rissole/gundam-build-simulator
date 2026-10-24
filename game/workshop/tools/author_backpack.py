"""Prepared backpack source, authored about its hinge in the 90-degree open pose.

Godot local X is right, Y is up and Z is rear. Closed geometry follows from a
+90-degree local-X rotation; the hinge datum does not move. External installation
and articulated strut/service controls are supplied by the receiving workflow.
"""
import math


def extend(trial, chest, layout, kinds, diagram):
    sources=trial["sources"];context=[]
    def box(at,size):return dict(shape="box",center=at,size=size)
    def tube(at,outer,inner,length,axis="x"):
        if axis=="z":axis=[0,0,1]
        return dict(shape="tube",center=at,outer=outer,inner=inner,length=length,axis=axis)
    def source(uid,shapes,owner=context,at=(0,0,0)):
        sources[uid]=dict(family=uid.split("__")[0],position=list(at),rotation_degrees=[0,0,0],primitives=shapes)
        # Preserve the moving frame's open recesses instead of replacing each
        # source with its enclosing box. Tube convex hulls preserve their outer
        # profile; pin-bore fit is independently checked against source triangles.
        motion=[]
        for shape in shapes:
            if shape["shape"]=="box":motion.append(dict(type="box",position=shape["center"],size=shape["size"]))
            elif shape["shape"]=="tube":
                axis=shape["axis"]
                axis=[1,0,0] if axis=="x" else [0,1,0] if axis=="y" else [0,0,1] if axis=="z" else axis
                # Radial polygon extruded along the authored axis, including
                # the tilted nozzle cylinders; no arbitrary AABB fills a recess.
                helper=[0,0,1] if abs(axis[2])<.9 else [1,0,0]
                u=[axis[1]*helper[2]-axis[2]*helper[1],axis[2]*helper[0]-axis[0]*helper[2],axis[0]*helper[1]-axis[1]*helper[0]]
                norm=math.sqrt(sum(v*v for v in u));u=[v/norm for v in u]
                v=[axis[1]*u[2]-axis[2]*u[1],axis[2]*u[0]-axis[0]*u[2],axis[0]*u[1]-axis[1]*u[0]]
                points=[]
                for sign in [-1,1]:
                    for i in range(32):
                        a=i*math.tau/32
                        points.append([shape["center"][j]+sign*axis[j]*shape["length"]/2+shape["outer"]*(u[j]*math.cos(a)+v[j]*math.sin(a)) for j in range(3)])
                motion.append(dict(type="convex",points=points))
        if len(motion)==len(shapes):sources[uid]["motion_shapes"]=motion
        owner.append(uid)

    frame=[]
    for side in [-1,1]:
        frame += [box([side*1.18,.445,1.4],[.04,.67,2.6]),
                  box([side*.72,.73,1.4],[.14,.14,2.4]),
                  box([side*.90,.26,.17],[.094,.52,.20])]
    frame += [box([0,.40,.16],[2.32,.12,.12]),box([0,.40,2.70],[2.32,.60,.20])]
    source("BP-FRAME__001",frame)
    # Rear panel and integral nozzle mounts stay inside the compact envelope.
    # The nozzles are separate visible manufactured pieces on the supplied pack.
    source("BP-SHELL__001",[box([0,.82,1.4],[2.4,.08,2.6])])
    for n,side in enumerate([-1,1],1):
        source(f"BP-HINGE__{n:03}",[tube([side*.9,0,0],.065,.0305,.094),box([side*.9,.12,.10],[.094,.24,.12])])
        source(f"BP-LIFT__{n:03}",[box([side*.72,.86,1.4],[.22,.04,.20])])
        source(f"BP-NOZZLE__{n:03}",[tube([side*.55,.88,2.4],.24,.205,.10,[0,math.cos(math.radians(15)),math.sin(math.radians(15))])])
        # Prepared B eye and stowed telescope lie under the back skin. The
        # receiving controller will extend the free A end before pinning it.
        source(f"BP-STRUT-B__{n:03}",[tube([0,0,0],.065,.0205,.074),tube([0,0,.42],.04,.032,.72,"z"),box([side*.05,0,.55],[.04,.04,.12])],at=[side*1.08,.75,1.15])
        source(f"BP-STRUT-MID__{n:03}",[tube([0,0,0],.031,.024,.70,"z")],at=[side*1.08,.75,1.572])
        source(f"BP-STRUT-A__{n:03}",[tube([0,0,0],.065,.0205,.074),tube([0,0,-.418],.023,0,.70,"z")],at=[side*1.08,.75,1.994])
        source(f"BP-LATCH__{n:03}",[box([side*1.04,.82,2.55],[.14,.04,.22])])
        source(f"BP-LATCH-LEVER__{n:03}",[box([0,0,0],[.08,.02,.14])],at=[side*1.04,.85,2.55])
        # A prepared link and draw-hook capture the existing lower striker.
        # The open hook clears by2 mm; the captive lever draws it into contact.
        source(f"BP-DRAW__{n:03}",[box([side*1.075,.476,2.54],[.03,.728,.03]),
            box([side*1.11,.112,2.53],[.08,.020,.18]),
            box([side*1.11,.086,2.44],[.08,.072,.020]),box([side*1.11,.086,2.62],[.08,.072,.020])])
        cover=f"BP-SERVICE-COVER__{n:03}"
        source(cover,[box([0,0,0],[.16,.04,.20])],at=[side*.57,.89,.35])
        sources[cover]["rotation_degrees"]=[0,0,60]

    # Replace the nominal A-eye stand-ins with actual fixed receiving clevises.
    roots=sources["CH-REAR-ROOTS__001"]["primitives"]
    sources["CH-REAR-ROOTS__001"]["primitives"]=[p for p in roots if p["shape"]!="tube"]
    for p in sources["CH-REAR-ROOTS__001"]["primitives"]:
        if p["center"][1]>2:
            p["center"][2]=1.025;p["size"][2]=.15
    for n,side in enumerate([-1,1],1):
        fixed=[]
        for dx in [-.07,.07]:
            fixed += [tube([side*.9+dx,2.8,1.2],.075,.0305,.04),box([side*.9+dx,2.8,1.10],[.04,.12,.20])]
        for dx in [-.055,.055]:
            fixed += [tube([side*1.08+dx,2.15,1.27],.065,.0205,.03),box([side*1.08+dx,2.15,1.16],[.03,.10,.22])]
        fixed += [box([side*1.11,.27,1.25],[.12,.12,.10])]
        source(f"CH-BACKPACK-ROOT__{n:03}",fixed,chest["context_sources"])

    descriptor=dict(title="Prepared open backpack",carry_class="equipment",bounds=[2.4,1.06,2.865],
        work_locations=["support","parent"],interaction="components",context_sources=context,slots={},
        supplied_milestones=["prepared"],milestones={"prepared":[]},manual=[dict(title="Prepared open backpack",view="overview",slots=[],
        body="The backpack frame, rear cover, nozzles, hinge eyes, telescopic struts and lower latches are supplied together. Fit backpack perimeter inserts on the empty bulky fixture, then use Backpack to fixture to collect this same unit from its storage saddles. Its front face rests downward, in the fully open installation orientation. Two structural lifting pads carry it with the shared spreader.")])
    trial["parents"].append(dict(id="backpack",definition="backpack",label=descriptor["title"],location="support:backpack_store",home=layout["workshop"]["backpack_storage"]["position"]))
    trial["supports"]["backpack_store"]=dict(assemblies=["backpack"],assembly_ids=["backpack"])
    for name in ["bulky_fixture","crane_rigging"]:
        trial["supports"][name]["assemblies"].append("backpack");trial["supports"][name]["assembly_ids"].append("backpack")
    slots=chest["slots"]
    slots["backpack"]=dict(assembly="backpack",milestone="prepared",requires=[],label=descriptor["title"],
        pose_source="BP-FRAME__001",snap_position=[0,2.8,1.2],support_required=True,source_supports=["crane_rigging"],
        undo_requires_support="crane_rigging",access_policy="mounted",mounted_motion="backpack_hinge",secured_equipment="backpack_hinge")
    for key,family,title in [("bp-hinge-pin","BP-P60","60 mm hinge pin"),("bp-hinge-keeper","BP-K60","60 mm hinge-pin keeper"),
                             ("bp-strut-pin","BP-P40","40 mm strut-base pin"),("bp-strut-keeper","BP-K40","40 mm strut-pin keeper"),
                             ("bp-service","BP-SERVICE","Protected backpack service run")]:
        kinds[key]=dict(family=family,variant=key,title=family+" · "+title,short_title=title,carry_class="pocket")
    def connection(sid,key,uid,requires,at,shapes,**extra):
        source(uid,shapes,owner=[],at=at)
        trial["parts"].append(dict(instance_id=uid,source_id=uid,part_id=kinds[key]["family"],kind=key,location="bin"))
        slots[sid]=dict(accepts=key,pose_source=uid,requires=list(requires),label=kinds[key]["title"],access_policy="mounted",**extra)
        return sid
    hinge=[];struts=[];services=[]
    for n,side in enumerate([-1,1],1):
        for name,x,y,z,radius,length,target in [("hinge",1.02,2.8,1.2,.03,.24,hinge),("strut",1.18,2.15,1.27,.02,.20,struts)]:
            family="60" if name=="hinge" else "40"
            at=[side*x,y,z];groove=length-.02
            uid=f"BP-P{family}__{n:03}";sid=f"backpack/{name}_pin_{n}"
            shapes=[tube([-side*(groove-.005)/2,0,0],radius,0,groove-.005),
                tube([-side*groove,0,0],radius-.006,0,.010),tube([-side*(length-.0075),0,0],radius,0,.015),
                tube([side*.008,0,0],radius+.012,0,.016)]
            req=["backpack"] if name=="hinge" else list(hinge)
            target.append(connection(sid,"bp-"+name+"-pin",uid,req,at,shapes,undo_requires_support="crane_rigging"))
            keeper=f"BP-K{family}__{n:03}"
            shape=dict(shape="ring_plate",center=[0,0,0],outer=radius+.008,inner=radius-.006,length=.006,axis="x",start_degrees=35,end_degrees=325)
            target.append(connection(f"backpack/{name}_keeper_{n}","bp-"+name+"-keeper",keeper,[sid],
                [side*(x-groove),y,z],[shape],undo_requires_support="crane_rigging"))
    # Both struts depend on the complete hinge pair, not loop iteration order.
    for sid in struts:
        if "_pin_" in sid:slots[sid]["requires"]=list(hinge)
    for n,side in enumerate([-1,1],1):
        uid=f"BP-SERVICE__{n:03}"
        services.append(connection(f"backpack/service_{n}","bp-service",uid,hinge+struts,[side*.57,2.58,1.24],
            [tube([0,0,.035],.035,0,.07,"z"),tube([0,0,.070],.045,0,.014,"z")]))
        source(f"CH-BACKPACK-SERVICE__{n:03}",[tube([0,0,-.025],.055,.036,.05,"z")],chest["context_sources"],[side*.57,2.58,1.24])
        source(f"BP-SERVICE-TAIL__{n:03}",[tube([0,0,0],.045,.025,.10,"z")],at=[side*.57,.28,.14])
    def page(title,body,ids):
        return dict(title=title,body=body,slots=ids,view="components",diagram_views=[diagram(title,[slots[s]["pose_source"] for s in ids])])
    chest["manual"] += [page("Seat the open backpack","Select backpack inserts on the empty bulky fixture and collect the prepared unit with Backpack to fixture. Select Backpack to hinges, attach both ends and follow the rear delivery route. Down aligns both open hinge eyes with the fixed chest forks; keep both crane ends attached.",["backpack"]),
        page("Retain both backpack hinges","Insert each BP-P60 hinge pin from the outboard side, then fit its BP-K60 keeper into the exposed inner groove. Both complete pin/keeper pairs are required before extending the struts.",hinge),
        page("Attach the backpack struts","At each free strut-end handle, Extend guides the prepared telescope to its fixed chest clevis. Fit the BP-P40 base pin and its BP-K40 keeper. Engage both positive open locks before releasing either crane end.",struts),
        page("Connect the supported backpack","With both struts positively locked open, release and stow both crane ends. Fit both BP-SERVICE protected runs at the fixed rear-facing sockets. The upper retained loops move with the cover; they provide no lifting support.",services),
        dict(title="Close and latch the backpack",view="overview",slots=[],status_equipment="backpack_hinge",
            body="Return the matching crane, refit both ends, then choose Take backpack weight. Release both strut locks at their handles. Choose Close backpack at the crane; Stop/Resume preserves partial closure. At the closed stop engage both lower draw latches, release and stow the crane ends, then close the two small service covers. For correction, reopen the covers, refit both ends and take weight before releasing either latch. Open fully and engage both strut locks before releasing the crane or changing service connections.")]
    chest["manual"][-5]["diagram_views"]=[diagram("Open backpack onto fixed hinge forks",context,["CH-BACKPACK-ROOT__001","CH-BACKPACK-ROOT__002"],offsets={uid:[0,2.8,1.2] for uid in context})]
    chest["milestones"]["backpack_retained"]=["backpack"]+hinge+struts
    chest["milestones"]["backpack_connected"]=["backpack"]+hinge+struts+services
    trial["robot"]["security_slots"]["backpack"]=["backpack"]+hinge+struts
    trial["robot"]["controlled_mount_slots"].append("chest.backpack")
    trial["robot"]["playable_slots"]["chest"]=list(slots)
    trial["equipment"]["backpack_hinge"]=dict(uid="backpack",owner="chest",slot="backpack",seat=[0,2.8,1.2],
        hinge_slots=hinge,strut_slots=struts,service_slots=services,
        strut_b=[[-1.08,.75,1.15],[1.08,.75,1.15]],strut_a=[[-1.08,2.15,1.27],[1.08,2.15,1.27]],
        stowed_length=.844,service_fixed=[[-.57,2.58,1.24],[.57,2.58,1.24]],service_pack=[[-.57,.28,.14],[.57,.28,.14]],
        service_nominal_length=.95,service_minimum_bend_radius=.10,
        latch_positions=[[-1.04,.84,2.55],[1.04,.84,2.55]])
    return descriptor
