--[[ How to bypass YBA "Anti-Cheat" 101

No-Clip Bypass
YBA uses Raycasts for children within workspace.Map to stop no-clipping, you can easily just hook Raycast to return nil but I have a more exploit-universal method:
Python: *]]
local MapFolder = Instance.new("Folder", workspace)

for _, Part in workspace.Map:GetChildren() do
    Part.Parent = MapFolder
end

--[[ Teleport Bypass
YBA has a very dogshit Anti-Teleport where you can just hook their TPHandler remote to return an argument which allows a teleport to go through:
Python: *]]
local OldNamecallTP;
OldNamecallTP = hookmetamethod(game, '__namecall', newcclosure(function(self, ...)
    local Arguments = {...}
    local Method =  getnamecallmethod()
 
    if Method == "InvokeServer" and Arguments[1] == "idklolbrah2de" then
        return "  ___XP DE KEY"
    end
 
    return OldNamecallTP(self, ...)
end))

--[[ Item Magnitude Bypass
YBA uses a magnitude check to see if you are within a certain radius of an item for it to appear, you can hook this so that every item on the map is loaded for you:
hookmetamethod version:
Python: *]]
local Player = game:GetService("Players").LocalPlayer

local OldIndexItem;
OldIndexItem = hookmetamethod(Player.Character.PrimaryPart.Position, "__index", newcclosure(function(self, Key)
    if not checkcaller() and Key:lower() == 'magnitude' and getcallingscript().Name == "ItemSpawn" then
        return 0;
    end
                                                     
    return OldIndexItem(self, key)
end))

--[[ hookfunction version:
Python: *]]
local Player = game:GetService("Players").LocalPlayer

local OldIndexItem;
OldIndexItem = hookfunction(getrawmetatable(Player.Character.PrimaryPart.Position).__index, function(self, Key)
    if getcallingscript().Name == "ItemSpawn" and Key:lower() == "magnitude" then
        return 0
    end
                     
    return OldIndexItem(self, Key)
end)

--[[ WalkSpeed/JumpPower Bypass
YBA speed/jump hacks used to be a simple hook but some time ago they implemented a new patch which kills & crashes you, here is the bypass with toggles:
Python: *]]
getgenv().Stuff = {
    ToggleWalkSpeed = true;
    ToggleJumpPower = true;

    --// Change these to preferred values
    WantedWalkSpeed = 100;
    WantedJumpPower = 120;

    --// Do not change these
    DefaultWalkSpeed = 22;
    DefaultJumpPower = 50;
}

if not HookRan then
    getgenv().HookRan = true

    local OldNewIndex;
    OldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, Key, Value, ...)
        if Key == "WalkSpeed" then
            Stuff.DefaultWalkSpeed = Value

            if Stuff.ToggleWalkSpeed then
                return OldNewIndex(self, Key, Stuff.WantedWalkSpeed, ...)
            end
        end

        if Key == "JumpPower" then
            Stuff.DefaultJumpPower = Value

            if Stuff.ToggleJumpPower then
                return OldNewIndex(self, Key, Stuff.WantedJumpPower, ...)
            end
        end

        return OldNewIndex(self, Key, Value, ...)
    end))

    local OldIndex;
    OldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Key, ...)
        if Key == "WalkSpeed" then
            return Stuff.DefaultWalkSpeed
        end

        if Key == "JumpPower" then
            return Stuff.DefaultJumpPower
        end
 
        return OldIndex(self, Key, ...)
    end))
end

--[[ Crash Bypass
YBA also crashes your game when certain things happen when you're cheating, here is the bypass:
Python: *]]
local FunctionLibrary = require(ReplicatedStorage:WaitForChild('Modules').FunctionLibrary)
local Old = FunctionLibrary.pcall

FunctionLibrary.pcall = function(...)
    local f = ...

    if type(f) == 'function' and #getupvalues(f) == 11 then
        return
    end
 
    return Old(...)
end
