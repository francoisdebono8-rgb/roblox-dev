-- Adapted from Velmora src/server/Combat/HitDetection.luau.
-- Copyright (c) 2026 Yashveer Singh, MIT.
-- Keeps the donor's short position history, interpolation, reach/cone and world LOS.
local Tune=require(game:GetService('ReplicatedStorage').NinjaDuel.VelmoraCombatConfig)
local HitDetection={}
local history={}
function HitDetection.record(root,t)
	local buf=history[root]
	if not buf then buf={};history[root]=buf end
	table.insert(buf,{t=t,pos=root.Position})
	local cutoff=t-(Tune.History+Tune.TimestampWindow)
	while #buf>2 and buf[1].t<cutoff do table.remove(buf,1) end
end
function HitDetection.positionAt(root,t)
	local buf=history[root]
	if not buf or #buf==0 then return root.Position end
	if t<=buf[1].t then return buf[1].pos end
	if t>=buf[#buf].t then return buf[#buf].pos end
	for i=1,#buf-1 do
		local a,b=buf[i],buf[i+1]
		if t>=a.t and t<=b.t then
			local span=b.t-a.t
			return a.pos:Lerp(b.pos,if span>0 then (t-a.t)/span else 0)
		end
	end
	return buf[#buf].pos
end
function HitDetection.clear(root) history[root]=nil end
function HitDetection.resolve(attackerRoot,range,arcAngle,origin,aim,t,candidates,effects)
	local look=if aim.Magnitude>.001 then aim.Unit else attackerRoot.CFrame.LookVector
	local exclude={effects,attackerRoot.Parent}
	for _,root in candidates do if root.Parent then table.insert(exclude,root.Parent) end end
	local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances=exclude;ray.IgnoreWater=true
	local best,bestPos,bestDistance=nil,nil,math.huge
	for _,root in candidates do
		if root~=attackerRoot and root.Parent then
			local pos=HitDetection.positionAt(root,t);local delta=pos-origin;local distance=delta.Magnitude
			if distance<=range and (distance<.001 or math.deg(math.acos(math.clamp(look:Dot(delta.Unit),-1,1)))<=arcAngle) and workspace:Raycast(origin,delta,ray)==nil and distance<bestDistance then
				best,bestPos,bestDistance=root,pos,distance
			end
		end
	end
	return best,bestPos
end
return HitDetection
