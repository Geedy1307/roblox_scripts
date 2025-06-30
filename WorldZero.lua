repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.CoreGui
repeat task.wait() until game:GetService('Players').LocalPlayer


game.CoreGui.RobloxPromptGui.promptOverlay.DescendantAdded:Connect(function()
    local GUI = game.CoreGui.RobloxPromptGui.promptOverlay:FindFirstChild('ErrorPrompt')
    if GUI then
        local Reason = GUI.TitleFrame.ErrorTitle.Text
        if Reason == 'Disconnected' or Reason:find('Server Kick') or Reason:find('GameEnded') or Reason:find('Teleport Failed') then
            warn("Kicked Reason: "..Reason)

            game:GetService("TeleportService"):Teleport(2727067538)

            while task.wait(5) do
                game:GetService("TeleportService"):Teleport(2727067538)
            end
        end
    end
end)

--- // Save Settings // ---
local FileName = 'worldzero(ID_'..game.Players.LocalPlayer.UserId..').json'
local DefaultSettings = {
    ['DungeonID'] = 1,
    ['DifficultyID'] = 1,
    ['FarmDailyQuest'] = true,
    ['FarmWorldQuest'] = true,
    ['FarmGuildDungeon'] = false,
    ['RestartDungeon'] = true,
    ['StartFarm'] = false,
    ['KillAura'] = false,
    ['PickUp'] = false,
    ['SellTier1'] = true,
    ['SellTier2'] = true,
    ['SellTier3'] = true,
    ['SellTier4'] = true,
    ['SellEgg'] = true,
    ['AutoEquip'] = false,
    ['AutoSell'] = false,
    ['Perks'] = {
        BonusHP = {["name"] = "HP UP",
            ["min"] = 5,
            ["max"] = 12,
            ["current"] = 5
        },
        DodgeChance = {["name"] = "Untouchable",
            ["min"] = 5,
            ["max"] = 20,
            ["current"] = 5
        },
        DamageReduction = {["name"] = "Damage Reduction",
            ["min"] = 2,
            ["max"] = 8,
            ["current"] = 2
        },
        BonusAttack = {["name"] = "Attack UP",
            ["min"] = 2,
            ["max"] = 8,
            ["current"] = 2
        },
        CritStack = {["name"] = "Crit Stack",
            ["min"] = 5,
            ["max"] = 15,
            ["current"] = 5
        },
        LifeDrain = {["name"] = "Life Drain",
            ["min"] = 2,
            ["max"] = 6,
            ["current"] = 2
        },
        TestTier5 = {["name"] = "Boss of the Boss",
            ["min"] = 10,
            ["max"] = 30,
            ["current"] = 10
        },
        MobBoss = {["name"] = "Mob Boss",
            ["min"] = 10,
            ["max"] = 30,
            ["current"] = 10
        },
        Glass = {["name"] = "Glass",
            ["min"] = 30,
            ["max"] = 100,
            ["current"] = 30
        },
    }
}
if not pcall(function() readfile(FileName) end) then writefile(FileName, game:GetService('HttpService'):JSONEncode(DefaultSettings)) end
local Settings = game:GetService('HttpService'):JSONDecode(readfile(FileName))
function Save() writefile(FileName, game:GetService('HttpService'):JSONEncode(Settings)) end

--- // UI Library // ---
local Lib = loadstring(game:HttpGet('https://raw.githubusercontent.com/hoangsalty/roblox/main/scripts/Materials/UISource/Vision_Lib.lua'))()
Window = Lib:Create({
	Name = "World//Zero",
	Footer = "By Jank",
	ToggleKey = Enum.KeyCode.RightControl,
	ToggledRelativeYOffset = 0,
    LoadedCallback = function()
		Window:TaskBarOnly(true)
	end
})

if game.PlaceId == 2727067538 then
    repeat task.wait() until game.ReplicatedStorage:FindFirstChild('ProfileCollections') and game.ReplicatedStorage.ProfileCollections:FindFirstChild(game.Players.LocalPlayer.Name)

    if Settings['StartFarm'] then
        Lib:Notify({Name = "Notification",Icon = "rbxassetid://11401835376",Duration = 3,
			Text = "Joining the game...",
		})

        while task.wait(2) do
            game.ReplicatedStorage.Shared.Teleport.JoinGame:FireServer(game.ReplicatedStorage.ProfileCollections[game.Players.LocalPlayer.Name].LastProfile.Value)
        end
    else
        Lib:Notify({Name = "Notification",Icon = "rbxassetid://11401835376",Duration = 3,
            Text = "Please join the game in order to use all function",
        })
    end

    return
end

repeat task.wait() until workspace:FindFirstChild('Characters') and workspace.Characters:FindFirstChild(game.Players.LocalPlayer.Name)
repeat task.wait() until game.Players.LocalPlayer.Character
repeat task.wait() until game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild('HumanoidRootPart')

--- // Variables // ---
local Client = game.Players.LocalPlayer
local Character = Client.Character or Client.Character:Wait()
local Client_Root = Character:WaitForChild('HumanoidRootPart')
local Client_Profile = game.ReplicatedStorage.Profiles:WaitForChild(Client.Name)
local Client_Level = Client_Profile:WaitForChild('Level') and Client_Profile.Level.Value
local Client_Class = Client_Profile:WaitForChild('Class') and Client_Profile.Class.Value
local InDungeon = require(game.ReplicatedStorage.Shared.Missions):IsMissionPlace()
local CurrentWorld = require(game.ReplicatedStorage.Shared.Teleport):GetCurrentWorldData().WorldOrderID

local AtkType = {['Primary']= {},['Skill1']= {},['Skill2']= {},['Skill3']= {},['Ultimate']= {},}
local ET_Delay = 0.05
local KA_Delay = {
    ['Mage']        = {0.35, 5, 8, 0, 0},
    ['Swordmaster'] = {0.4, 5, 8, 0, 0},
    ['Defender']    = {0.4, 5, 8, 0, 0},

    ['IcefireMage'] = {0.4, 6, 10, 15, 30},
    ['DualWielder'] = {0.5, 0, 6, 8, 30},
    ['Guardian']    = {0.75, 0, 6, 8, 30},

    ['MageOfLight'] = {0.1, 0, 0, 0, 0},
    ['Berserker']   = {0.35, 5, 5, 5, 20},
    ['Paladin']     = {0.3, 2, 0, 11, 0},

    ['Demon']       = {2, 0, 5, 9, 25},
    ['Dragoon']     = {0.45, 6, 6, 8, 20},
    ['Archer']      = {0.3, 5, 10, 10, 20},

    --[[ ['Summoner']    = {1, 0, 0, 10, 0}, ]]
    ['Warlord']     = {0.3, 5, 3, 5, 15},
    ['Assassin']    = {0.2, 0, 2, 4, 15},
}

function IsAlive(target)
    return target:FindFirstChild('HealthProperties') and target.HealthProperties:FindFirstChild('Health') and target.HealthProperties.Health.Value > 0
end

Client.CameraMaxZoomDistance = 500    
Client.CharacterAdded:Connect(function(Character)
    Character = Character
    Client_Root = Character:WaitForChild('HumanoidRootPart')
end)

for i,v in next, getconnections(game:GetService("Players").LocalPlayer.Idled) do
    v:Disable()
end

--Semi-god
local dangerTable = {} do
    for i,v in next, game.ReplicatedStorage.Shared.Mobs.Mobs:GetDescendants() do
        if v:IsA('RemoteEvent') then
            table.insert(dangerTable, v)
        end
    end

    local old_namecall
    old_namecall = hookmetamethod(game, '__namecall', function(self, ...)
        if getnamecallmethod() == 'FireServer' and table.find(dangerTable, self) then
            return
        end

        return old_namecall(self, ...)
    end)
end

--Block Inputs
local old_useskill = require(game.ReplicatedStorage.Client.Actions).UseSkill
require(game.ReplicatedStorage.Client.Actions).UseSkill = function(self, ...)
    if Settings['KillAura'] then
        return
    end
    
    return old_useskill(self, ...)
end

function Refill(class)
    if class == 'Mage' then
        table.insert(AtkType['Primary'], 'Mage1')
        
        table.insert(AtkType['Skill1'], 'ArcaneBlast')
        table.insert(AtkType['Skill1'], 'ArcaneBlastAOE')
    
        for i=1,12 do
            table.insert(AtkType['Skill2'], 'ArcaneWave'..i)
        end
    elseif class == 'Swordmaster' then
        for i=1,6 do
            table.insert(AtkType['Primary'], 'Swordmaster'..i)
        end
    
        for i=1,2 do
            table.insert(AtkType['Skill1'], 'CrescentStrike'..i)
        end
    
        table.insert(AtkType['Skill2'], 'Leap')
    elseif class == 'Defender' then
        for i=1,5 do
            table.insert(AtkType['Primary'], 'Defender'..i)
        end
    
        table.insert(AtkType['Skill1'], 'Groundbreaker')
    
        for i=1,4 do
            table.insert(AtkType['Skill2'], 'Spin'..i)
        end
    elseif class == 'IcefireMage' then
        table.insert(AtkType['Primary'], 'IcefireMage1')
        
        for i=1,5 do
            table.insert(AtkType['Skill1'], 'IcySpikes'..i)
        end
    
        table.insert(AtkType['Skill2'], 'IcefireMageFireballBlast')
        table.insert(AtkType['Skill2'], 'IcefireMageFireball')
    
        table.insert(AtkType['Skill3'], 'LightningStrike')
    
        table.insert(AtkType['Ultimate'], 'IcefireMageUltimateFrost')
        for i=1,10 do
            table.insert(AtkType['Ultimate'], 'IcefireMageUltimateMeteor'..i)
        end
    elseif class == 'DualWielder' then
        for i=1,10 do
            table.insert(AtkType['Primary'], 'DualWield'..i)
        end
    
        table.insert(AtkType['Skill2'], 'DashStrike')
    
        for i=1,4 do
            table.insert(AtkType['Skill3'], 'CrossSlash'..i)
        end
    
        for i=1,12 do
            table.insert(AtkType['Ultimate'], 'DualWieldUltimateSword'..i)
            table.insert(AtkType['Ultimate'], 'DualWieldUltimateHit'..i)
        end
        table.insert(AtkType['Ultimate'], 'DualWieldUltimateSlam')
        for i=1,3 do
            table.insert(AtkType['Ultimate'], 'DualWieldUltimateSlam'..i)
        end
    elseif class == 'Guardian' then
        for i=1,4 do
            table.insert(AtkType['Primary'], 'Guardian'..i)
        end
    
        for i=1,5 do
            table.insert(AtkType['Skill2'], 'RockSpikes'..i)
        end
    
        for i=1,15 do
            table.insert(AtkType['Skill3'], 'SlashFury'..i)
        end
    
        for i=1,12 do
            table.insert(AtkType['Ultimate'], 'SwordPrison'..i)
        end
    elseif class == 'MageOfLight' then
        table.insert(AtkType['Primary'], 'MageOfLight')
        table.insert(AtkType['Primary'], 'MageOfLightBlast')
        table.insert(AtkType['Primary'], 'MageOfLightCharged')
        table.insert(AtkType['Primary'], 'MageOfLightBlastCharged')
    elseif class == 'Berserker' then
        for i=1,6 do
            table.insert(AtkType['Primary'], 'Berserker'..i)
        end
    
        table.insert(AtkType['Skill1'], 'AggroSlam')
    
        for i=1,8 do
            table.insert(AtkType['Skill2'], 'GigaSpin'..i)
        end
    
        for i=1,2 do
            table.insert(AtkType['Skill3'], 'Fissure'..i)
        end
    elseif class == 'Paladin' then  
        for i=1,4 do
            table.insert(AtkType['Primary'], 'Paladin'..i)
            table.insert(AtkType['Primary'], 'LightPaladin'..i)
        end
    
        table.insert(AtkType['Skill1'], 'Block')
    
        for i=1,2 do
            table.insert(AtkType['Skill3'], 'LightThrust'..i)
        end
    elseif class == 'Demon' then
        for i=1,9 do
            table.insert(AtkType['Primary'], 'DemonDPS'..i)
        end
    
        for i=1,3 do
            table.insert(AtkType['Skill2'], 'ScytheThrow'..i)
            table.insert(AtkType['Skill2'], 'ScytheThrowDPS'..i)
        end
    
        table.insert(AtkType['Skill3'], 'DemonLifeStealDPS')

        for i=1,3 do
            table.insert(AtkType['Ultimate'], 'DemonSoulDPS'..i)
        end
    elseif class == 'Dragoon' then
        for i=1,6 do
            table.insert(AtkType['Primary'], 'Dragoon'..i)
        end
    
        table.insert(AtkType['Skill1'], 'DragoonDash')
        for i=1,10 do
            table.insert(AtkType['Skill1'], 'DragoonCross'..i)
        end
    
        for i=1,5 do
            table.insert(AtkType['Skill2'], 'MultiStrike'..i)
        end
    
        table.insert(AtkType['Skill3'], 'DragoonFall')
    
        table.insert(AtkType['Ultimate'], 'DragoonUltimate')
        for i=1,7 do
            table.insert(AtkType['Ultimate'], 'UltimateDragon'..i)
        end
    elseif class == 'Archer' then
        table.insert(AtkType['Primary'], 'Archer')
        
        for i=1,9 do
            table.insert(AtkType['Skill1'], 'PiercingArrow'..i)
        end
    
        table.insert(AtkType['Skill2'], 'SpiritBomb')
    
        for i=1,5 do
            table.insert(AtkType['Skill3'], 'MortarStrike'..i)
        end
    
        for i=1,6 do
            table.insert(AtkType['Ultimate'], 'HeavenlySword'..i)
        end
    elseif class == 'Summoner' then
        --[[ for i=1,4 do
            table.insert(AtkType['Primary'], 'Summoner'..i)
        end

        for i=1,5 do
            table.insert(AtkType['Skill3'], 'SoulHarvest'..i)
        end ]]
    elseif class == 'Warlord' then
        for i=1,4 do
            table.insert(AtkType['Primary'], 'Warlord'..i)
        end

        for i=1,3 do
            table.insert(AtkType['Skill1'], 'Piledriver'..i)
        end

        table.insert(AtkType['Skill2'], 'BlockingWarlord')

        table.insert(AtkType['Skill3'], 'ChainsOfWar')

        for i=1,4 do
            table.insert(AtkType['Ultimate'], 'WarlordUltimate'..i)
        end
    elseif class == 'Assassin' then
        for i=1,8 do
            table.insert(AtkType['Primary'], 'Assassin'..i)
        end

        table.insert(AtkType['Skill2'], 'ShadowLeap')

        for i=1,4 do
            table.insert(AtkType['Skill3'], 'ShadowSlash'..i)
        end

        table.insert(AtkType['Ultimate'], 'RealmOfShadows')
        for i=1,5 do
            table.insert(AtkType['Ultimate'], 'ShadowMulti'..i)
        end
    end
end
while task.wait() do
    Refill(Client_Class)
    if(#AtkType['Primary'] > 0) then break end
end
Client_Profile:WaitForChild('Class').Changed:connect(function(class)
    AtkType['Primary'] = {}
    AtkType['Skill1'] = {}
    AtkType['Skill2'] = {}
    AtkType['Skill3'] = {}
    AtkType['Ultimate'] = {}
    task.wait(0.5)
    Refill(class)
end)


--Clear death mobs
if workspace:FindFirstChild('Mobs') then
    task.defer(function()
        while task.wait() do
            for i,v in next, workspace.Mobs:GetChildren() do
                if v:FindFirstChild('Collider') and not IsAlive(v) then
                    v:Destroy()
                end
            end

            for i,v in next, workspace:GetChildren() do
                if v.Name == 'FireBase' and not v:FindFirstChildWhichIsA('ParticleEmitter') then
                    v:Destroy()
                end
            end
        end
    end)
end

local blacklist = {
    6510862058,
    4050468028,
    4646473427,
    5862277651, --- Halloween Event
}
local bossPos
if workspace:FindFirstChild('Mobs') then
    workspace.Mobs.ChildAdded:Connect(function(mob)
        if not mob.Name:find('#') and mob:FindFirstChild('Collider') and mob.MobProperties:FindFirstChild('CurrentAttack') then
            if not table.find(blacklist, game.PlaceId) and require(game.ReplicatedStorage.Shared.Mobs.Mobs[mob.Name]).BossTag ~= false then
                bossPos = mob.Collider.Position.Y
            end
        end
    end)
end

--- // Auto Farm // ---
local AutoFarm = Window:Tab({Name = "AutoFarm", Icon = "rbxassetid://11396131982", Color = Color3.new(1, 0, 0)})
local AF_SectionDebug = AutoFarm:Section({Name = "Debug"})
local AFDebug = AF_SectionDebug:Label({
	Name = "",
})

local AF_Section1 = AutoFarm:Section({Name = "Selection"}) do
    function Get_Missions()
        local ListMissions = {}

        for i,v in next, require(game.ReplicatedStorage.Shared.Missions):GetDungeonsFromWorldID(CurrentWorld, true) do
            if v.ShowOnProduction and v.ShowOnProduction == true then
                if v.ID == 17 then
                    v.NameTag = 'Holiday Event'
                elseif v.ID == 22 then
                    v.NameTag = 'Halloween Event'
                end

                if v.ID ~= 17 and v.ID ~= 22 then
                    table.insert(ListMissions, v)
                end
            end
        end

        for i,v in next, require(game.ReplicatedStorage.Shared.Missions.MissionData) do
            if v.DailyDungeon and v.DailyDungeon == true then
                table.insert(ListMissions, v)
            end
        end

    
        table.sort(ListMissions, function(a,b)
            return a.LevelRequirement < b.LevelRequirement
        end)
    
        return ListMissions
    end
    
    function Missions_List()
        local stringtable = {}
        for i,v in next, Get_Missions() do
            table.insert(stringtable, {v.NameTag..' (Lvl '..v.LevelRequirement..'+)', v.ID})
        end
    
        return stringtable
    end
    
    function Mission_Name(id_dungeon)
        for i,v in next, Get_Missions() do
            if v.ID == id_dungeon then
                return tostring(v.NameTag..' (Lvl '..v.LevelRequirement..'+)')
            end
        end

        Settings['DungeonID'] = Get_Missions()[1].ID
        Save()
        return tostring(Get_Missions()[1].NameTag..' (Lvl '..Get_Missions()[1].LevelRequirement..'+)')
    end

    function Diff_Default(id)
        local List = {
            {['id'] = 1, ['nameTag'] = 'NORMAL'},
            {['id'] = 5, ['nameTag'] = 'NIGHTMARE'},
        }

        for i,v in next, List do
            if id == v.id then
                return v.nameTag
            end
        end
    end

    local Dungeon_Selection, Difficulty_Selection do
        Dungeon_Selection = AF_Section1:Dropdown({Name = "Dungeons Selection",
            Items = Missions_List(),
            Default = Mission_Name(Settings['DungeonID']),
            Callback = function(item)
                Settings['DungeonID'] = item
                Save()
            end
        })

        Difficulty_Selection = AF_Section1:Dropdown({Name = "Difficulties Selection",
            Items = {{'NORMAL',1}, {'NIGHTMARE',5}},
            Default = Diff_Default(Settings['DifficultyID']),
            Callback = function(item)
                Settings['DifficultyID'] = item
                Save()
            end
        })
    end
end

local AF_Section2 = AutoFarm:Section({Name = "Extra Farm"}) do
    AF_Section2:Toggle({Name = "Daily Quests",
        Default = Settings['FarmDailyQuest'],
        Callback = function(state) 
            Settings['FarmDailyQuest'] = state
            Save()
    end})

    AF_Section2:Toggle({Name = "World Quests",
        Default = Settings['FarmWorldQuest'],
        Callback = function(state) 
            Settings['FarmWorldQuest'] = state
            Save()
    end})

    AF_Section2:Toggle({Name = "Guild Dungeons",
        Default = Settings['FarmGuildDungeon'],
        Callback = function(state) 
            Settings['FarmGuildDungeon'] = state
            Save()
    end})

    AF_Section2:Toggle({Name = "Restart Dungeon",
        Default = Settings['RestartDungeon'],
        Callback = function(state) 
            Settings['RestartDungeon'] = state
            Save()
    end})
end
local AF_Section3 = AutoFarm:Section({Name = "Action"}) do
    AF_Section3:Toggle({Name = "Start",
        Default = Settings['StartFarm'],
        Callback = function(state) 
            Settings['StartFarm'] = state
            Save()

            if not Settings['StartFarm'] then
                if Client_Root:FindFirstChild('NoClip') then
                    Client_Root.CFrame = Client_Root.CFrame + Vector3.new(0,20,0)
                    task.wait(0.3)
                    Client_Root.CanCollide = true
                    Client_Root.NoClip:Destroy()
                end
            else
                local TP_Angle = 0
                function TweenTP(target, height)
                    if target then
                        local speed = 150
                        if InDungeon then
                            speed = 1500
                        end

                        if not Client_Root:FindFirstChild('NoClip') then
                            local bv = Instance.new('BodyVelocity')
                            bv.Name = 'NoClip'
                            bv.Parent = Client_Root
                            bv.MaxForce = Vector3.new(0,math.huge,0)
                            bv.Velocity = Vector3.new(0,0,0)
                            Client_Root.CanCollide = false
                        end
                
                        repeat task.wait()
                            if not target then break end
                            
                            local speed = (speed*task.wait()) -- distance traveled between elapsed time
                            local distance = (Client_Root.Position - target.Position).magnitude
                            local estimatedTime = speed / distance -- obtain a lerp fraction between distance traveled in a frame divided by the overall distance towards the goal
                            local adjustedLerpAlpha = math.min(estimatedTime, 1) -- prevent the lerp from going over 1 which is over the lerp goal

                            Client_Root.CFrame = Client_Root.CFrame:lerp(target.CFrame + Vector3.new(10*math.cos(TP_Angle), height, 10*math.sin(TP_Angle)), adjustedLerpAlpha) -- lerps the position values at constant speed
                            Client_Root.CFrame = CFrame.lookAt(Client_Root.Position, Vector3.new(target.Position.X, Client_Root.Position.Y, target.Position.Z))
                            if (Client_Root.Position - target.Position).magnitude < 30 then
                                TP_Angle += math.rad(3)
                            end
                        until not target or not IsAlive(target)
                    end
                end

                function Quest_Finished(QuestID)
                    return require(game.ReplicatedStorage.Shared.Quests):QuestCompleted(Client, QuestID)
                end

                function Can_Access_Dungeon(DungeonID)
                    local canAccess, typeAccess = require(game.ReplicatedStorage.Shared.Missions):CanAccessMission(Client, DungeonID, 1)
                    return canAccess
                end
                
                function Quests_Left(QuestType)
                    local count = 0
                    for i,v in next, require(game.ReplicatedStorage.Shared.Quests.QuestList) do
                        if not Quest_Finished(i) then
                            if QuestType == 'daily' then
                                local DailyQuests = Client_Profile.DailyQuests
                                local Slot1 = DailyQuests.Slot1Quest.Value
                                local Slot2 = DailyQuests.Slot2Quest.Value
                                local Slot3 = DailyQuests.Slot3Quest.Value
                                if v.DailyQuest and (v.ID == Slot1 or v.ID == Slot2 or v.ID == Slot3) then
                                    count += 1
                                end
                            elseif QuestType == 'world' then
                                if v.WorldQuest and not v.Name:find('teleporter') and (v.Disabled == nil or (v.Disabled ~= nil and v.Disabled == false)) then
                                    count += 1
                                end
                            end
                        end
                    end
                
                    return count
                end
                
                function Get_Quests(QuestType)
                    local minWorld = math.huge
                    local data = nil
                
                    for i,v in next, require(game.ReplicatedStorage.Shared.Quests.QuestList) do
                        if not Quest_Finished(i) then
                            if QuestType == 'daily' then
                                local DailyQuests = Client_Profile.DailyQuests
                                local Slot1 = DailyQuests.Slot1Quest.Value
                                local Slot2 = DailyQuests.Slot2Quest.Value
                                local Slot3 = DailyQuests.Slot3Quest.Value
                                if v.DailyQuest and (v.ID == Slot1 or v.ID == Slot2 or v.ID == Slot3) then
                                    if v.LinkedWorld < minWorld then
                                        minWorld = v.LinkedWorld
                                        data = v
                                    end
                                end
                            elseif QuestType == 'world' then
                                if v.WorldQuest and not v.Name:find('teleporter') and (v.Disabled == nil or (v.Disabled ~= nil and v.Disabled == false)) then
                                    if v.LinkedWorld < minWorld then
                                        minWorld = v.LinkedWorld
                                        data = v
                                    end
                                end
                            end
                        end
                    end

                    return data
                end
                
                function Farm_Dungeon()
                    if not Client_Root:FindFirstChild('NoClip') then
                        local bv = Instance.new('BodyVelocity')
                        bv.Name = "NoClip"
                        bv.Parent = Client_Root
                        bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
                        bv.Velocity = Vector3.new()
                        Client_Root.CanCollide = false
                    end

                    function Get_Object()
                        for i,v in next, workspace:GetChildren() do
                            if (v.Name:find('Pillar') or v.Name == 'Gate' or v.Name == 'TriggerBarrel') and v.PrimaryPart and IsAlive(v) then
                                return v
                            elseif v.Name == 'FearNukes' then
                                for i1,v1 in next, v:GetChildren() do
                                    if v1.PrimaryPart and IsAlive(v1) then
                                        return v1
                                    end
                                end
                            end
                        end
                
                        if workspace:FindFirstChild('MissionObjects') then
                            for i,v in next, workspace.MissionObjects:GetChildren() do
                                if v.Name == 'IceBarricade' and v.PrimaryPart and IsAlive(v) then
                                    return v
                                elseif v.Name == 'SpikeCheckpoints' or v.Name == 'TowerLegs' then
                                    for i1,v1 in next, v:GetChildren() do
                                        if v1.PrimaryPart and IsAlive(v1) then
                                            return v1
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    function Get_Target(type)
                        local closest = nil
                        local closestDistance = math.huge
                
                        for i,v in next, workspace.Mobs:GetChildren() do
                            if not v.Name:find('#') and not v.Name:find('SummonerSummon') and not v:FindFirstChild('NoHealthbar') and v:FindFirstChild('Collider') then
                                if IsAlive(v) then
                                    if type == 'mob' and require(game.ReplicatedStorage.Shared.Mobs.Mobs[v.Name]).BossTag == false then
                                        local currentDistance = (Client_Root.Position - v.Collider.Position).magnitude
                                        if currentDistance < closestDistance then
                                            closest = v
                                            closestDistance = currentDistance
                                        end
                                    elseif type == 'boss' and require(game.ReplicatedStorage.Shared.Mobs.Mobs[v.Name]).BossTag ~= false then
                                        local AvoidPos = {'DireCaveSpawn',}
                                        local CurrentPos = v:FindFirstChild("FromSpawnPart") and tostring(v.FromSpawnPart.Value)
                                        if not table.find(AvoidPos, CurrentPos) then
                                            closest = v
                                        end
                                    end
                                end
                            end
                        end
                
                        return closest
                    end
                
                    function Sub_Object()
                        for i,v in next, workspace:GetChildren() do
                            if v.Name == 'IceWall' and v:FindFirstChild('Ring') then
                                return v.Ring
                            elseif v.Name == 'CureFountainFallenKing' and v:FindFirstChild('ArcanePanel') and tostring(Get_Target('boss').MobProperties.CurrentAttack.Value) == "Rage" then
                                return v.ArcanePanel
                            end
                        end
                
                        if workspace:FindFirstChild('MissionObjects') and workspace.MissionObjects:FindFirstChild('IgnisShield') then
                            local shield = workspace.MissionObjects:FindFirstChild('IgnisShield')
                            if shield:FindFirstChild("Ring") and shield.Ring.Transparency == 0 then
                                return shield.Ring
                            end
                        end
                    end
                
                    function Dodge_Alert()
                        local HurtfulSkills = {
                            'Slap','Sweep','Piledriver',
                            'BreathFire','FireBreath','Flamethrower',
                            'Attack1Fall','Attack2Fall',
                            'FireWall','Powerslash',
                            'DownwardIceFire','Attack1',
                            "Attack3",
                        }
                
                        for i,v in next, workspace.Mobs:GetChildren() do
                            if not v.Name:find('#') and v:FindFirstChild('Collider') and v:FindFirstChild('MobProperties') and v.MobProperties:FindFirstChild('CurrentAttack') and IsAlive(v) then
                                if (v.Collider.Position - Client_Root.Position).magnitude <= 50 then
                                    if table.find(HurtfulSkills, tostring(v.MobProperties.CurrentAttack.Value)) then
                                        return true
                                    end
                                end
                            end
                        end
                        
                        if workspace:FindFirstChild('FireBase') and workspace.FireBase:FindFirstChildWhichIsA('ParticleEmitter') then
                            return true
                        end
                
                        return false
                    end
                
                    function Avoid_Indicator_Mob()
                        if workspace:FindFirstChild('RadialIndicator') then
                            if workspace:FindFirstChild('DireDeathballPink')  then
                                return true
                            elseif workspace:FindFirstChild("FirePanelPurple") then
                                return true
                            end
                        end
                
                        return false
                    end
                
                    local object = Get_Object()
                    local mob = Get_Target('mob')
                    local boss = Get_Target('boss')

                    local focusMobFirst = {
                        3383444582, -- 1-4
                        6386112652, -- 5-1
                        5862277651, -- Halloween Event
                        6510862058, -- 6-1
                        11533444995, -- 6-2
                        4646475570, -- 4-3
                    }

                    if object then
                        AFDebug:SetName('Attacking: Object')
                        TweenTP(object.PrimaryPart, 0)
                    else
                        if mob then
                            repeat task.wait()
                                if (Get_Object()
                                    or not mob:FindFirstChild('Collider')
                                    or Client.PlayerGui.MissionRewards.MissionRewards.Visible) then
                                    break
                                end
                                
                                mob = Get_Target('mob')

                                local mob_name = require(game.ReplicatedStorage.Shared.Mobs.Mobs[mob.Name])['NameTag']
                                AFDebug:SetName('Attacking: '..tostring(mob_name))
                                
                                if require(game.ReplicatedStorage.Shared.Health):GetHealth(Character) < (require(game.ReplicatedStorage.Shared.Health):GetMaxHealth(Character)/2.5) then
                                    AFDebug:SetName('Healing...')
                                    TweenTP(mob.Collider, 100)
                                    repeat task.wait() until require(game.ReplicatedStorage.Shared.Health):GetHealth(Character) == require(game.ReplicatedStorage.Shared.Health):GetMaxHealth(Character)
                                end
                                if not mob:FindFirstChild('Collider') then break end

                                if Avoid_Indicator_Mob() then
                                    TweenTP(mob.Collider, 50)
                                else
                                    TweenTP(mob.Collider, 0)
                                end
                            until not mob or not Settings['StartFarm']
                            if game.PlaceId == 6386112652 and Get_Target('boss') then -- Dungeon 5-1
                                Client_Root.CFrame = Client_Root.CFrame + Vector3.new(0,50,0)
                            end
                        else
                            if boss then
                                repeat task.wait()
                                    if (Get_Object()
                                        or (Get_Target('mob') and table.find(focusMobFirst, game.PlaceId))
                                        or not boss.Parent
                                        or not boss:FindFirstChild('Collider')
                                        or (bossPos ~= nil and boss.Collider.Position.Y < bossPos - 100)
                                        or boss.MobProperties.Busy:FindFirstChild('Before')
                                        or workspace:FindFirstChild('GreaterTreeShield')
                                        or Client.PlayerGui.MissionRewards.MissionRewards.Visible) then
                                        break
                                    end
                                
                                    boss = Get_Target('boss')

                                    if not boss.Name:find('Zeus') then
                                        boss.Collider.CanCollide = false
                                    end
                
                                    if boss.Name:find('Kraken') then
                                        Client_Root.CFrame = boss.Collider.CFrame + Vector3.new(-10,-10,0)
                                    else
                                        if Sub_Object() then
                                            TweenTP(Sub_Object(), 5)
                                        else
                                            local boss_name = require(game.ReplicatedStorage.Shared.Mobs.Mobs[boss.Name])['NameTag']
                                            AFDebug:SetName('Attacking: '..tostring(boss_name))
            
                                            if boss.Name == 'BOSSAnubis' then -- Dungeon 4-3
                                                if (Client_Root.Position - boss.Collider.Position).magnitude > 100 then
                                                    Client_Root.CFrame = CFrame.new(-4904.49609375, 394.85925292969, -367.76528930664)
                                                    repeat task.wait() until boss:FindFirstChild('Collider') and (Client_Root.Position - boss.Collider.Position).magnitude <= 100
                                                end
                                            elseif boss.Name == 'Hades' then -- Dungeon 7-1
                                                if (Client_Root.Position - boss.Collider.Position).magnitude > 100 then
                                                    Client_Root.CFrame = CFrame.new(268.559814453125, 339.5906677246094, -620.95166015625)
                                                    repeat task.wait() until boss:FindFirstChild('Collider') and (Client_Root.Position - boss.Collider.Position).magnitude <= 100
                                                end
                                            elseif game.PlaceId == 4050468028 then -- Halloween
                                                if not Client.PlayerGui.BossHealthbar.BossHealthbar.Panels:FindFirstChild('Panel') then
                                                    Client_Root.CFrame = boss.Collider.CFrame + Vector3.new(0,55,0)
                                                    task.wait(3)
                                                end
                                            end

                                            local OneShotSkills = {'Thunderstorm','Shockwave','DarkOrbAttack','IceBeam','PillarSmash','Rage','Aoe',}
                                            local BossCurrentAttack = boss:FindFirstChild('MobProperties') and tostring(boss.MobProperties.CurrentAttack.Value)
                                            if table.find(OneShotSkills, BossCurrentAttack) then
                                                TweenTP(boss.Collider, 50)
                                            else                                                
                                                if require(game.ReplicatedStorage.Shared.Health):GetHealth(Character) < (require(game.ReplicatedStorage.Shared.Health):GetMaxHealth(Character)/2.5) then
                                                    AFDebug:SetName('Healing...')
                                                    TweenTP(boss.Collider, 100)
                                                    repeat task.wait() until require(game.ReplicatedStorage.Shared.Health):GetHealth(Character) == require(game.ReplicatedStorage.Shared.Health):GetMaxHealth(Character)
                                                end
                                                if not boss:FindFirstChild('Collider') then break end
                                                TweenTP(boss.Collider, 0)
                                            end
                                        end
                                    end
                                until not boss or not Settings['StartFarm']
                            end
                        end
                    end
                end

                function Farm_OpenWorld(target)
                    function Get_Mob()
                        local closest, closestDistance = nil, math.huge
                
                        for i,v in next, workspace.Mobs:GetChildren() do
                            if type(target) == 'table' and table.find(target, v.Name) and v:IsA('Model') and not v:FindFirstChild('NoHealthbar') and v:FindFirstChild('Collider') then
                                --[[ local IsMob = require(game.ReplicatedStorage.Shared.Mobs.Mobs[v.Name]).BossTag == false ]]
                                
                                if IsAlive(v) then
                                    local currentDistance = (Client_Root.Position - v.Collider.Position).magnitude
                                    if currentDistance < closestDistance then
                                        closest = v
                                        closestDistance = currentDistance
                                    end
                                end
                            end
                        end
                        
                        return closest
                    end
                    
                    function Get_WorldBoss()
                        for i,v in next, workspace.Mobs:GetChildren() do
                            if target == nil and v:FindFirstChild('Collider') and v:FindFirstChild('BossTag') and IsAlive(v) then
                                return v
                            end
                        end
                    end
                
                    function Get_Spawn()
                        if workspace:FindFirstChild('MobAreas') then
                            for i,v in next, workspace.MobAreas:GetChildren() do
                                if type(target) == 'table' and v:IsA('Part') and v:FindFirstChild('MobName') and table.find(target, v.MobName.Value) then
                                    return v
                                end
                            end
                        end
                    end
                
                    function Get_Flag()
                        for i,v in next, workspace:GetChildren() do
                            if target == nil and v:IsA('Folder') and v:FindFirstChild('BossSpawns') and v:FindFirstChild('Flag') then
                                return v
                            end
                        end
                    end
                
                    local bossFlag = Get_Flag()
                    local worldBoss = Get_WorldBoss()
                    local mob = Get_Mob()
                    local mobSpawn = Get_Spawn()
                
                    if bossFlag then
                        game.ReplicatedStorage.Shared.WorldEvents.TeleportToEvent:FireServer(bossFlag.Name)
                        if Client_Root:FindFirstChild('NoClip') then
                            Client_Root.CanCollide = true
                            Client_Root.NoClip:Destroy()
                        end

                        repeat task.wait() until Get_WorldBoss()
                    else
                        if worldBoss then
                            repeat task.wait()
                                if not worldBoss:FindFirstChild('Collider') or not IsAlive(worldBoss) then break end
                                TweenTP(worldBoss.Collider, 0)
                            until not worldBoss or not Settings['StartFarm']
                        else
                            if mob then
                                repeat task.wait()
                                    if not mob:FindFirstChild('Collider') or not IsAlive(mob) then break end
                                    mob = Get_Mob()
                                    TweenTP(mob.Collider, -10)
                                until not mob or not Settings['StartFarm']
                            else
                                if mobSpawn then
                                    repeat task.wait()
                                        TweenTP(mobSpawn, -100)
                                    until Get_Mob() or Get_WorldBoss() or Get_Flag() or not Settings['StartFarm']
                                else
                                    if workspace:FindFirstChild('Waystones') then
                                        local oldwaystone = nil
                                        for i,v in next, workspace.Waystones:GetChildren() do
                                            if v:FindFirstChild('SpawnZone') and v.SpawnZone:FindFirstChildWhichIsA('TouchTransmitter') then
                                                oldwaystone = v.SpawnZone.CFrame
                                                task.wait()
                                                v.SpawnZone.CanCollide = false
                                                v.SpawnZone.CFrame = Client_Root.CFrame
                                                task.wait()
                                                v.SpawnZone.CFrame = oldwaystone
                                            end
                                        end
                
                                        for i=1, #workspace.Waystones:GetChildren() do
                                            if not Settings['StartFarm'] or Get_Flag() or Get_WorldBoss() or Get_Mob() or Get_Spawn() then break end
                                            game.ReplicatedStorage.Shared.Teleport.WaystoneTeleport:FireServer(i, 1)
                                            task.wait(1)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                function Find_Dungeon(dungeonID)
                    function Get_Dungeon()
                        local gotDungeon = nil
                        for i,v in next, workspace.PhysicalDungeonLocations:GetChildren() do
                            if v:FindFirstChild('ID') and v.ID.Value == dungeonID and v:FindFirstChild('Ring') then
                                return v
                            end
                        end
                    end

                    local dungeon = Get_Dungeon()
                    local oldpos = nil
                    if dungeon then
                        repeat task.wait()
                            if(Client_Root.Position - dungeon.Ring.Position).magnitude < 30 then
                                oldpos = dungeon.Ring.CFrame
                                task.wait()
                                dungeon.Ring.CanCollide = false
                                dungeon.Ring.CFrame = Client_Root.CFrame
                                task.wait()
                                dungeon.Ring.CFrame = oldpos
                                break
                            end

                            TweenTP(dungeon.Ring, 0)
                        until Can_Access_Dungeon(dungeonID) or not Settings['StartFarm']
                    end
                end
                
                function List_Farm()
                    local List_Farm = {}
                    for i,v in next, Get_Missions() do
                        if v.LevelRequirement <= Client_Profile.Level.Value then
                            table.insert(List_Farm, v)
                        end
                    end
                
                    table.sort(List_Farm, function(c,d)
                        return c.LevelRequirement < d.LevelRequirement
                    end)
                
                    return List_Farm
                end
                
                function Dungeons_List()
                    local FinalList = {}
                    for i,v in next, List_Farm() do
                        if v.difficulties then
                            for i1,v1 in next, v.difficulties do
                                table.insert(FinalList, {v.ID, v1.id})
                            end
                        else
                            table.insert(FinalList, {v.ID, nil})
                        end
                    end
                
                    return FinalList
                end
                
                function NextDungeon()
                    local NextDungeon = 1
                    local NextDiff = 1
                
                    for i=1, #Dungeons_List() do
                        local Dungeon = game.ReplicatedStorage.ActiveMission.Value
                        local Diff = game.TeleportService:GetLocalPlayerTeleportData().difficultyId
                        local v = Dungeons_List()[i]
                
                        if v[1] == Dungeon and (v[2] == Diff or v[2] == nil) then
                            if i >= #Dungeons_List() then
                                Settings['FarmGuildDungeon'] = false
                                Save()
                            else
                                v = Dungeons_List()[i+1]
                                NextDungeon = v[1]
                                NextDiff = v[2]
                            end
                        end
                    end
                    
                    return {NextDungeon, NextDiff}
                end
                
                function Quest_Route(Mode, DoQuest)
                    local WorldIDs = {
                        [1] = 13, [2] = 19, [3] = 20,
                        [4] = 29, [5] = 31, [6] = 36,
                        [7] = 40, [8] = 45, [9] = 49,
                    }
                
                    local TowerTargets = {
                        ['MagmaGigaBlob'] = 21,
                        ['Nautilus'] = 23,
                        ['BOSSZeus'] = 27,
                        ['Taurha'] = 29,
                        ['VaneAetherDragon'] = 34,
                    }
                
                    local SpecialWorlds = {
                        7499964980, --Market
                        6510868181, --PvP Arena
                        5862275930, --Halloween Hub
                        4526768266, --Holiday Hub
                    }
                    
                    local QuestType = Mode.Objective[1]
                    local TargetTable = Mode.Objective[3]
                    local LinkedWorld = Mode.LinkedWorld
                    local CorrectWorld = CurrentWorld == LinkedWorld

                    if not CorrectWorld or InDungeon then
                        game.ReplicatedStorage.Shared.Teleport.TeleportToHub:FireServer(WorldIDs[LinkedWorld])
                        task.wait(100)
                    end

                    if QuestType == 'KillMob' then
                        if not TowerTargets[TargetTable[1]] then
                            if InDungeon then
                                if require(game.ReplicatedStorage.Shared.Teleport):WorldIsAvailableToPlayer(WorldIDs[LinkedWorld], Client) then
                                    AFDebug:SetName('Move to: World '..tostring(LinkedWorld)..' | Quest: '..tostring(Mode.Name))
                                    game.ReplicatedStorage.Shared.Teleport.TeleportToHub:FireServer(WorldIDs[LinkedWorld])
                                    task.wait(100)
                                else
                                    AFDebug:SetName('Farm level: '..(List_Farm()[#List_Farm()].NameTag))
                                    game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(List_Farm()[#List_Farm()].ID)
                                    task.wait(100)
                                end
                            elseif not InDungeon and DoQuest then
                                AFDebug:SetName('Do quest: '..tostring(Mode.Name))
                                Farm_OpenWorld(TargetTable)
                            end
                        else
                            local towerId = TowerTargets[TargetTable[1]]
                            if Client_Level >= require(game.ReplicatedStorage.Shared.Missions):GetMissionData()[towerId].LevelRequirement then
                                AFDebug:SetName('Move to tower has: '..tostring(TargetTable[1]))
                                game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(towerId)
                                task.wait(100)
                            else
                                AFDebug:SetName('Farming level: '..(List_Farm()[#List_Farm()].NameTag))
                                game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(List_Farm()[#List_Farm()].ID)
                                task.wait(100)
                            end
                        end
                    elseif QuestType == 'DoDungeon' then
                        local LevelRequirement = require(game.ReplicatedStorage.Shared.Missions):GetMissionData()[Mode.Objective[3][1]].LevelRequirement
                        if Client_Level >= LevelRequirement then
                            AFDebug:SetName('Do quest: '..tostring(Mode.Name))
                            if not Can_Access_Dungeon(TargetTable[1]) then
                                Find_Dungeon(TargetTable[1])
                            else
                                game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(TargetTable[1])
                                task.wait(100)
                            end
                        else
                            AFDebug:SetName('Farm level: '..(List_Farm()[#List_Farm()].NameTag))
                            game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(List_Farm()[#List_Farm()].ID)
                            task.wait(100)
                        end
                    elseif QuestType == 'CompleteWorldEvent' then
                        AFDebug:SetName('Do quest: '..tostring(Mode.Name))
                        Farm_OpenWorld(nil)
                    elseif QuestType == 'DoDungeonInWorld' then
                        AFDebug:SetName('Do quest: '..tostring(Mode.Name))
                        if Mode.Name:find('World 1') then
                            game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(1)
                        elseif Mode.Name:find('World 2') then
                            game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(11)
                        elseif Mode.Name:find('World 3') then 
                            game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(14)
                        elseif Mode.Name:find('World 4') then
                            game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(19)
                        end
                        task.wait(100)
                    elseif QuestType == 'LevelUp' then
                        AFDebug:SetName('Do quest: '..tostring(Mode.Name))
                        game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(List_Farm()[#List_Farm()].ID)
                        task.wait(100)
                    elseif QuestType == 'DoRandomDungeon' then
                        for i,v in next, require(game.ReplicatedStorage.Shared.Missions.MissionData) do
                            if v.DailyDungeon and v.DailyDungeon == true then
                                game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(v.ID)
                                break
                            end
                        end
                        task.wait(100)
                    end
                end
                
                function Action(DoQuest)
                    local Towers = {21,23,27,29,34}
                
                    if Quests_Left('daily') > 0 and Settings['FarmDailyQuest'] then
                        Quest_Route(Get_Quests('daily'), DoQuest)
                    elseif Quests_Left('daily') <= 0 or not Settings['FarmDailyQuest'] then
                        if Quests_Left('world') > 0 and Settings['FarmWorldQuest'] then
                            Quest_Route(Get_Quests('world'), DoQuest)
                        elseif Quests_Left('world') <= 0 or not Settings['FarmWorldQuest'] then
                            if Settings['FarmGuildDungeon'] then
                                if not InDungeon then
                                    AFDebug:SetName('Move to: '..(Mission_Name(1))..' ('..(Diff_Default(1))..')')
                                    game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(1, 1)
                                    task.wait(100)
                                else
                                    local nextDungeon = NextDungeon()
                                    if table.find(Towers, (nextDungeon[1])) then
                                        AFDebug:SetName('Move to: '..(Mission_Name(nextDungeon[1])))
                                        game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(nextDungeon[1])
                                        task.wait(100)
                                    else
                                        AFDebug:SetName('Move to: '..(Mission_Name(nextDungeon[1]))..' ('..(Diff_Default(nextDungeon[2]))..')')
                                        game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(nextDungeon[2])
                                        task.wait(100)
                                    end
                                end
                            else
                                if table.find(Towers, (Settings['DungeonID'])) then
                                    AFDebug:SetName('Move to: '..(Mission_Name(Settings['DungeonID'])))
                                    game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(Settings['DungeonID'])
                                    task.wait(100)
                                else
                                    AFDebug:SetName('Move to: '..(Mission_Name(Settings['DungeonID']))..' ('..(Diff_Default(Settings['DifficultyID']))..')')
                                    game.ReplicatedStorage.Shared.Teleport.StartRaid:FireServer(Settings['DungeonID'], Settings['DifficultyID'])
                                    task.wait(100)
                                end
                            end
                        end
                    end
                end
                
                local ItemCount = 0
                Client.PlayerGui.TowerFinish.TowerFinish.Description:GetPropertyChangedSignal("Text"):Once(function()
                    Client_Profile.Inventory.Items.ChildAdded:Connect(function(item)
                        local type = require(game.ReplicatedStorage.Shared.Items)[item.Name].Type
                        if type == 'Weapon' then
                            ItemCount += 1
                        elseif type == 'Armor' then
                            ItemCount += 1
                        end
                    end)
                    Client_Profile.Inventory.Cosmetics.ChildAdded:Connect(function(item)
                        ItemCount += 1
                    end)
                end)
                
                local HolidayDungeonEnded = false
                --[[ if game.PlaceId == 4526768588 then
                    if Client_Profile.Inventory.Items:FindFirstChild('HolidayPrizeTicket2') then
                        Client_Profile.Inventory.Items['HolidayPrizeTicket2'].Count:GetPropertyChangedSignal('Value'):Connect(function()
                            HolidayDungeonEnded = true
                        end)
                    else
                        Client_Profile.Inventory.Items.ChildAdded:Connect(function(item)
                            local type = require(game.ReplicatedStorage.Shared.Items)[item.Name].Type
                            if type == 'PrizeTicket' then
                                HolidayDungeonEnded = true
                            end
                        end)
                    end
                end ]]

                if InDungeon then
                    function DangerPart(part)
                        local DangerParts = {'teleport','hearttele','a0','e0','s0','reset','push','temple','mushroom','water','lava','damage','fall','slider','part0','kill','arenaentry',}
                        for i,v in next, DangerParts do
                            if part.Name:lower():find(v) or part.Name == 'Trigger' or tostring(part.Parent) == 'Geyser' or tostring(part.Parent) == 'Darts' then
                                return true
                            end
                        end
                    end

                    task.defer(function()
                        while Settings['StartFarm'] and task.wait(2) do
                            if workspace:FindFirstChild('MissionObjects') then
                                if workspace:FindFirstChild('KillerParts') then
                                    workspace.KillerParts:Destroy()
                                elseif workspace:FindFirstChild('CheckpointTriggers') then
                                    workspace.CheckpointTriggers:Destroy()
                                end
                                
                                local oldpos = nil
                                for i,v in next, workspace.MissionObjects:GetDescendants() do
                                    if v.Name == 'Cutscenes' or v.Name == 'WaterKillPart' or v.Name == 'CliffsideFallTriggers' or v.Name == 'DamageDroppers' or v.Name == 'FallAreas' or v.Name == 'TubeMarkers' then 
                                        v:Destroy()
                                    elseif not DangerPart(v) and v:FindFirstChildWhichIsA('TouchTransmitter') then
                                        oldpos = v.CFrame
                                        task.wait()
                                        v.CanCollide = false
                                        v.CFrame = Client_Root.CFrame
                                        task.wait()
                                        v.CFrame = oldpos
                                    end
                                end
                    
                                for i,v in next, workspace:GetChildren() do
                                    if (v.Name:find('Cage') or v.Name:find('Treasure')) and v.PrimaryPart and v.PrimaryPart:FindFirstChildWhichIsA('TouchTransmitter') then
                                        v.PrimaryPart.CanCollide = false
                                        v.PrimaryPart.CFrame = Client_Root.CFrame
                                    end
                                end
                            end
                        end
                    end)
                end
                
                task.defer(function()
                    while Settings['StartFarm'] and task.wait() do
                        if InDungeon then
                            Farm_Dungeon()
            
                            if Settings['RestartDungeon'] and (Client.PlayerGui.MissionRewards.MissionRewards.Visible or ItemCount >= 3 or HolidayDungeonEnded == true) then
                                game.ReplicatedStorage.Shared.Missions.GetMissionPrize:InvokeServer()
                                game.ReplicatedStorage.Shared.Missions.GetMissionPrize:InvokeServer()
                                task.wait(3)
                                Action(false)
                            end
                        else
                            Action(true)
                        end
                    end
                end)
            end
    end})
end

--- // Features // ---
local Features = Window:Tab({Name = "Features", Icon = "rbxassetid://11396131982", Color = Color3.new(1, 0, 0)})
local F_MainSection = Features:Section({Name = "Core"}) do
    F_MainSection:Toggle({Name = "Kill Aura",
        Default = Settings['KillAura'],
        Callback = function(state) 
            Settings['KillAura'] = state
            Save()

            function Get_ObjectPos()
                if workspace:FindFirstChild('MissionObjects') then
                    for i,v in next, workspace.MissionObjects:GetChildren() do
                        if v.Name == 'IceBarricade' and v.PrimaryPart and IsAlive(v) then
                            return v.PrimaryPart.Position
                        elseif v.Name == 'SpikeCheckpoints' or v.Name == 'TowerLegs' then
                            for i1,v1 in next, v:GetChildren() do
                                if v1.PrimaryPart and IsAlive(v1) then
                                    return v1.PrimaryPart.Position
                                end
                            end
                        end
                    end
            
                    for i,v in next, workspace:GetChildren() do
                        if (v.Name:find('Pillar') or v.Name == 'Gate' or v.Name == 'TriggerBarrel') and v.PrimaryPart and IsAlive(v) then
                            return v.PrimaryPart.Position
                        elseif v.Name == 'FearNukes' then
                            for i1,v1 in next, v:GetChildren() do
                                if v1.PrimaryPart and IsAlive(v1) then
                                    return v1.PrimaryPart.Position
                                end
                            end
                        end
                    end
                end
            end
            
            function Get_MobPos()
                local closest, closestDistance = nil, 30
                
                for i,v in next, workspace.Mobs:GetChildren() do
                    if v:IsA('Model') and not v:FindFirstChild('NoHealthbar') and v:FindFirstChild('Collider') then
                        local CanDamage = require(game.ReplicatedStorage.Shared.Status):HasStatus(v, 'Invincible') == nil
                        if CanDamage and IsAlive(v) then
                            local currentDistance = (Client_Root.Position - v.Collider.Position).magnitude
                            if currentDistance < closestDistance then
                                closest = v.Collider.Position
                                closestDistance = currentDistance
                            end
                        end
                    end
                end
                if workspace:FindFirstChild('TargetDummies') then
                    for i,v in next, workspace.TargetDummies:GetChildren() do
                        if v:IsA('Model') and not v:FindFirstChild('NoHealthbar') and v:FindFirstChild('Part') then
                            if IsAlive(v) then
                                local currentDistance = (Client_Root.Position - v.Part.Position).magnitude
                                if currentDistance < closestDistance then
                                    closest = v.Part.Position
                                    closestDistance = currentDistance
                                end
                            end
                        end
                    end
                end
            
                return closest
            end
            
            function DamagePos()
                local object = Get_ObjectPos()
                local mob = Get_MobPos()
            
                if object then
                    return object
                else
                    return mob
                end
            end
            
            function Loop_Attack(skilltype)
                local pos = DamagePos()
                if pos and not require(game.ReplicatedStorage.Client.Actions):IsMounted() then                        
                    for index,attack in next, AtkType[skilltype] do
                        game.ReplicatedStorage.Shared.Combat.Attack:FireServer(attack, Client_Root.Position, (pos - Client_Root.Position).Unit)
                        task.wait(ET_Delay)
            
                        if attack == AtkType[skilltype][#AtkType[skilltype]] then break end
                    end
                end
            end
            
            if #AtkType['Primary'] > 0 then
                task.defer(function()
                    while Settings['KillAura'] do
                        Loop_Attack('Primary')
                        task.wait(KA_Delay[Client_Class][1])
                    end
                end)
            end
            
            if #AtkType['Skill1'] > 0 then
                task.defer(function()
                    while Settings['KillAura'] do
                        Loop_Attack('Skill1')
                        task.wait(KA_Delay[Client_Class][2])
                    end
                end)
            end
            
            if #AtkType['Skill2'] > 0 then
                task.defer(function()
                    while Settings['KillAura'] do
                        Loop_Attack('Skill2')
                        task.wait(KA_Delay[Client_Class][3])
                    end
                end)
            end
            
            if #AtkType['Skill3'] > 0 then
                task.defer(function()
                    while Settings['KillAura'] do
                        Loop_Attack('Skill3')
                        task.wait(KA_Delay[Client_Class][4])
                    end
                end)
            end
            
            if #AtkType['Ultimate'] > 0 then
                task.defer(function()
                    while Settings['KillAura'] do
                        Loop_Attack('Ultimate')
                        task.wait(KA_Delay[Client_Class][5])
                    end
                end)
            end
            
            task.defer(function()
                while Settings['KillAura'] and task.wait(1) do
                    if not require(game.ReplicatedStorage.Client.Actions):IsMounted() then
                        if DamagePos() then
                            if Client_Class == 'Demon' then
                                game.ReplicatedStorage.Shared.Combat.Skillsets.Demon.LifeSteal:FireServer(workspace.Mobs:GetChildren())
                            elseif Client_Class == 'Paladin' then
                                game.ReplicatedStorage.Shared.Combat.Skillsets.Paladin.GuildedLight:FireServer()
                            elseif Client_Class == 'Assassin' then
                                game.ReplicatedStorage.Shared.Combat.Skillsets.Assassin.EventStealthWalk:FireServer(true)
                            elseif Client_Class == 'Summoner' then
                                if Character.Properties.SummonCount.Value >= 3 then
                                    game.ReplicatedStorage.Shared.Combat.Skillsets.Summoner.Ultimate:FireServer()
                                    game.ReplicatedStorage.Shared.Combat.Skillsets.Summoner.Summon:FireServer()
                                    task.wait(5)
                                    game.ReplicatedStorage.Shared.Combat.Skillsets.Summoner.ExplodeSummons:FireServer()
                                end
                            end
                        end
                    end
                end
            end)
    end})

    F_MainSection:Toggle({Name = "Pick Up",
        Default = Settings['PickUp'],
        Callback = function(state) 
            Settings['PickUp'] = state
            Save()

            task.defer(function()
                while Settings['PickUp'] and task.wait(0.1) do
                    for i,v in next, getupvalue(require(game.ReplicatedStorage.Shared.Chests).Start, 7) do
                        if v.Parent and game.ReplicatedStorage.Shared.Chests.CheckCondition:InvokeServer(i) == true then
                            v:Destroy()
                            game.ReplicatedStorage.Shared.Chests.OpenChest:FireServer(i)
                        end
                    end
    
                    for i, v in next, getupvalue(require(game.ReplicatedStorage.Shared.Drops).Start, 4) do
                        v.model:Destroy()
                        v.followPart:Destroy()
                        game.ReplicatedStorage.Shared.Drops.CoinEvent:FireServer(v.id)
                        table.remove(getupvalue(require(game.ReplicatedStorage.Shared.Drops).Start, 4), i)
                    end
                end
            end)
    end})

    F_MainSection:Toggle({Name = "Upgrade (Equipped)",
        Default = false,
        Callback = function(upgrade_state)
            task.defer(function()
                while upgrade_state == true and task.wait(0.1) do
                    for i,v in next, Client_Profile.Equip:GetChildren() do
                        if v:IsA('Folder') and (v.Name == 'Primary' or v.Name == 'Armor' or v.Name == 'Offhand') and v:FindFirstChildWhichIsA('Folder') then
                            local v1 = v:FindFirstChildWhichIsA('Folder')
                            if v1:FindFirstChild('Upgrade') and v1:FindFirstChild('UpgradeLimit') and v1.Upgrade.Value < v1.UpgradeLimit.Value then
                                game.ReplicatedStorage.Shared.ItemUpgrade.Upgrade:FireServer(v1)
                            elseif not v1:FindFirstChild('Upgrade') or v1:FindFirstChild('UpgradeLimit') then
                                game.ReplicatedStorage.Shared.ItemUpgrade.Upgrade:FireServer(v1)
                            end
                        end
                    end
                end
            end)
    end})

    F_MainSection:Slider({Name = "Sprint Speed",
        Max = 100,
        Min = 30,
        Default = 30,
        Callback = function(val)
            require(game.ReplicatedStorage.Shared.Settings).SPRINT_WALKSPEED = val
    end})
end

--- // Inventory // ---
local Inventory = Window:Tab({Name = "Inventory", Icon = "rbxassetid://11396131982", Color = Color3.new(1, 0, 0)})
local I_Section1 = Inventory:Section({Name = "Sell Selection"}) do
    for i=1, 4 do
        I_Section1:Toggle({Name = "Sell Tier "..tostring(i),
            Default = Settings['SellTier'..tostring(i)],
            Callback = function(state) 
                Settings['SellTier'..tostring(i)] = state
                Save()
        end})
    end

    I_Section1:Toggle({Name = "Sell Tier 5 (Good Perks) ",
        Default = Settings['SellTier5'],
        Callback = function(state) 
            Settings['SellTier5'] = state
            Save()
    end})

    I_Section1:Toggle({Name = "Sell Egg ",
        Default = Settings['SellEgg'],
        Callback = function(state) 
            Settings['SellEgg'] = state
            Save()
    end})
end
local I_Section2 = Inventory:Section({Name = "Good Perks' Range"}) do
    for i,v in next, Settings['Perks'] do
        I_Section2:Slider({Name = v['name'],
            Max = v['max'], Min = v['min'], Default = v['current'],
            Callback = function(value)
                Settings['Perks'][i]['current'] = value
                Save()
        end})
    end
end
local I_Section3 = Inventory:Section({Name = "Sell Trigger"}) do
    I_Section3:Button({Name = "Quick Sell",
        Callback = function()
            local sellTable = {}
            for i,v in next, Client_Profile.Inventory.Items:GetChildren() do
                if v:IsA('Folder') then
                    local rarity = require(game.ReplicatedStorage.Shared.Inventory):GetItemTier(v)
                    local type = require(game.ReplicatedStorage.Shared.Items)[v.Name].Type
                    if type == 'Weapon' or type == 'Armor' then
                        if Settings['SellTier1'] and rarity == 1 then
                            table.insert(sellTable, v)
                        elseif Settings['SellTier2'] and rarity == 2 then
                            table.insert(sellTable, v)
                        elseif Settings['SellTier3'] and rarity == 3 then
                            table.insert(sellTable, v)
                        elseif Settings['SellTier4'] and rarity == 4 then
                            table.insert(sellTable, v)
                        end
                    elseif type == 'Egg' and Settings['SellEgg'] then
                        table.insert(sellTable, v)
                    end
                end
            end
            game.ReplicatedStorage.Shared.Drops.SellItems:InvokeServer(sellTable)
    end})

    I_Section3:Toggle({Name = "Auto Equip",
        Default = Settings['AutoEquip'],
        Callback = function(state) 
            Settings['AutoEquip'] = state
            Save()
    end})

    I_Section3:Toggle({Name = "Auto Sell",
        Default = Settings['AutoSell'],
        Callback = function(state) 
            Settings['AutoSell'] = state
            Save()
    end})

    Client_Profile.Inventory.Items.ChildAdded:Connect(function(item)
        if Settings['AutoEquip'] then
            task.defer(function()
                while Settings['AutoEquip'] and task.wait() do
                    if item.Parent ~= Client_Profile.Inventory.Items then break end

                    local type = require(game.ReplicatedStorage.Shared.Items)[item.Name].Type
                    if type == 'Weapon' then
                        local currentWeapon = Client_Profile.Equip.Primary:FindFirstChildWhichIsA('Folder')
                        if currentWeapon then
                            local currentDmg = require(game.ReplicatedStorage.Shared.Combat):GetItemStats(currentWeapon).Attack
                            local newDmg = require(game.ReplicatedStorage.Shared.Combat):GetItemStats(item).Attack
                            if newDmg > currentDmg then
                                game.ReplicatedStorage.Shared.Inventory.EquipItem:FireServer(item, Client_Profile.Equip['Primary'])
                            end
                        end
                    elseif type == 'Armor' then
                        local currentArmor = Client_Profile.Equip.Armor:FindFirstChildWhichIsA('Folder')
                        if currentArmor then
                            local currentHealth = require(game.ReplicatedStorage.Shared.Combat):GetItemStats(currentArmor).Defense
                            local newHealth = require(game.ReplicatedStorage.Shared.Combat):GetItemStats(item).Defense
                            if newHealth > currentHealth then
                                game.ReplicatedStorage.Shared.Inventory.EquipItem:FireServer(item, Client_Profile.Equip['Armor'])
                            end
                        end
                    end
                end
            end)
        end
        
        task.wait(2)
        if item.Parent ~= Client_Profile.Inventory.Items then return end

        if Settings['AutoSell'] then
            local rarity = require(game.ReplicatedStorage.Shared.Inventory):GetItemTier(item)
            local typeItem = require(game.ReplicatedStorage.Shared.Items)[item.Name].Type

            if typeItem == 'Weapon' or typeItem == 'Armor' then
                if Settings['SellTier1'] and rarity == 1 then
                    game.ReplicatedStorage.Shared.Drops.SellItems:InvokeServer({item})
                elseif Settings['SellTier2'] and rarity == 2 then
                    game.ReplicatedStorage.Shared.Drops.SellItems:InvokeServer({item})
                elseif Settings['SellTier3'] and rarity == 3 then
                    game.ReplicatedStorage.Shared.Drops.SellItems:InvokeServer({item})
                elseif Settings['SellTier4'] and rarity == 4 then
                    game.ReplicatedStorage.Shared.Drops.SellItems:InvokeServer({item})
                elseif Settings['SellTier5'] and rarity == 5 then
                    local perkFound = 0

                    for i=1,3 do
                        if (Settings['Perks'][item['Perk'..i].Value]) then
                            if (math.round(item['Perk'..i].PerkValue.Value*100) >= Settings['Perks'][item['Perk'..i].Value]['current']) then
                                perkFound += 1
                            end
                        end
                    end

                    if (perkFound == 0) then
                        game.ReplicatedStorage.Shared.Drops.SellItems:InvokeServer({item})
                    end
                end
            elseif type == 'Egg' and Settings['SellEgg'] then
                game.ReplicatedStorage.Shared.Drops.SellItems:InvokeServer({item})
            end
        end
    end)
end

--- // Misc // ---
local Misc = Window:Tab({Name = "Misc", Icon = "rbxassetid://11396131982", Color = Color3.new(1, 0, 0)})
local M_Section1 = Misc:Section({Name = "Menu"}) do
    M_Section1:Button({Name = "Bank";
        Callback = function() 
            require(game.ReplicatedStorage.Client.Gui.GuiScripts.Bank):Open()
        end
    })

    M_Section1:Button({Name = "Dungeons";
        Callback = function() 
            require(game.ReplicatedStorage.Client.Gui.GuiScripts.MissionSelect):Open()
        end
    })

    M_Section1:Button({Name = "Worlds";
        Callback = function() 
            require(game.ReplicatedStorage.Client.Gui.GuiScripts.WorldTeleport):Open()
        end
    })
end
local M_Section2 = Misc:Section({Name = "Selection"}) do
    function Get_Worlds()
        local Worlds_List = {}
    
        for i,v in next, require(game.ReplicatedStorage.Shared.Teleport.WorldData) do
            v['ID'] = tonumber(i)
            task.wait()
    
            local IsAvailable = require(game.ReplicatedStorage.Shared.Teleport):WorldIsAvailable(v.ID)
            if not v.Disabled and v.IsTown and v.CanTeleport and IsAvailable and v.LevelRequirement then     
                table.insert(Worlds_List, v)
            end
        end
    
        table.sort(Worlds_List, function(a,b)
            return a.WorldOrderID < b.WorldOrderID
        end)
    
        return Worlds_List
    end
    
    function Worlds_List()
        local stringtable = {}
    
        for i,v in next, Get_Worlds() do
            table.insert(stringtable, {v.Name..' (Lvl '..v.LevelRequirement..'+)', v.ID})
        end
    
        return stringtable
    end
    
    M_Section2:Dropdown({Name = "Worlds Travel",
        Items = Worlds_List(),
        Default = 'World 1',
        Callback = function(item)
            game.ReplicatedStorage.Shared.Teleport.TeleportToHub:FireServer(item)
        end
    })

    local function EggList()
        local Eggs = {}
        for i,v in next, require(game.ReplicatedStorage.Shared.Items) do
            if v['Type'] == 'Egg' then
                table.insert(Eggs, {v.DisplayKey, v.Name})
            end
        end

        return Eggs
    end
    M_Section2:Dropdown({Name = "Eggs Selection",
        Items = EggList(),
        Default = EggList()[1],
        Callback = function(item)
            require(game.ReplicatedStorage.Client.Gui.GuiScripts.PetShop):Open(item)
        end
    })
end
local M_Section3 = Misc:Section({Name = "Extra"}) do
    M_Section3:Toggle({Name = "Feed Pet",
        Default = false,
        Callback = function(feedpet_state) 
            task.defer(function()
                while feedpet_state == true and task.wait(0.1) do
                    for i,v in next, Client_Profile.Inventory.Items:GetChildren() do
                        if v:FindFirstChild('Count') and v.Count.Value > 0 then
                            game.ReplicatedStorage.Shared.Pets.FeedPet:FireServer(v, true)
                        end
                    end
                end
            end)
    end})

    M_Section3:Button({Name = "Collect Battlepass";
        Callback = function()
            for i=1,40 do
                game.ReplicatedStorage.Shared.Battlepass.RedeemItem:FireServer(i)
                --game.ReplicatedStorage.Shared.Battlepass.RedeemItem:FireServer(i, true)
                task.wait(0.1)
            end
        end
    })

    M_Section3:SmallTextbox({Name = "Spin Wheel",
        Default = "Numbers only",
        Callback = function(val)
            for i=1,tonumber(val) do
                game.ReplicatedStorage.Shared.EventSpinner.JoinQueue:FireServer(game.Players.LocalPlayer)
                
                --[[ require(game.ReplicatedStorage.Shared.EventSpinner).SPINNER_TIMER = 0
                require(game.ReplicatedStorage.Shared.EventSpinner).SPINNER_INTERMISSION_TIMER = 0
                require(game.ReplicatedStorage.Shared.EventSpinner):RequestJoinQueue(Client)
                require(game.ReplicatedStorage.Shared.EventSpinner):RemoveFromQueue(Client)
                task.wait(0.1) ]]
            end
        end
    })
end