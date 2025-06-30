local wait = task.wait
local spawn = task.spawn

repeat wait(1) until game:IsLoaded()
repeat wait(1) until game.Players.LocalPlayer
repeat wait(1) until game.Players.LocalPlayer.Character 

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = Players.LocalPlayer or Players.PlayerAdded:Wait()

if game.PlaceId == 11872917490 then --[[ Lobby *]]
    repeat wait(1) until workspace:FindFirstChild("Map")

    local playerLevel = Client:WaitForChild("data"):WaitForChild("level").Value
    local dungeonInfo = require(game.ReplicatedStorage.Modules.DungeonInfo)
    local args = {
        [1] = {
            ["Map"] = "Raided Village",
            ["Difficulty"] = "Chaos",
            ["LevelRequirement"] = playerLevel,
            ["Private"] = true,
            ["Hardcore"] = false,
            ["Easter"] = false,
            ["NoHit"] = false,
            ["Calamity"] = false,
        }
    }
    
    ReplicatedStorage.CreateParty:InvokeServer(unpack(args))
    ReplicatedStorage.StartDungeon:FireServer()
else
    repeat wait(1) until workspace:FindFirstChild("Enemies")
    repeat wait(1) until workspace:FindFirstChild("dungeonStarted")
    repeat wait(1) until workspace:FindFirstChild("dungeonFinished")

    local dungeonStarted = workspace.dungeonStarted.Value
    local dungeonFinished = workspace.dungeonFinished.Value
    local Character = Client.Character or Client.Character:Wait()
    local clientRoot
    local clientHumanoid

    local cooldownQ = Client.cooldownQ.Value
    local cooldownE = Client.cooldownE.Value

    Client.CharacterAdded:Connect(function(newChar)
        Character = newChar
        clientRoot = Character:WaitForChild("HumanoidRootPart")
        clientHumanoid = Character:WaitForChild("Humanoid")
    end)
    clientRoot = Character:WaitForChild("HumanoidRootPart")
    clientHumanoid = Character:WaitForChild("Humanoid")

    if not dungeonStarted then
        ReplicatedStorage.StartDungeon:FireServer(true)
    end
    
    function isAlive(parent)
        return parent:FindFirstChild("HumanoidRootPart") and parent:FindFirstChild("Humanoid") and parent.Humanoid.Health > 0
    end

    function canCastSpell(distance)
        if tonumber(distance) <= 30 then
            ReplicatedStorage.Swing:FireServer()
            if cooldownQ <= 0 then
                ReplicatedStorage.useSpell:FireServer("Q")
            end
            if cooldownE <= 0 then
                ReplicatedStorage.useSpell:FireServer("E")
            end
        end
    end

    function lookAt(target)
        clientRoot.CFrame = CFrame.lookAt(clientRoot.Position, target.Position)
    end

    function closestEmeny()
        local target = nil
        local distance = math.huge

        for i,v in next, workspace.Enemies:GetChildren() do
            if isAlive(v) and isAlive(Character) then
                local newDistance = (clientRoot.Position - v.HumanoidRootPart.Position).magnitude
                if newDistance < distance then
                    target = v
                    distance = newDistance
                end
            end
        end

        return target
    end

    spawn(function()
        while wait(1) do
            for i,v in next, workspace.Enemies:GetChildren() do
                if isAlive(v) and isAlive(Character) then
                    local distance = (clientRoot.Position - v.HumanoidRootPart.Position).magnitude
                    canCastSpell(distance)
                end
            end
        end
    end)
    
    local radius = 7 -- Distance from the center
    local height = 5
    local angle = 0
    workspace.DescendantAdded:connect(function(hitbox)
        if (hitbox:IsA("BasePart") or hitbox:IsA("MeshPart") or hitbox:IsA("Part")) and hitbox.Name:find("Hitbox") then
            hitbox.Touched:connect(function(otherPart)
                if otherPart:IsDescendantOf(character) then
                    angle = angle + 45
                end
            end)
        end
    end)

    spawn(function()
        while wait() do
            local enemy = closestEmeny()
            if enemy then
                repeat wait()
                    if not isAlive(enemy) then
                        enemy:Destroy()
                        break
                    end
                    if not isAlive(Character) then break end

                    local enemyRoot = enemy.HumanoidRootPart.Position
                    local rad = math.rad(angle)
                    local offset = Vector3.new(math.cos(rad) * radius, height, math.sin(rad) * radius)
                    local newPosition = enemyRoot + offset
                    clientRoot.CFrame = CFrame.new(newPosition, enemyRoot)

                    -- lookAt(enemyRoot)
                until not enemy
            end
        end
    end)
end