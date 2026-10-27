#!/usr/bin/env python3
"""Generate exactly seven C6 overview SVGs; no close-up or pair inventories."""
import html
import math
import sys
from pathlib import Path
sys.dont_write_bytecode = True
from check import read, mirror

OUT = Path(__file__).resolve().parent / 'drawings'

class Sheet:
    def __init__(self,title,axes,limits):
        self.axes=axes;self.limits=limits;self.s=16
        self.parts=['<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="950" viewBox="0 0 1200 950">',
            '<style>text{font:14px sans-serif;fill:#162a38}.small{font-size:12px}.dim{stroke:#334155;stroke-width:1;fill:none}.shape{stroke-width:1.5}</style>',
            '<rect width="1200" height="950" fill="#fafafa"/>']
        self.text(35,32,title,20)
        self.text(35,56,'C6 · DESIGN ONLY · BUILD NOT APPROVED · metres · mirror X13')
        self.text(35,79,'Blue: tower/pocket · green: work path · amber: unresolved support envelope · red: exit reservation')
    def xy(self,p):
        a,b=self.axes;u,v=p[a],p[b]
        return 85+(u-self.limits[0])*self.s,105+(self.limits[3]-v)*self.s
    def text(self,x,y,text,size=14):
        self.parts.append(f'<text x="{x:.1f}" y="{y:.1f}" style="font-size:{size}px">{html.escape(text)}</text>')
    def rect(self,b,color,label='',opacity=.22):
        a,c=self.axes;x,y=self.xy(b['min']);xx,yy=self.xy(b['max'])
        self.parts.append(f'<rect x="{min(x,xx):.1f}" y="{min(y,yy):.1f}" width="{abs(xx-x):.1f}" height="{abs(yy-y):.1f}" fill="{color}" fill-opacity="{opacity}" stroke="{color}" class="shape"/>')
        if label:self.text(min(x,xx)+3,min(y,yy)+16,label,12)
    def line(self,a,b,color='#475569',dash=False):
        x,y=self.xy(a);xx,yy=self.xy(b)
        self.parts.append(f'<path d="M{x:.1f},{y:.1f} L{xx:.1f},{yy:.1f}" stroke="{color}" fill="none"'+(' stroke-dasharray="5 4"' if dash else '')+'/>')
    def dim(self,a,b,label,offset=-10):
        self.line(a,b);x,y=self.xy(a);xx,yy=self.xy(b)
        self.text((x+xx)/2+3,(y+yy)/2+offset,label,12)
        for px,py in [(x,y),(xx,yy)]:self.parts.append(f'<path d="M{px-4},{py-4} l8,8" class="dim"/>')
    def arc(self,x,z,y,r,left):
        points=[]
        for i in range(19):
            t=i*math.pi/36
            points.append([x+(1 if left else -1)*r*math.cos(t),y,z+r*math.sin(t)])
        for a,b in zip(points,points[1:]):self.line(a,b,'#19805d',True)
    def notes(self,lines):
        for i,t in enumerate(lines):self.text(735,125+i*25,t,13)
    def save(self,name):
        self.parts.append('</svg>');(OUT/name).write_text('\n'.join(self.parts)+'\n')

def main():
    p,e=read();OUT.mkdir(exist_ok=True);c=p['catwalk']
    for a in c['arms']:
        y=a['level'];z=a['root_z'];x=c['root_x'];w=c['deck_width']/2
        s=Sheet(f'Work level Y{y:g} — plan (north / exit is up)',(0,2),(-2,28,20,50))
        s.rect(p['exit']['corridor'],'#bd4343','11.0 exit lane',.06)
        for t in p['towers']:s.rect(t,'#24639a',t['id']+' tower')
        for l in p['lifts']:
            xx,_,zz=l['centre'];s.rect({'min':[xx-1.6,0,zz-1.6],'max':[xx+1.6,18.6,zz+1.6]},'#24639a','lift')
        for r in e['robot']:
            if r['min'][1]<=y+2.2 and r['max'][1]>=y-.2:s.rect(r,'#64748b',r['id'],.12)
        for b in [dict(min=[x-w,y,z-w],max=[x+w,y,41.7]),dict(min=[x,y,z-w],max=[x+a['length'],y,z+w])]:
            s.rect(b,'#19805d');s.rect(mirror(b),'#19805d')
        for b in [c['return_left'],c['landing_left']]:s.rect(b,'#19805d');s.rect(mirror(b),'#19805d')
        for side in [True,False]:
            xx=x if side else 26-x;s.arc(xx,z,y,a['length'],side)
            s.line([xx,y,z],[xx,y,41],'#19805d',True)
        for root,cap in zip(p['hip_support']['roots'],p['hip_support']['caps']):s.line(root,cap,'#bd7c16',True)
        s.rect(p['building']['door'],'#bd4343')
        s.dim([.5,y,46],[7,y,46],'6.50 tower')
        s.dim([7.5,y,24],[18.5,y,24],'11.00 exit')
        s.dim([6,y,49],[20,y,49],'14.00 door')
        s.dim([x,y,z],[x+a['length'],y,z],f'{a["length"]:.2f} arm',24)
        s.dim([0,y,40],[0,y,45],'5.00 tower',0)
        s.line([13,y,21],[13,y,49],'#64748b',True)
        s.notes([f'Deck top Y{y:g}; thickness 0.20',
                 'Tower footprints X0.5..7 /19..25.5',
                 'Both towers Z40..45; top Y18.6',
                 'Lift centres X2.4 /23.6, Z43.2',
                 'Shaft 3.20 square; car 2.60 square',
                 'Clear walking 1.20; landing 1.50',
                 'Return lane X3.7..5.2, mirrored',
                 f'Root X6.2 /19.8, Z{z:g}',
                 'Swing 90° aft; mirror handedness',
                 'Arm retracts 4.30 to3.00 first',
                 f'Root then retracts {41-z:.2f} aft',
                 'Park: X5.5..6.9, Z40.3..44.7',
                 'Guards 1.10; flush seams 0.02',
                 'Amber: hip support needs resolution',
                 'Empty paths before stow/rotation',
                 'No rear crossover or crosshead'])
        s.save(f'level-{y:g}.svg')
    s=Sheet('Front elevation — looking +Z',(0,1),(-16,42,0,28))
    s.s=11
    s.rect(p['building']['bounds'],'#64748b','proposed building 54 m wide',.03)
    s.rect(p['building']['door'],'#bd4343','14 ×22 opening',.04)
    for t in p['towers']:s.rect(t,'#24639a',t['id'])
    for r in e['robot']:s.rect(r,'#64748b',r['id'],.12)
    for y in p['levels']:
        s.line([.5,y,0],[7,y,0],'#19805d');s.line([19,y,0],[25.5,y,0],'#19805d')
        s.text(*s.xy([26,y,0]),f'Y{y:g}',12)
    s.line([-12.5,23.4,0],[25.3,23.4,0],'#475569')
    s.dim([6,22.8,0],[20,22.8,0],'14.00 aperture')
    s.dim([28,0,0],[28,22,0],'22.00 high')
    s.dim([.5,19.5,0],[7,19.5,0],'6.50')
    s.notes(['Hip datum (13,10.6,26) unchanged',
             'Caps Y10.97; four hold-downs',
             'Tower top Y18.6; no intertower tie',
             'Crane rail/trolley unchanged',
             'Car floors 0.15 /8.4 /11.2 /14 /16.4',
             'Rear door leaves slide 7.50 outboard',
             'Building X−14..40, roof Y26',
             'Exit robot remains at raised height'])
    s.save('front.svg')
    s=Sheet('Side elevation — looking −X',(2,1),(18,55,0,28))
    s.rect(p['exit']['corridor'],'#bd4343','exit height 21.0',.04)
    for t in p['towers'][:1]:s.rect(t,'#24639a','tower Z40..45')
    for r in e['robot']:s.rect(r,'#64748b',r['id'],.12)
    for a in c['arms']:
        y=a['level'];s.line([0,y,a['root_z']],[0,y,41],'#19805d')
    s.line([0,23,20],[0,23,38],'#475569');s.line([0,26,20],[0,26,48],'#475569')
    s.line(p['hip_support']['roots'][0],p['hip_support']['caps'][0],'#bd7c16',True)
    s.dim([0,24,40],[0,24,45],'5.00')
    s.dim([0,0,48],[0,22,48],'door 22.00',-8)
    s.dim([0,1,22],[0,1,54],'32.00 reserved exit run',-12)
    s.notes(['Crane routes end before aft towers',
             'Minimum route/tower gap: see checker',
             'Hoist attachment Y23 remains fixed',
             'Side view overlays both towers',
             '11.8 m hip root retraction toZ41',
             '9.0 m upper root retraction toZ41',
             'Long hip beams are unresolved',
             'No lowering required by exit envelope',
             'Level floor continues toZ54 apron'])
    s.save('side.svg')
    s=Sheet('Exit route — +Z roll-out, all roots/supports stowed',(0,2),(-2,28,20,55))
    s.rect(p['exit']['corridor'],'#bd4343','11.00 ×32.00 reservation',.08)
    for t in p['towers']:s.rect(t,'#24639a',t['id'])
    s.rect(p['exit']['carrier'],'#19805d','10 ×8 carrier')
    for b in p['building']['door_leaf_pockets']:s.rect(b,'#bd4343','open leaf')
    s.rect(p['building']['door'],'#bd4343','door Z48',.03)
    s.line([13,0,30],[13,0,54],'#19805d')
    s.dim([7.5,0,52],[18.5,0,52],'11.00 lane')
    s.dim([6,0,49],[20,0,49],'14.00 aperture')
    s.notes(['Lane X7.5..18.5, Y0..21, Z22..54',
             'Carrier X8..18, Z22.5..30.5',
             'Chassis with adjustable sole pads',
             'Raised robot retained: no datum move',
             'Carrier takes weight before jaw release',
             'Hip supports retract completely',
             'All eight work arms/roots inside towers',
             'Door leaves in outboard pockets',
             'Door opens only with clear local motion',
             'Flush floor; no guide rail at threshold',
             'No fixed steel crosses the exit',
             'Carrier/transfer not yet engineered'])
    s.save('exit-route.svg')
    print('Generated seven C6 overview sheets.')

if __name__=='__main__':main()
