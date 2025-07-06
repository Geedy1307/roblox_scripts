local wait = task.wait
local spawn = task.spawn

while not game:IsLoaded() do wait() end

local PlaceId = game.PlaceId
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local Client = Players.LocalPlayer
local Character = Client.Character or Client.Character:WaitForChild("HumanoidRootPart")

repeat wait() until Client and Character

-- Default Settings
local Default_Settings = {
    ["Main"] = {
        ["AutoPlay"] = { 
            ["Enabled"] = false,
            ["GroundSpread"] = 10,
            ["Distance"] = 2,
            ["TransparencyEnabled"] = true,
            ["WaveRequirements"] = {
                ["Enabled"] = false,
                ["Unit1"] = 1,
                ["Unit2"] = 1,
                ["Unit3"] = 1,
                ["Unit4"] = 1,
                ["Unit5"] = 1,
                ["Unit6"] = 1
            },
            ["Upgrade"] = {
                ["Enabled"] = false,
                ["Focus_Farms"] = false,
                ["Unit1"] = 1,
                ["Unit2"] = 1,
                ["Unit3"] = 1,
                ["Unit4"] = 1,
                ["Unit5"] = 1,
                ["Unit6"] = 1
            },
            ["PlacementLimits"] = {
                ["Enabled"] = false,
                ["Unit1"] = 1,
                ["Unit2"] = 1,
                ["Unit3"] = 1,
                ["Unit4"] = 1,
                ["Unit5"] = 1,
                ["Unit6"] = 1
            }
        },
        ["AutoLeave"] = false,
        ["AutoNext"] = false,
        ["AutoRetry"] = false,
        ["PlaceAnywhere"] = false,
        ["Auto Portal"] = {
            ["SelectedPortals"] = {},
            ["Claim"] = false,
            ["SelectedChallenges"] = {},
        },
        ["Auto Rewards Screen"] = false
    }
}

local HttpS = game:GetService("HttpService")
local FileName = "Akora Hub/Games/Anime Last Stand/" .. Client.Name .. " (" .. Client.UserId .. ") Settings.Ako"

-- Function to load settings with validation
local function LoadSettings()
    writefile(FileName, HttpS:JSONEncode(Default_Settings))
    if not pcall(function() readfile(FileName) end) then
        writefile(FileName, HttpS:JSONEncode(Default_Settings))
        return Default_Settings
    end

    local success, data = pcall(function() return HttpS:JSONDecode(readfile(FileName)) end)
    if not success or type(data) ~= "table" then
        writefile(FileName, HttpS:JSONEncode(Default_Settings))
        return Default_Settings
    end

    return data
end

-- Load settings (now always valid)
local Settings = LoadSettings()

-- Function to save settings
function Save_Settings()
    writefile(FileName, HttpS:JSONEncode(Settings))
end

-- Auto-save every 1 second
spawn(function()
    while wait(1) do Save_Settings() end
end)

local function PrintKeyValue(key, value, indent, clear)
    indent = indent or 0
    local spacing = string.rep("  ", indent)

    if type(value) == "table" then
        -- Print the key and open a brace
        rconsoleprint(spacing .. tostring(key) .. " = {\n")
        -- Recursively print each sub-key and sub-value
        for subKey, subValue in pairs(value) do
            PrintKeyValue(subKey, subValue, indent + 1)
        end
        -- Close the brace for this table
        rconsoleprint(spacing .. "}\n")
    else
        -- If it's not a table, just print key = value
        rconsoleprint(spacing .. tostring(key) .. " = " .. tostring(value) .. "\n")
    end
end

--// Defined Place Locals & Functions
if PlaceId == 18583778121 or PlaceId == 12886143095 then --// In Lobby (W1,W2)
    -- Arid of AFK overhead Status
    local old_namecall
    old_namecall = hookmetamethod(game, "__namecall", function(...)
        local args = {...}
        local self = args[1]
        local method = getnamecallmethod()
        if method == "FireServer" and self == ReplicatedStorage.Remotes.AFK.ChangeState then
            return false
        end
        return old_namecall(... )
    end)

else --// In Match

    function resetAutoplayState()
        print("🔄 Resetting Autoplay State...")
        wait(0.2)


    
        print("✅ Autoplay State reset complete. Ready to restart.")
    end

    local EndDataEvent = ReplicatedStorage.Remotes.UpdateEndData
    EndDataEvent.OnClientEvent:Connect(function(...) -- This check is to register the game ending
        --resetAutoplayState() --Pretty much all that is needed currently (might change in the future)
    end)

    -- Visual Placement Settings
    local radius = 10
    local spacing = 2
    local cubeSize = Vector3.new(0.25, 0.25, 0.25)
    local nodeIndex = 1
    local heightOffset = -0.15
    local PlacementheightOffset = 0.2
    
    -- Safe Map and Waypoint handling
    local Map = workspace:FindFirstChild("Map")
    local Waypoints = {}

    if Map then
        local WaypointContainer = Map:FindFirstChild("Waypoints")
        if WaypointContainer then
            Waypoints = WaypointContainer:GetChildren()
        end
    end

    -- Global variables
    getgenv().circlePosition = nil
    local cubes = {}
    local cubeContainer -- Will be set later
    globalPlacements = {}

    function getNodePosition(index)
        local mapFolder = workspace:FindFirstChild("Map")
        if mapFolder then
            local nodesFolder = mapFolder:FindFirstChild("Waypoints")
            if nodesFolder then
                local nodes = nodesFolder:GetChildren()
                table.sort(nodes, function(a, b)
                    return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
                end)
                if index >= 1 and index <= #nodes then
                    return nodes[index].Position + Vector3.new(0, heightOffset, 0)
                else
                    warn("Invalid node index:", index)
                end
            else
                warn("Nodes folder not found!")
            end
        end
        return nil
    end

    -- local function getNodePosition(index)
    --     local mapFolder = workspace:FindFirstChild("Map")
    --     if not mapFolder then
    --         warn("Map folder not found!")
    --         return nil
    --     end
    
    --     local nodes = {}
    
    --     -- Always start with the Start block if it exists.
    --     local startBlock = mapFolder:FindFirstChild("Start")
    --     if startBlock then
    --         table.insert(nodes, startBlock)
    --     else
    --         warn("Start block not found!")
    --     end
    
    --     -- Get the Waypoints folder and sort its children.
    --     local waypointsFolder = mapFolder:FindFirstChild("Waypoints")
    --     if waypointsFolder then
    --         local wpNodes = waypointsFolder:GetChildren()
    --         table.sort(wpNodes, function(a, b)
    --             return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
    --         end)
    --         for _, node in ipairs(wpNodes) do
    --             table.insert(nodes, node)
    --         end
    --     else
    --         warn("Waypoints folder not found!")
    --     end
    
    --     -- Always add the Finish block if it exists.
    --     local finishBlock = mapFolder:FindFirstChild("Finish")
    --     if finishBlock then
    --         table.insert(nodes, finishBlock)
    --     else
    --         warn("Finish block not found!")
    --     end
    
    --     if index >= 1 and index <= #nodes then
    --         return nodes[index].Position + Vector3.new(0, heightOffset, 0)
    --     else
    --         warn("Invalid node index:", index)
    --     end
    --     return nil
    -- end
    
    getgenv().circlePosition = getNodePosition(nodeIndex)
    if not getgenv().circlePosition then return end

    if workspace:FindFirstChild("Placements_Container") then
        workspace.Placements_Container:Destroy()
    end

    local PlacementContainer = Instance.new("Folder")
    PlacementContainer.Name = "Placements_Container"
    PlacementContainer.Parent = workspace

    local cylinder = Instance.new("Part")
    cylinder.Name = "PlacementVisualizer"
    cylinder.Size = Vector3.new(0.1, radius * 2, radius * 2)
    cylinder.Position = getgenv().circlePosition
    cylinder.Transparency = 0.75
    cylinder.Color = Color3.fromRGB(255, 100, 100)
    cylinder.Material = Enum.Material.SmoothPlastic
    cylinder.Anchored = true
    cylinder.CanCollide = false
    cylinder.Shape = Enum.PartType.Cylinder
    cylinder.Orientation = Vector3.new(0, 0, 90)
    cylinder.Parent = PlacementContainer

    local cubeContainer = Instance.new("Folder")
    cubeContainer.Name = "Placements"
    cubeContainer.Parent = cylinder

    function isPhysicallyTouching(position, size)
        local testPart = Instance.new("Part")
        testPart.Size = size
        testPart.Position = position
        testPart.Anchored = true
        testPart.CanCollide = true
        testPart.Transparency = 1
        testPart.Name = "CollisionTester"
        testPart.Parent = workspace
        local touchingParts = testPart:GetTouchingParts()
        testPart:Destroy()
    
        -- Loop through the touching parts and check if they are inside the "Map" folder
        for _, part in ipairs(touchingParts) do
            -- Check if part is not inside "workspace.Map.Map" or its descendants
            local inAssetsFolder = part:IsDescendantOf(workspace.Map.Map)
            
            if part ~= cylinder and part.Parent ~= cylinder and not inAssetsFolder then
                return true
            end
        end
        return false
    end

    -- Generates cubes and parents them into cubeContainer.
    function generateCubes()
        cubes = {}  -- Reset the cubes table
        for x = -radius, radius, spacing do
            for z = -radius, radius, spacing do
                local distance = math.sqrt(x^2 + z^2)
                if distance <= radius then
                    local cubeOffset = Vector3.new(x, cubeSize.Y/2, z)
                    local cubePosition = getgenv().circlePosition + cubeOffset + Vector3.new(0, heightOffset, 0)
                    -- if not isPhysicallyTouching(cubePosition, cubeSize) then
                        local cube = Instance.new("Part")
                        cube.Size = cubeSize
                        cube.Position = cubePosition
                        cube.Anchored = false  -- Unanchored so the Weld works
                        cube.CanCollide = false
                        cube.Color = Color3.fromRGB(255, 255, 255)
                        cube.Transparency = 0.75
                        cube.Material = Enum.Material.SmoothPlastic
                        cube.Parent = cubeContainer  -- Parent into our cube container
                        table.insert(cubes, { cube = cube, distance = distance, offset = cubeOffset })
        
                        -- Weld the cube to the cylinder (PlacementVisualizer)
                        local weld = Instance.new("WeldConstraint")
                        weld.Part0 = workspace.Placements_Container:FindFirstChild("PlacementVisualizer")
                        weld.Part1 = cube
                        weld.Parent = cube
                    -- end
                end
            end
        end
    
        table.sort(cubes, function(a, b)
            return a.distance < b.distance
        end)
        for i, data in ipairs(cubes) do
            data.cube.Name = "Placement_" .. i
        end
    
        -- Update globalPlacements similar to updatePlacementVisualizer:
        globalPlacements = {}
        if cubeContainer then
            for _, part in ipairs(cubeContainer:GetChildren()) do
                local num = tonumber(part.Name:match("Placement_(%d+)"))
                if num then
                    table.insert(globalPlacements, part)
                end
            end

            -- Sort globalPlacements by the numeric part of their names ("Placement_#")
            table.sort(globalPlacements, function(a, b)
                local aNum = tonumber(a.Name:match("Placement_(%d+)")) or 0
                local bNum = tonumber(b.Name:match("Placement_(%d+)")) or 0
                return aNum < bNum
            end)
        end
    end
    -- Generate the initial set of cubes.
    generateCubes()

    -- Moves the cylinder to a new node position and regenerates cubes.
    function moveCylinderTo(newNodeIndex)
        local newPosition = getNodePosition(newNodeIndex)
        if newPosition then
            cylinder.Position = newPosition
            getgenv().circlePosition = newPosition
            
            -- Remove only cubes (named "Placement_#") from the container.
            for _, child in ipairs(PlacementContainer:GetChildren()) do
                if child.Name:match("^Placement_") then
                    child:Destroy()
                end
            end
            
            cubes = {}
            generateCubes()
        else
            warn("Node " .. newNodeIndex .. " position not found!")
        end
    end
    
    -- Helper function: Updates the placement visualizer position based on a percentage along the track.
    function updatePlacementVisualizer(percent)
        -- Retrieve and sort the nodes
        local mapFolder = workspace:FindFirstChild("Map")
        if not mapFolder then return end
        local nodesFolder = mapFolder:FindFirstChild("Waypoints")
        if not nodesFolder then return end
    
        local nodes = nodesFolder:GetChildren()
    
        -- Sort the nodes, checking if they have a '-' in the name
        table.sort(nodes, function(a, b)
            -- Split name by "-" and convert to numeric values for comparison
            local a1, a2 = a.Name:match("^(%d+)%-(%d+)$")
            local b1, b2 = b.Name:match("^(%d+)%-(%d+)$")
            
            -- Case when both have '-' in the names (x-y format)
            if a1 and b1 then
                if tonumber(a1) == tonumber(b1) then
                    -- Compare by the second part if both have the same first number
                    return (tonumber(a2) or 0) < (tonumber(b2) or 0)
                else
                    -- Otherwise, compare by the first part (x)
                    return tonumber(a1) < tonumber(b1)
                end
            else
                -- If one or both are in the single 'x' format, compare by numeric value
                return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
            end
        end)
    
        if #nodes == 0 then return end
    
        -- Build an array of node positions
        local positions = {}
        for i, node in ipairs(nodes) do
            positions[i] = node.Position
        end
    
        -- Compute total length along the track (ignoring vertical differences)
        local totalLength = 0
        for i = 2, #positions do
            totalLength = totalLength + (positions[i] - positions[i-1]).Magnitude
        end
    
        -- Determine target distance along the track
        local targetDistance = (percent / 100) * totalLength
    
        -- Find which segment the target falls into
        local cumulative = 0
        local newPos = positions[1]
        for i = 1, #positions - 1 do
            local segment = (positions[i+1] - positions[i]).Magnitude
            if cumulative + segment >= targetDistance then
                local t = (targetDistance - cumulative) / segment
                newPos = positions[i]:Lerp(positions[i+1], t)
                break
            else
                cumulative = cumulative + segment
            end
        end
    
        -- Apply the vertical offset
        newPos = newPos + Vector3.new(0, heightOffset, 0)
    
        -- Tween the cylinder's position to newPos (faster tweening)
        local cylinder = workspace.Placements_Container and workspace.Placements_Container:FindFirstChild("PlacementVisualizer")
        if cylinder then
            local TweenService = game:GetService("TweenService")
            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
            local tween = TweenService:Create(cylinder, tweenInfo, {Position = newPos})
            tween:Play()
            tween.Completed:Wait()  -- Wait until the tween completes
        end
    
        -- Update the global circlePosition variable
        getgenv().circlePosition = newPos
        --print(string.format("New circlePosition updated to: (%.2f, %.2f, %.2f)", newPos.X, newPos.Y, newPos.Z))
    
        -- Reacquire (or create) the cubeContainer from the current cylinder.
        local visualizer = workspace.Placements_Container and workspace.Placements_Container:FindFirstChild("PlacementVisualizer")
        if visualizer then
            cubeContainer = visualizer:FindFirstChild("Placements")
            if not cubeContainer then
                cubeContainer = Instance.new("Model")
                cubeContainer.Name = "Placements"
                cubeContainer.Parent = visualizer
            end
        end
    
        -- Clear existing cubes
        if cubeContainer then
            for _, cube in ipairs(cubeContainer:GetChildren()) do
                cube:Destroy()
            end
        end
        cubes = {}  -- Reset the cubes table
    
        -- Generate new cubes
        generateCubes()
    
        -- At the end of updatePlacementVisualizer(), after generating cubes:
        globalPlacements = {}
        if cubeContainer then
            for _, part in ipairs(cubeContainer:GetChildren()) do
                local num = tonumber(part.Name:match("Placement_(%d+)"))
                if num then
                    table.insert(globalPlacements, part)
                end
            end
            --print(">> globalPlacements updated with " .. tostring(#globalPlacements) .. " items.")
        end
    end

    local farmUnitNames = {
        ["Idol"] = true,
        ["Idol (Pop-Star!)"] = true,
        ["Businessman Yojin"] = true,
        ["Demon Child"] = true,
        ["Demon Child (Unleashed)"] = true,
        ["Best Waifu"] = true,
        ["Speedcart"] = true,
    }
    
    local Cash_Loc = Client.Cash
    local Player_Cash = Cash_Loc.Value
    Cash_Loc:GetPropertyChangedSignal("Value"):Connect(function()
        Player_Cash = Cash_Loc.Value
    end)

    local EquippedUnits = {}
    local PlayerSoulData = {}
    local PlayerData = game:GetService("ReplicatedStorage").Remotes.GetPlayerData:InvokeServer()
    local TowerInfo = require(game:GetService("ReplicatedStorage").Modules.TowerInfo)
    local UnitNames = require(game:GetService("ReplicatedStorage").Modules.UnitNames)
    local ShinyUnitNames = require(game:GetService("ReplicatedStorage").Modules.UnitNames.ShinyInfo)
    
    local function GetUnitName(name)
        if UnitNames[name] then
            return UnitNames[name]
        end
        for key, value in pairs(UnitNames) do
            if value == name then
                return key
            end
        end
        return nil
    end
    
    -- Store PlayerSoulData
    for index, value in PlayerData do
        if index == "SoulData" then
            for Soul, Info in value do
                warn(Soul)
                PlayerSoulData[Soul] = {
                    ["EquippedOnUnit"] = Info.EquippedUnit or "None",
                    ["Upgrade"] = Info.Upgrades or 0, -- Default upgrade to 0 if missing
                }
            end
        end
    end 
    
    for index, value in PlayerData.Slots do
        if value.UnitID ~= '' then
            local newIndex = tonumber(string.sub(index, #index))
    
            -- Retrieve enchant & soul value safely
            local enchantValue = PlayerData.UnitData[value.UnitID].Enchant or "None"
            local soulValue = PlayerData.UnitData[value.UnitID].EquippedSoul or "None"
    
            -- Get soul upgrade level from PlayerSoulData
            local soulUpgradeLevel = 0
            if PlayerSoulData[soulValue] then
                soulUpgradeLevel = PlayerSoulData[soulValue].Upgrade or 0
            end

            -- Max Place check
            local MaxPlace = ReplicatedStorage.Units[value.Value].PlacementLimit.Value or 1
            local UnitQuirk = value.Quirk or "None"
            if UnitQuirk == "Overlord" or UnitQuirk == "Avatar" or UnitQuirk == "Glitched" then
                MaxPlace = 1
            end
    
            -- Create table for this unit
            EquippedUnits[newIndex] = {
                ["UnitID"] = value.UnitID or "None",
                ["UnitName"] = value.Value or "None",
                ["Enchant"] = enchantValue,
                ["Trait"] = value.Quirk or "None",
                ["Soul"] = soulValue,
                ["SoulUpgradeLevel"] = soulUpgradeLevel,
                ["UpgradeCosts"] = {},
                ["InitCost"] = 0,
                ["Abilities"] = {},
                ["MaxPlacement"] = MaxPlace,
            }
    
            -- Check if unit has TowerInfo
            if TowerInfo[value.Value] ~= nil then
                for a, b in next, TowerInfo[value.Value] do
                    if type(b) == "table" and b.Cost then
                        local cost = b.Cost
                        -- Base cost before any discount
                        local baseCost = cost
    
                        -- Calculate total discount percentage
                        local totalDiscount = 0 -- Start with no discount
    
                        if enchantValue == "Efficiency" then
                            totalDiscount = totalDiscount + 0.20 -- 20% reduction
                        end
    
                        if soulValue == "BenevolentSoul" and soulUpgradeLevel >= 10 then
                            totalDiscount = totalDiscount + 0.04 -- 4% reduction
                        elseif soulValue == "IdolSoul" then
                            local idolSoulDiscount = 0.99 - (soulUpgradeLevel * 0.003) -- Dynamic reduction based on upgrade level
                            idolSoulDiscount = math.max(0.96, idolSoulDiscount) -- Ensure it doesn't go below 0.96
                            totalDiscount = totalDiscount + (1 - idolSoulDiscount) 
                        end
    
                        -- Apply the **total** discount all at once, and round **only once**
                        cost = math.round(baseCost * (1 - totalDiscount))
    
                        EquippedUnits[newIndex]["UpgradeCosts"][a] = cost
    
                        -- Look for ability info in this upgrade.
                        -- It can be stored as a singular "Ability" or a table "Abilities".
                        local abilityContainer = nil
                        if b.Ability then
                            abilityContainer = { [1] = b.Ability }
                        elseif b.Abilities then
                            abilityContainer = b.Abilities
                        end
    
                        if abilityContainer then
                            for abilityNumber, abilityInfo in pairs(abilityContainer) do
                                -- Check if this ability (by Name and AbilityNumber) is already registered.
                                local alreadyRegistered = false
                                for _, existing in ipairs(EquippedUnits[newIndex]["Abilities"]) do
                                    if existing.AbilityNumber == abilityNumber and existing.AbilityData.Name == abilityInfo.Name then
                                        alreadyRegistered = true
                                        -- Keep the one with the lowest UpgradeRequired.
                                        if a < existing.UpgradeRequired then
                                            existing.UpgradeRequired = a
                                        end
                                        break
                                    end
                                end
                                if not alreadyRegistered then
                                    table.insert(EquippedUnits[newIndex]["Abilities"], {
                                        UpgradeRequired = a,
                                        AbilityNumber = abilityNumber,
                                        AbilityData = abilityInfo
                                    })
                                end
                            end
                        end
                    end
                end
    
                -- Sort upgrade costs in ascending order
                table.sort(EquippedUnits[newIndex]["UpgradeCosts"], function(a, b)
                    return a < b
                end)
    
                -- Grab index 0 in UpgradeCosts which is InitCost and separate it to InitCost
                EquippedUnits[newIndex]["InitCost"] = EquippedUnits[newIndex]["UpgradeCosts"][0]
                EquippedUnits[newIndex]["UpgradeCosts"][0] = nil
            end
        end
    end

    function CountUnit(unitName)
        local count = 0

        for i,v in next, workspace.Towers:GetChildren() do
            if v.Name == unitName and v:FindFirstChild('Owner') and v.Owner.Value == Client then
                count += 1
            end
        end

        return count
    end

    function WorkspaceUnit(unitID)
        local unit = nil
        for i,v in next, workspace.Towers:GetChildren() do
            if v:FindFirstChild('UnitID') and v:FindFirstChild('Owner') and v.UnitID.Value == unitID and v.Owner.Value == Client then
                unit = v
                break
            end
        end

        return unit
    end

    function PlaceUnits()
        local unitList = {}
        --[[ Make sure list of units isn't empty *]]
        if #unitList <= 0 then
            -- Build a list of units from EquippedUnits with their UnitName, TrueName, cost, and whether they're a farm unit (based on TrueName).
            for _, unit in pairs(EquippedUnits) do
                if unit.UnitName and unit.InitCost then
                    local trueName = GetUnitName(unit.UnitName) or unit.UnitName
                    local isFarm = farmUnitNames[trueName] or false
                    table.insert(unitList, {
                        UnitID = unit.UnitID,
                        UnitName = unit.UnitName,   -- Name used to place the unit.
                        TrueName = trueName,          -- The alternate name (from GetUnitName).
                        Cost = unit.InitCost,
                        Farm = isFarm,
                        MaxPlacement = unit.MaxPlacement,
                        UpgradeCosts = unit.UpgradeCosts,
                    })
                end
            end

            -- Sort the unit list:
            -- Farm units (determined by TrueName) come first; within each group, sort by cost ascending.
            table.sort(unitList, function(a, b)
                if a.Farm and not b.Farm then
                    return true
                elseif not a.Farm and b.Farm then
                    return false
                else
                    return a.Cost < b.Cost
                end
            end)
        end

        local NextPlaceIndex = 1
        --[[ Create a check for the game gayass remote's response before moving to next placement *]]
        -- ReplicatedStorage.Remotes.PlaceTower.OnClientEvent:connect(function(...)
        --     --[[ Don't care to check anything because the remote is client-sided called *]]
        --     NextPlaceIndex = NextPlaceIndex + 1
        --     print('Remote fired, increase by 1: ' .. NextPlaceIndex)
        -- end)

        -- Place one unit per entry in the sorted unit list using the sorted cube positions.
        for i, entry in ipairs(unitList) do
            if not Settings.Main.AutoPlay.Enabled then break end

            repeat wait()
                if not Settings.Main.AutoPlay.Enabled then break end

                local cube = globalPlacements[NextPlaceIndex]
                if cube then
                    -- Wait until the player's cash is enough to cover the unit's cost.
                    if Player_Cash >= entry.Cost then
                        --[[ childadded check because remote check is gay after a few spawn *]]
                        local TickPlace
                        local PlacementSuccess = false

                        TickPlace = workspace.Towers.ChildAdded:connect(function(unit)
                            local owner = unit:WaitForChild('Owner')
                            if owner.Value == Client then
                                PlacementSuccess = true
                                TickPlace:disconnect()
                            end
                        end)

                        -- Add PlacementheightOffset to the cube's CFrame so the unit is placed slightly higher.
                        local placeCFrame = cube.CFrame + Vector3.new(0, PlacementheightOffset, 0)
                        ReplicatedStorage.Remotes.PlaceTower:FireServer(entry.UnitName, placeCFrame)
                        print("Attemp place unit: " .. entry.UnitName .. " (TrueName: " .. entry.TrueName .. ") at cube " .. cube.Name)

                        local startTime = tick()
                        repeat wait(0.1) until tick() - startTime > 1

                        if PlacementSuccess then
                            NextPlaceIndex = NextPlaceIndex + 1
                            print('Remote fired, increase by 1: ' .. NextPlaceIndex)
                        end
                    end
                else
                    print("No placement cube available for unit: " .. entry.UnitName)
                end
            until CountUnit(entry.UnitName) >= entry.MaxPlacement
        end

        --[[ Finish placing and move to upgrade ]]
        -- for i, entry in ipairs(unitList) do
        --     local unit = WorkspaceUnit(entry.UnitID)
        --     if unit and entry.UpgradeCosts then
        --         for _,upprice in next, entry.UpgradeCosts do
        --             repeat wait() until Player_Cash >= upprice
        --             ReplicatedStorage.Remotes.Upgrade:InvokeServer(unit)
        --         end
        --     end
        -- end
    end
end

local Useful = {
    ["Remotes"] = ReplicatedStorage.Remotes:GetChildren(),
    ["Modules"] = ReplicatedStorage.Modules:GetChildren()
}

-- Load MacLib
local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

local Window = MacLib:Window({
    Title = "Akora Hub",
    Subtitle = "Anime Last Stand",
    Size = UDim2.fromOffset(868, 650),
    DragStyle = 2, -- Full UI Dragging for Mobile
    DisabledWindowControls = {},
    ShowUserInfo = true,
    Keybind = Enum.KeyCode.RightControl,
    AcrylicBlur = true,
})

-- Tab and Sections
local Tab_Groups = {
    Main_Group = Window:TabGroup(),
    Shop_Group = Window:TabGroup(),
    Setting_Groups = Window:TabGroup()
}

local Tabs = {
    Main = Tab_Groups.Main_Group:Tab({ Name = "Main", Image = "rbxassetid://10723407389" }),
    --Priority = Tab_Groups.Main_Group:Tab({ Name = "Autofarm Priority", Image = "rbxassetid://10709752906" }),
    Macro = Tab_Groups.Main_Group:Tab({ Name = "Macro", Image = "rbxassetid://10734943448" }),
    --CardPicker = Tab_Groups.Main_Group:Tab({ Name = "Card Picker", Image = "rbxassetid://10723396225" }),
    AutoPlay = Tab_Groups.Main_Group:Tab({ Name = "Auto Play", Image = "rbxassetid://10734966248" }),
    Ability = Tab_Groups.Main_Group:Tab({ Name = "Ability", Image = "rbxassetid://10747830374" }),
    --Shop = Tab_Groups.Shop_Group:Tab({ Name = "Shop", Image = "rbxassetid://10734952273" }),
    Webhook = Tab_Groups.Setting_Groups:Tab({ Name = "Webhook", Image = "rbxassetid://10747366266" }),
    Settings = Tab_Groups.Setting_Groups:Tab({ Name = "Settings", Image = "rbxassetid://10734950309" })
}

local Sections = {
    AutoFunctionsSection = Tabs.Main:Section({ Side = "Right" }),
    PortalSection = Tabs.Main:Section({Side = "Right"}),
    
    -- Auto Play
    AutoPlaySection = Tabs.AutoPlay:Section({ Side = "Left" }),
    WaveRequirementSection = Tabs.AutoPlay:Section({ Side = "Right" }),
    UpgradeUnitSection = Tabs.AutoPlay:Section({ Side = "Left" }),
    PlacementLimitSection = Tabs.AutoPlay:Section({ Side = "Right" }),
}

Sections.AutoFunctionsSection:Header({ Name = "Match Functions" })

-- Add toggles to Main tab
local AutoLeaveToggle = Sections.AutoFunctionsSection:Toggle({
    Name = "Auto Leave",
    Default = Settings.Main.AutoLeave,
    Callback = function(value)
        Settings.Main.AutoLeave = value
    end
}, "AutoLeaveToggle")

local AutoNextToggle = Sections.AutoFunctionsSection:Toggle({
    Name = "Auto Next",
    Default = Settings.Main.AutoNext,
    Callback = function(value)
        Settings.Main.AutoNext = value
    end
}, "AutoNextToggle")

local AutoRetryToggle = Sections.AutoFunctionsSection:Toggle({
    Name = "Auto Retry",
    Default = Settings.Main.AutoRetry,
    Callback = function(value)
        Settings.Main.AutoRetry = value
    end
}, "AutoRetryToggle")

local AutoMatchRewardsToggle = Sections.AutoFunctionsSection:Toggle({
    Name = "Auto Match Rewards (Match)",
    Default = Settings.Main["Auto Rewards Screen"],
    Callback = function(value)
        Settings.Main["Auto Rewards Screen"] = value
    end
}, "AutoMatchRewardsToggle")

local PlaceAnywhereToggle = Sections.AutoFunctionsSection:Toggle({
    Name = "Place Anywhere",
    Default = Settings.Main.PlaceAnywhere,
    Callback = function(value)
        Settings.Main.PlaceAnywhere = value
    end
}, "PlaceAnywhereToggle")



Sections.AutoPlaySection:Header({ Name = "Auto Play+" })

-- Store UI elements in local variables
local AutoPlaceToggle = Sections.AutoPlaySection:Toggle({
    Name = "Enable Auto Play",
    Default = Settings.Main.AutoPlay.Enabled,
    Callback = function(value)
        Settings.Main.AutoPlay.Enabled = value

        if Settings.Main.AutoPlay.Enabled then
            PlaceUnits()
        end
    end
}, "AutoPlayToggle")

local GroundSpreadSlider = Sections.AutoPlaySection:Slider({
    Name = "Ground Spread",
    Default = Settings.Main.AutoPlay.GroundSpread,
    Minimum = 1,
    Maximum = 100,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(value)
        Settings.Main.AutoPlay.GroundSpread = value
    end
}, "GroundSpreadSlider")

local DistanceSlider = Sections.AutoPlaySection:Slider({
    Name = "Distance",
    Default = Settings.Main.AutoPlay.Distance,
    Minimum = 1,
    Maximum = 100,
    DisplayMethod = "Percent",
    Precision = 0,
    Callback = function(value)
        Settings.Main.AutoPlay.Distance = value

        updatePlacementVisualizer(value)
    end
}, "DistanceSlider")

local DistanceSubLabel = Sections.AutoPlaySection:SubLabel({
    Text = "This setting will smoothly move the placement from start to finish along the given map's track."
})

local Transparency_Toggle = Sections.AutoPlaySection:Toggle({
    Name = "View Placements (Debug)",
    Default =  Settings.Main.AutoPlay.TransparencyEnabled or false,
    Callback = function(bool)
        Settings.Main.AutoPlay.TransparencyEnabled = bool
        
        --pcall(function()
            local placementContainer = workspace:FindFirstChild("Placements_Container")
            if not placementContainer then return end
            
            local cylinder = placementContainer:FindFirstChild("PlacementVisualizer")
            if not cylinder then return end
            
            if bool then
                cylinder.Transparency = 0.75
            else
                cylinder.Transparency = 1
            end
            
            local cubeContainer = cylinder:FindFirstChild("Placements")
            if cubeContainer then
                for _, cube in ipairs(cubeContainer:GetChildren()) do
                    if cube:IsA("Part") then
                        if bool then
                            cube.Transparency = 0.75
                        else
                            cube.Transparency = 1
                        end
                    end
                end
            end
        --end)
    end,
}, "Cylinder_Transparency_Flag")


Sections.WaveRequirementSection:Header({ Name = "Wave Requirement (Placing)" })
local WaveReqToggle = Sections.WaveRequirementSection:Toggle({
    Name = "Enable Wave Requirements",
    Default = Settings.Main.AutoPlay.WaveRequirements.Enabled,
    Callback = function(value)
        Settings.Main.AutoPlay.WaveRequirements.Enabled = value
    end
}, "WaveRequirementToggle")

Sections.UpgradeUnitSection:Header({ Name = "Auto Upgrade" })
local UpgradeLimitToggle = Sections.UpgradeUnitSection:Toggle({
    Name = "Enable Auto Upgrade",
    Default = Settings.Main.AutoPlay.Upgrade.Enabled,
    Callback = function(value)
        Settings.Main.AutoPlay.Upgrade.Enabled = value
    end
}, "UpgradeToggle")

local PrioritizeFarm_Toggle = Sections.UpgradeUnitSection:Toggle({
    Name = "Prioritize Farms",
    Default = Settings.Main.AutoPlay.Upgrade["Focus_Farms"],
    Callback = function(bool)
        Settings.Main.AutoPlay.Upgrade["Focus_Farms"] = bool
        SaveS()
        
    end,
}, "Prioritize_Farms_Flag")

Sections.PlacementLimitSection:Header({ Name = "Placement Limit" })
local PlacementLimitToggle = Sections.PlacementLimitSection:Toggle({
    Name = "Enable Placement Limits",
    Default = Settings.Main.AutoPlay.PlacementLimits.Enabled,
    Callback = function(value)
        Settings.Main.AutoPlay.PlacementLimits.Enabled = value
    end
}, "PlacementLimitToggle")

-- Local tables for sliders
local WaveRequirementSliders = {}
local UpgradeUnitSliders = {}
local PlacementLimitSliders = {}

for i = 1, 6 do
    WaveRequirementSliders[i] = Sections.WaveRequirementSection:Slider({
        Name = "Unit " .. i .. "",
        Default = Settings.Main.AutoPlay.WaveRequirements["Unit" .. i],
        Minimum = 1,
        Maximum = 50,
        DisplayMethod = "Value",
        Precision = 0,
        Callback = function(value)
            Settings.Main.AutoPlay.WaveRequirements["Unit" .. i] = value
        end
    }, "WaveReqUnit" .. i)

    UpgradeUnitSliders[i] = Sections.UpgradeUnitSection:Slider({
        Name = "Unit " .. i .. "",
        Default = Settings.Main.AutoPlay.Upgrade["Unit" .. i],
        Minimum = 1,
        Maximum = 15,
        DisplayMethod = "Value",
        Precision = 0,
        Callback = function(value)
            Settings.Main.AutoPlay.Upgrade["Unit" .. i] = value
        end
    }, "UpgradeUnit" .. i)

    PlacementLimitSliders[i] = Sections.PlacementLimitSection:Slider({
        Name = "Unit " .. i .. "",
        Default = Settings.Main.AutoPlay.PlacementLimits["Unit" .. i],
        Minimum = 1,
        Maximum = 8,
        DisplayMethod = "Value",
        Precision = 0,
        Callback = function(value)
            Settings.Main.AutoPlay.PlacementLimits["Unit" .. i] = value
        end
    }, "PlacementLimitUnit" .. i)
end


-------------------------------------------------------
-- Placement and Upgrade Loop
-------------------------------------------------------

spawn(function()

end)

-------------------------------------------------------
-- End of Placement and Upgrade Loop
-------------------------------------------------------

-------------------------------------------------------
-- Auto Portal Claim
-------------------------------------------------------

Sections.PortalSection:Header({ Name = "Portal Auto Claim" })

-- Define challenge options and their ratings
local challengeOptions = {"Barebones", "Tower Limit", "Flight", "No Hit", "Speedy", "High Cost", "Short Range", "Immunity"}
local challengeRatings = {
    ["Barebones"] = 3,
    ["Tower Limit"] = 8,
    ["Flight"] = 7.5,
    ["No Hit"] = 8,
    ["Speedy"] = 5,
    ["High Cost"] = 1,
    ["Short Range"] = 3,
    ["Immunity"] = 3
}

-- Create a multi-select dropdown for Challenges.
-- (Assuming MacLib's Dropdown supports a 'Multi' flag for multi-select.)
local ChallengesDropdown = Sections.PortalSection:Dropdown({
    Name = "Select Challenges",
    Options = challengeOptions,
    Multi = true,
    Default = Settings["Main"]["Auto Portal"]["SelectedChallenges"],
    Callback = function(selected)
        Settings["Main"]["Auto Portal"]["SelectedChallenges"] = selected
        print("Selected challenges updated:")
        for i, v in next, Settings["Main"]["Auto Portal"]["SelectedChallenges"] do
            print(v)
        end
    end,
})

-- Create a toggle for enabling/disabling Auto Claim Portal function.
local autoClaimEnabled = false
local AutoClaimToggle = Sections.PortalSection:Toggle({
    Name = "Auto Claim Portal",
    Default = Settings["Main"]["Auto Portal"]["Claim"],
    Callback = function(value)
        Settings["Main"]["Auto Portal"]["Claim"] = value
        print("Auto Claim Portal set to", value)
    end,
}, "AutoClaimToggle")

local sortedSelectedChallenges = {}
for _, ch in ipairs(Settings["Main"]["Auto Portal"]["SelectedChallenges"]) do
    table.insert(sortedSelectedChallenges, ch)
end

table.sort(sortedSelectedChallenges, function(a, b)
    local ra = challengeRatings[a] or 0
    local rb = challengeRatings[b] or 0
    if ra == rb then
        if a == "No Hit" and b == "Tower Limit" then
            return true
        elseif a == "Tower Limit" and b == "No Hit" then
            return false
        else
            return a < b
        end
    else
        return ra > rb
    end
end)

if PlaceId ~= 18583778121 or PlaceId ~= 12886143095 then
    if game:GetService("ReplicatedStorage").Remotes:FindFirstChild("PortalSelection") then
        game:GetService("ReplicatedStorage").Remotes.PortalSelection.OnClientEvent:Connect(function(...)
            local args = {...}
            local portals = args[1]  -- Remote returns a table of portal entries in its original order.
            if type(portals) == "table" then
                for i, portal in ipairs(portals) do
                    local data = portal.PortalData
                    if data then
                        local map = data.Map or "Unknown"
                        local challenge = data.Challenges or "Unknown"
                        local tier = data.Tier or "Unknown"
                        local portalName = portal.PortalName or "Unknown"
                        print("Portal received - Map:", map, "Challenge:", challenge, "Tier:", tier, "PortalName:", portalName)
                    end
                end
            end

            -- If auto claim is enabled, select the best portal based on our sorted selected challenges.
            if autoClaimEnabled and type(portals) == "table" then
                local bestPortal = nil
                local bestPriority = nil
                -- Only consider the first 3 portals (keep their order unchanged).
                for i = 1, math.min(3, #portals) do
                    local portal = portals[i]
                    local challengeName = portal.PortalData and portal.PortalData.Challenges
                    print(challengeName)
                    if challengeName then
                        for j, selCh in ipairs(sortedSelectedChallenges) do
                            if challengeName == selCh then
                                if not bestPriority or j < bestPriority then
                                    bestPortal = portal
                                    bestPriority = j
                                end
                                break
                            end
                        end
                    end
                end

                if bestPortal then
                    game:GetService("ReplicatedStorage").Remotes.PortalSelection:FireServer(bestPortal)
                    print("Auto claimed portal for challenge:", bestPortal.PortalData.Challenges)
                else
                    warn(bestPortal)
                    print("No matching portals found for selected challenges.")
                end
            end
        end)
    end
end

-------------------------------------------------------
-- End of Auto Portal Claim
-------------------------------------------------------

-------------------------------------------------------
-- Place Anywhere
-------------------------------------------------------
local placeFunc

while wait(1) do
    for i,v in next, getgc() do
        if typeof(v) == "function" and debug.info(v, "n") == "Place" then
            placeFunc = v
            break
        end
    end

    if placeFunc then
    	break
    end
end

if placeFunc then
    spawn(function()
        while wait() do
            if Settings.Main.PlaceAnywhere or Settings.Main.AutoPlay.Enabled then 
                debug.setupvalue(placeFunc, 2, true)
            end
        end
    end)
end
-------------------------------------------------------
-- End of Place Anywhere
-------------------------------------------------------

-------------------------------------------------------
-- Auto Next / Retry / Leave Integration
-------------------------------------------------------

local function ActivatePromptButton(uiElement, buttonIndex)
    buttonIndex = buttonIndex or 1
    if uiElement:IsA("TextButton") then
        uiElement.Selectable = true
        GuiService.SelectedObject = uiElement
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        print("Simulated Enter key press for TextButton:", uiElement.Name)
        return
    end

    local textButtons = {}
    for _, child in ipairs(uiElement:GetChildren()) do
        if child:IsA("TextButton") then
            table.insert(textButtons, child)
        end
    end
    if #textButtons >= buttonIndex then
        local selectedButton = textButtons[buttonIndex]
        selectedButton.Selectable = true
        GuiService.SelectedObject = selectedButton
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        --print("Simulated Enter key press for TextButton:", selectedButton.Name)
    else
        warn("No TextButton found at index " .. buttonIndex .. " in the given directory!")
    end
end

local function MonitorEndGame()
    local PlayerGui = Client:WaitForChild("PlayerGui")
    
    PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "Prompt" then
            --print("Detected Prompt GUI. Activating its TextButton via simulated key press...")
            task.spawn(function()
                while child and child:IsDescendantOf(PlayerGui) do
                    -- The desired button is at Prompt.TextButton.TextButton
                    local container = child:FindFirstChild("TextButton")
                    if container then
                        local targetButton = container:FindFirstChild("TextButton")
                        if targetButton and targetButton:IsA("TextButton") then
                            if Settings.Main["Auto Rewards Screen"] then
                                ActivatePromptButton(targetButton)
                            end
                        else
                            --warn("Prompt.TextButton.TextButton not found!")
                        end
                    else
                        --warn("Prompt.TextButton container not found!")
                    end 
                    task.wait(0.1)
                end
                GuiService.SelectedObject = nil
            end)
        elseif child.Name == "EndGameUI" then
            --print("Detected EndGameUI. Activating its designated TextButton via simulated key press...")
            -- Wait until the Prompt UI is gone
            repeat task.wait() until not PlayerGui:FindFirstChild("Prompt")
            task.spawn(function()
                local Buttons = child.BG and child.BG:FindFirstChild("Buttons")
                if Buttons then
                    local autoRetry = Settings.Main.AutoRetry
                    local autoNext = Settings.Main.AutoNext
                    local autoLeave = Settings.Main.AutoLeave
                    
                    if autoRetry and Buttons:FindFirstChild("Retry") then
                        ActivatePromptButton(Buttons.Retry)
                    elseif autoNext and Buttons:FindFirstChild("Next") then
                        ActivatePromptButton(Buttons.Next)
                    elseif autoLeave and Buttons:FindFirstChild("Leave") then
                        ActivatePromptButton(Buttons.Leave)
                    else
                        --warn("No valid EndGameUI button found based on auto flags!")
                    end
                else
                    --warn("EndGameUI BG.Buttons not found!")
                end
                task.wait(0.1)
                GuiService.SelectedObject = nil
            end)
        end
    end)
    
    PlayerGui.ChildRemoved:Connect(function(child)

    end)
end

MonitorEndGame()

-------------------------------------------------------
-- End of Auto Next / Retry / Leave Integration
-------------------------------------------------------

-- Load Auto Config
MacLib:SetFolder("Akora Hub")
Tabs.Main:Select()
MacLib:LoadAutoLoadConfig()
