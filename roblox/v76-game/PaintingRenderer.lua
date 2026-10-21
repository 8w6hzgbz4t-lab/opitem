-- Runtime bitmap from embedded RGB; never uploads an image or requests an asset.
local R={}
function R.mount(board,prefix)
 prefix=prefix or 'ForceOfDespairPainting'
 if board:FindFirstChild('StandalonePainting') then return end
 local dataPrefix=prefix=='ExodiaPainting' and 'ExodiaPaintingData' or (prefix=='EgyptianGodsPainting' and 'GodsPaintingData' or 'PaintingData')
 local chunks={};for i=1,8 do chunks[i]=require(script.Parent[dataPrefix..i]) end;local hex=table.concat(chunks)
 local width,height=192,128
 local gui=Instance.new('SurfaceGui');gui.Name='StandalonePainting';gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(width,height);gui.LightInfluence=.12;gui.MaxDistance=240;gui.Parent=board
 local bytes=buffer.create(width*height*4)
 for i=0,width*height-1 do
  local at=i*6+1;buffer.writeu8(bytes,i*4,tonumber(hex:sub(at,at+1),16));buffer.writeu8(bytes,i*4+1,tonumber(hex:sub(at+2,at+3),16));buffer.writeu8(bytes,i*4+2,tonumber(hex:sub(at+4,at+5),16));buffer.writeu8(bytes,i*4+3,255)
 end
 local image
 local ok=pcall(function()
  image=game:GetService('AssetService'):CreateEditableImage({Size=Vector2.new(width,height)})
  assert(image,'Image memory budget exhausted')
  image:WritePixelsBuffer(Vector2.zero,Vector2.new(width,height),bytes)
  local label=Instance.new('ImageLabel');label.Name='PaintingArtwork';label.BackgroundTransparency=1;label.Size=UDim2.fromScale(1,1);label.ImageContent=Content.fromObject(image);label.Parent=gui
 end)
 if ok then
  gui:SetAttribute('Renderer','EmbeddedBitmap');gui.Destroying:Connect(function()if image then image:Destroy() end end);return
 end
 if image then image:Destroy() end
 -- Studio/account settings may restrict EditableImage. Merge flat color runs as a local fallback.
 gui:ClearAllChildren();gui:SetAttribute('Renderer','PortableMosaic');local active={};local created=0
 for y=0,height-1,2 do
  local runs={};local x=0
  local function colorAt(col)
   local at=(y*width+col)*4
   local r=math.floor(buffer.readu8(bytes,at)/32)*32;local g=math.floor(buffer.readu8(bytes,at+1)/32)*32;local b=math.floor(buffer.readu8(bytes,at+2)/32)*32
   return r*65536+g*256+b,Color3.fromRGB(r,g,b)
  end
  while x<width do
   local key,color=colorAt(x);local last=x+2
   while last<width do local nextKey=colorAt(last);if nextKey~=key then break end;last+=2 end
   local run=x..':'..last..':'..key;local frame=active[run]
   if frame then frame.Size=frame.Size+UDim2.fromOffset(0,2) else
    frame=Instance.new('Frame');frame.BorderSizePixel=0;frame.BackgroundColor3=color;frame.Position=UDim2.fromOffset(x,y);frame.Size=UDim2.fromOffset(last-x,2);frame.Parent=gui;created+=1
   end
   runs[run]=frame;x=last
  end
  active=runs;if y%16==0 then task.wait() end
 end
 gui:SetAttribute('DrawRectangles',created)
end
return R
