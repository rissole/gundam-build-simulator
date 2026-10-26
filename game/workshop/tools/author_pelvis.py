"""Prepared pelvis/waist geometry and its existing external handling interfaces.

The hip-centre origin and existing playable hip recipes remain authoritative.
Prepared internal members are fixed source context owned by this one assembly;
four gantry jaws and two captive neutral locks are equipment/control state.
"""

def extend(trial, pelvis, layout):
    source=trial["sources"]
    def box(at,size):return dict(shape="box",center=at,size=size)
    def tube(at,outer,inner,length,axis="y"):
        return dict(shape="tube",center=at,outer=outer,inner=inner,length=length,axis=axis)
    def add(uid,at,shapes):
        source[uid]=dict(family=uid.split("__")[0],position=at,rotation_degrees=[0,0,0],primitives=shapes)
        if uid not in trial["context_sources"]:trial["context_sources"].append(uid)

    add("PV-100__001",[0,.5,.65],[box([0,0,0],[2.7,.26,.30])])
    add("PV-C-PEDESTAL__001",[0,.85,.125],[box([0,0,0],[.48,.60,.75])])
    for index,side in enumerate([-1,1],1):
        a=[side*.95,.60,.65];b=[side*.42,1.15,-.25]
        axis=[b[i]-a[i] for i in range(3)]
        length=sum(v*v for v in axis)**.5
        add(f"PV-C-BRACE__{index:03}",[(a[i]+b[i])/2 for i in range(3)],
            [tube([0,0,0],.09,0,length,[v/length for v in axis])])
    add("PV-300__001",[0,1.30,0],[box([0,-.12,0],[1.46,.06,1.46]),
        tube([0,0,0],.70,.425,.18),box([.89,.015,0],[.32,.33,.32])])
    yoke=[box([x,1.50,0],[.16,.48,.42]) for x in [-.78,.78]]
    yoke += [tube([x,1.70,0],.13,.08,.12,"x") for x in [-.78,.78]]
    add("PV-310__001",[0,0,0],yoke)
    cradle=[]
    for x in [-.84,.84]:
        cradle += [box([x,2.06,0],[.28,.08,.96]),tube([x,1.70,0],.08,0,.26,"x"),box([x,1.87,0],[.12,.34,.35])]
        for z in [-.58,.58]:
            cradle += [tube([x,2.06,z],.14,.0185,.08),box([x,2.06,z+(.10 if z>0 else -.10)],[.28,.08,.08])]
    for z in [-.58,.58]:cradle.append(box([0,2.06,z],[1.40,.08,.28]))
    for x in [-.92,.92]:
        for z in [-.25,.25]:cradle.append(box([x,2.16,z],[.08,.12,.12]))
    add("PV-320__001",[0,0,0],cradle)
    for index,x in enumerate([-.66,.66],1):
        add(f"PV-330__{index:03}",[x,1.45,-.50],[tube([0,.13,0],.05,0,.26),tube([0,.34,-.01],.02,0,.25),
            tube([0,0,0],.055,.025,.08,"x"),tube([0,.47,-.02],.055,.025,.08,"x")])
    for index,(x,z) in enumerate([(x,z) for x in [-1.15,1.15] for z in [-.70,.70]],1):
        add(f"PV-C-LIFT__{index:03}",[x,.75,z],[tube([0,0,0],.11,.05,.08,"z"),
            box([0,-.16,0],[.14,.20,.12]),box([0,-.14,(.65-z)/2],[.14,.10,abs(.65-z)+.12])])
    # Replace the historical contextual M24 socket bolts with the specified
    # prepared socket saddle hardware. These are supplied, not new manual stock.
    trial["context_sources"]=[uid for uid in trial["context_sources"] if not uid.startswith("PV-C-H24090")]
    for index,(x,z) in enumerate([(s*1.10+d,.60) for s in [-1,1] for d in [-.15,.15]],1):
        add(f"PV-C-H36160__{index:03}",[x,.546,z],[tube([0,-.08,0],.018,0,.16),tube([0,.018,0],.029,0,.036),tube([0,-.003,0],.033,.019,.006)])
    pelvis["context_sources"]=list(trial["context_sources"])
    pelvis.update(carry_class="equipment",work_locations=["support"],bounds=[4.02,4.1,2.0])
    pelvis["manual"].insert(0,dict(title="Deliver the prepared hip assembly",view="components",slots=[],
        goal="Lock the waist straight, crane the hip assembly onto the gantry and close its jaws.",
        objectives=[
            dict(op="operate",machine="module_supports",command="insert_pins"),
            dict(op="operate",machine="service_crane",command="pickup",task="pelvis"),
            dict(op="operate",machine="service_crane",command="down"),
            dict(op="connect",machine="service_crane"),
            dict(op="operate",machine="service_crane",command="up"),
            dict(op="operate",machine="service_crane",command="go:receiver",task="pelvis"),
            dict(op="operate",machine="service_crane",command="down"),
            dict(op="operate",machine="module_supports",command="close_jaws"),
            dict(op="detach",machine="service_crane"),
            dict(op="operate",machine="service_crane",command="up"),
            dict(op="operate",machine="service_crane",command="go:park")]))
    for parent in trial["parents"]:
        if parent["id"]=="pelvis":parent.update(label="Prepared hip assembly",location="support:bulky_fixture",home=[3.25,1.2,13])
    for name in ["bulky_fixture","pelvis_gantry"]:trial["supports"][name]=dict(assemblies=["pelvis"],assembly_ids=["pelvis"])
    crane=trial["supports"]["crane_rigging"]
    crane["assemblies"].append("pelvis");crane["assembly_ids"].append("pelvis")
