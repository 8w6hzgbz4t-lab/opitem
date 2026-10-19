local W={}
function W.build(F,Config)
 local previous=workspace:FindFirstChild('OPItemWorld');if previous then previous:Destroy() end
 local folder=Instance.new('Folder'); folder.Name='OPItemWorld'; folder.Parent=workspace
 local function p(n,s,cf,c,solid,mat)
  local a=F.part(folder,n,s,cf,c,mat); a.CanCollide=solid or false; a.CanQuery=solid or false; return a
 end
 local function label(a,t)
  local b=Instance.new('BillboardGui'); b.Size=UDim2.fromOffset(180,50); b.StudsOffset=Vector3.new(0,3.2,0); b.MaxDistance=60; b.AlwaysOnTop=false; b.Parent=a
  local l=Instance.new('TextLabel'); l.Size=UDim2.fromScale(1,1); l.BackgroundTransparency=.2; l.BackgroundColor3=Color3.fromRGB(14,19,35); l.TextColor3=Color3.new(1,1,1); l.Font=Enum.Font.GothamBold; l.TextSize=12; l.TextWrapped=true; l.Text=t; l.Parent=b
  Instance.new('UICorner',l).CornerRadius=UDim.new(0,10); return l
 end
 local navy=Color3.fromRGB(26,34,52); local cyan=Color3.fromRGB(70,221,237); local gold=Color3.fromRGB(240,188,68)
 p('FloatingFoundation',Vector3.new(254,8,190),CFrame.new(0,-5,0),navy,true,Enum.Material.Slate)
 p('Plaza',Vector3.new(252,1,188),CFrame.new(0,-.5,0),Color3.fromRGB(59,72,91),true,Enum.Material.SmoothPlastic)
 p('RiftCarpet',Vector3.new(222,.12,18),CFrame.new(0,.08,0),Color3.fromRGB(71,46,110))
 for i=-10,10 do p('LaneDivider',Vector3.new(.12,.15,16),CFrame.new(i*10,.16,0),cyan) end
 for _,z in ipairs({-93,93}) do p('OuterRail',Vector3.new(250,3,1),CFrame.new(0,1.5,z),navy,true); p('EdgeLight',Vector3.new(250,.12,1.1),CFrame.new(0,3.1,z),cyan,false,Enum.Material.Neon) end
 for _,x in ipairs({-125,125}) do p('EndRail',Vector3.new(1,3,186),CFrame.new(x,1.5,0),navy,true) end
 local bases={}
 for i=1,Config.MaxPlayers do
  local x=-84+((i-1)%4)*56; local z=i<=4 and -57 or 57
  local cf=CFrame.new(x,0,z)*CFrame.Angles(0,z<0 and math.pi or 0,0)
  local accent=Color3.fromHSV((i-1)/Config.MaxPlayers,.56,.92)
  local b={cf=cf,slots={}}; bases[i]=b
  local function localPart(n,size,pos,c,solid,mat) return p(n,size,cf*CFrame.new(pos),c,solid,mat) end
  localPart('VaultFloor',Vector3.new(48,1,48),Vector3.new(0,.5,0),navy,true)
  localPart('BackWall',Vector3.new(48,11,1),Vector3.new(0,6,24),navy,true)
  for _,sx in ipairs({-24,24}) do localPart('SideWall',Vector3.new(1,9,48),Vector3.new(sx,5,0),navy,true) end
  for _,sx in ipairs({-20,20}) do localPart('GatePillar',Vector3.new(4,12,4),Vector3.new(sx,6,-23),navy,true); localPart('PillarLight',Vector3.new(.3,10,.3),Vector3.new(sx,6,-25.1),accent,false,Enum.Material.Neon) end
  localPart('GateLintel',Vector3.new(44,2,4),Vector3.new(0,12,-23),navy,true)
  b.gate=localPart('ProtectionField',Vector3.new(35,10,.2),Vector3.new(0,6,-23),accent,false,Enum.Material.ForceField); b.gate.Transparency=.7
  b.sign=label(localPart('VaultSign',Vector3.new(1,1,1),Vector3.new(0,11,-23),accent),'UNCLAIMED VAULT')
  b.home=localPart('Deliver / Collect',Vector3.new(12,.2,8),Vector3.new(0,1.15,-16),Color3.fromRGB(63,221,154))
  b.bank=label(b.home,'COLLECT EARNINGS')
  -- The full-width green entrance line delivers loot and renews ready protection.
  b.lock=localPart('Delivery / Protection Line',Vector3.new(46,.16,4),Vector3.new(0,1.12,-22),Color3.fromRGB(63,221,154),false,Enum.Material.Neon)
  b.upgrade=localPart('Upgrade Console',Vector3.new(3,2.5,3),Vector3.new(16,2.2,-17),cyan,true)
  label(b.upgrade,'POWER SHOP / LOADOUT')
  b.spawn=cf*CFrame.new(0,5,-11)
  for slot=1,Config.BaseSlots do
   local sx=-16.5+((slot-1)%4)*11; local sz=-3+math.floor((slot-1)/4)*10
   localPart('DisplayPedestal',Vector3.new(7,1.2,7),Vector3.new(sx,1.6,sz),Color3.fromRGB(46,56,78),true)
   localPart('PedestalTrim',Vector3.new(7.1,.12,7.1),Vector3.new(sx,2.25,sz),accent,false,Enum.Material.Neon)
   b.slots[slot]=cf*CFrame.new(sx,2.9,sz)
  end
 end
 -- The original plaza and portal are retained; the lane becomes the market belt.
 local startX,endX=Config.ConveyorStartX,Config.ConveyorEndX
 local center=(startX+endX)/2
 p('ConveyorBelt',Vector3.new(startX-endX,.6,8),CFrame.new(center,.6,0),navy,true,Enum.Material.Metal)
 for _,z in ipairs({-4.3,4.3}) do
  p('ConveyorRail',Vector3.new(startX-endX,.3,.35),CFrame.new(center,1,z),cyan,false,Enum.Material.Neon)
 end
 for x=endX,startX,8 do
  p('BeltSlat',Vector3.new(.2,.08,7.8),CFrame.new(x,.94,0),Color3.fromRGB(78,91,112))
 end
 local exit=p('ConveyorExit',Vector3.new(2,.12,8),CFrame.new(endX,1,0),gold,false,Enum.Material.Neon)
 -- Disposal is silent; no exit label or popup.
 -- Decorative portal at the end of the lane, clear of every base entrance.
 for i=1,24 do
  local a=i*math.pi/12
  p('RiftArch',Vector3.new(1.3,2.1,1.2),CFrame.new(119,10+math.sin(a)*8,math.cos(a)*8)*CFrame.Angles(a,0,0),gold,false,Enum.Material.Metal)
 end
 local portal=p('Rift',Vector3.new(.2,14,14),CFrame.new(119,10,0),Color3.fromRGB(153,64,244),false,Enum.Material.Neon); portal.Transparency=.3
 -- Ownership signs, pedestal trims and base accents replace scattered lane lamps.
 local world={folder=folder,bases=bases,label=label,part=p}
 require(script.Parent.ArenaBounds).build(world)
 require(script.Parent.Aesthetics).build(world)
 require(script.Parent.PhaseDecor).build(world)
 require(script.Parent.DetailedArt.WorldArt).addDecorations(world)
 require(script.Parent.DetailedArt.EnhancedScene).build(world)
 require(script.Parent.DetailedArt.BasePolish).build(world)
 require(script.Parent.DetailedArt.PlazaPolish).build(world)
 return world
end
return W

