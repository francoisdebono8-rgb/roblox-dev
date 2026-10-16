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
local uis={WindowFocusReleased=signal(),TextBoxFocused=signal(),GamepadDisconnected=signal(),LastInputTypeChanged=signal(),focused=false}
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
 for i,pair in {{"Jump",E.KeyCode.ButtonA},{"Light",E.KeyCode.ButtonX},{"Heavy",E.KeyCode.ButtonY},{"Dodge",E.KeyCode.ButtonB}} do
  tap(pair[1],pair[2]);assert(last()=="Technique"..i)
 end
 tap("Light",Controls.Keyboard.Light);assert(last()=="Attack")
 tap("Heavy",Controls.Keyboard.Heavy);assert(last()=="Heavy")
 tap("Dodge",Controls.Keyboard.Dodge);assert(last()=="Dodge")
 tap("Grab",Controls.Keyboard.Grab);assert(last()=="Grab")
end)
test("analog L2/R2 have press/release hysteresis and retain their selected action",function()
 for _,pair in {{"Grab",E.KeyCode.ButtonL2,"Grab"},{"Tool",E.KeyCode.ButtonR2,"Tool"}} do
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
 press("Grab",E.KeyCode.ButtonL2,E.UserInputState.Change,V.new(0,0,.7));assert(last()=="Feint")
 press("Modifier",E.KeyCode.ButtonR1,E.UserInputState.End)
 press("Grab",E.KeyCode.ButtonL2,E.UserInputState.Change,V.new(0,0,.9));assert(last()=="Feint","modifier release changed a held trigger into grab")
end)
test("garde remains held across Change and releases only after both devices",function()
 press("Guard",E.KeyCode.ButtonL1);assert(last()=="Guard")
 press("Guard",E.KeyCode.ButtonL1,E.UserInputState.Change);assert(#sent==1)
 press("Guard",E.KeyCode.F);assert(#sent==1)
 press("Guard",E.KeyCode.ButtonL1,E.UserInputState.End);assert(#sent==1)
 press("Guard",E.KeyCode.F,E.UserInputState.Cancel);assert(last()=="GuardOff" and #sent==2)
end)
test("chakra modifier: Z + R and R1 + R2 infuse the tool; R and R2 alone stay plain",function()
 local clock,now=0,Input.now
 Input.now=function() return clock end
 local function chakra() local e=sent[#sent].extra;return type(e)=="table" and e.chakra==true end
 tap("Tool",Controls.Keyboard.Tool);assert(last()=="Tool" and sent[#sent].extra==nil,"a plain R carried chakra")
 press("ChakraKey",Controls.Keyboard.Chakra)
 tap("Tool",Controls.Keyboard.Tool);assert(last()=="Tool" and chakra(),"Z held + R was not infused")
 press("ChakraKey",Controls.Keyboard.Chakra,E.UserInputState.End)
 clock=Input.ChakraChord*.6;tap("Tool",Controls.Keyboard.Tool);assert(chakra(),"Z released just before R was lost")
 clock=1;tap("Tool",Controls.Keyboard.Tool);assert(sent[#sent].extra==nil,"a stale Z still infused")
 -- PS5: R2 alone is the plain tool, R1 + R2 the chakra tool; R1 + face stays a jutsu.
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.Change,V.new(0,0,.7));assert(last()=="Tool" and sent[#sent].extra==nil,"R2 alone carried chakra")
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.End)
 press("Modifier",E.KeyCode.ButtonR1)
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.Change,V.new(0,0,.7));assert(last()=="Tool" and chakra(),"R1 + R2 was not infused")
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.End)
 tap("Light",E.KeyCode.ButtonX);assert(last()=="Technique2","R1 + square stopped being a jutsu")
 press("Modifier",E.KeyCode.ButtonR1,E.UserInputState.End)
 -- The keyboard modifier never turns a pad tool into a chakra tool.
 press("ChakraKey",Controls.Keyboard.Chakra)
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.Change,V.new(0,0,.7));assert(sent[#sent].extra==nil,"keyboard Z modified the pad trigger")
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.End)
 assert(Controls.Help:find("Z + R",1,true) and Controls.HelpPad:find("R1 + R2",1,true),"the chakra chord is missing from the help")
 -- Aim parity with a plain throw: the mouse point in reach, the opponent on the pad.
 press("ChakraKey",Controls.Keyboard.Chakra,E.UserInputState.End);clock=5
 players.LocalPlayer.Character={FindFirstChild=function(_,name) return if name=="HumanoidRootPart" then {Position=V.zero} else nil end}
 press("ChakraKey",Controls.Keyboard.Chakra)
 tap("Tool",Controls.Keyboard.Tool);assert(chakra() and sent[#sent].extra.aim==mouseHit,"the chakra tool lost the mouse aim")
 mouseHit=V.new(0,3,-500)
 tap("Tool",Controls.Keyboard.Tool);assert(chakra() and sent[#sent].extra.aim==nil,"an out-of-reach aim was sent")
 press("ChakraKey",Controls.Keyboard.Chakra,E.UserInputState.End)
 state.bot={position=V.new(6,3,-12)};press("Modifier",E.KeyCode.ButtonR1)
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.Change,V.new(0,0,.7));assert(chakra() and sent[#sent].extra.aim==state.bot.position,"the pad chakra tool did not aim at the opponent")
 press("Tool",E.KeyCode.ButtonR2,E.UserInputState.End);press("Modifier",E.KeyCode.ButtonR1,E.UserInputState.End)
 state.bot=nil;players.LocalPlayer.Character=nil;mouseHit=V.new(0,3,-20)
 Input.now=now
end)
test("jump release cuts a jump but never a technique or pursuit",function()
 tap("Jump",E.KeyCode.Space);assert(#sent==2 and last()=="JumpOff")
 table.clear(sent);state.human.pursuit=1
 tap("Jump",E.KeyCode.ButtonA);assert(#sent==1 and last()=="Pursuit")
 table.clear(sent);press("Modifier",E.KeyCode.ButtonR1)
 tap("Jump",E.KeyCode.ButtonA);assert(#sent==1 and last()=="Technique1")
end)
test("PS5 provides deliberate escape, feint, detach and rush",function()
 tap("SubstitutePad",E.KeyCode.DPadRight);assert(last()=="Substitute")
 tap("RushPad",E.KeyCode.DPadLeft);assert(last()=="Pursuit")
 press("Modifier",E.KeyCode.ButtonR1);tap("Guard",E.KeyCode.ButtonL1)
 assert(last()=="WallDetach","detach emitted a stray GuardOff")
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
test("Escape reaches the Roblox menu outside tutorial and skips only training",function()
 local before=#sent
 assert(press("Skip",E.KeyCode.Escape)==E.ContextActionResult.Pass and #sent==before)
 state.tutorial={};tap("Skip",E.KeyCode.Escape);assert(last()=="TutorialSkip")
 state.tutorial=nil
end)
test("combo prompts omit routes that the current character does not have",function()
 local graphs=H.load("Shared/MoveGraphs")
 for _,id in {"Flashstep","Mirage","GentleFist","Lion"} do
  local help=Controls.comboHelp(graphs[id],true)
  assert(help:find("side + □",1,true) and help:find("away + R2",1,true))
 end
 local sand=Controls.comboHelp(graphs.Sand,true)
 assert(not sand:find("side",1,true) and not sand:find("retreat",1,true))
end)
test("PS5 prompts survive incidental mouse movement and list full jutsu chords",function()
 uis.LastInputTypeChanged:fire(E.UserInputType.Gamepad1);assert(input.pad)
 uis.LastInputTypeChanged:fire(E.UserInputType.MouseMovement);assert(input.pad)
 uis.LastInputTypeChanged:fire(E.UserInputType.Keyboard);assert(not input.pad)
 for i,chord in {"R1 + ×","R1 + □","R1 + △","R1 + ○","D-pad ↑"} do assert(Controls.TechniquePad[i]==chord) end
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
test("remote rejects malformed intent before mutating move or executing an action",function()
 local c,a,b=H.duel("Flashstep","Mirage");local send=remote(c,a,b)
 for _,dir in {V.new(2,0,0),V.new(0,1,0),V.new(0/0,0,0),"forward"} do
  send("Attack",dir);assert(a.state=="Neutral" and a.move==V.zero and a.pending==nil)
 end
 send("Dodge",V.xAxis);assert(a.state=="Dodging" and a.dodgeDirection.X>.9,"dodge used the previous movement tick")
end)
print(string.format("NinjaDuel input/PS5: %d PASS (callbacks + remote validation; hardware feel not simulated)",passed))
