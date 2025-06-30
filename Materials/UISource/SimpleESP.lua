local lib = {}
local Folder = Instance.new("Folder", game:GetService("CoreGui"))

function lib:AddOutline(Character, OutlineFill)
   local OutlineFill = OutlineFill or false;
   local Highlight = Instance.new("Highlight", Folder)
   
   Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
   Highlight.Adornee = Character
   
   if OutlineFill == true then
       Highlight.FillColor = Color3.fromRGB(255, 255, 255)
       Highlight.FillTransparency = 1
   else
       Highlight.FillTransparency = 1
   end
end

function lib:AddNameTag(Character)
   local BGui = Instance.new("BillboardGui", Folder)
   local Frame = Instance.new("Frame", BGui)
   local TextLabel = Instance.new("TextLabel", Frame)
   
   BGui.Adornee = Character:WaitForChild("Head")
   BGui.StudsOffset = Vector3.new(0, 3, 0)
   BGui.AlwaysOnTop = true
   
   BGui.Size = UDim2.new(4, 0, 0.5, 0)
   Frame.Size = UDim2.new(1, 0, 1, 0)
   TextLabel.Size = UDim2.new(1, 0, 1, 0)
   
   Frame.BackgroundTransparency = 1
   TextLabel.BackgroundTransparency = 1
   
   TextLabel.Text = Character.Name
   TextLabel.Font = Enum.Font.RobotoMono
   TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
   TextLabel.TextScaled = false
end

function lib:ClearESP()
   for i,v in pairs(Folder:GetChildren()) do
      v:Destroy();
   end
end

-- local studs = Player:DistanceFromCharacter(v.PrimaryPart.Position)
-- Simple_Create(v.PrimaryPart, v.Name, "AI_Tracker", math.floor(studs + 0.5))
function lib:StudESP(target, name, trackername, studs)
   local bb = Instance.new('BillboardGui', game.CoreGui)
   bb.Adornee = target
   bb.ExtentsOffset = Vector3.new(0,1,0)
   bb.AlwaysOnTop = true
   bb.Size = UDim2.new(0,6,0,6)
   bb.StudsOffset = Vector3.new(0,1,0)
   bb.Name = trackername

   local frame = Instance.new('Frame', bb)
   frame.ZIndex = 10
   frame.BackgroundTransparency = 0.3
   frame.Size = UDim2.new(1,0,1,0)
   frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

   local txtlbl = Instance.new('TextLabel', bb)
   txtlbl.ZIndex = 10
   txtlbl.BackgroundTransparency = 1
   txtlbl.Position = UDim2.new(0,0,0,-48)
   txtlbl.Size = UDim2.new(1,0,10,0)
   txtlbl.Font = 'ArialBold'
   txtlbl.FontSize = 'Size12'
   txtlbl.Text = name
   txtlbl.TextStrokeTransparency = 0.5
   txtlbl.TextColor3 = Color3.fromRGB(255, 0, 0)

   local txtlblstud = Instance.new('TextLabel', bb)
   txtlblstud.ZIndex = 10
   txtlblstud.BackgroundTransparency = 1
   txtlblstud.Position = UDim2.new(0,0,0,-35)
   txtlblstud.Size = UDim2.new(1,0,10,0)
   txtlblstud.Font = 'ArialBold'
   txtlblstud.FontSize = 'Size12'
   txtlblstud.Text = tostring(studs) .. " Studs"
   txtlblstud.TextStrokeTransparency = 0.5
   txtlblstud.TextColor3 = Color3.new(255,255,255)
end

function lib:ClearStudESP(espname)
   for _,v in pairs(game.CoreGui:GetChildren()) do
       if v.Name == espname and v:isA('BillboardGui') then
           v:Destroy()
       end
   end
end

return lib;