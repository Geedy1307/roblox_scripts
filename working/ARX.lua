local wait = task.wait

repeat wait() until game:IsLoaded()
repeat wait() until game.Players.LocalPlayer
repeat wait() until game.Players.LocalPlayer:GetAttribute("GUILoaded")

local defaultSettings = {
    AutoStart = false,
    AutoVote = false,
    AutoNext = false,
    AutoRetry = false,
    AutoUpgrade = false,
	FocusRangerStage = false,
	FocusChallenge = false,
	FocusPortal = false,
	Mode = "",
	World = "",
	Level = "",
	Difficulty = "",
	UpgradePriorities = {},
	UnitSlotStatReroll = "",
	TypeStatReroll = "",
	RankStatReroll = "",
	AutoStatReroll = false,
	UnitSlotTraitReroll = "",
	RankTraitReroll = "",
	AutoTraitReroll = false,
}
local HttpS = game:GetService("HttpService")
local FileName = 'anime_rangers_x(ID_'..game.Players.LocalPlayer.UserId..').json'
if not pcall(function() readfile(FileName) end) then writefile(FileName, HttpS:JSONEncode(defaultSettings)) end
local Settings = HttpS:JSONDecode(readfile(FileName))
function saveSettings() writefile(FileName, HttpS:JSONEncode(Settings)) end

local USERCONSOLE = false
local Version = "0.0.1"
local SubVersion = "L_Kain"

if not (rconsolecreate and rconsolesettitle) then
	USERCONSOLE = false
end

if USERCONSOLE then
	rconsolesettitle("Debugger")
	rconsolecreate()
end

function Stringify(Values)
	local Stringified = {}
	for Index, Value in next, Values do
		table.insert(Stringified, tostring(Value))
	end
	return Stringified
end

function sprint(...)
	if USERCONSOLE then
		rconsoleprint("[DEBUG] " .. table.concat(Stringify({ ... }), " "))
	else
		print("[DEBUG]", ...)
	end
end

function swarn(...)
	if USERCONSOLE then
		rconsolewarn("[DEBUG] " .. table.concat(Stringify({ ... }), " ") .. "\n")
	else
		warn("[DEBUG]", ...)
	end
end

function flen(Table)
	local Count = 0
	for _ in next, Table do
		Count += 1
	end
	return Count
end

--#region Cleanup library
local Cleaner = {
	Registry = {},
	AllowedTypes = {
		["RBXScriptConnection"] = true,
		["Instance"] = true,
		["table"] = true,
		["function"] = true,
		["thread"] = true,
	},
	CleanEvent = Instance.new("BindableEvent"),
}

function Cleaner.Register(Object)
	if not Cleaner.AllowedTypes[typeof(Object)] then
		swarn("Attempted to register an invalid object type:", typeof(Object))
		return
	end

	if Cleaner.Registry[Object] then
		swarn("Object is already registered for cleanup:", Object)
		return
	end

	Cleaner.Registry[Object] = true

	return {
		Clean = function()
			Cleaner.CleanOne(Object)
		end,
    }
end

function Cleaner.Clean()
	print("Cleaning up", flen(Cleaner.Registry), "objects.")
	for Object, _ in next, Cleaner.Registry do
		if typeof(Object) == "RBXScriptConnection" then
			Object:Disconnect()
		elseif typeof(Object) == "Instance" then
			Object:Destroy()
		elseif type(Object) == "table" then
			for Index, Value in next, Object do
				Object[Index] = nil
			end
		elseif type(Object) == "function" then
			Object()
		elseif type(Object) == "thread" then
			coroutine.close(Object)
		end

		Cleaner.Registry[Object] = nil
	end
	Cleaner.CleanEvent:Fire()
end

function Cleaner.CleanOne(Object)
	if not Cleaner.AllowedTypes[typeof(Object)] then
		swarn("Attempted to clean an invalid object type:", typeof(Object))
		return
	end

	if not Cleaner.Registry[Object] then
		swarn("Object is not registered for cleanup:", Object)
		return
	end

	if typeof(Object) == "RBXScriptConnection" then
		Object:Disconnect()
	elseif typeof(Object) == "Instance" then
		Object:Destroy()
	elseif type(Object) == "table" then
		for Index, Value in next, Object do
			Object[Index] = nil
		end
	elseif type(Object) == "function" then
		Object()
	elseif type(Object) == "thread" then
		coroutine.close(Object)
	end

	Cleaner.Registry[Object] = nil
end

function Cleaner.GetCleanEvent()
	return Cleaner.CleanEvent.Event
end

setmetatable(Cleaner, {
	__call = function(self, Object: any)
		self.Register(Object)
		return Object
	end,
})
--#endregionF

xpcall(function()
	local VirtualInputManager = game:GetService("VirtualInputManager")
    local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local Client = Players.LocalPlayer
	local playerData = ReplicatedStorage:WaitForChild("Player_Data")
	local clientData = playerData:WaitForChild(Client.Name)
    local clientChar, clientRoot
	Cleaner(Client.CharacterAdded:Connect(function(newChar)
        clientChar = newChar
        clientRoot = clientChar:WaitForChild("HumanoidRootPart")
    end))

	if Client.Character then
        clientChar = Client.Character or Client.CharacterAdded:Wait()
        clientRoot = clientChar:WaitForChild("HumanoidRootPart")
	end

	local statRankList = {"O+", "O", "O-", "SSS", "SS", "S+", "S", "S-", "A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-"}

	local function traitRanks()
		local traitRankText = {}
		local traitRankMap = {}

		for traitName, traitInfo in next, require(ReplicatedStorage.Shared.Info.Trait) do
			table.insert(traitRankMap, {Name = traitName, Chance = tonumber(traitInfo.Weight)})
		end
		
		table.sort(traitRankMap, function(a, b)
			return a.Chance < b.Chance
		end)

		for _, trait in next, traitRankMap do
			table.insert(traitRankText, trait.Name .. " - " .. trait.Chance .. "%")
		end

		return {
			traitRankText = traitRankText,
			traitRankMap = traitRankMap
		}
	end

	local function getSlotMap()
		local layoutData = clientData:WaitForChild("Data")
		return {
			Slot1 = layoutData:WaitForChild("UnitLoadout1") and layoutData.UnitLoadout1.Value or nil,
			Slot2 = layoutData:WaitForChild("UnitLoadout2") and layoutData.UnitLoadout2.Value or nil,
			Slot3 = layoutData:WaitForChild("UnitLoadout3") and layoutData.UnitLoadout3.Value or nil,
			Slot4 = layoutData:WaitForChild("UnitLoadout4") and layoutData.UnitLoadout4.Value or nil,
			Slot5 = layoutData:WaitForChild("UnitLoadout5") and layoutData.UnitLoadout5.Value or nil,
			Slot6 = layoutData:WaitForChild("UnitLoadout6") and layoutData.UnitLoadout6.Value or nil,
		}
	end

	local function dataWorlds()
		local worlds = {}
		for i,v in next, ReplicatedStorage.Shared.Info.GameWorld.World:GetChildren() do
			local data = require(v)[tostring(v)]
			
			if data.StoryAble then
				table.insert(worlds, data)
			end
		end
	
		table.sort(worlds, function(a, b)
			local aNum = a.LayoutOrder or 0
			local bNum = b.LayoutOrder or 0
			return aNum < bNum
		end)
	
		return worlds
	end

	local function remoteWorld()
        local world = nil
        for i,v in next, ReplicatedStorage.Shared.Info.GameWorld.World:GetChildren() do
			local module = require(v)
			local data = module[tostring(v)]
			if data and data.Name and data.Name == Settings.World then
                world = tostring(v)
				break
			end
        end
		
        return world
    end

	local function remoteLevel()
        local level = nil
		local world = remoteWorld(Settings.World)

        if world ~= '' and world ~= nil then
            for i,v in next, require(ReplicatedStorage.Shared.Info.GameWorld.Levels[world])[world] do
				if v.Name == string.match(Settings.Level, "%- (.+)") then
					level = tostring(i)
					break
				end
            end
        end

        return level
    end

	local function extractNum(str)
		local chapterNum = string.match(str, "Chapter(%d+)")
		local rangerNum = string.match(str, "RangerStage(%d+)")
		return tonumber(chapterNum or rangerNum or math.huge)
	end

	local function getNextStage()
		local nextChapter = nil
		local nextRangerStage = nil

		for _, v in next, ReplicatedStorage.Shared.Info.GameWorld.Levels:GetChildren() do
			local data = require(v)[tostring(v)]

			local chapterKeys = {}
			local rangerKeys = {}

			for key in next, data do
				if string.find(key, "RangerStage") then
					table.insert(rangerKeys, key)
				elseif string.find(key, "Chapter") then
					table.insert(chapterKeys, key)
				end
			end

			table.sort(chapterKeys, function(a, b)
				return extractNum(a) < extractNum(b)
			end)

			table.sort(rangerKeys, function(a, b)
				return extractNum(a) < extractNum(b)
			end)

			-- for _, key in next, chapterKeys do
			-- 	local value = data[key]
			-- 	local canAccess = value.Requirements and value.Requirements.Required_Levels and clientData.ChapterLevels:FindFirstChild(value.Requirements.Required_Levels)
			-- 	local completed = clientData.ChapterLevels:FindFirstChild(key)

			-- 	if canAccess and not completed then
			-- 		nextChapter = {
			-- 			World = value.World,
			-- 			Level = value.Wave
			-- 		}
			-- 		break
			-- 	end
			-- end

			for _, key in next, rangerKeys do
				local value = data[key]
				local canAccess = value.Requirements and value.Requirements.Required_Levels and clientData.ChapterLevels:FindFirstChild(value.Requirements.Required_Levels)
				local onCooldown = clientData.RangerStage:FindFirstChild(key)

				if canAccess and not onCooldown then
					nextRangerStage = {
						World = value.World,
						Level = value.Wave
					}
					break
				end
			end
		end

		return {
			nextChapter = nextChapter,
			nextRangerStage = nextRangerStage
		}
	end

	local function getPortal()
		for i,v in next, clientData.Items:GetChildren() do
			if v.Name:find("Portal") and v:FindFirstChild("Amount") and v.Amount.Value > 0 then
				return v
			end
		end

		return nil
	end

	local function startGame(mode, world, chapter, difficulty)
		if mode == "Challenge" then
			ReplicatedStorage.Remote.Server.PlayRoom.Event:FireServer("Create", {CreateChallengeRoom = true})
		else
			ReplicatedStorage.Remote.Server.PlayRoom.Event:FireServer("Create")
			ReplicatedStorage.Remote.Server.PlayRoom.Event:FireServer("Change-Mode", {Mode = mode})
			ReplicatedStorage.Remote.Server.PlayRoom.Event:FireServer("Change-World", {World = world})
			ReplicatedStorage.Remote.Server.PlayRoom.Event:FireServer("Change-Chapter", {Chapter = chapter})
			ReplicatedStorage.Remote.Server.PlayRoom.Event:FireServer("Change-Difficulty", {Difficulty = difficulty})
			ReplicatedStorage.Remote.Server.PlayRoom.Event:FireServer("Submit")
		end
		
		wait(1)
		ReplicatedStorage.Remote.Server.PlayRoom.Event:FireServer("Start")
	end

	local function unitUpgrade(targetTag)
		for _, unit in next, Client.UnitsFolder:GetChildren() do
			if unit:FindFirstChild("Tag") and unit.Tag.Value == targetTag then
				return unit
			end
		end

		return nil
	end

	local function unitCollection(targetTag)
		for _, unit in next, clientData.Collection:GetChildren() do
			if unit:FindFirstChild("Tag") and unit.Tag.Value == targetTag then
				return unit
			end
		end

		return nil
	end

	local function statRankIndex(rank)
		for i, v in next, statRankList do
			if v == rank then
				return i
			end
		end
		return math.huge
	end

	local function traitRankPercent(trait)
		for i,v in next, traitRanks()["traitRankMap"] do
			if v.Name == trait then
				return v.Chance
			end
		end
		return math.huge
	end

    local loopStartGame = coroutine.create(function()
        while wait(1) do
            if Settings.AutoStart then
				local nextStage = getNextStage()
				if Settings.FocusRangerStage and nextStage and nextStage.nextRangerStage then
					local rangerStage = nextStage.nextRangerStage
					sprint("Teleport to ranger stage World: "..rangerStage.World.." | Level: "..rangerStage.Level)
					startGame("Ranger Stage", rangerStage.World, rangerStage.Level, "Nightmare")
				else
					local portal = getPortal()
					if Settings.FocusPortal and portal then
						sprint("Teleport to portal: "..portal.Name)
						ReplicatedStorage.Remote.Server.Lobby.ItemUse:FireServer(portal)
						wait(1)
						ReplicatedStorage.Remote.Server.Lobby.PortalEvent:FireServer("Start")
					else
						if Settings.FocusChallenge then
							sprint("Teleport to challenge")
							startGame("Challenge")
						else
							local mWorld = remoteWorld()
							local mLevel = remoteLevel()
							sprint("Teleport to story World: "..mWorld.." | Level: "..mLevel)
							startGame("Story", mWorld, mLevel, Settings.Difficulty)
						end
					end
				end
            end
        end
    end)

	local loopStartVote = coroutine.create(function()
		while wait(1) do
			if Settings.AutoVote and Client.PlayerGui and Client.PlayerGui:FindFirstChild("HUD") and Client.PlayerGui.HUD.InGame.VotePlaying.Visible then
				ReplicatedStorage.Remote.Server.OnGame.Voting.VotePlaying:FireServer()
			end
		end
	end)

	local loopAutoUpgrade = coroutine.create(function()
		if Client:FindFirstChild("UnitsFolder") then
			while wait(0.1) do
				if Settings.AutoUpgrade and #Settings.UpgradePriorities > 0 then
					local slotsMap = getSlotMap()
					if slotsMap and #workspace.Agent.Agent:GetChildren() > 0 then
						for _, slot in next, Settings.UpgradePriorities do
							local targetTag = slotsMap[slot]
							if not targetTag then continue end

							local unit = unitUpgrade(targetTag)
							if unit and unit:FindFirstChild("Upgrade_Folder") and unit.Upgrade_Folder:FindFirstChild("Level") then
								local unitLevel = unit.Upgrade_Folder.Level.Value
								local unitData = require(ReplicatedStorage.Shared.GetData.GetUnitStats)(tostring(unit))
								
								if unitLevel <= #unitData.Upgrade then
									local upgradeCost = unitData.Upgrade[unitLevel].Cost
									local clientYen = Client:FindFirstChild("Yen") and Client.Yen.Value or 0
									if clientYen >= upgradeCost then
										-- sprint(tostring(unit) .. " - " .. unitLevel .. " - " .. clientYen .. " - " .. upgradeCost)
										ReplicatedStorage.Remote.Server.Units.Upgrade:FireServer(unit)
									end
									break
								end
							end
						end
					end
				end
			end
		end
	end)

	local loopAutoStatReroll = coroutine.create(function()
		while wait(0.1) do
			if Settings.AutoStatReroll then
				local slotsMap = getSlotMap()
				if slotsMap and slotsMap[Settings.UnitSlotStatReroll] then
					local targetTag = slotsMap[Settings.UnitSlotStatReroll]
					local unit = unitCollection(targetTag)
					if unit then
						local unitStats = {
							Damage = unit.DamagePotential.Value,
							Health = unit.HealthPotential.Value,
							Speed = unit.SpeedPotential.Value,
							Range = unit.RangePotential.Value,
							AttackCooldown = unit.AttackCooldownPotential.Value
						}
						local currentRank = unitStats[Settings.TypeStatReroll]

						if statRankIndex(currentRank) > statRankIndex(Settings.RankStatReroll) then
							ReplicatedStorage.Remote.Server.Gambling.RerollPotential:FireServer(Settings.TypeStatReroll, unit.Tag.Value, "Selective")
						end
					end
				end
			end
		end
	end)

	local loopAutoTraitReroll = coroutine.create(function()
		while wait(0.1) do
			if Settings.AutoTraitReroll then
				local slotsMap = getSlotMap()
				if slotsMap and slotsMap[Settings.UnitSlotTraitReroll] then
					local targetTag = slotsMap[Settings.UnitSlotTraitReroll]
					local unit = unitCollection(targetTag)
					if unit then
						local currentTrait = unit.PrimaryTrait.Value
						local currentRank = traitRankPercent(currentTrait)
						local targetRank = traitRankPercent(Settings.RankTraitReroll)
						
						if currentRank > targetRank then
							ReplicatedStorage.Remote.Server.Gambling.RerollTrait:FireServer(unit, "Reroll", "Main", "Shards")
						end
					end
				end
			end
		end
	end)

    if not workspace:FindFirstChild("WayPoint") then --[[ Lobby *]]
		Cleaner(loopStartGame)
		Cleaner(ReplicatedStorage.Remote.Server.PlayRoom.Event.OnClientEvent:Connect(function(player, action)
			if action == "Start" then
				coroutine.close(loopStartGame)
			end
		end))
		coroutine.resume(loopStartGame)

		Cleaner(loopAutoStatReroll)
		coroutine.resume(loopAutoStatReroll)

		Cleaner(loopAutoTraitReroll)
		coroutine.resume(loopAutoTraitReroll)
    else
		local countTryVote = 0
		Cleaner(ReplicatedStorage.Remote.Server.OnGame.Voting.VotePlaying.OnClientEvent:Connect(function()
			countTryVote += 1
			if countTryVote == 5 then
				coroutine.close(loopStartVote)
			end

			if not clientData.Data.AutoPlay.Value then
				ReplicatedStorage.Remote.Server.Units.AutoPlay:FireServer()
			end
		end))

		Cleaner(ReplicatedStorage.Remote.Client.UI.GameEndedUI.OnClientEvent:Connect(function(eventName, result)
			if eventName == "GameEnded_TextAnimation" then
				repeat wait() until Client.PlayerGui:FindFirstChild("GameEndedAnimationUI")

				local function getScreenCenter()
					local viewportSize = workspace.CurrentCamera.ViewportSize
					return viewportSize.X * 0.1, viewportSize.Y * 0.8
				end

				local function autoClick()
					local x, y = getScreenCenter()
					VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
					VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
				end

				for i=1,10 do
					autoClick()
					wait(0.5)
				end

				local canVoteNext = ReplicatedStorage.Values.Game.VoteNext.VoteEnabled.Value
				local canVoteRetry = ReplicatedStorage.Values.Game.VoteRetry.VoteEnabled.Value

				if result == "Won" then
					sprint("Client won")
				elseif result == "Defeat" then
					sprint("Client is defeated")
				end

				local nextStage = getNextStage()
				if Settings.FocusRangerStage and nextStage.nextRangerStage then
					local rangerStage = nextStage.nextRangerStage
					local currentWorld = ReplicatedStorage.Values.Game.World.Value
					local currentMode = ReplicatedStorage.Values.Game.Gamemode.Value

					if currentWorld == rangerStage.World and string.find(currentMode, "Ranger") then
						sprint("Next ranger stage level World: "..rangerStage.World.." | Level: "..rangerStage.Level)
						ReplicatedStorage.Remote.Server.OnGame.Voting.VoteNext:FireServer()
					else
						sprint("Teleport to ranger stage World: "..rangerStage.World.." | Level: "..rangerStage.Level)
						startGame("Ranger Stage", rangerStage.World, rangerStage.Level, "Nightmare")
					end
				else
					local portal = getPortal()
					if Settings.FocusPortal and portal then
						if canVoteRetry then
							sprint("Retry portal")
							ReplicatedStorage.Remote.Server.OnGame.Voting.VoteRetry:FireServer()
						else
							sprint("Teleport to portal: "..portal.Name)
							ReplicatedStorage.Remote.Server.Lobby.ItemUse:FireServer(portal)
							wait(1)
							ReplicatedStorage.Remote.Server.Lobby.PortalEvent:FireServer("Start")
						end
					else
						if Settings.FocusChallenge then
							if canVoteRetry then
								sprint("Retry challenge")
								ReplicatedStorage.Remote.Server.OnGame.Voting.VoteRetry:FireServer()
							else
								sprint("Teleport to challenge")
								startGame("Challenge")
							end
						else
							if Settings.AutoNext and canVoteNext then
								sprint("Next story stage same world")
								ReplicatedStorage.Remote.Server.OnGame.Voting.VoteNext:FireServer()
							else
								if Settings.AutoRetry and canVoteRetry then
									sprint("Retry story stage")
									ReplicatedStorage.Remote.Server.OnGame.Voting.VoteRetry:FireServer()
								else
									local mWorld = remoteWorld()
									local mLevel = remoteLevel()
									sprint("Teleport to story World: "..mWorld.." | Level: "..mLevel)
									startGame("Story", mWorld, mLevel, Settings.Difficulty)
								end
							end
						end
					end
				end

				-- wait(1)
				-- firesignal(ReplicatedStorage.Remote.Client.UI.GameEndedUI.OnClientEvent,  "Close - EndedScreen")
			end
		end))

		Cleaner(loopStartVote)
		coroutine.resume(loopStartVote)

		Cleaner(loopAutoUpgrade)
		coroutine.resume(loopAutoUpgrade)
    end

    --[[ UI *]]
    local worlds, levels, difficulties, labelPriority, upgradePriorities, unitSlotStatReroll
	local priorityOrder = {}
	local selectedSlot = {}
	local loadoutSlots = {} do
		for i=1,6 do
			table.insert(loadoutSlots, "Slot"..i)
		end
	end
	local traitRankDropdown = {} do
		for i,v in next, traitRanks()["traitRankMap"] do
			table.insert(traitRankDropdown, v.Name)
		end
	end

	if Settings.UpgradePriorities and typeof(Settings.UpgradePriorities) == "table" then
		for _, slot in next, Settings.UpgradePriorities do
			table.insert(priorityOrder, slot)
			selectedSlot[slot] = true
		end
	end

	local function updateLabelPriority()
		if #priorityOrder == 0 then
			labelPriority:SetText("No priority slot selected")
		else
			local display = ""
			for i, slot in next, priorityOrder do
				display = display .. i .. " -> " .. slot .. "\n"
			end
			labelPriority:SetText("Current upgrade priority:\n" .. display)
		end
	end

	local function updateDropdownPriorities()
		local available = {}
		local disabled = {}

		for i, slot in next, loadoutSlots do
			if selectedSlot[slot] then
				table.insert(disabled, slot)
			else
				table.insert(available, slot)
			end
		end

		upgradePriorities:SetValues(available)
		upgradePriorities:SetDisabledValues(disabled)

		updateLabelPriority()
	end

	local function dropdownWorlds()
		local worlds = {}
		local blacklist = {}

		for i,v in next, dataWorlds() do
			if v.Requirements and v.Requirements.Required_Levels and not clientData.ChapterLevels:FindFirstChild(v.Requirements.Required_Levels) then
				blacklist[#blacklist+1] = v.Name
			end

			worlds[#worlds+1] = v.Name
		end

		return {
			validLevels = worlds,
			invalidLevels = blacklist,
		}
	end

    local function dropdownLevels()
        local levels = {}
        local blacklist = {}
		local world = remoteWorld(Settings.World)

        if world ~= '' and world ~= nil then
            for i,v in next, require(ReplicatedStorage.Shared.Info.GameWorld.Levels[world])[world] do
				if string.find(i, "Chapter") then
					if v.Requirements and v.Requirements.Required_Levels and not clientData.ChapterLevels:FindFirstChild(v.Requirements.Required_Levels) then
						table.insert(blacklist, `{v.World} - {v.Name}`)
					else
						table.insert(levels, `{v.World} - {v.Name}`)
					end
				end
            end
        end

		table.sort(levels, function(a, b)
			local aNum = tonumber(string.match(a, "%d+")) or 0
			local bNum = tonumber(string.match(b, "%d+")) or 0
			return aNum < bNum
		end)

		table.sort(blacklist, function(a, b)
			local aNum = tonumber(string.match(a, "%d+")) or 0
			local bNum = tonumber(string.match(b, "%d+")) or 0
			return aNum < bNum
		end)

		return {
			validLevels = levels,
			invalidLevels = blacklist,
		}
    end

	local function updateDropdownUnitSlotStatReroll()
		Settings.UnitSlotStatReroll = ""
		saveSettings()

		unitSlotStatReroll:SetValue(nil)
		if Settings.RankStatReroll ~= '' and Settings.TypeStatReroll ~= '' then
			unitSlotStatReroll:SetDisabled(false)
		else
			unitSlotStatReroll:SetDisabled(true)
		end
	end

    local Repository = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
	local Library = loadstring(game:HttpGet(Repository .. "Library.lua"))()
    Cleaner.GetCleanEvent():Connect(function()
		Library:Unload()
	end)

	local Window = Library:CreateWindow({
		Title = "Anime Rangers X",
		Center = true,
		AutoShow = true,
        ShowCustomCursor = false,
        ToggleKeybind = Enum.KeyCode.RightControl,
		Footer = "Version: " .. Version .. " | " .. SubVersion,
		Size = UDim2.fromOffset(700, 400),
	})

	Library:Notify("Toggle UI is RightControl", 5)

	local Tabs = {
		Main = Window:AddTab("Main", "house"),
		Utilities = Window:AddTab("Utilities", "accessibility"),
		UISettings = Window:AddTab("UI Settings", "settings"),
	}

	local Groups = {
		Map = Tabs.Main:AddLeftGroupbox("Map"),
		PriorityFarm = Tabs.Main:AddLeftGroupbox("Priority Farm"),
		Auto = Tabs.Main:AddRightGroupbox("Auto"),
		UpgradeUnits = Tabs.Main:AddRightGroupbox("Upgrade Units"),

		StatReroll = Tabs.Utilities:AddLeftGroupbox("Stat Reroll"),
		TraitReroll = Tabs.Utilities:AddRightGroupbox("Trait Reroll"),
	}

	worlds = Groups.Map:AddDropdown("Worlds", {
		Text = "Worlds",
		Default = Settings.World,
		Values = dropdownWorlds()['validLevels'],
		DisabledValues = dropdownWorlds()['invalidLevels'],
		Tooltip = "Select a map",
		Searchable = true,
		Callback = function(value)
			Settings.World = value
			Settings.Level = ""
			saveSettings()

			levels:SetValues(dropdownLevels()['validLevels'])
			levels:SetDisabledValues(dropdownLevels()['invalidLevels'])
			levels:SetValue(nil)
		end,
	})
	
	levels = Groups.Map:AddDropdown("Levels", {
		Text = "Levels",
		Default = Settings.Level,
		Values = dropdownLevels()['validLevels'],
		DisabledValues = dropdownLevels()['invalidLevels'],
		Tooltip = "Select a world first to load levels",
		Searchable = true,
		Callback = function(value)
			Settings.Level = value
			saveSettings()
		end,
	})

	difficulties = Groups.Map:AddDropdown("Difficulties", {
		Text = "Difficulties",
		Default = Settings.Difficulty,
		Values = {"Normal", "Hard", "Nightmare"},
		Tooltip = "Select a difficulty",
		Searchable = true,
		Callback = function(value)
			Settings.Difficulty = value
			saveSettings()
		end,
	})

	Groups.PriorityFarm:AddToggle("FocusRangerStage", {
		Text = "Focus Ranger Stages",
		Default = Settings.FocusRangerStage,
		Tooltip = "Clear all the possible ranger stages first then farm selected",
		Callback = function(state)
			Settings.FocusRangerStage = state
			saveSettings()
		end,
	})

	Groups.PriorityFarm:AddToggle("FocusPortal", {
		Text = "Focus Portal",
		Default = Settings.FocusPortal,
		Tooltip = "Just farm portal",
		Callback = function(state)
			Settings.FocusPortal = state
			saveSettings()
		end,
	})

	Groups.PriorityFarm:AddToggle("FocusChallenge", {
		Text = "Focus Challenge",
		Default = Settings.FocusChallenge,
		Tooltip = "Just farm challenge",
		Callback = function(state)
			Settings.FocusChallenge = state
			saveSettings()
		end,
	})

	Groups.Auto:AddToggle("AutoVote", {
		Text = "Vote Start",
		Default = Settings.AutoVote,
		Tooltip = "Vote start game",
		Callback = function(state)
			Settings.AutoVote = state
			saveSettings()
		end,
	})

	Groups.Auto:AddToggle("AutoNext", {
		Text = "Next Stage",
		Default = Settings.AutoNext,
		Tooltip = "To next stage",
		Callback = function(state)
			Settings.AutoNext = state
			saveSettings()
		end,
	})

	Groups.Auto:AddToggle("AutoRetry", {
		Text = "Retry",
		Default = Settings.AutoRetry,
		Tooltip = "Retry stage",
		Callback = function(state)
			Settings.AutoRetry = state
			saveSettings()
		end,
	})

	Groups.Auto:AddToggle("AutoStart", {
		Text = "Start Game",
		Default = Settings.AutoStart,
		Tooltip = "Start the game",
		Callback = function(state)
			Settings.AutoStart = state
			saveSettings()
		end,
	})

	labelPriority = Groups.UpgradeUnits:AddLabel({
		Text = "No priority slot selected",
		DoesWrap = true
	})

	upgradePriorities = Groups.UpgradeUnits:AddDropdown("upgradePriorities", {
		Values = loadoutSlots,
		Text = "Select Priority Upgrade",
		Tooltip = "Select slot from 1 to 6",
		Searchable = true,
		Callback = function(value)
			if value and not selectedSlot[value] then
				table.insert(priorityOrder, value)
				selectedSlot[value] = true
				Settings.UpgradePriorities = priorityOrder
				saveSettings()
				updateDropdownPriorities()
				upgradePriorities:SetValue(nil)
			end
		end
	})
	updateDropdownPriorities()

	Groups.UpgradeUnits:AddButton({
		Text = "Reset Priorities",
		Func = function()
			priorityOrder = {}
			selectedSlot = {}
			Settings.UpgradePriorities = {}
			saveSettings()
			updateDropdownPriorities()
		end,
	})

	Groups.UpgradeUnits:AddToggle("AutoUpgrade", {
		Text = "Auto Upgrade Units",
		Default = Settings.AutoUpgrade,
		Tooltip = "Auto upgrade units based on priority",
		Callback = function(state)
			Settings.AutoUpgrade = state
			saveSettings()
		end,
	})

	Groups.StatReroll:AddDropdown("TypeStatReroll", {
		Values = {"Damage", "Health", "Speed", "Range", "AttackCooldown"},
		Default = Settings.TypeStatReroll,
		Text = "Select Focus Stat",
		Tooltip = "Select a stat to focus on rerolling",
		Searchable = true,
		Callback = function(value)
			Settings.TypeStatReroll = value
			saveSettings()
			updateDropdownUnitSlotStatReroll()
		end
	})

	Groups.StatReroll:AddDropdown("RankStatReroll", {
		Values = statRankList,
		Default = Settings.RankStatReroll,
		Text = "Select Lowest Rank",
		Tooltip = "Select the lowest rank you want to roll, if there are ranks above selected rank then it will stop",
		Searchable = true,
		Callback = function(value)
			Settings.RankStatReroll = value
			saveSettings()
			updateDropdownUnitSlotStatReroll()
		end
	})

	unitSlotStatReroll = Groups.StatReroll:AddDropdown("UnitSlotStatReroll", {
		Values = loadoutSlots,
		Default = Settings.UnitSlotStatReroll,
		Text = "Select Unit Slot",
		Tooltip = "Select an unit slot to reroll",
		Searchable = true,
		Callback = function(value)
			Settings.UnitSlotStatReroll = value
			saveSettings()
		end
	})
	updateDropdownUnitSlotStatReroll()

	Groups.StatReroll:AddToggle("AutoStatReroll", {
		Text = "Start Stat Reroll",
		Default = Settings.AutoStatReroll,
		Tooltip = "Auto stat reroll",
		Callback = function(state)
			Settings.AutoStatReroll = state
			saveSettings()
		end,
	})

	Groups.TraitReroll:AddLabel({
		Text = table.concat(traitRanks()["traitRankText"], "\n"),
		DoesWrap = true
	})

	Groups.TraitReroll:AddDropdown("RankTraitReroll", {
		Values = traitRankDropdown,
		Default = Settings.RankTraitReroll,
		Text = "Select Desired Trait",
		Tooltip = "Select the desired trait you want to roll, if there are traits better than selected trait then it will stop",
		Searchable = true,
		Callback = function(value)
			Settings.RankTraitReroll = value
			saveSettings()
		end
	})

	Groups.TraitReroll:AddDropdown("UnitSlotTraitReroll", {
		Values = loadoutSlots,
		Default = Settings.UnitSlotTraitReroll,
		Text = "Select Unit Slot",
		Tooltip = "Select an unit slot to reroll",
		Searchable = true,
		Callback = function(value)
			Settings.UnitSlotTraitReroll = value
			saveSettings()
		end
	})

	Groups.TraitReroll:AddToggle("AutoTraitReroll", {
		Text = "Start Trait Reroll",
		Default = Settings.AutoTraitReroll,
		Tooltip = "Auto trait reroll",
		Callback = function(state)
			Settings.AutoTraitReroll = state
			saveSettings()
		end,
	})

	local MenuGroup = Tabs.UISettings:AddLeftGroupbox("Menu")
	MenuGroup:AddButton("Unload", function()
		sprint("Cleaning up.")
		Cleaner.Clean()
		rconsoledestroy()
	end)
end, function(Error)
	warn(debug.traceback("[Error]: " .. tostring(Error), 2))
end)