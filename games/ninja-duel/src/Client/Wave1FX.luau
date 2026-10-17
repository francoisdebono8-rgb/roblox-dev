-- Roster 20, batch 1 (Haku, Zabuza, Kimimaro): the batch's own drawing,
-- installed by Effects. Most of it is FamilyFX's (Shared/Looks); here only
-- what a look alone cannot say: the dome of ice mirrors standing round the
-- opponent, and the Hidden Mist thick enough to lose a body in.
local Debris=game:GetService("Debris")
local M={}
function M.install(FX,kit)
	local new,block,tween,flash,shockRing,num,TEX=kit.new,kit.block,kit.tween,kit.flash,kit.shockRing,kit.num,kit.TEX
	local ICE=Color3.fromRGB(214,240,255)
	local EDGE=Color3.fromRGB(150,206,240)
	local function mirrors(fx,position,radius,time)
		local floor=kit.floorUnder(fx,position,3,14)
		local base=if floor then floor.Position else position-Vector3.new(0,2.8,0)
		local count=10
		for i=1,count do
			local angle=i/count*math.pi*2
			local at=base+Vector3.new(math.cos(angle)*radius,3.6,math.sin(angle)*radius)
			local pane=block(fx.folder,Vector3.new(2.6,5.2,.18),CFrame.lookAt(at,Vector3.new(base.X,at.Y,base.Z)),ICE,Enum.Material.Glass)
			pane.Transparency=1;pane.Reflectance=.35
			local rim=block(pane,Vector3.new(2.8,5.4,.08),pane.CFrame*CFrame.new(0,0,.06),EDGE,Enum.Material.Neon)
			rim.Transparency=1
			tween(pane,.25,{Transparency=.35});tween(rim,.25,{Transparency=.75})
			task.delay(math.max(.3,time-.4),function()
				if pane.Parent then tween(pane,.35,{Transparency=1});tween(rim,.35,{Transparency=1}) end
			end)
			Debris:AddItem(pane,time+.2)
		end
		shockRing(fx.folder,base+Vector3.new(0,.2,0),ICE,2,radius*2,.4)
	end
	local function mist(fx,position,radius,time)
		local floor=kit.floorUnder(fx,position,3,14)
		local at=if floor then floor.Position+Vector3.new(0,1,0) else position
		local holder=kit.anchorPart(fx.folder,at)
		holder.Size=Vector3.new(radius*2,4,radius*2)
		local e=new("ParticleEmitter",{Texture=TEX.smoke,Rate=22,Lifetime=NumberRange.new(2.5,3.5),Speed=NumberRange.new(.4,1.2),SpreadAngle=Vector2.new(60,60),
			EmissionDirection=Enum.NormalId.Top,Shape=Enum.ParticleEmitterShape.Box,Color=ColorSequence.new(Color3.fromRGB(226,232,238)),LightInfluence=1,
			Size=num({{0,10},{1,18}}),Transparency=num({{0,1},{.2,.55},{.8,.6},{1,1}}),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-8,8)},holder)
		task.delay(math.max(.3,time-1),function() if e.Parent then e.Enabled=false end end)
		Debris:AddItem(holder,time+3.5)
	end
	-- Runs before FamilyFX's layer and lets it draw the zone's floor too.
	table.insert(FX.layers,1,{name="Wave1",impact=function(fx,impact,folder)
		if impact.style=="zone" and impact.kind=="mirror" then
			mirrors(fx,impact.position,math.max(3,(impact.radius or 7)-.5),impact.time or 5)
		elseif impact.style=="zone" and impact.kind=="mist" and (impact.radius or 0)>=10 then
			mist(fx,impact.position,impact.radius,impact.time or 6)
		end
		return false
	end})
end
return M
