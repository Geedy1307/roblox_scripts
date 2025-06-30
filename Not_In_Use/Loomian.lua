
print("Line 1: ran gc")
local p1
for i,v in pairs(getgc(true)) do
	if typeof(v) == 'table' and rawget(v,'Battle') then
		p1 = v
		print("set")
	end
end
local plr = game.Players.LocalPlayer
local pgui = plr.PlayerGui
local MainGui = pgui.MainGui
local HttpService = game:GetService("HttpService")

local function start()
	local v13 = p1.DataManager.currentChunk.regionData.Grass;
	p1.Battle:doWildBattle(v13,{});
end

local function End()
	local p149
	for i,v in pairs(getgc(true)) do
		if typeof(v) == 'table' and rawget(v,'exitButtonsMain') then
			p149 = v
		end
	end
	local l__currentBattle__271 = p1.Battle.currentBattle;
	if l__currentBattle__271 and l__currentBattle__271.BattleEnded then
		local v274, v275, v276 = p1.Network:get("BattleFunction", p1.Battle.currentBattle.battleId, "tryRun");
		if v275 then
			l__currentBattle__271.masteryProgressUpdate = v275;
		end;
		if v276 then
			for v277, v278 in ipairs(v276) do
				table.insert(l__currentBattle__271.actionQueue, v278);
			end;
		end;
		if v274 == "partial" then
			p149:message("You can't escape!");
			return p149:mainChoices(unpack(u67));
		end;
		if not v274 then
			v7.IdleCameraController:quit(l__currentBattle__271);
			p149:message("You couldn't escape!");
			p149:send("choose", p149.sideId, { "pass" }, p149.lastRequest.rqid);
			wait();
			p149:setIdle();
			return;
		end;
		l__currentBattle__271.ended = true;
		l__currentBattle__271.BattleEnded:fire();
		--p1.Battle.currentBattle = nil
	end
end

-- Hooking function
repeat wait() until p1

local ow
local CurrentPokemonName = nil
ow = hookfunction(rawget(p1.Battle,"run"),function(ignore,info)
	local s,e = pcall(function()
		local data = HttpService:JSONDecode(info)
		for a,c in pairs(data) do
			if type(c) == 'string' and string.sub(c,1,5) == "1p2a:" then
				CurrentPokemonName = string.sub(c,7,#c)
				print("Searching... fighting: "..CurrentPokemonName)
			end
		end
	end)
	if e then
		warn(e) 
	end
	return ow(ignore,info)
end)

local battlestarted = false
local ow
ow = hookfunction(rawget(p1.Battle,"run"),function(...)
	battlestarted = true
	return ow(...)
end)

local started = false
MainGui.DescendantAdded:Connect(function()
	started = true
end)
MainGui.DescendantRemoving:Connect(function()
	started = false
end)
repeat
	local tic = tick()
	table.foreach(_G.Target,warn)
	MainGui.FadeGui.Visible = false
	warn("Starting battle")
	spawn(function()
		p1.Battle.fastForward = true
		start()
	end)
	repeat
		wait()
	until started
	print("round fully started")
	local s,e = pcall(function()
		if _G.Target[CurrentPokemonName]  or (_G.LookForShiny and p1.Battle.currentBattle.yourSide.active[1].sprite.monster.shiny) then
			print("Found: "..CurrentPokemonName)
			return true
		end
	end)
	if e then
		warn(e)
	end
	End()
	repeat
		wait()
	until p1.Battle.currentBattle == nil
	warn("Ended battle and now looking for a new battle and took: "..(tick()-tic).." seconds")
until _G.Target[CurrentPokemonName]
print("Found: "..CurrentPokemonName)