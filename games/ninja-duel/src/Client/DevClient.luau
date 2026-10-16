-- Studio dev panel (F6) and bounded client measurements (Codex 33028b2, ported).
-- Hidden at start. While it is open the fighter's combat input is held:
-- Main.client hands Input a non-Duel state (`blocked`), so every binding
-- passes to the panel, and held keys are released as on a window blur.
-- Closed, input is exactly the game's. Main.client's existing Studio probe,
-- info and log forwarding are left alone: this module only answers the
-- profiler ("profile", "report") and the command-bar fallback ("panel").
-- Debug/QA places only (build.py DEBUG_SOURCES); Main.client requires it only
-- when the module is present.
local Dev={}
local CORE={"Flashstep","Mirage","GentleFist","Lion"}
local SCENARIOS={"neutral","launcher","air","wall","substitution","grab","whiff","projectile"}
function Dev.install(ctx)
	local rs=game:GetService("RunService");if not rs:IsStudio() then return nil end
	local RS=game:GetService("ReplicatedStorage")
	local Shared=RS:WaitForChild("NinjaDuel")
	local Metrics=require(Shared.DevMetrics)
	local Fighters=require(Shared.Fighters)
	local volumes=require(script.Parent.DevVolumes).new(ctx.player)
	local m=Metrics.new()
	local self={panelOpen=false,metrics=m,blocked={phase="DevPanel"}}
	local track={};local lastPacket=nil;local packetAt=0;local epoch=nil
	local control=nil;local busy=false;local profile=false
	local gui=Instance.new("ScreenGui");gui.Name="NinjaDuelDevPanel";gui.ResetOnSpawn=false;gui.DisplayOrder=110;gui.Enabled=false
	gui.Parent=ctx.player:WaitForChild("PlayerGui")
	-- Right edge: the F8 inspector keeps the top-left corner.
	local frame=Instance.new("Frame");frame.Size=UDim2.fromOffset(360,530);frame.Position=UDim2.new(1,-376,0,16)
	frame.BackgroundColor3=Color3.fromRGB(20,24,30);frame.BackgroundTransparency=.05;frame.Parent=gui
	local title=Instance.new("TextLabel");title.Size=UDim2.new(1,-16,0,40);title.Position=UDim2.fromOffset(8,4);title.BackgroundTransparency=1
	title.TextColor3=Color3.new(1,1,1);title.TextSize=16;title.Font=Enum.Font.GothamBold;title.Text="DEV / F6 — Studio uniquement";title.Parent=frame
	local status=title:Clone();status.Position=UDim2.fromOffset(8,478);status.Size=UDim2.new(1,-16,0,46);status.TextSize=13;status.Font=Enum.Font.Gotham
	status.TextWrapped=true;status.Text="Mesures OFF · aucun scénario actif";status.Parent=frame
	local firstButton,selectedBefore
	local function run(op,arg)
		if busy then return end
		if not control then status.Text="Outils serveur absents (place Debug/QA ?)";return end
		busy=true;status.Text=op.." …"
		task.spawn(function()
			local ok,result=pcall(function() return control:InvokeServer(op,arg or {}) end)
			if ok and type(result)=="table" and result.ok then
				status.Text=op.." : OK"
				if op=="profile" then profile=result.enabled==true end
			else status.Text=op.." : "..tostring(if ok and type(result)=="table" then result.error else result) end
			busy=false
		end)
	end
	local index=0
	local function button(text,callback)
		local b=Instance.new("TextButton");local row=math.floor(index/2);local col=index%2;index+=1
		b.Position=UDim2.fromOffset(8+col*174,48+row*32);b.Size=UDim2.fromOffset(168,28);b.BackgroundColor3=Color3.fromRGB(43,51,65)
		b.TextColor3=Color3.new(1,1,1);b.TextSize=13;b.Font=Enum.Font.Gotham;b.Text=text;b.Parent=frame;b.Activated:Connect(callback)
		firstButton=firstButton or b
	end
	-- CORE4 ids from the active data; nothing new is registered.
	for _,id in CORE do
		local def=Fighters[id]
		if def then
			button("Joueur : "..def.Name,function() run("character",{first=id}) end)
			button("Adversaire : "..def.Name,function() run("character",{second=id}) end)
		end
	end
	button("Reset immédiat",function() run("reset") end);button("Chakra / sub pleins",function() run("refill") end)
	button("Éveil joueur",function() run("awaken") end);button("KO adversaire",function() run("ko",{actor="bot"}) end)
	button("Dummy",function() run("dummy",{enabled=true}) end);button("IA",function() run("dummy",{enabled=false}) end)
	for _,name in SCENARIOS do button("Situation : "..name,function() run("scenario",{name=name}) end) end
	button("Répéter situation",function() run("repeat") end)
	button("Mesures ON / OFF",function() run("profile",{enabled=not profile}) end)
	button("Rapport → Output",function() run("report") end)
	button("Volumes ON / OFF",function()
		volumes:set(not volumes.enabled)
		status.Text=if volumes.enabled then "Volumes : racines bleues / hitboxes rouges" else "Volumes OFF"
	end)
	function self:toggle(open)
		if open==nil then open=not self.panelOpen end
		if open==self.panelOpen then return end
		self.panelOpen=open;gui.Enabled=open
		local gs=game:GetService("GuiService")
		if open then
			selectedBefore=gs.SelectedObject
			-- The same release as a window blur: no key stays held behind the panel.
			local jumping=next(ctx.input.jumps)~=nil
			ctx.input:reset();ctx.send("GuardOff");if jumping then ctx.send("JumpOff") end;ctx.send("Move",Vector3.zero)
			-- Controller navigation starts on the first button; mouse users get no highlight.
			if ctx.input.pad then gs.SelectedObject=firstButton end
		else
			gs.SelectedObject=if selectedBefore and selectedBefore.Parent then selectedBefore else nil
		end
	end
	game:GetService("UserInputService").InputBegan:Connect(function(key,processed)
		if not processed and key.KeyCode==Enum.KeyCode.F6 then self:toggle() end
	end)
	local function setProfile(enabled)
		m:stop();track={};lastPacket=nil
		if not enabled then return end
		m:start()
		for _,key in {"smoothStep","update","impacts"} do m:wrap(ctx.presentation,key,"client.presentation."..key) end
		m:wrap(ctx.camera,"update","client.camera");m:wrap(ctx.ui,"render","client.hud")
		m:wrap(ctx.presentation.fx,"update","client.fx")
	end
	rs:BindToRenderStep("NinjaDuelDevMeasure",Enum.RenderPriority.Camera.Value+2,function(dt)
		local data=ctx.state()
		volumes:update(data)
		if not m.enabled or not data or data.phase~="Duel" or dt<=0 then return end
		m:sample("client.frame.ms",dt*1000)
		if dt>.05 then m:event("frame-spike",{ms=dt*1000,state=data.human and data.human.state}) end
		if epoch~=data.epoch then track={};epoch=data.epoch;m:event("epoch",{epoch=epoch}) end
		if data~=lastPacket then
			local at=os.clock();if lastPacket then m:sample("client.snapshot.gap.ms",(at-packetAt)*1000) end
			packetAt=at;lastPacket=data
			if data.serverNow then m:sample("client.snapshot.age.ms",math.max(0,workspace:GetServerTimeNow()-data.serverNow)*1000) end
		end
		for _,key in {"human","bot"} do
			local actor=data[key];local st=ctx.presentation.smooth[key];local draw=ctx.presentation:visualRoot(key)
			if actor and st and st.replicatedCF and draw then
				-- Includes the intended ~45 ms smoothing delay of Presentation.
				m:sample("client."..key..".presentationGap.studs",(draw-st.replicatedCF.Position).Magnitude)
				local old=track[key];local delta=old and (draw-old.p).Magnitude or 0
				m:sample("client."..key..".frameTravel.studs",delta)
				if old and delta>math.max(6,dt*160) then
					m:event("visual-position-jump",{actor=key,state=actor.state,reaction=actor.reaction,attack=actor.attackName,studs=delta,warp=actor.warpSerial,previousWarp=old.warp,ms=dt*1000})
				end
				track[key]={p=draw,warp=actor.warpSerial}
			end
		end
	end)
	task.spawn(function()
		-- Both channels are created by the server's DevHooks at ReplicatedStorage root.
		control=RS:WaitForChild("NinjaDuelDevControl",15)
		if not control then status.Text="Outils serveur absents (place Debug/QA ?)" end
		local log=RS:WaitForChild("NinjaDuelDevLog",15)
		if not log then return end
		log.OnClientEvent:Connect(function(kind,value)
			if kind=="profile" then
				profile=value==true;setProfile(profile);status.Text="Mesures "..(if profile then "ON" else "OFF")
			elseif kind=="report" then
				local report=m:report();report.build=Shared.BuildFingerprint.Value;log:FireServer("report",report)
			elseif kind=="panel" then
				self:toggle()
			end
		end)
	end)
	return self
end
return Dev
