local wait = task.wait

local function waitForChild(parent, options)
	assert(parent and parent:IsA("Instance"), "Parent must be a valid Instance")

	local name = options.Name
	local className = options.ClassName
	local found = nil

	if name and className then
		local candidate = parent:FindFirstChild(name)
		if candidate and candidate:IsA(className) then
			return candidate
		end
	elseif name then
		found = parent:FindFirstChild(name)
		if found then
			return found
		end
	elseif className then
		found = parent:FindFirstChildWhichIsA(className)
		if found then
			return found
		end
	end

	while wait() do
		if name and className then
			local candidate = parent:FindFirstChild(name)
			if candidate and candidate:IsA(className) then
				found = candidate
			end
		elseif name then
			found = parent:FindFirstChild(name)
		elseif className then
			found = parent:FindFirstChildWhichIsA(className)
		end

		if found then
			break
		end
	end

	return found
end

repeat
	wait()
until game:IsLoaded()
waitForChild(waitForChild(workspace, { Name = "CurrentRoom" }), { ClassName = "Model" })

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
local FileName = "dandys_world(ID_" .. game:GetService("Players").LocalPlayer.UserId .. ").json"
if not pcall(function()
	readfile(FileName)
end) then
	writefile(FileName, HttpS:JSONEncode(defaultSettings))
end
local Settings = HttpS:JSONDecode(readfile(FileName))
function saveSettings()
	writefile(FileName, HttpS:JSONEncode(Settings))
end

local USERCONSOLE = false
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
	local VirtualInputManager = game:GetService("VirtualInputManager")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local Client = Players.LocalPlayer
	local ScreenGui = waitForChild(Client.PlayerGui, { Name = "ScreenGui", ClassName = "ScreenGui" })
	local Menu = waitForChild(ScreenGui, { Name = "Menu", ClassName = "Frame" })
	local SkillCheckFrame = waitForChild(Menu, { Name = "SkillCheckFrame", ClassName = "Frame" })
	local Marker = waitForChild(SkillCheckFrame, { Name = "Marker", ClassName = "GuiObject" })
	local GoldArea = waitForChild(SkillCheckFrame, { Name = "GoldArea", ClassName = "Frame" })

	local Character = Client.Character or Client.CharacterAdded:Wait()
	local clientStats = Character:WaitForChild("Stats")
	Client.CharacterAdded:Connect(function(newChar)
		Character = newChar
	end)
	local clientRoot = waitForChild(Character, { Name = "HumanoidRootPart" })
	local clientHumanoid = waitForChild(Character, { Name = "Humanoid" })
	local clientInventory = waitForChild(Character, { Name = "Inventory" })

	Client.CameraMaxZoomDistance = 200

	local VirtualUser = game:GetService("VirtualUser")
	game:GetService("Players").LocalPlayer.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)

	local function interactPrompt(model)
		if not model then
			return
		end

		for _, prompt in next, model:GetDescendants() do
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

	local function useItems()
		for i = 1, 3 do
			ReplicatedStorage.Events.ItemEvent:InvokeServer(Character, clientInventory["Slot" .. i])
		end
	end

	--[[ Bassie Macro ]]
	local function collectClosestItems(useItem)
		useItem = useItem or false

		local currentRoom = waitForChild(workspace, { Name = "CurrentRoom" })
		local model = waitForChild(currentRoom, { ClassName = "Model" })

		for _, folder in next, model:GetChildren() do
			if folder:IsA("Folder") and folder.Name == "Items" then
				for _, item in next, folder:GetChildren() do
					if
						item:IsA("Model")
						and item.PrimaryPart
						and (clientRoot.Position - item.PrimaryPart.Position).magnitude <= 10
					then
						interactPrompt(item)
					end
				end
			end
		end

		if useItem then
			ReplicatedStorage.Events.SprintEvent:FireServer(true)
			useItems()
			ReplicatedStorage.Events.SprintEvent:FireServer(false)
		end
	end

	local function bassieMacro()
		ReplicatedStorage.Events.AbilityEvent:InvokeServer(Character, clientRoot.CFrame, false)
		wait()
		ReplicatedStorage.Events.ItemEvent:InvokeServer(Character, clientInventory.Slot1)
		wait(0.1)
		collectClosestItems()
	end

	local TOLERANCE = 10

	local function isWithinGoldArea(mark, area)
		local pos, size = area.AbsolutePosition, area.AbsoluteSize
		local markerX = mark.AbsolutePosition.X
		return markerX >= pos.X and markerX <= pos.X + size.X + TOLERANCE
	end

	local function tryAutoSkillCheck()
		if SkillCheckFrame.Visible and Settings.AutoSkillCheck then
			local marker = waitForChild(SkillCheckFrame, { Name = "Marker", ClassName = "GuiObject" })
			local goldArea = waitForChild(SkillCheckFrame, { Name = "GoldArea", ClassName = "Frame" })
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
	bindChanges(Marker)
	bindChanges(GoldArea)

	--[[ ESP ]]
	local function addESP(target, fillcolor)
		if not target:FindFirstChild("TargetESP") then
			local highlight = Instance.new("Highlight", target)
			highlight.Name = "TargetESP"
			highlight.Archivable = true
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Ensures highlight is always visible
			highlight.Enabled = true
			highlight.FillColor = fillcolor
			highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- Set outline color to white
			highlight.FillTransparency = 0.5 -- Set fill transparency
			highlight.OutlineTransparency = 0 -- No transparency on the outline
		end
	end

	local function applyESP()
		local currentRoom = waitForChild(workspace, { Name = "CurrentRoom" })
		local model = waitForChild(currentRoom, { ClassName = "Model" })

		local usefulItems = {
			"Bandage",
			"HealthKit",
			"ChocolateBox",
			"Valve",
			"JumperCable",
			"EjectButton",
			"Instructions",
			"SmokeBomb",
		}

		for _, folder in next, model:GetChildren() do
			local allowedFolders = {
				Monsters = true,
				Generators = true,
				Items = true,
			}
			if folder:IsA("Folder") and allowedFolders[folder.Name] then
				for _, child in next, folder:GetChildren() do
					if child:IsA("Model") then
						local highlight = child:FindFirstChild("TargetESP")
						if Settings.ESPNeededModels and not highlight then
							if child.Name == "Generator" then
								addESP(child, Color3.fromRGB(57, 255, 20))
							elseif table.find(usefulItems, child.Name) then
								addESP(child, Color3.fromRGB(0, 255, 255))
							elseif child:FindFirstChild("HumanoidRootPart") then
								addESP(child, Color3.fromRGB(255, 25, 25))
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
	local function backToElevator()
		if workspace:FindFirstChild("BaseplateTrigger") then
			firetouchinterest(clientRoot, workspace.BaseplateTrigger, 0)
			wait(0.1)
			firetouchinterest(clientRoot, workspace.BaseplateTrigger, 1)
		end
	end

	local function specialAlerts()
		local currentRoom = waitForChild(workspace, { Name = "CurrentRoom" })
		local model = waitForChild(currentRoom, { ClassName = "Model" })
		local danger = nil

		for _, folder in next, model:GetChildren() do
			if folder:IsA("Folder") and folder.Name == "FreeArea" then
				for _, object in next, folder:GetChildren() do
					if object.Name == "SproutTendril" and object:FindFirstChild("HumanoidRootPart") then
						danger = object
						break
					end
				end
			end
		end

		return danger
	end

	local function monstersAlert()
		local currentRoom = waitForChild(workspace, { Name = "CurrentRoom" })
		local model = waitForChild(currentRoom, { ClassName = "Model" })

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

	local function monstersClose(distance)
		distance = distance or 30
		local currentRoom = waitForChild(workspace, { Name = "CurrentRoom" })
		local model = waitForChild(currentRoom, { ClassName = "Model" })

		local blockList = { "RazzleDazzleMonster", "RodgerMonster" }
		for _, folder in next, model:GetChildren() do
			if folder:IsA("Folder") and folder.Name == "Monsters" then
				for _, monster in next, folder:GetChildren() do
					if monster:IsA("Model") and monster.PrimaryPart and not table.find(blockList, monster.Name) then
						if (clientRoot.Position - monster.PrimaryPart.Position).magnitude <= distance then
							return true
						end
					end
				end
			end
		end

		return false
	end

	local bodyPosition
	local function lerpTo(target)
		local distance = (clientRoot.Position - target.Position).magnitude
		local speedFactor = (60 * wait())
		local estimatedTime = speedFactor / distance
		local adjustedLerpAlpha = math.min(estimatedTime, 1)

		if not clientRoot:FindFirstChild("AntiGravityLock") then
			bodyPosition = Instance.new("BodyPosition")
			bodyPosition.Name = "AntiGravityLock"
			bodyPosition.MaxForce = Vector3.new(0, math.huge, 0)
			bodyPosition.P = 20000
			bodyPosition.D = 1500
			bodyPosition.Parent = clientRoot
		end

		if distance <= 20 and not monstersAlert() and not monstersClose(50) then
			clientRoot.CFrame = clientRoot.CFrame:lerp(CFrame.new(target.Position), adjustedLerpAlpha)
			bodyPosition.Position = Vector3.new(clientRoot.Position.X, target.Position.Y, clientRoot.Position.Z)
		else
			if (monstersAlert() and monstersClose(20)) or (monstersAlert() and distance <= 20) then
				clientRoot.CFrame = CFrame.new(clientRoot.Position.X, (target.Position.Y - 2.3), clientRoot.Position.Z)
			end
			clientRoot.CFrame = clientRoot.CFrame:lerp(
				CFrame.new(target.Position.X, (target.Position.Y - 2.3), target.Position.Z),
				adjustedLerpAlpha
			)
			bodyPosition.Position = Vector3.new(clientRoot.Position.X, target.Position.Y - 2.3, clientRoot.Position.Z)
		end
	end

	local function generators()
		local currentRoom = waitForChild(workspace, { Name = "CurrentRoom" })
		local model = waitForChild(currentRoom, { ClassName = "Model" })

		local sproutParts = {}
		do
			local freeArea = model:FindFirstChild("FreeArea")
			if freeArea then
				for _, obj in next, freeArea:GetChildren() do
					if obj.Name == "SproutTendril" then
						local hrp = obj:FindFirstChild("HumanoidRootPart")
						if hrp then
							sproutParts[#sproutParts + 1] = hrp
						end
					end
				end
			end
		end

		local nearestGen, shortestDistance = nil, math.huge
		local generatorsFolder = waitForChild(model, { Name = "Generators" })

		for _, gen in next, generatorsFolder:GetChildren() do
			local prompt = gen:FindFirstChild("Prompt")
			local origin = gen:FindFirstChild("Origin")
			local stats = gen:FindFirstChild("Stats")
			if prompt and origin and stats then
				local completed = stats:FindFirstChild("Completed")
				local activePlayer = stats:FindFirstChild("ActivePlayer")
				if completed and activePlayer and not completed.Value then
					local isNearDanger = false
					for _, hrp in next, sproutParts do
						if (prompt.Position - hrp.Position).magnitude <= 30 then
							isNearDanger = true
							break
						end
					end

					if not isNearDanger then
						local dist = (clientRoot.Position - origin.Position).magnitude
						if dist < shortestDistance then
							shortestDistance = dist
							nearestGen = gen
						end
					end
				end
			end
		end

		return nearestGen
	end

	local function bestCard()
		local info = waitForChild(workspace, { Name = "Info" })
		local cardVote = waitForChild(info, { Name = "CardVote" })

		for i, v in next, cardVote:GetChildren() do
			if v ~= nil and (v.Name == "Heal" or v.Name == "Heal2" or v.Name == "Machine") then
				return v
			end
		end

		return nil
	end

	local function stateCollide(parent, state)
		local ignoreNames = {
			DoorHitbox = true,
			DoorVisible = true,
			ElevatorHitBox = true,
		}

		for _, part in parent:GetDescendants() do
			if not ignoreNames[part.Name] then
				pcall(function()
					if state == false and part.CanCollide == true then
						part.CanCollide = state
					elseif state == true then
						part.CanCollide = state
					end
				end)
			end
		end
	end

	local function noclipCharacter()
		local charCFrame, charSize = Character:GetBoundingBox()
		local region = Region3.new(charCFrame.Position - (charSize / 2), charCFrame.Position + (charSize / 2))

		local touchingParts = workspace:FindPartsInRegion3(region, Character, math.huge)

		for _, part in next, touchingParts do
			if part:IsA("BasePart") and part.CanCollide and not Character:IsAncestorOf(part) then
				part.CanCollide = false
			end
		end
	end

	local loopApplyESP = coroutine.create(function()
		while wait(1) do
			applyESP()
		end
	end)

	local loopAutoFarm = coroutine.create(function()
		local debounce = false
		local currentHeight = clientRoot.Position.Y

		while wait(0.1) do
			if not Settings.AutoFarm then
				continue
			end

			local generator = generators()

			local inElevator = waitForChild(clientStats, { Name = "InElevator" })
			inElevator = inElevator.Value

			local elevator = waitForChild(workspace, { Name = "Elevators" })
			elevator = waitForChild(elevator, { Name = "Elevator" })
			local forceZone = waitForChild(elevator, { Name = "ForceZone" })
			local base = waitForChild(elevator, { Name = "Base" })

			if generator then
				local generatorOrigin = waitForChild(generator, { Name = "Origin" })
				local generatorStats = waitForChild(generator, { Name = "Stats" })
				local generatorStats_Completed = waitForChild(generatorStats, { Name = "Completed" })
				local generatorStats_StopInteracting = waitForChild(generatorStats, { Name = "StopInteracting" })

				if inElevator and not debounce then
					repeat
						wait()
						clientRoot.CFrame = CFrame.new(clientRoot.Position.X, currentHeight, clientRoot.Position.Z)
					until not Menu.Message.Visible or Menu.Message.Text:find("Elevator closes in")

					repeat
						wait()
						if not Settings.AutoFarm then
							break
						end
						lerpTo(forceZone)
					until (clientRoot.Position - forceZone.Position).magnitude <= 3

					generator = generators()
					if generator then
						generatorOrigin = waitForChild(generator, { Name = "Origin" })
						generatorStats = waitForChild(generator, { Name = "Stats" })
						if generatorStats then
							generatorStats_Completed = waitForChild(generatorStats, { Name = "Completed" })
							generatorStats_StopInteracting = waitForChild(generatorStats, { Name = "StopInteracting" })
						end
					end
					debounce = true
				else
					repeat
						wait()
						if not Settings.AutoFarm then
							break
						end

						if monstersClose(20) or monstersAlert() then
							generatorStats_StopInteracting:FireServer("Stop")

							generator = generators()
							if generator then
								generatorOrigin = waitForChild(generator, { Name = "Origin" })
								generatorStats = waitForChild(generator, { Name = "Stats" })
								if generatorStats then
									generatorStats_Completed = waitForChild(generatorStats, { Name = "Completed" })
									generatorStats_StopInteracting =
										waitForChild(generatorStats, { Name = "StopInteracting" })
								end
							else
								break
							end
						end

						if generatorOrigin then
							lerpTo(generatorOrigin)
							if (clientRoot.Position - generatorOrigin.Position).magnitude <= 2 then
								interactPrompt(generator)
							end
						end
					until generatorStats_Completed.Value
					if generatorOrigin then
						clientRoot.CFrame =
							CFrame.new(clientRoot.Position.X, generatorOrigin.Position.Y - 2.3, clientRoot.Position.Z)
					end
				end
			else
				if specialAlerts() then
					repeat
						wait()
						if not Settings.AutoFarm then
							break
						end

						if (clientRoot.Position - base.Position).magnitude > 30 then
							backToElevator()
						else
							lerpTo(base)
						end
					until not specialAlerts()
				else
					if inElevator then
						repeat
							wait(1)
							if not Settings.AutoFarm then
								break
							end

							clientRoot.CFrame = CFrame.new(clientRoot.Position.X, currentHeight, clientRoot.Position.Z)
							ReplicatedStorage.Events.CardVoteEvent:FireServer(bestCard())
						until generators()
						debounce = false
					else
						local info = waitForChild(workspace, { Name = "Info" })
						local elevatorPrompt = waitForChild(info, { Name = "ElevatorPrompt" })
						local claimIcon = waitForChild(elevatorPrompt, { Name = "ClaimIcon" })
						if claimIcon.Enabled then
							repeat
								wait()
								if not Settings.AutoFarm then
									break
								end

								if (clientRoot.Position - base.Position).magnitude > 30 then
									backToElevator()
								else
									lerpTo(base)
								end
							until not claimIcon.Enabled
						end
					end
				end
			end
		end
	end)

	local loopAutoItems = coroutine.create(function()
		while wait() do
			if not Settings.AutoFarm then
				continue
			end

			collectClosestItems(true)
			noclipCharacter()
			-- stateCollide(waitForChild(workspace, { Name = "CurrentRoom" }), false)
			-- stateCollide(waitForChild(workspace, { Name = "Elevators" }), false)
		end
	end)

	Cleaner(loopApplyESP)
	coroutine.resume(loopApplyESP)
	Cleaner(loopAutoFarm)
	coroutine.resume(loopAutoFarm)
	Cleaner(loopAutoItems)
	coroutine.resume(loopAutoItems)

	--[[ UI *]]
	local Library = loadstring(
		game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua")
	)()
	Cleaner.GetCleanEvent():Connect(function()
		Library:Unload()
	end)

	local Version = "0.0.2.7"
	local Author = "Kain"
	local Window = Library:CreateWindow({
		Title = "Dandys World",
		Center = true,
		AutoShow = true,
		ShowCustomCursor = false,
		ToggleKeybind = Enum.KeyCode.RightControl,
		Footer = "Version: " .. Version .. " | " .. Author,
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
			saveSettings()
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
			saveSettings()
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
			saveSettings()
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
				wait(0.1)
				backToElevator()
				wait(0.1)
				stateCollide(waitForChild(workspace, { Name = "CurrentRoom" }), true)
				stateCollide(waitForChild(workspace, { Name = "Elevators" }), true)
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
end, function(err)
	warn(debug.traceback("[Error]: " .. tostring(err), 2))
end)
