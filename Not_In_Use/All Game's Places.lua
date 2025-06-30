local string = ''
local pages = game:GetService("AssetService"):GetGamePlacesAsync()
while true do
     for _,place in pairs(pages:GetCurrentPage()) do
          string = string .. place.Name .. ': ' .. place.PlaceId .. '\n'
     end
     if pages.IsFinished then break end
     pages:AdvanceToNextPageAsync()
end

setclipboard(string)