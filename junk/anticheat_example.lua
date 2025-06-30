for i,v in next, getgc() do
	if type(v) == "function" and islclosure(v) and not isexecutorclosure(v) then
		local source = debug.info(v, "s")
		if source:find('Loading') then
			hookfunction(v, function(...)
				return task.wait(9e9)
			end)
		end
	end
end

local ac = {
    ["NC Hook #1"] = true,
    ["GetFullName"] = true,
    ["match"] = true,
    ["INJ #1"] = true,
    ["CGUI"] = true,
    ["INJ #2"] = true,
    ["HTP #3"] = true,
}

coroutine.wrap(function()
    for i, v in pairs(getgc(true)) do
        if type(v) == "function" and islclosure(v) then
            pcall(function()
                local consts = debug.getconstants(v)
                local matches = 0
                for _, const in ipairs(consts) do
                    if ac[const] then
                        matches = matches + 1
                    end
                end
                if matches >= 3 then
                    print(v)
                    hookfunction(v, function() return end)
                end
            end)
        end
    end
end)()


--[[ debug.info arg2
f = function
l = line
s = source ( Like Script:GetFullName() )
a = arguments, contain arguments
n = name


-- With Names
local function A() end -- n = "A"
function B() end -- n = "B"
local C = ({ -- n = "Name"
    Name = function() end,
}).Name

-- Without Names
D = function()end -- n = "" 
local E = function()end -- n = "" 
local D = ({ -- n = ""
    Name2 = (function() end),
}).Name2

print(debug.info(C, "n"))
]]




local Remote == RemotePath

local oldNc
oldNc = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local Method = getnamecallmethod()
    if not checkcaller() then
        local Args = {...}

        if rawequal(Method, "FireServer") and rawequal(self, Remote) then -- if pcall(function() game:FireServer() then print("Detected") end)
            return nil
        end
    end

    return oldNc(self, ...)
end))