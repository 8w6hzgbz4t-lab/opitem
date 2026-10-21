local Mock=dofile('tools/roblox_mock.lua')
local create=Instance.new
local geometry={Model=true,Folder=true,Part=true,WedgePart=true,CornerWedgePart=true,MeshPart=true}
Instance.new=function(class,parent)
 if geometry[class]then return create(class,parent)end
 local item=create('Folder',parent);item._class=class;item.Name=class;return item
end
Vector2={new=function(x,y)return{X=x,Y=y}end}
UDim2={fromScale=function(...)return{...}end}
local world={folder=create('Folder')};world.folder.Name='World'
local bench=Mock.loadModule((arg[1]or'roblox/v76-game')..'/CashShopBench.lua')
local anchor,model=bench.create(world)
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
check(model.Name=='CashShopBench'and model.Parent==world.folder,'Bench placed in current world')
check(model:GetAttribute('PreviewOnly')==true,'Preview metadata visible')
check(anchor.Transparency==1 and not anchor.CanCollide and not anchor.CanQuery,'Prompt anchor unobtrusive')
check(anchor.Position.X==9 and anchor.Position.Z==17.5,'Bench beside existing central Power Lab')
local parts=0
for _,p in ipairs(model:GetDescendants())do
 if p:IsA('BasePart')then
  parts=parts+1;check(p.Anchored and not p.CanTouch,'All decorative geometry stable without touch listeners')
  check(p.Size.X>0 and p.Size.Y>0 and p.Size.Z>0,'Positive finite part sizes')
  check(p.Position.Z-p.Size.Z/2>15 and p.Position.Z+p.Size.Z/2<22,'Desk stays outside conveyor and base entrances')
 end
end
check(parts<90 and parts>35,'Detailed bench within part budget')
local sign=assert(model:FindFirstChild('CashShopSign'))
local display=assert(sign:FindFirstChild('CashShopDisplay'))
local title=assert(display:FindFirstChild('TextLabel'))
check(title.Text=='CASH SHOP\nCOMING SOON\nGAME CASH PACKS','Visible cash-only preview signage')
local second,updated=bench.create(world)
check(updated~=model and #world.folder:GetChildren()==1,'Rebuilding does not duplicate desks')
print('CashShopBench v76 passed '..checks..' assertions; '..parts..' parts')
