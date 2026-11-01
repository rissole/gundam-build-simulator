"""Structural shin with enlarged calf load frame and twin rear/down thrusters."""
import math
from mathutils import Vector
from kit import (tube,cylinder,combine,difference,loft,chamfered_rect,bell_nozzle,
                 place,cable_bundle,frame)
from thigh import box,bore,strut,tag,register,captive_detail

THRUSTER_AXIS=(0,-math.cos(math.radians(12)),-math.sin(math.radians(12)))
THRUSTER_SEATS=[(0,-.72,3.98),(0,-.72,2.93)]


def build(ctx):
    m=ctx.materials; gun=m['gunmetal']; steel=m['steel']
    plate=box((.540,.440,.030),(0,0,1.395),gun,.003)
    difference(plate,box((.182,.102,.034),(0,0,1.390),gun,0))
    for x in (-.20,.20):
        for y in (-.15,.15): bore(plate,.019,(x,y,1.395),(0,0,1),.10)
    beam=loft([(1.410,chamfered_rect(.300,.200,.015)),
               (2.100,chamfered_rect(.300,.200,.015)),
               (2.420,chamfered_rect(.640,.620,.045)),
               (4.680,chamfered_rect(.640,.620,.045)),
               (4.920,chamfered_rect(.48,.30,.025))],gun,'Load-carrying shin')
    # Longitudinal lightening pockets, machined into front; centre web is intact.
    for z in (2.69,3.30,3.91,4.51):
        difference(beam,box((.38,.14,.36),(0,.31,z),gun,.035))
    parts=[tag(plate,'shin_flange'),tag(beam,'shin_beam'),
           tag(tube(.280,.150,.560,(0,0,5.10),(1,0,0),64,.006,gun),'shin_boss')]
    for s in (-1,1):
        # Long structural side ribs and explicit cradle/shell mounting lands.
        parts += [box((.10,.65,2.20),(s*.35,0,3.55),gun,.018)]
        for z in (2.68,3.29,3.90,4.40):
            # Exposed side panels are structural webs with recessed machining.
            panel=box((.075,.59,.42),(s*.4125,0,z),gun,.018)
            difference(panel,box((.04,.36,.24),(s*.450,0,z),gun,.024))
            parts.append(panel)
            for dz in (-.135,.135):
                for y in (-.205,.205):
                    parts.append(captive_detail((s*.455,y,z+dz),(s,0,0),steel,.023))
        for z in (2.38,3.45,4.52):
            parts += [box((.22,.69,.105),(s*.35,-.025,z),gun,.014),
                      captive_detail((s*.36,.326,z),(0,1,0),steel,.026)]
        # Doubler rails at the front/rear edges give the box a deep section.
        for y in (-.30,.30):
            parts.append(box((.14,.10,2.15),(s*.35,y,3.55),gun,.015))
        for z in (3.22,4.44):
            parts += [strut((s*.36,.04,z-.10),(s*.59,.04,z),.13,.19,gun),
                      box((.15,.28,.14),(s*.59,.04,z),gun,.016)]
        parts += [strut((s*.27,0,2.61),(s*.70,0,2.80),.15,.23,gun),
                  box((.13,.34,.28),(s*.73,0,2.80),gun,.012),
                  tag(box((.010,.28,.22),(s*.795,0,2.80),steel,.003),'shin_pad_'+str(s))]
    for z in (3.22,4.44):
        parts += [strut((0,.25,z-.12),(0,.38,z),.24,.12,gun),
                  box((.36,.12,.14),(0,.38,z),gun,.015)]
    # Godot (x,y,z) -> model (x,-z,y). Preserve the original FA-605 upper plug.
    direction=Vector((.080,.050,.160)).normalized()
    socket=Vector((.250,.100,1.400))+direction*.034
    stay=strut((.13,.075,1.47),socket+Vector((-.021,0,.009)),.025,.025,gun)
    bore(stay,.017,socket,direction,.08)
    # The tilted plug approach clips the baseplate's inner-forward corner.
    # Machine the integral support shells too; an ornamental sleeve is insufficient.
    bore(parts[0],.017,socket,direction,.09)
    parts += [tag(tube(.024,.017,.032,socket,direction,32,.001,steel),'electrical_sleeve'),stay]
    register(ctx,combine(parts,'Shin beam with integral ankle seat'),'LG-100')

    cradle=[]; w=Vector(THRUSTER_AXIS)
    for i,seat in enumerate(THRUSTER_SEATS,1):
        p=Vector(seat)
        cradle.append(tag(tube(.370,.320,.100,p,w,48,.008,gun),'thruster_seat_'+str(i)))
        # Hexagonal fabricated load ring surrounds the unchanged machined seat.
        # The broad corners read as structure even when engines/shroud are absent.
        cradle += [tube(.60,.40,.18,p,w,6,.012,gun),
                   tube(.565,.415,.040,p+w*.105,w,6,.006,steel)]
        # Ribs transfer ring loads into the broad shin beam, not the nozzle skin.
        for s in (-1,1):
            cradle += [strut((s*.34,-.29,p.z),(s*.48,-.70,p.z),.18,.20,gun),
                       box((.19,.22,.30),(s*.46,-.67,p.z),gun,.022),
                       strut((s*.46,-.70,p.z),(s*.30,-.72,p.z+.28),.15,.13,gun)]
            for dz in (-.07,.07):
                cradle.append(captive_detail((s*.46,-.766,p.z+dz),(0,-1,0),steel,.027))
    for s in (-1,1):
        cradle += [box((.14,.20,1.80),(s*.48,-.69,3.45),gun,.020),
                   strut((s*.48,-.69,2.50),(s*.25,-.22,2.25),.16,.17,gun)]
    # Cross tie is below the open knee and behind the future bridge panel.
    cradle.append(box((1.04,.20,.15),(0,-.69,3.45),gun,.018))
    register(ctx,combine(cradle,'Open twin-ring engine cradle'),'LG-440')

    for i,seat in enumerate(THRUSTER_SEATS,1):
        p=Vector(seat)
        engine=[tag(tube(.318,.170,.40,p-w*.12,w,48,.008,gun),'engine_seat'),
                tube(.352,.170,.045,p+w*.074,w,48,.004,steel)]
        nozzle=bell_nozzle(.170,.320,.60,.024,gun,m['bronze'],64)
        place(nozzle,p+w*.10,w)
        engine.append(tag(nozzle,'nozzle'))
        # Clocked longitudinal cooling fins and a bolted locking collar.
        u,v,_=frame(w)
        for j in range(12):
            a=math.tau*j/12
            offset=(u*math.cos(a)+v*math.sin(a))*.307
            engine.append(strut(p-w*.27+offset,p+w*.015+offset,.026,.035,gun))
        for j in range(8):
            a=math.tau*j/8
            offset=(u*math.cos(a)+v*math.sin(a))*.335
            engine.append(captive_detail(p+w*.101+offset,w,steel,.017))
        engine.append(cable_bundle([(p.x+.30,p.y+.28,p.z+.12),
                                   (p.x+.38,p.y+.20,p.z+.17),
                                   (p.x+.42,p.y+.02,p.z+.12)],2,.013,.032,m['rubber']))
        register(ctx,combine(engine,'Engine body and bronze-lined bell'),'LG-450',i)
