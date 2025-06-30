local url = "https://discord.com/api/webhooks/832131822036582400/agcPgUDpdWFnIHc_iVJHcaB8fo4Qcli3bSSA_HtzuQPb7Bf-CBF_2iLFS1lfuaCoQ8Ok"

local GuildTag = require(game.ReplicatedStorage.Shared.Guilds):GetGuildID(game.Players.LocalPlayer)[game.Players.LocalPlayer.UserId]
local GuildPicture = tonumber(tostring(game.ReplicatedStorage.Shared.Guilds.GetGroupData:InvokeServer(GuildTag).EmblemUrl):split('=')[2])
local GuildPoint = require(game.ReplicatedStorage.Shared.Guilds):GetGuildData(GuildTag).points
local GuildName = require(game.ReplicatedStorage.Shared.Guilds):GetGuildData(GuildTag).name
function GuildMembers()
    local Table = {}

    for i,v in next, require(game.ReplicatedStorage.Shared.Guilds):GetGuildData(GuildTag).users do
        table.insert(Table, v)
    end

    table.sort(Table, function(a,b)
        return (a.pointsContributed > b.pointsContributed)
    end)

    return Table
end

local FileName = 'guildpoints.json'
local PreviousPoints = {}

if not pcall(function() readfile(FileName) end) then 
    for i,v in next, GuildMembers() do
        local ChildList = {
            ['displayName'] = v.displayName,
            ['pointsContributed'] = v.pointsContributed,
        }
        table.insert(PreviousPoints, ChildList)
    end

    writefile(FileName, game:GetService('HttpService'):JSONEncode(PreviousPoints))
    return
end

local Settings = game:GetService('HttpService'):JSONDecode(readfile(FileName))

function FoundUser(displayname)
    for i,v in next, Settings do
        if v.displayName == displayname then
            return {
                state = true, 
                points = v.pointsContributed
            }
        end
    end
    return {
        state = false, 
        points = -1
    }
end

function FullTime()
    local function GetTime()
        local date = os.date("*t")
        return ("%02d:%02d"):format(((date.hour % 24) - 1) % 12 + 1, date.min)
    end
    
    local currentHour = os.date("*t")["hour"]
    if currentHour < 12 or currentHour == 24 then
        return (GetTime().." AM")
    else
        return (GetTime().." PM")
    end
end

local List = {}
local List2 = {}
for i,v in next, GuildMembers() do
    if FoundUser(v.displayName).state == true and FoundUser(v.displayName).points >= 0 then
        local New = v.pointsContributed
        local Old = FoundUser(v.displayName).points
        local ChildList = {
            ["name"] = "**"..(v.displayName).."**",
            ["value"] = "Old: "..Old.."\nNew: "..New.."\n".."Earned: "..(New - Old),
            ["inline"] = true
        }
        if v.id == game.Players.LocalPlayer.UserId then
            ChildList.name = "***"..(v.displayName).."*** (You)"
        else
            ChildList.name = "**"..(v.displayName).."**"
        end
        if i >= 25 then
            table.insert(List, ChildList)
        else
            table.insert(List2, ChildList)
        end
    end
end

function SendMessage(list, samelist)
    local data
    if samelist then
        data = {
            ["embeds"] = {{
                ["type"] = "rich",
                ["color"] = tonumber(0x7269da),
                ["fields"] = list,
            }}
        }
    else
        data = {
            ["content"] = "Date: "..tostring(os.date("%A, "..DateTime.now():FormatLocalTime("LL", "en-us")).."\nTime: "..FullTime()),
            ["embeds"] = {{
                ['thumbnail'] = {['url'] = "http://www.roblox.com/Thumbs/Asset.ashx?Width=250&Height=250&AssetID="..GuildPicture, ['height']=1536, ['width']=864},
                ["author"] = {
                    ["name"] = "["..GuildTag.."] "..GuildName, ---Title
                },
                ["description"] = "Total Points: "..GuildPoint,
                ["type"] = "rich",
                ["color"] = tonumber(0x7269da),
                ["fields"] = list,
            }}
        }
    end

    return syn.request({
        Url = url,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = game:GetService("HttpService"):JSONEncode(data)
    })
end

SendMessage(List2, false)
SendMessage(List, true)

delfile(FileName)