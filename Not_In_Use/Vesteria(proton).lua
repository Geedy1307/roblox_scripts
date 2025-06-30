local Lib = loadstring(game:HttpGet("https://pastebin.com/raw/tW4nuE5U", true))()
local Window = Lib:Window("Vesteria")

local Tabs = {
    Autofarm = Window:Tab("Autofarm"),
    Autosell = Window:Tab("Auto Sell"),
    Local = Window:Tab("Local"),
    Combat = Window:Tab("Combat"),
    Misc = Window:Tab("Misc"),
    Visuals = Window:Tab("Visuals")
}

local Sections = {
    AutofarmSettings = Tabs.Autofarm:Section("Settings"),
    AutofarmMisc = Tabs.Autofarm:Section("Misc"),
    LocalCharacter = Tabs.Local:Section("Character"),
    LocalCheats = Tabs.Local:Section("Cheats"),
    CombatSettings = Tabs.Combat:Section("Settings"),
    MiscRandom = Tabs.Misc:Section("Random"),
    VisualsESP = Tabs.Visuals:Section("ESP"),
    VisualsEnvironment = Tabs.Visuals:Section("Environment"),
    PrioritizeMenu = Tabs.Autofarm:Section("Prioritize Mobs"),
    AutosellSettings = Tabs.Autosell:Section("Settings")
}

local Environment = getgenv()

Environment.Settings = { 
    ["InfiniteStamina"] = false,
    ["Autofarm"] = false,
    ["Godmode"] = false,
    ["AutoPickup"] = false,
    ["Bypass"] = true,
    ["Flight"] = false,
    ["Autofish"] = false,
    ["Announce"] = true,
    ["FlightSpeed"] = 200,
    ["UseAbilities"] = true,
    ["Offset"] = Vector3.new(4, 0, 4),
    ["Autosell"] = false,
    ["KillAura"] = false,
    ["Chestfarm"] = false,
    ['HideName'] = true,
}

for Index, ServiceInstance in next, game:GetChildren() do
    local ServiceName = ServiceInstance.Name:gsub("%s+", "")
    local Service = select(2, pcall(game.GetService, game, ServiceName))

    if typeof(Service) == "Instance" then 
        Environment[ServiceName] = Service 
    end
end

for Index, Function in next, math do
    Environment[Index] = Function
end

Environment.PathfindingService = game:GetService("PathfindingService")
Environment.MarketplaceService = game:GetService("MarketplaceService")

Environment.set_thread_context = set_thread_context or setthreadcontext or syn.set_thread_identity
Environment.getscriptclosure = getscriptclosure or getscriptfunction or get_script_function
Environment.getprotos = getprotos or debug.getprotos 
Environment.getconstants = getconstants or debug.getconstants
Environment.getupvalues = getupvalues or debug.getupvalues

Environment.hookmetamethod = hookmetamethod or function(Table, Method, Callback)
    local mt = getrawmetatable(Table)
    local oldMethod 

    spawn(function()
        RunService.Heartbeat:Wait()
        oldMethod = hookfunction(mt[Method], Callback)
    end)

    return oldMethod
end

local Character = Player.Character or Player.CharacterAdded:Wait()
local Hitbox = Character:WaitForChild("hitbox") 
local Signal = ReplicatedStorage:WaitForChild("signal") 
local PlayerRequest = ReplicatedStorage:WaitForChild("playerRequest")
local Modules = ReplicatedStorage:WaitForChild("modules")
local Network = Modules:WaitForChild("network")
local JoltFunction = Network:WaitForChild("applyJoltVelocityToCharacter")
local ActiveAbilityExecutionData = Hitbox:WaitForChild("activeAbilityExecutionData")
local ActivateAbilityRequest = Network:WaitForChild("activateAbilityRequest")
local AbilityLookup = require(ReplicatedStorage:WaitForChild("abilityLookup"))

local AbilityTags = {}

for Index, Value in next, ReplicatedStorage.abilityLookup:GetChildren() do
    local AbilityModule = require(Value)
    
    for Index, Execute in next, getprotos(getscriptclosure(Value)) do
        if Execute then
            local IdConstantIndex = table.find(getconstants(Execute), "ability")
            
            if not IdConstantIndex then 
                for Index, Proto in next, getprotos(Execute) do
                    Execute = Proto 
                    IdConstantIndex = table.find(getconstants(Execute), "ability")
                    
                    if IdConstantIndex then 
                        break 
                    end
                end
            end
            
            if IdConstantIndex and #getconstants(Execute) >= IdConstantIndex + 2 then
                local AbilityTag = getconstant(Execute, IdConstantIndex + 2)
                AbilityTags[Value] = AbilityTag
            end
        end
    end
end

local function GetSpellContents()
    local AbilityData = Network:WaitForChild("getCacheValueByNameTag"):Invoke("abilities")
    local PlayerData = Network:WaitForChild("getLocalPlayerDataCache"):Invoke()
    local EntityContainer = Network:WaitForChild("getMyClientCharacterContainer"):Invoke()
    
    local Contents = {}
    local Number = 0 
    
    for Index, AbilitySlotData in next, AbilityData do 
        if AbilitySlotData.rank > 0 then 
            Number = Number + 1 
            Contents[tostring(Number)] = AbilitySlotData
        end
    end
    
    return Contents
end

local function CanAttack(Name)
    if #Settings.Prioritize == 0 then 
        return true 
    end

    if table.find(Settings.Prioritize, Name) then 
        return true 
    end
    
    return false
end

local function inPvp(Enemy) 
    if not Enemy then return end 
    for Index, Value in next, workspace.placeFolders.pvpZoneCollection:GetChildren() do 
        if Value.ClassName == "Model" then 
            for Index2, Value2 in next, Value:GetChildren() do 
                --warn("CRINGE")
                local Region = Region3.new(Value2.Position - (Value2.Size / 2), Value2.Position + (Value2.Size / 2))
                for Index3, Value3 in next, workspace:FindPartsInRegion3(Region, nil, huge) do 
                    --warn("STILL CRINGE",Value3)
                    if Value3.Parent == Enemy then 
                        return true 
                    end
                    
                end
            end
        end
    end
    return false
end


local function GetAttackable(Attacking)
    if not Hitbox then
        return 
    end
    
    local Attackable = {}   
    if not Attacking then 
        for Index, Value in next, workspace.placeFolders.entityManifestCollection:GetChildren() do 
            if Value.ClassName ~= "Model" and Value.Name ~= "Hitbox" and Value:FindFirstChild("health") and Value.health.Value > 0 and not Value:FindFirstChild("pet") then 
                local Distance = (Value.Position - Hitbox.Position).Magnitude
                if Distance < 15 then 
                    table.insert(Attackable, Value)
                end
            end
        end

        if #Attackable == 0 then
            for Index, Value in next, workspace.placeFolders.entityManifestCollection:GetChildren() do 
                if Value.ClassName ~= "Model" and Value:FindFirstChild("health") and Value.Name ~= "Hitbox" and Value.health.Value > 0 and not Value:FindFirstChild("pet") then 
                    local Distance = (Value.Position - Hitbox.Position).Magnitude
                    if Distance < 15 then 
                        table.insert(Attackable, Value)
                    end
                end
            end
        end
    else 
        for Index, Value in next, workspace.placeFolders.entityManifestCollection:GetChildren() do 
            if Value.Name ~= Player.Name and Players:FindFirstChild(Value.Name) and Value.PrimaryPart and inPvp(Value) then 
                local Distance = (Value.PrimaryPart.Position - Hitbox.Position).Magnitude
                if Distance < 15 then 
                    table.insert(Attackable, Value.PrimaryPart)
                end
            end
        end
    end

    return Attackable
end

local function CastSpell(ExecutionData)
    local Contents = GetSpellContents()
    local AbilityItems = {}
    local Entities = GetAttackable()
    for Index = 1, 20 do 
        local Item = Contents[tostring(Index)]
        
        if Item then 
            local AbilityBaseData = AbilityLookup[Item.id](PlayerData)
            
            if AbilityBaseData.execute then
                for _, Entity in next, Entities do 
                    Signal:FireServer("playerRequest_damageEntity", Entity, Entity.Position, "ability", Item.id, AbilityTags[AbilityBaseData.module], ExecutionData["ability-guid"])
                end
            end
        end
    end
end

local function CountTable(Table)
    local Count = 0 
    
    for Index, Value in next, Table do 
        Count = Count + 1 
    end 
    
    return Count 
end

local function ActivateSpells()
    local Contents = GetSpellContents()
    for Index = 1, CountTable(Contents) do 
        local Ability = Contents[tostring(Index + 1)]
        
        if Ability then
            pcall(function()
                ActivateAbilityRequest:Invoke(Ability.id, Player.PlayerGui.gameUI.bottomRight.hotbarFrame.content:FindFirstChild("hotbarButton" .. Index + 2))
            end)
        end
    end
end

local Teleports = {}
local ActualTeleports = {}

local function chat(text,colour)
    return false
end

--[[
Sections.AutosellSettings:Toggle("Enable", false, function(Value)
    Settings.Autosell = Value
end)
]]
Sections.AutosellSettings:Label("COMING SOON")

Sections.CombatSettings:Toggle("Kill Aura", false, function(Value)
    Settings.KillAura = Value
    if Settings.Announce then 
        if Value then 
            chat("Kill Aura enabled.",Color3.new(0,1,0))
        else 
            chat("Kill Aura disabled.",Color3.new(1,0,0))
        end
    end
end)


Sections.AutofarmSettings:Toggle("Enabled", false, function(Value)
    if not Value then 
        delay(3, function()
            if not Settings.Autofarm and not Settings.Chestfarm then
                Settings.Bypass = false -- ur mom
            end
        end)
    else 
        Settings.Bypass = true -- not ur mom
    end 

    Settings.Autofarm = Value
    
    if not Value then 
        JoltFunction:Fire(-huge, -huge, -huge) -- more like - huge bulge in your pants
    end
    if Settings.Announce then
        if Value then  
            chat("Autofarm enabled.",Color3.new(0, 1, 0))
        else
            chat("Autofarm disabled.",Color3.new(1, 0, 0)) 
        end
    end
end)

Sections.AutofarmSettings:Toggle("Use Abilities", true, function(Value)
    Settings.UseAbilities = Value 

    if Settings.Announce then
        if Value then  
            chat("Use Abilities enabled.",Color3.new(0, 1, 0))
        else
            chat("Use Abilities disabled.",Color3.new(1, 0, 0)) 
        end
    end
end)

Sections.AutofarmSettings:Toggle("Attack Players", false, function(Value)
    Settings.AttackPlayers = Value 

    if Settings.Announce then
        if Value then  
            chat("Attack Players enabled.",Color3.new(0, 1, 0))
        else
            chat("Attack Players disabled.",Color3.new(1, 0, 0)) 
        end
    end
end)



Sections.AutofarmSettings:Toggle("Use Smallest Server", false, function(Value)
    Settings.UseSmallestServer = Value 
end)

local function GetServers() 
    local Cursor
    local Servers = {}
    repeat
        local Response = HttpService:JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100" .. (Cursor and "&cursor=" .. Cursor or "")))
        for _, Value in next, Response.data do
            table.insert(Servers, Value)
        end
        Cursor = Response.nextPageCursor
    until not cursor
    return Servers
end

local function UseSmallestServer()
    local Servers = GetServers() 
    table.sort(Servers, function(V1,V2)
        return (V1.playing or 99) < (V2.playing or 99)
    end)

    if Servers[1].id ~= game.JobId then  
        PlayerRequest:InvokeServer("playerRequest_teleportToJobId", Servers[1].id)
    end
end



Sections.AutofarmSettings:Slider("X Teleport offset", {min = -8, default = 4, max = 8},function(Value)
    local Vector = Vector3.new(Value, Settings.Offset.Y, Settings.Offset.Z)
    Environment.Settings.Offset = Vector 
end)

Sections.AutofarmSettings:Slider("Y Teleport offset", {min = -8, default = 0, max = 8},function(Value)
    local Vector = Vector3.new(Settings.Offset.X, Value, Settings.Offset.Z)
    Environment.Settings.Offset = Vector 
end)

Sections.AutofarmSettings:Slider("Z Teleport offset", {min = -8,default = 4, max = 8},function(Value)
    local Vector = Vector3.new(Settings.Offset.X, Settings.Offset.Y, Value)
    Environment.Settings.Offset = Vector 
end)



Sections.MiscRandom:Button("Open Shop", function()
    local TravelingMerchant = ReplicatedStorage:FindFirstChild("TravelingMerchant")
    
    if TravelingMerchant then
        local InventoryModule = TravelingMerchant:FindFirstChild("inventory", true)
        
        if InventoryModule then
            set_thread_context(2)
            
            local ShopModule = require(Player.PlayerGui.gameUI.playerMenu.left.shop.shop)
            ShopModule.open(InventoryModule.Parent)
            
            set_thread_context(7)
        end
    end
end)

Sections.LocalCharacter:Toggle("Flight", false, function(Value)
    Settings.Flight = Value 
    if Settings.Announce then
        if Value then  
            chat("Flight enabled.",Color3.new(0, 1, 0))
        else 
            chat("Flight disabled",Color3.new(1, 0, 0))
        end
    end
end) 

Sections.LocalCharacter:Slider("Flight Speed", {default=200, min=0, max=1000}, function(Value)
    Settings.FlightSpeed = Value 
end) 

Sections.LocalCheats:Toggle("Infinite Stamina", false, function(Value)
    Settings.InfiniteStamina = Value 
    if Settings.Announce then
        if Value then  
            chat("Infinite stamina enabled.",Color3.new(0, 1, 0))
        else 
            chat("Infinite stamina disabled",Color3.new(1,0,0))
        end
    end
end) 

Sections.LocalCheats:Toggle("Godmode", false, function(Value)
    Settings.Godmode = Value 
    if Settings.Announce then
        if Value then  
            chat("Godmode enabled.",Color3.new(0, 1, 0))
        else 
            chat("Godmode disabled",Color3.new(1, 0, 0))
        end
    end
end) 

Sections.MiscRandom:Toggle("Anti Afk", true, function(Value)
    for Index, IValue in next, getconnections(Player.Idled) do 
        if Value then 
            IValue:Disable() 
        else
            IValue:Enable()
        end
    end

    if Settings.Announce then 
        if Value then 
            chat("Anti Afk enabled.", Color3.new(0, 1, 0))
        else
            chat("Anti Afk disabled.", Color3.new(1, 0, 0)) 
        end  
    end
end)


Sections.MiscRandom:Toggle("Auto Pickup", false, function(Value)
    Settings.AutoPickup = Value 
    if Settings.Announce then
        if Value then 
            chat("Auto Pickup enabled.",Color3.new(0, 1, 0))
        else
            chat("Auto Pickup disabled.",Color3.new(1, 0, 0)) 
        end
    end
end)

local Fishing

Sections.AutofarmMisc:Toggle("Auto Fish", false, function(Value)
    local t, error = pcall(function()
        Fishing = require(Player.PlayerScripts.assets.damageInterfaces["fishing-rod"])
    end)

    if not t then 
        if not t then  
            chat("You must have a fishing rod to use auto fish.",Color3.new(1, 0, 0))
        end
    else 
        if Settings.Announce then
            if Value then 
                chat("Auto fishing enabled.",Color3.new(0, 1, 0))
                Fishing.attack()
            else 
                chat("Auto fishing disabled.",Color3.new(1, 0, 0))
            end
        end
    end
    Settings.Autofish = Value 
end)

Environment.Settings.HiddenName = "Vesteria Epic Thing"
Environment.Settings.DefaultName = Player.Name

local HasName = {}
local chests = {}

for Index, Value in next, workspace:GetDescendants() do 
    if Value.ClassName == "TextLabel" and Value.Text == Settings.DefaultName then 
        table.insert(HasName, Value) -- nametags
    elseif Value.ClassName == "Model" and Value.Name:match("%w+Chest") and Value.Name:sub(Value.Name:len() - 4, Value.Name:len()) == "Chest" then 
        table.insert(chests, Value) -- chest 
    end
end


local Mobs = {}
for Index, Value in next, workspace.placeFolders.entityManifestCollection:GetChildren() do
    if not table.find(Mobs,Value.Name) and Value.ClassName ~= "Model" and Value.Name ~= "Hitbox" and not Value:FindFirstChild("pet") then 
        table.insert(Mobs,Value.Name)
    end
end

Environment.Settings.Prioritize = {}
for Index, IValue in next, Mobs do 
    Sections.PrioritizeMenu:Toggle(tostring(IValue), false, function(Value)
        if Value then 
            table.insert(Settings.Prioritize,IValue)
        else 
            if table.find(Settings.Prioritize, IValue) then 
                table.remove(Settings.Prioritize, table.find(Settings.Prioritize, IValue))
            end
        end
    end)
end


local function HideName(oldName)
    Settings.HideName = true
    for Index, Value in next, game:GetDescendants() do 
        if Value.ClassName == "TextLabel" or Value.ClassName == "TextButton" then 
            
            local str = Value.Text:gsub(oldName,Settings.HiddenName)
            str = str:gsub(Player.Name,Settings.HiddenName)
            str = str:gsub(Player.DisplayName, Settings.HiddenName)
            Value.Text = str 
            Value:GetPropertyChangedSignal("Text"):Connect(function()
                local str = Value.Text:gsub(Player.Name,Settings.HiddenName)
                str = str:gsub(Player.DisplayName, Settings.HiddenName)
                Value.Text = str 
            end)
        end
    end
end

game.DescendantAdded:Connect(function(Value)
    if Value.ClassName == "TextLabel" or Value.ClassName == "TextButton" and Settings.HideName then 
        
        local str = Value.Text:gsub(Player.Name, Settings.HiddenName)
        str = str:gsub(Player.DisplayName, Settings.HiddenName)
        Value.Text = str 
        Value:GetPropertyChangedSignal("Text"):Connect(function()
            local str = Value.Text:gsub(Player.Name,Settings.HiddenName)
            str = str:gsub(Player.DisplayName, Settings.HiddenName)
            Value.Text = str 
        end)

    end
end)

Sections.MiscRandom:Box("Hidden Name","Vesteria Epic Thing", function(Value)
    if Value then
        local old = Settings.HiddenName
        Settings.HiddenName = Value
        HideName(old)
        
    end

    if Settings.Announce then 
        chat("Hidden Name set to "..Value,Color3.new(0,1,0))
    end
end)

Sections.MiscRandom:Toggle("Chest Farm", false, function(Value)
    if not Value then 
        delay(3, function()
            if not Settings.Autofarm and not Settings.Chestfarm then
                Settings.Bypass = false -- ur mom
            end
        end)
    else 
        Settings.Bypass = true -- not ur mom
    end 

    Settings.Chestfarm = Value
    
    if not Value then 
        JoltFunction:Fire(-huge, -huge, -huge) -- more like - huge bulge in your pants
    end
    if Settings.Announce then
        if Value then  
            chat("Chestfarm enabled.",Color3.new(0, 1, 0))
        else
            chat("Chestfarm disabled.",Color3.new(1, 0, 0)) 
        end
    end
end)

Sections.MiscRandom:Button("Teleport To Smallest Server", function()
    chat("Finding smallest server.",Color3.new(0,1,0))
    UseSmallestServer()
end)

local function Rank(User)  
    local groups = GroupService:GetGroupsAsync(User.UserId)
    for i,v in pairs(groups) do 
        if v.Id == 4238824 then 
            return v.Rank 
        end
    end
    return 0
end

Sections.MiscRandom:Toggle("Staff Detection", true, function(Value)
    Settings.StaffDetection = Value
    if Settings.Announce then 
        if Value then 
            chat("Staff Detection enabled.",Color3.new(0,1,0))
        else 
            chat("Staff Detection disabled.",Color3.new(1,0,0))
        end
    end
    if Value then 
        for Index, Value in next, Players:GetPlayers() do 
            if Value ~= Player and Rank(Value) > 1 then 
                chat("Staff Detected, joining new server.", Color3.new(1,0,0))
                local Servers = GetServers()
                while wait() do 
                    for Index, Value in next, Servers do  
                        if Value.id ~= game.JobId then
                            PlayerRequest:InvokeServer("playerRequest_teleportToJobId", Value.id)
                        end
                    end
                end
                break
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(Plr)
    if Settings.StaffDetection and Plr:GetRankInGroup(4238824) > 1 then 
        chat("Staff Detected, joining new server.",Color3.new(1,0,0))
        while wait() do 
            local Servers = GetServers()
            for Index, Value in next, Servers do  
                if Value.id ~= game.JobId then
                    PlayerRequest:InvokeServer("playerRequest_teleportToJobId", Value.id)
                end
            end
        end
    end
end)

for Index, Value in next, workspace:GetDescendants() do
    if Value.Name == "teleportDestination" then 
        local Name = MarketplaceService:GetProductInfo(Value.Value).Name
        table.insert(Teleports, Name)
        ActualTeleports[Name] = Value.Parent
    end
end

local executed = tick()
Sections.LocalCharacter:SearchBox("Teleport", Teleports, nil, function(Value)
    if tick() - executed > 1 then 
        PlayerRequest:InvokeServer("playerRequest_useTeleporter", ActualTeleports[Value])
    end
end, false)



local oldIndex 
oldIndex = hookmetamethod(game, "__index", function(self, idx)
    if tostring(self) == "stamina" and idx == "Value" and Settings.InfiniteStamina then 
        return huge
    end

    return oldIndex(self, idx)
end)

local oldNamecall 
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}

    if Settings.Godmode and getnamecallmethod() == "FireServer" and args[4] == "monster" then 
        return
    end

    return oldNamecall(self, ...)
end)

local function BypassTP(Closest)
    if not Hitbox then
        return 
    end 

    Hitbox.CanCollide = false
    Hitbox.CFrame = Closest.CFrame + Settings.Offset
end


local function GetClosest(AttackkingPlayers) 
    if not Hitbox then
        return 
    end

    local Closest = {huge, nil} 
    if not AttackkingPlayers then
        for Index, Value in next, workspace.placeFolders.entityManifestCollection:GetChildren() do 
            if Value.ClassName ~= "Model" and Value.Name ~= "Hitbox" and CanAttack(Value.Name) and Value:FindFirstChild("health") and Value.health.Value > 0 and not Value:FindFirstChild("pet") then 
                local Distance = (Value.Position - Hitbox.Position).Magnitude

                if Distance < Closest[1] then 
                    Closest = {Distance, Value} 
                end
            end
        end

        if Closest[2] and Settings.Autofarm then 
            BypassTP(Closest[2])
        else 
            for Index, Value in next, workspace.placeFolders.entityManifestCollection:GetChildren() do 
                if Value.ClassName ~= "Model" and Value.Name ~= "Hitbox" and Value:FindFirstChild("health") and Value.health.Value > 0 and not Value:FindFirstChild("pet") then 
                    local Distance = (Value.Position - Hitbox.Position).Magnitude
        
                    if Distance < Closest[1] then 
                        Closest = {Distance, Value}
                    end
                end
            end
        end
    else 
        for Index, Value in next, workspace.placeFolders.entityManifestCollection:GetChildren() do 
            if Value.Name ~= Player.Name and Players:FindFirstChild(Value.Name) and Value.PrimaryPart and inPvp(Value) then 
                local Distance = (Value.PrimaryPart.Position - Hitbox.Position).Magnitude
                if Distance < Closest[1] then 
                    Closest = {Distance, Value.PrimaryPart}
                end
            end
        end
    end
        
    return Closest[2]   
end

local function PickupItem(Item) 
    PlayerRequest:InvokeServer("pickUpItemRequest", Item)
end

local function AutoPickup()
    if not Hitbox then
        return 
    end

    for Index, Value in next, workspace.placeFolders.items:GetChildren() do 
        if (Value.Position - Hitbox.Position).Magnitude < 10 then 
            PickupItem(Value)
        end
    end
end

local function Attack(Enemy,AttackingPlayers)
    repeat 
        if Hitbox then
            if Settings.Autofarm then 
                BypassTP(Enemy) 
            end
            Signal:FireServer("fireEvent", "playerWillUseBasicAttack", Player)

            RunService.Heartbeat:Wait()
            local AttackableEnemies = GetAttackable(AttackingPlayers)

            for Index = 1, 3 do 
                Signal:FireServer("replicatePlayerAnimationSequence", "swordAnimations", "strike" .. tostring(Index), {attackSpeed = -1})

                for Index, Value in next, AttackableEnemies do 
                    Signal:FireServer("playerRequest_damageEntity", Value, Hitbox.Position, "equipment")
                    Signal:FireServer("attackInteractionAttackableAttacked", Value, Hitbox.Position)
                end
            end

            if Settings.UseAbilities and Settings.Autofarm then
                ActivateSpells()
            end
        end 
        
        RunService.Heartbeat:Wait()
    until not Enemy:FindFirstChild("health") or Enemy.health.Value <= 0 or not Hitbox or not Settings.Autofarm
    
    if Hitbox and not Settings.Autofarm then 
        Hitbox.CanCollide = true 
    end
end

local function GetRenderedPlayer()
    for Index , Value in next, workspace.placeFolders.entityRenderCollection:GetChildren() do
        if Value:FindFirstChild("clientHitboxToServerHitboxReference") and Value.clientHitboxToServerHitboxReference.Value.Parent == Player.Character then
            return Value
        end
    end
end

local function AutoFish()
    local Bait
    local Found
    local RenderedPlayer = GetRenderedPlayer()

    if RenderedPlayer then
        for Index, Value in next, RenderedPlayer.entity:GetChildren() do
            if Value.Name:find("EQUIPMENT") and Value.Name ~= "!! EQUIPMENT !!" and Value:FindFirstChild("line") then
                Found = true
                Bait = Value.line.Attachment1

                if Bait then 
                    Bait = Bait.Parent 
                end
            end
        end

        if Bait then 
            if Bait:FindFirstChild("fishing_FishBite") then 
                wait(0.1)
                Fishing.attack()

                wait(1)
                Fishing.attack()
            end
        elseif Found then
            Fishing.attack()
            wait(2)
        end
    end
end

ActiveAbilityExecutionData.Changed:Connect(function(Property)
    if Settings.UseAbilities then
        CastSpell(HttpService:JSONDecode(ActiveAbilityExecutionData.Value))
    end
end)

Player.CharacterAdded:Connect(function(Character)
    Hitbox = Character:WaitForChild("hitbox")
    ActiveAbilityExecutionData = Hitbox:WaitForChild("activeAbilityExecutionData")
    ActiveAbilityExecutionData.Changed:Connect(function(Property)
        if Settings.UseAbilities then
            CastSpell(HttpService:JSONDecode(ActiveAbilityExecutionData.Value))
        end
    end)
end)

RunService.Heartbeat:Connect(function()
    if not Settings.Autofarm and not Settings.Chestfarm then
        Settings.Bypass = false  
    end
    if Settings.Bypass then
        JoltFunction:Fire(huge, huge, huge)
        if Hitbox and Hitbox:FindFirstChild("hitboxVelocity") then   
            Hitbox.hitboxVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            Hitbox.hitboxVelocity.Velocity = Vector3.new(0, 0, 0)
            Hitbox.Velocity = Vector3.new(0, 0, 0)
        end
    end
end)

chat("Vesteria Epic Thing loaded.\nMade by Introvert#1337 and ProtonDev-Sys#4419.", Color3.new(1, 0.341176, 1))

local keys = {}
UserInputService.InputBegan:Connect(function(key)
    keys[key.KeyCode] = true 
end)

UserInputService.InputEnded:Connect(function(key)
    keys[key.KeyCode] = false 
end)

local function fly()
    local FowardBack = (keys[Enum.KeyCode.W] and 1 or 0) + (keys[Enum.KeyCode.S] and -1 or 0)
    local LeftRight = (keys[Enum.KeyCode.A] and -1 or 0) + (keys[Enum.KeyCode.D] and 1 or 0)

    local CurrentCameraCFrame = workspace.CurrentCamera.CFrame
    local velocity = (CurrentCameraCFrame.rightVector * LeftRight + CurrentCameraCFrame.lookVector * FowardBack) * Settings.FlightSpeed
    
    removeVelocity = Hitbox.hitboxVelocity.Velocity * -1
    JoltFunction:Fire(removeVelocity)
    JoltFunction:Fire(velocity)
    Hitbox.Velocity = velocity
end

local CollectedAllChests = false 
local function Chestfarm() 
    for Index, Value in next, chests do 
        while not Value:FindFirstChild("chestBillboard") do 
            RunService.Heartbeat:wait()
            Hitbox.CFrame = Value.PrimaryPart.CFrame * CFrame.new(math.random(1, 4), math.random(1, 4), math.random(1, 4)) --  this could work? 
            wait(0.2)
            PlayerRequest:InvokeServer("openTreasureChest", Value.Parent)
        end
    end
    if not CollectedAllChests then 
        CollectedAllChests = true 
        chat("Collected all chests!",Color3.new(0,1,0))
    end
end

while RunService.Heartbeat:Wait() do
    if Settings.Autofarm or Settings.KillAura then 
        local Closest = GetClosest(Settings.AttackPlayers)

        if Closest then 
            Attack(Closest,Settings.AttackPlayers)   
        end 
        if Settings.UseSmallestServer then 
            UseSmallestServer()
        end
    end 

    if not Settings.Autofarm and Settings.Chestfarm then 
        Chestfarm()
    end

    if Settings.AutoPickup then 
        coroutine.wrap(AutoPickup)()
    end

    if Settings.Autofish then 
        AutoFish()
    end

    if Settings.Flight and not Settings.Bypass then 
        fly()
    end
end