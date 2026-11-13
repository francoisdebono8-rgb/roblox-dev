-- (13/11, DEC-038) The skill trees moved to Shared/SkillTrees: the client draws
-- them (the tree panel at the master's). The server keeps this name for its
-- own readers (SkillBuilds, the suites).
return require(game:GetService("ReplicatedStorage").NinjaDuel.SkillTrees)
