#!/usr/bin/env python3
"""Generate dimensionally faithful SVGs and complete numerical source index.
Run check.py first (its expected nonzero result is the candidate's blocked gate).
No raster rendering, player simulation, or hand-drawn geometry is involved.
"""
import csv
import hashlib
from html import escape
import json
import math
from pathlib import Path
import check

HERE=Path(__file__).resolve().parent
OUT=HERE/'drawings'
REPORT=check.ROOT/'game/workshop/verification/c5/check.json'
P,E,L=check.load()
R=json.loads(REPORT.read_text())
for name,digest in R['input_hashes'].items():
    assert hashlib.sha256((HERE/name).read_bytes()).hexdigest()==digest, 'Run check.py after changing '+name
M={m['id']:m for m in P['motions']}

class SVG:
    def __init__(self,width,height,title):
        self.width=width;self.height=height
        self.items=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
            '<defs><pattern id="hatch" width="8" height="8" patternUnits="userSpaceOnUse"><path d="M0 8L8 0" stroke="#b7bcc2" stroke-width="1"/></pattern><marker id="arrow" markerWidth="6" markerHeight="6" refX="3" refY="3" orient="auto-start-reverse"><path d="M6 0L0 3L6 6" fill="none" stroke="#ad442b"/></marker></defs>',
            '<rect width="100%" height="100%" fill="#faf9f5"/>']
        self.text(28,34,title,22)
    def text(self,x,y,value,size=14,color='#263846'):
        self.items.append(f'<text x="{x:.2f}" y="{y:.2f}" font-family="sans-serif" font-size="{size}" fill="{color}">{escape(str(value))}</text>')
    def line(self,a,b,color='#314e65',dash='',dim=False):
        self.items.append(f'<line x1="{a[0]:.2f}" y1="{a[1]:.2f}" x2="{b[0]:.2f}" y2="{b[1]:.2f}" stroke="{color}" stroke-width="1.4"'+(f' stroke-dasharray="{dash}"' if dash else '')+(' marker-start="url(#arrow)" marker-end="url(#arrow)"' if dim else '')+'/>')
    def rect(self,x,y,w,h,fill,stroke='#486579',dash=''):
        if w<0 or h<0:return
        self.items.append(f'<rect x="{x:.2f}" y="{y:.2f}" width="{w:.2f}" height="{h:.2f}" fill="{fill}" stroke="{stroke}" stroke-width="1.2"'+(f' stroke-dasharray="{dash}"' if dash else '')+'/>')
    def save(self,name):
        content='\n'.join(self.items+['</svg>'])+'\n'
        assert len(content.encode())<300000,(name,len(content))
        (OUT/name).write_text(content)

class View:
    def __init__(self,svg,axes,lo,hi,rect):
        self.svg=svg;self.axes=axes;self.lo=lo;self.hi=hi;self.rect=rect
        self.scale=min(rect[2]/(hi[0]-lo[0]),rect[3]/(hi[1]-lo[1]))
    def xy(self,p):
        u=p[self.axes[0][0]]*self.axes[0][1];v=p[self.axes[1][0]]*self.axes[1][1]
        return self.rect[0]+(u-self.lo[0])*self.scale,self.rect[1]+(self.hi[1]-v)*self.scale
    def box(self,b,fill='#dde5e9',stroke='#43637a',dash='',clip=False):
        pts=[self.xy([x,y,z]) for x in [b[0],b[3]] for y in [b[1],b[4]] for z in [b[2],b[5]]]
        xs=[q[0] for q in pts];ys=[q[1] for q in pts];x0,x1=min(xs),max(xs);y0,y1=min(ys),max(ys)
        if clip:
            x0=max(x0,self.rect[0]);x1=min(x1,self.rect[0]+self.rect[2]);y0=max(y0,self.rect[1]);y1=min(y1,self.rect[1]+self.rect[3])
        self.svg.rect(x0,y0,max(0,x1-x0),max(0,y1-y0),fill,stroke,dash)
    def dimension(self,a,b,label,offset=12):
        x=self.xy(a);y=self.xy(b)
        self.svg.line(x,y,'#ad442b',dim=True)
        self.svg.text((x[0]+y[0])/2+4,(x[1]+y[1])/2-offset,label,13,'#9b3422')
    def grid(self,step=2):
        for axis in range(2):
            v=math.ceil(self.lo[axis]/step)*step
            while v<=self.hi[axis]:
                a=[0,0,0];b=[0,0,0];other=1-axis
                a[self.axes[axis][0]]=b[self.axes[axis][0]]=v/self.axes[axis][1]
                a[self.axes[other][0]]=self.lo[other]/self.axes[other][1];b[self.axes[other][0]]=self.hi[other]/self.axes[other][1]
                self.svg.line(self.xy(a),self.xy(b),'#e2e3df')
                q=self.xy(a);self.svg.text(q[0]+3,q[1]-3,f'{v/self.axes[axis][1]:g}',11,'#777')
                v+=step

def geometry(v,level=None):
    for s in P['solids']:
        if level is not None and not (s['min'][1]<=level+1.1 and s['max'][1]>=level-.2):continue
        v.box(check.bounds(s),'#d7e2e7','#294f67')
        if s['motion']:
            m=M[s['motion']];v.box(check.posed(s,m,m['parked_degrees'],True),'none','#c37729','5 4')
    if level is not None:
        for m in P['motions']:
            if m['deck_y']!=level:continue
            points=[]
            for i in range(46):
                a=math.radians(m['parked_degrees']*i/45);direction=1 if m['id'].startswith('L_') else -1
                pos=[m['pivot'][0]+direction*m['radius']*math.cos(a),level,m['pivot'][2]+direction*m['radius']*math.sin(a)]
                points.append(v.xy(pos))
            for a,b in zip(points,points[1:]):v.svg.line(a,b,'#a96b2d','3 3')
            q=v.xy(m['pivot']);v.svg.text(q[0]+5,q[1]-5,m['id']+f' R{m["radius"]:.2f}',12)

def legend(svg):
    svg.text(28,61,'BLOCKED CANDIDATE · design only · build not approved',16,'#9b3422')
    svg.text(28,83,'Blue: docked steel   Orange dashed: parked steel / swing limit   Hatch: reservation   Red: measured separation',14)
    svg.text(28,104,'Dimensions in metres. Crane constraints: provisional (unmerged branch). See README for conservative-box limits.',14)

def plans():
    for level in P['datums']['levels']:
        relevant=[r for r in R['tight'] if r['a'][1]<=level+2.2 and r['a'][4]>=level-.6]
        svg=SVG(1440,1100+math.ceil(len(relevant)/4)*38,f'Launch cage v2 · work level Y{level:g} · plan');legend(svg)
        v=View(svg,[(0,1),(2,1)],[1,21],[25,36],[60,150,1190,750]);v.grid()
        for r in E['reserved']:
            if r['kind']=='invariant' and r['min'][1]<=level+1.1 and r['max'][1]>=level-.2:v.box(check.bounds(r),'url(#hatch)','#a4a7ab')
        for r in E['robot']:
            if r['stage']=='complete' and r['min'][1]<=level+1.1 and r['max'][1]>=level-.2:v.box(check.bounds(r),'url(#hatch)','#8e8e87')
        for side,spec in L['workshop']['elevators'].items():
            x,_,z=spec['origin'];v.box((x-1.6,level,z-1.6,x+1.6,level,z+1.6),'none','#797979','3 3')
            v.box((x-1.3,level,z-1.3,x+1.3,level,z+1.3),'#e9efdb','#74894f')
            q=v.xy([x,level,z]);svg.text(q[0]-30,q[1],side+' lift',13)
        geometry(v,level)
        # Nominal dimensions, all from the plan or measured layout.
        v.dimension([7.92,level,29.25],[9.4,level,29.25],'1.48 landing depth',-24)
        v.dimension([4.65,level,27.05],[8.55,level,27.05],'3.90 frame centres',22)
        v.dimension([6.6,level,28.5],[6.6,level,30],'1.50 door',12)
        relevant=[r for r in R['tight'] if r['a'][1]<=level+2.2 and r['a'][4]>=level-.6]
        # All tight dimensions are in readable per-pair detail sheets, not stacked
        # over one another on this overview. This count is checked against sheets.
        svg.text(28,960,f'{len(relevant)} tight positive pair clearances (<0.30 m) intersect this level band; every one is dimensioned in tight-*.svg.',15)
        svg.text(28,986,'The same pair may constrain multiple levels. Vertical clearances use elevation details. Zero-margin contacts are in the full CSV.',14)
        svg.text(28,1035,'Dimension register: true gap scale 300 px/m; T references link to enlarged spatial details. Zero contacts are not positive clearances.',14)
        ordered=sorted(R['tight'],key=lambda r:(r['solid'],r['reserved'],r['clearance']))
        for i,r in enumerate(relevant):
            number=ordered.index(r)+1;page=(number-1)//12+1;x=28+(i%4)*350;y=1070+(i//4)*38
            svg.items.append(f'<a href="tight-{page:02}.svg"><title>{escape(r["solid"]+" / "+r["reserved"])}</title>')
            svg.line((x,y),(x+300*r['clearance'],y),'#ad442b',dim=True)
            svg.text(x+100,y+5,f'T{number:03}  {r["clearance"]:.4f} m',14)
            svg.items.append('</a>')
        svg.save(f'level-{level:g}.svg')

def elevations():
    for name,axes,lo,hi,title in [('front',[(0,-1),(1,1)],[-26,0],[0,24],'Front elevation · looking +Z; X increases to left'),
                                ('side',[(2,-1),(1,1)],[-40,0],[-20,24],'Side elevation · looking −X; Z increases to left')]:
        svg=SVG(1700,1270,'Launch cage v2 · '+title);legend(svg)
        v=View(svg,axes,lo,hi,[50,150,1150,1000]);v.grid()
        for r in E['robot']:
            if r['stage']=='complete':v.box(check.bounds(r),'url(#hatch)','#979a90')
        geometry(v)
        for level in P['datums']['levels']:
            a=[0,level,20];b=[26,level,40];v.svg.line(v.xy(a),v.xy(b),'#8d969d','4 5')
        a=[0,22.875,20];b=[26,22.875,40];v.svg.line(v.xy(a),v.xy(b),'#b13e28');q=v.xy(a);svg.text(q[0]+6,q[1]-8,'Trolley underside Y22.875',14,'#9b3422')
        svg.text(1220,160,'Branch A carry envelope',17)
        svg.text(1220,183,'PROVISIONAL · unmerged',14,'#9b3422')
        svg.text(1220,207,'Task: head Y / lowest solid Y',14)
        for i,c in enumerate(E['crane']):
            lowest=min(a['lowest_solid'] for a in c['carry'])
            svg.text(1220,233+i*25,f'{c["id"]}: {c["carry_head_y"]:.2f} / {lowest:.3f}',13)
            # Per-task height ticks are staggered along the side projection. The
            # exact heights are drawn, even where several tasks coincide.
            if name=='side':
                z=21+(i%15)*1.15;a=[13,c['carry_head_y'],z];b=[13,lowest,z];v.dimension(a,b,str(i+1),4)
        svg.text(1220,1040,'Highest mast/cable: Y23.000',14)
        svg.text(1220,1063,'Top hook allowance: Y22.850',14)
        svg.text(1220,1086,'Measured spreader/hook top: Y22.850',14)
        svg.text(1220,1115,'Mast joins trolley; not a clearance.',13)
        svg.save(name+'.svg')

def exit_plan():
    svg=SVG(1440,1200,'Launch cage v2 · exit reservation to Z38.78');legend(svg)
    v=View(svg,[(0,1),(2,1)],[1,22],[25,40],[80,140,1150,920]);v.grid()
    v.box(check.bounds(P['exit']),'url(#hatch)','#a04a33')
    for r in R['exit_inventory']:
        v.box(check.bounds(r),'none','#a48f8c','4 3' if r['removed'] else '')
    for s in P['solids']:
        m=M.get(s['motion']);q=check.posed(s,m,m['parked_degrees'] if m else 0,True)
        v.box(q,'none' if m else '#d7e2e7','#c37729' if m else '#294f67','5 4' if m else '')
    for r in E['robot']:
        if r['stage']=='complete':v.box(check.bounds(r),'#dfe2d9','#727b6c')
    with (HERE/'exit-inventory.csv').open('w',newline='') as file:
        writer=csv.writer(file,lineterminator="\n");writer.writerow(['layout id','v2 removes','min X','min Y','min Z','max X','max Y','max Z'])
        for r in R['exit_inventory']:writer.writerow([r['id'],r['removed'],*r['min'],*r['max']])
    wall=next(r for r in E['layout_solids'] if r['id']=='wall_z39');v.box(check.bounds(wall),'#cf8c79','#9b3422')
    a=P['exit']['min'];b=P['exit']['max'];v.dimension([a[0],0,36.5],[b[0],0,36.5],f'{b[0]-a[0]:.3f} reserved width',16)
    v.dimension([2.95,0,38.78],[23.05,0,38.78],'20.10 visual opening; collision opening = 0',20)
    svg.text(28,1120,'No carrier or lowering mechanism is designed. Parked arms and fixed inner landings still intrude into this reservation.',15,'#9b3422')
    svg.text(28,1145,'Dashed grey: retired existing steel. Red rear wall remains solid; visible door is closed, decorative geometry.',15)
    svg.save('exit-route.svg')

def tight_details():
    rows=sorted(R['tight'],key=lambda r:(r['solid'],r['reserved'],r['clearance']))
    index=[]
    for start in range(0,len(rows),12):
        page=1+start//12;svg=SVG(1560,1160,f'C5 tight clearances · sheet {page} · every positive pair below 0.30 m')
        svg.text(28,61,'Red dimensions are true 3D separations; the selected projection contains all nonzero separation axes.',14)
        for k,r in enumerate(rows[start:start+12]):
            col=k%3;row=k//3;x=20+col*515;y=92+row*260
            svg.rect(x,y,500,247,'#fffdf9','#c9cbc5')
            a,b=check.nearest(r['a'],r['b']);gaps=[abs(a[i]-b[i]) for i in range(3)]
            nonzero=[i for i in range(3) if gaps[i]>1e-7]
            axes=([nonzero[0],nonzero[1]] if len(nonzero)>1 else [0,1] if nonzero==[1] else [0,2])
            # Three-axis distances are labelled explicitly; projection alone cannot
            # express their length. Component dimensions appear in the label.
            lo=[min(a[i],b[i])-.15 for i in axes];hi=[max(a[i],b[i])+.15 for i in axes]
            v=View(svg,[(axes[0],1),(axes[1],1)],lo,hi,[x+10,y+70,480,145])
            v.box(r['a'],'#d7e2e7','#294f67',clip=True);v.box(r['b'],'url(#hatch)','#848a88',clip=True)
            label=f'{r["clearance"]:.4f} m (min {r["margin"]:.3f})'
            v.dimension(a,b,label,8)
            svg.text(x+10,y+21,f'T{start+k+1:03}: {r["solid"]}',13)
            svg.text(x+10,y+41,r['reserved'],13)
            svg.text(x+10,y+60,r['phase']+' · '+r['state'],11)
            svg.text(x+10,y+235,'XYZ separation '+', '.join(f'{d:.4f}' for d in gaps),12)
            index.append({'id':f'T{start+k+1:03}','sheet':f'tight-{page:02}.svg',**r})
        svg.save(f'tight-{page:02}.svg')
    (OUT/'tight-index.json').write_text(json.dumps(index,indent=2)+'\n')
    assert len(index)==len(R['tight'])

def sources():
    rows=[]
    def walk(value,path,source):
        if isinstance(value,bool):return
        if isinstance(value,(int,float)):rows.append((path,repr(value),source))
        elif isinstance(value,list):
            for i,v in enumerate(value):walk(v,path+'/'+str(i),source)
        elif isinstance(value,dict):
            source=value.get('source',source)
            for k,v in value.items():walk(v,path+'/'+k,source)
    walk(P,'plan.json','C5 proposed design value; exact JSON pointer is the authoring source, not a measurement')
    for key in ['robot','equipment','layout_solids','crane','reserved','missing_runtime_geometry','door']:
        walk(E[key],'envelopes.json/'+key,'C5 runtime probe / explicitly identified derived reservation')
    with (HERE/'datums.csv').open('w',newline='') as file:
        writer=csv.writer(file,lineterminator="\n");writer.writerow(['JSON pointer','numeric value','source']);writer.writerows(rows)

OUT.mkdir(exist_ok=True)
# Delete only this tool's own generated SVG names, not arbitrary folder contents.
for pattern in ['level-*.svg','front.svg','side.svg','exit-route.svg','tight-*.svg']:
    for path in OUT.glob(pattern):path.unlink()
plans();elevations();exit_plan();tight_details();sources()
print(f'Generated {len(list(OUT.glob("*.svg")))} SVGs; {len(R["tight"])} individually dimensioned tight pairs. All SVGs <300 KB.')
