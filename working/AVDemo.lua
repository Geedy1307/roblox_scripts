local wait = task.wait
local spawn = task.spawn

while not game:isLoaded() do wait() end
getgenv().AkoraHub_DebugRewrite_Settings = false

----------------------------
--==  UTILITIES  ==--
----------------------------
local Workspace = game.Workspace
local Players = game:GetService("Players")
local Client = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualInputManager = game:GetService("VirtualInputManager")

repeat
    task.wait(0.1)
until not Client.PlayerGui:FindFirstChild("LoadingScreen") and not Client.PlayerGui:FindFirstChild("LobbyLoadingScreen")

local mouse = Client:GetMouse()
while not mouse do
    task.wait(0.1)
    mouse = Client:GetMouse()
end
local screenCenter = Vector2.new(mouse.ViewSizeX / 2, mouse.ViewSizeY / 2)

function removeSpaces(str)
    return str:gsub("%s+", "")
end

function printTable(tbl, indent)
    indent = indent or ""
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            print(indent .. tostring(key) .. ": (table)")
            printTable(value, indent .. "  ")
        else
            print(indent .. tostring(key) .. ": " .. tostring(value))
        end
    end
end

----------------------------
--==  SETTINGS & REFERENCES  ==--
----------------------------

-- Determine the correct Units GUI based on PlaceId.
local UnitsGui
if game.PlaceId == 16277809958 and game.PlaceId ~= 16146832113 then 
    UnitsGui = Client.PlayerGui.Hotbar.Main.Units
elseif game.PlaceId == 16146832113 and game.PlaceId ~= 16277809958 then 
    UnitsGui = Client.PlayerGui.HUD.Main.Units
end

local unitInfo = {}  -- Table storing per-unit data.

-- Global event placeholders.
local yenEvent, EndScreenEvent, GameEvent, InterfaceEvent, SkipWaveEvent
local matchEnded = false
local autoplayRunning = false
local FirstRun = true
local autoplayToken = nil

-- Global state to track progress
local autoplayState = {
    phase = "placing",  -- Can be "placing" or "upgrading"
    nextPlacementIndex = 1,
    unitOrder = {},
}
globalPlacements = {}
local placedUnits = {}
local autoplayEnableCount = 0
local updatedModels = {}
local foundCount = 0


-- Wave values.
local currentWave = 1
local maxWave = 0
local CurrentYen = 0

-- Visual Placement Settings
local radius = 10
local spacing = 1.9
local cubeSize = Vector3.new(0.25, 0.25, 0.25)
local nodeIndex = 2
local heightOffset = -0.25
local clearance = 0.2
getgenv().circlePosition = nil

local UnitFolder = ReplicatedStorage.Modules.Data.Entities.UnitsData
local EntityIDHandler = require(ReplicatedStorage.Modules.Data.Entities.EntityIDHandler)
local NonEvoUnits = UnitFolder.Default
local unitNames = {}
local AllUnitsInfo = {}
for _, descendant in ipairs(NonEvoUnits:GetDescendants()) do
    if descendant:IsA("ModuleScript") then
        table.insert(unitNames, descendant.Name)
    end
end
table.sort(unitNames)

for _, descendant in ipairs(UnitFolder:GetDescendants()) do
    if descendant:IsA("ModuleScript") then
        local success, unitData = pcall(require, descendant)
        if success and unitData then
            table.insert(AllUnitsInfo, {
                Name = unitData.Name,
                Upgrades = unitData.Upgrades
            })
        else
            warn("Failed to require module: " .. descendant.Name)
        end
    end
end

table.sort(AllUnitsInfo, function(a, b)
    return a.Name < b.Name
end)

settingsName = "Akora Hub/Games/Anime Vanguards/" .. "" .. Client.Name .. " (" .. game.Players.LocalPlayer.UserId .. ") Settings.Ako"
DefaultSettings = { 
    ["AutoPlay"] = {
        ["Enabled"] = false,
        ["Upgrade"] = {
            ["Enabled"] = false,
            ["Focus_Farms"] = false,
            ["Upgrade_On_Wave"] = {
                ["Enabled"] = false,
                ["Unit_1"] = 1,
                ["Unit_2"] = 1,
                ["Unit_3"] = 1,
                ["Unit_4"] = 1,
                ["Unit_5"] = 1,
                ["Unit_6"] = 1,
            },
        },
        ["Placement"] = {
            ["Enabled"] = false,
            ["PlacementSize"] = 15,
            ["Distance"] = 50,
            ["Spread"] = 0,
            ["Place_On_Wave"] = {
                ["Enabled"] = false,
                ["Unit_1"] = 1,
                ["Unit_2"] = 1,
                ["Unit_3"] = 1,
                ["Unit_4"] = 1,
                ["Unit_5"] = 1,
                ["Unit_6"] = 1,
            },
            ["Max_Placements"] = {
                ["Unit_1"] = 1,
                ["Unit_2"] = 1,
                ["Unit_3"] = 1,
                ["Unit_4"] = 1,
                ["Unit_5"] = 1,
                ["Unit_6"] = 1,
            }
        },
        ["TransparencyEnabled"] = false,
    },
    ["Auto"] = {
        ["Join"] = {
            ["Diff"] = {"Normal", "Nightmare"},
            ["Modes"] = {
                ["Story"] = {
                    ["Maps"] = {"Planet Namak", "Sand Village", "Double Dungeon", "Shibuya Station", "Underground Church", "Spirit Society"},
                    ["Acts"] = {"Sandbox", "Act 1", "Act 2", "Act 3", "Act 4", "Act 5", "Act 6"},
                },
                ["Infinite"] = {
                    ["Maps"] = {"Planet Namak", "Sand Village", "Double Dungeon", "Shibuya Station", "Underground Church", "Spirit Society"},
                    ["Acts"] = {},
                },
                ["Paragon"] = {
                    ["Maps"] = {"Planet Namak", "Sand Village", "Double Dungeon", "Shibuya Station", "Underground Church", "Spirit Society"},
                    ["Acts"] = {},
                },
                ["Legend"] = {
                    ["Maps"] = {"Sand Village", "Double Dungeon", "Shibuya Aftermath", "Golden Castle", "Kuinshi Palace"},
                    ["Acts"] = {"Act 1", "Act 2", "Act 3"},
                },
                ["Raid"] = { 
                    ["Maps"] = {"Spider Forest", "Tracks at the Edge of the World"},
                    ["Acts"] = {
                        ["Spider Forest"] = {"Act 1", "Act 2", "Act 3", "Act 4"},
                        ["Tracks at the Edge of the World"] = {"Act 1", "Act 2", "Act 3", "Act 4", "Act 5"},
                    },
                },
                ["BossRush"] = { 
                    ["Maps"] = {"A"},
                    ["Acts"] = {},
                },
                ["Challenge"] = { 
                    ["Maps"] = {"Daily", "Half Hourly"},
                    ["Acts"] = {},
                },
            },
        },
        ["StartMap"] = {
            ["Mode_Select"] = "Story",
            ["Map_Select"] = "Planet Namak",
            ["Act_Select"] = "Act 1",
            ["Difficulty_Select"] = "Normal",
            ["FriendsOnly"] = false,
            ["WaitForFriends"] = false,
            ["WaitForFriends_Seconds"] = 15,
            ["WalkToJoin"] = false,
            ["AutoJoinMap"] = false,
        },
        ["Start"] = {
            ["Enabled"] = false,
            ["Delay"] = 2,
        },
        ["Next"] = false,
        ["Replay"] = false,
        ["Leave"] = false,
        ["Skip_Wave"] = false,
        ["Next_Portal"] = false,
    },
    ["Shop"] = {
        ["Summon"] = {
            ["SummonMode"] = 0,
            ["SelectedBanner"] = 0,
            ["TargetUnit"] = 0,
            ["Summon_Until_Unit"] = false,
            ["Gem_Amount"] = 1000,
            ["Buy10_Mode"] = false,
            ["Specific_Summon_Mode"] = false,
            ["Specific_Summon_Amount"] = 9,
            ["Enable_Summons"] = false,
        },
        ["Gold"] = {
            ["ItemsAvailable"] = {},
            ["SelectedItems"] = {},
            ["BuyAmount"] = 1
        },
    },    
    ["Settings"] = {
        ["Collect"] = {
            ["Collections"] = false,
            ["Daily"] = false,
            ["EnemyIndex"] = false,
            ["Quests"] = false,
            ["Battlepass"] = false,
        },
    },
}

getgenv().Settings = nil

local hasfilefunctions = isfolder and makefolder and writefile and readfile
if hasfilefunctions then
    if not isfolder("Akora Hub//Games//Anime Vanguards") then 
        makefolder("Akora Hub//Games//Anime Vanguards")
    end

    if getgenv().AkoraHub_DebugRewrite_Settings or not pcall(function() readfile(settingsName) end) then writefile(settingsName, game:service'HttpService':JSONEncode(DefaultSettings)) end
end

getgenv().Settings = game:service'HttpService':JSONDecode(readfile(settingsName))

function SaveS()
    writefile(settingsName,game:service'HttpService':JSONEncode(getgenv().Settings))
end

----------------------------
--==  GAME EVENTS & UPDATE FUNCTIONS  ==--
----------------------------

if game.PlaceId == 16277809958 and game.PlaceId ~= 16146832113 then
    -- Cache events.
    yenEvent = ReplicatedStorage.Networking.ClientListeners.YenEvent
    EndScreenEvent = ReplicatedStorage.Networking.EndScreen.ShowEndScreenEvent
    GameEvent = ReplicatedStorage.Networking.GameEvent
    InterfaceEvent = ReplicatedStorage.Networking.InterfaceEvent
    SkipWaveEvent = ReplicatedStorage.Networking.SkipWaveEvent
    UnitEvent = ReplicatedStorage.Networking.UnitEvent

    -- Update wave information.
    local wavesLabel = Client.PlayerGui.HUD.Map.WavesAmount
    local function updateWaves()
        local text = wavesLabel.Text
        local waveValues = {}
        for fontContent in text:gmatch("<font.->(.-)</font>") do
            local number = fontContent:match("%d+")
            if number then
                table.insert(waveValues, number)
            end
        end
        currentWave = tonumber(waveValues[1]) or 0
        maxWave = tonumber(waveValues[2]) or 0
        print("Current Wave:", currentWave, "Max Wave:", maxWave)
    end
    wavesLabel:GetPropertyChangedSignal("Text"):Connect(updateWaves)

    yenEvent.OnClientEvent:Connect(function(amount)
        CurrentYen = amount
    end)

    function resetAutoplayState()
        print("🔄 Resetting Autoplay State...")
        task.wait(0.2)
    
        -- Reset unit placement tracking for each unit in unitInfo
        updatedModels = {}
        foundCount = 0
    
        -- Reset each unit's placed count to 0
        for i, info in ipairs(unitInfo) do
            if info then
                info.Placed = 0
            end
        end
    
        -- Clear placed unit records and reset autoplay state
        placedUnits = {}  -- Clear placed unit records
        autoplayState = {
            phase = "placing",  -- Reset the phase to 'placing'
            nextPlacementIndex = 1,  -- Start from the first placement index
            unitOrder = {}  -- Clear the unit order
        }
    
        -- Clear saved upgrade tracking states
        getgenv().SavedUpgradeTracking = nil
        getgenv().SavedTotalUpgrades = nil
        getgenv().SavedAutoPlayState = nil  -- Clear the saved state to prevent continued progress
        
        -- Reset match state
        matchEnded = false  -- Reset the match ended flag
        autoplayToken = nil  -- Clear the current autoplay token
    
        print("✅ Autoplay State reset complete. Ready to restart.")
    end
    
    
    --[[
    UnitEvent.OnClientEvent:Connect(function(...)
        task.wait(1)

    end)
    --]]
    
    GameEvent.OnClientEvent:Connect(function(...)
        task.wait(1)
        local args = { ... }
        if args[1] == "MatchEnded" then
            print("⏹️ Match End detected. Stopping all autoplay operations...")
            matchEnded = true
            autoplayRunning = false
            --resetAutoplayState()
            for i = 1, 12 do
                task.wait(0.4)
                VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, false, game, 0)
            end
        elseif args[1] == "MatchStarted" then
            if FirstRun == false then
                print("🚀 Match Started detected. Launching Autoplay Process...")
                matchEnded = true
                autoplayRunning = false
                resetAutoplayState()
                matchEnded = false
                currentWave = 1
                if not autoplayRunning then
                    if getgenv().Settings["AutoPlay"]["Enabled"] then
                        --trigger_Autoplay()
                        trigger_AutoPlayAndUpgrade()
                    end
                end
            else
                FirstRun = false
            end
        elseif args[1] == "GameRestarted" then
            print("⏹️ Game Restart detected. Stopping all autoplay operations...")
            matchEnded = true
            autoplayRunning = false
            currentWave = 1
            --resetAutoplayState()
            if getgenv().Settings["Auto"]["Start"]["Enabled"] then
                task.wait(getgenv().Settings["Auto"]["Start"]["Delay"])
                ReplicatedStorage.Networking.SkipWaveEvent:FireServer("Skip")
            end
        end
    end)   
    
    EndScreenEvent.OnClientEvent:Connect(function(...)
        print("End Screen Shown")
        task.wait(7)
        if getgenv().Settings["Auto"]["Replay"] then
            ReplicatedStorage.Networking.EndScreen.VoteEvent:FireServer("Retry")
        elseif getgenv().Settings["Auto"]["Next"] then
            ReplicatedStorage.Networking.EndScreen.VoteEvent:FireServer("Next")
        elseif getgenv().Settings["Auto"]["Leave"] then
            ReplicatedStorage.Networking.EndScreen.VoteEvent:FireServer("Leave")
        elseif getgenv().Settings["Auto"]["Leave_Challenge"] then
            ReplicatedStorage.Networking.EndScreen.VoteEvent:FireServer("Leave")
        end
    end)

    InterfaceEvent.OnClientEvent:Connect(function(...)
        task.wait(1)
    end)

    SkipWaveEvent.OnClientEvent:Connect(function(...)
        local args = { ... }
        if args[1] == "Show" then
            if getgenv().Settings["Auto"]["Skip_Wave"] then
                task.wait(0.3)
                ReplicatedStorage.Networking.SkipWaveEvent:FireServer("Skip")
            end
        end
    end)

    local function getNodePosition(index)
        local mapFolder = Workspace:FindFirstChild("Map")
        if mapFolder then
            local nodesFolder = mapFolder:FindFirstChild("Nodes")
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

    getgenv().circlePosition = getNodePosition(nodeIndex)
    if not getgenv().circlePosition then return end

    if Workspace:FindFirstChild("Placements_Container") then
        Workspace.Placements_Container:Destroy()
    end

    local PlacementContainer = Instance.new("Folder")
    PlacementContainer.Name = "Placements_Container"
    PlacementContainer.Parent = Workspace

    local cylinder = Instance.new("Part")
    cylinder.Name = "PlacementVisualizer"
    cylinder.Size = Vector3.new(0.1, radius * 2, radius * 2)
    cylinder.Position = circlePosition

    if getgenv().Settings["AutoPlay"]["TransparencyEnabled"] then 
        cylinder.Transparency = 0.75
    else
        cylinder.Transparency = 1
    end
    cylinder.Color = Color3.fromRGB(255, 100, 100)
    cylinder.Material = Enum.Material.SmoothPlastic
    cylinder.Anchored = true
    cylinder.CanCollide = false
    cylinder.Shape = Enum.PartType.Cylinder
    cylinder.Orientation = Vector3.new(0, 0, 90)
    cylinder.Parent = PlacementContainer

    --local cubeContainer = Instance.new("Folder")
    --cubeContainer.Name = "Placements"
    --cubeContainer.Parent = cylinder

    local cubes = {}
    function isPhysicallyTouching(position, size)
        local testPart = Instance.new("Part")
        testPart.Size = size
        testPart.Position = position
        testPart.Anchored = true
        testPart.CanCollide = true
        testPart.Transparency = 1
        testPart.Name = "CollisionTester"
        testPart.Parent = Workspace
        local touchingParts = testPart:GetTouchingParts()
        testPart:Destroy()
    
        -- Loop through the touching parts and check if they are inside the "Assets" folder
        for _, part in ipairs(touchingParts) do
            -- Check if part is not inside "workspace.Map.Assets" or its descendants
            local inAssetsFolder = part:IsDescendantOf(workspace.Map.Assets)
            
            if part ~= cylinder and part.Parent ~= cylinder and not inAssetsFolder then
                return true
            end
        end
        return false
    end
    
    function generateCubes()
        cubes = {}  -- Reset the cubes table
        --print(">> Generating cubes at circlePosition:", getgenv().circlePosition)
        for x = -radius, radius, spacing do
            for z = -radius, radius, spacing do
                local distance = math.sqrt(x^2 + z^2)
                if distance <= radius then
                    local cubeOffset = Vector3.new(x, cubeSize.Y / 2, z)
                    -- Use the updated global circlePosition:
                    local cubePosition = getgenv().circlePosition + cubeOffset
                    if not isPhysicallyTouching(cubePosition, cubeSize) then
                        local cube = Instance.new("Part")
                        cube.Size = cubeSize
                        cube.Position = cubePosition
                        cube.Anchored = false  -- unanchored so the Weld works
                        cube.CanCollide = false
                        cube.Color = Color3.fromRGB(255, 255, 255)
                        if getgenv().Settings["AutoPlay"]["TransparencyEnabled"] then 
                            cube.Transparency = 0.75
                        else
                            cube.Transparency = 1
                        end
                        cube.Material = Enum.Material.SmoothPlastic
                        cube.Parent = cubeContainer
                        table.insert(cubes, { cube = cube, distance = distance, offset = cubeOffset })
                        
                        -- Weld the cube to the cylinder so it moves with it.
                        local weld = Instance.new("WeldConstraint")
                        weld.Part0 = Workspace.Placements_Container.PlacementVisualizer
                        weld.Part1 = cube
                        weld.Parent = cube
                        
                        --print(string.format("Cube generated at: (%.2f, %.2f, %.2f)", cubePosition.X, cubePosition.Y, cubePosition.Z))
                    else
                        --print("Cube at offset", cubeOffset, "skipped because of collision.")
                    end
                end
            end
        end
        table.sort(cubes, function(a, b)
            return a.distance < b.distance
        end)
        for i, data in ipairs(cubes) do
            data.cube.Name = "Placement_" .. i
        end
        --print(">> Total cubes generated: " .. #cubes)
    end

    function moveCylinderTo(newNodeIndex)
        local newPosition = getNodePosition(newNodeIndex)
        if newPosition then
            cylinder.Position = newPosition
            circlePosition = newPosition
            for _, cube in ipairs(cubeContainer:GetChildren()) do
                cube:Destroy()
            end
            cubes = {}
            generateCubes()
        else
            warn("Node " .. newNodeIndex .. " position not found!")
        end
    end

    generateCubes()
end

----------------------------
--==  UI LIBRARY SETUP  ==--
----------------------------
local Library = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()
local Window = Library:Window({
    Title = "AV Demo",
    Subtitle = "Version: 1.0.0",
    Size = UDim2.fromOffset(868, 650),
    DragStyle = 2,
    DisabledWindowControls = {},
    ShowUserInfo = false,
    Keybind = Enum.KeyCode.RightControl,
    AcrylicBlur = true,
})
Window:SetUserInfoState(false)

local globalSettings = {
    UIBlurToggle = Window:GlobalSetting({
        Name = "UI Blur",
        Default = Window:GetAcrylicBlurState(),
        Callback = function(bool)
            Window:SetAcrylicBlurState(bool)
            Window:Notify({ Title = Window.Settings.Title, Description = (bool and "Enabled" or "Disabled") .. " UI Blur", Lifetime = 5 })
        end,
    }),
    NotificationToggler = Window:GlobalSetting({
        Name = "Notifications",
        Default = Window:GetNotificationsState(),
        Callback = function(bool)
            Window:SetNotificationsState(bool)
            Window:Notify({ Title = Window.Settings.Title, Description = (bool and "Enabled" or "Disabled") .. " Notifications", Lifetime = 5 })
        end,
    }),
    ShowUserInfo = Window:GlobalSetting({
        Name = "Show User Info",
        Default = false,
        Callback = function(bool)
            Window:SetUserInfoState(false)
            Window:Notify({ Title = Window.Settings.Title, Description = (bool and "Showing" or "Redacted") .. " User Info", Lifetime = 5 })
        end,
    }),
    Rejoin_Place = Window:GlobalSetting({
        Name = "Rejoin Lobby",
        Default = false,
        Callback = function(bool)
            if bool then
                TeleportService:Teleport(16146832113)
            end
        end,
    }),
}

local Tab_Groups = {
    Main_Group = Window:TabGroup(),
    Shop_Group = Window:TabGroup(),
    Setting_Groups = Window:TabGroup()
}

local Tabs = {
    Main = Tab_Groups.Main_Group:Tab({ Name = "Main", Image = "rbxassetid://10723407389" }),
    Priority = Tab_Groups.Main_Group:Tab({ Name = "Autofarm Priority", Image = "rbxassetid://10709752906" }),
    Macro = Tab_Groups.Main_Group:Tab({ Name = "Macro", Image = "rbxassetid://10734943448" }),
    CardPicker = Tab_Groups.Main_Group:Tab({ Name = "Card Picker", Image = "rbxassetid://10723396225" }),
    AutoPlay = Tab_Groups.Main_Group:Tab({ Name = "Auto Play", Image = "rbxassetid://10734966248" }),
    Ability = Tab_Groups.Main_Group:Tab({ Name = "Ability", Image = "rbxassetid://10747830374" }),
    Shop = Tab_Groups.Shop_Group:Tab({ Name = "Shop", Image = "rbxassetid://10734952273" }),
    Webhook = Tab_Groups.Setting_Groups:Tab({ Name = "Webhook", Image = "rbxassetid://10747366266" }),
    Settings = Tab_Groups.Setting_Groups:Tab({ Name = "Settings", Image = "rbxassetid://10734950309" })
}

----------------------------
--==  MAIN UI SECTIONS  ==--
----------------------------
local Sections = {
    AutoJoin = Tabs.Main:Section({ Side = "Left" }),
    AutoStart = Tabs.Main:Section({ Side = "Left" }),
    AutoOptions = Tabs.Main:Section({ Side = "Right" }),
    TPLobby = Tabs.Main:Section({ Side = "Right" }),
}
local Map_Select, Act_Select

-- Helper functions to update the dropdown options dynamically
local function updateMapOptions(mode)
    -- Clear current map options and insert new ones based on selected mode
    Map_Select:ClearOptions()
    Map_Select:InsertOptions(getgenv().Settings["Auto"]["Join"]["Modes"][mode]["Maps"])
end

-- Helper functions to update Act options
local function updateActOptions(mode, map)
    -- If the mode is "Raid", handle the format differently
    if mode == "Raid" then
        Act_Select:ClearOptions()
        -- Nested Acts for Raid, using the map key
        if getgenv().Settings["Auto"]["Join"]["Modes"]["Raid"]["Acts"][map] then
            Act_Select:InsertOptions(getgenv().Settings["Auto"]["Join"]["Modes"]["Raid"]["Acts"][map])
        end
    else
        -- For other modes, standard Acts handling
        Act_Select:ClearOptions()
        Act_Select:InsertOptions(getgenv().Settings["Auto"]["Join"]["Modes"][mode]["Acts"])
    end
end

-- AutoJoin Section
Sections.AutoJoin:Header({ Name = "Auto Join" })

-- Mode Select Dropdown
Mode_Select = Sections.AutoJoin:Dropdown({
    Name = "Mode Select",
    Multi = false,
    Required = true,
    Options = {"Story", "Infinite", "Paragon", "Legend", "Raid", "BossRush"},
    Default = getgenv().Settings["Auto"]["StartMap"]["Mode_Select"],
    Callback = function(Value)
        -- Update Mode Select
        getgenv().Settings["Auto"]["StartMap"]["Mode_Select"] = Value
        SaveS()

        -- If the mode is Raid, handle the format differently
        if Value == "Raid" then
            -- For Raids, the maps have a nested "Acts" structure
            Map_Select:ClearOptions()
            Map_Select:InsertOptions(getgenv().Settings["Auto"]["Join"]["Modes"]["Raid"]["Maps"])
        else
            -- For other modes, use the regular Maps and Acts structure
            Map_Select:ClearOptions()
            Map_Select:InsertOptions(getgenv().Settings["Auto"]["Join"]["Modes"][Value]["Maps"])
        end

        -- Update Act Select options based on the first map in the new mode
        local firstMap = getgenv().Settings["Auto"]["StartMap"]["Map_Select"]
        if Value == "Raid" then
            -- Special handling for Raid acts (nested structure)
            updateActOptions(Value, firstMap)
        else
            -- For other modes, standard handling
            updateActOptions(Value, firstMap)
        end
    end,
}, "Mode_Select")

-- Map Select Dropdown
Map_Select = Sections.AutoJoin:Dropdown({
    Name = "Map Select",
    Multi = false,
    Required = false,
    Options = getgenv().Settings["Auto"]["Join"]["Modes"][getgenv().Settings["Auto"]["StartMap"]["Mode_Select"]]["Maps"],
    Default = getgenv().Settings["Auto"]["StartMap"]["Map_Select"],
    Callback = function(Value)
        getgenv().Settings["Auto"]["StartMap"]["Map_Select"] = Value
        SaveS()

        -- If the mode is Raid, handle Act options differently (nested Acts structure)
        if getgenv().Settings["Auto"]["StartMap"]["Mode_Select"] == "Raid" then
            updateActOptions("Raid", Value)
        else
            updateActOptions(getgenv().Settings["Auto"]["StartMap"]["Mode_Select"], Value)
        end
    end,
}, "Map_Select")

-- Act Select Dropdown
Act_Select = Sections.AutoJoin:Dropdown({
    Name = "Act Select",
    Multi = false,
    Required = false,
    Options = getgenv().Settings["Auto"]["Join"]["Modes"][getgenv().Settings["Auto"]["StartMap"]["Mode_Select"]]["Acts"],
    Default = getgenv().Settings["Auto"]["StartMap"]["Act_Select"],
    Callback = function(Value)
        getgenv().Settings["Auto"]["StartMap"]["Act_Select"] = Value
        SaveS()

        Difficulty_Select:ClearOptions()
        Difficulty_Select:InsertOptions(getgenv().Settings["Auto"]["Join"]["Diff"])
    end,
}, "Act_Select")

-- Difficulty Select Dropdown
Difficulty_Select = Sections.AutoJoin:Dropdown({
    Name = "Difficulty Select",
    Multi = false,
    Required = false,
    Options = getgenv().Settings["Auto"]["Join"]["Diff"],
    Default = getgenv().Settings["Auto"]["StartMap"]["Difficulty_Select"],
    Callback = function(Value)
        getgenv().Settings["Auto"]["StartMap"]["Difficulty_Select"] = Value
        SaveS()
    end,
}, "Difficulty_Select")

Sections.AutoJoin:Divider()

Mode_Select:UpdateSelection(getgenv().Settings["Auto"]["StartMap"]["Mode_Select"])
Map_Select:UpdateSelection(getgenv().Settings["Auto"]["StartMap"]["Map_Select"])
Act_Select:UpdateSelection(getgenv().Settings["Auto"]["StartMap"]["Act_Select"])
Difficulty_Select:UpdateSelection(getgenv().Settings["Auto"]["StartMap"]["Difficulty_Select"])

FriendsOnly_Toggle = Sections.AutoJoin:Toggle({
    Name = "Friends Only",
    Default = getgenv().Settings["Auto"]["StartMap"]["FriendsOnly"],
    Callback = function(Bool)
        getgenv().Settings["Auto"]["StartMap"]["FriendsOnly"] = Bool
        SaveS()
    end,
}, "Freinds_Only")
FriendsOnly_Toggle:UpdateState(getgenv().Settings["Auto"]["StartMap"]["FriendsOnly"])

WaitForFriends_Slider = Sections.AutoJoin:Slider({
    Name = "Wait For (seconds)",
    Default = getgenv().Settings["Auto"]["StartMap"]["WaitForFriends_Seconds"],
    Minimum = 0,
    Maximum = 100,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(Value)
        getgenv().Settings["Auto"]["StartMap"]["WaitForFriends_Seconds"] = Value
        SaveS()
    end,
}, "WaitForFriends_Slider")
WaitForFriends_Slider:UpdateValue(getgenv().Settings["Auto"]["StartMap"]["WaitForFriends_Seconds"])

WalkJoin = Sections.AutoJoin:Toggle({
    Name = "Walk to Join [ALL]",
    Default = getgenv().Settings["Auto"]["StartMap"]["WalkToJoin"],
    Callback = function(bool)
        getgenv().Settings["Auto"]["StartMap"]["WalkToJoin"] = bool
        SaveS()
    end,
}, "Walk_To_Join")
WalkJoin:UpdateState(getgenv().Settings["Auto"]["StartMap"]["WalkToJoin"])

AutoJoinMap_Toggle = Sections.AutoJoin:Toggle({
    Name = "Auto Join Map",
    Default = getgenv().Settings["Auto"]["StartMap"]["AutoJoinMap"],
    Callback = function(Bool)
        getgenv().Settings["Auto"]["StartMap"]["AutoJoinMap"] = Bool
        SaveS()
        
        task.defer(function()
            wait(4)
            if getgenv().Settings["Auto"]["StartMap"]["AutoJoinMap"] and game.PlaceId == 16146832113 then
                warn("AutoJoinMap triggered")
                if getgenv().Settings["Auto"]["StartMap"]["Map_Select"] and 
                   getgenv().Settings["Auto"]["StartMap"]["Act_Select"] and 
                   getgenv().Settings["Auto"]["StartMap"]["Difficulty_Select"] then
                    local SelectedStage = MapConvert(getgenv().Settings["Auto"]["StartMap"]["Map_Select"])
                    local SelectedAct = removeSpaces(getgenv().Settings["Auto"]["StartMap"]["Act_Select"])
                    warn(getgenv().Settings["Auto"]["StartMap"]["Mode_Select"], SelectedStage, SelectedAct, 
                         getgenv().Settings["Auto"]["StartMap"]["Difficulty_Select"], getgenv().Settings["Auto"]["StartMap"]["FriendsOnly"])
                    local Match = {
                        "AddMatch",
                        {
                            Difficulty = getgenv().Settings["Auto"]["StartMap"]["Difficulty_Select"],
                            Act = SelectedAct,
                            StageType = getgenv().Settings["Auto"]["StartMap"]["Mode_Select"],
                            Stage = SelectedStage,
                            FriendsOnly = getgenv().Settings["Auto"]["StartMap"]["FriendsOnly"]
                        }
                    }
                    if getgenv().Settings["Auto"]["StartMap"]["AutoJoinMap"] then
                        ReplicatedStorage.Networking.LobbyEvent:FireServer(unpack(Match))
                        wait(0.8)
                        if getgenv().Settings["Auto"]["StartMap"]["WaitForFriends"] then 
                            task.wait(getgenv().Settings["Auto"]["StartMap"]["WaitForFriends_Seconds"])
                            ReplicatedStorage.Networking.LobbyEvent:FireServer("StartMatch")
                        else
                            task.wait()
                            ReplicatedStorage.Networking.LobbyEvent:FireServer("StartMatch")
                        end
                    else

                    end
                else
                    print("Can't Start Map")
                end
            end
        end)
    end,
}, "Auto_Join_Map")
--AutoJoinMap_Toggle:UpdateState(getgenv().Settings["Auto"]["StartMap"]["AutoJoinMap"])

-- TPLobby Section (re-added)
Sections.TPLobby:Button({
    Name = "Teleport To Lobby",
    Callback = function()
        TeleportService:Teleport(16146832113)
    end,
})

----------------------------
--==  AUTO START SECTION  ==--
----------------------------
Sections.AutoStart:Header({ Name = "Auto Start (Vote)" })
StartDelay = Sections.AutoStart:Slider({
    Name = "Auto Start Delay",
    Default = getgenv().Settings["Auto"]["Start"]["Delay"],
    Minimum = 0,
    Maximum = 45,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(Value)
        getgenv().Settings["Auto"]["Start"]["Delay"] = Value
        SaveS()
    end,
}, "Start_Delay")
StartDelay:UpdateValue(getgenv().Settings["Auto"]["Start"]["Delay"])

AutoStartGame = Sections.AutoStart:Toggle({
    Name = "Auto Start Game",
    Default = getgenv().Settings["Auto"]["Start"]["Enabled"],
    Callback = function(bool)
        getgenv().Settings["Auto"]["Start"]["Enabled"] = bool
        SaveS()

        if getgenv().Settings["Auto"]["Start"]["Enabled"] then
            wait(getgenv().Settings["Auto"]["Start"]["Delay"])
            ReplicatedStorage.Networking.SkipWaveEvent:FireServer("Skip")
        end
    end,
}, "Auto_Start_Game")
AutoJoinMap_Toggle:UpdateState(getgenv().Settings["Auto"]["Start"]["Enabled"])

----------------------------
--==  AUTO MATCH OPTIONS  ==--
----------------------------
Sections.AutoOptions:Header({ Name = "Auto Match Settings" })
local AutoNext_Toggle = Sections.AutoOptions:Toggle({
    Name = "Auto Next",
    Default = getgenv().Settings["Auto"]["Next"],
    Callback = function(bool)
        getgenv().Settings["Auto"]["Next"] = bool
        SaveS()

        if bool then
            if FirstRun == false then
                ReplicatedStorage.Networking.EndScreen.VoteEvent:FireServer("Next")
            end
        end
    end,
}, "Auto_Next")
AutoNext_Toggle:UpdateState(getgenv().Settings["Auto"]["Next"])

local AutoReplay_Toggle = Sections.AutoOptions:Toggle({
    Name = "Auto Replay",
    Default = getgenv().Settings["Auto"]["Replay"],
    Callback = function(bool)
        getgenv().Settings["Auto"]["Replay"] = bool
        SaveS()
        
        if bool then
            if FirstRun == false then
                ReplicatedStorage.Networking.EndScreen.VoteEvent:FireServer("Retry")
            end
        end
    end,
}, "Auto_Replay")
AutoReplay_Toggle:UpdateState(getgenv().Settings["Auto"]["Replay"])

local Auto_Leave_Toggle = Sections.AutoOptions:Toggle({
    Name = "Auto Leave",
    Default = getgenv().Settings["Auto"]["Leave"],
    Callback = function(bool)
        getgenv().Settings["Auto"]["Leave"] = bool
        SaveS()
        
        if bool then
            if FirstRun == false then
                ReplicatedStorage.Networking.EndScreen.VoteEvent:FireServer("Leave")
            end
        end
    end,
}, "Auto_Leave")
Auto_Leave_Toggle:UpdateState(getgenv().Settings["Auto"]["Leave"])

local Auto_Skip_Wave_Toggle = Sections.AutoOptions:Toggle({
    Name = "Auto Skip Wave",
    Default = getgenv().Settings["Auto"]["Skip_Wave"],
    Callback = function(bool)
        getgenv().Settings["Auto"]["Skip_Wave"] = bool
        SaveS()
        
        if bool then
            if FirstRun == false then
                game:GetService("ReplicatedStorage").Networking.SkipWaveEvent:FireServer("Skip")
            end
        end
    end,
}, "Auto_Skip_Wave")
Auto_Skip_Wave_Toggle:UpdateState(getgenv().Settings["Auto"]["Skip_Wave"])

local Auto_Next_Portal_Toggle = Sections.AutoOptions:Toggle({
    Name = "Auto Next Portal",
    Default = getgenv().Settings["Auto"]["Next_Portal"],
    Callback = function(bool)
        getgenv().Settings["Auto"]["Next_Portal"] = bool
        SaveS()
        
        if bool then
            if FirstRun == false then
                
            end
        end
    end,
}, "Auto_Next_Portal")
Auto_Next_Portal_Toggle:UpdateState(getgenv().Settings["Auto"]["Next_Portal"])


----------------------------
--==  AUTO PLAY SECTION  ==--
----------------------------
local Autoplay_Sections = {
    AutoPlay_Options = Tabs.AutoPlay:Section({ Side = "Left" }),
    Placements = Tabs.AutoPlay:Section({ Side = "Right" }),
    Upgrades = Tabs.AutoPlay:Section({ Side = "Right" }),
}

Autoplay_Sections.AutoPlay_Options:Header({ Name = "Auto Play Settings" })
Autoplay_Sections.Placements:Header({ Name = "Placement Wave Req (Per Unit)" })
Autoplay_Sections.Upgrades:Header({ Name = "Upgrade Wave Req (Per Unit)" })

placedUnits = {} -- Format: { ["UnitName"] = { "Model1", "Model2", ... } }

if game.PlaceId == 16277809958 and game.PlaceId ~= 16146832113 then
    local unitModuleData = {}
    local unitsDataFolder = ReplicatedStorage.Modules.Data.Entities.UnitsData
    
    -- Load unit module data into a table
    for _, mod in ipairs(unitsDataFolder:GetDescendants()) do
        if mod:IsA("ModuleScript") then
            local success, data = pcall(require, mod)
            if success and data and data.Name then
                unitModuleData[data.Name] = data
            end
        end
    end
    
    -- Function to update unit information
    local function updateUnitInfo(maxObj, unitNameLabel, idx, price)
        local current, maximum = maxObj.Text:match("^(%d+)%s*/%s*(%d+)")
        local displayedName = unitNameLabel.Text  -- Get unit name from the hotbar UI label
    
        -- Look up module data using the displayed name
        local moduleData = unitModuleData[displayedName]
        if not moduleData then
            warn("No moduleData found for displayedName = '" .. tostring(displayedName) .. "'")
            -- Debug: print all known unit names to help diagnose issues
            for k in pairs(unitModuleData) do
                print("  Known unit name:", k)
            end
            return
        end
    
        -- If found, store unit info
        if current and maximum and (current == "1" and maximum == "3") then
            unitInfo[idx] = {
                Name = displayedName,
                Placements = "0/" .. tostring(moduleData.MaxPlacements),
                Price = price,
                Current = 0,
                MaxAllowed = moduleData.MaxPlacements
            }
        elseif current and maximum then
            unitInfo[idx] = {
                Name = displayedName,
                Placements = current .. "/" .. maximum,
                Price = price,
                Current = tonumber(current),
                MaxAllowed = tonumber(maximum)
            }
        end
    
        -- Store max placements in settings
        getgenv().Settings["AutoPlay"]["Placement"]["Max_Placements"]["Unit_" .. idx] = unitInfo[idx].MaxAllowed
    
        -- Debug output to verify
        print("Updated Unit " .. idx .. ": " .. unitInfo[idx].Name ..
              ", Placements: " .. unitInfo[idx].Current .. "/" .. unitInfo[idx].MaxAllowed ..
              ", Price: " .. tostring(price) .. "¥")
    end
    
    -- Iterate through hotbar UI elements to find units
    for _, frame in ipairs(UnitsGui:GetChildren()) do
        local idx = tonumber(frame.Name)
        if frame:IsA("Frame") and idx and frame:FindFirstChild("UnitTemplate") then
            local unitTemplate = frame.UnitTemplate
            local holder = unitTemplate:FindFirstChild("Holder")
            local main = holder and holder:FindFirstChild("Main")
        
            if main then
                local unitNameLabel = main:FindFirstChild("UnitName") -- Get the unit name from UI
                local maxObj = main:FindFirstChild("MaxPlacement")
                local priceObj = main:FindFirstChild("Price")
            
                if unitNameLabel and unitNameLabel:IsA("TextLabel") and maxObj then
                    local price = "N/A"
                    if priceObj then
                        if priceObj:IsA("TextLabel") then
                            price = string.gsub(priceObj.Text, "¥", "")  -- Extract price text
                            price = string.gsub(price, ",", "")
                        elseif priceObj:FindFirstChild("Value") then
                            price = priceObj.Value
                            price = string.gsub(price, ",", "")
                        else
                            price = priceObj
                            price = string.gsub(price, ",", "")
                        end
                    end
                
                    -- Call function to update unit info
                    updateUnitInfo(maxObj, unitNameLabel, idx, price)
                
                    -- If placement count changes, re-update
                    maxObj:GetPropertyChangedSignal("Text"):Connect(function()
                        updateUnitInfo(maxObj, unitNameLabel, idx, price)
                    end)
                end
            end
        end
    end
    
    -- Print out unit info for debugging
    for i = 1, 6 do
        local info = unitInfo[i]
        print("Unit " .. i .. ": " .. (info and (info.Name .. ", Placements: " ..
              tostring(info.Current) .. "/" .. tostring(info.MaxAllowed) ..
              ", Price: " .. tostring(info.Price) .. "¥") or "Not Found"))
    end
end

-- Function to update the current placed units
function updateCurrentPlaced()
    for unitName, models in pairs(placedUnits) do
        updatedModels = {}
        foundCount = 0

        for _, modelName in ipairs(models) do
            if Workspace.Units:FindFirstChild(modelName) then
                table.insert(updatedModels, modelName)
                foundCount = foundCount + 1
            else
                print("❌ Unit model missing in workspace: " .. modelName)
            end
        end

        -- Update tracking table
        placedUnits[unitName] = updatedModels

        -- Find the correct unit slot in unitInfo
        for i = 1, 6 do
            if unitInfo[i] and unitInfo[i].Name == unitName then
                local previousCount = unitInfo[i].Placed
                unitInfo[i].Placed = foundCount

                if previousCount ~= foundCount then
                    print("🔄 Updated Unit " .. i .. ": Current: " .. unitInfo[i].Placed .. " / Max: " .. unitInfo[i].MaxAllowed)
                end
                break
            end
        end
    end
end



-----------------------------------------------------------
-- Helper Functions
-----------------------------------------------------------

-- Optimized Cancellation Helper
function shouldAbort(token)
    return (not getgenv().Settings["AutoPlay"]["Enabled"]) or matchEnded or (autoplayToken ~= token)
end

local function getUnitData(unitName)
    -- Look up unit data from AllUnitsInfo.
    for _, data in ipairs(AllUnitsInfo) do
        if data.Name == unitName then
            return data
        end
    end
    return nil
end

local function selectUpgradeCandidate(candidates)
    -- If Focus_Farms is enabled, prefer candidates in the farm list.
    local farmList = {"Sprintwagon", "Takaroda"}
    if getgenv().Settings["AutoPlay"]["Upgrade"]["Focus_Farms"] then
        local farmCandidates = {}
        for _, cand in ipairs(candidates) do
            if table.find(farmList, cand.unitName) then
                table.insert(farmCandidates, cand)
            end
        end
        if #farmCandidates > 0 then
            table.sort(farmCandidates, function(a, b) return a.cost < b.cost end)
            return farmCandidates[1]
        end
    end
    table.sort(candidates, function(a, b) return a.cost < b.cost end)
    return candidates[1]
end

local function getNextUpgradePrice(unitData, currentLevel)
    -- Get the next upgrade price based on the current upgrade level.
    if currentLevel < #unitData.Upgrades then
        return unitData.Upgrades[currentLevel + 1].Price or math.huge
    end
    return math.huge  -- No more upgrades, return a high value.
end

-----------------------------------------------------------
-- Main Function: trigger_AutoPlayAndUpgrade
-----------------------------------------------------------

local currentToken
function trigger_AutoPlayAndUpgrade()
    if not getgenv().Settings["AutoPlay"]["Enabled"] then return end
    if matchEnded then
        print("⏹️ Match already ended. Exiting process.")
        resetAutoplayState()
        return
    end


    -- If the function is being re-triggered, use saved state if available
    local savedState = getgenv().SavedAutoPlayState or {}
    local nextPlacementIndex = savedState.nextPlacementIndex or 1
    local placedUnits = savedState.placedUnits or {}
    local upgradeTracking = savedState.upgradeTracking or {}  -- [GUID] = current level
    local totalUpgrades = savedState.totalUpgrades or {}  -- [GUID] = count
    local stopUpgrade = savedState.stopUpgrade or false
    local candidateToUpgrade = savedState.candidateToUpgrade

    -- Create a new run token.
    autoplayToken = tick()
    currentToken = autoplayToken
    autoplayEnableCount = autoplayEnableCount + 1
    if autoplayEnableCount > 1 then updateCurrentPlaced() end

    -- Build unit order if not already built.
    local lowestCostFirst = true
    if #autoplayState.unitOrder == 0 then
        for i = 1, 6 do
            if unitInfo[i] then
                table.insert(autoplayState.unitOrder, { index = i, info = unitInfo[i] })
            end
        end
        if lowestCostFirst then
            table.sort(autoplayState.unitOrder, function(a, b)
                return tonumber(a.info.Price) < tonumber(b.info.Price)
            end)
        end
    end

    local heightAddition = 0

    -------------------------------------------------
    -- PLACEMENT LOOP (spawned)
    -------------------------------------------------
    spawn(function()
        wait(1)
        while getgenv().Settings["AutoPlay"]["Enabled"] and not matchEnded and currentToken == autoplayToken do
        -- Calculate the next-placement threshold: the minimum cost among units eligible for placement.
        local nextPlacementThreshold = math.huge
        for _, entry in ipairs(autoplayState.unitOrder) do
            local info = entry.info
            local unitSlot = entry.index
            local reqWave = getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_" .. unitSlot]
            local settingMax = getgenv().Settings["AutoPlay"]["Placement"]["Max_Placements"]["Unit_" .. unitSlot]
            local maxAllowed = settingMax and tonumber(settingMax) or info.MaxAllowed
            local placedCount = info.Placed or 0
            if placedCount < maxAllowed and tonumber(currentWave) >= reqWave then
                local price = tonumber(info.Price) or 0
                if price < nextPlacementThreshold then
                    nextPlacementThreshold = price
                end
            end
        end
        stopUpgrade = (CurrentYen >= nextPlacementThreshold)

        local anyAction = false
        for _, entry in ipairs(autoplayState.unitOrder) do
            if shouldAbort(currentToken) then break end
            local info = entry.info
            local unitSlot = entry.index
            local reqWave = getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_" .. unitSlot]
            local settingMax = getgenv().Settings["AutoPlay"]["Placement"]["Max_Placements"]["Unit_" .. unitSlot]
            local maxAllowed = settingMax and tonumber(settingMax) or info.MaxAllowed
            local placedCount = info.Placed or 0

            if placedCount < maxAllowed then
                if tonumber(currentWave) >= reqWave then
                    -- Re-grab placement parts to ensure the latest positions.
                    local placements = {}
                    if globalPlacements and #globalPlacements > 0 then
                        for _, part in ipairs(globalPlacements) do
                            local num = tonumber(part.Name:match("Placement_(%d+)"))
                            if num then placements[num] = part end
                        end
                    else
                        print("Warning: globalPlacements is nil or empty!")
                    end

                    -- Loop through the placement index and max allowed.
                    while placedCount < maxAllowed and autoplayState.nextPlacementIndex <= #placements do
                        if shouldAbort(currentToken) then break end

                        local requiredPrice = tonumber(info.Price) or 0
                        while CurrentYen < requiredPrice do
                            task.wait(0.2)
                            if shouldAbort(currentToken) then break end
                        end
                        if shouldAbort(currentToken) then break end

                        -- Re-grab the placements table before getting the placement part.
                        placements = {}
                        if globalPlacements and #globalPlacements > 0 then
                            for _, part in ipairs(globalPlacements) do
                                local num = tonumber(part.Name:match("Placement_(%d+)"))
                                if num then placements[num] = part end
                            end
                        end

                        -- Ensure we always grab the updated placements.
                        local placementPart = placements[autoplayState.nextPlacementIndex]  -- Re-grab updated placement part
                        local spawnPos = placementPart.Position + Vector3.new(0, heightAddition, 0)

                        local placementSuccess = false
                        local referenceGUID = nil
                        local tempConn
                        tempConn = UnitEvent.OnClientEvent:Connect(function(...)
                            local args = {...}
                            if args[1] == "ReplicatePlacedUnits" and type(args[2]) == "table" then
                                local rep = args[2]
                                if rep[info.Name] then
                                    for _, guid in ipairs(rep[info.Name]) do
                                        if not table.find(placedUnits[info.Name] or {}, guid) then
                                            referenceGUID = guid
                                            placementSuccess = true
                                            break
                                        end
                                    end
                                    if placementSuccess and tempConn then
                                        tempConn:Disconnect()
                                    end
                                end
                            end
                        end)

                        local unitCode = EntityIDHandler:GetIDFromName("Unit", info.Name, true)
                        print("🔄 Placing " .. info.Name .. " at index " .. autoplayState.nextPlacementIndex)
                        UnitEvent:FireServer("Render", {info.Name, unitCode, spawnPos, 0})
                        local startTime = tick()
                        while not placementSuccess and tick() - startTime < 0.3 do
                            task.wait(0.05)
                        end

                        if placementSuccess then
                            placedCount = placedCount + 1
                            info.Placed = placedCount
                            placedUnits[info.Name] = placedUnits[info.Name] or {}
                            table.insert(placedUnits[info.Name], referenceGUID)
                            print("✅ " .. info.Name .. " placed (" .. placedCount .. "/" .. maxAllowed .. "); GUID: " .. tostring(referenceGUID))
                            anyAction = true
                        else
                            print("❌ Placement failed at index " .. autoplayState.nextPlacementIndex)
                        end

                        autoplayState.nextPlacementIndex = autoplayState.nextPlacementIndex + 1
                    end
                else
                    print("⏳ Skipping placement for " .. info.Name .. " (req wave: " .. reqWave .. ", current: " .. tostring(currentWave) .. ")")
                end
            end
        end

        if shouldAbort(currentToken) then break end
        print("⌛ Placement loop waiting...")
        task.wait(2)
        end

        -- Save state before exiting
        getgenv().SavedAutoPlayState = {
            nextPlacementIndex = autoplayState.nextPlacementIndex,
            placedUnits = placedUnits,
            upgradeTracking = upgradeTracking,
            totalUpgrades = totalUpgrades,
            stopUpgrade = stopUpgrade,
            candidateToUpgrade = candidateToUpgrade
        }
    end)


    ---------------------------------
    -- UPGRADE LOOP (spawned)
    ---------------------------------
    spawn(function()
        -- Wait until at least one unit is placed.
        while next(placedUnits) == nil do
            task.wait(1)
        end

        -- Variable to track active upgrade connection.
        local upgradeConn

        while getgenv().Settings["AutoPlay"]["Enabled"] and not matchEnded and currentToken == autoplayToken do
            -- Wait for upgrade toggle to be enabled if it was disabled.
            if not getgenv().Settings["AutoPlay"]["Upgrade"]["Enabled"] then
                print("Auto Upgrade disabled. Waiting for it to be enabled...")
                task.wait(1) -- Keep waiting for the toggle to be enabled
                continue
            end

            if stopUpgrade then
                task.wait(1)
                continue
            end

            -- Prevent duplicate connections for upgrades
            if upgradeConn then
                upgradeConn:Disconnect()
            end

            local upgradeCandidates = {}
            for unitName, guidList in pairs(placedUnits) do
                for _, guid in ipairs(guidList) do
                    local currentLevel = upgradeTracking[guid] or 1
                    local unitData = getUnitData(unitName)
                    if unitData then
                        local maxLevel = (#unitData.Upgrades) + 1
                        if currentLevel < maxLevel then
                            local cost = getNextUpgradePrice(unitData, currentLevel)
                            if cost ~= math.huge then
                                table.insert(upgradeCandidates, { guid = guid, unitName = unitName, cost = cost, currentLevel = currentLevel })
                            end
                        end
                    end
                end
            end

            if #upgradeCandidates == 0 then
                print("🎉 All units are fully upgraded!")
                getgenv().SavedUpgradeTracking = nil
                getgenv().SavedTotalUpgrades = nil
                break
            end

            local candidateToUpgrade = selectUpgradeCandidate(upgradeCandidates)
            print("🔍 Upgrade candidate: " .. candidateToUpgrade.unitName ..
                  " (GUID: " .. candidateToUpgrade.guid .. "), Level: " .. candidateToUpgrade.currentLevel ..
                  ", Cost: " .. candidateToUpgrade.cost)

            while CurrentYen < candidateToUpgrade.cost do
                task.wait(0.5)
                if not getgenv().Settings["AutoPlay"]["Enabled"] or not getgenv().Settings["AutoPlay"]["Upgrade"]["Enabled"] then break end
            end

            if not getgenv().Settings["AutoPlay"]["Enabled"] or matchEnded or currentToken ~= autoplayToken or not getgenv().Settings["AutoPlay"]["Upgrade"]["Enabled"] then
                break
            end

            -- Set up a temporary connection to track the upgrade.
            upgradeConn = UnitEvent.OnClientEvent:Connect(function(eventType, guid, upgradeData)
                -- Ensure we are processing the correct upgrade event and that the GUID matches
                if eventType == "Upgrade" and guid == candidateToUpgrade.guid then
                    -- Check if the upgrade data is valid and contains the necessary fields
                    if upgradeData and upgradeData.Data and upgradeData.Data.CurrentUpgrade then
                        local currentUpgradeLevel = upgradeData.Data.CurrentUpgrade
                    
                        -- Upgrade successful, track it based on the CurrentUpgrade value
                        upgradeTracking[guid] = currentUpgradeLevel
                        totalUpgrades[guid] = (totalUpgrades[guid] or 0) + 1
                        print("🔄 Upgraded " .. candidateToUpgrade.unitName .. " (GUID: " .. candidateToUpgrade.guid .. ") to level " .. 
                              currentUpgradeLevel .. " (" .. totalUpgrades[guid] .. " total)")

                        -- Update the candidate with the latest upgrade data (to reflect the new level)
                        candidateToUpgrade.currentLevel = currentUpgradeLevel
                    
                        print("New Upgrade Data: CurrentUpgrade " .. currentUpgradeLevel .. " for unit: " .. guid)
                        
                        -- Disconnect the connection after the upgrade is successfully handled
                        upgradeConn:Disconnect()

                        -- Re-select the upgrade candidate with the updated information
                        local upgradeCandidates = {}  -- Refresh the upgrade candidate list
                        for unitName, guidList in pairs(placedUnits) do
                            for _, guid in ipairs(guidList) do
                                local unitData = getUnitData(unitName)
                                if unitData then
                                    local currentLevel = upgradeTracking[guid] or 1
                                    local maxLevel = (#unitData.Upgrades) + 1
                                    if currentLevel < maxLevel then
                                        local cost = getNextUpgradePrice(unitData, currentLevel)
                                        if cost ~= math.huge then
                                            table.insert(upgradeCandidates, { guid = guid, unitName = unitName, cost = cost, currentLevel = currentLevel })
                                        end
                                    end
                                end
                            end
                        end

                        -- Re-run the candidate selection with the updated list
                        candidateToUpgrade = selectUpgradeCandidate(upgradeCandidates)
                        print("🔍 Next upgrade candidate selected: " .. candidateToUpgrade.unitName ..
                              " (GUID: " .. candidateToUpgrade.guid .. "), Level: " .. candidateToUpgrade.currentLevel .. 
                              ", Cost: " .. candidateToUpgrade.cost)
                    end
                end
            end)

            -- Fire the upgrade remote.
            UnitEvent:FireServer("Upgrade", candidateToUpgrade.guid)
            print("🔄 Upgrading unit " .. candidateToUpgrade.unitName .. " (GUID: " .. candidateToUpgrade.guid .. ")")

            task.wait(0.5)
        end
        print("Upgrade loop finished.")
    end)

    -- Save state before exiting
    getgenv().SavedAutoPlayState = {
        nextPlacementIndex = autoplayState.nextPlacementIndex,
        placedUnits = placedUnits,
        upgradeTracking = upgradeTracking,
        totalUpgrades = totalUpgrades,
        stopUpgrade = stopUpgrade,
        candidateToUpgrade = candidateToUpgrade
    }

    print("🎉 AutoPlayAndUpgrade process started.")
end

-- Helper function: Updates the placement visualizer position based on a percentage along the track.
function updatePlacementVisualizer(percent)
    -- Retrieve and sort the nodes
    local mapFolder = Workspace:FindFirstChild("Map")
    if not mapFolder then return end
    local nodesFolder = mapFolder:FindFirstChild("Nodes")
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
    local cylinder = Workspace.Placements_Container and Workspace.Placements_Container:FindFirstChild("PlacementVisualizer")
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
    local visualizer = Workspace.Placements_Container and Workspace.Placements_Container:FindFirstChild("PlacementVisualizer")
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

--[[ --== Might add later?
local Ground_Percent = Autoplay_Sections.AutoPlay_Options:Slider({
    Name = "Ground Size",
    Default = getgenv().Settings["AutoPlay"]["Placement"]["PlacementSize"],
    Minimum = 0,
    Maximum = 100,
    DisplayMethod = "Percent",
    Callback = function(Value)
        getgenv().Settings["AutoPlay"]["Placement"]["PlacementSize"] = Value
        SaveS()
        
        print("Ground Size set to " .. Value .. "%")
        
        updateCylinderSize()
    end,
}, "Ground_Percent_Flag")
Ground_Percent:UpdateValue(getgenv().Settings["AutoPlay"]["Placement"]["PlacementSize"])
--]]

-- Then, update the slider callback for Distance_FromSpawn:
local Distance_FromSpawn = Autoplay_Sections.AutoPlay_Options:Slider({
    Name = "Distance",
    Default = getgenv().Settings["AutoPlay"]["Placement"]["Distance"],
    Minimum = 0,
    Maximum = 100,
    DisplayMethod = "Percent",
    Callback = function(Value)
        getgenv().Settings["AutoPlay"]["Placement"]["Distance"] = Value
        SaveS()
        
        print("Distance From Spawn set to " .. Value .. "%")
        updatePlacementVisualizer(Value)
        -- Optionally, you may wish to call updateCurrentPlaced() if needed.
    end,
}, "Distance_Percent_Flag")
Distance_FromSpawn:UpdateValue(getgenv().Settings["AutoPlay"]["Placement"]["Distance"])

--[[ --== Might add later?
local Spread_Percent = Autoplay_Sections.AutoPlay_Options:Slider({
    Name = "Unit Spread",
    Default = getgenv().Settings["AutoPlay"]["Placement"]["Spread"],
    Minimum = 0,
    Maximum = 100,
    DisplayMethod = "Percent",
    Callback = function(Value)
        getgenv().Settings["AutoPlay"]["Placement"]["Spread"] = Value
        SaveS()
        
        print("Unit Spread set to " .. Value .. "%")
        -- Optionally update placement logic for unit spread.
    end,
}, "Spread_Percent_Flag")
Spread_Percent:UpdateValue(getgenv().Settings["AutoPlay"]["Placement"]["Spread"])
--]]

-- Create the toggle to control cylinder and cubes' transparency
local Transparency_Toggle = Autoplay_Sections.AutoPlay_Options:Toggle({
    Name = "View Placements (Debug)",
    Default = getgenv().Settings["AutoPlay"]["TransparencyEnabled"] or false,  -- You can set a default value for this
    Callback = function(bool)
        getgenv().Settings["AutoPlay"]["TransparencyEnabled"] = bool
        SaveS()  -- Assuming this function saves the settings
        
        pcall(function()
            local cylinder = Workspace.Placements_Container and Workspace.Placements_Container:FindFirstChild("PlacementVisualizer")
            
            if bool then
                cylinder.Transparency = 0.75  -- Set the cylinder transparency to 0.75

                -- Loop through the cubes in the Placements container
                local placementsContainer = Workspace.Placements_Container:FindFirstChild("PlacementVisualizer"):FindFirstChild("Placements")
                if placementsContainer then
                    for _, cube in ipairs(placementsContainer:GetChildren()) do
                        if cube:IsA("Part") then  -- Ensure it's a Part (cube)
                            cube.Transparency = 0.75  -- Set each cube's transparency to 0.75
                        end
                    end
                end
            else
                -- If the toggle is off, make cylinder and all cubes fully transparent (invisible)
                cylinder.Transparency = 1  -- Set the cylinder transparency to 1 (hidden)

                -- Loop through the cubes in the Placements container
                local placementsContainer = Workspace.Placements_Container:FindFirstChild("PlacementVisualizer"):FindFirstChild("Placements")
                if placementsContainer then
                    for _, cube in ipairs(placementsContainer:GetChildren()) do
                        if cube:IsA("Part") then  -- Ensure it's a Part (cube)
                            cube.Transparency = 1  -- Set each cube's transparency to 1 (hidden)
                        end
                    end
                end
            end
        end)
    end,
}, "Cylinder_Transparency_Flag")
--AutoPlayTransparency_Toggle_Toggle:UpdateState(getgenv().Settings["AutoPlay"]["TransparencyEnabled"])

AutoPlay_Toggle = Autoplay_Sections.AutoPlay_Options:Toggle({
    Name = "Autoplay",
    Default = getgenv().Settings["AutoPlay"]["Enabled"],
    Callback = function(bool)
        getgenv().Settings["AutoPlay"]["Enabled"] = bool
        SaveS()
        
    end,
}, "Auto_Play_Flag")

Unit1_Place = Autoplay_Sections.Placements:Slider({
    Name = "Unit 1",
    Default = getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_1"],
    Minimum = 1,
    Maximum = 50,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(Value)
        getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_1"] = Value
        SaveS()
        
    end
}, "Unit1_Place_Flag")
Unit1_Place:UpdateValue(getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_1"])

Unit2_Place = Autoplay_Sections.Placements:Slider({
    Name = "Unit 2",
    Default = getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_2"],
    Minimum = 1,
    Maximum = 50,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(Value)
        getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_2"] = Value
        SaveS()
        
    end
}, "Unit2_Place_Flag")
Unit2_Place:UpdateValue(getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_2"])

Unit3_Place = Autoplay_Sections.Placements:Slider({
    Name = "Unit 3",
    Default = getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_3"],
    Minimum = 1,
    Maximum = 50,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(Value)
        getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_3"] = Value
        SaveS()
        
    end
}, "Unit3_Place_Flag")
Unit3_Place:UpdateValue(getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_3"])

Unit4_Place = Autoplay_Sections.Placements:Slider({
    Name = "Unit 4",
    Default = getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_4"],
    Minimum = 1,
    Maximum = 50,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(Value)
        getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_4"] = Value
        SaveS()
        
    end
}, "Unit4_Place_Flag")
Unit4_Place:UpdateValue(getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_4"])

Unit5_Place = Autoplay_Sections.Placements:Slider({
    Name = "Unit 5",
    Default = getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_5"],
    Minimum = 1,
    Maximum = 50,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(Value)
        getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_5"] = Value
        SaveS()
        
    end
}, "Unit5_Place_Flag")
Unit5_Place:UpdateValue(getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_5"])

Unit6_Place = Autoplay_Sections.Placements:Slider({
    Name = "Unit 6",
    Default = getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_6"],
    Minimum = 1,
    Maximum = 50,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(Value)
        getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_6"] = Value
        SaveS()
        
    end
}, "Unit6_Place_Flag")
Unit6_Place:UpdateValue(getgenv().Settings["AutoPlay"]["Placement"]["Place_On_Wave"]["Unit_6"])

Auto_Upgrade_Toggle = Autoplay_Sections.Upgrades:Toggle({
    Name = "Auto Upgrade",
    Default = getgenv().Settings["AutoPlay"]["Upgrade"]["Enabled"],
    Callback = function(bool)
        getgenv().Settings["AutoPlay"]["Upgrade"]["Enabled"] = bool
        SaveS()
        
        if getgenv().Settings["AutoPlay"]["Upgrade"]["Enabled"] and autoplayState.phase == "upgrading" then
            if game.PlaceId == 16277809958 and game.PlaceId ~= 16146832113 then
                trigger_AutoUpgrade(currentToken)
            end
        end
    end,
}, "Auto_Upgrade_Flag")

PrioritizeFarm_Toggle = Autoplay_Sections.Upgrades:Toggle({
    Name = "Prioritize Farms",
    Default = getgenv().Settings["AutoPlay"]["Upgrade"]["Focus_Farms"],
    Callback = function(bool)
        getgenv().Settings["AutoPlay"]["Upgrade"]["Focus_Farms"] = bool
        SaveS()
        
    end,
}, "Prioritize_Farms_Flag")

Unit1_Upg = Autoplay_Sections.Upgrades:Slider({
	Name = "Unit 1",
	Default = getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_1"],
	Minimum = 1,
	Maximum = 50,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_1"] = Value
        SaveS()
        
	end
}, "Unit1_Upg_Flag")
Unit1_Upg:UpdateValue(getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_1"])

Unit2_Upg = Autoplay_Sections.Upgrades:Slider({
	Name = "Unit 2",
	Default = getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_2"],
	Minimum = 1,
	Maximum = 50,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_2"] = Value
        SaveS()
        
	end
}, "Unit2_Upg_Flag")
Unit2_Upg:UpdateValue(getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_2"])

Unit3_Upg = Autoplay_Sections.Upgrades:Slider({
	Name = "Unit 3",
	Default = getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_3"],
	Minimum = 1,
	Maximum = 50,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_3"] = Value
        SaveS()
        
	end
}, "Unit3_Upg_Flag")
Unit3_Upg:UpdateValue(getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_3"])

Unit4_Upg = Autoplay_Sections.Upgrades:Slider({
	Name = "Unit 4",
	Default = getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_4"],
	Minimum = 1,
	Maximum = 50,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_4"] = Value
        SaveS()
        
	end
}, "Unit4_Upg_Flag")
Unit4_Upg:UpdateValue(getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_4"])

Unit5_Upg = Autoplay_Sections.Upgrades:Slider({
	Name = "Unit 5",
	Default = getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_5"],
	Minimum = 1,
	Maximum = 50,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_5"] = Value
        SaveS()
        
	end
}, "Unit5_Upg_Flag")
Unit5_Upg:UpdateValue(getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_5"])

Unit6_Upg = Autoplay_Sections.Upgrades:Slider({
	Name = "Unit 6",
	Default = getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_6"],
	Minimum = 1,
	Maximum = 50,
	DisplayMethod = "Value",
	Precision = 0,
	Callback = function(Value)
		getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_6"] = Value
        SaveS()
        
	end
}, "Unit6_Upg_Flag")
Unit6_Upg:UpdateValue(getgenv().Settings["AutoPlay"]["Upgrade"]["Upgrade_On_Wave"]["Unit_6"])

----------------------------
---==  Update Toggles  ==---
----------------------------
PrioritizeFarm_Toggle:UpdateState(getgenv().Settings["AutoPlay"]["Upgrade"]["Focus_Farms"])
Auto_Upgrade_Toggle:UpdateState(getgenv().Settings["AutoPlay"]["Upgrade"]["Enabled"])
AutoPlay_Toggle:UpdateState(getgenv().Settings["AutoPlay"]["Enabled"])


----------------------------
--==  SHOP & MISC SECTIONS  ==--
----------------------------
local Shop_Sections
if game.PlaceId == 16146832113 and game.PlaceId ~= 16277809958 then
    Shop_Sections = {
        Shop_Banner = Tabs.Shop:Section({ Side = "Left" }),
        Shop_Gold = Tabs.Shop:Section({ Side = "Right" }),
    }
else
    Shop_Sections = { Shop_Banner = Tabs.Shop:Section({ Side = "Left" }) }
end

SummonMode = Shop_Sections.Shop_Banner:Dropdown({
    Name = "Summon Mode",
    Multi = false,
    Required = false,
    Options = {"All Gems", "Until Target Unit", "Only Use Specified Gems"},
    Default = getgenv().Settings["Shop"]["Summon"]["SummonMode"],
    Callback = function(Value)
        getgenv().Settings["Shop"]["Summon"]["SummonMode"] = Value
        SaveS()
        
    end,
}, "Summon_Mode")
SummonMode:UpdateSelection(getgenv().Settings["Shop"]["Summon"]["SummonMode"])

Shop_Sections.Shop_Banner:SubLabel({ Text = "BANNER INFO:\nSpecial = Normal Banner\nWinter = Winter Event" })

BannerSelect = Shop_Sections.Shop_Banner:Dropdown({
    Name = "Selected Banner",
    Multi = false,
    Required = false,
    Options = {"Special", "Winter"},
    Default = getgenv().Settings["Shop"]["Summon"]["SelectedBanner"],
    Callback = function(Value)
        getgenv().Settings["Shop"]["Summon"]["SelectedBanner"] = Value
        SaveS()
        
    end,
}, "Selected_Banner")
BannerSelect:UpdateSelection(getgenv().Settings["Shop"]["Summon"]["SelectedBanner"])

TargetUnit = Shop_Sections.Shop_Banner:Dropdown({
    Name = "Target Unit",
    Multi = false,
    Required = false,
    Options = unitNames,
    Search = true,
    Default = getgenv().Settings["Shop"]["Summon"]["TargetUnit"],
    Callback = function(Value)
        getgenv().Settings["Shop"]["Summon"]["TargetUnit"] = Value
        SaveS()
        
    end,
}, "Target_Unit")
TargetUnit:UpdateSelection(getgenv().Settings["Shop"]["Summon"]["TargetUnit"])

Gem_Amount = Shop_Sections.Shop_Banner:Input({
    Name = "Gem Amount",
    Placeholder = "Gems to use",
    AcceptedCharacters = "Numeric",
    Callback = function(input)
        getgenv().Settings["Shop"]["Summon"]["Gem_Amount"] = input
        SaveS()
        
    end,
}, "Input")
--Gem_Amount:UpdateText(getgenv().Settings["Shop"]["Summon"]["Gem_Amount"])

Ten_Mode = Shop_Sections.Shop_Banner:Toggle({
    Name = "Buy 10",
    Default = getgenv().Settings["Shop"]["Summon"]["Buy10_Mode"],
    Callback = function(bool)
        getgenv().Settings["Shop"]["Summon"]["Buy10_Mode"] = bool
        SaveS()
        
    end,
}, "Buy10_Mode")
Ten_Mode:UpdateState(getgenv().Settings["Shop"]["Summon"]["Buy10_Mode"])

Specific_Mode = Shop_Sections.Shop_Banner:Toggle({
    Name = "Specific # Summons",
    Default = getgenv().Settings["Shop"]["Summon"]["Specific_Summon_Mode"],
    Callback = function(bool)
        getgenv().Settings["Shop"]["Summon"]["Specific_Summon_Mode"] = bool
        SaveS()
        
    end,
}, "Specific_Summon_Mode")
Specific_Mode:UpdateState(getgenv().Settings["Shop"]["Summon"]["Specific_Summon_Mode"])

Summon_Amount = Shop_Sections.Shop_Banner:Slider({
    Name = "Summon Amount",
    Default = getgenv().Settings["Shop"]["Summon"]["Specific_Summon_Amount"],
    Minimum = 1,
    Maximum = 9,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(Value)
        getgenv().Settings["Shop"]["Summon"]["Specific_Summon_Amount"] = Value
        SaveS()
        
    end,
}, "Specific_Summon_Amount")
Summon_Amount:UpdateValue(getgenv().Settings["Shop"]["Summon"]["Specific_Summon_Amount"])

-- Auto-summon functions:
function Specific_Summon(Banner, Amount)
    local args = {"SummonMany", Banner, Amount}
    ReplicatedStorage.Networking.Units.SummonEvent:FireServer(unpack(args))
end

function Ten_Summon(Banner)
    local args = {"SummonTen", Banner}
    ReplicatedStorage.Networking.Units.SummonEvent:FireServer(unpack(args))
end

local Enable_Summon

if game.PlaceId == 16146832113 and game.PlaceId ~= 16277809958 then
    -- Create a global connection for summon event results (created only once):
    if not autoSummonConnection then
        autoSummonConnection = ReplicatedStorage.Networking.Units.SummonEvent.OnClientEvent:Connect(function(args)
            print("autoSummonConnection received event:", args[1])
            if args[1] == "SummonTenAnimation" then
                local unitsTable = args[2]
                for _, unitInfoReturned in ipairs(unitsTable) do
                    local identifier = unitInfoReturned.UnitObject.UniqueIdentifier
                    local unitName = require(ReplicatedStorage.Modules.Data.Entities.EntityIDHandler).GetNameFromID("Unit", "Unit", identifier)
                    print("Summoned unit from event: " .. unitName)
                    if getgenv().Settings["Shop"]["Summon"]["TargetUnit"] == unitName then
                        print("Target unit reached: " .. unitName)
                        getgenv().Settings["Shop"]["Summon"]["Enable_Summons"] = false
                        if Enable_Summon and Enable_Summon.UpdateState then
                            Enable_Summon:UpdateState(false)
                        end
                    end
                end
            end
        end)
    end

    function trigger_AutoSummon()
        local SummonSettings = getgenv().Settings["Shop"]["Summon"]
        
        local summonMode = SummonSettings["SummonMode"]
        local selectedBanner = SummonSettings["SelectedBanner"]
        if not summonMode or summonMode == 0 then
            warn("Error: SummonMode not selected or 0")
            return
        end
        if not selectedBanner or selectedBanner == 0 then
            warn("Error: SelectedBanner not selected or 0")
            return
        end

        local isWinter = (selectedBanner == "Winter")
        local isSpecial = (selectedBanner == "Special")

        -- Get current currency based on banner type:
        local currentCurrency = 0
        if isWinter then
            local presentObj = Client.PlayerGui.HUD.Main.Currencies:FindFirstChild("Present")
            if not presentObj or not presentObj:FindFirstChild("Amount") then
                warn("Error: Presents currency not found!")
                return
            end
            currentCurrency = tonumber(presentObj.Amount.Text) or 0
        elseif isSpecial then
            local gemsObj = Client.PlayerGui.HUD.Main.Currencies:FindFirstChild("Gems")
            if not gemsObj or not gemsObj:FindFirstChild("Amount") then
                warn("Error: Gems currency not found!")
                return
            end
            currentCurrency = tonumber(gemsObj.Amount.Text) or 0
        end


        -- Determine cost per unit based on banner type and gamepass (only applicable for Special)
        local costPerUnit = 0
        local costForTen = 0
        if isSpecial then
            local gamepassOwned = MarketplaceService:UserOwnsGamePassAsync(Client.UserId, 843295206)
            if gamepassOwned then
                costPerUnit = 40
                costForTen = 400
            else
                costPerUnit = 50
                costForTen = 500
            end
        elseif isWinter then
            costPerUnit = 150
            costForTen = 1500
        end

        while SummonSettings["Enable_Summons"] do
            -- Refresh current currency:
            if isWinter then
                local presentObj = Client.PlayerGui.HUD.Main.Currencies:FindFirstChild("Present")
                if not presentObj or not presentObj:FindFirstChild("Amount") then
                    warn("Error: Presents currency not found!")
                    return
                end
                currentCurrency = tonumber(presentObj.Amount.Text) or 0
            elseif isSpecial then
                local gemsObj = Client.PlayerGui.HUD.Main.Currencies:FindFirstChild("Gems")
                if not gemsObj or not gemsObj:FindFirstChild("Amount") then
                    warn("Error: Gems currency not found!")
                    return
                end
                currentCurrency = tonumber(gemsObj.Amount.Text) or 0
            end

            if summonMode == "All Gems" then
                print("All Gems mode triggered!")
                if SummonSettings["Specific_Summon_Mode"] then
                    Specific_Summon(selectedBanner, SummonSettings["Specific_Summon_Amount"])
                elseif SummonSettings["Buy10_Mode"] then
                    Ten_Summon(selectedBanner)
                else
                    warn("No specific summon method selected for All Gems mode.")
                end

            elseif summonMode == "Only Use Specified Gems" then
                if currentCurrency < (SummonSettings["Gem_Amount"] or 0) then
                    print("Not enough currency (" .. currentCurrency .. ") for Only Use Specified Gems mode. Waiting...")
                else
                    if SummonSettings["Specific_Summon_Mode"] then
                        Specific_Summon(selectedBanner, SummonSettings["Specific_Summon_Amount"])
                    elseif SummonSettings["Buy10_Mode"] then
                        Ten_Summon(selectedBanner)
                    else
                        warn("No specific summon method selected for Only Use Specified Gems mode.")
                    end
                end

            elseif summonMode == "Until Target Unit" then
                if SummonSettings["Specific_Summon_Mode"] then
                    Specific_Summon(selectedBanner, SummonSettings["Specific_Summon_Amount"])
                elseif SummonSettings["Buy10_Mode"] then
                    Ten_Summon(selectedBanner)
                else
                    warn("No specific summon method selected for Until Target Unit mode.")
                end
                -- The global connection above will catch summon results and disable auto-summon if the target unit is found.
            else
                warn("Invalid Summon Mode: " .. tostring(summonMode))
            end

            task.wait(2)  -- Wait between summoning attempts
        end

        print("Auto Summon loop ended.")
        end
    else
    end


-- Toggle for Enable_Summons:
Enable_Summon = Shop_Sections.Shop_Banner:Toggle({
    Name = "Enable Summons",
    Default = false,
    Callback = function(bool)
        --getgenv().Settings["Shop"]["Summon"]["Enable_Summons"] = bool
        --SaveS()
        
        if bool then
            task.defer(function()
                trigger_AutoSummon()
            end)
        end
    end,
}, "Enable_Summons")

if game.PlaceId == 16146832113 and game.PlaceId ~= 16277809958 then
    Shop_Sections.Shop_Gold:Header({ Name = "Gold Marchant | Shop" })
    for i, v in next, Client.PlayerGui.Windows.GoldShop.Holder.List:GetChildren() do
        for i_1, v_1 in next, v:GetChildren() do
            if v_1.Name == "Main" then 
                for i_2, v_2 in next, v_1:GetChildren() do
                    if v_2:IsA("Frame") and v_2.Name == "ItemInfo" then
                        table.insert(getgenv().Settings["Shop"]["Gold"]["ItemsAvailable"], v_2.ItemName.Text)
                    end
                end
            end
        end
    end
    table.sort(getgenv().Settings["Shop"]["Gold"]["ItemsAvailable"])
    GoldShop_Item = Shop_Sections.Shop_Gold:Dropdown({
        Name = "Item to buy",
        Multi = false,
        Required = true,
        Options = getgenv().Settings["Shop"]["Gold"]["ItemsAvailable"],
        Default = getgenv().Settings["Shop"]["Gold"]["SelectedItems"],
        Callback = function(Value)
            getgenv().GoldShop_SelectedItem = Value
            SaveS()
            
        end,
    }, "GoldShop_Item")
    GoldShop_Item:UpdateSelection(getgenv().Settings["Shop"]["Gold"]["SelectedItems"])

    Shop_Sections.Shop_Gold:SubLabel({ Text = "SHOP INFO:\nNo.. You can't buy more than the available amounts.." })
    
    GoldShop_Amount = Shop_Sections.Shop_Gold:Slider({
        Name = "Amount",
        Default = getgenv().Settings["Shop"]["Gold"]["BuyAmount"],
        Minimum = 0,
        Maximum = 50,
        DisplayMethod = "Value",
        Precision = 0,
        Callback = function(Value)
            getgenv().Settings["Shop"]["Gold"]["BuyAmount"] = Value
            SaveS()
            
        end,
    }, "GoldShop_Amount")
    GoldShop_Amount:UpdateValue(getgenv().Settings["Shop"]["Gold"]["BuyAmount"])

    Shop_Sections.Shop_Gold:Button({
        Name = "Buy Item(s)",
        Callback = function()
            if getgenv().GoldShop_SelectedItem and getgenv().GoldShop_BuyAmount then
                ReplicatedStorage.Networking.GoldShop.GoldShopEvent:FireServer("Buy", {Name = getgenv().GoldShop_SelectedItem, Amount = getgenv().GoldShop_BuyAmount})
            end
        end,
    })
end

----------------------------
--==  MISC SECTION  ==--
----------------------------
Library:SetFolder("Akora Hub//Games//Anime Vanguards")
local Settings_Sections = { Auto_Collect = Tabs.Settings:Section({ Side = "Right" }) }
--Tabs.Settings:InsertConfigSection("Left")

Claim_Collections = Settings_Sections.Auto_Collect:Toggle({
    Name = "Claim Collection",
    Default = getgenv().Settings["Settings"]["Collect"]["Collections"],
    Callback = function(bool)
        getgenv().Settings["Settings"]["Collect"]["Collections"] = bool
        SaveS()
        
        if bool and Game.PlaceId == 16146832113 then
            ReplicatedStorage.Networking.Units.CollectionEvent:FireServer("ClaimAll")
        end
    end,
}, "Claim_Collections")
Claim_Collections:UpdateState(getgenv().Settings["Settings"]["Collect"]["Collections"])

Claim_Daily = Settings_Sections.Auto_Collect:Toggle({
    Name = "Claim Daily",
    Default = getgenv().Settings["Settings"]["Collect"]["Daily"],
    Callback = function(bool)
        getgenv().Settings["Settings"]["Collect"]["Daily"] = bool
        SaveS()
        
        if bool and Game.PlaceId == 16146832113 then
            for i = 1, 7 do
                ReplicatedStorage.Networking.DailyRewardEvent:FireServer("Claim", i)
            end
        end
    end,
}, "Claim_Daily")
Claim_Daily:UpdateState(getgenv().Settings["Settings"]["Collect"]["Daily"])

Claim_EnemyIndex = Settings_Sections.Auto_Collect:Toggle({
    Name = "Claim Enemy Index",
    Default = getgenv().Settings["Settings"]["Collect"]["EnemyIndex"],
    Callback = function(bool)
        getgenv().Settings["Settings"]["Collect"]["EnemyIndex"] = bool
        SaveS()
        
        if bool and Game.PlaceId == 16146832113 then
            ReplicatedStorage.Networking.ClaimEnemyIndex:FireServer("ClaimAll")
        end
    end,
}, "Claim_EnemyIndex")
Claim_EnemyIndex:UpdateState(getgenv().Settings["Settings"]["Collect"]["EnemyIndex"])

Claim_Quests = Settings_Sections.Auto_Collect:Toggle({
    Name = "Claim Quests",
    Default = getgenv().Settings["Settings"]["Collect"]["Quests"],
    Callback = function(bool)
        getgenv().Settings["Settings"]["Collect"]["Quests"] = bool
        SaveS()
        
        if bool and Game.PlaceId == 16146832113 then
            ReplicatedStorage.Networking.Quests.ClaimQuest:FireServer("ClaimAll")
        end
    end,
}, "Claim_Quests")
Claim_Quests:UpdateState(getgenv().Settings["Settings"]["Collect"]["Quests"])

Claim_Battlepass = Settings_Sections.Auto_Collect:Toggle({
    Name = "Claim Battlepass",
    Default = getgenv().Settings["Settings"]["Collect"]["Battlepass"],
    Callback = function(bool)
        getgenv().Settings["Settings"]["Collect"]["Battlepass"] = bool
        SaveS()
        
        if bool and Game.PlaceId == 16146832113 then
            ReplicatedStorage.Networking.BattlepassEvent:FireServer("ClaimAll")
        end
    end,
}, "Claim_Battlepass")
Claim_Battlepass:UpdateState(getgenv().Settings["Settings"]["Collect"]["Battlepass"])

Window.onUnloaded(function()
    print("Unloaded!")
end)

updatePlacementVisualizer(getgenv().Settings["AutoPlay"]["Placement"]["Distance"])

Tabs.Main:Select()
--Library:LoadAutoLoadConfig()

spawn(function()
    while true do
        if getgenv().Settings["AutoPlay"]["Enabled"] then
            if game.PlaceId == 16277809958 and game.PlaceId ~= 16146832113 then
                --print("Autoplay is enabled, triggering now...")
                --trigger_Autoplay()
                trigger_AutoPlayAndUpgrade()
                --print("Autoplay finished. Waiting for reactivation...")
                repeat task.wait(1) until not getgenv().Settings["AutoPlay"]["Enabled"]
                --print("Autoplay disabled, waiting for reactivation...")
            end
        end
        task.wait(1)  -- Avoid high CPU usage
    end
end)

if game.PlaceId == 16277809958 and game.PlaceId ~= 16146832113 then
    if getgenv().Settings["Auto"]["Start"]["Enabled"] then
        task.wait(getgenv().Settings["Auto"]["Start"]["Delay"])
        ReplicatedStorage.Networking.SkipWaveEvent:FireServer("Skip")
    end
end