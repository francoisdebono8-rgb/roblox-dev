-- Optional intent planner ONLY. Does not bind keys or send/change combat actions.
-- context MUST be resolved by a future host (technique/loadout/mastery/geometry),
-- never accepted as authoritative client data. Hold qualification belongs to Claude.
local S=require(script.Parent.ProfileSchema)
local P={Modes={AutoTechnique=true,Modifier=true,Contextual=true,Loadout=true,HoldRelease=true,CompatibleAuto=true}}
function P.build(cfg,mode,intent,context)
 assert(P.Modes[mode] and S.serializable(intent) and S.serializable(context),"Invalid input proposal")
 assert(type(intent)=="table" and type(context)=="table" and S.id(intent.action) and cfg.Objects[context.tool],"Action/tool required")
 assert(intent.modified==nil or type(intent.modified)=="boolean","Invalid modifier")
 assert(intent.released==nil or type(intent.released)=="boolean","Invalid release")
 local candidate="None"
 if mode=="AutoTechnique" then candidate=context.techniqueInfusion or "None"
 elseif mode=="Modifier" and intent.modified then candidate=context.selectedInfusion or "None"
 elseif mode=="Contextual" and context.compatible==true then candidate=context.contextInfusion or "None"
 elseif mode=="Loadout" then candidate=(context.loadout or {})[context.tool] or "None"
 elseif mode=="HoldRelease" and intent.released and context.holdQualified==true then candidate=context.selectedInfusion or "None"
 elseif mode=="CompatibleAuto" and context.compatible==true and context.availableProperty then candidate=context.propertyInfusion or "None" end
 assert(candidate=="None" or cfg.Infusions[candidate],"Unknown proposed infusion")
 local compatible=candidate=="None" or cfg.Objects[context.tool].infusions[candidate]==true
 return {action=intent.action,mode=mode,candidate=candidate,compatible=compatible,infusion=if compatible then candidate else "None",requiresServerValidation=true,gameplayIntegration=false}
end
return P
