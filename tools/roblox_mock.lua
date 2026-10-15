-- Offline Roblox geometry mock. It records procedural parts; it does not simulate gameplay.
-- Offline geometry recorder. This does not replace a Studio playtest.
local V={}
V.__index=function(v,k)
 if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
 if k=="Unit" then local n=v.Magnitude; assert(n>0,"zero unit vector"); return v/n end
 return V[k]
end
Vector3={}
function Vector3.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},V) end
Vector3.zero=Vector3.new()
V.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
V.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
V.__unm=function(a) return Vector3.new(-a.X,-a.Y,-a.Z) end
V.__mul=function(a,b)
 if type(a)=="number" then a,b=b,a end
 assert(type(b)=="number","scalar multiplication required")
 return Vector3.new(a.X*b,a.Y*b,a.Z*b)
end
V.__div=function(a,b) return a*(1/b) end
function V:Dot(b) return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
function V:Cross(b) return Vector3.new(self.Y*b.Z-self.Z*b.Y,self.Z*b.X-self.X*b.Z,self.X*b.Y-self.Y*b.X) end
function V:Lerp(b,t) return self+(b-self)*t end

local CF={}
CF.__index=function(c,k)
 if k=="Position" or k=="p" then return c.position end
 if k=="RightVector" then return Vector3.new(c.r[1],c.r[4],c.r[7]) end
 if k=="UpVector" then return Vector3.new(c.r[2],c.r[5],c.r[8]) end
 if k=="LookVector" then return -Vector3.new(c.r[3],c.r[6],c.r[9]) end
 return CF[k]
end
local function frame(p,r) return setmetatable({position=p,r=r},CF) end
CFrame={}
function CFrame.new(x,y,z)
 if type(x)=="table" then return frame(x,{1,0,0,0,1,0,0,0,1}) end
 return frame(Vector3.new(x,y,z),{1,0,0,0,1,0,0,0,1})
end
CFrame.identity=CFrame.new()
function CFrame.fromMatrix(p,x,y,z)
 z=z or x:Cross(y)
 return frame(p,{x.X,y.X,z.X,x.Y,y.Y,z.Y,x.Z,y.Z,z.Z})
end
local function rotate(c,v)
 local r=c.r
 return Vector3.new(r[1]*v.X+r[2]*v.Y+r[3]*v.Z,r[4]*v.X+r[5]*v.Y+r[6]*v.Z,r[7]*v.X+r[8]*v.Y+r[9]*v.Z)
end
CF.__mul=function(a,b)
 if getmetatable(b)==V then return a.position+rotate(a,b) end
 local out={}
 for i=0,2 do for j=1,3 do
  out[i*3+j]=a.r[i*3+1]*b.r[j]+a.r[i*3+2]*b.r[3+j]+a.r[i*3+3]*b.r[6+j]
 end end
 return frame(a.position+rotate(a,b.position),out)
end
CF.__add=function(a,b) return frame(a.position+b,a.r) end
CF.__sub=function(a,b) return frame(a.position-b,a.r) end
function CFrame.Angles(x,y,z)
 local sx,cx,sy,cy,sz,cz=math.sin(x),math.cos(x),math.sin(y),math.cos(y),math.sin(z),math.cos(z)
 return frame(Vector3.zero,{1,0,0,0,cx,-sx,0,sx,cx})
  *frame(Vector3.zero,{cy,0,sy,0,1,0,-sy,0,cy})
  *frame(Vector3.zero,{cz,-sz,0,sz,cz,0,0,0,1})
end
function CF:Inverse()
 local r=self.r
 local inverse=frame(Vector3.zero,{r[1],r[4],r[7],r[2],r[5],r[8],r[3],r[6],r[9]})
 inverse.position=rotate(inverse,-self.position)
 return inverse
end
function CF:GetComponents() return self.position.X,self.position.Y,self.position.Z,table.unpack(self.r) end

Color3={}
function Color3.fromRGB(r,g,b) return {R=r/255,G=g/255,B=b/255} end
function Color3.new(r,g,b) return {R=r,G=g,B=b} end
local colorMethods={}
function colorMethods:Lerp(other,t)
 return Color3.new(self.R+(other.R-self.R)*t,self.G+(other.G-self.G)*t,self.B+(other.B-self.B)*t)
end
local rgbConstructor,colorConstructor=Color3.fromRGB,Color3.new
function Color3.fromRGB(r,g,b) return setmetatable(rgbConstructor(r,g,b),{__index=colorMethods}) end
function Color3.new(r,g,b) return setmetatable(colorConstructor(r,g,b),{__index=colorMethods}) end
Enum={Material={Metal="Metal",Neon="Neon",SmoothPlastic="SmoothPlastic"},PartType={Block="Block",Ball="Ball",Cylinder="Cylinder"}}
Enum.SurfaceType={Smooth="Smooth"}
local methods={}
local I={}
I.__index=function(i,k)
 if k=="Position" and i._props.CFrame then return i._props.CFrame.Position end
 return methods[k] or i._props[k]
end
I.__newindex=function(i,k,v)
 if k=="Position" and i._props.CFrame then
  local rotation=i._props.CFrame-i._props.CFrame.Position
  i._props.CFrame=CFrame.new(v)*rotation
  return
 end
 if k=="Parent" then
  local old=i._props.Parent
  if old then for n,c in ipairs(old._children) do if c==i then table.remove(old._children,n); break end end end
  if v then v._children[#v._children+1]=i end
 end
 i._props[k]=v
end
Instance={}
function Instance.new(class,parent)
 assert(class=="Model" or class=="Folder" or class=="Part" or class=="WedgePart" or class=="CornerWedgePart" or class=="MeshPart","unsupported geometry instance "..class)
 local i=setmetatable({_class=class,_children={},_attrs={},_props={Name=class}},I)
 if class~="Model" and class~="Folder" then
  i.CFrame=CFrame.new(); i.Size=Vector3.new(1,1,1); i.Color=Color3.new(1,1,1)
  i.Material="SmoothPlastic"; i.Shape="Block"; i.Transparency=0
  i.Anchored=false; i.CanCollide=true; i.CanQuery=true; i.CanTouch=true
 end
 i.Parent=parent
 return i
end
function methods:SetAttribute(k,v) self._attrs[k]=v end
function methods:GetAttribute(k) return self._attrs[k] end
function methods:GetChildren() return self._children end
function methods:GetDescendants()
 local out={}
 local function walk(i) for _,c in ipairs(i._children) do out[#out+1]=c; walk(c) end end
 walk(self); return out
end
function methods:IsA(class)
 local parts={Part=true,WedgePart=true,CornerWedgePart=true,MeshPart=true}
 return self._class==class or (class=="BasePart" and parts[self._class]==true)
end
function methods:GetPivot() return self._props._pivot or (self.PrimaryPart and self.PrimaryPart.CFrame) or CFrame.new() end
function methods:PivotTo(cf)
 local transform=cf*self:GetPivot():Inverse()
 for _,p in ipairs(self:GetDescendants()) do if p:IsA("BasePart") then p.CFrame=transform*p.CFrame end end
 self._props._pivot=cf
end

local function json(value)
 local kind=type(value)
 if kind=="string" then return '"'..value:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r')..'"' end
 if kind=="number" then assert(value==value and math.abs(value)<math.huge,"nonfinite value"); return string.format("%.12g",value) end
 if kind=="boolean" then return tostring(value) end
 assert(kind=="table","unsupported JSON value")
 local out={}
 if #value>0 then for _,v in ipairs(value) do out[#out+1]=json(v) end; return "["..table.concat(out,",").."]" end
 for k,v in pairs(value) do out[#out+1]=json(k)..":"..json(v) end
 table.sort(out); return "{"..table.concat(out,",").."}"
end

-- Roblox scalar and frame features used by procedural model builders.
Vector3.one=Vector3.new(1,1,1)
Vector3.xAxis=Vector3.new(1,0,0)
Vector3.yAxis=Vector3.new(0,1,0)
Vector3.zAxis=Vector3.new(0,0,1)
function Color3.fromHSV(h,s,v)
 h=h%1; local i=math.floor(h*6); local f=h*6-i
 local p,q,t=v*(1-s),v*(1-f*s),v*(1-(1-f)*s)
 local colors={{v,t,p},{q,v,p},{p,v,t},{p,q,v},{t,p,v},{v,p,q}}
 return Color3.new(table.unpack(colors[i%6+1]))
end
local originalCFNew=CFrame.new
function CFrame.lookAt(position,target,up)
 up=up or Vector3.yAxis
 local direction=position-target
 if direction.Magnitude<1e-8 then return originalCFNew(position) end
 local back=direction.Unit
 local right=up:Cross(back)
 if right.Magnitude<1e-8 then right=Vector3.xAxis:Cross(back) end
 right=right.Unit
 return CFrame.fromMatrix(position,right,back:Cross(right).Unit,back)
end
function CFrame.new(x,y,z)
 if getmetatable(x)==V and getmetatable(y)==V then return CFrame.lookAt(x,y) end
 return originalCFNew(x,y,z)
end
function CFrame.lookAlong(position,direction,up) return CFrame.lookAt(position,position+direction,up) end
function CF:PointToWorldSpace(v) return self*v end
function CF:PointToObjectSpace(v) return self:Inverse()*v end
function CF:VectorToWorldSpace(v) return rotate(self,v) end
function CF:VectorToObjectSpace(v) return rotate(self:Inverse(),v) end
function CF:ToObjectSpace(other) return self:Inverse()*other end
function CF:ToWorldSpace(other) return self*other end
local originalCFIndex=CF.__index
CF.__index=function(c,k)
 if k=="Rotation" then return frame(Vector3.zero,c.r) end
 return originalCFIndex(c,k)
end
for _,category in pairs(Enum) do
 setmetatable(category,{__index=function(t,k) rawset(t,k,k); return k end})
end
setmetatable(Enum,{__index=function(t,k)
 local category=setmetatable({},{__index=function(c,key) rawset(c,key,key); return key end})
 rawset(t,k,category); return category
end})
local originalInstanceIndex=I.__index
I.__index=function(i,k)
 local value=originalInstanceIndex(i,k)
 if value~=nil then return value end
 for _,child in ipairs(i._children) do if child.Name==k then return child end end
end
function methods:FindFirstChild(name,recursive)
 for _,child in ipairs(self._children) do
  if child.Name==name then return child end
  if recursive then local found=child:FindFirstChild(name,true); if found then return found end end
 end
end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name),"missing mock child "..name) end
function methods:GetFullName()
 return self.Parent and (self.Parent:GetFullName().."."..self.Name) or self.Name
end
function methods:Destroy()
 self.Parent=nil
 for _,child in ipairs(self:GetChildren()) do child:Destroy() end
 self._children={}
end
function typeof(value)
 if getmetatable(value)==V then return "Vector3" end
 if getmetatable(value)==CF then return "CFrame" end
 if getmetatable(value)==I then return "Instance" end
 return type(value)
end
if not math.clamp then function math.clamp(x,lo,hi) return math.max(lo,math.min(hi,x)) end end
if not table.clone then function table.clone(t) local copy={}; for k,v in pairs(t) do copy[k]=v end; return copy end end
if not table.clear then function table.clear(t) for k in pairs(t) do t[k]=nil end end end
warn=function(...) io.stderr:write(table.concat({...}," ").."\n") end

-- Filesystem-backed ModuleScript tree. Each module receives its own script and require.
local Mock={json=json}
local moduleCache,nodeCache={},{}
local function normalize(path)
 local prefix=path:sub(1,1)=="/" and "/" or ""
 local out={}
 for segment in path:gmatch("[^/]+") do
  if segment==".." and #out>0 and out[#out]~=".." then table.remove(out)
  elseif segment~="." and segment~="" then out[#out+1]=segment end
 end
 return prefix..table.concat(out,"/")
end
local function dirname(path) return path:match("^(.*)/[^/]+$") or "." end
local function exists(path) local f=io.open(path,"r"); if f then f:close(); return true end; return false end
local Node={}
local function node(path)
 path=normalize(path)
 if nodeCache[path] then return nodeCache[path] end
 local value=setmetatable({_path=path},Node); nodeCache[path]=value; return value
end
local function childNode(parent,key,required)
 local path=normalize(parent._path.."/"..key)
 if exists(path..".lua") then return node(path..".lua") end
 if exists(path.."/init.lua") then return node(path.."/init.lua") end
 if required then return node(path) end
 return nil
end
Node.__index=function(n,k)
 if k=="Name" then return n._path:match("([^/]+)$"):gsub("%.lua$","") end
 if k=="Parent" then return node(dirname(n._path)) end
 if k=="ClassName" then return n._path:match("%.lua$") and "ModuleScript" or "Folder" end
 if k=="FindFirstChild" then return function(self,name) return childNode(self,name,false) end end
 if k=="WaitForChild" then return function(self,name) return childNode(self,name,true) end end
 if k=="IsA" then return function(self,class) return self.ClassName==class end end
 if k=="GetFullName" then return function(self) return self._path end end
 return childNode(n,k,true)
end
local originalRequire=require
function Mock.loadModule(path)
 if type(path)=="table" and path._path then path=path._path end
 path=normalize(path)
 if not path:match("%.lua$") then path=path..".lua" end
 if moduleCache[path]~=nil then
  assert(moduleCache[path]~=false,"circular mock require: "..path)
  return moduleCache[path]
 end
 local environment=setmetatable({script=node(path)},{__index=_G})
 environment.require=function(target)
  if type(target)=="table" and target._path then return Mock.loadModule(target._path) end
  if type(target)=="string" and target:match("%.lua$") then return Mock.loadModule(target) end
  return originalRequire(target)
 end
 local chunk,err=loadfile(path,"t",environment)
 assert(chunk,err)
 moduleCache[path]=false
 local ok,result=pcall(chunk)
 if not ok then moduleCache[path]=nil; error(result,0) end
 assert(result~=nil,"module returned nil: "..path)
 moduleCache[path]=result
 return result
end
function Mock.bounds(model)
 local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") and part~=model.PrimaryPart then
   local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22=part.CFrame:GetComponents()
   local sx,sy,sz=part.Size.X*.5,part.Size.Y*.5,part.Size.Z*.5
   local hx,hy,hz=math.abs(r00)*sx+math.abs(r01)*sy+math.abs(r02)*sz,
    math.abs(r10)*sx+math.abs(r11)*sy+math.abs(r12)*sz,
    math.abs(r20)*sx+math.abs(r21)*sy+math.abs(r22)*sz
   lo=Vector3.new(math.min(lo.X,x-hx),math.min(lo.Y,y-hy),math.min(lo.Z,z-hz))
   hi=Vector3.new(math.max(hi.X,x+hx),math.max(hi.Y,y+hy),math.max(hi.Z,z+hz))
  end
 end
 return lo,hi
end
function Mock.record(model)
 assert(model and model.PrimaryPart,"model root missing")
 local result={name=model.Name,attributes=model._attrs,parts={}}
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") then
   assert(part.Anchored,"procedural parts must be anchored")
   assert(type(part.Material)=="string","invalid material assignment on "..part.Name)
   assert(part.Size.X>0 and part.Size.Y>0 and part.Size.Z>0,"invalid part dimensions")
   result.parts[#result.parts+1]={name=part.Name,class=part._class,
    size={part.Size.X,part.Size.Y,part.Size.Z},cf={part.CFrame:GetComponents()},
    color={part.Color.R,part.Color.G,part.Color.B},material=part.Material,
    shape=part.Shape,transparency=part.Transparency or 0,reflectance=part.Reflectance or 0,
    castShadow=part.CastShadow~=false,
    canCollide=part.CanCollide,canQuery=part.CanQuery,canTouch=part.CanTouch,
    primary=part==model.PrimaryPart}
  end
 end
 local lo,hi=Mock.bounds(model)
 result.bounds={min={lo.X,lo.Y,lo.Z},max={hi.X,hi.Y,hi.Z},size={hi.X-lo.X,hi.Y-lo.Y,hi.Z-lo.Z}}
 local declared=model:GetAttribute("PartCount")
 if declared~=nil then assert(declared==#result.parts,"part count metadata mismatch") end
 return result
end
return Mock
