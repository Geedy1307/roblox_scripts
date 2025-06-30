local PS = game.Players.LocalPlayer.PlayerScripts
local Worker = require(PS.CookingNew.WorkerComponents.WorkerDefault)
local M1 = require(PS.ClientMain.Replications.Customers.GetNPCFolder)


Worker.event = function(...)
   local args = {...}
   local npc = M1.GetNPCFolder(args[1]).ClientWorkers:FindFirstChild(args[2])
   local M2 = game.ReplicatedStorage.Resources.NewCookingResources.SharedCharacterComponents:FindFirstChild(args[4])
   if M2 then
       local Task = require(M2)
       Task.finishInteract(npc,args[3],args[4])
   end
   return
end