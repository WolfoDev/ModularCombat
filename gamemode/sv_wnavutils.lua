
NAV_POINT_DISTANCE = 200
NAV_CHECK_SIZE = 50
NAV_DELAY_PER_POINT = 0.005

hook.Add("Initialize", "initializingWNAV", function()
	customNavStart = nil
	customNavEnd = nil
end)


function GenerateWNav(ply, cmd, args)
	if (customNavStart == nil || customNavEnd == nil || !ply:IsSuperAdmin()) then
		return
	end

	ply:ChatPrint( "WNav generation started!" )

	local viablePositions = {}

	local gridx = math.Round(math.abs(customNavEnd.x - customNavStart.x) / NAV_POINT_DISTANCE)
	local gridy = math.Round(math.abs(customNavEnd.y - customNavStart.y) / NAV_POINT_DISTANCE)
	local signx = 1
	local signy = 1
	if (customNavEnd.x - customNavStart.x) < 0 then signx = -1 end
	if (customNavEnd.y - customNavStart.y) < 0 then signy = -1 end

	local minHeight = math.min(customNavStart.z, customNavEnd.z) - (NAV_POINT_DISTANCE * 0.2)
	local maxHeight = math.max(customNavStart.z, customNavEnd.z) + (NAV_POINT_DISTANCE)

	local totalCount = gridx * gridy
	local totalTime = totalCount * NAV_DELAY_PER_POINT

	ply:ChatPrint( "This will take more than " .. totalTime .. " seconds" )
	
	local co = coroutine.create(function()
		local lastProgress = 0
		local currentCount = 0

		for x = 0, gridx do
			for y = 0, gridy do
				currentCount = currentCount + 1
				local traceStart = Vector(customNavStart.x + (x * signx * NAV_POINT_DISTANCE), customNavStart.y + (y * signy * NAV_POINT_DISTANCE), maxHeight)
				local traceEnd = Vector(traceStart.x, traceStart.y, minHeight)

				local tracedPositions = TraceForSpawns(traceStart, traceEnd)

				for k, v in pairs (tracedPositions) do
					table.insert(viablePositions, v)
				end
				
				local progress = math.floor(currentCount / totalCount * 10) - 1

				if (progress > lastProgress) then
					lastProgress = progress
					ply:ChatPrint( "Progress: " .. progress .. "0%")
				end

				coroutine.wait(NAV_DELAY_PER_POINT)
			end
		end

		local totalPoints = table.Count(viablePositions)
		ply:ChatPrint( "Done! Valid points: " .. totalPoints)

		if (totalPoints <= 0) then
			return
		end

		totalTime = totalPoints * NAV_DELAY_PER_POINT
		ply:ChatPrint( "Now creating groups... This will take more or less " .. totalTime .. " seconds" )

		local groups = {}
		local groupColors = {}
		lastProgress = 0

		local traceOffset = Vector(0, 0, 10)
		for k, point in ipairs (viablePositions) do				
			local progress = math.floor(k / totalCount * 10) - 1

			if (progress > lastProgress) then
				lastProgress = progress
				ply:ChatPrint( "Progress: " .. progress .. "0%")
			end

			local isInGroup = false

			if (table.Count(groups) > 0) then
				for groupKey, groupValue in pairs (groups) do
					for pointInGroupKey, pointInGroup in pairs (groupValue) do
						if (k == pointInGroupKey) then
							continue
						end

						local trace = util.TraceLine({start = point + traceOffset, endpos = pointInGroup + traceOffset})
						isInGroup = !trace.Hit

						if (isInGroup) then
							break
						end

						//coroutine.wait(NAV_DELAY_PER_POINT)
					end

					if (isInGroup) then
						groups[groupKey][k] = point
						break
					end
				end

				if (isInGroup) then
					continue
				end
			end

			local groupKey = "group" .. table.Count(groups)
			groups[groupKey] = {}
			groups[groupKey][k] = point
			groupColors[groupKey] = Color(math.random(0, 255), math.random(0, 255), math.random(0, 255))

			for k2, otherPoint in ipairs (viablePositions) do
				if (k == k2) then
					continue
				end

				if (math.abs(point.z - otherPoint.z) > 200) then
					continue
				end

				local trace = util.TraceLine({start = point + traceOffset, endpos = otherPoint + traceOffset})

				if (!trace.Hit) then
					groups[groupKey][k2] = otherPoint
					//debugoverlay.Line(point + traceOffset, otherPoint + traceOffset, 10, Color(0, 255, 0), false)
					break
				end

			end
				
			coroutine.wait(NAV_DELAY_PER_POINT)
		end

		local totalGroups = table.Count(groups)
		ply:ChatPrint( "Created raw groups: " .. totalGroups )
		totalTime = totalGroups * NAV_DELAY_PER_POINT
		ply:ChatPrint( "Now cleaning groups... This will take more or less " .. tostring(totalTime) .. " seconds" )

		//Merges groups
		//This is so bad I know. Shhh
		if (totalGroups > 1) then
			local count = 0
			lastProgress = 0
			for k, v in pairs (groups) do
				count = count + 1
				local progress = math.floor(count / totalGroups * 10) - 1

				if (progress > lastProgress) then
					lastProgress = progress
					ply:ChatPrint( "Progress: " .. progress .. "0%")
				end

				for k2, v2 in pairs (groups) do
					if (k2 == k) then
						continue
					end

					for pointKey, point in pairs (groups[k]) do
						if (groups[k2][pointKey] != nil) then
							table.Add(groups[k], groups[k2])
							groups[k2] = nil
							break
						end
					end
				end
				coroutine.wait(NAV_DELAY_PER_POINT)
			end
			
			for k, v in pairs (groups) do
				if (biggestGroup == nil) then
					biggestGroup = k
					continue
				end

				if (table.Count(v) > table.Count(groups[biggestGroup])) then
					biggestGroup = k
				end
			end

			viablePositions = groups[biggestGroup]

		elseif (table.Count(groups) == 1) then
			ply:ChatPrint( "Only one group created. Elements: " .. table.Count(groups["group0"]) )
		end

		ply:ChatPrint( "Created groups: " .. table.Count(groups) )

		navmesh.ClearWalkableSeeds()
		//for k, v in pairs (groups) do
		for k2, pos in pairs (viablePositions) do
			//local ent = ents.Create( "prop_physics" )
			//ent:SetModel( "models/dav0r/buttons/button.mdl" )
			//ent:SetPos( v )
			//ent:Spawn()
			//ent:PhysicsInit(SOLID_NONE)

			//local ent = ents.Create("prop_effect")
			//ent:SetModel("models/items/hevsuit.mdl")
			//ent:SetPos(pos)
			//ent:Spawn()
			//timer.Simple(60, function() ent:Remove() end)

			//ent:SetColor(groupColors[k])
			//ent:SetRenderMode( RENDERMODE_TRANSCOLOR )

			navmesh.AddWalkableSeed(pos, Vector(0, 0, 1))
			debugoverlay.Line(pos, pos + Vector(0,0, 100), 60, Color(0, 255, 0), true) // groupColors[k]

			coroutine.wait(NAV_DELAY_PER_POINT)
		end
		//end

		if (!file.Exists("wnavdata", "DATA")) then
			file.CreateDir("wnavdata")
		end

		file.Write("wnavdata/"..game.GetMap()..".txt", util.TableToJSON(viablePositions))

		ply:ChatPrint( "Done! Final valid points: " .. table.Count(viablePositions))
	end)

	local resume, args = coroutine.resume(co)
	print("running wnav co " .. coroutine.status(co) .. " / " .. tostring(resume) .. " | " .. tostring(args))

	hook.Add("Think", "WNavCoroutineManagement", function()
		if (co != nil && coroutine.status(co) == "suspended") then
			local resume, args = coroutine.resume(co)
			if (args != nil) then print("running target coroutine " .. coroutine.status(co) .. " / " .. tostring(resume) .. " | " .. tostring(args)) end
		elseif (co != nil && coroutine.status(co) == "dead") then		
			hook.Remove("Think", "WNavCoroutineManagement")
		end
	end)
end

function GenerateNavmeshFromWNav(ply, cmd, args)
	if (!ply:IsSuperAdmin()) then
		return
	end

	local co = coroutine.create(function()
		navmesh.BeginGeneration()

		while (navmesh.IsGenerating()) do
			coroutine.wait(0.1)
		end

		navmesh.Save()
	end)

	local resume, args = coroutine.resume(co)
	print("running wnav co " .. coroutine.status(co) .. " / " .. tostring(resume) .. " | " .. tostring(args))

	hook.Add("Think", "WNavGenerationCoroutineManagement", function()
		if (co != nil && coroutine.status(co) == "suspended") then
			local resume, args = coroutine.resume(co)
			if (args != nil) then print("running target coroutine " .. coroutine.status(co) .. " / " .. tostring(resume) .. " | " .. tostring(args)) end
		elseif (co != nil && coroutine.status(co) == "dead") then		
			hook.Remove("Think", "WNavGenerationCoroutineManagement")
		end
	end)
end

function TraceForSpawns(startPos, endPos, iteration)
	local tracedPositions = {}

	if (customNavStart == nil || customNavEnd == nil || startPos.z < endPos.z) then
		return tracedPositions
	end

	if (iteration == nil) then
		iteration = 0
	end

	if (iteration > 20) then
		return tracedPositions
	end

	local right = Vector(NAV_CHECK_SIZE, 0, 0)
	local left = Vector(-NAV_CHECK_SIZE, 0, 0)
	local forward = Vector(0, NAV_CHECK_SIZE, 0)
	local backward = Vector(0, -NAV_CHECK_SIZE, 0)
	local up = Vector(0, 0, NAV_CHECK_SIZE * 2)

	local trace = util.TraceLine({start = startPos, endpos = endPos})

	if (iteration == 0) then
		debugoverlay.Line(startPos, endPos, 5, Color(255, 0, 0), true)
	else
		debugoverlay.Line(startPos, endPos, 6, Color(0, 0, 255), true)
	end

	if (trace.HitWorld) then
		local recursiveTracedPositions = TraceForSpawns(trace.HitPos - Vector(0, 0, NAV_POINT_DISTANCE * 0.25), endPos, iteration + 1)
		if (table.Count(recursiveTracedPositions) > 0) then
			//if (iteration == 0) then print("Found recursive traced pos: " .. table.Count(recursiveTracedPositions)) end
			table.Add(tracedPositions, recursiveTracedPositions)
		end

		local traceR = util.TraceLine({start = trace.HitPos, endpos = trace.HitPos + right})
		local traceL = util.TraceLine({start = trace.HitPos, endpos = trace.HitPos + left})
		local traceF = util.TraceLine({start = trace.HitPos, endpos = trace.HitPos + forward})
		local traceB = util.TraceLine({start = trace.HitPos, endpos = trace.HitPos + backward})
		local traceRF = util.TraceLine({start = trace.HitPos, endpos = trace.HitPos + right + forward})
		local traceLB = util.TraceLine({start = trace.HitPos, endpos = trace.HitPos + left + backward})
		local traceU = util.TraceLine({start = trace.HitPos, endpos = trace.HitPos + up})
		local isViable = !traceR.Hit && !traceL.Hit && !traceF.Hit && !traceB.Hit && !traceU.Hit && !traceRF.Hit && !traceLB.Hit

		if (isViable) then
			table.insert(tracedPositions, trace.HitPos)
			//debugoverlay.Line(trace.HitPos, trace.HitPos + right, 60, Color(255, 0, 255), true)
			//debugoverlay.Line(trace.HitPos, trace.HitPos + left, 60, Color(255, 0, 255), true)
			//debugoverlay.Line(trace.HitPos, trace.HitPos + forward, 60, Color(255, 0, 255), true)
			//debugoverlay.Line(trace.HitPos, trace.HitPos + backward, 60, Color(255, 0, 255), true)
			//if (iteration == 0) then print("Found a traced pos") end
		end
	end

	return tracedPositions
end

function SetWNavStart(ply, cmd, args)
	if (!ply:IsSuperAdmin()) then
		return
	end

	customNavStart = ply:GetPos()
	ply:ChatPrint( "WNav start set!" )
end

function SetWNavEnd(ply, cmd, args)
	if (!ply:IsSuperAdmin()) then
		return
	end

	customNavEnd = ply:GetPos()
	ply:ChatPrint( "WNav end set!" )
end

concommand.Add("wnav_setstart", SetWNavStart);
concommand.Add("wnav_setend", SetWNavEnd);
concommand.Add("wnav_generate", GenerateWNav);
concommand.Add("wnav_generatenavmesh", GenerateNavmeshFromWNav);