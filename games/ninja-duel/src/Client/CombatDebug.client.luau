-- Optional debug-build display, outbound server data only; no combat input.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players=game:GetService("Players")
local remote=game:GetService("ReplicatedStorage"):WaitForChild("NinjaDuelCombatDebug",10)
if not remote then return end
local gui=Instance.new("ScreenGui");gui.Name="NinjaDuelCombatInspector";gui.ResetOnSpawn=false;gui.DisplayOrder=100
local panel=Instance.new("TextLabel");panel.Size=UDim2.fromOffset(590,340);panel.Position=UDim2.fromOffset(12,12)
panel.BackgroundColor3=Color3.fromRGB(18,20,28);panel.BackgroundTransparency=.15;panel.TextColor3=Color3.fromRGB(220,237,245)
panel.Font=Enum.Font.Code;panel.TextSize=13;panel.TextXAlignment=Enum.TextXAlignment.Left;panel.TextYAlignment=Enum.TextYAlignment.Top
panel.Text="Ninja Duel debug — waiting for a duel (F8: hide/show)";panel.Parent=gui;gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
 if not processed and input.KeyCode==Enum.KeyCode.F8 then gui.Enabled=not gui.Enabled end
end)
remote.OnClientEvent:Connect(function(data)
 local lines={"NINJA DUEL — READ-ONLY DEBUG  /  F8 hide/show",string.format("%s  t=%.2f  projectiles=%d hazards=%d",data.phase,data.now,data.projectileCount,data.hazardCount)}
 for _,a in data.actors do
  local tools={};for _,p in a.projectiles do table.insert(tools,p.kind.."#"..p.id) end
  table.insert(lines,string.format("\n%s [%s]  HP %.0f  chakra %.0f",a.name,a.fighterId,a.health,a.chakra))
  table.insert(lines,string.format("%s / %s  move=%s variant=%s",a.state,a.reaction,a.move,a.attackVariant))
  table.insert(lines,string.format("phase=%s %.3fs  combo=%d hits=%d chain=%s",a.phase,a.phaseRemaining,a.combo,a.comboHits,tostring(a.chainOpen)))
  table.insert(lines,string.format("%s / %s  lock=%s target=%s",a.terrain,a.movement,tostring(a.locked),a.target))
  table.insert(lines,string.format("guard=%s stam=%.0f parryCD=%.2f dodge=%.2f counter=%.2f",tostring(a.guard),a.stamina,a.parryCooldown,a.dodge,a.counter))
  table.insert(lines,string.format("grab=%s bound=%s throw=%s tools=%s",a.grabbedBy,tostring(a.bound),a.throw and a.throw.kind or "none",table.concat(tools,",")))
  table.insert(lines,string.format("clashes=%d riposte=%.2f awaken=%.2f",a.clashes,a.riposte,a.awakening))
 end
 panel.Text=table.concat(lines,"\n")
end)
