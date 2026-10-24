"""Author the M3 workshop's shared spatial contract and derived solid groups.

Equipment and content consume leg-bay-m3-layout.json. The old leg author remains
responsible for structural recipes; this author owns the wider spatial blockout.
No player/access simulation or rendered verification is performed here.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

ASSETS = Path(__file__).resolve().parents[1] / "assets"
PATH = ASSETS / "leg-bay-m3-layout.json"


def pose(position, rotation=(0, 0, 0)):
    return dict(position=list(position), rotation_degrees=list(rotation))


def contract():
    data = dict(
        revision=1,
        shell=dict(center=[6, 0, 15], size=[40, 25, 48], wall=.3,
                   lowest_overhead=23.0),
        bays={
            "bulky": dict(bounds=[-2.25, 8.75, 6, 18], datum=[3.25, .85, 13]),
            "limb": dict(bounds=[10.5, 17.5, 7.8, 20.8], datum=[14, 1.85, 14.5]),
            "leg_parking": dict(bounds=[20, 24, 8, 20.5], datum=[22, 1.85, 14.5]),
            "arm_parking": dict(bounds=[11.8, 16.2, -7, 2.5], datum=[14, 1.55, -6.3]),
            "foot": dict(bounds=[-11.5, -3.5, 5, 16], datum=[-7, 1.2, 8]),
            "stock": dict(bounds=[-11.5, 8.75, -5, 2], height_limit=3.2),
            "structural_stock": dict(bounds=[-11.25, -2.25, 17.5, 23.5], datum=[-6.75,1.85,18.5]),
        },
        robot=dict(origin=[13, 1.4, 26], hips=[11.9, 14.1], hip_y=10.6,
                   chest_seat=[13, 12.70, 26], core_axis=[13, 13.35, 26],
                   shoulders=[[10.8, 15.8, 26], [15.2, 15.8, 26]],
                   head_base=[13, 16.8, 26]),
        rail=dict(station_x=14, lanes={"left":11.9, "right":14.1, "parking":22},
                  home_z=14.5, bay_z=26, pivot=5.1, base_y=.5, lying_lift=1.35,
                  delivery_lower=.30, lower_during_turn=.25, dock_rise=1.2, gauge=1.24, table_bounds=[10.5,23.4,13.25,15.75],
                  roll_axis_y=3.1, roll_stops=[0,90,180,270],
                  corridor=[10.5,15.5,20.5,30.6],
                  panels=[[8.78,0,14.5],[8.5,0,24]],
                  holder=dict(spine=[0,4.45,1.45], spine_size=[.24,3.6,.20],
                              contacts_y=[2.8,6.1], contact_x=.80,
                              outer_x=1.05, jaw_stroke=.15, lower=.30,
                              withdrawal=1.40, outboard=2.0, compact_width=2.0,
                              empty_root_base=1.1, empty_root_lift=2.25,
                              cross_slide_max_y=1.0,
                              bogie=dict(y=.23,size=[1.5,.36,1.65]),
                              wheel=dict(y=.11,z=.55,size=[.16,.20,.28]),
                              crossbar=dict(z=1.42,size=[1.94,.22,.16]),
                              yoke=dict(x=[.975,.92],rear=1.5,length=[1.55,.30],section=[.15,.26]),
                              finger=dict(x=[.84,.90],z=[0,1.35],size=[.08,.24,.20]),
                              bolster=dict(spread_fraction=.25,lift=2.8,x=[.17,.90],
                                  pad=[-.035,.43],pad_size=[.18,.07,.66],
                                  stop=[.07,.78],stop_size=[.18,.14,.04],
                                  outrigger_x=.96,outrigger_z=1.44,section=.12,
                                  crossarm=[-.14,1.13,.70],link=[-.14,.60,1.08]),
                              slides=dict(y=.25,width=.25,height=.15),
                              mast=dict(width=.20,min_height=.05),
                              bearing=dict(z=1.45,size=[.40,.30,.30]))),
        foot_dispatch=dict(sole_source=pose([14,1.2,7]),
                           sole_route=[pose([14,1.2,7]),pose([14,1.85,7]),
                                       pose([14,1.85,9.4]),pose([14,1.85,9.4],[90,0,0])]),
        foot_storage={"foot":pose([-7,2,7.3]),"right_foot":pose([-7,2,12.3])},
        chest_storage=pose([-7,.85,27.5]),
        core_storage=pose([-7,1.3,31.3]),
        backpack_storage=pose([-7,.85,35]),
        backpack=dict(hinge_seat=[13,15.5,27.2],closed_rotation=[90,0,0],
                      route_positions=[[3.25,.85,13],[3.25,5.5,13],[23.7,5.5,13],[23.7,5.5,31.8],
                                       [24,5.5,31.8],[24,18,31.8],[13,18,31.8],[13,15.7,31.8],[13,15.7,27.2],[13,15.5,27.2]]),
        cassette=dict(size=[2,.2,9], source_shoulder=[14,1.55,9.9],
                      parked_shoulder=[14,1.55,-6.3], saddles=[1.35,4.05,6.05],
                      transfer_bottom=4.8, folded_clamp_top=1.7),
        arm_delivery=dict(source_shoulder=[14,1.55,9.9],upend_y=9.6,forward_z=19.5,
                          approach_distance=1.13,head_height=1.35,rig_overhead=23.0,
                          right_store_shoulder=[21,1.55,-6.3]),
        bulky_fixture=dict(datum=[3.25,.85,13], pelvis_datum=[3.25,1.2,13],
                           chest_service=pose([3.25,1.3,14.6],[60,0,0]),
                           chest_tilt_limit=60, cockpit_approach=2.4,height_travel=.45,
                           templates={"pelvis":pose([3.25,1.2,13]),"chest":pose([3.25,.85,13]),"core":pose([3.25,1.3,13]),"backpack":pose([3.25,.85,13])},
                           pelvis_envelope=[[-2.01,-.71,-.90],[2.01,2.22,.90]],
                           panel=[1.25,0,12],source_support="bulky_fixture",source_pose=pose([3.25,1.2,13]),
                           receiver_support="pelvis_gantry",receiver_pose=pose([13,10.6,26]),
                           locks={"yaw":[0,1.37,-.70],"lean":[.92,1.70,0]}),
        stock_grid=dict(origin=[-10.8,.7,-3.6],columns=14,spacing=[1.35,1.8]),
        rail_gates=dict(groups=["rail_gate_left","rail_gate_right"],duration=2,
                        occupied_center=[13,1.15,25.55],occupied_size=[8.2,2.1,10.1]),
        mobile_platform=dict(size=[2.4,2], deck_size=[1.2,1.4], heights=[.15,1.6,2.0,2.4],
                             speed=.8, lift_speed=.5,
                             docks={"park":[6.7,0,19.3],"bulky_left":[-.95,0,13],
                                    "bulky_right":[7.45,0,13],"bulky_front":[3.25,0,8.8],
                                    "bulky_rear":[3.25,0,15.6],"limb_left":[11.75,0,14.5],
                                    "limb_right":[16.25,0,14.5]},
                             # Each path starts at parking. Transfers reverse the
                             # current path, then follow the destination path.
                             routes={"park":[],
                                     "bulky_left":[[7.45,0,19.3],[7.45,0,8.8],[-.95,0,8.8],[-.95,0,13]],
                                     "bulky_right":[[7.45,0,19.3],[7.45,0,13]],
                                     "bulky_front":[[7.45,0,19.3],[7.45,0,8.8],[3.25,0,8.8]],
                                     "bulky_rear":[[3.25,0,19.3],[3.25,0,15.6]],
                                     "limb_left":[[11.75,0,19.3],[11.75,0,14.5]],
                                     "limb_right":[[16.25,0,19.3],[16.25,0,14.5]]}),
        crane=dict(runways=[-12.5,25.3], columns=[-7,1,19,37],
                   runway_y=23.4, bridge_y=23.15, runway_span=[-8,38],
                   console=[7.8,0,22.8], park=[8.4,20,18],
                   rear_low_x=23.7, rear_well_x=24, rear_cross_bottom=18,
                   head_transit_bottom=19, pauldron_transit_bottom=18,
                   rear_well_bounds=[22.8,25.2,31.7,34.7],
                   arm_upend_y=9.6, arm_spreader_allowance=1.8),
        access=dict(levels=[8.4,11.2,14,16.4], floor_depth=.2, guard_height=1.1,
                    wing_roots=[[5,24],[21,24]], wing_length=8, wing_width=1.2,
                    rear_roots=[[10.1,27.95],[15.9,27.95]], rear_leaf=1.45,
                    modes={"work":[],"pelvis":[11.2,14,16.4],"leg":[8.4],
                           "chest":[14,16.4],"arm":[8.4,11.2,14,16.4],
                           "rear":[],"head":[]},
                    duration=6.0),
        elevators={}, groups={}, solids=[], signs=[],
    )
    for side, x in [("left",6.6),("right",19.4)]:
        data["elevators"][side] = dict(
            name=side, origin=[x,0,29], size=[2.6,2.6], levels=[.15,8.4,11.2,14,16.4],
            yaw_degrees=0, side_doors=True, shaft_size=[3.2,3.2],
            guide_positions=[[-1.45,-1.45],[1.45,1.45]],
            shelf=dict(id=side+"_shelf",supports=[side+"_shelf_0",side+"_shelf_1"],
                       position=[-.25,.65,-1],yaw_degrees=0,size=[1.4,.08,.4],
                       places=[-.35,.35]))

    def group(name, parent="", at=(0,0,0), rotation=(0,0,0), **extra):
        data["groups"][name] = dict(parent=parent, **pose(at,rotation), **extra)
        return name

    def box(name, at, size, material="steel", parent="", solid=True):
        data["solids"].append(dict(id=name,parent=parent,position=list(at),size=list(size),
                                   material=material,solid=solid))

    def bounds(name,x0,x1,y0,y1,z0,z1,material="steel",parent=""):
        box(name,[(x0+x1)/2,(y0+y1)/2,(z0+z1)/2],[x1-x0,y1-y0,z1-z0],material,parent)

    def deck(name, x0,x1,z0,z1,y,guards=(),parent=""):
        bounds(name+"_floor",x0,x1,y-.2,y,z0,z1,"deck",parent)
        for edge in guards:
            a = [x0,x1,z0,z1]
            if edge == "left":a[0],a[1] = x0-.08,x0
            if edge == "right":a[0],a[1] = x1,x1+.08
            if edge == "front":a[2],a[3] = z0-.08,z0
            if edge == "rear":a[2],a[3] = z1,z1+.08
            bounds(name+"_"+edge+"_rail",a[0],a[1],y+1.02,y+1.10,a[2],a[3],"yellow",parent)
            if edge in ["left","right"]:
                for i,z in enumerate([z0+.04,z1-.04]):box(name+"_"+edge+"_post"+str(i),[(a[0]+a[1])/2,y+.51,z],[.08,1.02,.08],"yellow",parent)
            else:
                for i,x in enumerate([x0+.04,x1-.04]):box(name+"_"+edge+"_post"+str(i),[x,y+.51,(a[2]+a[3])/2],[.08,1.02,.08],"yellow",parent)

    # Shell, flush crossings, marked reservations and a single expanded crane.
    box("floor",[6,-.15,15],[40,.3,48],"floor")
    for x in [-14,26]:box("wall_x"+str(x),[x,12.5,15],[.3,25,48],"wall")
    for z in [-9,39]:box("wall_z"+str(z),[6,12.5,z],[40,25,.3],"wall")
    box("roof",[6,25.15,15],[40,.3,48],"dark")
    for z in [-6,2,10,18,26,34]:box("truss"+str(z),[6,24.7,z],[39.6,.4,.3])
    for key,bay in data["bays"].items():
        x0,x1,z0,z1=bay["bounds"]
        for edge,x,z,sx,sz in [("l",x0,(z0+z1)/2,.04,z1-z0),("r",x1,(z0+z1)/2,.04,z1-z0),
                              ("f",(x0+x1)/2,z0,x1-x0,.04),("b",(x0+x1)/2,z1,x1-x0,.04)]:
            box(key+"_mark_"+edge,[x,.006,z],[sx,.012,sz],"yellow",solid=False)
        data["signs"].append(dict(text=key.replace("_"," ").upper(),position=[(x0+x1)/2,2.8,z0],width=min(5,x1-x0)))
    for x in data["crane"]["runways"]:
        for z in data["crane"]["columns"]:
            box(f"crane_base_{x}_{z}",[x,.12,z],[.8,.24,.8],"dark")
            box(f"crane_column_{x}_{z}",[x,11.7,z],[.4,23.4,.4])
        box(f"crane_runway_{x}",[x,23.4,15],[.4,.4,46])
    group("crane_bridge",at=[0,0,18])
    box("crane_bridge",[6.4,23.15,0],[38.2,.3,.4],parent="crane_bridge")
    group("crane_trolley",parent="crane_bridge",at=[8.4,23,0])
    box("crane_trolley",[0,0,0],[.55,.25,.5],"yellow","crane_trolley")
    for lane,x in data["rail"]["lanes"].items():
        end=20.5 if lane=="parking" else 27
        for side in [-1,1]:box(f"rail_{lane}_{side}",[x+side*.62,.008,(14.5+end)/2],[.1,.016,end-14.5],solid=False)
    bounds("transverse_table",10.5,23.4,-.1,0,13.25,15.75,"dark")
    for owner,frame in data["foot_storage"].items():
        for side in [-1,1]:
            x=frame["position"][0]+side*.43;z=frame["position"][2]+1.13
            box(f"{owner}_store_mast_{side}",[x,.58,z],[.12,1.16,.18])
            box(f"{owner}_store_sole_{side}",[x,1.165,z],[.18,.07,.66],"yellow")

    # Pedestrian entrances at either end of the ground crosswalk. Hinges stay
    # outside the empty holder's X8.9..17.1 sweep; rails travel between gates.
    for side,x,angle in [("left",8.4,-90),("right",17.6,90)]:
        key="rail_gate_"+side
        box(key+"_post",[x,.65,20.5],[.14,1.3,.14],"dark")
        group(key,at=[x,0,20.5],closed_angle=0,open_angle=angle,motion_contacts=[key+"_post"])
        box(key+"_bar",[0,1.02,.85],[.10,.18,1.50],"yellow",key)
        box(key+"_lower_bar",[0,.60,.85],[.08,.12,1.50],"yellow",key)
        box(key+"_link",[0,.81,.12],[.08,.60,.08],parent=key)
        data["signs"].append(dict(text="RAIL CROSSING / WAIT FOR OPEN GATES",position=[x,1.65,20.5],width=2.6))

    # The one adjustable bulky fixture, initially using pelvis bearing inserts.
    # Payload-specific contacts move with its frame; exchange is occupancy-gated
    # by the fixture controller, rather than respawning a second workstation.
    group("bulky_fixture",at=[3.25,0,13])
    group("bulky_frame",parent="bulky_fixture")
    group("bulky_insert_pelvis",parent="bulky_frame")
    group("bulky_insert_chest",parent="bulky_frame")
    for x in [-.65,.65]:
        box(f"bulky_foot_{x}",[x,.12,.65],[.75,.24,1.8],"dark","bulky_fixture")
        box(f"bulky_screw_{x}",[x,.40,.65],[.18,.36,.18],parent="bulky_fixture")
        box(f"bulky_inner_{x}",[x,.58,.65],[.12,.36,.12],parent="bulky_frame")
        box(f"bulky_insert_{x}",[x,1.52,.65],[.24,.10,.26],"yellow","bulky_insert_pelvis")
        box(f"bulky_pelvis_riser_{x}",[x,1.08,.65],[.18,.88,.18],parent="bulky_insert_pelvis")
        for z in [.55,.75]:
            key=f"bulky_jaw_pelvis_{x}_{z}";group(key,parent="bulky_insert_pelvis",at=[x,1.88,z])
            box(key+"_contact",[0,0,0],[.18,.10,.16],"yellow",key)
            box(key+"_back",[0,-.23,.91-z],[.12,.46,.10],parent=key)
            box(key+"_link",[0,0,(.91-z)/2],[.12,.10,.91-z],parent=key)
    box("bulky_crossbeam",[0,.55,.65],[1.66,.2,.24],parent="bulky_frame")
    for x in [-.84,.84]:
        box(f"bulky_chest_rail_{x}",[x,.70,0],[.18,.20,1.1],parent="bulky_insert_chest")
        for z in [-.45,.45]:
            box(f"bulky_chest_pad_{x}_{z}",[x,.825,z],[.20,.05,.18],"yellow","bulky_insert_chest")
            key=f"bulky_jaw_chest_{x}_{z}";group(key,parent="bulky_insert_chest",at=[x,1.0,z])
            box(key+"_contact",[0,0,0],[.18,.10,.18],"yellow",key)
            box(key+"_link",[.15 if x>0 else -.15,0,0],[.30,.10,.12],parent=key)
            box(key+"_back",[.28 if x>0 else -.28,-.15,0],[.12,.30,.12],parent=key)
    for x in [-.84,.84]:
        for z in [-.45,.45]:
            box(f"chest_store_pad_{x}_{z}",[-7+x,.80,27.5+z],[.24,.1,.24],"yellow")
            box(f"chest_store_leg_{x}_{z}",[-7+x,.375,27.5+z],[.18,.75,.18],"dark")
    data["signs"].append(dict(text="PREPARED CHEST / CRANE TO EMPTY BULKY FIXTURE",position=[-7,1.7,25.8],width=3.2))

    group("bulky_insert_core",parent="bulky_frame")
    group("core_store",at=[-7,0,31.3])
    for parent in ["bulky_insert_core","core_store"]:
        for x in [-.35,.35]:
            box(parent+f"_rail_{x}",[x,.65,.2],[.12,.12,1.35],parent=parent)
            for z in [-.35,.75]:
                box(parent+f"_post_{x}_{z}",[x,.785,z],[.10,.33,.12],parent=parent)
                key=parent+f"_saddle_{x}_{z}";group(key,parent=parent,at=[0,1.3,z],rotation=[0,0,135 if x<0 else -135])
                box(key+"_pad",[0,.467,0],[.065,.04,.16],"yellow",key)
            if parent=="core_store":box(parent+f"_leg_{x}",[x,.295,.2],[.18,.59,1.35],"dark",parent)
    for z in [-.35,.75]:
        key=f"bulky_jaw_core_{z}";group(key,parent="bulky_insert_core",at=[0,1.77,z])
        box(key+"_contact",[0,0,0],[.12,.10,.15],"yellow",key)
        box(key+"_arm",[-.28,0,0],[.56,.10,.10],parent=key)
        box(key+"_back",[-.55,-.48,0],[.10,.96,.10],parent=key)

    group("bulky_insert_backpack",parent="bulky_frame")
    group("backpack_store",at=[-7,0,35])
    for parent in ["bulky_insert_backpack","backpack_store"]:
        for x in [-1.18,1.18]:
            box(parent+f"_rail_{x}",[x,.76,1.4],[.10,.18,2.6],parent=parent)
            for z in [.50,2.40]:
                box(parent+f"_pad_{x}_{z}",[x,.91,z],[.10,.10,.24],"yellow",parent)
                if parent=="backpack_store":box(parent+f"_leg_{x}_{z}",[x,.34,z],[.14,.68,.24],"dark",parent)
                if parent=="bulky_insert_backpack":
                    key=f"bulky_jaw_backpack_{x}_{z}";group(key,parent=parent,at=[x,1.68,z])
                    box(key+"_contact",[0,0,0],[.08,.10,.16],"yellow",key)
                    box(key+"_link",[.14 if x>0 else -.14,0,0],[.28,.10,.10],parent=key)
                    box(key+"_back",[.24 if x>0 else -.24,-.36,0],[.10,.72,.10],parent=key)
    for z in [.50,2.40]:box(f"bulky_backpack_crossbeam_{z}",[0,.64,z],[2.46,.12,.16],parent="bulky_insert_backpack")
    for x in [-.65,.65]:box(f"bulky_backpack_spine_{x}",[x,.64,1.45],[.14,.12,2.06],parent="bulky_insert_backpack")
    data["signs"].append(dict(text="PREPARED BACKPACK / TWO-END CRANE TO BULKY FIXTURE",position=[-7,1.65,34.3],width=3.4))

    # Passive arm parking and the single removable cassette start together.
    group("arm_cassette",at=[14,0,-6.3])
    for t in data["cassette"]["saddles"]:
        if t==4.05:
            for x in [-.7,.7]:box(f"arm_park_pedestal_{x}_{t}",[14+x,.32,-6.3+t],[.3,.64,.4],"dark")
        else:
            for x in [-.7,.7]:
                box(f"arm_cassette_foot_{x}_{t}",[x,.32,t],[.16,.64,.24],"dark","arm_cassette")
                # Flush bearing patches leave the leg bogie's wheel route open.
                for z in [-6.3,9.9]:box(f"arm_cassette_floor_pad_{x}_{t}_{z}",[14+x,-.025,z+t],[.28,.05,.36],"yellow")
        box(f"arm_cassette_saddle_{t}",[0,.93,t],[1.4,.14,.24],"yellow","arm_cassette")
        box(f"arm_cassette_tie_{t}",[0,.74,t],[2,.2,.24],parent="arm_cassette")
        for side in [-1,1]:
            key=f"arm_cassette_clamp_{side}_{t}"
            group(key,parent="arm_cassette",at=[side*.82,1.10,t])
            data["groups"][key].update(joint="clamp",side=side,fold_degrees=-side*90)
            box(key+"_bar",[-side*.255,0,0],[.51,.08,.12],"yellow",key)
            box(key+"_foot",[-side*.51,0,0],[.14,.08,.12],"yellow",key)
            box(key+"_post",[side*.82,.93,t],[.10,.34,.12],parent="arm_cassette")
    for x in [-.9,.9]:box(f"arm_cassette_rail_{x}",[x,.75,4.05],[.2,.2,9],parent="arm_cassette")
    for x in [-.9,.9]:
        for t in [1.35,6.05]:box(f"arm_cassette_lift_{x}_{t}",[x,.87,t],[.18,.04,.18],"yellow","arm_cassette")
    # The second prepared arm waits on passive structural rests. Its own
    # physical identity is later transferred onto the one shared cassette.
    group("right_arm_store",at=[21,0,-6.3])
    for t in data["cassette"]["saddles"]:
        box(f"right_arm_store_pad_{t}",[0,.93,t],[1.4,.14,.24],"yellow","right_arm_store")
        for x in [-.55,.55]:box(f"right_arm_store_leg_{x}_{t}",[x,.465,t],[.16,.93,.24],"dark","right_arm_store")

    # Readable source contacts in the reserved foot area. Detailed foot tooling
    # remains a later component workflow; the prepared foot uses its carrier.

    # Low portal: no crown across the rear suspension corridor.
    for x in [8.8,17.2]:
        box(f"gantry_foot_{x}",[x,.15,31.7],[1.4,.3,1.6],"dark")
        box(f"gantry_column_{x}",[x,5.55,31.1],[.6,11.1,.6])
        # Stepped blockout braces stay wholly behind the portal and out of wells.
        for i in range(4):box(f"gantry_brace_{x}_{i}",[x,.5+i*.65,32.7-i*.32],[.35,1,.35])
    bounds("gantry_crosshead",8.5,17.5,10.5,11.1,30.8,31.4,"dark")
    for x in [12.35,13.65]:
        bounds(f"gantry_arm_{x}",x-.18,x+.18,10.65,10.95,26.5,31.1)
        bounds(f"gantry_bearing_{x}",x-.18,x+.18,10.95,10.97,26.52,26.78,"yellow")
    for x in [11.60,14.40]:
        for z in [26.55,26.75]:
            key=f"gantry_jaw_{x}_{z}"
            group(key,at=[x,11.1,z],joint="clamp")
            box(key+"_handle",[x,10.8,z],[.12,.12,.18],"yellow")
            box(key+"_drive",[x,10.975,z],[.06,.35,.06])
            # Link between the outboard operating handle and bearing-side jaw.
            dx=.75 if x<13 else -.75
            box(key+"_link",[dx/2,.23,0],[.83,.08,.10],parent=key)
            box(key+"_rod",[0,-.02,0],[.04,.50,.04],parent=key)
            box(key+"_contact",[dx,.18,0],[.18,.1,.16],"yellow",key)

    for level in data["access"]["levels"]:
        tag=str(level)
        for side in ["left","right"]:
            left=side=="left"
            x0,x1=(3.5,5) if left else (21,22.5)
            # Front landing joins a gate at 24.7, rear portion always connected.
            deck(f"outer_{side}_{tag}",x0,x1,24.7,37.3,level,["left" if left else "right","rear"])
            # The root apron is the wing's bearing interface. Keep it a
            # separately identified solid, never exclude the full outer walk
            # from moving-equipment collision queries.
            deck(f"wing_hinge_{side}_{tag}",x0,x1,23.4,24.7,level,[])
            box(f"hinge_front_guard_{side}_{tag}",[(x0+x1)/2+(-.35 if left else .35),level+1.06,23.32],[.8,.08,.08],"yellow")
            # Split inner guard around the elevator's side doorway and wing root.
            for n,(z0,z1) in enumerate([(24.7,28.5),(30,35.8)]):
                gx=x1+.04 if left else x0-.04
                box(f"outer_inner_{side}_{tag}_{n}",[gx,level+1.06,(z0+z1)/2],[.08,.08,z1-z0],"yellow")
            gate=group(f"access_gate_{side}_{tag}",at=[(x0+x1)/2,level,24.85],joint="gate",level=level,stow_x=1.6 if left else -1.6)
            box(gate,[0,.65,0],[1.5,.10,.08],"yellow",gate)
            root=group(f"wing_{side}_{tag}",at=[5 if left else 21,level,24],rotation=[0,0 if left else 180,0],joint="wing",side=side,level=level)
            data["groups"][root]["motion_contacts"]=[f"wing_hinge_{side}_{tag}_floor"]
            deck(root,.02,7.98,-.6,.6,0,["front","rear"],root)
            # Local rear guard leaves gaps for the telescoping work patches.
            for record in data["solids"]:
                if record["parent"]==root and "_rear_" in record["id"]:record["solid"]=False;record["hidden"]=True
            if level in [8.4,11.2]:
                fx=4.6 if level==8.4 else 5.35
                length=1.2 if level==8.4 else 2.0
                finger=group(f"finger_{side}_{tag}",parent=root,at=[fx,0,0],joint="finger",extension=length,side=side,level=level)
                # Telescopes rearward in world Z (local sign differs on right).
                # At 11.2 the socket crown rises through the floor's elevation.
                # Leave .05 m lateral clearance to its real spherical shell.
                deck(finger,0,1.2 if level==8.4 else 1.15,-.6,.6,0,[],finger)
                if level==11.2:
                    middle=group(f"finger_middle_{side}_{tag}",parent=root,at=[fx,0,0],joint="finger",extension=.8,side=side,level=level)
                    deck(middle,0,1.3,-.6,.6,-.025,[],middle)
            if level==8.4:
                a,b=(8.2,10.1) if left else (15.9,17.8)
                deck(f"hip_apron_{side}",a,b,27.35,30.1,level,["rear"])
                outer=group("rear_outer_"+side,at=[10.1 if left else 15.9,level,27.95],rotation=[0,0 if left else 180,0],joint="rear_outer",side=side,level=level)
                deck(outer,.01,1.45,-.6,.6,0,[],outer)
                inner=group("rear_inner_"+side,parent=outer,at=[1.45,.1,0],joint="rear_inner",side=side,level=level)
                deck(inner,0,1.44,-.6,.6,-.1,[],inner)
                for parent in [outer,inner]:
                    guard=group(parent+"_guard",parent=parent,joint="rear_guard",level=level)
                    box(guard,[.725,.55,.64],[1.45,1.1,.08],"yellow",guard)
            else:
                a,b=(7.9,9.7) if left else (16.3,18.1)
                deck(f"rear_branch_{side}_{tag}",a,b,28.5,30,level,["front","rear"])
                a,b=(9.7,11.4) if left else (14.6,16.3)
                deck(f"rear_flank_{side}_{tag}",a,b,27.4,30.1,level,[])
                if level==11.2:deck("aft_finger_"+side,a,b,31.7,35.8,level,["left","right","front"])
        deck("rear_crossover_"+tag,5,21,35.8,37.3,level,["rear"])

    return data


def audit(data):
    ids=[record["id"] for record in data["solids"]]
    assert len(ids)==len(set(ids)), "Duplicate geometry identity"
    for record in data["solids"]:
        assert all(v>0 for v in record["size"]), record
        assert not record["parent"] or record["parent"] in data["groups"], record
    for name,record in data["groups"].items():
        ancestors={name}
        while record["parent"]:
            assert record["parent"] not in ancestors, "Cyclic equipment frame"
            ancestors.add(record["parent"])
            record=data["groups"][record["parent"]]
    assert data["rail"]["lying_lift"]+data["rail"]["base_y"]==1.85
    assert data["rail"]["holder"]["withdrawal"]==1.4
    assert len(data["elevators"])==2


def delivery_inputs(layout, data):
    """Project shared workshop coordinates into supported equipment routes."""
    from copy import deepcopy
    r=data["rail"]
    layout["parent_homes"]["pelvis"]=[3.25,1.2,13]
    layout["rail"].update(x=r["station_x"],home_z=r["home_z"],bay_z=r["bay_z"],
                          base_y=r["base_y"],lying_lift=r["lying_lift"],panels=r["panels"])
    carrier=layout["foot_carrier"]
    # FA-01's scene origin is (0,.8,-.7) relative to its sole datum.
    carrier.update(source_pose=pose([14,2.0,6.3]), receiver_pose=pose([14,2.55,10.2],[90,0,0]),
                   route=[pose([14,2.0,6.3]),pose([14,2.65,6.3]),pose([14,2.65,8.7]),pose([14,2.55,10.2],[90,0,0])],
                   durations=[4,5,8],panel=[11.1,0,7],contacts=[[-.43,-.8,1.13],[.43,-.8,1.13]],
                   sole_pad_size=[.18,.07,.66], assembly="foot",receiver_owner="left_leg",receiver_slot="foot",
                   assignments={"foot":"left_leg","right_foot":"right_leg"},
                   sole_route=data["foot_dispatch"]["sole_route"],root_offset=[0,.8,-.7])
    carrier["end_stop"]=dict(centers=[[-.43,-.73,1.48],[.43,-.73,1.48]],size=[.18,.14,.04])
    for key in ["shin","fork","spar"]:
        mirrored=deepcopy(layout["crane"]["tasks"][key])
        mirrored.update(load_uid="R-"+mirrored["load_uid"],owner="right_leg",source_support=mirrored["source_support"]+"_right",title="Right "+mirrored["title"])
        mirrored["magnetic_points"]={name:[-at[0],at[1],at[2]] for name,at in mirrored["magnetic_points"].items()}
        mirrored["rack_contacts"]=[[-at[0],at[1],at[2]] for at in mirrored["rack_contacts"]]
        layout["crane"]["tasks"]["right_"+key]=mirrored
    for key,task in layout["crane"]["tasks"].items():
        if key not in ["shin","fork","spar","right_shin","right_fork","right_spar"]:continue
        base=key.removeprefix("right_")
        index=["shin","fork","spar"].index(base)
        x=-10.5+index*3+(1.5 if key.startswith("right_") else 0)
        source_z=19.2 if key.startswith("right_") else 18.5
        task["source_pose"]=pose([x,1.85,source_z],[90,0,0])
        z={"shin":10.795,"fork":14.5,"spar":15.34}[base]
        task["receiver_pose"]=pose([14,1.85,z],[90,0,0])
        task["route_positions"]=[task["source_pose"]["position"],[x,6,source_z],[14,6,z+.2],[14,1.85,z+.2],[14,1.85,z]]
        task["up_y"]=6.88;task["console_position"]=data["crane"]["console"]
        task["overhead_y"]=23.0
        task["park_position"]=[8.4,0,18]
    for owner,source in data["foot_storage"].items():
        layout["crane"]["tasks"][owner]=dict(title="Prepared "+("left" if owner=="foot" else "right")+" foot",
            payload="assembly",load_uid=owner,owner=owner,slot="",source_support=owner+"_store",support="m2_service_crane",
            receiver_support="foot_carrier",receiver_equipment="foot_carrier",follow_owner="left_leg" if owner=="foot" else "right_leg",
            secured=dict(milestone=""),endpoint_ids=["magnet_a","magnet_b","magnet_c","magnet_d"],
            # Four exposed top faces of the fixed FA-100 rails. Sole-local
            # frame Z440 becomes root Y-.36; original fore/aft Y maps to -Z.
            magnetic_points={"foot_front_left":[-.50,-.36,-.2],"foot_front_right":[.50,-.36,-.2],
                             "foot_rear_left":[-.50,-.36,1.2],"foot_rear_right":[.50,-.36,1.2]},
            source_pose=source,receiver_pose=carrier["source_pose"],
            route_positions=[source["position"],[-7,5.8,source["position"][2]],[-7,5.8,6.3],[14,5.8,6.3],[14,2.08,6.3],[14,2,6.3]],
            approach=dict(axis=[0,-1,0],distance=.08),rig_clearance=1.5,up_y=6.9,
            rack_contacts=[],console_position=data["crane"]["console"],overhead_y=23.0,park_position=[8.4,0,18])
    layout["crane"]["tasks"]["pelvis"]=dict(title="Pelvis and waist",payload="assembly",load_uid="pelvis",owner="pelvis",slot="",
        source_support="bulky_fixture",source_equipment="module_supports",support="m2_service_crane",receiver_support="pelvis_gantry",receiver_equipment="module_supports",
        secured=dict(milestone=""),endpoint_ids=["magnet_a","magnet_b","magnet_c","magnet_d"],
        magnetic_points={f"pelvis_eye_{i}":[x,.75,z] for i,(x,z) in enumerate([(x,z) for x in [-1.15,1.15] for z in [-.70,.70]],1)},
        spreader_points=[[x,0,z] for x in [-1.35,1.35] for z in [-.90,.90]],
        source_pose=pose([3.25,1.2,13]),receiver_pose=pose([13,10.6,26]),
        route_positions=[[3.25,1.2,13],[3.25,10.8,13],[13,10.8,13],[13,10.8,26],[13,10.72,26],[13,10.6,26]],
        approach=dict(axis=[0,-1,0],distance=.12),rig_clearance=2.05,up_y=14.0,rack_contacts=[],
        access_mode="pelvis",restore_access=True,console_position=data["crane"]["console"],overhead_y=23.,park_position=[8.4,0,18])
    chest_common=dict(payload="assembly",load_uid="chest",support="m2_service_crane",
        endpoint_ids=["magnet_a","magnet_b","magnet_c","magnet_d"],
        magnetic_points={f"chest_pad_{i}":[x,3.55,z] for i,(x,z) in enumerate([(x,z) for x in [-1.15,1.15] for z in [-.65,.65]],1)},
        handle_points={f"chest_pad_{i}":[x,3.55,-.85 if z<0 else 1.05] for i,(x,z) in enumerate([(x,z) for x in [-1.15,1.15] for z in [-.65,.65]],1)},
        spreader_points=[[x,0,z] for x in [-1.3,1.3] for z in [-.8,.8]],
        rig_clearance=1.8,up_y=18.23,rack_contacts=[],console_position=data["crane"]["console"],overhead_y=23.,park_position=[8.4,0,18])
    layout["crane"]["tasks"]["chest_store"]=dict(**deepcopy(chest_common),title="Chest to fixture",owner="chest",slot="",
        source_support="chest_store",receiver_support="bulky_fixture",receiver_equipment="module_supports",receiver_contact=True,
        secured=dict(milestone=""),source_pose=data["chest_storage"],receiver_pose=pose([3.25,.85,13]),
        route_positions=[[-7,.85,27.5],[-7,6.2,27.5],[-7,6.2,13],[3.25,6.2,13],[3.25,.98,13],[3.25,.85,13]],
        approach=dict(axis=[0,-1,0],distance=.13))
    layout["crane"]["tasks"]["chest"]=dict(**deepcopy(chest_common),title="Chest to waist",owner="pelvis",slot="chest",
        source_support="bulky_fixture",source_equipment="module_supports",receiver_equipment="module_supports",
        secured=dict(milestone="chest_secured"),source_pose=pose([3.25,.85,13]),receiver_pose=pose([13,12.7,26]),
        route_positions=[[3.25,.85,13],[3.25,12.88,13],[13,12.88,13],[13,12.88,26],[13,12.88,26],[13,12.7,26]],
        approach=dict(axis=[0,-1,0],distance=.18),access_mode="chest",restore_access=True)
    core_common=dict(payload="assembly",load_uid="core",rig_adapter="core_guide",support="m2_service_crane",endpoint_ids=["magnet_a","magnet_b"],
        magnetic_points={"core_front":[0,.58,-.15],"core_aft":[0,.22,1.16]},
        point_ends={"core_front":"magnet_a","core_aft":"magnet_b"},endpoint_labels={"magnet_a":"forward equalizing bridge","magnet_b":"aft magnetic end"},
        handle_points={"core_front":[.42,.32,-.15],"core_aft":[0,.22,1.16]},
        spreader_points=[[0,0,-.65],[0,0,.65]],rig_center_offset=[0,0,.095],rig_clearance=1.17,up_y=20.22,rack_contacts=[],
        console_position=data["crane"]["console"],overhead_y=23.,park_position=[8.4,0,18])
    layout["crane"]["tasks"]["core_store"]=dict(**deepcopy(core_common),title="Core to fixture",owner="core",slot="",
        source_support="core_store",receiver_support="bulky_fixture",receiver_equipment="module_supports",receiver_contact=True,
        secured=dict(milestone=""),source_pose=data["core_storage"],receiver_pose=pose([3.25,1.3,13]),
        route_positions=[[-7,1.3,31.3],[-7,6,31.3],[-7,6,13],[3.25,6,13],[3.25,1.4,13],[3.25,1.3,13]],
        approach=dict(axis=[0,-1,0],distance=.10))
    layout["crane"]["tasks"]["core"]=dict(**deepcopy(core_common),title="Core to rear dock",owner="chest",slot="core",
        source_support="bulky_fixture",source_equipment="module_supports",guided_receiver="core_guide",receiver_equipment="core_guide",
        secured=dict(milestone="core_seated"),source_pose=pose([3.25,1.3,13]),receiver_pose=pose([13,13.35,28.2]),
        route_positions=[[3.25,1.3,13],[3.25,6,13],[23.7,6,13],[23.7,6,32.4],[24,6,32.4],[24,18.47,32.4],
                         [13,18.47,32.4],[13,13.35,32.4],[13,13.35,28.2],[13,13.35,28.2]],
        approach=dict(axis=[0,0,-1],distance=0))
    layout["crane"]["tasks"]["backpack_store"]=dict(payload="assembly",load_uid="backpack",support="m2_service_crane",
        title="Backpack to fixture",owner="backpack",slot="",source_support="backpack_store",receiver_support="bulky_fixture",
        receiver_equipment="module_supports",receiver_contact=True,secured=dict(milestone=""),
        endpoint_ids=["magnet_a","magnet_b"],magnetic_points={"backpack_left":[-.72,.88,1.4],"backpack_right":[.72,.88,1.4]},
        magnetic_normal=[0,1,0],
        spreader_points=[[-.72,0,0],[.72,0,0]],rig_clearance=1.2,rig_min_height=2.08,sweep_rig=True,exact_receiver=True,
        up_y=20.08,overhead_y=23.,rack_contacts=[],console_position=data["crane"]["console"],park_position=[8.4,0,18],
        source_pose=data["backpack_storage"],receiver_pose=pose([3.25,.85,13]),
        route_positions=[[-7,.85,35],[-7,5.5,35],[-7,5.5,13],[3.25,5.5,13],[3.25,.98,13],[3.25,.85,13]],
        approach=dict(axis=[0,-1,0],distance=.13))
    backpack=deepcopy(layout["crane"]["tasks"]["backpack_store"])
    backpack.update(title="Backpack to hinges",owner="chest",slot="backpack",source_support="bulky_fixture",source_equipment="module_supports",
        receiver_equipment="backpack_hinge",guided_receiver="backpack_hinge",secured=dict(milestone="backpack_retained"),
        source_pose=pose([3.25,.85,13]),receiver_pose=pose(data["backpack"]["hinge_seat"]),route_positions=data["backpack"]["route_positions"],
        approach=dict(axis=[0,-1,0],distance=.2))
    backpack.pop("receiver_support");backpack.pop("receiver_contact")
    layout["crane"]["tasks"]["backpack"]=backpack
    layout["crane"]["tasks"]["cassette"]=dict(payload="assembly",load_uid="arm_cassette",support="m2_service_crane",
        title="Cassette to station",owner="arm_cassette",slot="",source_support="cassette_park",source_equipment="arm_cassette",
        receiver_support="cassette_station",receiver_equipment="arm_cassette",receiver_contact=True,rig_adapter="arm_cassette",
        secured=dict(milestone=""),endpoint_ids=["magnet_a","magnet_b","magnet_c","magnet_d"],
        magnetic_points={f"cassette_pad_{i}":[x,.89,t] for i,(t,x) in enumerate([(t,x) for t in [1.35,6.05] for x in [-.9,.9]],1)},
        magnetic_normal=[0,1,0],spreader_points=[[x,0,z] for z in [-2.35,2.35] for x in [-1.1,1.1]],
        rig_clearance=2.21,up_y=7.9,overhead_y=23.,rack_contacts=[],console_position=data["crane"]["console"],park_position=[8.4,0,18],
        source_pose=pose([14,0,-6.3]),receiver_pose=pose([14,0,9.9]),
        route_positions=[[14,0,-6.3],[14,4.8,-6.3],[14,4.8,9.9],[14,0,9.9]],
        approach=dict(axis=[0,-1,0],distance=0))
    for side,sign in [("left",-1),("right",1)]:
        uid=side+"_arm"; center=data["robot"]["shoulders"][0 if sign<0 else 1]
        offset=data["arm_delivery"]["approach_distance"]
        before=[center[0]+sign*math.sin(math.pi/12)*offset,center[1]-math.cos(math.pi/12)*offset,center[2]]
        layout["crane"]["tasks"][uid]=dict(payload="assembly",load_uid=uid,support="m2_service_crane",title=side.title()+" arm to shoulder",
            owner="chest",slot=uid,source_support="arm_cassette",source_equipment="arm_cassette",guided_receiver=side+"_shoulder",
            receiver_equipment=side+"_shoulder",rig_adapter=side+"_shoulder",secured=dict(milestone=uid+"_retained"),
            endpoint_ids=["magnet_a","magnet_b","magnet_c","magnet_d"],
            magnetic_points={f"{uid}_pad_{i}":[x,.10,t] for i,(t,x) in enumerate([(t,x) for t in [.75,4.40] for x in [-.68,.68]],1)},
            handle_points={f"{uid}_pad_{i}":[x,.10,t] for i,(t,x) in enumerate([(t,x) for t in [.75,4.40] for x in [-.72,.72]],1)},
            rig_clearance=1.25,up_y=20,overhead_y=23.,rack_contacts=[],console_position=data["crane"]["console"],park_position=[8.4,0,18],
            source_pose=pose([14,1.55,9.9]),receiver_pose=pose(center,[75,sign*90,0]),
            route_positions=[[14,1.55,9.9],[14,9.6,9.9],[14,9.6,9.9],[14,9.6,9.9],[14,9.6,9.9],
                             [14,before[1],9.9],[14,before[1],19.5],[before[0],before[1],19.5],before,center],
            route_rotations=[[0,0,0],[0,0,0],[90,0,0],[90,sign*90,0]]+[[75,sign*90,0]]*6,
            sweep_radius=7.6,exact_receiver=True,access_mode="arm",restore_access=True,approach=dict(axis=[0,0,0],distance=offset))
    right=deepcopy(layout["crane"]["tasks"]["right_arm"])
    for key in ["guided_receiver","source_equipment","access_mode","restore_access"]:right.pop(key)
    right.update(title="Right arm to cassette",owner="right_arm",slot="",source_support="right_arm_store",receiver_support="arm_cassette",
        receiver_equipment="arm_cassette",receiver_contact=True,secured=dict(milestone=""),
        source_pose=pose([21,1.55,-6.3]),receiver_pose=pose([14,1.55,9.9]),
        route_positions=[[21,1.55,-6.3],[21,4.8,-6.3],[14,4.8,-6.3],[14,4.8,9.9],[14,1.55,9.9]],route_rotations=[[0,0,0]]*5)
    layout["crane"]["tasks"]["right_arm_store"]=right
    for key,value in layout["crane"]["tasks"][layout["crane"]["task"]].items():layout["crane"][key]=deepcopy(value)
    return layout


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check",action="store_true")
    args=parser.parse_args()
    authored=contract()
    audit(authored)
    layout=json.loads(PATH.read_text())
    expected=delivery_inputs(json.loads(PATH.read_text()),authored)
    expected["workshop"]=authored
    if args.check:
        assert layout==expected, "Regenerate with author_workshop_blockout.py"
    else:
        PATH.write_text(json.dumps(expected,indent=2,ensure_ascii=False)+"\n")
    print(f"WORKSHOP_BLOCKOUT PASS: {len(authored['solids'])} solids, {len(authored['groups'])} equipment frames; byte equality={args.check}")
