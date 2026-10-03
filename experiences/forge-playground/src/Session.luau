local Catalog = require(game:GetService("ReplicatedStorage").ForgePlayground.Catalog)
local World = require(script.Parent.World)
local Session = {}; Session.__index = Session

-- Transport/session ownership only. Each station owns its distinct product workflow.
function Session.new(parent, slot)
	local self = setmetatable({ world = World.create(parent, slot), current = "access", stations = {}, options = {} }, Session)
	local ok, err = pcall(function()
		for _, id in ipairs(Catalog.order) do
			self.options[id] = Catalog.defaults(id)
			self.stations[id] = require(script.Parent.Stations[id]).new(self.world.stations[id])
		end
	end)
	if not ok then self.world.model:Destroy(); error(err) end
	return self
end
function Session:handle(action, id, options, index)
	if action == "visit" then
		self.stations[self.current]:leave(); self.current = id
	elseif action == "reset" then self.stations[id]:reset(); self.options[id] = Catalog.defaults(id)
	else
		assert(self.current == id, "Select this station first.")
		if action == "configure" then self.options[id] = table.clone(options) end
		self.stations[id]:handle(action, self.options[id], index)
	end
	return self:state(id)
end
function Session:state(id)
	local state = self.stations[id]:state(self.options[id])
	state.ok, state.id, state.center = true, id, self.world.stations[id].center
	state.options = table.clone(self.options[id]); state.fixture = self.world.stations[id].model
	return state
end
function Session:destroy() self.world.model:Destroy() end
return Session
