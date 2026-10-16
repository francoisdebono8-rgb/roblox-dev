-- Serializable vector math: simulation/reporting has no Roblox instance dependency.
local V={}
function V.valid(v) return type(v)=="table" and type(v.x)=="number" and type(v.y)=="number" and type(v.z)=="number" and v.x==v.x and v.y==v.y and v.z==v.z and math.max(math.abs(v.x),math.abs(v.y),math.abs(v.z))<=100000 end
function V.new(x,y,z) return {x=x or 0,y=y or 0,z=z or 0} end
function V.add(a,b) return V.new(a.x+b.x,a.y+b.y,a.z+b.z) end
function V.sub(a,b) return V.new(a.x-b.x,a.y-b.y,a.z-b.z) end
function V.mul(a,n) return V.new(a.x*n,a.y*n,a.z*n) end
function V.dot(a,b) return a.x*b.x+a.y*b.y+a.z*b.z end
function V.length(a) return math.sqrt(V.dot(a,a)) end
function V.unit(a) local length=V.length(a);assert(length>1e-8,"Zero direction");return V.mul(a,1/length) end
function V.reflect(a,n) n=V.unit(n);return V.sub(a,V.mul(n,2*V.dot(a,n))) end
-- Swept relative spheres catch fast projectiles that cross between ticks.
function V.sweep(a,da,b,db,radius)
 local p=V.sub(a,b);local d=V.sub(da,db);local c=V.dot(p,p)-radius*radius
 if c<=0 then return 0 end
 local aa=V.dot(d,d);if aa<1e-10 then return nil end
 local bb=2*V.dot(p,d);local disc=bb*bb-4*aa*c;if disc<0 then return nil end
 local t=(-bb-math.sqrt(disc))/(2*aa);return if t>=0 and t<=1 then t else nil
end
return V
