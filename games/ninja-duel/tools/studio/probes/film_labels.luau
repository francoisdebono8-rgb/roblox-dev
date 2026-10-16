local film=shared.NdFilm
if not film then return "no film" end
local out={}
local last=nil
for _,f in film.frames do
 if f.label~=last then table.insert(out,string.format("%.2f %s",f.t,f.label));last=f.label end
end
return table.concat(out,"\n")
