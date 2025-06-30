local client = game.Players.LocalPlayer
local profile = game.ReplicatedStorage.Profiles[client.Name]
local petFolder = profile.Equip.Pet

function GetEgg()
    for i,v in next, profile.Inventory.Items:GetChildren() do
        if v.Name:find("Egg") then
            return v
        end
    end
end

function GetFood()
    for i,v in next, profile.Inventory.Items:GetChildren() do
        if v:FindFirstChild("Count") and v.Count.Value > 0 then
            return v
        end
    end
end

while game:GetService("RunService").Heartbeat:wait() do
    if not petFolder:FindFirstChildWhichIsA("Folder") or (petFolder:FindFirstChildWhichIsA("Folder"):FindFirstChild("Level") and petFolder:FindFirstChildWhichIsA("Folder").Level.Value == 40) then
        game.ReplicatedStorage.Shared.Inventory.EquipItem:FireServer(GetEgg(), petFolder)
    elseif client.PlayerGui.MainGui.HatchEgg.Visible == true then
        game.ReplicatedStorage.Shared.Pets.Hatch:FireServer(game.Players.LocalPlayer.Character.Collider.Position + Vector3.new(0,0,5))
        repeat wait() until petFolder:FindFirstChildWhichIsA("Folder") and petFolder:FindFirstChildWhichIsA("Folder"):FindFirstChild("Level")
        game.ReplicatedStorage.Shared.Pets.NamePet:InvokeServer("Gura")
    end
    game.ReplicatedStorage.Shared.Pets.FeedPet:FireServer(GetFood(), true)
end
