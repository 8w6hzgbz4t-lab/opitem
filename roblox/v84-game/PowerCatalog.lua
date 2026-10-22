-- Ten server-authorized regular powers. Tag plus two optional loadout slots.
local P={Items={
 {id='tag',name='Tag',rank=1,price=0,range=7,radius=0,duration=0,cooldown=4,windup=.15,target='cone',cone=.5,force=0,dislodge=true,warningColor={93,230,215},description='Permanent short-range hit knocks carried loot loose.'},
 {id='dash',name='Dash',rank=1,price=250,range=0,radius=0,duration=.22,cooldown=9,windup=0,target='self',dash=true,force=0,starter=true,warningColor={70,215,255},description='A short burst checked against solid walls. Cannot cast while carrying.'},
 {id='gravity',name='Pull',rank=2,price=1200,range=11,radius=11,duration=0,cooldown=14,windup=.55,target='burst',force=22,pull=true,warningColor={170,120,255},description='Short-range inward pull interrupts holds. Visible violet warning.'},
 {id='slow',name='Slow Field',rank=2,price=1500,range=16,radius=6,duration=2.5,cooldown=15,windup=.65,target='field',slow=true,force=0,warningColor={80,170,255},description='Aim the reticle to place a marked slowing zone within sixteen studs. Knocks carried loot loose; walls, shields and immunity block hits.'},
 {id='slam',name='Ground Slam',rank=3,price=5000,range=8,radius=8,duration=0,cooldown=18,windup=.7,target='burst',force=18,dislodge=true,warningColor={255,170,65},description='A clear ground warning erupts into cracked-earth rubble and dislodges nearby loot. Rubble fades and never blocks movement.'},
 {id='repulse',name='Knockback Pulse',rank=4,price=14000,range=11,radius=11,duration=0,cooldown=20,windup=.8,target='burst',force=28,dislodge=true,warningColor={255,115,180},description='Visible outward pink blast knocks nearby carriers away.'},
 {id='shield',name='Force Field Shield',rank=4,price=18000,range=0,radius=0,duration=3,cooldown=23,windup=0,target='self',force=0,warningColor={75,240,180},description='Surrounds you for three seconds. Blocks exactly one incoming hit.'},
 {id='lightning',name='Lightning Strike',rank=5,price=65000,range=26,radius=4,duration=.85,cooldown=28,windup=1.2,target='lock',stun=true,force=0,warningColor={255,225,95},description='Automatically locks onto the nearest visible opponent in range. A clear warning precedes the brief stun and loot drop. Walls, shields and immunity protect the target.'},
 {id='kiblast',name='Ki Blast',rank=5,price=65000,range=40,radius=1.1,blastRadius=6,duration=40/70,cooldown=28,windup=.6,target='projectile',projectileSpeed=70,force=16,dislodge=true,warningColor={84,226,255},description='Aim a bright energy projectile. Explodes within six studs at a target, solid wall or maximum range. Walls, shields and immunity block blast hits.'},
 {id='spinjitzu',name='Spinjitzu',rank=4,price=16000,range=8,radius=8,duration=1.5,cooldown=22,windup=.6,target='tornado',force=20,dislodge=true,warningColor={121,241,201},description='A small moving tornado briefly knocks nearby opponents back and drops carried loot. Hits each opponent once per cast; walls and shields block it.'},
}}
P.ById={};for _,d in ipairs(P.Items) do P.ById[d.id]=d end
P.Replacements={push='dash',gust='dash',frost='slow',storm='repulse',tide='slow',pull='gravity',pulse='repulse'}
return P

