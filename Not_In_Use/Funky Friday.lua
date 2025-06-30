--// Variables
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/un-named%20backups/jans", true))()

for i,v in next, getconnections(game.Players.LocalPlayer.Idled) do
    v:Disable()
end

local framework, scrollHandler
while task.wait() do
    for _, obj in next, getgc(true) do
        if type(obj) == 'table' and rawget(obj, 'GameUI') then 
            framework = obj
            break
        end
    end

    for _, module in next, getloadedmodules() do
        if module.Name == 'ScrollHandler' then
            scrollHandler = module
            break
        end
    end 

    if (type(framework) == 'table' and typeof(scrollHandler) == 'Instance') then
        break
    end
end

local set_identity = (type(syn) == 'table' and syn.set_thread_identity) or setidentity or setthreadcontext
function fireSignal(target, signal, ...)    
    set_identity(2) 
    for _, signal in next, getconnections(signal) do
        if type(signal.Function) == 'function' and islclosure(signal.Function) then
            local scr = rawget(getfenv(signal.Function), 'script')
            if scr == target then
                pcall(signal.Function, ...)
            end
        end
    end
    set_identity(7)
end

local keyCodeMap = {}
for _, enum in next, Enum.KeyCode:GetEnumItems() do
    keyCodeMap[enum.Value] = enum
end

local Chances = {
    ['Sick'] = 97,
    ['Good'] = 93,
    ['Ok'] = 88,
    ['Bad'] = 76,
}

function RollAccuracy()
    local ACCURACY_NAMES = {'Sick', 'Good', 'Ok', 'Bad'}
    local Percentages = {
        ['Sick'] = library.flags.sickChance,
        ['Good'] = library.flags.goodChance,
        ['Ok'] = library.flags.okChance,
        ['Bad'] = library.flags.badChance,
    }
    
    local ChanceData = {} 
    for i = 1, #ACCURACY_NAMES do 
        local Name = ACCURACY_NAMES[i] 
        if Percentages[Name] > 0 then 
            ChanceData[Percentages[Name]] = Name 
        end
    end
    
    local Total = 0
    local Entries = {}
    for i, Chance in next, ChanceData do 
        Entries[Chance] = {Min = Total, Max = Total + i} 
        Total = Total + i 
    end
    
    local Sum = 0
    for i,v in next, Percentages do
        Sum = Sum + v
    end

    local Percentage = math.random(0, Sum)
    for i, Entry in next, Entries do 
        if Entry.Min <= Percentage and Entry.Max >= Percentage then
            return i
        end
    end

    return 97
end

function nearNote(note_DataTime, note_Position)
    local count = framework.SongPlayer:GetKeyCount()
    local mode = count .. 'Key'

    for index, arrow in next, framework.UI:GetNotes() do
        if arrow.Side == framework.UI.CurrentSide then
            local position = (arrow.Data.Position % count) .. ''

            if position and (position == note_Position) then
            	if (arrow.Data.Time - note_DataTime) <= 0.15 then
                    return 0.03
                elseif (arrow.Data.Time - note_DataTime) < 0.25 then
                    return 0.05
                end
            end
        end
    end
    return Random.new():NextNumber(0.1, 0.15)
end

if shared._id then
	pcall(game:GetService('RunService').UnbindFromRenderStep, game:GetService('RunService'), shared._id)
end

shared._id = game:GetService('HttpService'):GenerateGUID(false)
game:GetService('RunService'):BindToRenderStep(shared._id, 1, function()
	if not library.flags.autoPlayer then return end

    local currentlyPlaying = framework.SongPlayer.CurrentlyPlaying

    if typeof(currentlyPlaying) ~= 'Instance' or not currentlyPlaying:IsA('Sound') then 
        return 
    end

    local count = framework.SongPlayer:GetKeyCount()
    local mode = count .. 'Key'

    local arrowData = framework.ArrowData[mode].Arrows

    for index, arrow in next, framework.UI:GetNotes() do
        local ignoredNoteTypes = { Death = true, Mechanic = true, Poison = true }

        if type(arrow.NoteDataConfigs) == 'table' then 
            if ignoredNoteTypes[arrow.NoteDataConfigs.Type] then 
                continue
            end
        end

        if (arrow.Side == framework.UI.CurrentSide) and (not arrow.Marked) and (currentlyPlaying.TimePosition > 0) then
            local position = tostring(arrow.Data.Position % count)

            if position then
                local hitboxOffset = 0 do
                    local settings = framework.Settings
                    local offset = type(settings) == 'table' and settings.HitboxOffset
                    local value = type(offset) == 'table' and offset.Value

                    if type(value) == 'number' then
                        hitboxOffset = value
                    end

                    hitboxOffset = hitboxOffset / 1000
                end

                local songTime = framework.SongPlayer.CurrentTime do
                    local configs = framework.SongPlayer.CurrentSongConfigs
                    local playbackSpeed = type(configs) == 'table' and configs.PlaybackSpeed

                    if type(playbackSpeed) ~= 'number' then
                        playbackSpeed = 1
                    end

                    songTime = songTime /  playbackSpeed
                end
                
                local noteTime = math.clamp((1 - math.abs(arrow.Data.Time - (songTime + hitboxOffset))) * 100, 0, 100)
                
                if noteTime >= Chances[RollAccuracy()] then
                    task.spawn(function()
                        arrow.Marked = true

                        local keyCode = keyCodeMap[arrowData[position].Keybinds.Keyboard[1]]
                        fireSignal(scrollHandler, game:GetService('UserInputService').InputBegan, { KeyCode = keyCode, UserInputType = Enum.UserInputType.Keyboard }, false)
                        if arrow.Data.Length > 0 then
                            task.wait(arrow.Data.Length)
                        else
                            task.wait(nearNote(arrow.Data.Time, position))
                        end
                        fireSignal(scrollHandler, game:GetService('UserInputService').InputEnded, { KeyCode = keyCode, UserInputType = Enum.UserInputType.Keyboard }, false)
                        arrow.Marked = nil
                    end)
                end
            end
        end
    end
end)

-- function getPrompt(side)
--     local currentside = '1'
--     if side == 'Left' then
--         currentside = '1'
--     elseif side == 'Right' then
--         currentside = '2'
--     end
--     for i,v in next, workspace.Map.Stages:GetChildren() do
--         if v:FindFirstChild('Microphones') then
--             for i1,v1 in next, v.Microphones:GetChildren() do
--                 if v1.Name == currentside and v1:FindFirstChild('Handle') and v1.Handle:FindFirstChild('Attachment') and v1.Handle.Attachment:FindFirstChildWhichIsA('ProximityPrompt') then
--                     if (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - v1.Handle.Position).magnitude <= 50 then
--                         return v1.Handle
--                     end
--                 end
--             end
--         end
--     end
-- end

-- local Songs = {
--     {'VSCyrix_Voltage','Hard'},
--     {'VSCamellia_Me','Mania'},
--     {'VSCamellia_Ghost','Mania'},
--     {'VSPonko_Mortis','Hard'},
--     {'VSPonko_Banned','Hard'},
--     {'VSAgoti_Agoti','Insane'},
--     {'VSMonika_BaraNoYume','Hard'},
-- }

-- game:GetService('RunService'):BindToRenderStep(shared._id, 1, function()
-- 	if not library.flags.farmscore then return end
--     if game.Players.LocalPlayer.PlayerGui.GameUI.Arrows.Visible == false then
--         if game.Players.LocalPlayer.PlayerGui.GameUI.Solo.Visible == false then
--             local trigger = getPrompt(library.flags.pickStage)
--             if trigger then
--                 trigger.Attachment:FindFirstChildWhichIsA('ProximityPrompt'):InputHoldBegin()
--             end
--         end
--         if game.Players.LocalPlayer.PlayerGui.GameUI.SongSelector.Visible == true then
--             task.wait(2)
--             game.ReplicatedStorage.RF:InvokeServer({"Server","SelectMap"}, {"Default"})
--             game.ReplicatedStorage.RF:InvokeServer({"Server","SelectWin"}, {"HighestScore"})
--             game.ReplicatedStorage.RF:InvokeServer({'Server','SelectSong'}, Songs[math.random(1, #Songs)])
--             repeat task.wait() until game.Players.LocalPlayer.PlayerGui.GameUI.Arrows.Visible == true or not library.flags.farmscore
--         end
--     end
--     task.wait(0.5)
-- end)

local window = library:CreateWindow('Funky Friday') do
	local folder = window:AddFolder('Main') do
		folder:AddToggle({ text = 'Autoplayer', flag = 'autoPlayer' })
        folder:AddSlider({ text = 'Sick %', flag = 'sickChance', min = 0, max = 100, value = 100 })
		folder:AddSlider({ text = 'Good %', flag = 'goodChance', min = 0, max = 100, value = 0 })
		folder:AddSlider({ text = 'Ok %', flag = 'okChance', min = 0, max = 100, value = 0 })
        folder:AddSlider({ text = 'Bad %', flag = 'badChance', min = 0, max = 100, value = 0 })
	end
    -- local folder1 = window:AddFolder('Farm') do
    --     folder1:AddToggle({ text = 'Score', flag = 'farmscore' })
    --     folder1:AddList({text = 'Stage', flag = 'pickStage', value = 'Left', values = {'Left', 'Right'}})
    -- end
end
library:Init()