"""Original Dungepm art study. Run with Blender --background --python this_file.
All geometry, textures and animations authored for this project. Seeded/rebuildable.
Coordinates: metres, Blender Z up, character forward -Y (Godot +Z).
"""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
R = random.Random(47)
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'jogo/assets/originais'
TEX = ROOT/'arte/texturas'
OUT.mkdir(parents=True,exist_ok=True); TEX.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
for d in list(bpy.data.collections):
 if d.name != 'Collection': bpy.data.collections.remove(d)
MATS = {}; ASSETS={}; CUR=[]

def mat(name, base, kind='stone', rough=0.95, metallic=0):
 m=bpy.data.materials.new(name);m.use_nodes=True
 bs=next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
 if bs is None:
  bs=m.node_tree.nodes.new('ShaderNodeBsdfPrincipled');out=m.node_tree.nodes.new('ShaderNodeOutputMaterial');m.node_tree.links.new(bs.outputs['BSDF'],out.inputs['Surface'])
 bs.inputs['Roughness'].default_value=rough;bs.inputs['Metallic'].default_value=metallic
 img=bpy.data.images.new(name+'_128px',width=128,height=128,alpha=False)
 rng=random.Random(name); px=[]
 for y in range(128):
  for x in range(128):
   small=rng.uniform(-.045,.045)
   cloud=math.sin(x*.092+y*.041)*math.sin(y*.075-x*.018)*.055
   tone=small+cloud
   if kind=='wood': tone+=math.sin(x*.8+math.sin(y*.04)*1.9)*.034+(0.055 if x%24==0 else 0)
   elif kind=='cloth': tone+=(.018 if (x+y)%2==0 else -.018)+(.01 if y%6==0 else -.01)
   elif kind=='skin': tone*=.23
   elif kind=='metal': tone*=.5
   elif kind=='stone':
    if rng.random()<.025: tone-=.1
    tone-=.04*max(0,math.sin(x*.048)*math.cos(y*.065))
   px.extend([max(.012,min(.95,c+tone)) for c in base]+[1])
 img.pixels.foreach_set(px)
 img.filepath_raw=str(TEX/(name+'.png'));img.file_format='PNG';img.save();img.pack()
 tx=m.node_tree.nodes.new('ShaderNodeTexImage');tx.image=img;tx.interpolation='Closest'
 m.node_tree.links.new(tx.outputs['Color'],bs.inputs['Base Color'])
 MATS[name]=m;return m

mat('calcario',(0.38,.38,.34));mat('pedra_escura',(.29,.30,.28));mat('argamassa',(.21,.23,.21));mat('piso',(.35,.35,.30));mat('piso_b',(.39,.38,.32));mat('musgo',(.22,.25,.17))
mat('carvalho',(.27,.19,.115),'wood');mat('madeira_clara',(.36,.28,.18),'wood');mat('ferro',(.18,.19,.18),'metal',.72,.35);mat('aco',(.47,.50,.49),'metal',.6,.48)
mat('linho',(.42,.41,.31),'cloth');mat('tunika',(.29,.32,.25),'cloth');mat('calca',(.25,.24,.21),'cloth');mat('couro',(.20,.14,.095),'wood');mat('pele',(.55,.40,.29),'skin');mat('cabelo',(.12,.09,.065),'cloth');mat('saco',(.40,.34,.24),'cloth');mat('ceramica',(.35,.26,.19));mat('negro',(.045,.04,.03),'cloth')

def begin(name):
 global CUR
 CUR=[]; ASSETS[name]=CUR

def finish(obj, material, bone=None, bevel=0):
 obj.data.materials.append(MATS[material]); CUR.append(obj)
 if bevel:
  mod=obj.modifiers.new('Arestas gastas','BEVEL');mod.width=bevel;mod.segments=1
  bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=mod.name)
 if bone: obj['bone']=bone
 return obj

def box(name, loc, size, material, bone=None, bevel=0.005):
 bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
 o=bpy.context.object;o.name=name;o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 return finish(o,material,bone,bevel)

def beam(name,a,b,r1,r2,material,bone=None,n=8):
 a,b=Vector(a),Vector(b);vec=b-a
 bpy.ops.mesh.primitive_cone_add(vertices=n,radius1=r1,radius2=r2,depth=vec.length,location=(a+b)/2)
 o=bpy.context.object;o.name=name;o.rotation_euler=vec.to_track_quat('Z','Y').to_euler()
 bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 return finish(o,material,bone)

def rings(name, levels, material, bone=None, n=8):
 # Each level: center xyz, radius x, radius y. Forward face at -Y.
 verts=[];faces=[]
 for (x,y,z,rx,ry) in levels:
  for i in range(n):
   a=2*math.pi*i/n+math.pi/8
   verts.append((x+math.cos(a)*rx,y+math.sin(a)*ry,z))
 for j in range(len(levels)-1):
  for i in range(n):faces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
 faces.extend([tuple(reversed(range(n))),tuple((len(levels)-1)*n+i for i in range(n))])
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
 o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o)
 uv=mesh.uv_layers.new(name='UVMap')
 for poly in mesh.polygons:
  for li in poly.loop_indices:
   vi=mesh.loops[li].vertex_index;uv.data[li].uv=((vi%n)/n,(vi//n)/(len(levels)-1))
 return finish(o,material,bone)

# Ground tile: four irregular slabs with fine raised seams, two variants.
for variant in range(2):
 begin('piso'+('_b' if variant else ''))
 box('Base de argamassa',(0,0,-.065),(1,1,.12),'argamassa',bevel=0)
 for row in range(2):
  for col in range(2):
   o=box('Laje',(-.25+col*.5,-.25+row*.5,-.011+R.uniform(-.002,.002)),(.493,.493,.085),'piso' if (row+col+variant)%2 else 'piso_b',bevel=.012)
   # Hairline cracks are physical slivers, using our own material.
   if (col+row+variant)%3==0:
    crack=box('Fissura',(-.30+col*.5,-.30+row*.5,.033),(.14,.008,.001),'pedra_escura',bevel=0);crack.rotation_euler.z=.55
begin('parede')
box('Miolo',(0,0,1.10),(2,.28,2.20),'argamassa',bevel=0)
for row in range(8):
 # Staggered masonry; end stones fitted to a 2 metre module.
 edges=[-1,-.63,.04,.68,1] if row%2 else [-1,-.35,.31,1]
 for a,b in zip(edges,edges[1:]):
  box('Pedra de alvenaria',((a+b)/2,R.uniform(-.008,.008),.14+row*.274),(b-a-.012,.35+R.uniform(-.015,.015),.26),'calcario' if R.random()>.26 else 'pedra_escura',bevel=.018)
# Footline moisture and cap.
box('Rodape escurecido',(0,-.185,.12),(2,.035,.15),'pedra_escura',bevel=.008)
box('Coroamento',(0,0,2.235),(2.04,.39,.10),'calcario',bevel=.015)
begin('pilar')
box('Pe',(0,0,.08),(.49,.49,.16),'pedra_escura',bevel=.02)
for i in range(8):box('Bloco',(0,0,.30+i*.26),(.35,.36,.252),'calcario' if i%3 else 'pedra_escura',bevel=.014)
box('Topo',(0,0,2.29),(.46,.46,.15),'calcario',bevel=.016)
begin('porta')
for x in [-.68,.68]:
 for i in range(7):box('Ombreira',(x,0,.15+i*.30),(.25,.42,.29),'calcario',bevel=.016)
box('Verga',(0,0,2.20),(1.64,.45,.25),'calcario',bevel=.016)
for i in range(6):box('Tabua da porta',(-.5+i*.2,0,1.04),(.193,.095,2.02),'carvalho',bevel=.006)
for z in [.35,1.64]:box('Travessa',(0,-.07,z),(1.12,.065,.10),'ferro',bevel=.003)
box('Fechadura',(.39,-.095,1.04),(.075,.04,.16),'ferro')
# Chests: planks and a curved lid, wrought iron bands.
begin('bau')
for i in range(5):box('Tabua do corpo',(-.38+i*.19,0,.24),(.182,.47,.43),'carvalho',bevel=.006)
for i in range(7):
 a=-math.pi/2+math.pi*(i+.5)/7
 o=box('Tabua da tampa',(0,math.sin(a)*.25,.465+math.cos(a)*.16),(.96,.118,.065),'madeira_clara',bevel=.006);o.rotation_euler.x=-a*.6
for x in [-.34,.34]:
 for y in [-.245,.245]:box('Faixa de ferro',(x,y,.24),(.045,.018,.47),'ferro',bevel=.002)
 for i in range(9):
  a=-math.pi/2+math.pi*(i+.5)/9
  o=box('Ferragem da tampa',(x,math.sin(a)*.267,.475+math.cos(a)*.171),(.052,.092,.023),'ferro',bevel=.001);o.rotation_euler.x=-a*.65
box('Trinco',(0,-.273,.40),(.083,.035,.17),'ferro')
for x in [-.40,.40]:
 for y in [-.17,.17]:box('Pe do bau',(x,y,.043),(.09,.09,.07),'couro')
begin('barril')
rings('Aduegas',[(0,0,.04,.26,.26),(0,0,.13,.29,.29),(0,0,.40,.32,.32),(0,0,.70,.28,.28),(0,0,.76,.26,.26)],'carvalho',n=12)
for z,r in [(.14,.295),(.37,.326),(.66,.294)]:
 rings('Aro',[(0,0,z-.025,r,r),(0,0,z+.025,r,r)],'ferro',n=12)
for i in range(5):
 y=-.20+i*.10;w=2*math.sqrt(max(.001,.257**2-y**2))
 box('Tampa',(0,y,.769),(w,.095,.025),'madeira_clara',bevel=.003)
begin('mesa')
for i in range(5):box('Tampo',(0,-.30+i*.15,.77),(1.4,.143,.064),'madeira_clara',bevel=.008)
for x in [-.55,.55]:
 for y in [-.25,.25]:box('Perna',(x,y,.37),(.085,.085,.72),'carvalho',bevel=.005)
box('Travessa baixa',(0,0,.24),(1.14,.08,.10),'carvalho')
begin('banco')
for y in [-.095,.095]:box('Assento',(0,y,.44),(1.03,.184,.065),'madeira_clara')
for x in [-.42,.42]:
 for y in [-.10,.10]:box('Perna',(x,y,.205),(.08,.08,.41),'carvalho')
begin('caixote')
for x in [-.31,.31]:
 for i in range(4):box('Tabua lateral',(x,-.225+i*.15,.30),(.04,.14,.60),'carvalho')
for y in [-.31,.31]:
 for i in range(4):box('Tabua frente',(-.225+i*.15,y,.30),(.14,.04,.60),'madeira_clara')
for i in range(4):box('Tabua topo',(-.225+i*.15,0,.62),(.14,.65,.04),'carvalho')
for x in [-.28,.28]:
 for y in [-.32,.32]:box('Reforco',(x,y,.31),(.063,.063,.65),'carvalho')
begin('saco')
rings('Saco de mantimentos',[(0,0,.02,.16,.13),(0,0,.12,.23,.18),(.02,0,.32,.21,.15),(0,0,.47,.09,.065),(.01,0,.52,.075,.045)],'saco',n=9)
rings('Amarracao',[(0,0,.462,.093,.07),(0,0,.48,.09,.068)],'couro',n=8)
begin('vaso')
rings('Vaso',[(0,0,.01,.11,.11),(0,0,.12,.19,.19),(0,0,.26,.20,.20),(0,0,.39,.11,.11),(0,0,.43,.12,.12),(0,0,.445,.09,.09),(0,0,.35,.085,.085)],'ceramica',n=12)
begin('tocha')
beam('Cabo',(0,0,0),(0,0,.62),.027,.040,'carvalho',n=8)
beam('Estopa',(0,0,.45),(0,0,.69),.055,.040,'linho',n=8)
for z in [.47,.56,.63]:beam('Arame',(0,0,z),(0,0,z+.018),.059,.059,'ferro',n=8)
box('Suporte',(0,.045,.24),(.06,.16,.09),'ferro')
begin('espada')
# Long straight blade, cross guard, leather grip. Origin at the grip.
verts=[(-.038,0,.10),(.038,0,.10),(-.026,0,.73),(.026,0,.73),(0,0,.87),(0,-.015,.10),(0,-.009,.73),(0,.015,.10),(0,.009,.73)]
faces=[(0,2,6,5),(5,6,3,1),(2,4,6),(6,4,3),(0,7,8,2),(7,1,3,8),(2,8,4),(8,3,4),(0,5,1,7)]
mesh=bpy.data.meshes.new('Lamina');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('Lamina',mesh);bpy.context.collection.objects.link(o);finish(o,'aco')
box('Guarda',(0,0,.082),(.23,.043,.040),'ferro',bevel=.006)
beam('Empunhadura',(0,0,-.09),(0,0,.065),.024,.024,'couro',n=8)
beam('Pomo',(0,0,-.13),(0,0,-.09),.038,.03,'ferro',n=8)

# Gameplay props in metres; authored here alongside the study library.
begin('lanca')
beam('Haste',(0,0,-.72),(0,0,.72),.023,.019,'carvalho',n=8)
beam('Encaixe',(0,0,.65),(0,0,.84),.033,.023,'ferro',n=8)
beam('Ponta',(0,0,.80),(0,0,1.13),.058,0,'aco',n=4)
begin('escada')
for i in range(5):box('Degrau',(0,i*.32,.12+i*.12),(1.7,.34,.24+i*.24),'calcario',bevel=.015)
begin('rochas')
for i in range(4):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.18,location=(R.uniform(-.25,.25),R.uniform(-.22,.22),.1))
 o=bpy.context.object;o.scale=(1.3,1,.6);finish(o,'pedra_escura')
begin('catre')
for x in [-.35,.35]:
 for y in [-.85,.85]:box('Pe',(x,y,.18),(.09,.09,.36),'carvalho')
box('Estrado',(0,0,.35),(.85,1.95,.10),'carvalho')
box('Colchao de palha',(0,0,.44),(.78,1.86,.12),'saco',bevel=.04)
box('Manta',(0,-.2,.51),(.80,1.2,.035),'tunika',bevel=.015)
box('Travesseiro',(0,.64,.54),(.56,.35,.12),'linho',bevel=.04)
begin('bandagem')
beam('Linho enrolado',(-.07,0,.055),(.07,0,.055),.065,.065,'linho',n=12)
begin('moeda')
beam('Disco',(0,0,.01),(0,0,.03),.07,.07,'aco',n=12)
begin('selo')
box('Selo de ferro',(0,0,.03),(.24,.18,.05),'ferro',bevel=.01)
for x in [-.06,0,.06]:box('Inscricao',(x,0,.058),(.014,.11,.009),'aco',bevel=0)

# Human adventurer. Head is ~1/7.8 of height rather than chibi proportions.
begin('aventureiro')
rig_data=bpy.data.armatures.new('Esqueleto humano');rig=bpy.data.objects.new('Aventureiro',rig_data);bpy.context.collection.objects.link(rig);CUR.append(rig)
bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
bones={}
def bone(name,a,b,parent=None):
 e=rig_data.edit_bones.new(name);e.head=a;e.tail=b
 if parent:e.parent=rig_data.edit_bones[parent]
 bones[name]=(a,b);return e
bone('root',(0,0,0),(0,0,.15));bone('pelvis',(0,0,.91),(0,0,1.05),'root');bone('spine',(0,0,1.05),(0,0,1.42),'pelvis');bone('neck',(0,0,1.42),(0,0,1.56),'spine');bone('head',(0,0,1.56),(0,0,1.77),'neck')
for sign,side in [(-1,'right'),(1,'left')]:
 bone('thigh-'+side,(sign*.095,0,.94),(sign*.10,-.008,.55),'pelvis');bone('shin-'+side,(sign*.10,-.008,.55),(sign*.105,.018,.17),'thigh-'+side);bone('foot-'+side,(sign*.105,.018,.17),(sign*.105,-.17,.075),'shin-'+side)
 bone('arm-'+side,(sign*.22,0,1.42),(sign*.28,.005,1.15),'spine');bone('forearm-'+side,(sign*.28,.005,1.15),(sign*.30,-.025,.94),'arm-'+side);bone('hand-'+side,(sign*.30,-.025,.94),(sign*.30,-.04,.85),'forearm-'+side)
bpy.ops.object.mode_set(mode='OBJECT')
for sign,side in [(-1,'right'),(1,'left')]:
 x=sign*.1
 rings('Coxa '+side,[(x,0,.56,.078,.08),(x,0,.88,.102,.097),(x,0,.97,.096,.083)],'calca','thigh-'+side)
 rings('Canela '+side,[(x,.015,.19,.053,.055),(x,0,.38,.070,.074),(x,0,.57,.077,.078)],'calca','shin-'+side)
 rings('Cano da bota '+side,[(x,.015,.09,.066,.073),(x,.015,.29,.062,.067),(x,.012,.38,.07,.075)],'couro','shin-'+side)
 boot=box('Bota '+side,(x,-.045,.07),(.139,.26,.13),'couro','foot-'+side,.023)
 box('Sola '+side,(x,-.045,.021),(.147,.265,.031),'negro','foot-'+side,.008)
 beam('Manga '+side,(sign*.22,0,1.41),(sign*.28,.005,1.17),.098,.074,'tunika','arm-'+side,n=8)
 beam('Antebraco '+side,(sign*.28,.005,1.17),(sign*.30,-.025,.94),.076,.052,'linho','forearm-'+side,n=8)
 beam('Bracelete '+side,(sign*.292,-.015,1.04),(sign*.30,-.025,.947),.060,.055,'couro','forearm-'+side,n=8)
 box('Mao '+side,(sign*.30,-.035,.9),(.064,.064,.115),'pele','hand-'+side,.014)
rings('Saia da tunica',[(0,0,.83,.225,.139),(0,0,1.00,.185,.12),(0,0,1.12,.19,.12)],'tunika','pelvis')
rings('Peito',[(0,0,1.01,.18,.115),(0,0,1.22,.207,.128),(0,0,1.42,.23,.137),(0,0,1.47,.145,.11)],'tunika','spine')
rings('Cinto',[(0,-.002,.997,.19,.133),(0,-.002,1.047,.189,.132)],'couro','pelvis')
box('Fivela',(0,-.137,1.023),(.062,.020,.058),'ferro','pelvis')
box('Fivela interna',(0,-.150,1.023),(.032,.005,.026),'couro','pelvis',0)
beam('Pescoco',(0,0,1.44),(0,0,1.59),.064,.058,'pele','neck',n=8)
rings('Cabeca',[(0,-.008,1.545,.060,.060),(0,-.005,1.59,.078,.078),(0,0,1.70,.084,.087),(0,.003,1.765,.069,.072),(0,.003,1.78,.040,.048)],'pele','head',n=10)
rings('Cabelo',[(0,.012,1.695,.086,.080),(0,.006,1.759,.073,.076),(0,.008,1.788,.045,.052)],'cabelo','head',n=10)
for sign in [-1,1]:
 box('Olho',(sign*.029,-.080,1.675),(.018,.006,.009),'negro','head',0)
 box('Sobrancelha',(sign*.030,-.081,1.689),(.024,.006,.007),'cabelo','head',0)
 box('Orelha',(sign*.080,.005,1.658),(.021,.032,.05),'pele','head',.005)
box('Nariz',(0,-.091,1.650),(.025,.031,.038),'pele','head',.006)
box('Barba',(0,-.077,1.602),(.091,.009,.023),'cabelo','head',.004)
# Linen collar, shoulder leather and small waist pouch.
for sign in [-1,1]:
 o=box('Gola',(sign*.05,-.102,1.434),(.065,.025,.084),'linho','spine',.003);o.rotation_euler.y=sign*.4
 o=box('Correia mochila',(sign*.124,-.115,1.267),(.038,.022,.34),'couro','spine',.003);o.rotation_euler.y=sign*.1
box('Bolsa',(0,.155,1.24),(.28,.15,.32),'couro','spine',.035)
box('Aba da bolsa',(0,.245,1.36),(.275,.025,.12),'carvalho','spine',.012)
box('Bolso de cintura',(.19,-.06,.94),(.11,.13,.13),'couro','pelvis',.018)
# Parenting/rig weights, with reproducible rigid sections for this first art study.
for o in CUR:
 if o.type!='MESH':continue
 bname=o.get('bone','root');vg=o.vertex_groups.new(name=bname);vg.add(list(range(len(o.data.vertices))),1.0,'REPLACE')
 mod=o.modifiers.new('Deformacao','ARMATURE');mod.object=rig
 o.parent=rig
# Original actions, in place. Gameplay owns displacement and impact timing.
bpy.context.scene.render.fps=24
for name,frames in [('idle',48),('guard',48),('walk',24),('run',18),('attack',20),('stab',24),('dodge',12),('hit',12),('die',24)]:
 action=bpy.data.actions.new(name);action.use_fake_user=True
 rig.animation_data_create();rig.animation_data.action=action
 sample_frames=list(range(1,frames+2)) if name=='attack' else sorted(set(list(range(1,frames+2,2))+[frames+1]))
 for frame in sample_frames:
  phase=(frame-1)/frames;t=phase*math.tau
  for pb in rig.pose.bones:pb.rotation_mode='XYZ';pb.rotation_euler=(0,0,0);pb.location=(0,0,0)
  def rx(b,v):rig.pose.bones[b].rotation_euler.x=v
  def ry(b,v):rig.pose.bones[b].rotation_euler.y=v
  def rz(b,v):rig.pose.bones[b].rotation_euler.z=v
  def loc(b,z):rig.pose.bones[b].location.z=z
  if name in ('idle','guard'):
   rx('spine',math.sin(t)*.013)
   rz('head',math.sin(t)*.023)
   if name=='guard':
    rx('arm-right',-.48);rx('forearm-right',-.66)
    rx('arm-left',-.18);rx('forearm-left',-.35)
    rx('thigh-right',-.10);rx('shin-right',.12)
  elif name in ('walk','run'):
   running=name=='run';stride=.78 if running else .46
   rx('spine',.14 if running else .055)
   rz('pelvis',math.cos(t)*(.065 if running else .035))
   for sign,side in [(-1,'right'),(1,'left')]:
    swing=sign*math.sin(t)
    rx('thigh-'+side,swing*stride)
    rx('shin-'+side,max(0,-swing)*(.72 if running else .42))
    rx('foot-'+side,-swing*(.19 if running else .13))
    rx('arm-'+side,-swing*(.40 if running else .20))
    rx('forearm-'+side,-.48 if running else -.16)
   loc('root',abs(math.sin(t))*(.04 if running else .025))
  elif name=='attack':
   # Whole-body diagonal cut. The blade crosses the target at ~40%,
   # matching the game's delayed damage window instead of only lifting up.
   poses=[
    (0.0,{}),
    (.18,{'root':(.08,0,-.08),'pelvis':(0,0,-.23),'spine':(-.16,0,-.42),'arm-right':(-1.45,.12,-.72),'forearm-right':(-.75,0,-.15),'hand-right':(.25,0,-.15),'arm-left':(-.35,0,.10),'thigh-left':(-.18,0,0),'thigh-right':(.11,0,0)}),
    (.30,{'root':(.16,0,.09),'pelvis':(0,0,.27),'spine':(.10,0,.54),'arm-right':(-.62,-.45,.68),'forearm-right':(-.20,.10,.18),'hand-right':(-.25,0,.15),'arm-left':(-.48,0,-.12),'thigh-left':(-.28,0,0),'shin-left':(.18,0,0),'thigh-right':(.08,0,0)}),
    (.43,{'root':(.07,0,.05),'pelvis':(0,0,.26),'spine':(.08,0,.36),'arm-right':(-.28,-.65,1.15),'forearm-right':(-.38,.08,.30),'hand-right':(-.65,0,.36),'arm-left':(-.34,0,-.08),'thigh-left':(-.19,0,0),'shin-left':(.12,0,0)}),
    (.72,{'spine':(.04,0,.13),'arm-right':(-.12,-.20,.42),'forearm-right':(-.10,0,.08),'hand-right':(-.18,0,.12),'thigh-left':(-.08,0,0)}),
    (1.0,{})]
   for i in range(len(poses)-1):
    p0,a0=poses[i];p1,a1=poses[i+1]
    if phase<=p1:
     blend=(phase-p0)/(p1-p0);blend=blend*blend*(3-2*blend)
     for b in set(a0)|set(a1):
      v0=a0.get(b,(0,0,0));v1=a1.get(b,(0,0,0))
      v=tuple(v0[j]+(v1[j]-v0[j])*blend for j in range(3))
      rx(b,v[0]);ry(b,v[1]);rz(b,v[2])
     break
  elif name=='stab':
   a=math.sin(phase*math.pi)
   rx('arm-right',-.9*a);rx('forearm-right',-.42*a)
   rx('arm-left',-.75*a);rx('forearm-left',-.65*a)
   rx('spine',.15*a);rx('thigh-left',-.20*a);rx('shin-left',.15*a)
  elif name=='dodge':
   a=math.sin(phase*math.pi)
   rx('spine',.35*a);rx('thigh-left',-.70*a);rx('thigh-right',.35*a)
   rx('shin-left',.45*a);rx('shin-right',.45*a)
   rx('arm-right',.45*a);rx('arm-left',.45*a);loc('root',-.10*a)
  elif name=='hit':
   a=math.sin(phase*math.pi)
   rx('spine',-.24*a);rx('head',-.15*a)
   rx('arm-right',-.30*a);rx('arm-left',-.28*a);rz('pelvis',.08*a)
  elif name=='die':
   progress=min(1,phase/0.88);progress=progress*progress*(3-2*progress)
   rx('root',-progress*math.pi/2);loc('root',progress*.16)
  for pb in rig.pose.bones:
   pb.keyframe_insert('rotation_euler',frame=frame,group=pb.name);pb.keyframe_insert('location',frame=frame,group=pb.name)
rig.animation_data.action=bpy.data.actions['idle']
bpy.context.scene.frame_set(1)
# A corrupted dungeon dweller shares the original rig but has its own face,
# cloth palette and skeletal details. No external character meshes.
mat('pele_corrompida',(.32,.34,.28),'skin')
mat('trapos',(.25,.20,.16),'cloth')
begin('corrompido')
monster_rig=rig.copy();monster_rig.data=rig.data.copy();monster_rig.name='Corrompido'
bpy.context.collection.objects.link(monster_rig);CUR.append(monster_rig)
for original in ASSETS['aventureiro']:
 if original.type!='MESH' or original.name.startswith(('Bolsa','Aba','Bolso','Correia','Cabelo','Barba','Sobrancelha')):continue
 o=original.copy();o.data=original.data.copy();bpy.context.collection.objects.link(o);CUR.append(o);o.parent=monster_rig
 for mod in o.modifiers:
  if mod.type=='ARMATURE':mod.object=monster_rig
 for slot in o.material_slots:
  if slot.material==MATS['pele']:slot.material=MATS['pele_corrompida']
  elif slot.material==MATS['tunika']:slot.material=MATS['trapos']
for x in [-.065,0,.065]:
 o=beam('Osso exposto',(x,-.04,1.77),(x*1.4,-.02,1.90),.027,.003,'linho','head',n=5)
 vg=o.vertex_groups.new(name='head');vg.add(list(range(len(o.data.vertices))),1,'REPLACE')
 mod=o.modifiers.new('Deformacao','ARMATURE');mod.object=monster_rig;o.parent=monster_rig
# Join temporary mesh copies to reduce draw calls. Editable parts stay in .blend.
manifest={}
for name,objs in ASSETS.items():
 bpy.ops.object.select_all(action='DESELECT')
 duplicates=[];armatures=[o for o in objs if o.type=='ARMATURE']
 for original in objs:
  if original.type!='MESH':continue
  o=original.copy();o.data=original.data.copy();bpy.context.collection.objects.link(o)
  o.select_set(True);duplicates.append(o)
 bpy.context.view_layer.objects.active=duplicates[0]
 bpy.ops.object.join();merged=bpy.context.object;merged.name=name+'_mesh'
 for arm in armatures:arm.select_set(True)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=bool(armatures),export_animation_mode='ACTIONS',export_frame_range=False,export_optimize_animation_size=True,export_yup=True,export_apply=False)
 triangles=sum(max(0,len(poly.vertices)-2) for poly in merged.data.polygons)
 manifest[name]={'meshes':1,'triangles':triangles,'source':'arte/fontes/gerar_modelos.py','authorship':'Original para Dungepm'}
 bpy.data.objects.remove(merged,do_unlink=True)
# Organize the Blender source as separate collections, hidden by default except adventurer.
for name,objs in ASSETS.items():
 col=bpy.data.collections.new(name);bpy.context.scene.collection.children.link(col)
 for o in objs:
  for existing in list(o.users_collection):existing.objects.unlink(o)
  col.objects.link(o)
 col.hide_viewport=name!='aventureiro';col.hide_render=name!='aventureiro'
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'arte/fontes/dungepm_modelos.blend'))
(OUT/'MANIFESTO.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
print('ASSETS_ORIGINAIS_CONCLUIDOS',len(manifest))
