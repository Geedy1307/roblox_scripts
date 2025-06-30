	local last
	PathTo = function(pos)
		pos = pos.p
		local path = Paths[game.PlaceId]
		if not path then
			return TweenTo(pos)
		end
		
		local hrp = (plr.Character or plr.CharacterAdded:Wait()).PrimaryPart
		if not hrp then
			hrp = plr.Character:WaitForChild("HumanoidRootPart")
		end
		
		local waypoint = Closest(path, hrp.Position)
		--local waypointPos = Vector3.new(unpack(path[waypoint].Pos))
		local target = Closest(path, pos)
		--local targetPos = Vector3.new(unpack(path[target].Pos))
		
		if isDebug then
			Waypoints[target].BrickColor = BrickColor.Blue()
		end
		
		local function Recur(curr, ignore, history, count, oneOfManyPaths)
			if count and count >= 30 then
				return false
			end
			for i,v in pairs(curr.Conn) do
				if isDebug then
					if history and #history > 0 then
						Waypoints[history[#history].Index].BrickColor = BrickColor.White()
					end
					debugwarn("Checking",v,"of waypoint",curr.Index)
					--wait(.1)
					Waypoints[v].BrickColor = BrickColor.Yellow()
				end
				if not ignore[v] and v ~= target then
					local wp = path[v]
					local res
					
					local c = 0
					local paths = oneOfManyPaths
					if #curr.Conn <= 2 --[[and (curr.Conn[1] == history[#history] or curr.Conn[2] == history[#history])]] then
						if oneOfManyPaths then
							c = (count or 0) + 1
						end
					else
						debugprint("Waypoint",curr.Index,"has many paths")
						paths = true
					end
					
					ignore[v] = true
					if not history then
						debugprint("Starting a new thread")
						res = Recur(wp, ignore, {}, c, paths)
					else
						history[#history + 1] = curr
						res = Recur(wp, ignore, history, c, paths)
					end
					if res then
						return res
					end
				elseif v == target then
					return history and history[1] or debugwarn("No waypoint #1") or path[target]
				end
			end
		end
		
		local wp = Recur(path[waypoint], {[waypoint] = true})
		if not wp then
			debugwarn("No waypoint #2")
			wp = path[waypoint]
		end
		local pos = Vector3.new(unpack(wp.Pos))
		local i = wp.Index
		
		if isDebug then
			if last then
				last.BrickColor = BrickColor.White()
			end
			Waypoints[target].BrickColor = BrickColor.White()
			last = Waypoints[i]
			last.BrickColor = BrickColor.Red()
			debugprint("Tweening to",pos)
		end
		
		local targetPos = CFrame.new(pos)
		if CurrentTarget then
			local newPos = CFrame.new(pos, CurrentTarget.Part.Position)
			local angles = newPos - newPos.p
			angles = Vector3.new(angles:ToEulerAnglesYXZ())
			
			targetPos = targetPos * CFrame.Angles(0,angles.Y,0)
		end
		if wp.Tp and path[waypoint].Tp then
			wait((targetPos.p - hrp.Position).magnitude/Settings.AutofarmSpeed)
			return plr.Character:SetPrimaryPartCFrame(targetPos)
		end
		return TweenTo(targetPos)
	end