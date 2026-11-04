-- Exercise the actual ContextActionService callbacks and remote entry point.
-- No combat rules, move graphs or character parameters are mocked/replaced.
local H=require("./Harness")
local fs=require("@lune/fs")
local E=H.roblox.Enum
local V,V2=H.V,H.roblox.Vector2
local Controls=H.load("Shared/Controls")
local SRC=if fs.isDir("src") then "src" else "games/ninja-duel/src"
local function signal()
 local s={callbacks={}}
 function s:Connect(fn) table.insert(self.callbacks,fn) end
 function s:fire(...) for _,fn in self.callbacks do fn(...) end end
 return s
end
local bindings={}
local uis={WindowFocusReleased=signal(),WindowFocused=signal(),TextBoxFocused=signal(),GamepadDisconnected=signal(),LastInputTypeChanged=signal(),focused=false}
function uis:GetFocusedTextBox() return if self.focused then {} else nil end
function uis:GetLastInputType() return E.UserInputType.Keyboard end
-- Only the chakra tool reads the mouse itself (aim parity with a plain throw).
local mouseHit=V.new(0,3,-20)
local players={LocalPlayer={Character=nil,GetMouse=function() return {Hit=H.C.new(mouseHit)} end}}
local game={GetService=function(_,name)
 if name=="UserInputService" then return uis end
 if name=="Players" then return players end
 if name=="ReplicatedStorage" then return {NinjaDuel={Controls="Controls"}} end
 if name=="ContextActionService" then return {BindActionAtPriority=function(_,name,callback,_,_,...)
  bindings[name]={callback=callback,keys={...}}
 end} end
 error(name)
end}
local fn=assert(loadstring(fs.readFile(SRC.."/Client/Input.luau")))
setfenv(fn,setmetatable({game=game,require=function() return Controls end,Enum=E,Vector2=V2,Vector3=V},{__index=getfenv()}))
local Input=fn()
local state={phase="Duel",human={pursuit=0}}
local camera={CFrame=H.C.new(),look=V2.zero}
local sent={}
local input=Input.new(function(action,extra) table.insert(sent,{action=action,extra=extra}) end,
 function() return state end,function() table.insert(sent,{action="Lock"}) end,camera)
local function press(action,code,mode,position)
 local binding=assert(bindings["Ninja"..action],action.." is unbound")
 local found=false
 for _,bound in binding.keys do if bound==code then found=true end end
 assert(found,code.Name.." is not actually bound to "..action)
 local isMouse=code.EnumType==E.UserInputType
 local obj={KeyCode=if isMouse then E.KeyCode.Unknown else code,
  UserInputType=if isMouse then code elseif code.Name:match("^Button") or code.Name:match("^DPad") or code.Name:match("^Thumbstick") then E.UserInputType.Gamepad1 else E.UserInputType.Keyboard,
  Position=position or V.zero}
 return binding.callback("Ninja"..action,mode or E.UserInputState.Begin,obj)
end
local function tap(action,code,position)
 press(action,code,E.UserInputState.Begin,position);press(action,code,E.UserInputState.End,position)
end
local function last() return sent[#sent].action end
local passed=0
local function test(name,run)
 input:reset();state.phase="Duel";state.human.pursuit=0;uis.focused=false;table.clear(sent)
 local ok,err=pcall(run)
 if not ok then error("FAIL "..name..": "..tostring(err),0) end
 passed+=1;print("PASS "..name)
end
test("all declared physical bindings are reachable and unique",function()
 local owner={}
 for action,code in Controls.Gamepad do
  assert(not owner[code.Name],code.Name.." is shared by "..tostring(owner[code.Name]).." and "..action)
  owner[code.Name]=action
 end
 for _,mapping in {Controls.Keyboard,Controls.Gamepad} do
  for action,code in mapping do
   local reachable=false
   for _,binding in bindings do for _,bound in binding.keys do if bound==code then reachable=true end end end
   assert(reachable,action.." is declared but unbound")
  end
 end
end)
test("mouse heavy and light may overlap without losing either press",function()
 press("Light",Controls.Keyboard.Light);press("Heavy",Controls.Keyboard.Heavy)
 assert(#sent==2 and sent[1].action=="Attack" and sent[2].action=="Heavy")
 press("Light",Controls.Keyboard.Light,E.UserInputState.Change)
 assert(#sent==2,"a held button repeated its attack")
 press("Light",Controls.Keyboard.Light,E.UserInputState.End);press("Light",Controls.Keyboard.Light)
 assert(last()=="Attack" and #sent==3)
end)
test("PS5 modifier maps four jutsu and never modifies keyboard or mouse",function()
 press("Modifier",E.KeyCode.ButtonR1)
 for i,pair in {{"Light",E.KeyCode.ButtonX},{"Heavy",E.KeyCode.ButtonY},{"Dodge",E.KeyCode.ButtonB},{"Jump",E.KeyCode.ButtonA}} do
  -- the press is the jutsu, its release lets a held one go (audit 29/10)
  local n=#sent;tap(pair[1],pair[2]);local got={};for k=n+1,#sent do table.insert(got,sent[k].action) end;assert(sent[n+1].action=="Technique"..i and last()=="SealRelease",table.concat(got,","))
 end
 tap("Light",Controls.Keyboard.Light);assert(last()=="Attack")
 tap("Heavy",Controls.Keyboard.Heavy);assert(last()=="Heavy")
 tap("Dodge",Controls.Keyboard.Dodge);assert(last()=="Dodge")
 tap("Grab",Controls.Keyboard.Grab);assert(last()=="Grab")
end)
test("analog R2 has press/release hysteresis; R1 + R2 is the feint",function()
 for _,pair in {{"Tool",E.KeyCode.ButtonR2,"Tool"}} do
  local n=#sent
  press(pair[1],pair[2],E.UserInputState.Begin,V.new(0,0,.1));assert(#sent==n)
  press(pair[1],pair[2],E.UserInputState.Change,V.new(0,0,.7));assert(last()==pair[3] and #sent==n+1)
  for _,z in {.8,.6,.4,.52,.9} do press(pair[1],pair[2],E.UserInputState.Change,V.new(0,0,z)) end
  assert(#sent==n+1,"held trigger repeated")
  press(pair[1],pair[2],E.UserInputState.Change,V.new(0,0,.2))
  press(pair[1],pair[2],E.UserInputState.Change,V.new(0,0,.7));assert(#sent==n+2)
  press(pair[1],pair[2],E.UserInputState.End)
 end
 press("Modifier",E.KeyCode.ButtonR1)
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.Change,V.new(0,0,.7));assert(last()=="Feint","R1 + R2 is not the feint")
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.End)
 press("Modifier",E.KeyCode.ButtonR1,E.UserInputState.End)
end)
test("garde remains held across Change and releases only after both devices",function()
 press("Guard",E.KeyCode.ButtonL1);assert(last()=="Guard")
 press("Guard",E.KeyCode.ButtonL1,E.UserInputState.Change);assert(#sent==1)
 press("Guard",E.KeyCode.F);assert(#sent==1)
 press("Guard",E.KeyCode.ButtonL1,E.UserInputState.End);assert(#sent==1)
 press("Guard",E.KeyCode.F,E.UserInputState.Cancel);assert(last()=="GuardOff" and #sent==2)
end)
test("chakra button: Z + R and L2 + R2 infuse the tool; R and R2 alone stay plain",function()
 local clock,now=0,Input.now
 Input.now=function() return clock end
 local function chakra() local e=sent[#sent].extra;return type(e)=="table" and e.chakra==true end
 tap("Tool",Controls.Keyboard.Tool);assert(last()=="Tool" and sent[#sent].extra==nil,"a plain R carried chakra")
 press("ChakraKey",Controls.Keyboard.Chakra)
 tap("Tool",Controls.Keyboard.Tool);assert(last()=="Tool" and chakra(),"Z held + R was not infused")
 press("ChakraKey",Controls.Keyboard.Chakra,E.UserInputState.End)
 clock=Input.ChakraChord*.6;tap("Tool",Controls.Keyboard.Tool);assert(chakra(),"Z released just before R was lost")
 clock=1;tap("Tool",Controls.Keyboard.Tool);assert(sent[#sent].extra==nil,"a stale Z still infused")
 -- PS5 (user 29/10): R2 alone is the plain tool, L2 + R2 the chakra tool; R1 + face stays a jutsu.
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.Change,V.new(0,0,.7));assert(last()=="Tool" and sent[#sent].extra==nil,"R2 alone carried chakra")
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.End)
 press("ChakraPad",E.KeyCode.ButtonL2,E.UserInputState.Begin,V.new(0,0,.8))
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.Change,V.new(0,0,.7));assert(last()=="Tool" and chakra(),"L2 + R2 was not infused")
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.End)
 press("ChakraPad",E.KeyCode.ButtonL2,E.UserInputState.End);clock=3
 press("Modifier",E.KeyCode.ButtonR1)
 local n=#sent;tap("Light",E.KeyCode.ButtonX);assert(sent[n+1].action=="Technique1","R1 + square stopped being a jutsu")
 press("Modifier",E.KeyCode.ButtonR1,E.UserInputState.End)
 -- The keyboard modifier never turns a pad tool into a chakra tool.
 press("ChakraKey",Controls.Keyboard.Chakra)
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.Change,V.new(0,0,.7));assert(sent[#sent].extra==nil,"keyboard Z modified the pad trigger")
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.End)
 assert(Controls.Help:find("hold Z",1,true) and Controls.HelpPad:find("hold L2",1,true),"the chakra button is missing from the help")
 -- Aim parity with a plain throw: the mouse point in reach, the opponent on the pad.
 press("ChakraKey",Controls.Keyboard.Chakra,E.UserInputState.End);clock=5
 players.LocalPlayer.Character={FindFirstChild=function(_,name) return if name=="HumanoidRootPart" then {Position=V.zero} else nil end}
 press("ChakraKey",Controls.Keyboard.Chakra)
 tap("Tool",Controls.Keyboard.Tool);assert(chakra() and sent[#sent].extra.aim==mouseHit,"the chakra tool lost the mouse aim")
 mouseHit=V.new(0,3,-500)
 tap("Tool",Controls.Keyboard.Tool);assert(chakra() and sent[#sent].extra.aim==nil,"an out-of-reach aim was sent")
 press("ChakraKey",Controls.Keyboard.Chakra,E.UserInputState.End)
 state.bot={position=V.new(6,3,-12)};press("ChakraPad",E.KeyCode.ButtonL2,E.UserInputState.Begin,V.new(0,0,.8))
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.Change,V.new(0,0,.7));assert(chakra() and sent[#sent].extra.aim==state.bot.position,"the pad chakra tool did not aim at the opponent")
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.End);press("ChakraPad",E.KeyCode.ButtonL2,E.UserInputState.End)
 state.bot=nil;players.LocalPlayer.Character=nil;mouseHit=V.new(0,3,-20)
 Input.now=now
end)
test("chakra button (user 29/10): L2 or Z held infuses the press it is held with; held alone it sends nothing; L1 + square grabs",function()
 local clock,now=0,Input.now
 Input.now=function() return clock end
 local function infused(i) local e=sent[i] return e and e.extra and e.extra.chakra==true end
 table.clear(sent)
 -- pad: L2 held, then square / triangle / cross / circle
 press("ChakraPad",E.KeyCode.ButtonL2,E.UserInputState.Begin,V.new(0,0,.8))
 clock=1;input:chakraHold();input:direction(camera);assert(#sent==0,"L2 held alone sent "..tostring(sent[1] and sent[1].action))
 tap("Light",E.KeyCode.ButtonX);assert(last()=="Attack" and infused(#sent),"L2 + square is not an infused light")
 tap("Heavy",E.KeyCode.ButtonY);assert(last()=="Heavy" and infused(#sent),"L2 + triangle is not an infused heavy")
 press("ChakraPad",E.KeyCode.ButtonL2,E.UserInputState.End)
 clock=5;tap("Light",E.KeyCode.ButtonX);assert(last()=="Attack" and not infused(#sent),"a light after L2 was let go is still infused")
 -- pad: R1 + square stays a jutsu, never infused
 local n=#sent
 press("Modifier",E.KeyCode.ButtonR1);tap("Light",E.KeyCode.ButtonX);press("Modifier",E.KeyCode.ButtonR1,E.UserInputState.End)
 assert(sent[n+1].action=="Technique1" and not infused(n+1))
 -- pad: guard held + square is the grab
 press("Guard",E.KeyCode.ButtonL1);tap("Light",E.KeyCode.ButtonX);assert(last()=="Grab","L1 + square is not the grab")
 press("Guard",E.KeyCode.ButtonL1,E.UserInputState.End)
 -- keyboard: Z held + light / jump
 clock=20;press("ChakraKey",Controls.Keyboard.Chakra)
 clock=21;input:direction(camera)
 tap("Light",Controls.Keyboard.Light);assert(last()=="Attack" and infused(#sent),"Z + LMB is not an infused light")
 press("ChakraKey",Controls.Keyboard.Chakra,E.UserInputState.End)
 for _,e in sent do assert(e.action~="ChakraLoad","a hold alone still loads") end
 table.clear(sent)
 Input.now=now
end)
test("seal page (04/11): C held + 1-5 and R1 + L1 held + □ △ ○ × / D-pad ↑ send Seal1-5, one press",function()
 press("SealKey",E.KeyCode.C);assert(last()=="WallDetach","C does not reach the server (wall detach)")
 for i,code in {E.KeyCode.One,E.KeyCode.Two,E.KeyCode.Three,E.KeyCode.Four} do
  tap("Technique"..i,code);assert(sent[#sent-1].action=="Seal"..i and last()=="SealRelease","C + "..i.." sent "..tostring(sent[#sent-1].action))
 end
 tap("Technique5",E.KeyCode.Five);assert(last()=="Seal5","C + 5 sent "..last())
 press("SealKey",E.KeyCode.C,E.UserInputState.End)
 tap("Technique1",E.KeyCode.One);assert(sent[#sent-1].action=="Technique1","1 after C let go is not the quick slot")
 table.clear(sent)
 press("Modifier",E.KeyCode.ButtonR1);press("Guard",E.KeyCode.ButtonL1)
 for i,pair in {{"Light",E.KeyCode.ButtonX},{"Heavy",E.KeyCode.ButtonY},{"Dodge",E.KeyCode.ButtonB},{"Jump",E.KeyCode.ButtonA}} do
  tap(pair[1],pair[2])
  local got=false;for _,p in sent do if p.action=="Seal"..i then got=true end end
  assert(got,"R1 + L1 + "..pair[1].." did not send Seal"..i)
 end
 tap("Technique5",E.KeyCode.DPadUp);assert(last()=="Seal5","R1 + L1 + D-pad ↑ sent "..last())
 press("Guard",E.KeyCode.ButtonL1,E.UserInputState.End);press("Modifier",E.KeyCode.ButtonR1,E.UserInputState.End)
 for _,p in sent do assert(p.action~="Ultimate","a seal page that cast also fired the ultimate");assert(p.action~="Guard","the page raised the guard") end
 -- R1 + L3 is the sprint again (no weave)
 table.clear(sent);press("Modifier",E.KeyCode.ButtonR1);tap("Sprint",E.KeyCode.ButtonL3);press("Modifier",E.KeyCode.ButtonR1,E.UserInputState.End)
 for _,p in sent do assert(p.action~="Seals","R1 + L3 still opens the old weave") end
end)
test("seal page (audit 04/11): L1 then R1 opens it too; a held page let go is no ultimate; the guard comes back",function()
 local clock,now=0,Input.now
 Input.now=function() return clock end
 table.clear(sent)
 -- L1 first (the guard), then R1: the page, the guard let go, □ a seal jutsu
 press("Guard",E.KeyCode.ButtonL1);assert(last()=="Guard")
 press("Modifier",E.KeyCode.ButtonR1);assert(last()=="GuardOff","the page kept the guard up: "..last())
 tap("Light",E.KeyCode.ButtonX)
 local got=false;for _,p in sent do if p.action=="Seal1" then got=true end;assert(p.action~="Technique1" and p.action~="Grab","L1, R1, □ sent "..p.action) end
 assert(got,"L1 then R1 then □ did not send Seal1")
 -- R1 let go first, L1 still held: the guard is back, no ultimate
 press("Modifier",E.KeyCode.ButtonR1,E.UserInputState.End)
 assert(last()=="Guard","L1 still held after the page: no guard ("..last()..")")
 press("Guard",E.KeyCode.ButtonL1,E.UserInputState.End);assert(last()=="GuardOff")
 for _,p in sent do assert(p.action~="Ultimate","a page that cast fired the ultimate") end
 -- the page held to choose, then let go without a seal: no ultimate
 table.clear(sent)
 press("Modifier",E.KeyCode.ButtonR1);press("Guard",E.KeyCode.ButtonL1)
 clock+=Input.UltimateTap+.2
 press("Guard",E.KeyCode.ButtonL1,E.UserInputState.End);press("Modifier",E.KeyCode.ButtonR1,E.UserInputState.End)
 for _,p in sent do assert(p.action~="Ultimate","a held page let go burnt the ultimate") end
 -- R1 + L1 + R2 is the feint, not the feint and the ultimate
 table.clear(sent)
 press("Modifier",E.KeyCode.ButtonR1);press("Guard",E.KeyCode.ButtonL1)
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.Begin,V.new(0,0,1));press("Tool",E.KeyCode.ButtonR2,E.UserInputState.End,V.zero)
 press("Guard",E.KeyCode.ButtonL1,E.UserInputState.End);press("Modifier",E.KeyCode.ButtonR1,E.UserInputState.End)
 local feint=false
 for _,p in sent do if p.action=="Feint" then feint=true end;assert(p.action~="Ultimate","R1 + L1 + R2 also fired the ultimate") end
 assert(feint,"R1 + L1 + R2 is no feint")
 -- a tap of the chord: the ultimate
 table.clear(sent)
 press("Modifier",E.KeyCode.ButtonR1);tap("Guard",E.KeyCode.ButtonL1)
 assert(last()=="Ultimate","a tap of R1 + L1 is not the ultimate")
 press("Modifier",E.KeyCode.ButtonR1,E.UserInputState.End)
 Input.now=now
end)
test("jump release cuts a jump but never a technique or pursuit",function()
 tap("Jump",E.KeyCode.Space);assert(#sent==2 and last()=="JumpOff")
 table.clear(sent);state.human.pursuit=1
 -- (Audit 29/10) the pad's × is PadJump: the server picks chase or jump
 tap("Jump",E.KeyCode.ButtonA);assert(sent[1].action=="PadJump","× sent "..tostring(sent[1].action))
 -- (User 29/10) on a keyboard Space stays a jump inside a chase window
 table.clear(sent);tap("Jump",E.KeyCode.Space);assert(sent[1] and sent[1].action=="Jump","Space chased instead of jumping")
 state.human.pursuit=0
 table.clear(sent);state.human.pursuit=1;press("Modifier",E.KeyCode.ButtonR1)
 tap("Jump",E.KeyCode.ButtonA);assert(sent[1].action=="Technique4" and last()=="SealRelease" and #sent==2,"R1 + × sent a JumpOff")
end)
test("PS5 provides deliberate escape, feint and detach; re-engage is never a D-pad press",function()
 tap("SubstitutePad",E.KeyCode.DPadRight);assert(last()=="Substitute")
 press("Modifier",E.KeyCode.ButtonR1);tap("Guard",E.KeyCode.ButtonL1)
 -- (Stage 6) R1 + L1 is the ultimate; on a wall the server makes it the detach.
 -- (04/11) it goes on the chord's release, the chord held being the seal page.
 assert(last()=="Ultimate","R1 + L1 emitted a stray GuardOff")
 press("Modifier",E.KeyCode.ButtonR1,E.UserInputState.End)
 assert(last()=="Ultimate" and sent[#sent-1].action~="Ultimate","the ultimate went twice")
 -- CORE_COMBAT_CONVERGENCE_2 §3: no D-pad input sends the re-engage.
 for _,binding in bindings do
  for _,code in binding.keys do
   if typeof(code)=="EnumItem" and code.EnumType==E.KeyCode and code.Name:match("^DPad") then
    local n=#sent
    binding.callback("Probe",E.UserInputState.Begin,{KeyCode=code,UserInputType=E.UserInputType.Gamepad1,Position=V.zero})
    binding.callback("Probe",E.UserInputState.End,{KeyCode=code,UserInputType=E.UserInputType.Gamepad1,Position=V.zero})
    for k=n+1,#sent do assert(sent[k].action~="Pursuit",code.Name.." sends the re-engage") end
   end
  end
 end
 assert(Controls.Gamepad.Rush==nil,"the chakra dash is still declared on the D-pad")
 -- On a pad the re-engage is × inside a chase window, sprint + ○ toward outside.
 state.human.pursuit=1;local n=#sent;tap("Jump",E.KeyCode.ButtonA);assert(sent[n+1].action=="PadJump","× does not send the server's chase-or-jump")
 state.human.pursuit=0;tap("Dodge",E.KeyCode.ButtonB);assert(last()=="Dodge","○ does not send the dodge the server reads")
 assert(Controls.HelpPad:find("sprint + ○ toward: chakra dash",1,true),"the pad help does not teach the chakra dash")
 assert(Controls.Help:find("E re-engage",1,true),"the keyboard help does not teach the re-engage")
end)
test("movement intent is current at a press and survives keyboard Change",function()
 press("W",E.KeyCode.W);press("W",E.KeyCode.W,E.UserInputState.Change)
 assert(input:direction(camera).Z<-.9)
 press("W",E.KeyCode.W,E.UserInputState.End);press("S",E.KeyCode.S)
 assert(input:direction(camera).Z>.9)
 press("MoveStick",E.KeyCode.Thumbstick1,E.UserInputState.Change,V.new(1,0,0))
 assert(input:direction(camera).X>.9 and math.abs(input:direction(camera).Z)<.01,"stale keyboard mixed into pad route")
 tap("Light",Controls.Keyboard.Light)
 assert(input:direction(camera).Z>.9 and math.abs(input:direction(camera).X)<.01,"resting pad mixed into keyboard route")
 press("S",E.KeyCode.S,E.UserInputState.Cancel);assert(input:direction(camera).Magnitude==0)
end)
-- (Freeze 02/11) A connected pad whose stick rests never takes the keys away:
-- held W kept the body still once any pad event switched to "pad".
test("a resting pad never freezes the held keys",function()
 input:reset();press("W",E.KeyCode.W)
 uis.LastInputTypeChanged:fire(E.UserInputType.Gamepad1);assert(input.pad)
 assert(input:direction(camera).Z<-.9,"held W ignored once the pad took over with its stick at rest")
 press("MoveStick",E.KeyCode.Thumbstick1,E.UserInputState.Change,V.new(1,0,0))
 assert(input:direction(camera).X>.9 and math.abs(input:direction(camera).Z)<.01,"a pushed stick no longer owns the route")
 press("MoveStick",E.KeyCode.Thumbstick1,E.UserInputState.End,V.new(0,0,0))
 assert(input:direction(camera).Z<-.9,"the held key did not come back once the stick rested")
 press("W",E.KeyCode.W,E.UserInputState.End)
end)
test("text focus, window blur and disconnect clear guard, jump and stuck controls",function()
 for _,event in {uis.WindowFocusReleased,uis.TextBoxFocused,uis.GamepadDisconnected} do
  input:reset();press("W",E.KeyCode.W);press("Guard",E.KeyCode.F);press("Jump",E.KeyCode.Space)
  press("Modifier",E.KeyCode.ButtonR1);event:fire()
  assert(next(input.keys)==nil and next(input.guards)==nil and next(input.jumps)==nil and not input.modifier)
  assert(last()=="Move" and sent[#sent-1].action=="JumpOff" and sent[#sent-2].action=="GuardOff")
 end
 uis.focused=true;local n=#sent
 assert(press("Light",Controls.Keyboard.Light)==E.ContextActionResult.Pass and #sent==n)
end)
test("tutorial (audit 04/11): BACKSPACE / touchpad tap skips the step, held a second leaves; Escape stays Roblox's",function()
 local before=#sent
 assert(press("Skip",E.KeyCode.Backspace)==E.ContextActionResult.Pass and #sent==before,"the skip key acts outside the tutorial")
 assert(Controls.Keyboard.Skip~=E.KeyCode.Escape,"the skip is on Escape again (Roblox keeps it for its menu)")
 local clock,now=0,Input.now
 Input.now=function() return clock end
 state.tutorial={};tap("Skip",E.KeyCode.Backspace);assert(last()=="TutorialStep","a tap sent "..last())
 press("Skip",E.KeyCode.ButtonSelect);clock+=1.2;press("Skip",E.KeyCode.ButtonSelect,E.UserInputState.End)
 assert(last()=="TutorialSkip","a held touchpad sent "..last())
 Input.now=now
 state.tutorial=nil
end)
test("combo prompts omit routes that the current character does not have",function()
 local graphs=H.load("Shared/MoveGraphs")
 for _,id in {"Flashstep","Mirage","GentleFist","Lion"} do
  local help=Controls.comboHelp(graphs[id],true)
  -- (04/11) buttons only: no direction left in the prompt
  assert(help:find("○: around",1,true) and help:find("R2: retreat",1,true) and help:find("3 hits → △: low",1,true),help)
  assert(not help:find("toward",1,true) and not help:find("away",1,true),"a direction left in "..help)
 end
 -- (Stage 6) Gaara now has a side route (the sand glide), still no retreat.
 local sand=Controls.comboHelp(graphs.Sand,true)
 assert(sand:find("around",1,true) and not sand:find("retreat",1,true))
end)
test("PS5 prompts survive incidental mouse movement and list full jutsu chords",function()
 uis.LastInputTypeChanged:fire(E.UserInputType.Gamepad1);assert(input.pad)
 uis.LastInputTypeChanged:fire(E.UserInputType.MouseMovement);assert(input.pad)
 uis.LastInputTypeChanged:fire(E.UserInputType.Keyboard);assert(not input.pad)
 for i,chord in {"R1 + □","R1 + △","R1 + ○","R1 + ×","D-pad ↑"} do assert(Controls.TechniquePad[i]==chord) end
 for _,symbol in {"□","△","○","×","L1","R1","L2","R2"} do assert(Controls.HelpPad:find(symbol,1,true),symbol.." missing") end
end)
-- Integration: use real server validation and the unchanged character graphs.
H.workspace.GetServerTimeNow=function() return 100 end
local Matches=H.load("Server/Matches")
local AntiCheat=H.load("Server/VelmoraAntiCheat")
local function remote(c,a,b)
 local player={};local s=c.match;s.epoch=1;s.combat=c;s.human=a;s.bot=b;s.bucket={tokens=100,time=os.clock()}
 local matches=setmetatable({sessions={[player]=s}},Matches)
 local function send(action,dir)
  AntiCheat.clear(a) -- isolate direction validation from real wall-clock rate limiting
  matches:request(player,{action=action,epoch=1,direction=dir,clientTime=100})
 end
 return send,s,matches,player
end
local function confirmed(c,a,b)
 assert(c:request(a,"Attack"))
 for _=1,90 do H.step(c,.01);if a.state=="Recovery" and a.chainOpen then return end end
 error("chain did not open")
end
test("remote directional press overrides a stale Move and buffer keeps it on release",function()
 for _,id in {"Flashstep","Mirage","GentleFist","Lion"} do
  local c,a,b=H.duel(id,"Flashstep")
  confirmed(c,a,b);assert(c:request(a,"Attack"));H.step(c,.03)
  local send=remote(c,a,b)
  a.move=V.zero;send("Attack",a.root.CFrame.LookVector)
  assert(a.buffered and a.buffered.intent[1]=="forward",id..": the remote read old movement")
  a.move=V.zero
  for _=1,90 do H.step(c,.01);if a.attackName==(if id=="Lion" then "LionKick" else "Launcher") then break end end
  assert(a.attackName==(if id=="Lion" then "LionKick" else "Launcher"),id..": release lost the existing launcher route")
 end
end)
test("remote pad re-engage: sprint + dodge toward a locked opponent is the chakra dash, a walking dodge stays a dodge",function()
 for _,id in {"Flashstep","Mirage","GentleFist","Lion"} do
  for _,sprint in {true,false} do
   local c,a,b=H.duel(id,"Mirage")
   c:relocate(a,V.new(0,3,10));c:relocate(b,V.new(0,3,-10))
   a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position);a.locked=true
   local player={};local s=c.match;s.epoch=1;s.combat=c;s.human=a;s.bot=b;s.bucket={tokens=100,time=os.clock()}
   local matches=setmetatable({sessions={[player]=s}},Matches)
   AntiCheat.clear(a)
   matches:request(player,{action="Dodge",epoch=1,direction=V.new(0,0,-1),sprint=sprint,clientTime=100})
   if sprint then assert(a.state=="Rush",id..": the sprinting dodge toward did not re-engage ("..a.state..")")
   else assert(a.state=="Dodging",id..": a walking dodge became "..a.state) end
  end
 end
end)
test("remote rejects malformed intent before mutating move or executing an action",function()
 local c,a,b=H.duel("Flashstep","Mirage");local send=remote(c,a,b)
 for _,dir in {V.new(2,0,0),V.new(0,1,0),V.new(0/0,0,0),"forward"} do
  send("Attack",dir);assert(a.state=="Neutral" and a.move==V.zero and a.pending==nil)
 end
 send("Dodge",V.xAxis);assert(a.state=="Dodging" and a.dodgeDirection.X>.9,"dodge used the previous movement tick")
end)
test("B01 (audit 03/11, a French Mac): on AZERTY every text names the key printed on the keyboard",function()
 local C=H.load("Shared/Controls")
 local saved={K=table.clone(C.KeyLabel),Help=C.Help,Grammar=C.Grammar,layout=C.layout}
 -- What Roblox answers on an AZERTY Mac (measured in Studio 03/11).
 local azerty={W="Z",A="Q",Q="A",Z="W"}
 local changed=C.useLayout(function(code) return azerty[code.Name] or code.Name end)
 assert(changed,"an AZERTY layout was not noticed")
 assert(C.KeyLabel.Dodge=="A","the dodge reads "..C.KeyLabel.Dodge.." (the key labelled A is KeyCode.Q)")
 assert(C.KeyLabel.Chakra=="W" and C.KeyLabel.ChakraLoad=="W + action","the chakra key reads "..C.KeyLabel.Chakra)
 assert(string.find(C.Help,"ZQSD move",1,true) and string.find(C.Help,"A dodge",1,true),"help: "..C.Help)
 assert(C.localize("WALL SPLAT • Q ON IMPACT TO TECH")=="WALL SPLAT • A ON IMPACT TO TECH")
 assert(C.localize("Hold F")=="Hold F" and C.localize("LMB twice")=="LMB twice","words and other keys stay")
 -- (Studio 03/11) the article stays an article; the roster's string notes follow the keys too.
 assert(C.localize("RASENGAN • A CLONE FOR IT")=="RASENGAN • A CLONE FOR IT",C.localize("RASENGAN • A CLONE FOR IT"))
 assert(C.localize("SUBSTITUTION • IT WAS A CLONE!")=="SUBSTITUTION • IT WAS A CLONE!")
 local routes=H.load("Shared/Fighters").Legion.Routes
 -- (Audit 04/11) the notes name the actions, not keys (they read on the pad too).
 assert(string.find(C.localize(routes),"chakra + tool: the kunai turns into a clone",1,true),"Naruto's notes: "..C.localize(routes))
 assert(not string.find(routes,"[↑↓←→]"),"Naruto's notes still use the stick grammar: "..routes)
 -- QWERTY: nothing changes.
 C.KeyLabel=saved.K;C.Help=saved.Help;C.Grammar=saved.Grammar;C.layout=saved.layout
 assert(not C.useLayout(function(code) return code.Name end),"a QWERTY layout was rewritten")
 assert(C.KeyLabel.Dodge=="Q")
end)
test("DEC-031: free (not locked on), the body faces where the player looks; the look is validated like the stick",function()
 local c,a,b=H.duel("Lion","Mirage")
 c:relocate(a,V.new(0,3,10));c:relocate(b,V.new(0,3,-10))
 a.root.CFrame=H.C.lookAt(a.root.Position,b.root.Position)
 local player={};local s=c.match;s.epoch=1;s.combat=c;s.human=a;s.bot=b;s.bucket={tokens=100,time=os.clock()}
 local matches=setmetatable({sessions={[player]=s}},Matches)
 for _,bad in {V.new(0,1,0),V.new(3,0,0),V.new(0/0,0,0)} do
  AntiCheat.clear(a)
  matches:request(player,{action="Move",epoch=1,direction=V.zero,locked=false,look=bad})
  assert(a.look==nil,"a malformed look was kept")
 end
 AntiCheat.clear(a)
 matches:request(player,{action="Move",epoch=1,direction=V.zero,locked=false,look=V.new(1,0,0)})
 assert(a.locked==false and a.look and a.look.X>.99,"the look was not kept")
 for _=1,60 do H.step(c,.01) end
 local face=a.root.CFrame.LookVector
 assert(face.X>.9,string.format("free, the body did not turn where he looks (%.2f, %.2f)",face.X,face.Z))
 -- locked on, the opponent wins again
 AntiCheat.clear(a)
 matches:request(player,{action="Move",epoch=1,direction=V.zero,locked=true})
 for _=1,80 do H.step(c,.01) end
 face=a.root.CFrame.LookVector
 assert(face.Z<-.9,string.format("locked on, the body did not face him (%.2f, %.2f)",face.X,face.Z))
end)
test("B04 (audit 03/11, the user's own play): key 5 with four techniques does nothing quietly, no UNKNOWN ACTION on screen",function()
 for _,id in {"Flashstep","Mirage","GentleFist","Lion","Sand","Leaf","Legion","Copycat"} do
  local c,a,b=H.duel(id,"Mirage");local send=remote(c,a,b)
  a.cue="";a.cueUntil=0
  if not a.def.Techniques[5] then
   local ok,why=c:request(a,"Technique5")
   assert(ok==false and why=="Empty slot",id..": "..tostring(why))
   send("Technique5")
   assert(a.cue=="" and a.state=="Neutral",id..": the empty slot spoke ("..tostring(a.cue)..")")
  end
 end
end)
print(string.format("NinjaDuel input/PS5: %d PASS (callbacks + remote validation; hardware feel not simulated)",passed))
