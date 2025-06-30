local wait = task.wait

repeat wait() until game:IsLoaded()
repeat wait() until workspace:FindFirstChild('CurrentRoom')
repeat wait() until workspace.CurrentRoom:FindFirstChildOfClass("Model")

local defaultSettings = {
    FullBright = false,
    AutoSkillCheck = false,
    ESPNeededModels = false,
    AutoFarm = false,
    SpeedBoost = 20,
    KeySpeedBoost = "Q",
    KeyMacroBassie = "Z",
}
local HttpS = game:GetService("HttpService")
local FileName = 'dandys_world(ID_'..game.Players.LocalPlayer.UserId..').json'
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
	__call = function(self, Object)
		self.Register(Object)
		return Object
	end,
})
--#endregionF

xpcall(function()
	local Lighting = game:GetService("Lighting")
	local UserInputService = game:GetService("UserInputService")
	local VirtualInputManager = game:GetService("VirtualInputManager");
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local Client = Players.LocalPlayer
	local ScreenGui = Client.PlayerGui:WaitForChild("ScreenGui")
	local Menu = ScreenGui:WaitForChild("Menu")
	local SkillCheckFrame = Menu:WaitForChild("SkillCheckFrame")
	local Marker = SkillCheckFrame:WaitForChild("Marker")
	local GoldArea = SkillCheckFrame:WaitForChild("GoldArea")

	local Character = Client.Character or Client.CharacterAdded:Wait()
	local clientStats = Character:WaitForChild('Stats')
	Client.CharacterAdded:Connect(function(newChar)
		Character = newChar
		clientRoot = Character:WaitForChild("HumanoidRootPart")
		clientHumanoid = Character:WaitForChild("Humanoid")
		clientInventory = Character:WaitForChild("Inventory")
	end)
	clientRoot = Character:WaitForChild("HumanoidRootPart")
	clientHumanoid = Character:WaitForChild("Humanoid")
	clientInventory = Character:WaitForChild("Inventory")

	Client.CameraMaxZoomDistance = 200

	local VirtualUser = game:service("VirtualUser")
	game:service("Players").LocalPlayer.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)

	local function interactPrompt(model)
		if not model then return end

		for _,prompt in next, model:GetDescendants() do
			if prompt:IsA("ProximityPrompt") then
				if prompt.HoldDuration == 0 then
					prompt:InputHoldBegin()
					prompt:InputHoldEnd()
				else
					prompt:InputHoldBegin()
					wait(prompt.HoldDuration)
					prompt:InputHoldEnd()
				end
				break
			end
		end
	end

	--[[ Full Bright ]]
	local oldLighting = {
		Brightness = Lighting.Brightness,
		FogEnd = Lighting.FogEnd,
		GlobalShadows = Lighting.GlobalShadows,
		OutdoorAmbient = Lighting.OutdoorAmbient,
	}

	local function ApplyFullBright()
		Lighting.Brightness = 2
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	end

	local function ResetFullBright()
		Lighting.Brightness = oldLighting.Brightness
		Lighting.FogEnd = oldLighting.FogEnd
		Lighting.GlobalShadows = oldLighting.GlobalShadows
		Lighting.OutdoorAmbient = oldLighting.OutdoorAmbient
	end

	--[[ Bassie Macro ]]
	local function collectClosestItems()
		local currentRoom = workspace:FindFirstChild("CurrentRoom")
		if not currentRoom then return end
		
		local model = currentRoom:FindFirstChildOfClass("Model")
		if not model then return end

		for _, folder in next, model:GetChildren() do
			if folder:IsA("Folder") and folder.Name == "Items" then
				for _, item in next, folder:GetChildren() do
					if item:IsA("Model") and item.PrimaryPart then
						if (clientRoot.Position - item.PrimaryPart.Position).magnitude <= 10 then
							interactPrompt(item)
						end
					end
				end
			end
		end
	end

	local function bassieMacro()
		ReplicatedStorage.Events.AbilityEvent:InvokeServer(Character, clientRoot.CFrame, false)
		wait()
		ReplicatedStorage.Events.ItemEvent:InvokeServer(Character, clientInventory.Slot1)
		wait(.1)
		collectClosestItems()
	end

	local TOLERANCE = 10

	local function isWithinGoldArea(marker, goldArea)
		local pos, size = goldArea.AbsolutePosition, goldArea.AbsoluteSize
		local markerX = marker.AbsolutePosition.X
		return markerX >= pos.X and markerX <= pos.X + size.X + TOLERANCE
	end

	local function tryAutoSkillCheck()
		if SkillCheckFrame.Visible and Settings.AutoSkillCheck then
			local marker = SkillCheckFrame:WaitForChild("Marker")
			local goldArea = SkillCheckFrame:WaitForChild("GoldArea")
			if marker and goldArea and isWithinGoldArea(marker, goldArea) then
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
			end
		end
	end

	local function onRelevantChange(property)
		if property == "Visible" or property == "AbsolutePosition" or property == "AbsoluteSize" then
			tryAutoSkillCheck()
		end
	end

	local function bindChanges(instance)
		instance.Changed:Connect(onRelevantChange)
	end

	bindChanges(SkillCheckFrame)
	bindChanges(SkillCheckFrame:WaitForChild("Marker"))
	bindChanges(SkillCheckFrame:WaitForChild("GoldArea"))

	--[[ ESP ]]
	local function ApplyESP(target,fillcolor)
		if not target:FindFirstChild("TargetESP") then
			local highlight = Instance.new("Highlight", target)
			highlight.Name = "TargetESP"
			highlight.Archivable = true
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Ensures highlight is always visible
			highlight.Enabled = true
			highlight.FillColor = fillcolor
			highlight.OutlineColor = Color3.fromRGB(255,255,255) -- Set outline color to white
			highlight.FillTransparency = 0.5 -- Set fill transparency
			highlight.OutlineTransparency = 0 -- No transparency on the outline
		end
	end

	local function ApplyImportantModelESP()
		local currentRoom = workspace:FindFirstChild("CurrentRoom")
		if not currentRoom then return end
		
		local model = currentRoom:FindFirstChildOfClass("Model")
		if not model then return end

		local usefulItems = {'Bandage','HealthKit','ChocolateBox','Valve','JumperCable','EjectButton','Instructions','SmokeBomb'}
		
		for _, folder in next, model:GetChildren() do
			if folder:IsA("Folder") and (folder.Name == "Monsters" or folder.Name == "Generators" or folder.Name == "Items") then
				for _, child in next, folder:GetChildren() do
					if child:IsA("Model") then
						local highlight = child:FindFirstChild("TargetESP")
						if Settings.ESPNeededModels and not highlight then
							if child.Name == 'Generator' then
								ApplyESP(child, Color3.fromRGB(57,255,20))
							elseif table.find(usefulItems, child.Name) then
								ApplyESP(child, Color3.fromRGB(0,255,255))
							elseif child:FindFirstChild("HumanoidRootPart") then
								ApplyESP(child, Color3.fromRGB(255,25,25))
							end
						elseif not Settings.ESPNeededModels and highlight then
							highlight:Destroy()
						end
					end
				end
			end
		end
	end

	--[[ AutoFarm ]]
	local function BackToElevator()
		if workspace:FindFirstChild("BaseplateTrigger") then
			firetouchinterest(clientRoot, workspace.BaseplateTrigger, 0)
			wait(.1)
			firetouchinterest(clientRoot, workspace.BaseplateTrigger, 1)
		end
	end

	local function SpecialAlerts()
		local currentRoom = workspace:FindFirstChild("CurrentRoom")
		if not currentRoom then return false end
		
		local model = currentRoom:FindFirstChildOfClass("Model")
		if not model then return false end

		local danger = nil
		
		for _, folder in next, model:GetChildren() do
			if folder:IsA("Folder") and folder.Name == "FreeArea" then
				for _, object in next, folder:GetChildren() do
					if object.Name == "SproutTendril" then
						danger = object
					end
				end
			end
		end
		return danger
	end

	local function MonstersAlert()
		local currentRoom = workspace:FindFirstChild("CurrentRoom")
		if not currentRoom then return false end
		
		local model = currentRoom:FindFirstChildOfClass("Model")
		if not model then return false end
		
		for _, folder in next, model:GetChildren() do
			if folder:IsA("Folder") and folder.Name == "Monsters" then
				for _, monster in next, folder:GetChildren() do
					if monster:FindFirstChild("ChasingValue") and monster.ChasingValue.Value == Character then
						return true
					end
				end
			end
		end
		return false
	end

	local function MonstersClose(distance)
		distance = distance or 30
		local currentRoom = workspace:FindFirstChild("CurrentRoom")
		if not currentRoom then return false end
		
		local model = currentRoom:FindFirstChildOfClass("Model")
		if not model then return false end
		
		local blockList = {"RazzleDazzleMonster", "RodgerMonster"}
		for _, folder in next, model:GetChildren() do
			if folder:IsA("Folder") and folder.Name == "Monsters" then
				for _, monster in next, folder:GetChildren() do
					if monster:IsA("Model") and monster.PrimaryPart and not table.find(blockList, monster.Name) then
						if (clientRoot.Position - monster.PrimaryPart.Position).Magnitude <= distance then
							return true
						end
					end
				end
			end
		end
		return false
	end

	local function OneTimeLerpTo(target)
		if not clientRoot then return end

		local distance = (clientRoot.Position - target.Position).magnitude
		local speedFactor = (60*wait())
		local estimatedTime = speedFactor / distance
		local adjustedLerpAlpha = math.min(estimatedTime, 1)

		-- Create or reuse BodyPosition for anti-gravity
		if not clientRoot:FindFirstChild("AntiGravityLock") then
			bodyPosition = Instance.new("BodyPosition")
			bodyPosition.Name = "AntiGravityLock"
			bodyPosition.MaxForce = Vector3.new(0,math.huge,0)
			bodyPosition.P = 20000
			bodyPosition.D = 1500
			bodyPosition.Parent = clientRoot
		end

		if distance <= 20 and not MonstersAlert() and not MonstersClose(50) then
			clientRoot.CFrame = clientRoot.CFrame:lerp(CFrame.new(target.Position), adjustedLerpAlpha)
			bodyPosition.Position = Vector3.new(clientRoot.Position.X, target.Position.Y, clientRoot.Position.Z)
		else
			if (MonstersAlert() and MonstersClose(20)) or (MonstersAlert() and distance <= 10) then
				clientRoot.CFrame = CFrame.new(clientRoot.Position.X, (target.Position.Y - 2.25), clientRoot.Position.Z)
			end
			clientRoot.CFrame = clientRoot.CFrame:lerp(CFrame.new(target.Position.X, (target.Position.Y - 2.25), target.Position.Z), adjustedLerpAlpha)
			bodyPosition.Position = Vector3.new(clientRoot.Position.X, target.Position.Y - 2.25, clientRoot.Position.Z)
		end
	end

	local function IncompleteGenerator()
		local currentRoom = workspace:FindFirstChild("CurrentRoom")
		if not currentRoom then return false end
		
		local model = currentRoom:FindFirstChildOfClass("Model")
		if not model then return false end
		
		local nearest = nil
		local nearestDistance = math.huge

		for _, folder in next, model:GetChildren() do
			if folder:IsA("Folder") and folder.Name == "Generators" then
				for _, gen in next, folder:GetChildren() do
					if gen:FindFirstChild('TeleportPositions') and gen.TeleportPositions:FindFirstChild('TeleportPosition') and gen:FindFirstChild('Prompt') then
						local stats = gen:FindFirstChild('Stats')
						local notCompleted = stats and stats:FindFirstChild('Completed') and not stats.Completed.Value
						local notBeingUsed = stats and stats:FindFirstChild('ActivePlayer') and not stats.ActivePlayer.Value
						if notCompleted and notBeingUsed then
							local distance = (clientRoot.Position - gen.TeleportPositions.TeleportPosition.Position).magnitude
							if distance < nearestDistance then
								nearest = gen
								nearestDistance = distance
							end
						end
					end
				end
			end
		end
			
		return nearest
	end

	local function GetBestCard()
		local bestCards = {'Machine','Heal','Heal2'}
		for i,v in next, workspace.Info.CardVote:GetChildren() do
			if v ~= nil and (v.Name == 'Heal' or v.Name == 'Heal2' or v.Name == 'Machine') then
				return v
			end
		end

		return nil
	end

	local function StateCollide(parent, state)
		local noCollide = {'DoorHitbox','DoorVisible','ElevatorHitBox'}

		for _, v in next, parent:GetDescendants() do
			if v:IsA("BasePart") and not table.find(noCollide, v.Name) then
				if state then
					v.CanCollide = true
				else
					v.CanCollide = false
				end
			end
		end
	end

    local loopApplyESP = coroutine.create(function()
		while wait(1) do
			ApplyImportantModelESP()
		end
    end)

	local loopAutoFarm = coroutine.create(function()
		local debounce = false
    	local currentHeight = clientRoot.Position.Y

		while wait(0.1) do
			if Settings.AutoFarm then
				local generator = IncompleteGenerator()
				local inElevator = clientStats:FindFirstChild("InElevator") and clientStats.InElevator.Value
				
				if generator then
					if inElevator and not debounce then
						StateCollide(workspace.CurrentRoom, true)
						StateCollide(workspace.Elevators, true)
						repeat wait()
							clientRoot.CFrame = CFrame.new(clientRoot.Position.X, currentHeight, clientRoot.Position.Z)
						until Menu.Message.Text:find('Elevator closes in') or not Menu.Message.Visible

						StateCollide(workspace.CurrentRoom, false)
						StateCollide(workspace.Elevators, false)

						repeat wait()
							if not Settings.AutoFarm then break end
							
							OneTimeLerpTo(workspace.Elevators.Elevator.ForceZone)
						until (clientRoot.Position - workspace.Elevators.Elevator.ForceZone.Position).magnitude <= 3
						generator = IncompleteGenerator()
						debounce = true
					else
						StateCollide(workspace.CurrentRoom, false)
						StateCollide(workspace.Elevators, false)

						repeat wait()
							if not Settings.AutoFarm then break end
							if generator.Stats.ActivePlayer.Value ~= nil and tostring(generator.Stats.ActivePlayer.Value) ~= Client.Name then break end

							if SpecialAlerts() then
								local danger = SpecialAlerts()
								if danger then
									repeat wait()
										if not danger or not danger.PrimaryPart then break end
					
										local dangerRoot = danger.PrimaryPart
										if dangerRoot then
											generator.Stats.StopInteracting:FireServer("Stop")

											local zone = workspace.Elevators.Elevator.ForceZone
											if (clientRoot.Position - zone.Position).magnitude > 30 then
												BackToElevator()
											else
												clientRoot.CFrame = CFrame.new(clientRoot.Position.X, zone.Position.Y-5, clientRoot.Position.Z)
											end
										end
									until not danger
									generator = IncompleteGenerator()
									break
								end
							end

							if MonstersClose(20) or MonstersAlert() or SpecialAlerts() then
								generator.Stats.StopInteracting:FireServer("Stop")
							else
								if (clientRoot.Position - generator.PrimaryPart.Position).magnitude <= 2 then
									interactPrompt(generator)
								end
							end
							
							OneTimeLerpTo(generator.PrimaryPart) --[[ TeleportPositions.TeleportPosition *]]
						until generator.Stats.Completed.Value
						clientRoot.CFrame = CFrame.new(clientRoot.Position.X, (generator.PrimaryPart.Position.Y - 2.5), clientRoot.Position.Z)
					end
				else
					if inElevator then
						StateCollide(workspace.CurrentRoom, true)
						StateCollide(workspace.Elevators, true)
						repeat wait()
							if not Settings.AutoFarm then break end

							clientRoot.CFrame = CFrame.new(clientRoot.Position.X, currentHeight, clientRoot.Position.Z)
							local bestCard = GetBestCard()
							if bestCard then
								ReplicatedStorage.Events.CardVoteEvent:FireServer(bestCard)
							end
						until IncompleteGenerator()
						debounce = false
					else
						StateCollide(workspace.CurrentRoom, false)
						StateCollide(workspace.Elevators, false)
						
						if workspace.Info.ElevatorPrompt.ClaimIcon.Enabled then
							repeat wait()
								if not Settings.AutoFarm then break end
								
								local base = workspace.Elevators.Elevator.Base
								if (clientRoot.Position - base.Position).magnitude > 30 then
									BackToElevator()
								else
									OneTimeLerpTo(base)
								end
							until not workspace.Info.ElevatorPrompt.ClaimIcon.Enabled
						end
					end
				end
			end
		end
	end)

	Cleaner(loopApplyESP)
	coroutine.resume(loopApplyESP)
	Cleaner(loopAutoFarm)
	coroutine.resume(loopAutoFarm)

    --[[ UI *]]
    local Repository = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
	local Library = loadstring(game:HttpGet(Repository .. "Library.lua"))()
    Cleaner.GetCleanEvent():Connect(function()
		Library:Unload()
	end)

	local Window = Library:CreateWindow({
		Title = "Dandys World",
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
		UISettings = Window:AddTab("UI Settings", "settings"),
	}

	local Groups = {
		Map = Tabs.Main:AddLeftGroupbox("Map"),
		Client = Tabs.Main:AddLeftGroupbox("Client"),
		ESP = Tabs.Main:AddRightGroupbox("ESP"),
		Auto = Tabs.Main:AddRightGroupbox("Auto"),
	}

	Groups.Map:AddButton("Full Bright", function()
        ApplyFullBright()
	end)

	Groups.Map:AddButton("Reset Brightness", function()
        ResetFullBright()
	end)

	Groups.Client:AddSlider("SpeedBoost", {
		Text = "Speed Boost",
		Default = Settings.SpeedBoost,
		Min = 20,
		Max = 35,
		Rounding = 1,
		Compact = false,
		Callback = function(value)
			Settings.SpeedBoost = value
			Save_Settings()
		end,
	})

	Groups.Client:AddLabel("Speed Boost Bind"):AddKeyPicker("SpeedKey", {
		Default = Settings.KeySpeedBoost,
		Text = "Key Speed Boost",
		Mode = "Toggle", -- Options: "Toggle", "Hold", "Always"
		SyncToggleState = false,
		Callback = function()
            clientHumanoid.WalkSpeed = Settings.SpeedBoost
		end,
		Clicked = function()
            clientHumanoid.WalkSpeed = Settings.SpeedBoost
		end,
		ChangedCallback = function(key)
			Settings.KeySpeedBoost = tostring(key)
            Save_Settings()
		end,
	})
	
	Groups.Client:AddLabel("Macro Bassie Bind"):AddKeyPicker("MacroBassieBoost", {
		Default = Settings.KeyMacroBassie,
		Text = "Macro Bassie Boost",
		Mode = "Toggle", -- Options: "Toggle", "Hold", "Always"
		SyncToggleState = false,
		Callback = function()
			bassieMacro()
		end,
		Clicked = function()
			bassieMacro()
		end,
		ChangedCallback = function(key)
			Settings.KeyMacroBassie = tostring(key)
            Save_Settings()
		end,
	})

	Groups.Auto:AddToggle("AutoGeneratorCheck", {
		Text = "Auto Generator Check",
		Default = Settings.AutoSkillCheck,
		Tooltip = "Auto check generator",
		Callback = function(state)
			Settings.AutoSkillCheck = state
			saveSettings()
		end,
	})

	Groups.Auto:AddToggle("AutoFarm", {
		Text = "Auto Farm",
		Default = Settings.AutoFarm,
		Tooltip = "Auto check generator",
		Callback = function(state)
			Settings.AutoFarm = state
			saveSettings()

			if not Settings.AutoFarm and clientRoot:FindFirstChild("AntiGravityLock") then
				clientRoot.AntiGravityLock:Remove()
				wait(.1)
				BackToElevator()
				wait(.1)
				StateCollide(workspace.CurrentRoom, true)
				StateCollide(workspace.Elevators, true)
			end
		end,
	})

	Groups.ESP:AddToggle("ESPNeededModels", {
		Text = "ESP Needed Models",
		Default = Settings.ESPNeededModels,
		Tooltip = "Apply ESP to monsters / items",
		Callback = function(state)
			Settings.ESPNeededModels = state
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