-- Exactly eight server-authorized powers; existing IDs retained where possible.
local P={Items={
 {id='tag',name='Tag',rank=1,price=0,range=7,radius=0,duration=0,cooldown=4,windup=.15,target='cone',cone=.5,force=0,dislodge=true,warningColor={93,230,215},description='Permanent short-range hit knocks carried loot loose.'},
 {id='dash',name='Dash',rank=1,price=250,range=0,radius=0,duration=.22,cooldown=9,windup=0,target='self',dash=true,force=0,starter=true,warningColor={70,215,255},description='A short burst checked against solid walls. Cannot cast while carrying.'},
 {id='gravity',name='Pull',rank=2,price=1200,range=11,radius=11,duration=0,cooldown=14,windup=.55,target='burst',force=22,pull=true,warningColor={170,120,255},description='Short-range inward pull interrupts holds. Visible violet warning.'},
 {id='slow',name='Slow Field',rank=2,price=1500,range=16,radius=6,duration=2.5,cooldown=15,windup=.65,target='field',slow=true,force=0,warningColor={80,170,255},description='Marked blue zone briefly slows entrants and knocks carried loot loose. Shields and immunity can block the hit.'},
 {id='slam',name='Ground Slam',rank=3,price=5000,range=8,radius=8,duration=0,cooldown=18,windup=.7,target='burst',force=18,dislodge=true,warningColor={255,170,65},description='Close-range ground impact dislodges loot after a clear warning.'},
 {id='repulse',name='Knockback Pulse',rank=4,price=14000,range=11,radius=11,duration=0,cooldown=20,windup=.8,target='burst',force=28,dislodge=true,warningColor={255,115,180},description='Visible outward pink blast knocks nearby carriers away.'},
 {id='shield',name='Force Field Shield',rank=4,price=18000,range=0,radius=0,duration=3,cooldown=23,windup=0,target='self',force=0,warningColor={75,240,180},description='Surrounds you for three seconds. Blocks exactly one incoming hit.'},
 {id='lightning',name='Lightning Strike',rank=5,price=65000,range=26,radius=4,duration=.85,cooldown=28,windup=1.2,target='field',stun=true,force=0,warningColor={255,225,95},description='Marked target area, then a brief carrier-stopping stun. Four-second immunity prevents repeated stuns.'},
}}
P.ById={};for _,d in ipairs(P.Items) do P.ById[d.id]=d end
P.Replacements={push='dash',gust='dash',frost='slow',storm='repulse',tide='slow',pull='gravity',pulse='repulse'}
return P

