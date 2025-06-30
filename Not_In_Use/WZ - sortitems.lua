local GuiNames = {
    'Mummy Costume',
    'Toxic Reaper Cloak',
    'Back Cauldron',
    'Slime Head',
    'Dire Boarwolf Mask',
    'Bat Wings',
    'Back Tendrils',
    'Half Mask',
    'Snowman Mask',
    'Christmas Stocking',
    'Reindeer Antlers',
    'Scented Pinecone',
    'Bag Of Snowballs',
    'Turkey Head',
    'Nutcracker',
    'Cheetah Tail',
    'Melted Candle Hat',
    'Pumpkin Backpack',
    'Pumpkin Stem Hat',
    'Broken Halo',
}

local DelCosmetics = {}
for i,v in next, require(game.ReplicatedStorage.Shared.Items) do
    if table.find(GuiNames, v.DisplayKey) then
        table.insert(DelCosmetics, v.Name)
    end
end
task.wait(1)

function Amount(name)
    local count = 0
    for i,v in next, game.ReplicatedStorage.Profiles[game.Players.LocalPlayer.Name].Inventory.Cosmetics:GetChildren() do
        if v.Name == name then
            count = count + 1
        end
    end

    return count
end

for i,v in next, game.ReplicatedStorage.Profiles[game.Players.LocalPlayer.Name].Inventory.Cosmetics:GetChildren() do
    if table.find(DelCosmetics, v.Name) then
        game.ReplicatedStorage.Shared.Inventory.DeleteItem:FireServer(v)
    end
    task.wait(0.1)
end