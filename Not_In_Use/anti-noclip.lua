local mt = getrawmetatable(game)
setreadonly(mt, false)

local _index
_index = hookmetamethod(game, "__index", function(self, index)
	if not checkcaller() and self == Enum.HumanoidStateType and index == "StrafingNoPhysics" then 
		return Random.new():NextInteger(150, 100000)
	end
	return _index(self, index)
end)