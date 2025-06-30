	--[[
    local NameList, DistanceList = {}, {}
    Sections.LocalCheat:addToggle('ESP Players', false, function(state)
        ESPPlayer = state
        if ESPPlayer then
            EspLoop = game:GetService('RunService').RenderStepped:Connect(function()
                for i,v in next, NameList do if v then v:Remove() end end
                for i,v in next, DistanceList do if v then v:Remove() end end
                
                NameList = {}
                DistanceList = {}

                for i,v in next, game.Players:GetPlayers() do
                    if v.Name ~= game.Players.LocalPlayer.Name and v.Character and v.Character.PrimaryPart ~= nil then
                        local pos = v.Character.PrimaryPart.Position
                        local ScreenSpacePos, IsOnScreen = workspace.CurrentCamera:WorldToViewportPoint(pos)
                        
                        if IsOnScreen then
                            local NAME = Drawing.new('Text')
                            NAME.Text = v.Name
                            NAME.Size = 16
                            NAME.Color = Color3.fromRGB(255, 248, 145)
                            NAME.Center = true
                            NAME.Visible = true
                            NAME.Transparency = 1
                            NAME.Position = Vector2.new(0, 0)
                            NAME.Outline = true
                            NAME.OutlineColor = Color3.fromRGB(10, 10, 10)
                            NAME.Font = 3
                            
                            local DISTANCE = Drawing.new('Text')
                            DISTANCE.Text = '[]'
                            DISTANCE.Size = 14
                            DISTANCE.Color = Color3.fromRGB(255, 255, 255)
                            DISTANCE.Center = true
                            DISTANCE.Visible = true
                            DISTANCE.Transparency = 1
                            DISTANCE.Position = Vector2.new(0, 0)
                            DISTANCE.Outline = true
                            DISTANCE.OutlineColor = Color3.fromRGB(10, 10, 10)
                            DISTANCE.Font = 3
                            
                            NAME.Position = Vector2.new(ScreenSpacePos.X, ScreenSpacePos.Y)
                            DISTANCE.Position = NAME.Position + Vector2.new(0, NAME.TextBounds.Y/1.2)
                            DISTANCE.Text = '['..math.round((game.Players.LocalPlayer.Character.PrimaryPart.Position - pos).magnitude)..'m]'
            
                            NameList[#NameList+1] = NAME
                            DistanceList[#DistanceList+1] = DISTANCE
                        end
                    end
                end
            end)
        else
            pcall(function() EspLoop:Disconnect() end)

            for i,v in next, NameList do v:Remove() end
            for i,v in next, DistanceList do v:Remove() end
            
            NameList = {}
            DistanceList = {}
        end
    end)
	]]