-- What the roster and the result screen say and do for a kit on the masters'
-- path (DEC-037; beta loop, user 13/11: « qu'on soit proche de la vraie boucle
-- du jeu »). Pure: the client's UI reads it, the headless suites test it.
-- `kits` is the server's Progression.view (nil when the path is off: every
-- kit is open, as before).
local Masters=require(script.Parent.Masters)
local Fighters=require(script.Parent.Fighters)
local Text=require(script.Parent.Text)
local V={}

local function name(id)
	local def=Fighters[id]
	return Text.upper(def and def.Name or tostring(id))
end
local function names(list)
	local out={}
	for _,id in list do table.insert(out,name(id)) end
	return table.concat(out," OR ")
end

-- The masters this kit leads to (whose kit its mastery opens).
function V.leadsTo(id)
	local out={}
	for _,master in Masters.Kits do
		local rule=Masters.Map[master]
		if rule and table.find(rule.from,id) then table.insert(out,master) end
	end
	return out
end

function V.on(kits) return kits~=nil end

-- open (no path) · loading · starter / starterLocked (a new player's choice) ·
-- owned · master (his master teaches now) · locked
function V.status(kits,id)
	if not kits then return "open" end
	if kits.state=="loading" or kits.state=="none" then return "loading" end
	if kits.owned and kits.owned[id] then return "owned" end
	if kits.needStarter then return if Masters.isStarter(id) then "starter" else "starterLocked" end
	local m=kits.masters and kits.masters[id]
	if m and m.ready then return "master" end
	return "locked"
end

-- The tablet on the roster: dimmed when locked, a tag, mastery 0..1.
function V.tablet(kits,id)
	local status=V.status(kits,id)
	local mastery=kits and kits.mastery and kits.mastery[id] or 0
	return {
		status=status,
		locked=status=="locked" or status=="starterLocked" or status=="master",
		tag=if status=="master" then "MASTER" elseif status=="locked" or status=="starterLocked" then "LOCKED"
			elseif status=="starter" then "START" else "",
		progress=if status=="owned" then math.clamp(mastery/Masters.Need,0,1) else nil,
	}
end

-- What pressing the stage button does with this kit picked, its label, and
-- the line under the fighter's name. kind: play (as before) · choose (the
-- first kit) · master (his master's duel, fought with `via`) · try (practice
-- with it) · wait (the profile is loading).
function V.action(kits,id)
	local status=V.status(kits,id)
	local who=name(id)
	if status=="open" then return {kind="play"} end
	if status=="loading" then return {kind="wait",label="LOADING YOUR KITS…",note="Your ninja's kits are on their way."} end
	if status=="starter" then
		return {kind="choose",label="TAKE THIS KIT",
			note="YOUR FIRST KIT: "..names(Masters.Starters)..". Every other kit is taught by its master."}
	end
	if status=="starterLocked" then
		return {kind="try",label="TRY IN TRAINING",
			note=who.." TEACHES HIS KIT LATER. FIRST, TAKE "..names(Masters.Starters).."."}
	end
	if status=="owned" then
		local mastery=kits.mastery and kits.mastery[id] or 0
		local leads=V.leadsTo(id)
		local note="MASTERY "..mastery
		if #leads>0 then note..="  •  "..Masters.Need.." OPENS "..names(leads) end
		return {kind="play",note=note}
	end
	local m=kits.masters and kits.masters[id] or {}
	if status=="master" then
		return {kind="master",label="DUEL THE MASTER",via=m.via,
			note=who.." WAITS FOR YOU. BEAT HIM WITH "..name(m.via).." AND HIS KIT IS YOURS."}
	end
	local rule=Masters.Map[id]
	local from=if rule then names(rule.from) else "HIS MASTER"
	return {kind="try",label="TRY IN TRAINING",product=m.product,
		note=string.format("%s TEACHES WHOEVER HAS %d MASTERY WITH %s (BEST: %d).",who,Masters.Need,from,m.best or 0)}
end

-- The result screen's line: mastery earned, a kit learned, a master waiting.
function V.result(progress,kits)
	if type(progress)~="table" then return nil end
	if progress.learned then return name(progress.learned).."'S KIT IS YOURS  •  PICK IT ON THE ROSTER" end
	if not progress.gained then return nil end
	local line=string.format("+%d MASTERY  •  %s %d / %d",progress.amount or 0,name(progress.fighter),progress.mastery or 0,progress.need or Masters.Need)
	if (progress.mastery or 0)>=(progress.need or Masters.Need) then
		local leads={}
		for _,master in V.leadsTo(progress.fighter) do
			if not (kits and kits.owned and kits.owned[master]) then table.insert(leads,master) end
		end
		if #leads>0 then line..="  •  "..names(leads).." WILL TEACH YOU" end
	end
	return line
end

return V
