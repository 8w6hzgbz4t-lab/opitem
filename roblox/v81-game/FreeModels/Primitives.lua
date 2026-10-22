-- Shared procedural art. No external assets, remotes, or runtime scripts.
local P={}
local B={}; B.__index=B
function P.new(parent,options)
 options=options or {}
 options.parent=parent
 local scale=options.scale or 1
 assert(type(scale)=="number" and scale>0 and scale<math.huge,"Invalid art scale")
 local model=Instance.new("Model"); model.Name=options.name or options.model or "Collectible"
 model:SetAttribute("Kind",options.itemId or options.model or "art")
 model:SetAttribute("AnimatedCharacter",false)
 model:SetAttribute("ArtVersion",1)
 local root=Instance.new("Part"); root.Name="Root"; root.Size=Vector3.new(.1,.1,.1)
 root.CFrame=CFrame.new(); root.Transparency=1; root.Anchored=true
 root.CanCollide=false; root.CanTouch=false; root.CanQuery=false; root.Parent=model
 model.PrimaryPart=root
 return setmetatable({model=model,root=root,scale=scale,options=options,count=1,minY=math.huge},B)
end
function B:part(name,size,cf,color,material,shape,solid,class)
 assert(type(material)~="number","Material must be an Enum.Material, not a dimension")
 local p=Instance.new(class or "Part")
 p.Name=name; p.Size=size*self.scale
 p.CFrame=CFrame.new(cf.Position*self.scale)*(cf-cf.Position)
 p.Color=color or Color3.fromRGB(205,160,60); p.Material=material or Enum.Material.Metal
 if shape then p.Shape=shape end
 p.Anchored=true; p.CanCollide=solid==true; p.CanTouch=false; p.CanQuery=solid==true
 p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=self.model; self.count=self.count+1
 local x,y,z,r00,r01,r02,r10,r11,r12=p.CFrame:GetComponents()
 local half=.5*(math.abs(r10)*p.Size.X+math.abs(r11)*p.Size.Y+math.abs(r12)*p.Size.Z)
 self.minY=math.min(self.minY,y-half)
 return p
end
function B:box(name,size,cf,color,material,solid)
 return self:part(name,size,cf,color,material,Enum.PartType.Block,solid)
end
function B:ball(name,size,cf,color,material,solid)
 if type(size)=="number" then size=Vector3.new(size,size,size) end
 return self:part(name,size,cf,color,material,Enum.PartType.Ball,solid)
end
function B:cylinder(name,size,cf,color,material,solid)
 return self:part(name,size,cf,color,material,Enum.PartType.Cylinder,solid)
end
function B:line(name,a,c,thickness,depth,color,material,solid)
 local d=c-a; if d.Magnitude<1e-7 then return end
 local up=d.Unit; local ref=Vector3.new(0,0,1)
 if math.abs(up:Dot(ref))>.95 then ref=Vector3.new(1,0,0) end
 local right=up:Cross(ref).Unit; local back=right:Cross(up).Unit
 return self:box(name,Vector3.new(thickness,d.Magnitude,depth or thickness),CFrame.fromMatrix((a+c)*.5,right,up,back),color,material,solid)
end
function B:ring(name,cf,radius,thickness,color,segments,material)
 segments=segments or 20
 for i=0,segments-1 do
  local a=i*math.pi*2/segments; local c=(i+1)*math.pi*2/segments
  self:line(name.."_"..i,cf*Vector3.new(math.cos(a)*radius,math.sin(a)*radius,0),
   cf*Vector3.new(math.cos(c)*radius,math.sin(c)*radius,0),thickness,thickness,color,material)
 end
end
function B:wedge(name,size,cf,color,material,solid)
 return self:part(name,size,cf,color,material,nil,solid,"WedgePart")
end
function B:triangle(name,a,b,c,color,thickness,material)
 local ab,ac,bc=b-a,c-a,c-b
 if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c
 elseif ac:Dot(ac)>bc:Dot(bc) and ac:Dot(ac)>ab:Dot(ab) then a,b=b,a end
 ab,ac,bc=b-a,c-a,c-b
 local normal=ac:Cross(ab); if normal.Magnitude<1e-7 then return end
 local right=normal.Unit; local back=bc.Unit; local up=back:Cross(right).Unit
 local height=math.abs(ab:Dot(up)); thickness=thickness or .035
 local first,second=math.abs(ab:Dot(back)),math.abs(ac:Dot(back))
 if first>1e-6 then self:wedge(name.."_A",Vector3.new(thickness,height,first),CFrame.fromMatrix((a+b)*.5,right,up,back),color,material) end
 if second>1e-6 then self:wedge(name.."_B",Vector3.new(thickness,height,second),CFrame.fromMatrix((a+c)*.5,-right,up,-back),color,material) end
end
function B:finish()
 assert(self.count<=(self.options.partBudget or 240),"Art part budget exceeded")
 if self.options.alignBase~=false and self.minY<math.huge then
  for _,p in ipairs(self.model:GetChildren()) do
   if p:IsA("BasePart") and p~=self.root then p.CFrame=p.CFrame+Vector3.new(0,.04-self.minY,0) end
  end
 end
 self.model:SetAttribute("PartCount",self.count)
 self.model:PivotTo(self.options.cframe or CFrame.new())
 self.model.Parent=self.options.parent
 return self.model
end
return P
