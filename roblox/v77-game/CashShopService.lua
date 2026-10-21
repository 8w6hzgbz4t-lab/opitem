-- Prepared cash/level/regular-power storefront. No MarketplaceService callback.
-- This session-only alpha cannot sell durable currency safely. A future live
-- store must grant cash + receipt ID atomically in the persistent player profile.
local S={};S.__index=S
local Powers=require(script.Parent.PowerCatalog)
local cashIds={pocket=true,stack=true,chest=true,fortune=true}
local levelIds={level_one=1,level_five=5}
local normalPowers={dash=true,gravity=true,slow=true,slam=true,repulse=true,shield=true,lightning=true}
local configKeys={Enabled=true,PreviewOnly=true,CashPerRobux=true,Offers=true}
local commonKeys={id=true,name=true,category=true,robux=true,productId=true}
local function positiveInteger(n)
 return type(n)=='number' and n==n and n>0 and n<math.huge and n%1==0
end
function S.validate(config)
 if type(config)~='table' or config.Enabled~=false or config.PreviewOnly~=true then
  return false,'Shop remains preview-only until persistent profiles and atomic receipt grants are installed.'
 end
 for key in pairs(config)do if not configKeys[key]then return false,'Unsupported shop configuration field.'end end
 if not positiveInteger(config.CashPerRobux) or type(config.Offers)~='table' or #config.Offers~=13 then return false,'Expected cash, base level and regular power offers.' end
 for key in pairs(config.Offers)do if type(key)~='number'or key%1~=0 or key<1 or key>13 then return false,'Offer list must be a dense array.'end end
 local ids={};local counts={cash=0,levels=0,powers=0}
 for _,offer in ipairs(config.Offers) do
  if type(offer)~='table' or type(offer.id)~='string' or #offer.id<1 or #offer.id>32 or ids[offer.id]
   or type(offer.name)~='string' or #offer.name<1 or #offer.name>40
   or not positiveInteger(offer.robux) or offer.productId~=0 or not counts[offer.category] then
   return false,'Offers require unique IDs, valid preview prices and supported categories.'
  end
  local effect=offer.category=='powers' and 'power' or offer.category
  for key in pairs(offer)do if not commonKeys[key]and key~=effect then return false,'Only one supported offer effect is allowed.'end end
  if offer.category=='cash' then
   if not cashIds[offer.id]or not positiveInteger(offer.cash)or offer.cash~=offer.robux*config.CashPerRobux then return false,'Cash offers must have proportional prices.'end
  elseif offer.category=='levels' then
   if levelIds[offer.id]~=offer.levels or not positiveInteger(offer.levels)then return false,'Invalid base level offer.'end
  else
   local power=Powers.ById[offer.power]
   if not normalPowers[offer.power]or not power or offer.id~='unlock_'..offer.power
    or offer.robux~=math.ceil(power.price/config.CashPerRobux)then return false,'Only regular power unlocks can be offered.'end
  end
  counts[offer.category]+=1;ids[offer.id]=true
 end
 if counts.cash~=4 or counts.levels~=2 or counts.powers~=7 then return false,'Missing supported shop offers.'end
 return true
end
function S.new(config,ctx)
 local valid,why=S.validate(config);assert(valid,why)
 local offers={}
 for _,offer in ipairs(config.Offers) do offers[#offers+1]={id=offer.id,name=offer.name,category=offer.category,robux=offer.robux,cash=offer.cash,levels=offer.levels,power=offer.power} end
 return setmetatable({ctx=ctx,offers=offers,nextOpen={},clock=ctx.clock or os.clock},S)
end
function S:catalog()
 local offers={};for _,offer in ipairs(self.offers) do offers[#offers+1]=table.clone(offer) end
 return {kind='preview',available=false,configured=false,title='Robux Shop',message='Coming soon • Purchases are not available yet.',offers=offers}
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
 return false,'Purchases are not available yet.'
end
function S:removePlayer(player) self.nextOpen[player.UserId]=nil end
return S
