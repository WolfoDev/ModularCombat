include("enemies.lua")

MAX_DIST = 3000
MIN_DIST = 1000
MAX_SPAWNS = 20
CHASE_PLAYERS = true

hook.Add("Initialize", "initializing_zinv", function()
	Nodes = {}
	found_ain = false
	parsed_wnav = false
	spawnedEnemies = {}
	liveEnemiesCount = 0
	targetCoroutine = nil
	nodeCoroutine = nil

	ParseFile()
end)

hook.Add("EntityKeyValue", "newkeyval_zinv", function(ent)
	if ent:GetClass() == "info_player_teamspawn" then
		local valid = true
		for k,v in pairs(Nodes) do
			if v == ent:GetPos() then
				valid = false
			end
		end

		if valid then
			local node = {
				pos = ent:GetPos(),
				yaw = 0,
				offset = 0,
				type = 0,
				info = 0,
				zone = 0,
				neighbor = {},
				numneighbors = 0,
				link = {},
				numlinks = 0
			}
			table.insert(Nodes, node.pos) //Nodes used to have all the info, but we only need position
		end
	end
end)

--Taken from nodegraph addon - thx
local SIZEOF_INT = 4
local SIZEOF_SHORT = 2
local AINET_VERSION_NUMBER = 37
local function toUShort(b)
	local i = {string.byte(b,1,SIZEOF_SHORT)}
	return i[1] +i[2] *256
end
local function toInt(b)
	local i = {string.byte(b,1,SIZEOF_INT)}
	i = i[1] +i[2] *256 +i[3] *65536 +i[4] *16777216
	if(i > 2147483647) then return i -4294967296 end
	return i
end
local function ReadInt(f) return toInt(f:Read(SIZEOF_INT)) end
local function ReadUShort(f) return toUShort(f:Read(SIZEOF_SHORT)) end

function ParseWNavFile()
	local navFile = file.Read("wnavdata/"..game.GetMap()..".txt")

	if (navFile) then
		Nodes = util.JSONToTable(navFile)
		parsed_wnav = true
	end
end

--Taken from nodegraph addon - thx
--Types:
--1 = ?
--2 = info_nodes
--3 = playerspawns
--4 = wall climbers
function ParseFile()
	if found_ain then
		return
	end

	local ainFile = file.Open("maps/graphs/"..game.GetMap()..".ain","rb","GAME")
	
	if (!ainFile) then
		return
	end

	found_ain = true

	local ainet_ver = ReadInt(ainFile)
	local map_ver = ReadInt(ainFile)
	
	if(ainet_ver != AINET_VERSION_NUMBER) then
		MsgN("Unknown graph file")
		return
	end

	local numNodes = ReadInt(ainFile)
	
	if(numNodes < 0) then
		ainFile:Close()
		MsgN("Graph file has an unexpected amount of nodes")
		return
	end

	for i = 1,numNodes do
		local v = Vector(ainFile:ReadFloat(), ainFile:ReadFloat(), ainFile:ReadFloat())
		local yaw = ainFile:ReadFloat()
		local flOffsets = {}
		for i = 1,NUM_HULLS do
			flOffsets[i] = ainFile:ReadFloat()
		end
		local nodetype = ainFile:ReadByte()
		local nodeinfo = ReadUShort(ainFile)
		local zone = ainFile:ReadShort()

		if nodetype == 4 then
			continue
		end
		
		local node = {
			pos = v,
			yaw = yaw,
			offset = flOffsets,
			type = nodetype,
			info = nodeinfo,
			zone = zone,
			neighbor = {},
			numneighbors = 0,
			link = {},
			numlinks = 0
		}

		table.insert(Nodes, node.pos)
	end

	ainFile:Close()
end

hook.Add( "EntityTakeDamage", "SetDamageDealt", function(ent, dmginfo)
	if (spawnedEnemies[ent:EntIndex()] && IsValid(dmginfo:GetAttacker()) && dmginfo:GetAttacker():IsPlayer()) then
		spawnedEnemies[ent:EntIndex()].totalDamage = spawnedEnemies[ent:EntIndex()].totalDamage + dmginfo:GetDamage()
		local damageDealt = spawnedEnemies[ent:EntIndex()].attackers[dmginfo:GetAttacker():EntIndex()]
		if (damageDealt == nil) then
			spawnedEnemies[ent:EntIndex()].attackers[dmginfo:GetAttacker():EntIndex()] = dmginfo:GetDamage()
		else
			spawnedEnemies[ent:EntIndex()].attackers[dmginfo:GetAttacker():EntIndex()] = damageDealt + dmginfo:GetDamage()
		end
	end
end)

hook.Add( "OnNPCKilled", "AddExp", function(npc, attacker, inflictor )
	net.Start( "SyncNpcDeath" )
	net.WriteEntity( npc )
	net.Broadcast()
	local _npc = spawnedEnemies[npc:EntIndex()]
	if _npc then
	
		local exp = _npc.exp * 0.1
		for k, v in pairs (player.GetAll()) do
			if (_npc.attackers[v:EntIndex()] != nil && _npc.totalDamage > 0) then
				local dmgRap = (_npc.attackers[v:EntIndex()] / _npc.totalDamage)
				local levelCheck = math.random(0.95, 1.05)
				if (npc.level && v.level) then
					if (npc.level >= (v.level + 4)) then
						levelCheck = 1.2
					elseif (npc.level < (v.level - 1)) then
						levelCheck = 0.2
					end
				end
				local gainedExp = exp * dmgRap * levelCheck
				local center = npc:OBBCenter()
				center.z = npc:OBBMaxs().z
				ShowWorldText(npc:LocalToWorld(center), "+" .. math.Round(gainedExp * 10) .. " XP", "exp", v)
				v.exp = v.exp + gainedExp
				
				local modPwr = v:GetModuleUpgrade(MC.modulesByName.criticalHits)
				local explosionChance = math.random(0, 100)
				if (modPwr > 0 && explosionChance <= modPwr * 100) then
					local effectdata = EffectData()
					effectdata:SetOrigin( npc:GetPos() )
					effectdata:SetRadius( 380 )
					util.Effect( "Explosion", effectdata )

					for _, ent in pairs (ents.FindInSphere(npc:GetPos(), 380)) do
						if (IsValid(ent) && ent:IsNPC() && ent != npc) then
							local d = DamageInfo()
							d:SetDamage( 8.5 )
							d:SetAttacker( v )
							d:SetInflictor(ent)
							d:SetDamageType( DMG_BURN )

							ent:TakeDamageInfo(d)
						end
					end
				end
			end
		end

		local times = math.random(1, 4)
		local max = 160
		for i = 0,times do
			local chance = math.random(0, max)
			if (chance >= max - 15) then
				local ent = ents.Create("weapon_smg1")
				ent:SetPos(npc:GetPos() + npc:GetUp() * 20)
				ent:Spawn()
			elseif (chance >= max - 25) then
				local ent = ents.Create("weapon_pistol")
				ent:SetPos(npc:GetPos() + npc:GetUp() * 20)
				ent:Spawn()
			elseif (chance >= max - 28) then
				local ent = ents.Create("weapon_ar2")
				ent:SetPos(npc:GetPos() + npc:GetUp() * 20)
				ent:Spawn()
			elseif (chance >= max - 31) then
				local ent = ents.Create("weapon_crossbow")
				ent:SetPos(npc:GetPos() + npc:GetUp() * 20)
				ent:Spawn()
			elseif (chance >= max - 35) then
				local ent = ents.Create("weapon_shotgun")
				ent:SetPos(npc:GetPos() + npc:GetUp() * 20)
				ent:Spawn()
			end

			if (chance < 15) then
				local ent = ents.Create("item_healthvial")
				ent:SetPos(npc:GetPos() + npc:GetUp() * 20)
				ent:Spawn()
			elseif (chance < 10) then
				local ent = ents.Create("item_battery")
				ent:SetPos(npc:GetPos() + npc:GetUp() * 20)
				ent:Spawn()
			elseif (chance < 8) then
				local ent = ents.Create("weapon_357")
				ent:SetPos(npc:GetPos() + npc:GetUp() * 20)
				ent:Spawn()
			end
		end

		if npc && spawnedEnemies[npc:EntIndex()] then
			spawnedEnemies[npc:EntIndex()] = nil
			liveEnemiesCount = liveEnemiesCount - 1
		end
	end
end )

hook.Add("EntityRemoved", "Entity_Removed_zinv", function(ent)
	if spawnedEnemies && spawnedEnemies[ent:EntIndex()] then
		spawnedEnemies[ent:EntIndex()] = nil
		liveEnemiesCount = liveEnemiesCount - 1
	end
end)


function PickRandomNPC()
	local npc = NPCs[0];
	local maxChance = 0
	local canSpawnBoss = true
	local levels = {}
	for _, v in pairs (player.GetAll()) do
		table.insert(levels, v.level)
		canSpawnBoss = (v.level >= 5) && canSpawnBoss
	end
	for _, v in pairs (ents.FindByClass("npc_*")) do
		canSpawnBoss = !v.boss && canSpawnBoss
	end
	local level = table.Random(levels) || 1

	for _,v in pairs (NPCs) do
		if ((v.boss || v.type == "metal") && !canSpawnBoss) then
			continue
		end
		if (v.chance > 0) then
			maxChance = maxChance + v.chance
		end
	end
	local curChance = math.random(0, maxChance)
	local lastChance = 0
	local lastCheck = maxChance
	for _,v in pairs (NPCs) do
		if ((v.boss || v.type == "metal") && !canSpawnBoss) then
			continue
		end
		lastChance = lastChance + v.chance
		if (math.abs(lastChance - curChance) < lastCheck) then
			lastCheck = math.abs(lastChance - curChance)
			npc = v
		end
	end
	
	return npc, level
end


function CanSeePlayers(pos)
	local result = false
	local hit = nil
	for k, ply in pairs (player.GetAll()) do
		if (IsValid(ply)) then
			local trace = {}
			trace.start = pos
			trace.endpos = ply:LocalToWorld(ply:OBBCenter())
			local traceLine = util.TraceLine(trace)
			hit = traceLine.Entity
			if (traceLine.Entity == ply) then
				result = true
			end
		end
	end
	return result
end

function SpawnEnemy(pos)
	local result = NULL;
	--Pick random NPC based on chance
	local npcInfo, level = PickRandomNPC()

	--Spawn NPC
	if npcInfo then
		local npc = npcInfo.npc
		local health = npcInfo.health()
		local weapon = npcInfo.weapon
		local experience = npcInfo.exp
		local boss = npcInfo.boss
		local ent = ents.Create(npc)
		local size = npcInfo.size
		local name = npcInfo.name
		local prof = npcInfo.proficiency
		local type = npcInfo.type
		if ent then
			if weapon != "" then
				ent:SetKeyValue("additionalequipment", weapon)
			end
			ent:SetPos(pos)
			ent:SetAngles(Angle(0, math.random(0, 360), 0))
			ent:Spawn()

			spawnedEnemies[ent:EntIndex()] = {
				exp = experience,
				totalDamage = 0,
				status = {},
				attackers = {}
			}
			liveEnemiesCount = liveEnemiesCount + 1
			
			if (weapon != "") then ent:Give(weapon) end
			ent.level = level
			prof = ent:ProficiencyFormulaNPC(prof)
			health = ent:HealthFormulaNPC(health)
			if (health > 0) then ent:SetHealth(health) end
			ent:SetModelScale(size)
			ent:SetMaxHealth(health)
			ent.name = name
			ent.type = type
			ent.boss = boss

			local entIndex = ent:EntIndex()
			if (ent.type == "medic") then
				for _, v in pairs (NPCs) do
					ent:AddRelationship(v.npc .. " D_HT 99")
				end
				//ent:SetMaterial("models/props_pipes/Pipesystem01a_skin3")
				ent:SetMaterial("models/XQM/LightLinesRed_tool")
				ent:AddRelationship("player D_HT 20")
				timer.Create("MedicTargetCheck" .. entIndex, 2, 0, function()
					if (!IsValid(ent)) then
						timer.Remove("MedicTargetCheck" .. entIndex)
					else
						local npcToHeal = nil
						local healthDiff = 1
						for k, v in pairs (ents.FindByClass("npc_*")) do
							local curHealth = v:Health() / v:GetMaxHealth()
							if (v:IsNPC() && curHealth <= healthDiff && !v.minion) then
								npcToHeal = v
								healthDiff = curHealth
							end
						end
						if (npcToHeal) then
							ent:SetEnemy(npcToHeal)
						end
					end
				end)
			else
				for _, v in pairs (NPCs) do
					ent:AddRelationship(v.npc .. " D_LI 99")
				end
				ent:AddRelationship("player D_HT 1")
			end
			if (ent.type == "metal") then
				ent:SetMaterial("phoenix_storms/gear")
			end
			for _, v in pairs (ents.FindByClass("npc_*")) do
				if (v.minion) then
					ent:AddEntityRelationship(v, D_HT, 99)
				end
			end
			
			ent:SetCurrentWeaponProficiency(prof)
			if (npc == "npc_vortigaunt" || npc == "npc_strider" || npc == "npc_helicopter") then
				ent:SetCurrentWeaponProficiency(WEAPON_PROFICIENCY_POOR)
			end
			if (npc == "npc_rollermine") then
				ent.health = ent:GetMaxHealth()
				timer.Create("RollerMineHealthCheck" .. entIndex, 0.05, 0, function()
					if (!IsValid(ent)) then
						timer.Remove("RollerMineHealthCheck" .. entIndex)
					else
                    	if (ent.health) then ent:SetHealth(ent.health) end
						if (ent:Health() <= 0) then
							local effectdata = EffectData()
							effectdata:SetOrigin( ent:GetPos() )
							effectdata:SetRadius( 50 )
							effectdata:SetScale( 1 )
							util.Effect( "Explosion", effectdata )
							ent:Remove()
						end
					end
				end)
			end
			if (npc == "npc_strider") then
				ent.health = ent:GetMaxHealth()
				timer.Create("StriderHealthCheck" .. entIndex, 0.05, 0, function()
					if (!IsValid(ent)) then
						timer.Remove("StriderHealthCheck" .. entIndex)
					else
                    	if (ent.health) then ent:SetHealth(ent.health) end
						if (ent:Health() <= 0) then
							//ent:Kill()
						end
					end
				end)
				//local toGround = util.QuickTrace(ent:GetPos() + ent:GetUp() * 10, ent:GetUp() * -1000, ent)
				//ent:SetPos(toGround.HitPos)
			end
			if (npc == "npc_helicopter") then
				ent.health = ent:GetMaxHealth()
				timer.Create("HelicopterHealthCheck" .. entIndex, 0.05, 0, function()
					if (!IsValid(ent)) then
						timer.Remove("HelicopterHealthCheck" .. entIndex)
					else
                    	if (ent.health) then ent:SetHealth(ent.health) end
						if (ent:Health() <= 0 && IsValid(ent)) then
							ent:Kill()
						end
					end
				end)
			end
			ent:Fire("StartPatrolling")
			ent:Fire("SetReadinessHigh")
			ent:SetNPCState(NPC_STATE_COMBAT)
			ent:Activate()

			result = ent;

			timer.Simple(0.5, function()
				if (IsValid(ent)) then
					net.Start( "SyncNpcStats" )
					net.WriteEntity( ent )
					net.WriteUInt(level, 8)
					net.WriteFloat(ent:Health())
					net.WriteFloat(ent:Health())
					net.WriteBool(ent.boss)
					net.WriteString(ent.name)
					net.WriteBool(ent.minion)
					net.WriteEntity( NULL )
					net.Broadcast()
				end
			end)
		end
	end

	return result;
end

function CleanNPCs()
	/*
	--Check enemy
	for k, v in pairs(enemies) do
		local closest = 99999
		local closest_plr = NULL
		local enemy_pos = v:GetPos()

		for k2, v2 in pairs(player.GetAll()) do
			local dist = enemy_pos:Distance(v2:GetPos())

			if dist < closest then
				closest_plr = v2
				closest = dist
			end
		end

		if closest > MAX_DIST * 1.25 then
			table.RemoveByValue(enemies, v)
			v:Remove()
		end
	end
	*/
	local maxcycle = #player.GetAll()
	for k, v in pairs (ents.FindByClass("npc_*")) do
		local inactive = true
		local cycle = 0
		for _, ply in pairs (player.GetAll()) do
			cycle = cycle + 1
			if (IsValid(v) && spawnedEnemies[v:EntIndex()]) then
				inactive = inactive && (v:GetPos():Distance(ply:GetPos()) > MAX_DIST)
				if (cycle >= maxcycle && inactive) then
					spawnedEnemies[v:EntIndex()] = nil
					liveEnemiesCount = liveEnemiesCount - 1
					v:Remove()
				end
			end
		end
	end
end

function SetNPCsEnemy()
	if !CHASE_PLAYERS || (targetCoroutine != nil && coroutine.status(targetCoroutine) != "dead") then
		return
	end

	targetCoroutine = coroutine.create(function()
		local npcs = ents.GetAll()
		local plys = player.GetAll()
		local plyCount = #plys

		-- No point trying to give NPCs a player when there are none
		if ( plyCount == 0 ) then
			return
		end

		-- Loop over all entities and check for NPCs
		for i = 1, #npcs do
			local npc = npcs[ i ]

			-- If this entity is an NPC without an enemy, give them one
			if ( IsValid(npc) && npc:IsNPC() ) then
				local curPly = nil			-- Closest player
				local curPlyPos = nil		-- Position of closest player
				local curDist = math.huge	-- Lowest distance between npc and player
				
				local npcPos = npc:GetPos()	-- Position of the NPC

				-- Loop over all players to check their distance from the NPC
				for i = 1, plyCount do
					local ply = plys[ i ]

					-- TODO: You can optimise looking up each player's position (constant)
					-- for every NPC by generating a table of:
					--- key = player identifier (entity object, UserID, EntIndex, etc.)
					--- value = player's position vector
					-- for the first NPC that passes to this part of the code,
					-- then reuse it for other NPCs
					local plyPos = ply:GetPos()

					if (spawnedEnemies[npc:EntIndex()] && npc.type != "medic") then						
						-- Use DistToSqr for distance comparisons since
						-- it's more efficient than Distance, and the
						-- non-squared distance isn't needed for anything
						local dist = npcPos:DistToSqr( plyPos )

						-- If the new distance is lower, update the player information
						if ( dist < curDist ) then
							curPly = ply
							curPlyPos = plyPos
							curDist = dist
						end
					elseif npc:IsMinion(ply) && not IsValid(npc:GetEnemy()) then
						curPly = ply
						curPlyPos = plyPos
					else
						continue
					end
				end

				-- curPly is guarenteed to be valid since this code
				-- will only run if there is at least one player
				//npc:SetEnemy( curPly )
				//npc:MoveOrder( curPlyPos )
				//npc:UpdateEnemyMemory( curPly, curPlyPos )

				//local dir = (curPlyPos - npc:GetPos())
				//dir:Normalize()

				//print(tostring(npc) .. " done, moving to: " .. tostring(curPlyPos))

				if curPlyPos != nil then
					local result = npc:NavSetGoal( curPlyPos )
					npc:SetSaveValue("m_vecLastPosition", curPlyPos)
					npc:SetSchedule(SCHED_FORCED_GO)
					npc:IdleSound()
					//print(tostring(npc) .. ":NavSetGoal = " .. tostring(result))
				end
				
				coroutine.wait(0.1)
			end
		end
	end)

	local resume, args = coroutine.resume(targetCoroutine)
	//print("running target coroutine " .. coroutine.status(targetCoroutine) .. " / " .. tostring(resume) .. " | " .. tostring(args))
end

local function MapGen()
    --navmesh.IsGenerating()
    --gmod.GetGamemode():SetStatus(-2)

    local SpawnPoints = ents.FindByClass( "info_player_*" )
    local tab = {"ins_spawnpoint","aoc_spawnpoint","dys_spawn_point","diprip_start_team_blue","diprip_start_team_red"}
    for I=1,#tab do
        table.Merge( SpawnPoints, ents.FindByClass( tab[I] ) )  
    end
    for I=1,#SpawnPoints do
        navmesh.AddWalkableSeed( SpawnPoints[I]:GetPos(), SpawnPoints[I]:GetAngles():Up() )
    end

    navmesh.BeginGeneration()
    PrintMessage(3,"[GAMEMODE] Generating navmesh. This will take some time.")

    timer.Create("MapNavGen", 1, 0, function()
        if !navmesh.IsGenerating() then
            -- Restart
            PrintMessage( 3, "[GAMEMODE] Restarting ...")
            timer.Destroy("MapNavGen")
            RunConsoleCommand( "changelevel", game.GetMap() )
        end
    end)
end

function AutoSpawnNPCs()
	if (pvpmode >= 1) then
		return
	end

	if table.Count(player.GetAll()) <= 0 || liveEnemiesCount >= MAX_SPAWNS then
		return
	end

	local status, err = pcall( function()
		local valid_nodes = {}		
		local nodePositions = {}
		local enemies = {}
		
		if !found_ain then
			ParseFile()
		end

		if !parsed_wnav && (!Nodes || table.Count(Nodes) < 1) then --TODO: use navmesh.CreateNavArea( Vector corner, Vector opposite_corner )
			ParseWNavFile()
		end

		if !Nodes || table.Count(Nodes) < 1 then --TODO: use navmesh.CreateNavArea( Vector corner, Vector opposite_corner )
			print("No info_node(s) or wnav_nodes in map! NPCs will not spawn.")
			return
		end

		if table.Count(Nodes) <= 35 then
			print("NPCs may not spawn well on this map, please try another.")
		end

		for ent_index, _ in pairs(spawnedEnemies) do
			if !IsValid(Entity(ent_index)) then
				spawnedEnemies[ent_index] = nil
				liveEnemiesCount = liveEnemiesCount - 1
			else
				table.insert(enemies, Entity(ent_index))
			end
		end

		--Get valid nodes
		for k, nodePos in pairs(Nodes) do
			local valid = false

			for k2, v2 in pairs(player.GetAll()) do
				local dist = nodePos:Distance(v2:GetPos())

				if dist <= MIN_DIST then
					valid = false
					break
				elseif dist < MAX_DIST then
					valid = true
				end
			end

			if !valid then
				continue
			end

			for k2, v2 in pairs(enemies) do
				local dist = nodePos:Distance(v2:GetPos())
				if dist <= 100 then
					valid = false
					break
				end
			end

			valid = valid && !CanSeePlayers(nodePos)

			if valid then
				table.insert(valid_nodes, nodePos)
			end
		end

		--Spawn enemies if not enough
		if table.Count(valid_nodes) > 0 then
			SpawnEnemiesAsync(valid_nodes)
		end
	end)

	if !status then
		print(err)
	end
end

function SpawnEnemiesAsync(nodes)
	if nodeCoroutine != nil && coroutine.status(nodeCoroutine) != "dead" then
		return
	end

	MAX_SPAWNS = 10 + 15 * #player.GetAll()

	nodeCoroutine = coroutine.create(function()	
		for i = 0, 5 do
			if liveEnemiesCount < MAX_SPAWNS then
				local pos = table.Random(nodes) 
				if pos != nil then
					local npc = SpawnEnemy(pos)
				
					coroutine.wait(0.1)

					if npc:IsEntityStuck() || npc:WaterLevel() >= 1 then
						npc:Remove()
						print(tostring(npc) .. " REMOVED! WATER LEVEL: " .. tostring(npc:WaterLevel()))
					end

					table.RemoveByValue(nodes, pos)
					//print("Node removed, remaining: " .. tostring(table.Count(nodes)))
				end
			else
				break
			end

			coroutine.wait(0.5)
		end
	end)

	local resume, args = coroutine.resume(nodeCoroutine)
	//print("running node coroutine " .. coroutine.status(nodeCoroutine) .. " / " .. tostring(resume) .. " | " .. tostring(args))
end

local function CreateDelayedUpdates()	
	timer.Simple( 2, function()
		print("Timers created")
		timer.Create( "SyncLevel", 1, 0, UpdateLevel )
		timer.Create( "AutoSpawnTimer" , 5, 0, AutoSpawnNPCs)
		timer.Create( "DelayedUpdate", 0.25, 0, DelayedUpdate )
		timer.Create( "CleanInactiveNPCs", 20, 0, CleanNPCs )
		timer.Create( "SetNPCsEnemy", 7, 0, SetNPCsEnemy )
		
		hook.Add("Think", "CoroutineManagement", function()
			if (targetCoroutine != nil && coroutine.status(targetCoroutine) == "suspended") then
				local resume, args = coroutine.resume(targetCoroutine)
				if (args != nil) then print("running target coroutine " .. coroutine.status(targetCoroutine) .. " / " .. tostring(resume) .. " | " .. tostring(args)) end
			end

			if (nodeCoroutine != nil && coroutine.status(nodeCoroutine) == "suspended") then
				local resume, args = coroutine.resume(nodeCoroutine)
				if (args != nil) then print("running target coroutine " .. coroutine.status(nodeCoroutine) .. " / " .. tostring(resume) .. " | " .. tostring(args)) end
			end
		end)

	end)
end
hook.Add( "InitPostEntity", "CreateDelayedUpdates", CreateDelayedUpdates )