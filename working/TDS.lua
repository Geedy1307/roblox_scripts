local radius, spacing = 20, 2
local cubeSize, heightOffset = Vector3.new(0.25, 0.25, 0.25), -0.25

local function getNodePosition(index)
	local nodesFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Nodes")
	if not nodesFolder then
		return
	end

	local nodes = {}
	for _, node in ipairs(nodesFolder:GetChildren()) do
		if tonumber(node.Name) then
			table.insert(nodes, node)
		end
	end

	table.sort(nodes, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)

	local node = nodes[index]
	return node and (node.Position + Vector3.new(0, heightOffset, 0))
end

local function createPlacement(nodeIndex)
	getgenv().circlePosition = getNodePosition(nodeIndex)
	if not getgenv().circlePosition then
		return
	end

	local old = workspace:FindFirstChild("Placements_Container")
	if old then
		old:Destroy()
	end

	local PlacementContainer = Instance.new("Folder", workspace)
	PlacementContainer.Name = "Placements_Container"

	local cylinder = Instance.new("Part", PlacementContainer)
	cylinder.Name, cylinder.Shape = "PlacementVisualizer", Enum.PartType.Cylinder
	cylinder.Size, cylinder.Position = Vector3.new(0.1, radius * 2, radius * 2), getgenv().circlePosition
	cylinder.Anchored, cylinder.CanCollide, cylinder.Orientation = true, false, Vector3.new(0, 0, 90)
	cylinder.Transparency, cylinder.Color, cylinder.Material =
		0.75, Color3.fromRGB(255, 100, 100), Enum.Material.SmoothPlastic

	local cubeContainer = Instance.new("Folder", cylinder)
	cubeContainer.Name = "Placements"

	local function isPhysicallyTouching(pos, size, cylinder)
		local tester = Instance.new("Part")
		tester.Size, tester.Position = size, pos
		tester.Anchored, tester.CanCollide, tester.Transparency = true, true, 1
		tester.Parent = workspace

		local touching = tester:GetTouchingParts()
		tester:Destroy()

		for _, part in ipairs(touching) do
			if part ~= cylinder and not part:IsDescendantOf(workspace.Map.Assets) then
				return true
			end
		end
		return false
	end

	local cubes = {}
	for x = -radius, radius, spacing do
		for z = -radius, radius, spacing do
			local dist = (x ^ 2 + z ^ 2) ^ 0.5
			if dist <= radius then
				local pos = getgenv().circlePosition + Vector3.new(x, cubeSize.Y / 2, z)
				if not isPhysicallyTouching(pos, cubeSize, cylinder) then
					local cube = Instance.new("Part", cubeContainer)
					cube.Size, cube.Position = cubeSize, pos
					cube.Anchored, cube.CanCollide, cube.Transparency = false, false, 0.75
					cube.Color, cube.Material = Color3.new(1, 1, 1), Enum.Material.SmoothPlastic

					local weld = Instance.new("WeldConstraint", cube)
					weld.Part0, weld.Part1 = cylinder, cube

					table.insert(cubes, { cube = cube, distance = dist })
				end
			end
		end
	end

	table.sort(cubes, function(a, b)
		return a.distance < b.distance
	end)

	for i, v in ipairs(cubes) do
		v.cube.Name = "Placement_" .. i
	end
end

createPlacement(4)
