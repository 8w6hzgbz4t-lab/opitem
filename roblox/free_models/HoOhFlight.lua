-- Pure decorative flight/pose functions. The caller owns its render connection.
-- Construct Body, LeftWing, RightWing and Tail as child Models with alignBase=false.
-- Every component's PrimaryPart is its original chest-origin Root. Do not reset
-- its pivot to the mesh bounds: the shoulder rotations use that shared origin.
local Flight={}
local TAU=math.pi*2
local V=Vector3.new
local SHOULDER_LEFT=V(-1.08,.61,.02)
local SHOULDER_RIGHT=V(1.08,.61,.02)
local TAIL_SOCKET=V(0,-.66,1.04)

-- origin is the top of the tower and faces the intended initial flight direction.
-- A 32-second uninterrupted ellipse passes close to the bell tower once per loop.
-- Bird faces travel direction; height and bank change gently along the route.
function Flight.position(origin,time)
 local theta=(time or 0)*TAU/32
 local function sample(a)
  return V(22*(1-math.cos(a)),8+3*math.sin(2*a),-20*math.sin(a))
 end
 local localPos=sample(theta)
 local nextPos=sample(theta+.012)
 local bank=-math.sin(theta)*math.rad(13)
 return origin*CFrame.lookAt(localPos,nextPos)*CFrame.Angles(0,0,bank)
end

local function pivotChild(model,name,cf)
 local child=model:FindFirstChild(name)
 if child and child:IsA("Model") then child:PivotTo(cf) end
end

-- Called client-side each frame. No gameplay authority, movement forces or remotes.
-- Decorative bird roots stay anchored and noncolliding throughout the animation.
function Flight.pose(model,origin,time)
 local t=time or 0
 local scale=model:GetAttribute("FlightScale") or 1
 assert(type(scale)=="number" and scale>0,"FlightScale must be positive")
 local flightCF=Flight.position(origin,t)
 local beat=math.sin(t*TAU/1.8)
 local flap=math.rad(22)*beat+math.rad(5)
 local chestBob=CFrame.new(0,.11*math.cos(t*TAU/1.8),0)
 flightCF=flightCF*chestBob
 -- Update only the invisible parent pivot. PivotTo here would move articulated
 -- children a second time and cause their wing/tail transforms to accumulate.
 if model.PrimaryPart then model.PrimaryPart.CFrame=flightCF end
 pivotChild(model,"Body",flightCF)
 pivotChild(model,"LeftWing",flightCF*CFrame.new(SHOULDER_LEFT*scale)*CFrame.Angles(0,0,-flap)*CFrame.new(-SHOULDER_LEFT*scale))
 pivotChild(model,"RightWing",flightCF*CFrame.new(SHOULDER_RIGHT*scale)*CFrame.Angles(0,0,flap)*CFrame.new(-SHOULDER_RIGHT*scale))
 pivotChild(model,"Tail",flightCF*CFrame.new(TAIL_SOCKET*scale)*CFrame.Angles(math.rad(4)*math.sin(t*1.7),math.rad(3)*math.sin(t*.9),0)*CFrame.new(-TAIL_SOCKET*scale))
 return flightCF
end
return Flight
