"""External shoulder stock and manuals. Sources use the arm's f/e/t frame.

The prepared arms stay distinct; the chest owns their mounting hardware. Ring
liners are stepped source approximations of the selected spherical clearance.
"""
import math


def extend(trial, chest, arms, kinds, diagram):
    slots = chest["slots"]
    crane, rail = "service_crane", "leg_rail"
    def operate(machine, command, task=None):
        record = dict(op="operate", machine=machine, command=command)
        if task is not None: record["task"] = task
        return record
    def crane_to(task, seat=None):
        steps = [operate(crane, "pickup", task), operate(crane, "down"), dict(op="connect", machine=crane),
                 operate(crane, "up"), operate(crane, "go:receiver", task)]
        if seat is None: steps.append(operate(crane, "down"))
        else: steps.append(dict(op="seat", slot=seat, via=dict(machine=crane, command="down")))
        return steps
    def park():
        return [dict(op="detach", machine=crane), operate(crane, "up"), operate(crane, "go:park")]
    def box(at, size): return dict(shape="box", center=at, size=size)
    def tube(at, outer, inner, length, axis="x"):
        return dict(shape="tube", center=at, outer=outer, inner=inner, length=length, axis=axis)
    def link(a, b, radius):
        d = [y-x for x,y in zip(a,b)]; length = math.sqrt(sum(x*x for x in d))
        return tube([(x+y)/2 for x,y in zip(a,b)], radius, 0, length, [x/length for x in d])
    for key, title, carry in [("ring-front","Front keyed ring half","hand"),("ring-rear","Rear relieved ring half","hand"),
            ("washer","M24 shoulder washer","pocket"),("bolt","M24 × 240 shoulder bolt","pocket"),
            ("brace-left","Left keyed neutral service brace","two_hand"),("brace-right","Right keyed neutral service brace","two_hand"),("pin","Ø40 shoulder pin","pocket"),
            ("keeper","Ø40 pin keeper","pocket"),("drive","Shoulder screw-drive cartridge","two_hand"),
            ("service","Isolated arm service harness","hand")]:
        kinds["sh-"+key]=dict(family="SH-"+key.upper(),variant="sh-"+key,title="SH-"+key.upper()+" · "+title,short_title=title,carry_class=carry)
    serial = {}
    for side, sign, prefix in [("left",-1,"AL"),("right",1,"AR")]:
        uid=side+"_arm"; root=uid+"/"; rotation=[75,sign*90,0]
        # Equivalent to Godot Basis.from_euler([75, ±90, 0]).
        def parent_point(p):
            f,e,t=p; s=math.sin(math.pi/12); c=math.cos(math.pi/12)
            return [sign*2.2+sign*(c*e+s*t),3.1+s*e-c*t,-sign*f]
        def source(source_uid, shapes, origin=(0,0,0)):
            for shape in shapes:shape["center"]=[a-b for a,b in zip(shape["center"],origin)]
            trial["sources"][source_uid]=dict(family=source_uid.split("__")[0],position=parent_point(origin),rotation_degrees=rotation,primitives=shapes)
        def part(name, key, shapes, requires, origin=(0,0,0), structural=True):
            serial[key]=serial.get(key,0)+1
            source_uid="SH-"+key.upper()+f"__{serial[key]:03}"
            source(source_uid,shapes,origin)
            sid=root+name
            trial["parts"].append(dict(instance_id=source_uid,source_id=source_uid,part_id=kinds["sh-"+key]["family"],kind="sh-"+key,location="bin"))
            slots[sid]=dict(accepts="sh-"+key,pose_source=source_uid,requires=list(requires),label=kinds["sh-"+key]["title"],access_policy="mounted")
            if structural:slots[sid]["undo_requires_support"]="crane_rigging"
            return sid
        seat="SH-"+side.upper()+"-SEAT__001"
        source(seat,[dict(shape="sphere",center=[0,0,0],radius=.34)])
        slots[uid]=dict(assembly=uid,milestone="prepared",requires=[],pose_source=seat,label="Prepared "+side+" arm",
            support_required=True,source_supports=["crane_rigging"],undo_requires_support="crane_rigging",access_policy="mounted")
        rings=[]
        for front in [True,False]:
            shapes=[]
            for layer in range(18):
                low=.08+layer*.01;high=low+.01
                # Native ring coordinates (f,-e), normal+t.
                start,end=(-90,90) if front==(sign>0) else (90,270)
                if not front and layer in [3,4]:start+=5;end-=5
                holes=[[sign*.405*math.sin(math.radians(a)),-.405*math.cos(math.radians(a)),.027 if low>=.20 else .0125]
                       for a in [45,135,225,315] if (math.sin(math.radians(a))>0)==front]
                shapes.append(dict(shape="ring_plate",center=[0,0,(low+high)/2],axis=[0,0,1],outer=.48,
                    inner=max(.24,math.sqrt(.345**2-low**2)),length=.01,start_degrees=start,end_degrees=end,holes=holes))
            if front:shapes += [box([0,e,.12],[.048,.026,.018]) for e in [-.45,.45]]
            rings.append(part("ring_"+("front" if front else "rear"),"ring-front" if front else "ring-rear",shapes,[uid],(0,0,.17)))
        retention=rings.copy()
        for n,theta in enumerate([45,135,225,315],1):
            a=math.radians(theta);f=sign*.405*math.sin(a);e=.405*math.cos(a)
            w=part("washer_"+str(n),"washer",[tube([f,e,.205],.024,.0128,.006,[0,0,1])],rings,(f,e,.205))
            b=part("bolt_"+str(n),"bolt",[tube([f,e,.088],.012,0,.24,[0,0,1]),tube([f,e,.220],.018,0,.024,[0,0,1])],[w],(f,e,.208))
            retention += [w,b]
        # Moving keys and fixed tabs belong to their actual prepared bodies.
        bridge=trial["sources"]["CH-"+side.upper()+"-DRIVE-BRIDGE__001"]["primitives"]
        beam=trial["sources"][prefix+"-BALL-BEAM__001"]
        brace=[];keys=[]
        for n,(theta,e,f) in enumerate([(130,.05,.25),(230,-.15,-.25)],1):
            a=math.radians(theta); tab=[sign*.43*math.sin(a),.43*math.cos(a),.80]
            key=[sign*f,e,1.05];keys.append(key)
            bridge.append(box([tab[0],tab[1],.72],[.08,.06,.16]))
            beam["primitives"] += [tube(key,.045,.0205,.074),link([0,0,1.14],[key[0],key[1],1.14],.025),box([key[0],key[1],1.105],[.06,.05,.04])]
            # Preserve the actual bore; transport convex profiles bound the eyes.
            beam["motion_shapes"] += [dict(type="box",position=key,size=[.074,.09,.09]),dict(type="box",position=[key[0]/2,key[1]/2,1.14],size=[abs(key[0])+.05,abs(key[1])+.05,.05]),dict(type="box",position=[key[0],key[1],1.105],size=[.06,.05,.04])]
            # Three faces capture the fixed tab without filling its material.
            brace += [box([tab[0]+d,tab[1],tab[2]],[.025,.10,.08]) for d in [-.055,.055]]
            brace += [box([tab[0],tab[1],tab[2]+.0525],[.085,.10,.025]),
                      link([tab[0],tab[1],.865],[key[0],tab[1],.865],.022),
                      link([key[0],tab[1],.865],[key[0],key[1],.865],.022),
                      link([key[0],key[1],.865],[key[0],key[1],.97],.022)]
            for delta in [-.055,.055]:brace.append(tube([key[0]+delta,key[1],key[2]],.045,.0205,.03))
            brace += [link([key[0]-.055,key[1],.97],[key[0]+.055,key[1],.97],.020),
                      link([key[0],key[1],.97],[key[0],.16,.97],.020)]
            brace += [box([key[0]+d,key[1],.995],[.03,.06,.06]) for d in [-.055,.055]]
        brace.append(link([keys[0][0],.16,.97],[keys[1][0],.16,.97],.025))
        br=part("brace","brace-"+side,brace,retention,(0,0,.85));bracing=[br]
        def pin_pair(name,eye,direction,head,requires):
            f,e,t=eye;h=f+direction*head
            p=part(name+"_pin","pin",[tube([h-direction*.11,e,t],.020,0,.22),tube([h,e,t],.032,0,.014)],requires,(h,e,t))
            k=part(name+"_keeper","keeper",[tube([h-direction*.205,e,t],.030,.0202,.008)],[p],(h-direction*.205,e,t))
            return [p,k]
        for n,key in enumerate(keys,1):bracing += pin_pair("brace_"+str(n),key,1 if key[0]>0 else -1,.10,[br])
        drives=[];drive_pages=[]
        for n,theta in enumerate([100,180,260],1):
            a=math.radians(theta);b=math.radians(theta+45)
            A=[sign*.46*math.sin(a),.46*math.cos(a),.64];B=[sign*.34*math.sin(b),.34*math.cos(b),1.5]
            d=[y-x for x,y in zip(A,B)]; length=math.sqrt(sum(x*x for x in d)); unit=[x/length for x in d]
            shapes=[tube(A,.05,.0205,.074),
                    link([x+.045*v for x,v in zip(A,unit)],[x+.15*v for x,v in zip(A,unit)],.018),
                    link([x+.15*v for x,v in zip(A,unit)],[x-.15*v for x,v in zip(B,unit)],.05),
                    link([x-.15*v for x,v in zip(B,unit)],[x-.09*v for x,v in zip(B,unit)],.018)]
            for delta in [-.055,.055]:shapes.append(tube([B[0]+delta,B[1],B[2]],.05,.0205,.03))
            shapes.append(link([B[0]-.055,B[1],B[2]-.09],[B[0]+.055,B[1],B[2]-.09],.025))
            shapes += [box([B[0]+d,B[1],B[2]-.06],[.03,.06,.08]) for d in [-.055,.055]]
            drive=part("drive_"+str(n),"drive",shapes,bracing,[(x+y)/2 for x,y in zip(A,B)])
            ids=[drive]+pin_pair("drive_"+str(n)+"_a",A,sign if theta==180 else (1 if A[0]>0 else -1),.10,[drive])
            ids+=pin_pair("drive_"+str(n)+"_b",B,1 if B[0]>0 else -1,.12,[drive]);drives+=ids;drive_pages.append(ids)
        # Isolated service couplings and a bounded protected-run source proxy.
        def channel(x,z):
            dx=x-2.2;dy=z-14.4;c=math.cos(math.pi/12);s=math.sin(math.pi/12)
            return [sign*.56,c*dx+s*dy,s*dx-c*dy]
        tail=[sign*.50,.26,1.10];bulk=channel(2.0,14.46);bulk[0]=sign*.50
        beam["primitives"] += [tube(tail,.038,.023,.08),link([0,0,1.24],[tail[0],tail[1],1.24],.018),link([tail[0],tail[1],1.24],tail,.018)]
        beam["motion_shapes"] += [dict(type="box",position=tail,size=[.08,.076,.076]),
            dict(type="box",position=[tail[0]/2,tail[1]/2,1.24],size=[abs(tail[0])+.036,abs(tail[1])+.036,.036]),
            dict(type="box",position=[tail[0],tail[1],1.17],size=[.036,.036,.176])]
        fixed="SH-"+side.upper()+"-SERVICE-PORT__001"
        source(fixed,[tube(bulk,.038,.023,.08),link(bulk,[sign*.40,-.15,-.08],.022)])
        chest["context_sources"].append(fixed)
        path=[bulk,[sign*.56,bulk[1],bulk[2]],channel(2.65,14.46),channel(2.72,13.45),[sign*.56,.26,1.10],tail]
        service=part("service","service",[link(a,b,.017) for a,b in zip(path,path[1:])]+[tube(p,.022,0,.08) for p in [bulk,tail]],retention+bracing+drives,tuple(path[1]),False)
        def page(title, goal, ids, objectives, note=None):
            record = dict(title=side.title()+" shoulder: "+title, goal=goal, slots=list(ids), objectives=objectives, view="components",
                diagram_views=[diagram(side.title()+" shoulder "+title,[slots[s]["pose_source"] for s in ids])])
            if note is not None: record["note"] = note
            return record
        if side=="left":
            chest["manual"].append(dict(title="Bring the arm rig to the Limb Bay", goal="Park the leg rig and crane the arm rig into the Limb Bay.",
                slots=[], objectives=[operate(rail,"table:park")]+crane_to("cassette")+park(), view="components"))
        else:
            chest["manual"].append(dict(title="Bring the right arm onto the arm rig", goal="Crane the right arm onto the arm rig.",
                slots=[], objectives=crane_to("right_arm_store")+park(), view="components"))
        chest["manual"] += [page("deliver the retained arm","Crane the "+side+" arm from the arm rig and seat its shoulder ball.",[uid],
                crane_to(uid, uid), dict(at=2, text="Keep all four connectors attached until the arm's services are connected.")),
            page("retain the ball","Clamp both ring halves around the shoulder ball.",retention,
                [dict(op="fit", slots=list(rings)), dict(op="fit", slots=list(retention[len(rings):]))],
                dict(at=0, text="Use a workshop-side rope from the left lift's ROPE ACCESS stop. The seam keys only fit one way round.")),
            page("fit the neutral brace","Fit the shoulder brace that holds the arm straight.",bracing,
                [dict(op="fit", slots=[bracing[0]]), dict(op="fit", slots=list(bracing[1:]))])]
        for n,ids in enumerate(drive_pages,1):
            chest["manual"].append(page("drive "+str(n),"Fit drive "+str(n)+" between its clevis and eye, pinned at both ends.",ids,
                [dict(op="fit", slots=[ids[0]]), dict(op="fit", slots=list(ids[1:]))]))
        chest["manual"].append(page("connect services","Hand the arm's weight to the shoulder, plug in its services and release the crane.",[service],
            [operate(side+"_shoulder","check_brakes"), operate(side+"_shoulder","transfer_weight"), dict(op="fit", slots=[service])]+park(),
            dict(at=3, text="Leave the shoulder brace and the arm's joint restraints engaged.")))
        structure=[uid]+retention+bracing+drives
        chest["milestones"][uid+"_retained"]=structure
        chest["milestones"][uid+"_connected"]=structure+[service]
        trial["robot"]["security_slots"][uid]=structure
        trial["robot"]["controlled_mount_slots"].append("chest."+uid)
        trial["equipment"][side+"_shoulder"]=dict(uid=uid,owner="chest",slot=uid,side=sign,seat=parent_point([0,0,0]),rotation_degrees=rotation,
            structural_slots=structure,service_slots=[service])
        for name in ["crane_rigging"]:
            trial["supports"][name].setdefault("assemblies",[]).append(uid)
            trial["supports"][name].setdefault("assembly_ids",[]).append(uid)
    trial["robot"]["playable_slots"]["chest"]=list(slots)
