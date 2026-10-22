-- Actual ItemPromptClient labels and lifecycle with event/replication doubles.
return function(package,require,setGlobals)
 local checks=0;local groups={}
 local function check(value,message)checks+=1;assert(value,message)end
 local signals={}
 local function signal()
  local s={listeners={}};signals[#signals+1]=s
  function s:Connect(callback)
   local connection={Connected=true,callback=callback};self.listeners[#self.listeners+1]=connection
   function connection:Disconnect()self.Connected=false end
   return connection
  end
  function s:Fire(...)
   for _,connection in ipairs(table.clone(self.listeners))do if connection.Connected then connection.callback(...)end end
  end
  function s:count()local n=0;for _,c in ipairs(self.listeners)do if c.Connected then n+=1 end end;return n end
  return s
 end
 local service={PromptShown=signal(),PromptHidden=signal()}
 local space={DescendantAdded=signal(),children={}}
 function space:GetDescendants()return table.clone(self.children)end
 local owner={UserId=77};local visitor={UserId=88}
 local function prompt(class)
  local object={attributes={},attributeSignals={},propertySignals={},inside=true,ClassName=class or'ProximityPrompt',AncestryChanged=signal(),Destroying=signal(),properties={ActionText='Original',Enabled=true}}
  local mt={}
  mt.__index=function(o,key)
   if key=='ActionText'or key=='Enabled'then return o.properties[key]end
  end
  mt.__newindex=function(o,key,value)
   if key=='ActionText'or key=='Enabled'then
    local previous=o.properties[key];o.properties[key]=value
    if previous~=value and o.propertySignals[key]then o.propertySignals[key]:Fire()end
   else rawset(o,key,value)end
  end
  setmetatable(object,mt)
  function object:IsA(kind)return kind==self.ClassName end
  function object:IsDescendantOf(parent)return self.inside and parent==space end
  function object:GetAttribute(key)return self.attributes[key]end
  function object:SetAttribute(key,value)
   local previous=self.attributes[key];self.attributes[key]=value
   if previous~=value and self.attributeSignals[key]then self.attributeSignals[key]:Fire()end
  end
  function object:GetAttributeChangedSignal(key)
   self.attributeSignals[key]=self.attributeSignals[key]or signal();return self.attributeSignals[key]
  end
  function object:GetPropertyChangedSignal(key)
   self.propertySignals[key]=self.propertySignals[key]or signal();return self.propertySignals[key]
  end
  function object:Destroy()self.Destroying:Fire();self.inside=false;self.AncestryChanged:Fire()end
  function object:connectionCount()
   local n=self.AncestryChanged:count()+self.Destroying:count()
   for _,s in pairs(self.attributeSignals)do n+=s:count()end
   for _,s in pairs(self.propertySignals)do n+=s:count()end
   return n
  end
  return object
 end
 local function tagged(ownerId,state,price)
  local q=prompt();q:SetAttribute('OPItemPrompt',true);q:SetAttribute('ItemUID','stored-1')
  q:SetAttribute('ItemOwnerUserId',ownerId);q:SetAttribute('ItemState',state or'Stored');q:SetAttribute('SellPrice',price or 500)
  return q
 end
 local own=tagged(77,'Stored',500);own.ActionText='Interact'
 local other=tagged(88,'Stored',500);other.ActionText='Interact'
 local untagged=prompt();untagged.ActionText='Protect';local part=prompt('Part')
 space.children={own,other,untagged,part}
 setGlobals({workspace=space,game={GetService=function(_,name)
  if name=='ProximityPromptService'then return service end
  if name=='Players'then return{LocalPlayer=owner}end
  error('Unexpected client service '..name)
 end}})
 local client=require(package.ItemPromptClient)
 local session=client.start({},owner)
 check(session~=nil and client.start({},owner)==session,'Duplicate start created another prompt session')
 check(own.ActionText=='Sell · $500 (50%)','Own stored item does not show Sell payout before first display')
 check(other.ActionText=='Steal','Another owner item does not show Steal')
 check(untagged.ActionText=='Protect'and part:connectionCount()==0,'Unrelated world objects were changed')
 check(own.Enabled and other.Enabled,'Client changed server-owned prompt Enabled')
 check(service.PromptShown:count()==1 and service.PromptHidden:count()==1 and space.DescendantAdded:count()==1,'Client service listeners duplicated')
 service.PromptShown:Fire(own)
 check(own.ActionText=='Sell · $500 (50%)','Shown owner prompt displayed Steal')
 local baselineConnections=own:connectionCount()
 for _=1,10 do service.PromptHidden:Fire(own);service.PromptShown:Fire(own)end
 check(own:connectionCount()==baselineConnections,'Repeated show/hide added listeners')
 own.ActionText='Steal'
 check(own.ActionText=='Sell · $500 (50%)','Server default text overwrote local ownership label')
 own:SetAttribute('SellPrice',123456789)
 check(own.ActionText=='Sell · $123456789 (50%)','Sale payout metadata did not refresh exactly')
 own:SetAttribute('SellPrice',0/0)
 check(own.ActionText=='Sell (50%)','Malformed sale value was displayed')
 own:SetAttribute('ItemState','TheftCarry')
 check(own.ActionText=='In transit','Carried item still advertises Sell or Steal')
 own:SetAttribute('ItemOwnerUserId',88);own:SetAttribute('ItemState','Stored')
 check(own.ActionText=='Steal','Former owner still sees Sell after completed ownership transfer')
 own:SetAttribute('ItemState','TheftCarry');own:SetAttribute('ItemOwnerUserId',77);own:SetAttribute('ItemState','Stored');own:SetAttribute('SellPrice',700)
 check(own.ActionText=='Sell · $700 (50%)','Return/new owner metadata did not restore Sell')
 own:SetAttribute('ItemOwnerUserId',nil)
 check(own.ActionText=='Interact','Incomplete owner replication briefly advertised Steal')
 own:SetAttribute('ItemOwnerUserId',77)
 check(own.ActionText=='Sell · $700 (50%)','Owner arrival did not refresh incomplete metadata')
 for _,state in ipairs({'Conveyor','Contesting','Auction'})do own:SetAttribute('ItemState',state);check(own.ActionText=='Buy','Conveyor/bid state did not show Buy: '..state)end
 own:SetAttribute('ItemState','PurchaseCarry');check(own.ActionText=='In transit','Purchased carry still advertises Buy')
 own:SetAttribute('ItemState','Stored');own:SetAttribute('ItemUID',nil)
 check(own.ActionText=='Interact','Prompt with no UID advertised a sale')
 groups[#groups+1]='Owner Sell, visitor Steal, exact payout, live ownership/state updates, neutral incomplete metadata and no authority changes'

 local late=prompt();late.ActionText='Interact';space.children[#space.children+1]=late;space.DescendantAdded:Fire(late)
 check(late.ActionText=='Interact','Untagged creation was rewritten')
 late:SetAttribute('OPItemPrompt',true)
 check(late.ActionText=='Interact','Tag-only prompt advertises an unverified operation')
 late:SetAttribute('ItemUID','new-item');late:SetAttribute('ItemOwnerUserId',77);late:SetAttribute('SellPrice',250);late:SetAttribute('ItemState','Stored')
 check(late.ActionText=='Sell · $250 (50%)','Late tagged prompt did not bind before show')
 service.PromptHidden:Fire(late);late:SetAttribute('ItemOwnerUserId',88)
 check(late.ActionText=='Steal','Hidden ownership change was not prepared for next show')
 local shownLate=tagged(77,'Stored',900);service.PromptShown:Fire(shownLate)
 check(shownLate.ActionText=='Sell · $900 (50%)','Already-shown prompt was not discovered')
 service.PromptShown:Fire(untagged)
 check(untagged.ActionText=='Protect','Unrelated shown prompt was rewritten')
 late.inside=false;late.AncestryChanged:Fire()
 check(late:connectionCount()==0,'Prompt moved out of workspace retained observers')
 late.ActionText='Outside';late:SetAttribute('ItemOwnerUserId',77)
 check(late.ActionText=='Outside','Removed prompt still receives label updates')
 shownLate:Destroy()
 check(shownLate:connectionCount()==0,'Destroyed prompt retained observers')
 session.destroy();session.destroy()
 check(own:connectionCount()==0 and other:connectionCount()==0 and untagged:connectionCount()==0,'Session cleanup leaked prompt observers')
 check(service.PromptShown:count()==0 and service.PromptHidden:count()==0 and space.DescendantAdded:count()==0,'Session cleanup leaked global listeners')
 other.ActionText='Stopped';other:SetAttribute('ItemOwnerUserId',77)
 check(other.ActionText=='Stopped','Destroyed session still changes prompt labels')
 groups[#groups+1]='Late replication, hidden/show lifecycle, unrelated prompts, reparent/destroy cleanup and duplicate-start safety'

 other:SetAttribute('ItemOwnerUserId',88);other:SetAttribute('ItemUID','stored-2')
 local visitorSession=client.start({},visitor)
 check(other.ActionText=='Sell · $500 (50%)','Different account cannot see Sell on its own item')
 own:SetAttribute('ItemUID','stored-1');own:SetAttribute('ItemOwnerUserId',77);own:SetAttribute('ItemState','Stored')
 check(own.ActionText=='Steal','Different account cannot see Steal on the former owner item')
 visitorSession.destroy()
 check(other.Enabled and own.Enabled,'Client lifecycle changed server-owned availability')
 groups[#groups+1]='Independent viewer semantics on a fresh client session'
 return{assertions=checks,groups=groups}
end
