-- Four overlapping barriers enclose the original 252 x 188 plaza.
local B={}
B.WallHeight=24
B.WallThickness=3
function B.build(world)
 local previous=world.folder:FindFirstChild('ArenaBounds'); if previous then previous:Destroy() end
 local root=Instance.new('Folder'); root.Name='ArenaBounds'; root.Parent=world.folder
 local function wall(name,size,pos)
  local p=Instance.new('Part'); p.Name=name; p.Size=size; p.Position=pos
  p.Anchored=true; p.CanCollide=true; p.CanTouch=false; p.CanQuery=true
  p.Material=Enum.Material.Slate; p.Color=Color3.fromRGB(42,40,62)
  p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=root
  local trim=Instance.new('Part'); trim.Name='DimensionalCoping'; trim.Anchored=true
  trim.CanCollide=false; trim.CanTouch=false; trim.CanQuery=false
  trim.Size=Vector3.new(size.X,.25,size.Z); trim.Position=pos+Vector3.new(0,size.Y/2+.15,0)
  trim.Material=Enum.Material.Neon; trim.Color=Color3.fromRGB(121,137,221); trim.Parent=root
 end
 wall('NorthBarrier',Vector3.new(253,24,3),Vector3.new(0,11,-93))
 wall('SouthBarrier',Vector3.new(253,24,3),Vector3.new(0,11,93))
 wall('WestBarrier',Vector3.new(3,24,189),Vector3.new(-125,11,0))
 wall('EastBarrier',Vector3.new(3,24,189),Vector3.new(125,11,0))
 for _,z in ipairs({-93,93}) do for _,x in ipairs({-112,-56,0,56,112}) do
  local column=Instance.new('Part');column.Name='SolidArenaButtress';column.Size=Vector3.new(4,44,4);column.Position=Vector3.new(x,21,z)
  column.Anchored=true;column.CanCollide=true;column.CanTouch=false;column.CanQuery=true;column.Material=Enum.Material.Slate;column.Color=Color3.fromRGB(67,62,89);column.Parent=root
  local cap=Instance.new('Part');cap.Name='ButtressCrown';cap.Size=Vector3.new(5,2,5);cap.Position=Vector3.new(x,44,z)
  cap.Anchored=true;cap.CanCollide=true;cap.CanTouch=false;cap.CanQuery=true;cap.Material=Enum.Material.Metal;cap.Color=Color3.fromRGB(211,173,85);cap.Parent=root
 end end
 return root
end
return B
