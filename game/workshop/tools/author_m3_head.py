"""Head assembly pieces in upright Godot axes, datum robot (0,0,15.40).

Only prepared physical members are context; the chest manual owns each mounted
piece and its external hardware. No complete-head inventory object is added.
"""
import argparse
import math
import subprocess
import sys
from pathlib import Path
from copy import deepcopy

PIECES = [("head_baseplate", "Head baseplate", 15.40, .60, [.95,.60,15.6]),
          ("head_left", "Left wraparound side", 15.52, .85, [1.4,.73,10.6]),
          ("head_right", "Right wraparound side", 15.52, .85, [.8,.73,17.1]),
          ("head_top", "Structural head top", 16.96, .85, [5.15,-.71,10.6]),
          ("head_crown", "Decorative head crown", 17.20, .85, [5.15,-.95,17.1])]


def pose(at):return dict(position=list(at), rotation_degrees=[0,0,0])
def point(x,y,z):return [x,round(z-15.4,6),-y]
def box(at,size):return dict(shape="box",center=list(at),size=list(size))
def tube(at,outer,inner,length,axis="y"):return dict(shape="tube",center=list(at),outer=outer,inner=inner,length=length,axis=axis)


def perforated(at,size,holes,axis="front"):
    """Box runs around rectangular openings; source and collision share the voids."""
    w,h,d=size
    xs=sorted(set([-w/2,w/2]+[x+s*hw/2 for x,y,hw,hh in holes for s in [-1,1] if -w/2<x+s*hw/2<w/2]))
    ys=sorted(set([-h/2,h/2]+[y+s*hh/2 for x,y,hw,hh in holes for s in [-1,1] if -h/2<y+s*hh/2<h/2]))
    rectangles=[];previous={}
    for c,e in zip(ys,ys[1:]):
        spans=[];start=None
        for a,b in zip(xs,xs[1:]):
            x,y=(a+b)/2,(c+e)/2
            filled=not any(abs(x-hx)<hw/2 and abs(y-hy)<hh/2 for hx,hy,hw,hh in holes)
            if filled and start is None:start=a
            if not filled and start is not None:spans.append((start,a));start=None
        if start is not None:spans.append((start,xs[-1]))
        current={}
        for a,b in spans:
            if (a,b) in previous:
                index=previous[(a,b)];rectangles[index][3]=e
            else:
                index=len(rectangles);rectangles.append([a,b,c,e])
            current[(a,b)]=index
        previous=current
    result=[]
    for a,b,c,e in rectangles:
        offset=[(a+b)/2,(c+e)/2,0] if axis=="front" else [(a+b)/2,0,(c+e)/2]
        result.append(box([round(p+q,6) for p,q in zip(at,offset)],
            [round(b-a,6),round(e-c,6),d] if axis=="front" else [round(b-a,6),d,round(e-c,6)]))
    return result


def crown_shapes():
    result=[]
    for x,width in [(-.20,.044),(.20,.064)]:
        # Different rectangular keys, open from below. Front bolt lane remains open.
        result+=perforated([x,1.92,-.615],[.12,.24,.01],[[0,-.04,.014,.014]])
        result.append(tube([x,1.88,-.64],.016,.0065,.04,[0,0,1]))
        result += [box([x,1.92,-.445],[.12,.24,.01]),
            box([x-(width+.01)/2,1.93,-.53],[.01,.22,.16]),box([x+(width+.01)/2,1.93,-.53],[.01,.22,.16]),
            box([x,2.055,-.53],[.12,.03,.18])]
    result.append(box([0,2.085,-.53],[.56,.03,.18]))
    for sign in [-1,1]:
        result += [box([sign*.40,2.18,-.56],[.36,.20,.12]),
            box([sign*.58,2.32,-.60],[.18,.24,.16]),
            box([sign*.96,2.48,-.56],[.68,.24,.12])]
    return result


def rig(uid):
    if uid=="head_crown":
        return [[x,2.36,-.68] for x in [-.58,.58]], [[0,0,-1]]*2, [[x,0,0] for x in [-.58,.58]]
    if uid=="head_baseplate":
        return [[x,.8,0] for x in [-.62,.62]], [[0,1,0]]*2, [[x,0,0] for x in [-.62,.62]]
    if uid=="head_top":
        return [[x,1.88,z] for x in [-.62,.62] for z in [-.70,.90]], [[0,0,n] for x in [-1,1] for n in [-1,1]], [[x,0,z] for x in [-.62,.62] for z in [-1.05,1.05]]
    x=-.62 if uid=="head_left" else .62
    return [[x,1.5,z] for z in [-.58,.90]], [[0,0,-1],[0,0,1]], [[0,0,z] for z in [-1.11,.99]]


def routes(layout):
    for uid,title,zmin,height,store in PIECES:
        points,normals,anchors=rig(uid)
        source=[3.25,round(height-(zmin-15.4),6),13]
        high=round(19-(zmin-15.4),6)
        approach=.24 if uid=="head_baseplate" else .18 if uid=="head_crown" else .22
        common=dict(title=title,payload="assembly",load_uid=uid,owner="chest",slot=uid,
            source_support="bulky_fixture",source_equipment="module_supports",support="m2_service_crane",
            guided_receiver=uid+"_receiver",receiver_equipment=uid+"_receiver",
            secured=dict(milestone=uid+"_retained"),endpoint_ids=["magnet_a","magnet_b","magnet_c","magnet_d"][:len(points)],
            magnetic_points={"head_pad_"+str(n):p for n,p in enumerate(points)},magnetic_normal=[0,1,0],
            handle_points={"head_pad_"+str(n):p for n,p in enumerate(points)},spreader_points=anchors,
            source_pose=pose(source),receiver_pose=pose([13,16.8,26]),
            route_positions=[source,[3.25,high,13],[13,high,13],[13,high,26],[13,16.8+approach,26],[13,16.8,26]],
            approach=dict(axis=[0,-1,0],distance=approach),rig_clearance=1.20,
            sweep_rig=True,exact_receiver=True,sweep_radius=2.1,up_y=high+max(p[1] for p in points)+1.2,
            access_mode="head",console_position=layout["workshop"]["crane"]["console"],overhead_y=23.0,
            park_position=[8.4,0,18],rack_contacts=[])
        if uid=="head_crown":common["rig_center_offset"]=[0,0,-.30]
        layout["crane"]["tasks"][uid]=common
        transfer=deepcopy(common)
        for key in ["source_equipment","guided_receiver","access_mode","exact_receiver"]:transfer.pop(key)
        transfer.update(title=title+" to fixture",owner=uid,slot="",source_support=uid+"_store",
            receiver_support="bulky_fixture",receiver_equipment="module_supports",receiver_contact=True,
            secured=dict(milestone=""),source_pose=pose(store),receiver_pose=pose(source),rig_adapter=uid+"_receiver",
            route_positions=[store,[store[0],6,store[2]],[3.25,6,store[2]],[3.25,6,13],source],up_y=9)
        layout["crane"]["tasks"][uid+"_to_fixture"]=transfer


def fixtures(data):
    """Exchangeable structural saddles and tipping braces; no new equipment."""
    data["zones"] += [uid+"_rig" for uid,*_ in PIECES]
    for uid,title,zmin,height,store in PIECES:
        y=round(height-(zmin-15.4),6)
        data["bulky_fixture"]["templates"][uid]=pose([3.25,y,13])
        group="bulky_insert_"+uid
        data["groups"][group]=dict(parent="bulky_frame",position=[0,0,0],rotation_degrees=[0,0,0],enabled=False)
        for parent,offset in [(group,[0,0,0]),("",[store[0],0,store[2]])]:
            # Support the plate, each side's lower structural foot, or roof ears.
            xs=[-.20,.20] if uid=="head_crown" else [-.62,.62] if uid in ["head_baseplate","head_top"] else [-.76 if uid=="head_left" else .76]
            for n,x in enumerate(xs):
                for j,z in enumerate([-.53] if uid=="head_crown" else [-.64,.84] if uid=="head_top" else [-.35,.35]):
                    prefix=(group if parent else uid+"_store")+f"_{n}_{j}"
                    for label,at,size,material in [("post",[x,height/2-.025,z],[.10,height-.05,.10],"steel"),
                        ("saddle",[x,height-.025,z],[.14,.05,.16],"yellow")]:
                        data["solids"].append(dict(id=prefix+"_"+label,parent=parent,
                            position=[a+b for a,b in zip(at,offset)],size=size,material=material,solid=True))
            # Front/rear jaws retract .25 m by the existing source_contact phase.
            for n,z in enumerate([-.64,-.42] if uid=="head_crown" else [-.64,.84] if uid=="head_top" else [-.40,.40]):
                name=("bulky_jaw_"+uid if parent else uid+"_store_brace")+"_"+str(n)
                if parent:
                    data["groups"][name]=dict(parent=parent,position=[0,height+.08,z],rotation_degrees=[0,0,0],enabled=True)
                    data["solids"].append(dict(id=name+"_pad",parent=name,position=[xs[0],0,0],size=[.08,.08,.08],material="yellow",solid=True))


def proxies(shapes):
    """Exact box runs and conservative convex tube sectors preserve open pockets."""
    result=[]
    for p in shapes:
        if p["shape"]=="box":result.append(dict(type="box",position=list(p["center"]),size=list(p["size"])));continue
        if p["inner"]==0:
            result.append(dict(type="cylinder",position=list(p["center"]),radius=p["outer"],height=p["length"],
                rotation_degrees=[0,0,0] if p.get("axis","y")=="y" else [90,0,0]));continue
        if p["outer"]<=.03:
            size=[p["outer"]*2]*3
            size[1 if p.get("axis","y")=="y" else 2]=p["length"]
            result.append(dict(type="box",position=list(p["center"]),size=size));continue
        # Annular sectors keep the pilot and bolt bores open in moving checks.
        axis=p.get("axis","y");a=[0,1,0] if axis=="y" else axis
        u=[1,0,0];v=[0,0,1] if a==[0,1,0] else [0,1,0]
        for n in range(64):
            verts=[]
            for h in [-1,1]:
                for angle in [n*math.tau/64,(n+1)*math.tau/64]:
                    for r in [p["inner"],p["outer"]]:
                        verts.append([p["center"][i]+a[i]*h*p["length"]/2+r*(u[i]*math.cos(angle)+v[i]*math.sin(angle)) for i in range(3)])
            result.append(dict(type="convex",points=verts))
    return result


def extend(trial,chest,kinds,layout,diagram):
    sources=trial["sources"];slots=chest["slots"];definitions={}
    def source(uid,at,shapes,motion=None):
        sources[uid]=dict(family=uid.split("__")[0],position=list(at),rotation_degrees=[0,0,0],primitives=shapes)
        if motion is not None:sources[uid]["motion_shapes"]=motion
    for key,family,title in [("hd-m24-160","HD-M24160","M24 × 160 neck bolt"),("hd-w24","HD-W24","M24 / 4 mm washer"),
        ("hd-m12-100","HD-M12100","M12 × 100 side bolt"),("hd-m12-160","HD-M12160","M12 × 160 top bolt"),
        ("hd-loom","HD-LOOM","Keyed central power/data loom and strain relief")]:
        kinds[key]=dict(family=family,variant=key,title=family+" · "+title,short_title=title,carry_class="pocket")
    def item(kind,uid,at,shapes,requires):
        source(uid,[at[0],round(at[1]+4.10,6),at[2]],shapes)
        trial["parts"].append(dict(instance_id=uid,source_id=uid,part_id=kinds[kind]["family"],kind=kind,location="bin"))
        sid=uid.lower().replace("__","/")
        slots[sid]=dict(accepts=kind,pose_source=uid,requires=requires,label=kinds[kind]["title"],access_policy="mounted",undo_requires_support="m2_service_crane")
        return sid
    def page(title,body,ids):
        chest["manual"].append(dict(title=title,body=body,slots=ids,view="components",diagram_views=[diagram(title,[slots[s]["pose_source"] for s in ids])]))
    retained={};connected=[]
    for uid,title,zmin,height,store in PIECES:
        shapes=[]
        if uid=="head_baseplate":
            # A perforated plate plus keyed hub. The notch is cut through both.
            holes=[[x,z,.0125] for x in [-.27,.27] for z in [-.27,.27]]+[[0,0,.162]]
            plate=dict(shape="plate",center=[0,.06,0],size=[1.44,.12,1.24],holes=holes,rect_holes=[[0,-.18,.084,.048]])
            hub=tube([0,.18,0],.26,.162,.12)
            # Split raised hub around the front key; back/side annulus remains.
            hub.update(start_degrees=-75,end_degrees=255)
            shapes=[plate,hub,box([0,.18,-.232],[.084,.12,.056])]
            for x in [-.64,.64]:
                for z in [-.45,.45]:
                    shapes.append(dict(shape="plate",center=[x,.46,z],size=[.10,.10,.68],axis=[0,0,1],
                        holes=[[.02 if x>0 else -.02,.46-y,.0065] for y in [.40,.78]] if z<0 else []))
                shapes.append(box([x,.77,0],[.10,.06,.80]))
            # Sweep compounds preserve the actual keyed passage. Seat-bearing
            # faces use 2 mm contact tolerance for MotionSweep's 1 mm margin;
            # the rendered/collision source still meets the exact hard seat.
            def clip(poly,axis,bound,less):
                out=[]
                for a,b in zip(poly,poly[1:]+poly[:1]):
                    ia=(a[axis]<=bound) if less else (a[axis]>=bound)
                    ib=(b[axis]<=bound) if less else (b[axis]>=bound)
                    if ia:out.append(a)
                    if ia!=ib:
                        t=(bound-a[axis])/(b[axis]-a[axis])
                        out.append([a[i]+t*(b[i]-a[i]) for i in range(2)])
                return out
            motion=[]
            corners=[math.atan2(z,x)%math.tau for x in [-.72,.72] for z in [-.62,.62]]
            angles=sorted(set([n*math.tau/64 for n in range(64)]+corners))+[math.tau]
            for low,high,rectangle in [(.002,.12,True),(.12,.24,False)]:
                for a,b in zip(angles,angles[1:]):
                    outer=lambda t:min(.72/max(abs(math.cos(t)),1e-9),.62/max(abs(math.sin(t)),1e-9)) if rectangle else .26
                    poly=[[r*math.cos(t),r*math.sin(t)] for r,t in [(.162,a),(outer(a),a),(outer(b),b),(.162,b)]]
                    pieces=[poly] if min(v[1] for v in poly)>=0 else [clip(poly,0,-.042,True),clip(poly,0,.042,False),clip(clip(clip(poly,0,-.042,False),0,.042,True),1,-.204,True)]
                    for section in pieces:
                        if len(section)<3:continue
                        motion.append(dict(type="convex",points=[[x,y,z] for y in [low,high] for x,z in section]))
            for shape in shapes[3:]:
                motion.append(dict(type="box",position=list(shape["center"]),size=[.10,.68,.10] if shape["shape"]=="plate" else list(shape["size"])))
        elif uid in ["head_left","head_right"]:
            sign=-1 if uid=="head_left" else 1
            shapes=[box([sign*.97,.90,.10],[.06,1.56,1.28]),box([sign*.75,.15,0],[.10,.06,1.0]),
                box([sign*.76,.89,.0],[.10,1.42,.16])]
            # Rear half-returns have complementary material at the centre seam.
            shapes += [box([sign*.50,.79,.87 if sign<0 else .79],[.94,1.30,.06]),
                box([sign*.015,.79,.85 if sign<0 else .77],[.03,1.30,.04])]
            # Open-bottom hook pockets surround the rear uprights, never fill them.
            for y in [.38,.70]:
                shapes += [box([sign*.64,y,.524],[.16,.06,.04]),box([sign*.735,y,.45],[.03,.06,.18])]
            for z in [-.45,.45]:
                shapes += [box([sign*.82,1.65,z],[.20,.06,.18]),box([sign*.82,1.74,z],[.06,.12,.06])]
            for y in [.40,.78]:shapes.append(tube([sign*.66,y,-.512],.022,.0065,.016,[0,0,1]))
            for z in [-.55,.77]:shapes.append(tube([sign*.66,1.62,z],.025,.0065,.052 if z>0 else .06,[0,0,1]))
            motion=proxies(shapes)
            motion[1]["position"][1]+=.001;motion[1]["size"][1]-=.002
        elif uid=="head_top":
            # Roof underside 17.22 throughout X±.60; downstanding ears outside.
            shapes=perforated([0,1.91,.10],[1.84,1.60,.18],[[x,-.65,.14,.30] for x in [-.20,.20]],"roof")
            for a,b in [(-.92,-.27),(-.13,.13),(.27,.92)]:shapes.append(box([(a+b)/2,1.85,-.68],[b-a,.06,.04]))
            motion=proxies(shapes)
            for x in [-.66,.66]:
                for z in [-.64,.84]:shapes.append(dict(shape="plate",center=[x,1.62,z],size=[.10,.08,.12],axis=[0,0,1],holes=[[0,0,.0065]]))
            for shape in shapes[-4:]:motion.append(dict(type="box",position=list(shape["center"]),size=[.10,.12,.08]))
            for x in [-.82,.82]:
                for z in [-.45,.45]:
                    shapes.append(dict(shape="plate",center=[x,1.75,z],size=[.20,.14,.18],rect_holes=[[0,0,.064,.064]]))
                    for at,size in [([x-.066,1.751,z],[.068,.138,.18]),([x+.066,1.751,z],[.068,.138,.18]),
                        ([x,1.751,z-.061],[.064,.138,.058]),([x,1.751,z+.061],[.064,.138,.058])]:
                        motion+=proxies([box(at,size)])
            for x,width,depth in [(-.20,.04,.05),(.20,.06,.04)]:
                key=box([x,1.88,-.52],[width,.12,depth]);shapes.append(key);motion+=proxies([key])
                boss=tube([x,1.88,-.57],.012,.0065,.06,[0,0,1]);shapes.append(boss);motion+=proxies([boss])
                ledge=box([x,1.81,-.52],[.20,.02,.08]);shapes.append(ledge);motion+=proxies([ledge])
        else:
            shapes=crown_shapes();motion=proxies(shapes)
            # The actual foot bears at Z17.22; only moving contact proxies use
            # the established 2 mm tolerance around the 1 mm sweep margin.
            for shape in motion:
                if shape["position"][1]==1.93:
                    shape["position"][1]+=.001;shape["size"][1]-=.002
        pads,normals,_=rig(uid)
        for p,n in zip(pads,normals):
            size=[.12,.02,.12] if n[1] else [.12,.12,.02]
            # Faces (rather than centres) coincide with the attachment points.
            at=[p[i]-n[i]*.01 for i in range(3)]
            shapes.append(box(at,size));motion+=proxies([shapes[-1]])
        context="HD-"+uid.upper()+"__001";source(context,[0,0,0],shapes,motion)
        definitions[uid]=dict(title="Prepared "+title.lower(),carry_class="equipment",bounds=[2,2,1.8],work_locations=["support","parent"],interaction="components",
            context_sources=[context],slots={},supplied_milestones=["prepared"],milestones=dict(prepared=[]),
            manual=[dict(title=title+" preparation supplied",view="overview",slots=[],body="Upright structural frames, locating tabs and magnetic pads are prepared. The chest manual owns installation and external hardware.")])
        seat="HD-"+uid.upper()+"-SEAT__001";source(seat,[0,4.10,0],[box([0,0,0],[.01,.01,.01])])
        if uid=="head_crown":hand_pieces(trial,chest,kinds,diagram,source,page)
        requires=(["left_pauldron/front","left_pauldron/rear","right_pauldron/front","right_pauldron/rear"] if uid=="head_baseplate" else connected if uid in ["head_left","head_right"] else chest["milestones"]["head_mask_retained"] if uid=="head_crown" else retained["head_left"]+retained["head_right"])
        slots[uid]=dict(assembly=uid,milestone="prepared",requires=list(requires),pose_source=seat,label=title,support_required=True,source_supports=["m2_service_crane"],undo_requires_support="m2_service_crane",secured_by=[],access_policy="mounted")
        page(title+": deliver", "Fit matching "+title.lower()+" upright inserts on the empty lowered bulky fixture. Use "+title+" to fixture to collect the passive-store piece, retain on the saddles, release and park. Select "+title+"; attach every magnetic end individually. Up tensions the rig before clamps open. Lift until the lowest load is Y19, cross to X13 at Z13, then to Z26 with front wings closed. Down aligns the keyed front and lowers "+str(int((.24 if uid=="head_baseplate" else .18 if uid=="head_crown" else .22)*100))+" cm onto the seat. Keep the rig attached. "+("The underside starts at robot Z15.64: 6 cm to pilot entry, then 18 cm to the flange; the front key rejects reversed yaw." if uid=="head_baseplate" else "After mask retention, the final crown lowers 18 cm: 6 cm clear lead and 12 cm onto the two unequal keyed prongs. Keep both front-facing ends attached." if uid=="head_crown" else "The side pockets/hooks and roof ledges remain open to vertical entry; either handed side may be fitted first."),[uid])
        hardware=[]
        if uid=="head_baseplate":
            for n,(x,y) in enumerate([(x,y) for x in [-.27,.27] for y in [-.27,.27]],1):
                washer=item("hd-w24",f"HD-W24__{n:03}",point(x,y,15.522),[tube([0,0,0],.025,.0125,.004)],[uid]);hardware.append(washer)
                hardware.append(item("hd-m24-160",f"HD-M24160__{n:03}",point(x,y,15.526),[tube([0,-.08,0],.012,0,.16),tube([0,.016,0],.021,0,.032)],[washer]))
        else:
            positions=([(x,.66,17.28) for x in [-.20,.20]] if uid=="head_crown" else [( -.66 if uid=="head_left" else .66,.52,z) for z in [15.80,16.18]] if uid!="head_top" else [(x,y,17.02) for x in [-.66,.66] for y in [.68,-.90]])
            kind="hd-m12-160" if uid=="head_top"  else "hd-m12-100";length=.16 if uid=="head_top" else .10
            start=5 if uid=="head_crown" else 1 if uid!="head_right" else 3
            for n,(x,y,z) in enumerate(positions,start):
                direction=1 if y>0 else -1
                hardware.append(item(kind,f"{kinds[kind]['family']}__{n:03}",point(x,y,z),
                    [tube([0,0,direction*length/2],.006,0,length,[0,0,1]),tube([0,0,-direction*.006],.010,0,.012,[0,0,1])],[uid]))
        retained[uid]=[uid]+hardware;slots[uid]["secured_by"]=hardware.copy()
        chest["milestones"][uid+"_retained"]=retained[uid]
        retain_body=("Fit four HD-W24 4 mm washers and four HD-M24160 bolts down into the torso's captive flange threads. Work from the open front before shells close access; the rear pair uses the specified deeper tool lane." if uid=="head_baseplate" else
            "Fit both HD-M12100 M12 × 100 front bolts rearward through the crown feet into the independent keyed root bosses. Only after both bolts are complete may the two front-facing magnetic ends be released and stowed." if uid=="head_crown" else
            "Fit four HD-M12160 bolts horizontally through the exposed roof-ear recesses into captive side-frame threads. Rear bolts enter forward from the rear flanks; front bolts enter rearward from the front landing." if uid=="head_top" else
            "Fit both HD-M12100 bolts rearward through the exposed side-shell recesses into captive upright threads.")
        page(title+": retain",retain_body+" Keep all ends attached until retention is complete; reacquire every end before a local bolt correction.",hardware)
        if uid=="head_baseplate":
            loom=item("hd-loom","HD-LOOM__001",point(.10,.25,15.69),[box([0,0,0],[.06,.06,.06]),tube([.47,.32,0],.016,0,.64) ],hardware.copy())
            connected=retained[uid]+[loom];chest["milestones"]["head_baseplate_connected"]=connected.copy()
            page("Head baseplate: connect loom","After all four neck bolt/washer pairs, plug the keyed central power/data loom and bond at the exposed front disconnects. Clip strain relief up the right portal, keeping bolt lanes and the future sensor slide clear. Then release and stow both upward magnetic ends from the open front before either side shell.",[loom])
        receiver_requires=(["chest:head_mask_retained"] if uid=="head_crown" else ["chest:left_pauldron_closed","chest:right_pauldron_closed","chest:backpack_connected"] if uid=="head_baseplate" else ["chest:head_baseplate_connected"] if uid!="head_top" else ["chest:head_left_retained","chest:head_right_retained"])
        clear_zones=["head_top_rig"] if uid=="head_crown" else [] if uid=="head_baseplate" else ["head_baseplate_rig"] if uid!="head_top" else ["head_left_rig","head_right_rig"]
        trial["equipment"]["receivers"][uid+"_receiver"]=dict(title=title,uid=uid,owner="chest",slot=uid,seat=pose([0,4.10,0]),crane_task=uid,
            keyed=uid in ["head_baseplate","head_crown"],requires=receiver_requires,clear_zones=clear_zones,rig_zone=uid+"_rig",retention_slots=hardware+([loom] if uid=="head_baseplate" else []),
            closure_slots=(["head_left","head_right"] if uid=="head_baseplate" else ["head_top"] if uid!="head_top" else []),rig=dict(normals=normals))
        trial["m3"]["security_slots"][uid]=retained[uid];trial["m3"]["controlled_mount_slots"].append("chest."+uid)
        trial["parents"].append(dict(id=uid,definition=uid,label=title,location="support:"+uid+"_store",home=store))
        trial["supports"][uid+"_store"]=dict(assemblies=[uid],assembly_ids=[uid])
        for support in ["m2_service_crane","bulky_fixture"]:
            for key in ["assemblies","assembly_ids"]:trial["supports"][support][key].append(uid)
    chest["milestones"]["head_complete"]=chest["milestones"]["head_mask_retained"]+chest["milestones"]["head_crown_retained"]
    trial["m3"]["playable_slots"]["chest"]=list(slots)
    return definitions


def hand_pieces(trial,chest,kinds,diagram,source,page):
    """Ordinary items share staged receivers; the model slot is their local catch."""
    slots=chest["slots"];sources=trial["sources"]
    for key,family,title,carry in [
        ("hd-sensors","HD-SENSORS","Prepared two-camera / range-sensor carrier","two_hand"),
        ("hd-faceplate","HD-FACE","Front faceplate","two_hand"),
        ("hd-mask","HD-MASK","Samurai mask","two_hand"),
        ("hd-m8","HD-M8","Captive M8 carrier bolt","pocket"),
        ("hd-sensor-loom","HD-SERVICE","Keyed sensor power/data plug and service-loop clip","pocket"),
        ("hd-m10-80","HD-M10080","M10 × 80 faceplate bolt","pocket"),
        ("hd-m10-160","HD-M10160","M10 × 160 mask bolt","pocket")]:
        kinds[key]=dict(family=family,variant=key,title=family+" · "+title,short_title=title,carry_class=carry)
    def add(kind,uid,at,shapes,requires,sid=None,captive=False):
        source(uid,[at[0],round(at[1]+4.10,6),at[2]],shapes)
        support="captive_"+uid.lower()
        trial["parts"].append(dict(instance_id=uid,source_id=uid,part_id=kinds[kind]["family"],kind=kind,
            location="support:"+support if captive else "bin"))
        sid=sid or uid.lower().replace("__","/")
        slots[sid]=dict(accepts=kind,pose_source=uid,requires=list(requires),label=kinds[kind]["title"],access_policy="mounted")
        if captive:
            trial["supports"][support]=dict(parts=[kind],item_ids=[uid])
            slots[sid].update(support_required=True,source_supports=[support])
        if kinds[kind]["carry_class"]=="two_hand":
            slots[sid]["undo_to"]="hands";kinds[kind]["collision_shapes"]=proxies(shapes)
        return sid
    def bolt(kind,uid,at,length,requires,captive=False):
        return add(kind,uid,point(*at),[tube([0,0,length/2],.004 if captive else .005,0,length,[0,0,1]),
            tube([0,0,.004 if kind=="hd-m10-80" else -.006],.007 if captive else .009,0,.012,[0,0,1])],requires,captive=captive)
    # Identical camera bodies/lenses and two M6 screws per supplied module.
    # The compact .32 m-deep carrier fits inside the specified .42 m insertion envelope.
    sensor=perforated([0,1.42,-.20],[1.02,.64,.04],[[x,z-16.82,.04,.05] for x in [-.49,.49] for z in [16.52,17.08]])
    sensor.append(box([0,1.09,-.20],[.90,.02,.04]))
    for x,z,w,h in [(-.27,16.66,.18,.14),(.27,16.66,.18,.14),(0,17.02,.14,.14)]:
        sensor += [box(point(x,.33,z),[w,h,.22]),tube(point(x,.49,z),min(w,h)*.32,0,.02,[0,0,1])]
        for sign in [-1,1]:sensor.append(tube(point(x+sign*(w/2-.018),.46,z-.045),.005,0,.012,[0,0,1]))
    for x,width in [(-.52,.02),(.515,.03)]:sensor.append(box([x,1.09,-.28],[width,.02,.16]))
    for x in [-.49,.49]:
        for z in [16.52,17.08]:
            sensor += [tube(point(x,.49,z),.018,.0045,.02,[0,0,1]),box(point(x,.35,z+.05),[.03,.015,.30]),box(point(x,.49,z+.034),[.03,.035,.02])]
    ready=chest["milestones"]["head_top_retained"]
    sid=add("hd-sensors","HD-SENSORS__001",[0,0,0],sensor,ready,"head_sensors")
    page("Sensor carrier: slide onto guides","Bench preparation is supplied: two interchangeable cameras and one distinct range sensor, two M6 screws each, wired on HD-SENSORS. Carry with two hands; use one elevator shelf trip with the padded grips. With structural top retained and every end stowed, approach 1 m forward, then slide straight rearward through the open front. The unequal guide shoes reject reversed orientation; captured rails and the rear stop support the seated carrier.",[sid])
    screws=[bolt("hd-m8",f"HD-M8__{n:03}",(x,.50,z),.04,[sid],True)
        for n,(x,z) in enumerate([(x,z) for x in [-.49,.49] for z in [16.52,17.08]],1)]
    page("Sensor carrier: retain","Tighten the four captive M8 carrier bolts at their front heads after the rails capture the carrier. The two-camera and range-sensor preparation screws are already supplied; no loose module stock is required.",screws)
    service=add("hd-sensor-loom","HD-SERVICE__001",point(.43,.57,16.46),
        [box([0,0,0],[.05,.06,.04]),box([.05,0,.07],[.025,.10,.12])],screws)
    page("Sensor carrier: connect and check","Plug the single keyed power/data connection near the lower right front. Clip the prepared short service loop inside the right portal, clear of the guides and all three optical apertures. Check all three modules before closing the faceplate.",[service])
    chest["milestones"]["head_sensors_retained"]=[sid]+screws
    chest["milestones"]["head_sensors_connected"]=[sid]+screws+[service]
    trial["equipment"]["receivers"]["head_sensors_receiver"]=dict(title="Sensor carrier",uid="HD-SENSORS__001",item=True,
        owner="chest",slot=sid,seat=pose([0,4.10,0]),requires=["chest:head_top_retained"],
        clear_zones=["head_top_rig"],retention_slots=screws+[service],captive_slots=screws,
        closure_slots=["head_faceplate"],keyed=True,approach_offsets=[[0,0,-1],[0,0,0]])
    # Guide lips stay outside X±.53. Four bolt ears and a rear stop belong to the frame.
    base=sources["HD-HEAD_BASEPLATE__001"]
    mounts=[]
    for x in [-.55,.55]:
        mounts += [box([math.copysign(.545,x),1.065,-.39],[.05,.03,.58]),box([math.copysign(.545,x),1.125,-.39],[.05,.03,.58])]
        for z in [16.52,17.08]:mounts.append(tube(point(math.copysign(.49,x),.44,z),.012,.0045,.06,[0,0,1]))
    # The wider right shoe fits its wider channel; reversed shoes foul the left key.
    mounts += [box([-.50,1.0875,-.39],[.01,.015,.58]),box([.485,1.0875,-.39],[.02,.015,.58])]
    mounts.append(box([0,1.41,-.15],[1.0,.66,.04]))
    # Ledges, separate lower mask hooks, and independent bolt bosses.
    for x in [-.55,.55]:
        mounts.append(box(point(x,.68,16.11),[.12,.04,.12]))
        for z in [16.20,17.12]:mounts.append(tube(point(x,.645,z),.008,.0055,.05,[0,0,1]))
    for x in [-.68,.68]:
        mounts += [box(point(x,.74,16.49),[.04,.02,.08]),box(point(x,.77,16.52),[.016,.04,.02])]
    for x in [-.56,.56]:mounts.append(tube(point(x,.74,15.98),.024,.0055,.04,[0,0,1]))
    base["primitives"]+=mounts;base["motion_shapes"]+=proxies(mounts)
    holes=[[-.27,16.66-16.655,.36,.18],[.27,16.66-16.655,.36,.18],[0,17.02-16.655,.24,.17]]
    holes += [[x,z-16.655,.052,.052] for x in [-.55,.55] for z in [16.20,17.12]]
    holes += [[x,16.53-16.655,.13,.18] for x in [-.535,.535]]
    holes += [[x,17.02-16.655,.10,.16] for x in [-.65,.65]]
    face=perforated(point(0,.68,16.655),[1.30,1.05,.08],holes)
    face_sid=add("hd-faceplate","HD-FACE__001",[0,0,0],face,chest["milestones"]["head_sensors_connected"],"head_faceplate")
    page("Front faceplate: seat","Carry HD-FACE with both hands on the elevator shelf. After all four carrier bolts and its keyed power/data check, approach 18 cm forward and translate rearward onto the two lower support ledges and side-frame locators. The ledges support fastening; the camera and range openings remain clear.",[face_sid])
    face_bolts=[bolt("hd-m10-80",f"HD-M10080__{n:03}",(x,.73,z),.08,[face_sid]) for n,(x,z) in enumerate([(x,z) for x in [-.55,.55] for z in [16.20,17.12]],1)]
    page("Front faceplate: retain","Fit all four HD-M10080 M10 × 80 front bolts rearward into the independent frame bosses. All four are required before fitting the mask; support ledges alone do not retain the faceplate.",face_bolts)
    chest["milestones"]["head_faceplate_retained"]=[face_sid]+face_bolts
    trial["equipment"]["receivers"]["head_faceplate_receiver"]=dict(title="Front faceplate",uid="HD-FACE__001",item=True,owner="chest",slot=face_sid,seat=pose([0,4.10,0]),
        requires=["chest:head_sensors_connected"],retention_slots=face_bolts,closure_slots=["head_mask"],approach_offsets=[[0,0,-.18],[0,0,0]])
    mask=perforated(point(0,.84,16.34),[1.40,1.16,.08],[[x,.32,.36,.18] for x in [-.27,.27]]+[[x,-.36,.012,.012] for x in [-.56,.56]])
    mask+=perforated(point(0,.79,16.34),[1.40,1.16,.02],[[x,.32,.36,.18] for x in [-.27,.27]]+[[x,-.36,.012,.012] for x in [-.56,.56]]+[[x,.125,.05,.21] for x in [-.68,.68]])
    mask+=perforated(point(0,.89,16.34),[1.40,1.16,.02],[[x,.32,.36,.18] for x in [-.27,.27]]+[[x,-.36,.024,.024] for x in [-.56,.56]])
    # Cheek reliefs leave both optical corridors; raised central nose stays between them.
    mask.append(box(point(0,.88,16.63),[.12,.40,.04]))
    for x in [-.68,.68]:
        mask += [box(point(x-.017,.74,16.53),[.006,.06,.08]),box(point(x+.017,.74,16.53),[.006,.06,.08]),box(point(x,.75,16.545),[.04,.01,.10])]
    mask_sid=add("hd-mask","HD-MASK__001",[0,0,0],mask,chest["milestones"]["head_faceplate_retained"],"head_mask")
    page("Samurai mask: hook","Carry HD-MASK on the enlarged shared shelf with two hands. With the faceplate fully retained, approach 16 cm forward and 10 cm high. Translate rearward, then lower 10 cm onto the two independent hooks outside the faceplate edges. Once hooked the mask is hands-free, ready for its uplift bolts.",[mask_sid])
    mask_bolts=[bolt("hd-m10-160",f"HD-M10160__{n:03}",(x,.88,15.98),.16,[mask_sid]) for n,x in enumerate([-.56,.56],1)]
    page("Samurai mask: retain","Fit both HD-M10160 M10 × 160 front bolts rearward into the lower portal bosses. These prevent uplift; hooks alone are temporary support. For a local correction before the crown, undo both bolts, lift the mask clear into free hands, then refit that same mask and both bolts.",mask_bolts)
    chest["milestones"]["head_mask_retained"]=[mask_sid]+mask_bolts
    trial["equipment"]["receivers"]["head_mask_receiver"]=dict(title="Samurai mask",uid="HD-MASK__001",item=True,owner="chest",slot=mask_sid,seat=pose([0,4.10,0]),
        requires=["chest:head_faceplate_retained"],retention_slots=mask_bolts,closure_slots=["head_crown"],seated_state="hooked",
        approach_offsets=[[0,.10,-.16],[0,.10,0],[0,0,0]])
    # The structural roof owns the downstream front closure, not a special controller.
    trial["equipment"]["receivers"]["head_top_receiver"]["closure_slots"]=["head_sensors"]
    for support in trial["supports"]:
        if support.startswith(("left_shelf_","right_shelf_")):trial["supports"][support]["parts"] += ["hd-sensors","hd-faceplate","hd-mask"]


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("--check",action="store_true");args=parser.parse_args()
    here=Path(__file__).resolve().parent
    for script in ["author_workshop_blockout.py","author_leg_prototype.py"]:
        subprocess.run([sys.executable,str(here/script)]+(["--check"] if args.check else []),check=True)
