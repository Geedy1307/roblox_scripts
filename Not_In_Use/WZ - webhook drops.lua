if not game:IsLoaded() then
    game.Loaded:Wait()
end
game.Players.LocalPlayer.CharacterAdded:Wait()
if not game.Players.LocalPlayer.CharacterAdded then
    game.Players.LocalPlayer.CharacterAdded:Wait()
end

local WebHook = "link" 
local HTTPService = game:GetService("HttpService")
local plrname = game.Players.LocalPlayer.Name
local inv = game:GetService("ReplicatedStorage").Profiles[plrname].Inventory.Items
local items = require(game.ReplicatedStorage.Shared.Items)
local towerEnd = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("TowerFinish").TowerFinish.Description
local tier = require(game.ReplicatedStorage.Shared.Inventory)
local perklist = {
    GoldDrop = "Bonus Gold", 
    PetFoodDrop = "Bonus Pet Food", 
    Aggro = "Shifted Aggro", 
    UltCharge = "Bonus Ult. Charge", 
    BonusHP = "HP UP", 
    BonusAttack = "Attack UP", 
    BonusWalkspeed = "Bonus Walkspeed", 
    ResistBurn = "Resist Burn", 
    ResistPoison = "Resist Poison", 
    ResistFrost = "Resist Frost", 
    ResistKnockdown = "Resist Knockdown", 
    TestTier5 = "Boss of the Boss", 
    DodgeChance = "Untouchable", 
    RoughSkin = "Rough Skin", 
    DamageReduction = "Damage Reduction",
    BurnChance = "Burn Chance", 
    CritStack = "Crit Stack", 
    LifeDrain = "Life Drain", 
    OpeningStrike = "Opening Strike", 
    Fortress = "Fortress", 
    MobBoss = "Mob Boss", 
    EliteBoss = "Elite Boss", 
    BonusRegen = "Bonus Health Regen", 
    Glass = "Glass", 
    MasterThief = "Master Thief" 
}
function msg(v1)  
    syn.request({
        Url = WebHook,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HTTPService:JSONEncode({
            content = v1
        })
    })
end
function drophook()
    inv.ChildAdded:Connect(function(c)
        if tier:GetItemTier(c) == 5 then
            local str = plrname .. " got a " .. "**wepname**" .. " - " .. os.date("%X") .. "\t-\t@everyone\t\t" .. os.date("**%d/%m/%Y**\n")
            local itemname = items[c.Name]
            str = string.gsub(str,"wepname",itemname.DisplayKey)
            c:WaitForChild("Perk3")
            for i,v in pairs(c:GetChildren()) do
                for i2,v2 in pairs(perklist) do
                    if v.Value == i2 then
                        str = str .. "\n" .. v2 .. " - **" .. math.round(v.PerkValue.Value*100) .. "%**"
                    end
                end
            end
            msg(str)
        end
    end)
end
game:GetService("ReplicatedStorage").Shared.Missions.MissionFinished.OnClientEvent:Once(function()
    drophook()
end)
towerEnd:GetPropertyChangedSignal("Text"):Once(function()
	drophook()
end)