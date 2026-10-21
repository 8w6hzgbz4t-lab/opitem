-- Execute the real Server snapshot/audio glue with controlled recipients.
return function(sources)
 local checks=0
 local function check(v,msg)checks+=1;assert(v,msg)end
 local owner={UserId=77,Parent=true};local other={UserId=88,Parent=true}
 local delivered,cues,broadcast={},{},{}
 local snapshots={}
 local mode=false;local studio=false
 local env=setmetatable({
  core={players={[77]={settings={musicVolume=.3},tutorialCompleted=true,paidCashCredit=5},[88]={settings={},tutorialCompleted=false}},snapshot=function(_,id)
   local out=table.clone(snapshots[id]or{cash=100,level=0,lock=0});return out
  end},
  admin={isDeveloperMode=function(_,p)return p==owner and mode end,
   authorized=function(_,p)return p==owner end,getState=function()return{royalSealRemaining=8.5}end},
  persistence={pendingSettings={},isReady=function()return true end},phase={battles=function()return{}end},Run={IsStudio=function()return studio end},
  runtime={[77]={},[88]={}},
  update={FireClient=function(_,p,data)delivered[#delivered+1]={p=p,data=data}end},
  audioEvent={FireClient=function(_,p,data)cues[#cues+1]={p=p,data=data}end,
   FireAllClients=function(_,data)broadcast[#broadcast+1]=data end},
 },{__index=getfenv()})
 local sf=assert(loadstring(sources.sound..'\nreturn sound'));setfenv(sf,env);env.sound=sf()
 local chunk=assert(loadstring(sources.send..'\nreturn send'));setfenv(chunk,env);local send=chunk()
 send(other);check(delivered[1].p==other and not delivered[1].data.developerAbility,'Normal account received developer metadata')
 send(owner);check(not delivered[2].data.developerAbility,'Mode-off owner received fourth slot')
 mode=true;send(owner)
 local d=delivered[3].data.developerAbility
 check(d.id=='royalseal'and d.mode and d.enabled and d.remaining==8.5,'Owner fourth-slot cooldown not wired to backend')
 send(other);check(not delivered[4].data.developerAbility and not delivered[4].data.studio,'Owner state leaked to another account')
 studio=true;send(other);send(owner)
 check(not delivered[5].data.studio and delivered[6].data.studio,'Studio grant visibility ignores authorization')
 mode=false;send(owner);check(not delivered[#delivered].data.developerAbility,'Mode-off snapshot failed to remove slot')
 snapshots[77]={cash=80,level=1,lock=10,carry='uid1'};send(owner)
 check(#cues==2 and cues[1].data.kind=='levelup'and cues[2].data.kind=='purchase','Level/pickup sounds missing')
 send(owner);check(#cues==2,'Repeated snapshots replayed pickup/level audio')
 snapshots[77]={cash=80,level=1,lock=0};send(owner)
 check(#cues==3 and cues[3].data.kind=='unlock','Protection expiry sound missing')
 send(owner);check(#cues==3,'Expiry sound repeated')
 snapshots[77]={cash=80,level=1,lock=0,carry='uid2'};send(owner)
 check(#cues==4 and cues[4].data.kind=='purchase','Next pickup sound missing')
 env.sound(owner,'powerCast','lightning',{X=1,Y=2,Z=3})
 check(#broadcast==1 and broadcast[1].power=='lightning','Positional power cue not shared with nearby listeners')
 env.sound(nil,'lock');env.sound({Parent=false},'lock')
 check(#broadcast==1 and #cues==4,'Unavailable player produced audio')
 check(delivered[#delivered].data.mode=='STUDIO TEST SAVES','Saved profile status missing')
 check(delivered[#delivered].data.settings.musicVolume==.3 and delivered[#delivered].data.settings.tutorialCompleted==true,'Saved settings/tutorial not wired')
 env.core.persistenceBusy=true;local count=#delivered;send(owner);check(#delivered==count,'Unconfirmed memory must not be sent while saving')
 local notice=assert(loadstring(sources.ownerAlert..'\nreturn ownerAlert'));setfenv(notice,env);local ownerAlert=notice()
 local count=#delivered
 for _,kind in ipairs({'taken','stolen','recovered'})do
  ownerAlert(owner,kind,'Millennium Puzzle','Raider')
  local alert=delivered[#delivered]
  check(alert.p==owner and alert.data.theftAlert.kind==kind,'Theft alert recipient/status incorrect')
  check(alert.data.theftAlert.item=='Millennium Puzzle'and alert.data.theftAlert.thief=='Raider','Theft alert omitted item/raider')
 end
 check(#delivered==count+3,'Owner theft alerts were broadcast to other accounts')
 ownerAlert(nil,'taken','Item','Raider');ownerAlert({Parent=false},'stolen','Item','Raider')
 check(#delivered==count+3,'Disconnected owner received an alert')
 print('SERVER INTEGRATION PASS '..checks..' assertions')
end
