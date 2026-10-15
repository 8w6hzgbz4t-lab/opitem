local P={Items={
 {id='tag',name='Tag',rank=1,price=0,range=7,radius=0,duration=0,cooldown=4,windup=.15,target='cone',cone=.5,force=0,dislodge=true,description='Permanent slot. A short-range verified touch knocks carried loot loose.'},
 {id='push',name='Palm Push',rank=1,price=150,range=10,radius=0,duration=0,cooldown=8,windup=.4,target='cone',cone=.65,force=22,dislodge=true,starter=true,description='Directional knockback. Drops carried loot; dodge the narrow cone.'},
 {id='gust',name='Gust',rank=1,price=200,range=14,radius=0,duration=0,cooldown=10,windup=.65,target='cone',cone=.5,force=25,dislodge=true,starter=true,description='Wider directional gust. Drops carried loot after a visible warning.'},
 {id='slow',name='Slowing Field',rank=2,price=800,range=15,radius=7,duration=1.8,cooldown=12,windup=.7,target='field',slow=true,force=0,dislodge=false,description='A small slowing field. Interrupts holds/bids, but does not drop loot.'},
 {id='shield',name='Prism Shield',rank=2,price=1000,range=0,radius=0,duration=2.5,cooldown=15,windup=0,target='self',force=0,dislodge=false,description='Briefly block incoming powers. Cannot be cast while carrying.'},
 {id='repulse',name='Repulse',rank=3,price=3500,range=11,radius=11,duration=0,cooldown=14,windup=.8,target='burst',force=28,dislodge=true,description='Warned radial knockback. Drops carried loot; retreat out of the ring.'},
 {id='frost',name='Frost Snap',rank=3,price=4500,range=18,radius=4,duration=.6,cooldown=15,windup=1,target='field',stun=true,force=0,dislodge=false,description='A short stop after a long warning. Keeps loot in hand; follow with Tag.'},
 {id='storm',name='Storm Gust',rank=4,price=14000,range=18,radius=0,duration=0,cooldown=18,windup=1,target='cone',cone=.4,force=32,dislodge=true,description='Long, broad knockback cone. Drops loot; a one-second warning gives counterplay.'},
 {id='tide',name='Tidal Field',rank=4,price=18000,range=22,radius=8,duration=2.2,cooldown=20,windup=1,target='field',slow=true,force=0,dislodge=false,description='A larger slowing field. Interrupts holds and auctions without dropping loot.'},
 {id='lightning',name='Lightning Bolt',rank=5,price=65000,range=26,radius=4,duration=.85,cooldown=24,windup=1.2,target='field',stun=true,force=0,dislodge=false,description='Briefly shocks and stops a carrier. Does not drop loot directly; intercept with Tag during the stop; stun immunity prevents chains.'},
 {id='dash',name='Rift Dash',rank=2,price=1200,range=1,radius=0,duration=.65,cooldown=15,windup=0,target='self',dash=true,force=0,dislodge=false,description='A short server-authorized dash. Disabled while carrying or bidding.'},
 {id='gravity',name='Gravity Pull',rank=3,price=5000,range=12,radius=12,duration=0,cooldown=18,windup=1.1,target='burst',force=24,pull=true,dislodge=false,description='Warned radial pull. Interrupts bids and moves carriers without dropping loot.'},
}}
P.ById={};for _,d in ipairs(P.Items) do
 d.warningColor=d.warningColor or ({ {93,219,225},{123,200,245},{166,154,245},{213,150,233},{255,220,108} })[d.rank]
 P.ById[d.id]=d
end
return P
