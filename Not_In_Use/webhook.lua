function convertToHex(color)
	local int = math.floor(color.r*255)*256^2+math.floor(color.g*255)*256+math.floor(color.b*255)
	local current = int
	local final = ""
	local hexChar = {"A", "B", "C", "D", "E", "F"}

	repeat wait()
        local remainder = current % 16
		local char = tostring(remainder)
		if remainder >= 10 then
			char = hexChar[1 + remainder - 10]
		end
		current = math.floor(current/16)
		final = final..char
	until current <= 0
	
	return "0x"..string.reverse(final)
end

function sendMessage(name, subname, decal)
    --Change this url link
    local url = "https://discord.com/api/webhooks/847105180045541396/O3KGCW4y3XsvycURkwxNTohtRx-eb0veXSsZBEPhWKiVBQWV2yU__t4pndLnYrmjxek5"
    
    local data = {
        ["embeds"] = {{
            ['thumbnail'] = {['url'] = "https://www.roblox.com/asset-thumbnail/image?assetId=".. game.PlaceId.. "&width=768&height=432&format=png", ['height']=1536, ['width']=864},
            ["author"] = {
                ["name"] = "Title", ---Title
                ["icon_url"] = "https://cdn.discordapp.com/avatars/739173192471675021/3c99fd2253a206b40800f88523b00de4.png"--
            },
            ["image"] = {
                ["url"] = "https://cdn.discordapp.com/avatars/739173192471675021/3c99fd2253a206b40800f88523b00de4.png"--"http://www.roblox.com/Thumbs/Asset.ashx?Width=420&Height=420&AssetID="..decal,
            },
            ["description"] = "[*Link to game*](https://www.roblox.com/games/".. game.PlaceId..")",
            ["type"] = "rich",
            ["color"] = tonumber(convertToHex(Color3.new(0.596078, 0.760784, 0.858824))),
            ["fields"] = {
                {
                    ["name"] = "Name: "..tostring(name),
                    ["value"] = "Sub: "..tostring(subname),
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "Time: "..tostring(os.date("%A | %m/%d/%Y | %X \nTime zone: %Z", os.time()))
            },
        }}
    }

    return syn.request({
        Url = url,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = game:GetService("HttpService"):JSONEncode(data)
    })
end

sendMessage("Name", "Sub", 1)

