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
		tag=if status=="master" then "READY" elseif status=="locked" or status=="starterLocked" then "LOCKED"
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
			note=who.." COMES LATER. FIRST, CHOOSE "..names(Masters.Starters).."."}
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
		return {kind="master",label="DUEL HIM",via=m.via,
			note=who.." WAITS FOR YOU. BEAT HIM WITH "..name(m.via).." AND HIS KIT IS YOURS."}
	end
	local rule=Masters.Map[id]
	local from=if rule then names(rule.from) else "HIS INSPIRATION"
	return {kind="try",label="TRY IN TRAINING",product=m.product,
		note=string.format("%s OPENS UP TO WHOEVER HAS %d MASTERY WITH %s (BEST: %d).",who,Masters.Need,from,m.best or 0)}
end

-- (14/11, new player's walk) The first kit taken, its first duel not fought
-- yet: that kit's id, else nil. The master's card offers YOUR FIRST DUEL and
-- Konoha's goal and marker point at him until the duel is fought.
function V.firstDuel(kits)
	if not kits or kits.state~="ready" or not kits.starter or not (kits.owned and kits.owned[kits.starter]) then return nil end
	if (kits.mastery and kits.mastery[kits.starter] or 0)~=0 then return nil end
	return kits.starter
end

-- (14/11, new player's walk) Konoha's goal: a short head and the line under
-- it (where to go: `items`, joined in `sub`, or one a line on a narrow
-- screen). Before, one line of a hundred letters ran under the shop
-- and Roblox's buttons; a new player's three masters now sit under the head.
function V.goal(kits)
	local HubMap=require(script.Parent.HubMap)
	local function place(id) local spot=HubMap.Masters[id] return spot and spot.place or "" end
	local function goal(head,items) return {head=head,items=items,sub=table.concat(items,"      ")} end
	local proctor=goal("DUELS AND THE TOURNAMENT",{"THE PROCTOR  •  "..HubMap.Proctor.place})
	if not kits then return proctor end
	if kits.state~="ready" then return goal("",{}) end
	if kits.needStarter then
		local where={}
		for _,id in Masters.Starters do table.insert(where,name(id).." • "..place(id)) end
		return goal("CHOOSE YOUR INSPIRATION",where)
	end
	local first=V.firstDuel(kits)
	if first then return goal("YOUR FIRST DUEL",{"TALK TO "..name(first).."  •  "..place(first)}) end
	for _,id in Masters.Kits do
		local m=kits.masters and kits.masters[id]
		if m and m.ready and not (kits.owned and kits.owned[id]) then
			return goal(name(id).." WANTS TO MEET YOU",{place(id)})
		end
	end
	return proctor
end

-- (DEC-038) The master's card in Konoha: what his three buttons do for this
-- player. primary / second / third = {label, send = {action, payload}} or
-- {label, tree = kit} (opens the tree), nil when absent.
function V.card(kits,id)
	local FirstMinute=require(script.Parent.FirstMinute)
	local act=V.action(kits,id)
	local who=name(id)
	local out={note=act.note,kind=act.kind}
	local rival=FirstMinute.rival(id) or "Lion"
	if act.kind=="wait" then out.primary={label="LOADING YOUR KITS…"}
	elseif act.kind=="choose" then out.primary={label="TAKE HIS KIT",send={"ChooseStarter",{player=id}}}
	elseif act.kind=="master" then out.primary={label="DUEL HIM",send={"MasterTrial",{player=act.via,master=id}}}
	elseif act.kind=="try" then out.primary={label="TRY HIS KIT",send={"Tutorial",{player=id,bot=rival}}}
	else
		if V.firstDuel(kits)==id then out.primary={label="YOUR FIRST DUEL",send={"First",{player=id}}}
		else out.primary={label="SPAR WITH "..who,send={"Start",{player=id,bot=id,level="normal"}}} end
	end
	local extra={}
	local tree=kits and kits.trees and kits.trees[id]
	if tree then table.insert(extra,{label=if (tree.free or 0)>0 then "SKILL TREE • "..tree.free else "SKILL TREE",tree=id}) end
	if act.product then table.insert(extra,{label="BUY HIS KIT",send={"BuyKit",{player=id}}}) end
	if act.kind=="choose" or act.kind=="master" then table.insert(extra,{label="TRY HIS KIT",send={"Tutorial",{player=id,bot=rival}}}) end
	if act.kind=="play" and kits and kits.owned and kits.owned[id] and kits.selected~=id then table.insert(extra,{label="MAKE IT MY KIT",send={"SelectKit",{player=id}}}) end
	out.second=extra[1];out.third=extra[2]
	return out
end

-- The result screen's line: mastery earned, a kit learned, a master waiting.
function V.result(progress,kits)
	if type(progress)~="table" then return nil end
	if progress.learned then
		return name(progress.learned).."'S KIT IS YOURS"..(if (progress.ryo or 0)>0 then string.format("  •  +%d RYŌ",progress.ryo) else "")
	end
	if not progress.gained then return nil end
	local line=string.format("+%d MASTERY  •  %s %d / %d",progress.amount or 0,name(progress.fighter),progress.mastery or 0,progress.need or Masters.Need)
	-- (13/11) the Ryō it paid (the day's first win counts double).
	if (progress.ryo or 0)>0 then line..=string.format("  •  +%d RYŌ%s",progress.ryo,if progress.firstWin then " (FIRST WIN ×2)" else "") end
	if (progress.mastery or 0)>=(progress.need or Masters.Need) then
		local leads={}
		for _,master in V.leadsTo(progress.fighter) do
			if not (kits and kits.owned and kits.owned[master]) then table.insert(leads,master) end
		end
		if #leads>0 then line..="  •  "..names(leads).." WANT TO MEET YOU" end
	end
	return line
end

return V
