-- The tiers of a kit's tree (13/11, user: « vraiment les arbres de compétences,
-- vraiment comment ça va marcher »). A tree opens in three steps, with the
-- kit's mastery: tier I from the start (the kit object and the small edges),
-- tier II at 300 (when the next master opens: the routes, escapes and walls),
-- tier III at 800 (what builds on a big node: the signature moves). The tier
-- is each node's own (Shared/SkillTrees: Tier); without one it follows from
-- the node itself:
--   * a kit object (Item) is tier I: the first big node a player takes;
--   * a small node is tier I, or tier II when it needs another node first;
--   * a big node (Major) is tier II, or tier III when it needs another first.
-- Shared: the server refuses a node above the kit's mastery (ProfileSchema
-- learnNode), the tree panel draws the tiers (TreeView).
local T={}

T.Need={0,300,800}
T.Names={"I","II","III"}

local function needs(node)
	return (node.Requires~=nil and #node.Requires>0) or (node.RequiresAny~=nil and #node.RequiresAny>0)
end
function T.of(node)
	-- A tree's own tiers first (Shared/SkillTrees: each node's Tier).
	if node.Tier==1 or node.Tier==2 or node.Tier==3 then return node.Tier end
	if node.Item then return 1 end
	if not node.Major then return if needs(node) then 2 else 1 end
	return if needs(node) then 3 else 2
end
-- The mastery a node asks before it can be learned.
function T.need(node) return T.Need[T.of(node)] or 0 end
-- The highest tier open at this mastery.
function T.open(mastery)
	local tier=1
	for k,need in T.Need do if (mastery or 0)>=need then tier=k end end
	return tier
end

return T
