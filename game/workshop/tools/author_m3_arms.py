"""Prepared M3 arms: separate source pieces, restrained transport geometry.

Local X=f, Y=e, Z=t. Left source geometry mirrors X; its delivery uses the
opposite yaw and splay, preserving the actual handed B eyes. Internal arm
construction remains supplied. Masses are explicit blockout mass allocations,
not material/strength certification; they supply a reproducible rig trim check.
"""
import math


def extend(trial, layout, chest):
    definitions = {}
    for side in ("left", "right"):
        prefix = "AL" if side == "left" else "AR"
        mirror = -1 if side == "left" else 1
        context = []

        def box(at, size):
            return dict(shape="box", center=at, size=size)

        def tube(at, radius, inner, length, axis):
            return dict(shape="tube", center=at, outer=radius, inner=inner,
                        length=length, axis=axis)

        def source(name, shapes, mass, center):
            uid = prefix + "-" + name + "__001"
            motion = []
            for shape in shapes:
                shape["center"][0] *= mirror
                if shape["shape"] == "box":
                    motion.append(dict(type="box", position=shape["center"], size=shape["size"]))
                elif shape["shape"] == "sphere":
                    motion.append(dict(type="sphere", position=shape["center"], radius=shape["radius"]))
                else:
                    axis = shape["axis"]
                    motion.append(dict(type="cylinder", position=shape["center"], radius=shape["outer"],
                                       height=shape["length"], rotation_degrees=[90, 0, 0] if axis == [0, 0, 1] else [0, 0, -90]))
            trial["sources"][uid] = dict(family=prefix+"-"+name, position=[0, 0, 0],
                rotation_degrees=[0, 0, 0], primitives=shapes, motion_shapes=motion,
                mass_kg=mass, mass_center=[mirror*center[0], center[1], center[2]])
            context.append(uid)

        source("BALL-BEAM", [dict(shape="sphere", center=[0, 0, 0], radius=.34),
            tube([0, 0, .65], .11, 0, .8, [0, 0, 1]),
            box([0, 0, 1.325], [.23, .23, .55]), box([0, 0, 2.20], [.30, .30, 1.20])], 620, [0, 0, 1.55])
        # Actual skewed moving eyes, with pin bores through f. The torso owns A.
        for n, theta in enumerate((100, 180, 260), 1):
            a = math.radians(theta+45)
            e, f = .34*math.cos(a), .34*math.sin(a)
            source("B-EYE-"+str(n), [tube([f, e, 1.5], .06, .0205, .074, "x"),
                box([f/2, e/2, 1.62], [abs(f)+.08, abs(e)+.08, .10]),
                box([f,e,1.555],[.06,.07,.04])], 9, [f, e, 1.5])
        source("UPPER-SHELL", [box([f, 0, 2.14], [.08, .90, 1.08]) for f in [-.46, .46]]+
            [box([0, e, 2.14], [.84, .08, 1.08]) for e in [-.41, .41]], 180, [0, 0, 2.14])
        source("ELBOW", [tube([0, 0, 3], .32, 0, .70, "x"),
            box([-.39, 0, 2.88], [.08, .64, .50]), box([.39, 0, 2.88], [.08, .64, .50])], 210, [0, 0, 3])
        source("FOREARM-BEAM", [box([0, 0, 4.20], [.32, .32, 2.60])], 390, [0, 0, 4.20])
        shell=[box([0, .51, 4.25], [.94, .08, 2.1])]
        for start, end in [(3.20,3.91),(4.19,5.30)]:
            shell += [box([f, 0, (start+end)/2], [.08, 1.10, end-start]) for f in [-.51,.51]]
            shell.append(box([0, -.51, (start+end)/2], [.94, .08, end-start]))
        shell += [box([f, .10, 4.05], [.08, .90, .28]) for f in [-.51,.51]]
        source("FOREARM-SHELL", shell, 200, [0, 0, 4.25])
        source("WRIST", [tube([0, 0, 5.53], .375, 0, .20, [0, 0, 1]),
            dict(shape="sphere", center=[0, 0, 5.60], radius=.23)], 90, [0, 0, 5.53])
        source("PALM", [box([0, 0, 6.03], [.90, .45, .80])], 120, [0, 0, 6.03])
        for n, (f, length) in enumerate([(-.33, .83), (-.11, 1.0), (.11, .96), (.33, .78)], 1):
            source("DIGIT-"+str(n), [box([f, 0, 6.43+length/2], [.18, .30, length])], 15, [f, 0, 6.43+length/2])
        source("THUMB", [box([.61, -.05, 6.16], [.28, .32, .70]),
            box([.46,-.05,6.16],[.12,.16,.20])], 25, [.61, -.05, 6.16])
        # Restraints attach to beams/chassis and hold the supplied elbow/wrist/
        # digits. No crane force depends on armor or actuator rods.
        source("JOINT-RESTRAINTS", [box([f, 0, t], [.06, .12, length])
            for f, t, length in [(-.46, 3, .9), (.46, 3, .9), (-.40, 5.6, .55), (.40, 5.6, .55)]], 24, [0, 0, 3.9])
        source("DIGIT-CRADLE", [box([0, -.25, 6.82], [.90, .10, 1.26]),
            box([0,-.175,6.75],[.86,.05,.12]),box([0,.18,6.75],[.98,.06,.12]),
            box([-.47,-.05,6.82],[.06,.44,1.26]),box([.47,-.05,7.0],[.06,.44,.90]),
            box([.595,.14,6.16],[.31,.06,.16]),box([.595,-.24,6.16],[.31,.06,.16]),
            box([.43,-.05,6.16],[.04,.44,.16])], 15, [0, -.23, 6.82])
        for n, t in enumerate([1.35, 4.05, 6.05], 1):
            source("SUPPORT-"+str(n), [box([0, -.52, t], [.70, .06, .20]),
                box([0, -.32, t], [.20, .42, .16])], 12, [0, -.35, t])
        for n, t in enumerate([.75, 4.40], 1):
            source("LIFT-"+str(n), [box([0, .10, t], [1.32, .08, .08])]+
                [box([f, .10, t], [.04, .12, .12]) for f in [-.66, .66]], 18, [0, .10, t])
        # Torso-owned C bridge and open clevises are present during the actual
        # arm approach. Its central pin port is a true bore, not a solid hoop.
        radius=math.hypot(.48,.58)
        radial_end=[-.48*mirror*.43/radius,-.58*.43/radius,.64]
        radial_start=[-.48*mirror,-.58,.64]
        fixed = [box([-.48*mirror, -.58, .245], [.08, .08, .79]),
                 box([-.48*mirror, -.54, -.15], [.08, .16, .08]),
                 tube([(a+b)/2 for a,b in zip(radial_start,radial_end)],.03,0,radius-.43,
                      [.48*mirror/radius,.58/radius,0])]
        for start, end in [(20, 75), (105, 160)]:
            fixed.append(dict(shape="ring_plate", center=[0, 0, .64], outer=.46, inner=.40,
                length=.06, axis=[0, 0, 1], start_degrees=start, end_degrees=end))
        for start,end in [(10,25),(155,170)]:
            fixed.append(dict(shape="ring_plate", center=[0,0,.57],outer=.48,inner=.40,
                length=.03,axis=[0,0,1],start_degrees=start,end_degrees=end))
        for f in [-.10,.10]:
            fixed.append(dict(shape="plate", center=[f, -.49, .64], size=[.04, .18, .20],
                              axis="x", holes=[[-.03, 0, .04]]))
        for theta in (100, 180, 260):
            a=math.radians(theta);e=.46*math.cos(a);f=mirror*.46*math.sin(a)
            fixed.append(box([f,e,.555],[.24 if theta==180 else .14,.08,.03]))
            for delta in [-.055, .055]:
                fixed += [tube([f+delta, e, .64], .05, .0205, .03, "x"),
                          box([f+delta, e, .575], [.03, .08, .07])]
        root_id="CH-"+side.upper()+"-DRIVE-BRIDGE__001"
        trial["sources"][root_id]=dict(family="CH-DRIVE-BRIDGE", position=[(-1 if side=="left" else 1)*2.2, 3.1, 0],
            rotation_degrees=[75, -90 if side=="left" else 90, 0], primitives=fixed)
        chest["context_sources"].append(root_id)
        uid = side+"_arm"
        support = "arm_cassette" if side == "left" else "right_arm_store"
        at = layout["workshop"]["cassette"]["parked_shoulder"] if side == "left" else layout["workshop"]["arm_delivery"]["right_store_shoulder"]
        trial["parents"].append(dict(id=uid, definition=uid, label="Prepared "+side+" arm",
                                    location="support:"+support, home=at))
        trial["supports"][support] = dict(assemblies=[uid], assembly_ids=[uid])
        definitions[uid] = dict(title="Prepared "+side+" arm", carry_class="equipment",
            bounds=[1.5, 1.1, 7.79], work_locations=["support", "parent"], interaction="components",
            context_sources=context, slots={}, supplied_milestones=["prepared"], milestones={"prepared":[]},
            manual=[dict(title="Prepared "+side+" arm", view="overview", slots=[],
                body="The upper arm, restrained elbow, forearm, neutral wrist and retained hand are supplied together. The shared cassette supports three structural pads; four structural lifting faces carry the arm. Shoulder retention, drives, services and pauldron work belong to the chest manual.")])
    return definitions
