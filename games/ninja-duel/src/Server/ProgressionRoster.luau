-- Future policy boundary only. Never gates local selection or applies stats.
local S=require(script.Parent.ProfileSchema)
local P=require(script.Parent.CharacterProgression)
local R={Modes={Local=true,Ranked=true,ProgressionBattles=true}}
function R.list(cfg,profile,mode)
 assert(R.Modes[mode],"Unknown experience mode")
 local ids={};for id in cfg.Characters do if mode=="Local" or (profile and profile.collection[id]) then table.insert(ids,id) end end
 table.sort(ids);return ids
end
function R.select(cfg,profile,mode,id)
 if not R.Modes[mode] or not cfg.Characters[id] then return nil,"Unknown mode / character" end
 if mode~="Local" and (not profile or not profile.collection[id]) then return nil,"Character locked" end
 local ch=profile and profile.characters[id] or S.character()
 return {mode=mode,character=id,normalized=mode=="Ranked",combatApplicationEnabled=false,
  base=P.project(cfg,id,ch,true),potential=P.project(cfg,id,ch,mode~="ProgressionBattles")}
end
-- Separate queues prevent normalized ranked and progression battles mixing.
function R.queueKey(mode,region)
 assert(mode=="Ranked" or mode=="ProgressionBattles","Online mode required")
 assert(S.id(region),"Region label required");return mode..":"..region
end
return R
