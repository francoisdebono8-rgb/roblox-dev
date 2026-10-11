-- Studio tooling boundary. Reject arbitrary keys/types before dispatch.
local Commands={}
Commands.ops={reset=true,character=true,scenario=true,["repeat"]=true,profile=true,report=true,dummy=true,refill=true,awaken=true,ko=true}
function Commands.validate(op,arg)
 if type(op)~="string" or not Commands.ops[op] then return false end
 if arg==nil then return true,{} end
 if type(arg)~="table" then return false end
 local out={};local n=0
 for k,v in arg do
  n+=1;if n>5 then return false end
  if k=="first" or k=="second" or k=="name" then
   if type(v)~="string" or #v>32 then return false end
  elseif k=="actor" then if v~="human" and v~="bot" then return false end
  elseif k=="enabled" then if type(v)~="boolean" then return false end
  else return false end
  out[k]=v
 end
 return true,out
end
return Commands
