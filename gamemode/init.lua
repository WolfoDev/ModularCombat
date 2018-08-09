AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "modules.lua" )

include( "modules.lua" )
include( "spawner.lua" )
include( "shared.lua" )

//resource.AddFile( "materials/ui/vignette.png" ) 
//resource.AddFile( "fonts/vignette.ttf" ) 

resource.AddSingleFile( "materials/fx/circle.png" )
resource.AddSingleFile( "materials/fx/groundbreaker.png" )
resource.AddSingleFile( "materials/fx/hospital-cross.png" )
resource.AddSingleFile( "materials/fx/magic-swirl.png" )
resource.AddSingleFile( "materials/fx/pounce.png" )
resource.AddSingleFile( "materials/fx/shatter.png" )
resource.AddSingleFile( "materials/fx/broken-heart.png" )
resource.AddSingleFile( "materials/fx/broken-skull.png" )
resource.AddSingleFile( "materials/fx/small-fire.png" )
resource.AddSingleFile( "materials/fx/thorns.png" )

resource.AddSingleFile( "materials/ui/vignette_white.png" )
resource.AddSingleFile( "materials/ui/icons/battery-plus.png" )
resource.AddSingleFile( "materials/ui/icons/bell-shield.png" )
resource.AddSingleFile( "materials/ui/icons/bright-explosion.png" )
resource.AddSingleFile( "materials/ui/icons/broken-heart.png" )
resource.AddSingleFile( "materials/ui/icons/caltrops.png" )
resource.AddSingleFile( "materials/ui/icons/health-capsule.png" )
resource.AddSingleFile( "materials/ui/icons/health-increase.png" )
resource.AddSingleFile( "materials/ui/icons/health-normal.png" )
resource.AddSingleFile( "materials/ui/icons/ion-cannon-blast.png" )
resource.AddSingleFile( "materials/ui/icons/land-mine.png" )
resource.AddSingleFile( "materials/ui/icons/quake-stomp.png" )
resource.AddSingleFile( "materials/ui/icons/sentry-gun.png" )
resource.AddSingleFile( "materials/ui/icons/shield-reflect.png" )
resource.AddSingleFile( "materials/ui/icons/targeting.png" )
resource.AddSingleFile( "materials/ui/icons/wolf-trap.png" )
resource.AddSingleFile( "materials/ui/icons/aerodynamic-harpoon.png" )
resource.AddSingleFile( "materials/ui/icons/broadhead-arrow.png" )
resource.AddSingleFile( "materials/ui/icons/chemical-arrow.png" )
resource.AddSingleFile( "materials/ui/icons/arrow-dunk.png" )
resource.AddSingleFile( "materials/ui/icons/sprint.png" )
resource.AddSingleFile( "materials/ui/icons/grenade.png" )
resource.AddSingleFile( "materials/ui/icons/molotov.png" )
resource.AddSingleFile( "materials/ui/icons/supersonic-bullet.png" )
resource.AddSingleFile( "materials/ui/icons/bullets.png" )
resource.AddSingleFile( "materials/ui/icons/crowbar.png" )
resource.AddSingleFile( "materials/ui/icons/fangs.png" )
resource.AddSingleFile( "materials/ui/icons/rosa-shield.png" )
resource.AddSingleFile( "materials/ui/icons/jet-pack.png" )
resource.AddSingleFile( "materials/ui/icons/heart-inside.png" )
resource.AddSingleFile( "materials/ui/icons/morph-ball.png" )
resource.AddSingleFile( "materials/ui/icons/static-guard.png" )

GM.PlayerSpawnTime = {}
local delays = {}

util.AddNetworkString( "SyncLevel" )
util.AddNetworkString( "SyncExperience" )
util.AddNetworkString( "SyncProfile" )
util.AddNetworkString( "SyncSelectedProfile" )
util.AddNetworkString( "SyncStamina" )
util.AddNetworkString( "SyncDamageAmount" )
util.AddNetworkString( "SyncPoints" )
util.AddNetworkString( "SyncModules" )
util.AddNetworkString( "SyncModulesCd" )
util.AddNetworkString( "SyncShop" )
util.AddNetworkString( "SyncStatus" )
util.AddNetworkString( "SyncNpcDeath" )
util.AddNetworkString( "SyncNpcStats" )
util.AddNetworkString( "SyncVotes" )

util.AddNetworkString( "UseModuleCL" )
util.AddNetworkString( "SetModuleCooldownCL" )
util.AddNetworkString( "SelectModuleCL" )
util.AddNetworkString( "HealEffectCL" )
util.AddNetworkString( "CriticalEffectCL" )
util.AddNetworkString( "SkillHitEffectCL" )
util.AddNetworkString( "PlayMusicCL" )
util.AddNetworkString( "DrawWorldTextCL" )
util.AddNetworkString( "DrawScreenTextCL" )

util.AddNetworkString( "SelectModuleSV" )
util.AddNetworkString( "BuyModuleSV" )
util.AddNetworkString( "UseModuleSV" )
util.AddNetworkString( "ChangeProfileNameSV" )
util.AddNetworkString( "SelectProfileSV" )
util.AddNetworkString( "ResetProfileSV" )
util.AddNetworkString( "SaveDataSV" )
util.AddNetworkString( "VoteKickSV" )
util.AddNetworkString( "VoteSV" )

/*local music = {
	"music/HL2_song12_long.mp3",
	"music/HL2_song14.mp3",
	"music/HL2_song16.mp3",
	"music/HL2_song3.mp3",
	"music/HL2_song4.mp3",
	"music/HL2_song6.mp3",
	"music/HL2_song29.mp3",
	"music/HL2_song31.mp3",
	"music/HL2_song19.mp3"
}*/
pvpmode = 0
local music = {"music/HL2_song26_trainstation2.mp3", "music/HL2_song26_trainstation1.mp3"}


local function SwitchProfile(ply, profile)
	MC.SaveData(ply)
	ply:Spawn()
	MC.LoadData(ply, profile)
	net.Start( "SyncSelectedProfile" )
	net.WriteUInt( profile, 16 )
	net.Send(ply)
end

net.Receive("VoteSV", function(len, ply)
	local voteType = net.ReadString()
	local isCancel = string.find(voteType, "cancel")
	if (string.find(voteType, "map")) then
		if (isCancel) then
			ply.votemap = 0
			ply:ChatPrint("Map-change vote revoked.")
		else
			ply.votemap = 1
			ply:ChatPrint("Map-change vote forwarded.")
		end
	elseif (string.find(voteType, "pvp")) then
		if (isCancel) then
			ply.votepvp = 0
			ply:ChatPrint("PvP vote revoked.")
		else
			ply.votepvp = 1
			ply:ChatPrint("PvP vote forwarded.")
		end
	end
end)

net.Receive("VoteKickSV", function(len, ply)
	local playerToKick = net.ReadString()
	if (playerToKick == "NULL") then playerToKick = "BOT" end

	local v = player.GetBySteamID(playerToKick)
	if (!v) then
		return
	end
	
	if (!v:IsAdmin() && v != ply) then
		if (ply:IsAdmin()) then
			v:Kick()
		else
			for _, voter in pairs (ply.kickvotes) do
				if (!player.GetBySteamID( voter )) then
					table.RemoveByValue(ply.kickvotes, voter)
				end
			end
			local voter = ply:SteamID()
			if (!table.HasValue(v.kickvotes, voter)) then
				table.insert(v.kickvotes, voter)
			end
			if (table.Count(v.kickvotes) >= (table.Count(player.GetAll()) - 1)) then
				v:Kick()
			end
			timer.Simple(300, function()
				if (IsValid(v) && table.HasValue(v.kickvotes, voter)) then
					table.RemoveByValue(v.kickvotes, voter)
				end
			end)
		end
	end
end)

net.Receive("SelectModuleSV", function(len, ply)
	ply.useModule = net.ReadUInt(8)
end)

net.Receive("UseModuleSV", function(len, ply)
	ply:UseModule(net.ReadUInt(8))
end)

net.Receive("ChangeProfileNameSV", function(len, ply)
	local id = net.ReadUInt(16)
	local name = net.ReadString()
	MC.RenameProfile(ply, id, name)
end)

net.Receive("SelectProfileSV", function(len, ply)
	local id = net.ReadUInt(16)
	if (id != ply.profile) then
		SwitchProfile(ply, id)
	end
end)

net.Receive("ResetProfileSV", function(len, ply)
	local id = net.ReadUInt(16)
	MC.ResetData(ply, id)
	if (tonumber(id) == tonumber(ply.profile)) then
		SwitchProfile(ply, id)
	end
end)

net.Receive("SaveDataSV", function(len, ply)
	MC.SaveData(ply)
end)

net.Receive("BuyModuleSV", function(len, ply)
	local modNum = net.ReadUInt(8)
	
	if (ply.modules[modNum] == nil) then ply.modules[modNum] = 0 end
	if (ply.modulesCd[modNum] == nil) then ply.modulesCd[modNum] = 0 end
	local cost = MC.modules[modNum].cost
	if (cost == nil || ply.modules[modNum] >= 1) then cost = 1 end
	
	if (ply.points >= cost && ply.modules[modNum] < 10) then
		ply.points = ply.points - cost
		ply.modules[modNum] = ply.modules[modNum] + 1
		net.Start( "SyncShop" )
		net.WriteTable( ply.modules )
		net.Send(ply)
	end
end)

local function RandomPlayersSpawn()
	local spawned = {}
	for __, ply in pairs (player.GetAll()) do
		for k, v in pairs(Nodes) do
			local canSpawn = true
			for _, other in pairs (spawned) do
				canSpawn = canSpawn && (v["pos"]:Distance(other:GetPos()) >= MIN_DIST)
			end
			if (canSpawn) then
				table.insert(spawned, ply)
				ply:SetPos(v["pos"])
				break
			end
		end
	end
end

local function RandomPlayerSpawn(ply)
	for k, v in pairs(Nodes) do
		local canSpawn = true
		for _, other in pairs (player.GetAll()) do
			if (other == ply) then continue end
			canSpawn = canSpawn && (v["pos"]:Distance(other:GetPos()) >= MIN_DIST)
		end
		if (canSpawn) then
			ply:SetPos(v["pos"])
			break
		end
	end
end

local function EverySpawn(ply)
	ply:AllowFlashlight( true )
	ply:StripWeapons()
	ply:StripAmmo()
	ply:SetWalkSpeed(150)
	ply:SetRunSpeed(275)
	ply:Give("weapon_pistol")
	ply:Give("weapon_smg1")
	ply:Give("weapon_crowbar")
	ply:GiveAmmo( 150, "Pistol", true )
	ply:GiveAmmo( 120, "smg1", true )
	ply:GiveAmmo( 30, "ar2", true )
	ply:SetHealth(ply:HealthFormula())
	ply:SetModel("models/player/soldier_stripped.mdl")
	if (pvpmode == 0) then
		ply:SetTeam(0)
		ply.immortal = true
		hook.Add("Think", "CheckPlayerMovement"..ply:EntIndex(), function()
			if (IsValid(ply) && ply:GetVelocity():Length() >= 60) then
				ply.immortal = false
				hook.Remove("Think", "CheckPlayerMovement"..ply:EntIndex())
			end
		end)
		ply.votepvp = 0
	else
		ply:SetTeam(math.random(0, 999))
		RandomPlayerSpawn(ply)
		ply.votepvp = 1
	end
end
hook.Add( "PlayerSpawn", "PlayerEverySpawn", EverySpawn )

local function TogglePvp()
	pvpmode = (pvpmode + 1) % 2

	for k, v in pairs (player.GetAll()) do
		v:Spawn()
	end

	if (pvpmode == 1) then
		for k, v in pairs (ents.FindByClass("npc_*")) do
			v:Remove()
		end
	end

end
concommand.Add("TogglePvp", TogglePvp)

local function InitSpawn(ply)
	if (ply.kickvotes == nil) then ply.kickvotes = {} end
	if (ply.profile == nil) then ply.profile = 1 end
	if (ply.profileName == nil) then ply.profileName = "New Profile" end
	if (ply.level == nil) then ply.level = 1 end
	if (ply.exp == nil) then ply.exp = 0 end
	if (ply.stamina == nil) then ply.stamina = 100 end
	if (ply.points == nil) then ply.points = 2 end
	if (ply.useModule == nil) then ply.useModule = -1 end
	if (ply.modules == nil) then ply.modules = {} end
	if (ply.modulesCd == nil) then ply.modulesCd = {} end
	ply.votemap = 0
	MC.LoadData(ply)
	timer.Simple(1, function()
		net.Start( "SelectModuleCL" )
		net.WriteInt( ply.useModule, 8 )
		net.Send(ply)
	end)
	net.Start( "PlayMusicCL" )
	net.WriteTable( music )
	net.Send(ply)
	local sid = ply:SteamID()
	timer.Create( "SavePlayerData" .. sid, 5, 0, function() SavePlayerData(ply, sid) end)
end
hook.Add( "PlayerInitialSpawn", "PlayerFirstSpawn", InitSpawn )

function SavePlayerData(ply, sid)
	//print("SAVING " .. ply:Nick() .. " DATA")
	if (IsValid(ply)) then
		MC.SaveData(ply)
		for p = 1, PROFILES_AMOUNT do
			net.Start( "SyncProfile" )
			net.WriteUInt( p, 16 )
			net.WriteUInt( ply:GetPData(p .. "_level", 1), 16 )
			net.Send(ply)
		end
		net.Start( "SyncSelectedProfile" )
		net.WriteUInt( ply.profile, 16 )
		net.Send(ply)
	else
		timer.Destroy("SavePlayerData" .. sid)
	end
end

function SaveAllData()
	for i, ply in ipairs (player.GetAll()) do
		timer.Simple(i * 0.25, function()
			MC.SaveData(ply)
			for p = 1, PROFILES_AMOUNT do
				net.Start( "SyncProfile" )
				net.WriteUInt( p, 16 )
				net.WriteUInt( ply:GetPData(p .. "_level", 1), 16 )
				net.Send(ply)
			end
			net.Start( "SyncSelectedProfile" )
			net.WriteUInt( ply.profile, 16 )
			net.Send(ply)
		end)
	end
	/*for k, ent in pairs (ents.FindByClass("npc_*")) do
		net.Start( "SyncNpcStats" )
		net.WriteEntity( ent )
		net.WriteUInt(ent.level || 1, 8)
		net.Broadcast()
	end*/
end

function DelayedUpdate()
	local missingPvpVotes = table.Count(player.GetAll())
	local missingMapVotes = table.Count(player.GetAll())
	for _, ply in pairs (player.GetAll()) do
		if (ply.staminaGainDelay == nil) then ply.staminaGainDelay = 0 end

		if (ply.level >= MAX_LEVEL) then
			ply.exp = ply:NextExpFormula()
			ply.level = MAX_LEVEL
		elseif (ply.exp >= ply:NextExpFormula()) then
			ply.exp = ply.exp - ply:NextExpFormula();
			ply.level = ply.level + 1
			ply.points = ply.points + ply:PointsPerLevelFormula()
			ply:EmitSound("items/suitchargeok1.wav")
			ply:GainHealth(999)
		end

		ply:SetMaxHealth(ply:HealthFormula())
		//speed = ply:SpeedFormula()
		local amount = ply:StaminaFormula() * ply:StaminaGainFormula()
		if (ply.stamina < ply:StaminaFormula() * 0.2) then
			amount = ply:StaminaFormula() * ply:StaminaGainFormula() * 0.5
			//speed = ply:GetWalkSpeed()
		end
		if ( ply:IsRunning() && ply.stamina >= ply:StaminaDrainFormula() ) then
			ply:DrainStamina(ply:StaminaDrainFormula(), true)
		elseif (ply.stamina < ply:StaminaFormula()) then
			if (ply.staminaGainDelay <= CurTime()) then ply.stamina = ply.stamina + amount end
		else
			ply.stamina = ply:StaminaFormula()
		end
		//ply:SetRunSpeed(speed);
		if (ply.votepvp && ply.votepvp == 1) then
			missingPvpVotes = missingPvpVotes - 1
		end
		if (ply.votemap && ply.votemap == 1) then
			missingMapVotes = missingMapVotes - 1
		end

		
		net.Start( "SyncStamina" )
		net.WriteUInt( ply.stamina, 10 )
		net.Send(ply)
		
		net.Start( "SyncPoints" )
		net.WriteEntity( ply )
		net.WriteUInt( ply.points, 10 )
		net.Broadcast()
		
		if (ply.modules != nil) then
			net.Start( "SyncModules" )
			net.WriteTable( ply.modules )
			net.Send(ply)
		end
		
		net.Start( "SyncStatus" )
		net.WriteBool(ply.vulnerable)
		net.WriteBool(ply.weakened)
		net.WriteBool(ply.burned)
		net.WriteBool(ply.poisoned)
		net.Send(ply)
	end

	net.Start( "SyncVotes" )
	net.WriteInt(table.Count(player.GetAll()) - missingPvpVotes, 16)
	net.WriteInt(table.Count(player.GetAll()) - missingMapVotes, 16)
	//net.WriteInt(0, 16)
	net.Broadcast()

	if ((missingPvpVotes <= 0 && pvpmode != 1) || (missingPvpVotes > 0 && pvpmode == 1)) then
		TogglePvp()
	end

	if (missingMapVotes <= 0) then
		//TODO
	end

	for k, ent in pairs (ents.FindByClass("npc_*")) do
		net.Start( "SyncNpcStats" )
		net.WriteEntity( ent )
		net.WriteUInt(ent.level || 1, 8)
		net.WriteFloat(ent.health || ent:Health())
		net.WriteBool(ent.boss)
		net.WriteString(ent.name || "ENEMY")
		net.WriteBool(ent.minion || false)
		net.WriteEntity(ent.owner || NULL)
		net.Broadcast()
	end
	
end

hook.Add( "DoAnimationEvent" , "ExtraClipOnReload" , function( ply , event , data )
	local wep = ply:GetActiveWeapon()
	local modPwr = ply:GetModuleUpgrade(MC.modulesByName.increasedClipSize)
	if (IsValid(wep) && event == PLAYERANIMEVENT_RELOAD && modPwr > 0) then
		local oldClip = wep:Clip1()

		hook.Add("Think", "FillClip" .. ply:EntIndex(), function()
			local curWep = ply:GetActiveWeapon()
			if (!IsValid(curWep) || curWep != wep) then

				hook.Remove("Think", "FillClip" .. ply:EntIndex())
				sound.Play("player/suit_denydevice.wav", ply:GetPos())

			elseif (curWep:Clip1() == curWep:GetMaxClip1()) then

				local ammoType = curWep:GetPrimaryAmmoType()
				local curAmmo = ply:GetAmmoCount(ammoType)

				local extra = curWep:GetMaxClip1() * modPwr
				local totalClip = math.Round(curWep:GetMaxClip1() + extra)
				if (oldClip >= curWep:GetMaxClip1()) then extra = (totalClip - oldClip) end

				curWep:SetClip1(totalClip)
				ply:SetAmmo( curAmmo - extra, ammoType)

				sound.Play("npc/roller/blade_in.wav", curWep:GetPos())
				hook.Remove("Think", "FillClip" .. ply:EntIndex())

			end
		end)
	end
end)

function UpdateLevel()
	for _, ply in pairs (player.GetAll()) do
		net.Start( "SyncLevel" )
		net.WriteEntity( ply )
		net.WriteUInt( ply.level, 8 )
		net.Broadcast()
		
		net.Start( "SyncExperience" )
		net.WriteUInt( ply.exp, 16 )
		net.Send(ply)
	end
end

function ManageModulesCooldowns()
	for _, ply in pairs (player.GetAll()) do
		if (ply.modulesCd == nil) then ply.modulesCd = {} end
		for k, v in pairs (ply.modulesCd) do
			if (ply.modulesCd[k] > 0) then
				ply.modulesCd[k] = ply.modulesCd[k] - 0.1
				if (ply.modulesCd[k] == 0) then
					net.Start( "SyncModulesCd" )
					net.WriteUInt( k, 8 )
					net.Send(ply)
				end
			end
		end
	end
end
timer.Create( "ManageModulesCooldowns", 0.1, 0, ManageModulesCooldowns )

function GM:GetFallDamage( ply, speed )
	local falldmg = 0 // math.max( 0, math.ceil( 0.2418*speed - 141.75 ) )
	return falldmg
end

--[[---------------------------------------------------------
   Name: gamemode:Initialize()
   Desc: Called immediately after starting the gamemode
-----------------------------------------------------------]]
function GM:Initialize()
end

--[[---------------------------------------------------------
   Name: gamemode:InitPostEntity()
   Desc: Called as soon as all map entities have been spawned
-----------------------------------------------------------]]
function GM:InitPostEntity()
end

--[[---------------------------------------------------------
   Name: gamemode:Think()
   Desc: Called every frame
-----------------------------------------------------------]]
function GM:Think()
end

--[[---------------------------------------------------------
   Name: gamemode:ShutDown()
   Desc: Called when the Lua system is about to shut down
-----------------------------------------------------------]]
function GM:ShutDown()
end

--[[---------------------------------------------------------
   Name: gamemode:DoPlayerDeath( )
   Desc: Carries out actions when the player dies
-----------------------------------------------------------]]
function GM:DoPlayerDeath( ply, attacker, dmginfo )

	ply:CreateRagdoll()
	
	ply:AddDeaths( 1 )
	
	if ( attacker:IsValid() && attacker:IsPlayer() ) then
	
		if ( attacker == ply ) then
			attacker:AddFrags( -1 )
		else
			attacker:AddFrags( 1 )
		end
	
	end

end


--[[---------------------------------------------------------
   Name: gamemode:ScaleNPCDamage()
-----------------------------------------------------------]]
function GM:ScaleNPCDamage( npc, hitgroup, dmginfo )
	local percent = 0
	local atk = dmginfo:GetAttacker()

	if (hitgroup == HITGROUP_HEAD) then
		dmginfo:ScaleDamage( 0.5 + percent )
		dmginfo:SetReportedPosition(Vector(1, 0, 0))
	else
		dmginfo:ScaleDamage( 0.25 + percent )
	end
end

--[[---------------------------------------------------------
   Name: gamemode:EntityTakeDamage( ent, dmginfo )
   Desc: The entity has received damage
-----------------------------------------------------------]]
function GM:EntityTakeDamage( ent, dmginfo )
	local atk = dmginfo:GetAttacker()

	if (atk:IsNPC()) then
		if (!ent.minion) then
			dmginfo:SetDamage(atk:DamageFormulaNPC(dmginfo:GetDamage()))
		end
		if (atk:GetClass() == "npc_vortigaunt") then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.4)
		end
		if (ent:IsNPC() && atk.type && atk.type == "medic") then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0)
			local health = math.min(ent:Health() + atk:HealthFormulaNPC(6), ent:GetMaxHealth())
			local healed = health - ent:Health()
			ent:SetHealth(health)
			ShowWorldText(ent:LocalToWorld(ent:OBBCenter()), "+"..math.Round(healed * 10).." HP", "heal")
		end
		if (atk.minion && atk.damage) then
			dmginfo:SetDamage(atk.damage)
			ShowDamageText(dmginfo:GetDamagePosition(), dmginfo:GetDamage() * 10, "skill")
			if (ent:IsNPC()) then ent:AddEntityRelationship(atk, D_HT, 99) end
		end
		if (ent.minion) then
			ShowDamageText(dmginfo:GetDamagePosition(), dmginfo:GetDamage() * 10, "default")
		end
	end

	if (IsValid(atk) && atk.weakened) then
		dmginfo:SetDamage(dmginfo:GetDamage() * 0.5)
	end
	
	if (ent:IsPlayer()) then
		if (ent.shield) then
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.5)
		end

		if (ent.vulnerable) then
			dmginfo:SetDamage(dmginfo:GetDamage() * 1.25)
		end

		local fwd = ent:EyeAngles():Forward()
		local normal = (atk:GetPos() - ent:EyePos()):GetNormalized()
		local isBehindPly = fwd:Dot(normal) < 0
		if (ent.absorb && atk && !isBehindPly) then
			ent:GainHealth(dmginfo:GetDamage())
			ShowWorldText(ent:LocalToWorld(ent:OBBCenter()) + ent:GetForward() * 15, "+"..math.Round(dmginfo:GetDamage()).." HP", "heal")
			dmginfo:SetDamage(0)
		end
		if (ent.reflect && atk && !isBehindPly) then
			local refDmg = dmginfo
			refDmg:SetAttacker(ent)
			refDmg:SetInflictor(atk)
			atk:TakeDamageInfo(refDmg)
			dmginfo:SetDamage(0)
		end

		if (ent.immortal) then
			dmginfo:SetDamageForce(Vector(0, 0, 0))
			dmginfo:SetDamage(0)
		end
	end

	if (atk:IsPlayer() && ent:IsPlayer() && atk:Team() == ent:Team()) then
		dmginfo:SetDamage(0)
	end


	if (atk:IsPlayer() && ent:IsMinion(atk)) then
		dmginfo:SetDamage(0)
		dmginfo:SetDamageForce(Vector(0, 0, 0))
	end
	if (atk:IsPlayer() && ent:IsEnemy(atk)) then
		if (ent.vulnerable) then
			dmginfo:SetDamage(dmginfo:GetDamage() * 1.25)
		end
		local modPwr = atk:GetModuleUpgrade(MC.modulesByName.criticalHits)
		local criticalChance = math.random(0, 100)
		if (modPwr > 0 && criticalChance <= modPwr * 100 && dmginfo:GetInflictor() == atk) then
			dmginfo:SetDamage(dmginfo:GetDamage() * 1.5)
			net.Start( "CriticalEffectCL" )
			net.WriteVector(dmginfo:GetDamagePosition())
			net.Broadcast()
			dmginfo:SetReportedPosition(Vector(2, 0, 0))
		end
		if (dmginfo:IsBulletDamage()) then
			local modPwr = atk:GetModuleUpgrade(MC.modulesByName.increasedRangedDmg)

			if (modPwr > 0) then
				local extra = 1 + modPwr
				dmginfo:SetDamage(dmginfo:GetDamage() * extra)
			end
		elseif (dmginfo:IsDamageType(DMG_CLUB)) then
			local modPwr = atk:GetModuleUpgrade(MC.modulesByName.increasedMeleeDmg)

			if (modPwr > 0) then
				local extra = 1 + modPwr
				dmginfo:SetDamage(dmginfo:GetDamage() * extra)
			end
		end
		if (dmginfo:IsDamageType(DMG_CLUB)) then
			local modPwr = atk:GetModuleUpgrade(MC.modulesByName.lifeSteal)
			
			if (modPwr > 0) then
				local healed = dmginfo:GetDamage() * modPwr * 10
				atk:GainHealth(healed)
				ShowWorldText(ent:LocalToWorld(ent:OBBCenter()), "+"..math.Round(healed).." HP", "heal")
			end
		end
		if (ent:IsPlayer()) then
			if (dmginfo:GetInflictor() == ent) then
				dmginfo:SetDamage(dmginfo:GetDamage() * 0.80)
			else
				dmginfo:SetDamage(dmginfo:GetDamage() * 0.55)
			end
		end
		if (ent:IsMinion(atk)) then
			dmginfo:SetDamage(dmginfo:GetDamage() * 2)
		end

		local type = "default"
		local traceFx = nil
		local pos = dmginfo:GetDamagePosition()
		if (dmginfo:GetReportedPosition().x == 1) then
			type = "critical"
		end
		if (dmginfo:GetReportedPosition().x == 2) then
			type = "critical"
			traceFx = "vortigaunt_beam"
		end

		if (dmginfo:GetInflictor():IsNPC() || dmginfo:GetInflictor() == ent) then
			pos = (ent:GetPos() + ent:GetUp() * 50)
			type = "skill"
		else
			if (IsValid(atk) && atk:IsPlayer() && dmginfo:GetDamagePosition() != Vector(0, 0, 0) && dmginfo:GetDamage() > 0) then
				local wep = atk:GetActiveWeapon()
				local startPos = atk:LocalToWorld(atk:OBBCenter())
				if (wep && wep:LookupAttachment("muzzle")) then
					if (traceFx) then
						util.ParticleTracerEx( traceFx, startPos, dmginfo:GetDamagePosition(), false, wep:EntIndex(), wep:LookupAttachment("muzzle") )//atk:LookupAttachment("eyes")
					//elseif (dmginfo:IsBulletDamage()) then
					//	ShowBulletFx(atk, startPos, dmginfo:GetDamagePosition())
					end
				end
			end
		end
		ShowDamageText(pos, dmginfo:GetDamage() * 10, type)
	end

	if (ent.health) then ent.health = ent.health - dmginfo:GetDamage() end
	if (ent:Health() <= dmginfo:GetDamage() * 2) then
		dmginfo:SetDamageType( DMG_DISSOLVE )
	end
end

function ShowBulletFx(ply, pos, hitPos)
	timer.Simple(0.025, function()
		local bullet = {}
		bullet.Attacker = nil
		bullet.Force = 0
		bullet.Num = 1
		bullet.Damage = 0
		bullet.TracerName = "AirboatGunHeavyTracer" //"GunshipTracer"
		bullet.Dir = (hitPos - pos):GetNormalized()
		bullet.Src = pos
		ply:FireBullets(bullet)
	end)
end

function ShowDamageText(pos, dmg, type)
	net.Start( "SyncDamageAmount" )
	net.WriteVector(pos)
	net.WriteInt(dmg, 16)
	net.WriteString(type)
	net.Broadcast()
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerHurt( )
   Desc: Called when a player is hurt.
-----------------------------------------------------------]]
function GM:PlayerHurt( player, attacker, healthleft, healthtaken )
end

--[[---------------------------------------------------------
   Name: gamemode:CreateEntityRagdoll( entity, ragdoll )
   Desc: A ragdoll of an entity has been created
-----------------------------------------------------------]]
function GM:CreateEntityRagdoll( entity, ragdoll )
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerNoClip( ply, active )
-----------------------------------------------------------]]
function GM:PlayerNoClip( ply, active )
	ply:UseModule()
	return false
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerCanPickupWeapon( ply, wep )
-----------------------------------------------------------]]
function GM:PlayerCanPickupWeapon( ply, wep )
	return true
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerCanPickupItem( ply, item )
-----------------------------------------------------------]]
function GM:PlayerCanPickupItem( ply, item )
	return true
end

-- Set the ServerName every 30 seconds in case it changes..
-- This is for backwards compatibility only - client can now use GetHostName()
local function HostnameThink()

	SetGlobalString( "ServerName", GetHostName() )

end

timer.Create( "HostnameThink", 30, 0, HostnameThink )

--[[---------------------------------------------------------
	Show the default team selection screen
-----------------------------------------------------------]]
function GM:ShowTeam( ply )

	if ( !GAMEMODE.TeamBased ) then return end
	
	local TimeBetweenSwitches = GAMEMODE.SecondsBetweenTeamSwitches or 10
	if ( ply.LastTeamSwitch && RealTime() - ply.LastTeamSwitch < TimeBetweenSwitches ) then
		ply.LastTeamSwitch = ply.LastTeamSwitch + 1
		ply:ChatPrint( Format( "Please wait %i more seconds before trying to change team again", ( TimeBetweenSwitches - ( RealTime() - ply.LastTeamSwitch ) ) + 1 ) )
		return false
	end
	
	-- For clientside see cl_pickteam.lua
	ply:SendLua( "GAMEMODE:ShowTeam()" )

end

--
-- CheckPassword( steamid, networkid, server_password, password, name )
--
-- Called every time a non-localhost player joins the server. steamid is their 64bit
-- steamid. Return false and a reason to reject their join. Return true to allow
-- them to join.
--
function GM:CheckPassword( steamid, networkid, server_password, password, name )

	-- The server has sv_password set
	if ( server_password != "" ) then

		-- The joining clients password doesn't match sv_password
		if ( server_password != password ) then
			return false
		end

	end
	
	--
	-- Returning true means they're allowed to join the server
	--
	return true

end

--[[---------------------------------------------------------
   Name: gamemode:FinishMove( player, movedata )
-----------------------------------------------------------]]
function GM:VehicleMove( ply, vehicle, mv )

	--
	-- On duck toggle third person view
	--
	if ( mv:KeyPressed( IN_DUCK ) && vehicle.SetThirdPersonMode ) then
		vehicle:SetThirdPersonMode( !vehicle:GetThirdPersonMode() )
	end

	--
	-- Adjust the camera distance with the mouse wheel
	--
	local iWheel = ply:GetCurrentCommand():GetMouseWheel()
	if ( iWheel != 0 && vehicle.SetCameraDistance ) then
		-- The distance is a multiplier
		-- Actual camera distance = ( renderradius + renderradius * dist )
		-- so -1 will be zero.. clamp it there.
		local newdist = math.Clamp( vehicle:GetCameraDistance() - iWheel * 0.03 * ( 1.1 + vehicle:GetCameraDistance() ), -1, 10 )
		vehicle:SetCameraDistance( newdist )
	end

end
