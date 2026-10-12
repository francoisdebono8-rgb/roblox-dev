-- Safe examples: every entry is disabled and uses an invalid placeholder ID.
return {
	{
		enabled = false,
		type = "DeveloperProduct",
		id = 0,
		fallbackLabel = "100 Coins",
		rewardHandler = "LeaderstatIncrement",
		params = {
			statName = "Coins",
			amount = 100,
		},
	},
	{
		enabled = false,
		type = "GamePass",
		id = 0,
		fallbackLabel = "Speed Boost",
		rewardHandler = "WalkSpeedMinimum",
		params = {
			minimum = 24,
		},
	},
}
