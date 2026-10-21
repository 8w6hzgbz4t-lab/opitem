-- Prepared cash storefront. Intentionally owns no MarketplaceService callback.
-- This session-only alpha cannot sell durable currency safely. A future live
-- store must grant cash + receipt ID atomically in the persistent player profile.
local S={};S.__index=S
local function positiveInteger(n)
 return type(n)=='number' and n==n and n>0 and n<math.huge and n%1==0
end
function S.validate(config)
 if type(config)~='table' or config.Enabled~=false or config.PreviewOnly~=true then
  return false,'Cash shop remains preview-only until persistent profiles and atomic receipt grants are installed.'
 end
 if not positiveInteger(config.CashPerRobux) or type(config.Packs)~='table' or #config.Packs~=4 then return false,'Invalid cash pack configuration.' end
 local ids={}
 for _,pack in ipairs(config.Packs) do
  if type(pack)~='table' or type(pack.id)~='string' or #pack.id<1 or #pack.id>32 or ids[pack.id]
   or type(pack.name)~='string' or #pack.name<1 or #pack.name>40
   or not positiveInteger(pack.robux) or not positiveInteger(pack.cash)
   or pack.cash~=pack.robux*config.CashPerRobux or pack.productId~=0 then
   return false,'Cash packs must use unique IDs, proportional prices, and unconfigured product IDs.'
  end
  ids[pack.id]=true
 end
 return true
end
function S.new(config,ctx)
 local valid,why=S.validate(config);assert(valid,why)
 local packs={}
 for _,pack in ipairs(config.Packs) do packs[#packs+1]={id=pack.id,name=pack.name,robux=pack.robux,cash=pack.cash} end
 return setmetatable({ctx=ctx,packs=packs,nextOpen={},clock=ctx.clock or os.clock},S)
end
function S:catalog()
 local packs={};for _,pack in ipairs(self.packs) do packs[#packs+1]=table.clone(pack) end
 return {kind='preview',available=false,title='Cash Shop',message='Coming soon • Cash packs are not on sale yet.',packs=packs}
end
function S:open(player)
 if not player or not player.Parent or not self.ctx.core.players[player.UserId] then return false,'Player unavailable.' end
 local root,h=self.ctx.body(player);local anchor=self.ctx.anchor
 if not root or not h or h.Health<=0 or not anchor or not anchor.Parent or (root.Position-anchor.Position).Magnitude>12 then return false,'Visit the cash shop bench.' end
 local now=self.clock();if now<(self.nextOpen[player.UserId] or 0) then return false,'Please wait.' end
 self.nextOpen[player.UserId]=now+.5
 self.ctx.remote:FireClient(player,self:catalog())
 return true
end
function S:request(_player,_payload)
 -- No client payload, product ID, or developer status can enable purchases.
 return false,'Cash packs are not on sale yet.'
end
function S:removePlayer(player) self.nextOpen[player.UserId]=nil end
return S
