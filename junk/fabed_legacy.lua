local wait = task.wait
local spawn = task.spawn

while not game:IsLoaded() do wait() end

local locals = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
}

locals.Player = locals.Players.LocalPlayer or locals.Players.PlayerAdded:Wait()
locals.Character = locals.Player.Character or locals.Player.CharacterAdded:Wait()
locals.HumanoidRootPart = locals.Character:WaitForChild("HumanoidRootPart")

locals.Player.CharacterAdded:Connect(function(char)
    locals.Character = char
    locals.HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

locals.UseSpell = locals.ReplicatedStorage:WaitForChild("useSpell")
locals.Swing = locals.ReplicatedStorage:WaitForChild("Swing")
locals.Enemies = locals.Workspace:WaitForChild("Enemies")

locals.SpellGui = locals.Player:WaitForChild("PlayerGui"):WaitForChild("Spell")
locals.CoverQ = locals.SpellGui.qMainFrame.coverQ
locals.CoverE = locals.SpellGui.eMainFrame.coverE
locals.CoverR = locals.SpellGui.rMainFrame.coverR

locals.SpellRange = 50
locals.SigilRange = 35
locals.SwingRange = 22

function locals.GetClosestEnemy(maxDistance)
    local closest = nil
    local shortest = maxDistance

    for _, enemy in ipairs(locals.Enemies:GetChildren()) do
        local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
        if enemyHRP then
            local dist = (locals.HumanoidRootPart.Position - enemyHRP.Position).Magnitude
            if dist < shortest then
                shortest = dist
                closest = enemyHRP
            end
        end
    end

    return closest
end

getgenv().Enabled = true

while getgenv().Enabled and task.wait() do
    if locals.Workspace:FindFirstChild("SpellPart4") then
        continue
    end

    local spellTarget = locals.GetClosestEnemy(locals.SpellRange)
    if spellTarget then
        locals.HumanoidRootPart.CFrame = CFrame.lookAt(
            locals.HumanoidRootPart.Position,
            Vector3.new(spellTarget.Position.X, locals.HumanoidRootPart.Position.Y, spellTarget.Position.Z)
        )

        if not locals.CoverQ.Visible then
            locals.UseSpell:FireServer("Q")
        end
        if not locals.CoverE.Visible then
            locals.UseSpell:FireServer("E")
        end
        
    end

    local sigilTarget = locals.GetClosestEnemy(locals.SigilRange)
    if sigilTarget then
        if not locals.CoverR.Visible then
            locals.UseSpell:FireServer("R")
        end
    end

    local swingTarget = locals.GetClosestEnemy(locals.SwingRange)
    if swingTarget then
        locals.Swing:FireServer()
    end
end