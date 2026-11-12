-- The lane's stadium between duels (QA test of b822ee5, 12/11: « gel à chaque
-- début de duel », about 0.9 s frozen then 1 s of stutter at BEGIN, 6 out of
-- 6). Every Matches:start rebuilt the whole Courtyard (some two thousand
-- parts and meshes, Server/World) next to the two new bodies, and every
-- client received all of it in the same frame and walked it. Now a lane keeps
-- its stadium:
--   * the first one is built ahead, while the player is on the roster, and
--     its pieces reach the world a few at a time (Stage.reveal: PER_FRAME
--     instances a server frame; the Courtyard carries Building=true until the
--     last one is in, the clients wait for it before reading the stadium);
--   * a duel's damage is undone before the next duel (Stage.remember once the
--     stadium is whole, Stage.restore at each start): a cracked wall's colour,
--     a felled trunk's size and place and the tree mesh it carries, the
--     WorldReaction attributes; anything the duel left inside the stadium
--     goes. A piece that went missing (destroyed) rebuilds the stadium.
-- Only the pieces that changed are written, so a restore sends the clients
-- what the last duel broke, nothing else.
local RunService=game:GetService("RunService")
local Stage={}
Stage.PER_FRAME=160
-- What a duel can change on a stadium piece (Server/WorldReaction: cracks,
-- breaks; nothing else in the game writes to the stadium).
Stage.PROPS={"Size","CFrame","Color","Transparency","CanCollide","Material"}
Stage.ATTRIBUTES={"WorldState","WorldIntegrity"}
local jobs=setmetatable({},{__mode="k"})

-- The whole stadium as it stands now (call it on a pristine one).
function Stage.remember(yard)
	local record={yard=yard,known={},parts={},count=0}
	for _,d in yard:GetDescendants() do
		record.known[d]=true
		record.count+=1
		if d:IsA("BasePart") then
			local values={}
			for _,key in Stage.PROPS do values[key]=(d::any)[key] end
			record.parts[d]=values
		end
	end
	return record
end

-- Back to the remembered stadium. Returns whether it is whole (false: a piece
-- is gone, rebuild it) and how many instances were written or removed.
function Stage.restore(record)
	local yard=record.yard
	if not yard or not yard.Parent then return false,0 end
	local seen,changed=0,0
	local strays={}
	for _,d in yard:GetDescendants() do
		if record.known[d] then
			seen+=1
			local values=record.parts[d]
			if values then
				local wrote=false
				for key,value in values do
					if (d::any)[key]~=value then (d::any)[key]=value;wrote=true end
				end
				for _,name in Stage.ATTRIBUTES do
					if d:GetAttribute(name)~=nil then d:SetAttribute(name,nil);wrote=true end
				end
				if wrote then changed+=1 end
			end
		else
			table.insert(strays,d)
		end
	end
	-- Not the stadium's own (a log a duel left under its trunk): out.
	for _,d in strays do
		if d.Parent then d:Destroy();changed+=1 end
	end
	return seen==record.count,changed
end

-- Puts `yard` (built outside the world) under `parent` a few pieces a frame:
-- the floor first (the clients read it), then what the fighters touch, then
-- the decor. `done(yard)` runs once the last piece is in.
function Stage.reveal(yard,parent,done)
	local decor=yard:FindFirstChild("Decor")
	local floor=yard:FindFirstChild("Training floor")
	local pending={}
	for _,child in yard:GetChildren() do
		if child~=decor and child~=floor then table.insert(pending,{child,yard}) end
	end
	if decor then
		for _,child in decor:GetChildren() do table.insert(pending,{child,decor}) end
	end
	for _,entry in pending do entry[1].Parent=nil end
	yard:SetAttribute("Building",true)
	yard.Parent=parent
	local job={pending=pending,next=1,done=done}
	jobs[yard]=job
	task.spawn(function()
		while jobs[yard]==job do
			if Stage.step(yard,Stage.PER_FRAME) then break end
			if RunService.Heartbeat and RunService.Heartbeat.Wait then RunService.Heartbeat:Wait() else task.wait() end
		end
	end)
	return job
end

-- Moves up to `budget` instances in. Returns whether the stadium is complete.
function Stage.step(yard,budget)
	local job=jobs[yard]
	if not job then return true end
	if not yard.Parent then jobs[yard]=nil;return true end
	while job.next<=#job.pending and budget>0 do
		local entry=job.pending[job.next]
		job.next+=1
		entry[1].Parent=entry[2]
		budget-=1+#entry[1]:GetDescendants()
	end
	if job.next<=#job.pending then return false end
	jobs[yard]=nil
	yard:SetAttribute("Building",nil)
	if job.done then job.done(yard) end
	return true
end

-- A duel that starts before the reveal is over gets the rest now.
function Stage.finish(yard)
	return Stage.step(yard,math.huge)
end

function Stage.building(yard)
	return jobs[yard]~=nil
end

return Stage
