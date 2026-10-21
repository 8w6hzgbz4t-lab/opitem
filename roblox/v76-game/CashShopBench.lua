local M={}
function M.create(world)
 local old=world.folder:FindFirstChild('CashShopBench');if old then old:Destroy() end
 local model=Instance.new('Model');model.Name='CashShopBench';model.Parent=world.folder
 model:SetAttribute('PreviewOnly',true)
 local V,C=Vector3.new,CFrame.new
 local gold=Color3.fromRGB(235,186,76);local navy=Color3.fromRGB(21,31,47)
 local green=Color3.fromRGB(81,219,159);local steel=Color3.fromRGB(116,139,156)
 local function part(name,size,cf,color,material,solid)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=C(9,0,19)*cf
  p.Anchored=true;p.CanCollide=solid==true;p.CanTouch=false;p.CanQuery=solid==true
  p.Color=color;p.Material=material or Enum.Material.Metal;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=model;return p
 end
 part('Worktop',V(5,.3,3),C(0,2.35,0),steel,nil,true)
 part('GoldWorktopRim',V(5.15,.1,3.15),C(0,2.17,0),gold,nil,true)
 for _,x in ipairs({-1.8,1.8}) do
  part('DeskLeg'..x,V(.35,2,.4),C(x,1.1,.55),navy,nil,true)
  part('DeskFoot'..x,V(.8,.2,2.4),C(x,.2,0),navy,nil,true)
  part('DeskCornerLight'..x,V(.12,1.55,.12),C(x,1.2,.28),green,Enum.Material.Neon,false)
 end
 part('DisplayStand',V(.5,.8,.4),C(0,2.8,.7),gold)
 part('SignBezel',V(4.8,2.6,.32),C(0,4.35,.7),navy,nil,true)
 local sign=part('CashShopSign',V(4.4,2.2,.08),C(0,4.35,.49),Color3.fromRGB(16,64,55),Enum.Material.SmoothPlastic,false)
 local surface=Instance.new('SurfaceGui');surface.Name='CashShopDisplay';surface.Face=Enum.NormalId.Front;surface.CanvasSize=Vector2.new(640,300);surface.LightInfluence=0;surface.Parent=sign
 local title=Instance.new('TextLabel');title.Size=UDim2.fromScale(.94,.94);title.Position=UDim2.fromScale(.03,.03);title.BackgroundTransparency=1;title.Text='CASH SHOP\nCOMING SOON\nGAME CASH PACKS';title.TextColor3=gold;title.TextSize=47;title.Font=Enum.Font.GothamBold;title.TextWrapped=true;title.Parent=surface
 for _,x in ipairs({-2.3,2.3}) do part('GoldSignEdge'..x,V(.09,2.5,.12),C(x,4.35,.47),gold,Enum.Material.Neon,false) end
 for row=0,2 do for col=0,5 do part('Key'..row..col,V(.22,.06,.17),C(-.8+col*.3,2.55,-.7+row*.23),row==0 and green or steel) end end
 for stack=0,2 do for level=0,2 do
  local p=part('CashBundle'..stack..level,V(.65,.18,.4),C(1.25+stack*.13,2.62+level*.2,.2+stack*.25),green,Enum.Material.SmoothPlastic,false)
  part('CashBand'..stack..level,V(.1,.185,.405),C(p.Position-V(9,0,19)),gold,Enum.Material.SmoothPlastic,false)
 end end
 local anchor=part('Browse Cash Packs',V(1,1,1),C(0,3,-1.5),green,nil,false);anchor.Transparency=1
 return anchor,model
end
return M
