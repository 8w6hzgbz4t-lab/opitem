-- Owner-uploaded audio goes here. Zero IDs use built-in SFX, and leave music off.
-- These files contain an original score; upload the supplied assets to this experience owner.
return {
 Music={AssetId=0,Volume=.18,PlaybackSpeed=1,Title='Relic Rivalry'},
 EffectsVolume=.55,
 MaxSimultaneous=12,
 MaxDistance=160,
 PowerPitch={tag=1.25,dash=1.3,gravity=.8,slow=.9,slam=.72,repulse=.86,shield=1.12,lightning=1.18,kiblast=1.08,spinjitzu=.84,royalseal=.75},
 Cues={
  powerCast={AssetId=0,File='power-cast.wav',Fallback='rbxasset://sounds/electronicpingshort.wav',Volume=.42,Speed=.8,Gap=.12},
  powerHit={AssetId=0,File='power-hit.wav',Fallback='rbxasset://sounds/action_footsteps_plastic.mp3',Volume=.5,Speed=1.05,Gap=.1},
  shield={AssetId=0,File='shield.wav',Fallback='rbxasset://sounds/electronicpingshort.wav',Volume=.42,Speed=1.45,Gap=.15},
  purchase={AssetId=0,File='purchase.wav',Fallback='rbxasset://sounds/electronicpingshort.wav',Volume=.48,Speed=1.3,Gap=.18},
  lost={AssetId=0,File='item-lost.wav',Fallback='rbxasset://sounds/action_jump.mp3',Volume=.5,Speed=.72,Gap=.2},
  deliver={AssetId=0,File='delivered.wav',Fallback='rbxasset://sounds/electronicpingshort.wav',Volume=.52,Speed=1.7,Gap=.2},
  lock={AssetId=0,File='base-lock.wav',Fallback='rbxasset://sounds/electronicpingshort.wav',Volume=.48,Speed=.65,Gap=.35},
  unlock={AssetId=0,File='base-unlock.wav',Fallback='rbxasset://sounds/electronicpingshort.wav',Volume=.36,Speed=.9,Gap=.35},
  levelup={AssetId=0,File='level-up.wav',Fallback='rbxasset://sounds/electronicpingshort.wav',Volume=.58,Speed=1.8,Gap=.4},
  ui={AssetId=0,File='ui-tick.wav',Fallback='rbxasset://sounds/button.wav',Volume=.2,Speed=1.25,Gap=.08},
 },
}
