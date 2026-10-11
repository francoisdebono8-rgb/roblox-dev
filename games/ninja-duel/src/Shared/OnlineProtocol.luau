-- Optional future 1v1 boundary. NOT imported by either active bootstrap.
local P={Enabled=false,Version=1,SnapshotHz=12,QueueLimit=32}
P.actions={Move=true,Attack=true,Heavy=true,Jump=true,Dash=true,Guard=true,GuardOff=true,Substitute=true,Grab=true,Tool=true,Pursuit=true,Dodge=true,JumpOff=true,Feint=true,Awaken=true,WallDetach=true}
for i=1,5 do P.actions["Technique"..i]=true end
return table.freeze(P)
