local D={}
function D.build(world)
 local root=Instance.new('Folder');root.Name='PhaseDecor';root.Parent=world.folder
 local function p(name,size,cf,color,solid,material)
  local a=Instance.new('Part');a.Name=name;a.Size=size;a.CFrame=cf;a.Color=color;a.Material=material or Enum.Material.SmoothPlastic
  a.Anchored=true;a.CanCollide=solid or false;a.CanQuery=solid or false;a.CanTouch=false;a.Parent=root;return a
 end
 local navy=Color3.fromRGB(29,33,54)
 -- Anchored item models are moved through this facade by the server; characters collide with it.
 p('DisposalFacade',Vector3.new(1,12,13),CFrame.new(-109.8,6,0),navy,true,Enum.Material.Metal)
 p('DisposalRoof',Vector3.new(14,1,13),CFrame.new(-117,12.5,0),navy,true)
 p('DisposalRear',Vector3.new(1,12,13),CFrame.new(-123.5,6,0),navy,true)
 for _,z in ipairs({-6,6}) do p('DisposalSide',Vector3.new(14,12,1),CFrame.new(-117,6,z),navy,true) end
 p('DisposalFloor',Vector3.new(14,1,13),CFrame.new(-117,.5,0),navy,true)
 local shop=p('PowerShop',Vector3.new(3,2.5,3),CFrame.new(0,1.5,19),Color3.fromRGB(70,207,224),true)
 world.label(shop,'POWER SHOP');world.powerShop=shop
 local flower=Instance.new('Model');flower.Name='MidnightLotus';flower.Parent=root
 p('LotusScenicPedestal',Vector3.new(22,5,20),CFrame.new(-70,28,104),navy,false,Enum.Material.Slate)
 for layer=1,3 do for i=0,7 do
  local angle=i*math.pi/4+layer*.2
  local petal=p('LotusPetal',Vector3.new(4,1,10-layer),CFrame.new(-70+math.cos(angle)*(6-layer),34+layer*1.2,104+math.sin(angle)*(6-layer))*CFrame.Angles(0,-angle+math.pi/2,.2),Color3.fromRGB(39+layer*8,29,65+layer*10),false,Enum.Material.Glass)
  petal.Parent=flower
 end end
 p('LotusGem',Vector3.new(2,2,2),CFrame.new(-70,38,104)*CFrame.Angles(.4,0,.4),Color3.fromRGB(148,118,220),false,Enum.Material.Neon)
 return root
end
return D

