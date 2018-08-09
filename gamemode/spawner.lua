
MAX_DIST = 3000
MIN_DIST = 1500
MAX_SPAWNS = 20
CHASE_PLAYERS = false
NPCs = {}

hook.Add("Initialize", "initializing_zinv", function()
	Nodes = {}
	found_ain = false
	spawnedZombies = {}
	ParseFile()
end)

hook.Add("EntityKeyValue", "newkeyval_zinv", function(ent)
	if ent:GetClass() == "info_player_teamspawn" then
		local valid = true
		for k,v in pairs(Nodes) do
			if v["pos"] == ent:GetPos() then
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
			table.insert(Nodes, node)
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

--Taken from nodegraph addon - thx
--Types:
--1 = ?
--2 = info_nodes
--3 = playerspawns
--4 = wall climbers
function ParseFile()
	if foundain then
		return
	end

	f = file.Open("maps/graphs/"..game.GetMap()..".ain","rb","GAME")
	if(!f) then
		return
	end

	found_ain = true
	local ainet_ver = ReadInt(f)
	local map_ver = ReadInt(f)
	if(ainet_ver != AINET_VERSION_NUMBER) then
		MsgN("Unknown graph file")
		return
	end

	local numNodes = ReadInt(f)
	if(numNodes < 0) then
		MsgN("Graph file has an unexpected amount of nodes")
		return
	end

	for i = 1,numNodes do
		local v = Vector(f:ReadFloat(),f:ReadFloat(),f:ReadFloat())
		local yaw = f:ReadFloat()
		local flOffsets = {}
		for i = 1,NUM_HULLS do
			flOffsets[i] = f:ReadFloat()
		end
		local nodetype = f:ReadByte()
		local nodeinfo = ReadUShort(f)
		local zone = f:ReadShort()

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

		table.insert(Nodes,node)
	end
end

hook.Add( "EntityTakeDamage", "SetDamageDealt", function(ent, dmginfo)
	if (spawnedZombies[ent:EntIndex()] && IsValid(dmginfo:GetAttacker()) && dmginfo:GetAttacker():IsPlayer()) then
		spawnedZombies[ent:EntIndex()].totalDamage = spawnedZombies[ent:EntIndex()].totalDamage + dmginfo:GetDamage()
		local damageDealt = spawnedZombies[ent:EntIndex()].attackers[dmginfo:GetAttacker():EntIndex()]
		if (damageDealt == nil) then
			spawnedZombies[ent:EntIndex()].attackers[dmginfo:GetAttacker():EntIndex()] = dmginfo:GetDamage()
		else
			spawnedZombies[ent:EntIndex()].attackers[dmginfo:GetAttacker():EntIndex()] = damageDealt + dmginfo:GetDamage()
		end
	end
end)

hook.Add( "OnNPCKilled", "AddExp", function(npc, attacker, inflictor )
	net.Start( "SyncNpcDeath" )
	net.WriteEntity( npc )
	net.Broadcast()
	local _npc = spawnedZombies[npc:EntIndex()]
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
		//attacker.exp = attacker.exp + exp//math.Round(npc:GetMaxHealth() * math.Rand(0.11, 0.09))

		local times = math.random(1, 4)
		for i = 0,times do
			local chance = math.random(0, 200)
			if (chance >= 185) then
				local ent = ents.Create("weapon_smg1")
				ent:SetPos(npc:GetPos() + npc:GetUp() * 20)
				ent:Spawn()
			elseif (chance >= 175) then
				local ent = ents.Create("weapon_pistol")
				ent:SetPos(npc:GetPos() + npc:GetUp() * 20)
				ent:Spawn()
			elseif (chance >= 172) then
				local ent = ents.Create("weapon_ar2")
				ent:SetPos(npc:GetPos() + npc:GetUp() * 20)
				ent:Spawn()
			elseif (chance >= 169) then
				local ent = ents.Create("weapon_crossbow")
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

		spawnedZombies[npc:EntIndex()] = nil
	end
end )

hook.Add("EntityRemoved", "Entity_Removed_zinv", function(ent)
	if spawnedZombies[ent:EntIndex()] then
		spawnedZombies[ent:EntIndex()] = nil
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


/*function CanSeePlayer(ent, ply)
	local result = false
	if (IsValid(ent) && IsValid(ply)) then
		local trace = {}
		trace.start = ent:GetPos() + ent:GetUp() * 50
		trace.endpos = ply:GetPos() + ply:GetUp() * 50
		local traceLine = util.TraceLine(trace)
		result = (traceLine.Entity == ply)
	end
	return result
end*/

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

function CanSeePlayer(ent, ply)
	return ent:IsLineOfSightClear( ply )
end
/*function CanSeePlayers(ent)
	local result = false
	local hit = nil
	for k, ply in pairs (player.GetAll()) do
		if (IsValid(ply)) then
			if (ent:IsLineOfSightClear( ply )) then
				result = true
			end
		end
	end	
end*/

function SpawnEnemy(pos)
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

			spawnedZombies[ent:EntIndex()] = {
				exp = experience,
				totalDamage = 0,
				status = {},
				attackers = {}
			}
			
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
			if (npc == "npc_vortigaunt") then
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
			ent:Fire("StartPatrolling")
			ent:Fire("SetReadinessHigh")
			ent:SetNPCState(NPC_STATE_COMBAT)
			ent:Activate()
			timer.Simple(0.5, function()
				if (IsValid(ent)) then
					net.Start( "SyncNpcStats" )
					net.WriteEntity( ent )
					net.WriteUInt(level, 8)
					net.WriteFloat(ent:Health())
					net.WriteFloat(ent:GetMaxHealth())
					net.WriteString(ent.name)
					net.WriteBool(ent.minion)
					net.Broadcast()
				end
			end)
		end
	end
end

function CleanNPCs()
	local maxcycle = #player.GetAll()
	for k, v in pairs (ents.FindByClass("npc_*")) do
		local inactive = true
		local cycle = 0
		for _, ply in pairs (player.GetAll()) do
			cycle = cycle + 1
			if (IsValid(v) && spawnedZombies[v:EntIndex()]) then
				inactive = inactive && (v:GetPos():Distance(ply:GetPos()) > MAX_DIST)
				if (cycle >= maxcycle && inactive) then
					spawnedZombies[v:EntIndex()] = nil
					v:Remove()
				end
			end
		end
	end
end

function AutoSpawnNPCs()
	if (pvpmode >= 1) then
		return
	end
	MAX_SPAWNS = 15 + 15 * #player.GetAll()
	local status, err = pcall( function()
	local valid_nodes = {}
	local zombies = {}

	if table.Count(player.GetAll()) <= 0 then
		return
	end
	
	if !found_ain then
		ParseFile()
	end

	if !Nodes or table.Count(Nodes) < 1 then
		print("No info_node(s) in map! NPCs will not spawn.")
		return
	end

	if table.Count(Nodes) <= 35 then
		print("NPCs may not spawn well on this map, please try another.")
	end

	local zombies = {}
	for ent_index, _ in pairs(spawnedZombies) do
		if !IsValid(Entity(ent_index)) then
			spawnedZombies[ent_index] = nil
		else
			table.insert(zombies, Entity(ent_index))
		end
	end

	--Check zombie
	for k, v in pairs(zombies) do
		local closest = 99999
		local closest_plr = NULL
		local zombie_pos = v:GetPos()

		for k2, v2 in pairs(player.GetAll()) do
			local dist = zombie_pos:Distance(v2:GetPos())

			if dist < closest then
				closest_plr = v2
				closest = dist
			end
		end

		if closest > MAX_DIST * 1.25 then
			table.RemoveByValue(zombies, v)
			v:Remove()
		end
		if v && IsValid(v) && CHASE_PLAYERS then
			v:SetLastPosition(closest_plr:GetPos())
			v:SetTarget(closest_plr)
			if !v:IsCurrentSchedule(SCHED_FORCED_GO_RUN) then
				v:SetSchedule(SCHED_FORCED_GO_RUN)
			end
		end
	end

	if table.Count(zombies) >= MAX_SPAWNS then
		return
	end

	--Get valid nodes
	for k, v in pairs(Nodes) do
		local valid = false

		for k2, v2 in pairs(player.GetAll()) do
			local dist = v["pos"]:Distance(v2:GetPos())

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

		for k2, v2 in pairs(zombies) do
			local dist = v["pos"]:Distance(v2:GetPos())
			if dist <= 100 then
				valid = false
				break
			end
		end

		valid = valid && !CanSeePlayers(v["pos"] + Vector(0, 0, 50))

		if valid then
			table.insert(valid_nodes, v["pos"])
		end
	end

	--Spawn zombies if not enough
	if table.Count(valid_nodes) > 0 then
		for i = 0, 5 do
			if table.Count(zombies)+i < MAX_SPAWNS then
				local pos = table.Random(valid_nodes) 
				if pos != nil then
					table.RemoveByValue(valid_nodes, pos)
					SpawnEnemy(pos + Vector(0,0,30))
				end
			else
				break
			end
		end
	end
	end) 

	if !status then
		print(err)
	end
end

proficiencies = {}
local function CreateDelayedUpdates()
	local npc = {}
	npc = {
		name = "Combine Cop",
		npc = "npc_metropolice",
		health = function() return math.random(6,8) end,
		size = 1,
		weapon = "ai_weapon_pistol",
		type = "",
		exp = 180,
		chance = 40,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	}

	table.insert( NPCs, npc )
	npc = {
		name = "Veteran Combine Cop",
		npc = "npc_metropolice",
		health = function() return math.random(8,11) end,
		size = 1,
		weapon = "ai_weapon_smg1",
		type = "",
		exp = 200,
		chance = 33,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	}

	table.insert( NPCs, npc )
	npc = {
		name = "Silver Combine Soldier",
		npc = "npc_combine_s",
		health = function() return math.random(16,19) end,
		size = 1.15,
		weapon = "ai_weapon_ar2",
		type = "metal",
		exp = 1000,
		chance = 8,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	}

	table.insert( NPCs, npc )
	npc = {
		name = "Combine Recruit",
		npc = "npc_combine_s",
		health = function() return math.random(5,8) end,
		size = 1,
		weapon = "ai_weapon_smg1",
		type = "",
		exp = 300,
		chance = 23,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	}

	table.insert( NPCs, npc )
	npc = {
		name = "Silver Antlion",
		npc = "npc_antlion",
		health = function() return math.random(17,22) end,
		size = 1.5,
		weapon = "",
		type = "metal",
		exp = 700,
		chance = 10,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	}

	table.insert( NPCs, npc )
	npc = {
		name = "Antlion",
		npc = "npc_antlion",
		health = function() return math.random(9,14) end,
		size = 1,
		weapon = "",
		type = "",
		exp = 200,
		chance = 40,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_AVERAGE
	}

	table.insert( NPCs, npc )
	npc = {
		name = "Fast Zombie",
		npc = "npc_fastzombie",
		health = function() return math.random(12,16) end,
		size = 1,
		weapon = "",
		type = "",
		exp = 200,
		chance = 40,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	}

	table.insert( NPCs, npc )
	npc = {
		name = "Headcrab",
		npc = "npc_headcrab",
		health = function() return math.random(5,8) end,
		size = 1,
		weapon = "",
		type = "",
		exp = 90,
		chance = 40,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_AVERAGE
	}

	table.insert( NPCs, npc )
	npc = {
		name = "Silver Headcrab",
		npc = "npc_headcrab",
		health = function() return math.random(15,19) end,
		size = 2.5,
		weapon = "",
		type = "metal",
		exp = 150,
		chance = 30,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	}

	table.insert( NPCs, npc )
	npc = {
		name = "Fast Headcrab",
		npc = "npc_headcrab_fast",
		health = function() return math.random(3,5) end,
		size = 1,
		weapon = "",
		type = "",
		exp = 90,
		chance = 30,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_AVERAGE
	}

	table.insert( NPCs, npc )
	npc = {
		name = "Manhack",
		npc = "npc_manhack",
		health = function() return math.random(10,12) end,
		size = 1,
		weapon = "",
		type = "",
		exp = 50,
		chance = 40,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	}

	table.insert( NPCs, npc )
	npc = {
		name = "Silver Manhack",
		npc = "npc_manhack",
		health = function() return math.random(15,20) end,
		size = 2.5,
		weapon = "",
		type = "metal",
		exp = 120,
		chance = 20,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	}

	table.insert( NPCs, npc )
	npc = {
		name = "Silver Fast Zombie",
		npc = "npc_fastzombie",
		health = function() return math.random(22,27) end,
		size = 1.5,
		weapon = "",
		type = "metal",
		exp = 500,
		chance = 20,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	}

	table.insert( NPCs, npc )
	npc = {
		name = "Zombie",
		npc = "npc_zombie",
		health = function() return math.random(15,18) end,
		size = 1,
		weapon = "",
		type = "",
		exp = 200,
		chance = 20,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_GOOD
	}
	table.insert( NPCs, npc )

	npc = {
		name = "Combine Soldier",
		npc = "npc_combine_s",
		health = function() return math.random(5,7) end,
		size = 0.85,
		weapon = "ai_weapon_ar2",
		type = "",
		exp = 500,
		chance = 5,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_GOOD
	}
	table.insert( NPCs, npc )

	npc = {
		name = "Super Combine",
		npc = "npc_combine_s",
		health = function() return math.random(220,250) end,
		size = 2,
		weapon = "ai_weapon_ar2",
		type = "",
		exp = 4000,
		chance = 5,
		boss = true,
		proficiency = WEAPON_PROFICIENCY_GOOD
	}
	table.insert( NPCs, npc )

	npc = {
		name = "Antlion Guard",
		npc = "npc_antlionguard",
		health = function() return math.random(300,350) end,
		size = 1,
		weapon = "",
		type = "",
		exp = 5000,
		chance = 5,
		boss = true,
		proficiency = WEAPON_PROFICIENCY_AVERAGE
	}
	table.insert( NPCs, npc )

	npc = {
		name = "Vortigaunt",
		npc = "npc_vortigaunt",
		health = function() return math.random(25,30) end,
		size = 1.25,
		weapon = "",
		type = "",
		exp = 300,
		chance = 15,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	}
	table.insert( NPCs, npc )

	npc = {
		name = "Silver Vortigaunt",
		npc = "npc_vortigaunt",
		health = function() return math.random(50,60) end,
		size = 1.55,
		weapon = "",
		type = "metal",
		exp = 600,
		chance = 10,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_GOOD
	}
	table.insert( NPCs, npc )

	npc = {
		name = "Medic Vortigaunt",
		npc = "npc_vortigaunt",
		health = function() return math.random(30,40) end,
		size = 1,
		weapon = "",
		type = "medic",
		exp = 200,
		chance = 21,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_GOOD
	}
	table.insert( NPCs, npc )

	npc = {
		name = "Medic Rollermine",
		npc = "npc_rollermine",
		health = function() return math.random(15,20) end,
		size = 1,
		weapon = "",
		type = "medic",
		exp = 100,
		chance = 21,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_GOOD
	}
	table.insert( NPCs, npc )

	npc = {
		name = "Rollermine",
		npc = "npc_rollermine",
		health = function() return math.random(20,30) end,
		size = 1,
		weapon = "",
		type = "",
		exp = 250,
		chance = 21,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	}
	table.insert( NPCs, npc )
	
	timer.Simple( 2, function()
		print("Timers created")
		timer.Create( "SyncLevel", 1, 0, UpdateLevel )
		timer.Create( "AutoSpawnTimer" , 5, 0, AutoSpawnNPCs)
		timer.Create( "DelayedUpdate", 0.25, 0, DelayedUpdate )
		//timer.Create( "SaveAllData", 5, 0, SaveAllData )
		timer.Create( "CleanInactiveNPCs", 20, 0, CleanNPCs )
	end)
end
hook.Add( "InitPostEntity", "CreateDelayedUpdates", CreateDelayedUpdates )