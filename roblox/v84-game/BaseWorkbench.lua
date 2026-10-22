-- Cosmetic base desk around the existing manager anchor. No economy or input code.
local B={}
function B.create(world,anchor,index,baseCF)
 local name='VaultWorkbench'..tostring(index)
 local old=world.folder:FindFirstChild(name)
 if old then old:Destroy()end
 local model=Instance.new('Model');model.Name=name
 model:SetAttribute('BaseIndex',index)
 model:SetAttribute('CosmeticWorkbench',true)
 model:SetAttribute('PartBudget',85)
 if baseCF then model:SetAttribute('BaseCF',baseCF)end
 local V,C,A=Vector3.new,CFrame.new,CFrame.Angles
 local navy=Color3.fromRGB(25,35,49)
 local steel=Color3.fromRGB(112,134,144)
 local wood=Color3.fromRGB(101,73,48)
 local gold=Color3.fromRGB(222,181,104)
 local green=Color3.fromRGB(105,220,167)
 local pale=Color3.fromRGB(230,234,217)
 local parts=0
 local function part(label,size,cf,color,material,solid)
  parts=parts+1;assert(parts<=85,'Base workbench part budget exceeded')
  local p=Instance.new('Part');p.Name=label;p.Size=size;p.CFrame=anchor.CFrame*cf
  p.Anchored=true;p.CanTouch=false;p.CanCollide=solid==true;p.CanQuery=solid==true
  p.Material=material or Enum.Material.Metal;p.Color=color
  p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
  p.Parent=model;return p
 end
 part('WorkbenchTop',V(4.8,.24,2.8),C(0,.28,0),steel,nil,true)
 part('BronzeDesktopEdge',V(4.88,.08,2.88),C(0,.14,0),gold)
 part('InsetWoodSurface',V(4.55,.06,2.55),C(0,.43,0),wood,Enum.Material.Wood)
 for _,x in ipairs({-1.85,1.85})do
  for _,z in ipairs({-.95,.95})do
   part('Leg'..x..'_'..z,V(.24,1.35,.28),C(x,-.4,z),navy,nil,true)
   part('LegFoot'..x..'_'..z,V(.46,.16,.53),C(x,-1.09,z),steel,nil,true)
   part('WorktopRivet'..x..'_'..z,V(.09,.035,.09),C(x,.48,z),gold)
  end
 end
 part('LowerShelf',V(3.8,.14,1.8),C(0,-.71,.15),wood,Enum.Material.Wood)
 for drawer=1,3 do
  local x=(drawer-2)*1.1
  part('SupplyDrawer'..drawer,V(1,.38,1.15),C(x,-.04,.3),navy)
  part('DrawerFace'..drawer,V(.96,.32,.08),C(x,-.04,-.315),steel)
  part('DrawerPull'..drawer,V(.35,.065,.10),C(x,-.04,-.405),gold)
 end
 part('ScreenStand',V(.45,.55,.35),C(0,.76,.75),steel)
 part('ScreenStandFoot',V(1.1,.07,.65),C(0,.5,.72),navy)
 local monitor=C(0,1.58,.75)*A(math.rad(-12),0,0)
 part('MonitorBezel',V(3.15,1.8,.25),monitor,navy)
 local screen=part('VaultDisplay',V(2.91,1.56,.045),monitor*C(0,0,-.15),Color3.fromRGB(15,53,43),Enum.Material.SmoothPlastic)
 local surface=Instance.new('SurfaceGui');surface.Name='VaultWorkbenchDisplay'
 surface.Face=Enum.NormalId.Front;surface.CanvasSize=Vector2.new(800,340)
 surface.LightInfluence=0;surface.AlwaysOnTop=false;surface.Parent=screen
 local title=Instance.new('TextLabel');title.Name='WorkbenchTitle'
 title.BackgroundTransparency=1;title.Position=UDim2.fromScale(.035,.04);title.Size=UDim2.fromScale(.93,.92)
 title.Font=Enum.Font.GothamBold;title.TextSize=51;title.TextColor3=green;title.TextWrapped=true
 title.Text='MY VAULT\nMOVE • SELL\nBASE LEVELS';title.Parent=surface
 for _,side in ipairs({-1,1})do
  part('MonitorGoldTrim'..side,V(.06,1.72,.05),monitor*C(side*1.52,0,-.15),gold)
 end
 part('MonitorStatusLight',V(.26,.045,.035),monitor*C(0,-.82,-.15),green,Enum.Material.Neon)
 part('KeyboardBase',V(2.25,.075,.72),C(-.25,.5,-.7),navy)
 for row=0,2 do
  for column=0,6 do
   part('Key'..row..'_'..column,V(.21,.045,.12),C(-1.11+column*.28,.56,-.94+row*.2),row==0 and green or pale)
  end
 end
 part('ControlPad',V(.62,.065,.66),C(1.48,.5,-.72),navy)
 part('ControlDial',V(.31,.06,.31),C(1.48,.56,-.72)*A(0,math.pi/4,0),gold)
 part('LedgerCover',V(.72,.09,.83),C(-1.55,.52,.04)*A(0,-.13,0),green,Enum.Material.SmoothPlastic)
 part('LedgerPages',V(.65,.075,.77),C(-1.55,.58,.04)*A(0,-.13,0),pale,Enum.Material.SmoothPlastic)
 part('LedgerBinding',V(.095,.15,.85),C(-1.9,.56,.09)*A(0,-.13,0),gold)
 part('LedgerBookmark',V(.06,.015,.48),C(-1.46,.625,.12)*A(0,-.13,0),navy)
 part('ItemTray',V(.78,.07,.65),C(1.58,.5,.22),steel)
 for _,side in ipairs({-1,1})do
  part('TrayEdge'..side,V(.05,.11,.66),C(1.58+side*.38,.56,.22),gold)
 end
 part('TrayRelic',V(.34,.34,.34),C(1.58,.72,.22)*A(.35,.6,.2),green,Enum.Material.Glass)
 model:SetAttribute('PartCount',parts)
 model.PrimaryPart=model:FindFirstChild('WorkbenchTop')
 -- Keep the interaction object, its CFrame and every connected prompt intact.
 anchor.Transparency=1;anchor.CanCollide=false;anchor.CanQuery=false
 model.Parent=world.folder
 return model
end
return B
