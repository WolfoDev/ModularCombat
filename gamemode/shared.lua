PROFILES_AMOUNT = 6
MAX_LEVEL = 25

GM.Name			= "Modular Combat"
GM.Author		= "Wolfo"
GM.Email		= "wolfosobastardo@gmail.com"
GM.Website		= "wolfoso.itch.io"
GM.TeamBased	= false

function hex(hex)
    hex = hex:gsub("#","")
    return Color(tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)), 255)
end

meta = FindMetaTable( "Player" )

function meta:PointsPerLevelFormula()
	local points = 3
	if (self.level > 5) then
		points = 2
	end
	if (self.level > 15) then
		points = 1
	end
	return points
end

function meta:NextExpFormula()
	local nextexp = math.Round( 200 * (math.pow(1.1, self.level || 1)) )
	return nextexp
end

function meta:HealthFormula()
	local health = 100 * (math.pow(1.066, self.level || 1))
	local index = MC.modulesByName.increasedHp
	local mod = MC.modules[index]
	if (SERVER) then
		if (self.modules != nil && self.modules[index] != nil && self.modules[index] >= 1) then
			local modLv = self.modules[index]
			health = health + mod.upgrades[modLv]
		end
	elseif (CLIENT) then
		if (modulesLevels[index] != nil && modulesLevels[index] >= 1) then
			local modLv = modulesLevels[index]
			health = health + mod.upgrades[modLv]
		end
	end
	return health
end

function meta:StaminaFormula()
	local stamina = 100 * (math.pow(1.01, self.level || 1))
	local index = MC.modulesByName.increasedAux
	local mod = MC.modules[index]
	if (SERVER) then
		if (self.modules != nil && self.modules[index] != nil && self.modules[index] >= 1) then
			local modLv = self.modules[index]
			stamina = stamina + mod.upgrades[modLv]
		end
	elseif (CLIENT) then
		if (modulesLevels[index] != nil && modulesLevels[index] >= 1) then
			local modLv = modulesLevels[index]
			stamina = stamina + mod.upgrades[modLv]
		end
	end
	return stamina
end

function meta:StaminaDrainFormula()
	local drain = 2.5
	return drain
end

function meta:StaminaGainFormula()
	local gain = 0.1
	return gain
end

function meta:SpeedFormula()
	local speed = 270 * (math.pow(1.05, self.level || 1))
	return speed
end

function GM:Initialize()
	GAMEMODE.ShowScoreboard = false
end

function meta:IsRunning( )
	return self:KeyDown( IN_SPEED ) && self:GetVelocity():Length() >= 1
end

function meta:DrainStamina(drain, isWalk)
	isWalk = isWalk || false
	self.stamina = self.stamina - drain
	if (self.stamina <= self:StaminaFormula() * 0.2) then
		if (isWalk && self.staminaGainDelay <= CurTime() + 1) then
			self.staminaGainDelay = CurTime() + 1
		else
			self.staminaGainDelay = CurTime() + 1.5
		end
	else
		if (isWalk && self.staminaGainDelay <= CurTime() + 0.5) then
			self.staminaGainDelay = CurTime() + 0.5
		else
			self.staminaGainDelay = CurTime() + 1
		end
	end
end

function meta:GainHealth(gain)
	if (self:Health() + gain <= self:HealthFormula()) then
		self:SetHealth(self:Health() + gain)
	else
		self:SetHealth(self:HealthFormula())
	end
	local healed = math.Clamp(gain * 0.1, 0.5, 2)
	net.Start( "HealEffectCL" )
	net.WriteFloat(healed)
	net.Send(self)
end

function meta:CanUseModule(num)
	local mod = MC.modules[num]
	return self:Alive() && mod && mod.execute != nil && (self.modulesCd[num] == nil || self.modulesCd[num] <= 0) && self.modules[num] != nil && self.modules[num] >= 1 && self.stamina >= mod.drain
end

function meta:UseModule(modNum)
	local isDefault = true
	if (modNum) then isDefault = false end
	local modId = modNum || self.useModule
	local mod = MC.modules[modId]
	local pos = self:GetPos()
	if (!self:CanUseModule(modId)) then
		sound.Play("player/suit_denydevice.wav", pos)
		local cd = self.modulesCd[modNum] || 0
		if (cd > 0) then
			ShowScreenText(self:EyePos() + self:EyeAngles():Forward() * 50, ""..TransformCooldown(cd).."s", "cd")
		end
		return
	end
	if (mod.grenade) then //if grenade, throw a grenade then execute module when nade is touched
		local id = CurTime()
		local grenade = self:CreateGrenade("prop_physics", mod.grenade)    

		/*local collisionCheck = function()
			if (grenade && IsValid(grenade)) then
				local physObj = grenade:GetPhysicsObject()
				if (IsValid(physObj)) then
					local nadeBase = grenade:LocalToWorld(grenade:OBBMins())
					local touchGround = util.QuickTrace(nadeBase, nadeBase + Vector(0, 0, -1000), {grenade, self})
					if (touchGround.HitPos:Distance(nadeBase) <= 10 || (physObj:GetVelocity():Length() <= 5 && touchGround.HitPos:Distance(nadeBase) <= 30)) then
						pos = grenade:GetPos()
						mod.execute(self, modId, self.modules[modId], pos) //execute module on grenade's pos before removal
						for k, v in pairs (player.GetAll()) do //do the CL stuff
							net.Start( "UseModuleCL" )
							net.WriteEntity( self )
							net.WriteUInt( modId, 8 )
							net.WriteUInt( self.modules[modId], 8 )
							net.WriteVector( pos )
							net.Send(v)
						end
						grenade:Remove()
						hook.Remove("Think", "GrenadeCollisionCheckSV" .. id)
					end
				end
			end
		end*/

		local collisionCheck = function(ent, coll)
			if (!IsValid(self)) then
				ent:Remove()
			end
			if (IsValid(ent) && (coll.HitEntity != ent && coll.HitEntity != self)) then
				pos = ent:GetPos()
				mod.execute(self, modId, self.modules[modId], pos) //execute module on grenade's pos before removal
				for k, v in pairs (player.GetAll()) do //do the CL stuff
					net.Start( "UseModuleCL" )
					net.WriteEntity( self )
					net.WriteUInt( modId, 8 )
					net.WriteUInt( self.modules[modId], 8 )
					net.WriteVector( pos )
					net.Send(v)
				end
				ent:Remove()
			end
		end

		//hook.Add("Think", "GrenadeCollisionCheckSV" .. id, collisionCheck)
		grenade:AddCallback( "PhysicsCollide", collisionCheck )

		self.modulesCd[modId] = mod.cooldown
		self:DrainStamina(mod.drain)
		net.Start( "SetModuleCooldownCL" )
		net.WriteUInt(modId, 8)
		net.Send(self)
		if (isDefault) then
			net.Start( "SelectModuleCL" )
			net.WriteUInt( modId, 8 )
			net.Send(self)
		end
	else //execute module normally if no grenade-throw is needed
		if (mod.execute(self, modId, self.modules[modId])) then
			for k, v in pairs (player.GetAll()) do
				net.Start( "UseModuleCL" )
				net.WriteEntity( self )
				net.WriteUInt( modId, 8 )
				net.WriteUInt( self.modules[modId], 8 )
				net.WriteVector( pos )
				net.Send(v)
			end

			self.modulesCd[modId] = mod.cooldown
			self:DrainStamina(mod.drain)
			net.Start( "SetModuleCooldownCL" )
			net.WriteUInt(modId, 8)
			net.Send(self)
			if (isDefault) then
				net.Start( "SelectModuleCL" )
				net.WriteUInt( modId, 8 )
				net.Send(self)
			end
		else
			sound.Play("player/suit_denydevice.wav", pos)
		end
	end
end

function TransformCooldown(cd)
	local integerCd = math.Truncate(cd)
	local decimalCd = math.Truncate((cd - integerCd) * 10)
	local cdText = integerCd .. "." .. decimalCd
	return cdText
end

function meta:UseModuleCL(modId, modLv, modPos)
	local mod = MC.modules[modId]
	if (mod) then
		//print(self:Nick() .. " executing module " .. mod.name .. " on CL")
		mod.execute(self, modId, modLv, modPos)
	end
end


function meta:CreateGrenade(grenade, model, dontRotate)
	local gren = ents.Create(grenade)
	if IsValid(gren) then
		sound.Play("weapons/slam/throw.wav", self:GetPos())
		gren:SetModel(model)//"models/items/grenadeammo.mdl")
		local ang = self:EyeAngles()
		local src = self:GetPos() + (self:Crouching() and self:GetViewOffsetDucked() or self:GetViewOffset()) + (ang:Forward() * 8) + (ang:Right() * 10)
		local target = self:GetEyeTraceNoCursor().HitPos
		local tang = (target-src):Angle() -- A target angle to actually throw the grenade to the crosshair instead of fowards
		-- Makes the grenade go upgwards
		if tang.p < 90 then
			tang.p = -10 + tang.p * ((90 + 10) / 90)
		else
			tang.p = 360 - tang.p
			tang.p = -10 + tang.p * -((90 + 10) / 90)
		end
		tang.p = math.Clamp(tang.p,-90,90) -- Makes the grenade not go backwards :/
		local vel = math.min(800, (90 - tang.p) * 6)
		local thr = tang:Forward() * vel + self:GetVelocity()
		local angimp = Vector(600, math.random(-1200, 1200), 0)
		if (dontRotate) then angimp = Vector(0, 0, 0) end

		gren:SetPos(src)
		gren:SetAngles(ang)

		--   gren:SetVelocity(thr)
		gren:SetOwner(self)
		//gren:SetThrower(self)

		gren:SetGravity(0.4)
		gren:SetFriction(0.2)
		gren:SetElasticity(0.45)

		gren:Spawn()

		gren:PhysWake()

		local phys = gren:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetVelocity(thr)
			phys:AddAngleVelocity(angimp)
		end
	end
	return gren
end

function meta:GetModuleUpgrade(modNum)
	local result = 0
	if (self.modules != nil && self.modules[modNum] != nil) then
		local mod = MC.modules[modNum]
		local modLv = self.modules[modNum]
		if (mod != nil && modLv != nil && modLv >= 1) then
			result = mod.upgrades[modLv]
		end
	end
	return result
end

npcmeta = FindMetaTable( "Entity" )
function npcmeta:HealthFormulaNPC(baseHealth)
	local level = self.level || 1
	local health = baseHealth * (math.pow(1.06, level) + math.log(level, 50))
	return health
end

function npcmeta:DamageFormulaNPC(baseDamage)
	local level = self.level || 1
	local health = baseDamage * (math.pow(1.03, level))
	return health
end

function npcmeta:ProficiencyFormulaNPC(baseProficiency)
	local prof = baseProficiency
	local level = self.level || 1

	if (level < 3) then
		prof = WEAPON_PROFICIENCY_POOR
	elseif (level < 6) then
		prof = WEAPON_PROFICIENCY_AVERAGE
	elseif (level < 9) then
		prof = WEAPON_PROFICIENCY_GOOD
	elseif (level < 14) then
		prof = WEAPON_PROFICIENCY_VERY_GOOD
	else
		prof = WEAPON_PROFICIENCY_PERFECT
	end
	
	return math.max(baseProficiency, prof)
end

function npcmeta:IsEnemy(ply)
	return (self:IsNPC() && !self:IsMinion(ply)) || (self:IsPlayer() && self:Team() != ply:Team()) 
end

function npcmeta:IsEntityStuck()
	local boxMins, boxMaxs = self:GetCollisionBounds()
	//local difference = pos - self:GetPos()
	//local worldBoxMins = self:LocalToWorld(boxMins) - difference
	//local worldBoxMins = self:LocalToWorld(boxMaxs) - difference
	local result = false
	local entsInBox = ents.FindInBox(self:LocalToWorld(boxMins), self:LocalToWorld(boxMaxs))

	for k, v in pairs(entsInBox) do
		if (v:IsNPC() || v:IsPlayer()) && v != self then
			result = true
			print(tostring(self) .. " STUCK! CAUSE: " .. tostring(v))
		end
	end

	return result
end

function npcmeta:IsMinion(ply)
	return self:IsNPC() && self.minion && (IsValid(self.owner) && self.owner:Team() == ply:Team())
end

function npcmeta:GetHealthPercent()
	if (!self.maxHealth) then self.maxHealth = self:GetMaxHealth() end

	if (self.maxHealth < self:Health()) then self.maxHealth = self:Health() end

	return ((self:Health() * 100.1) / (self.maxHealth * 100.1))
end

function npcmeta:ApplyPoison(timerName, timerTick, timerDuration, ply, dmg)
	self.poisoned = true
	local dur = timerDuration * timerTick
	local getPoisonDamage = function()
		if (IsValid(self) && IsValid(ply) && !self.dead && !self:IsMinion(ply)) then
			local dmginfo = DamageInfo()
			dmginfo:SetDamage(dmg)
			dmginfo:SetAttacker(ply)
			dmginfo:SetInflictor(self)
			self:TakeDamageInfo(dmginfo)

			self:ShowEffect(self:LocalToWorld(self:OBBCenter()), Color(180, 180, 50), 3)

			sound.Play("physics/flesh/flesh_squishy_impact_hard" .. math.random(1,4) .. ".wav", self:GetPos())

			for _, enemy in pairs (ents.FindInSphere(self:GetPos(), 150)) do
				if (!enemy.poisoned && enemy:IsEnemy(ply)) then
					enemy:ApplyPoison("InfestedPoison" .. CurTime() .. "," .. enemy:EntIndex(), timerTick, timerDuration, ply, dmg * 0.75)
				end
			end
		end
	end
	getPoisonDamage()
	timer.Create(timerName, timerTick, timerDuration, getPoisonDamage)
    timer.Simple(dur, function()
		if (IsValid(self)) then self.poisoned = false end
	end)
end

function npcmeta:ApplyExplosion(timerName, timerTick, timerDuration, ply, dmg)
	self.exploding = true
	local size = 400
	local ticksCompleted = timerDuration
	local dur = timerDuration * timerTick
	local getPoisonDamage = function()
		ticksCompleted = ticksCompleted - 1
		if (IsValid(self)) then
			sound.Play("HL1/fvox/blip.wav", self:GetPos(), 75, 100 + (1.01 - (ticksCompleted / timerDuration)) * 100)
			self:ShowEffect(self:LocalToWorld(self:OBBCenter()), Color(252, 119, 83), 1)
		end
	end
	timer.Create(timerName, timerTick, timerDuration, getPoisonDamage)
    timer.Simple(dur, function()
		if (IsValid(self)) then self.exploding = false end

		local sounds = {"weapons/mortar/mortar_explode1.wav", "ambient/explosions/explode_5.wav", "ambient/explosions/explode_1.wav"}
		sound.Play(table.Random(sounds), self:GetPos())

		local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetRadius( size )
		effectdata:SetScale( 3 )
		util.Effect( "Explosion", effectdata )

		for _, enemy in pairs (ents.FindInSphere(self:GetPos(), size)) do
			if (enemy:IsEnemy(ply)) then
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(dmg)
				dmginfo:SetAttacker(ply)
				dmginfo:SetInflictor(enemy)
				enemy:TakeDamageInfo(dmginfo)
				enemy:ShowEffect(enemy:LocalToWorld(enemy:OBBCenter()), Color(252, 119, 83), 30)
			end
		end
	end)
end

function npcmeta:ApplyFire(timerName, timerTick, timerDuration, ply, dmg)
	self.burned = true
	local dur = timerDuration * timerTick
	local getBurnDamage = function()
		if (IsValid(self) && IsValid(ply) && !self.dead && !self:IsMinion(ply)) then
			local dmginfo = DamageInfo()
			dmginfo:SetDamage(dmg)
			dmginfo:SetAttacker(ply)
			dmginfo:SetInflictor(self)
			self:TakeDamageInfo(dmginfo)

			self:ShowEffect(self:LocalToWorld(self:OBBCenter()), Color(200, 65, 50), 3, "fx/small-fire.png")

			sound.Play("physics/flesh/flesh_squishy_impact_hard" .. math.random(1,4) .. ".wav", self:GetPos())
		end
	end
	getBurnDamage()
	timer.Create(timerName, timerTick, timerDuration, getBurnDamage)
    timer.Simple(dur, function()
		if (IsValid(self)) then self.burned = false end
	end)
end

function npcmeta:ShowEffect(pos, color, amount, sprite)
	pos = pos || self:LocalToWorld(self:OBBCenter())
	color = color || Color(255, 255, 255, 255)
	amount = amount || 5
	sprite = sprite || "effects/spark"

	net.Start( "SkillHitEffectCL" )
	net.WriteVector(pos)
	net.WriteColor(color)
	net.WriteInt(amount, 16)
	net.WriteString(sprite)
	net.Broadcast()
end

function ShowWorldText(pos, txt, type, ply)
	net.Start( "DrawWorldTextCL" )
	net.WriteVector(pos)
	net.WriteString(txt)
	net.WriteString(type)
	if (ply) then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function ShowScreenText(pos, txt, type, ply)
	net.Start( "DrawScreenTextCL" )
	net.WriteVector(pos)
	net.WriteString(txt)
	net.WriteString(type)
	if (ply) then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

--[[---------------------------------------------------------
   Name: gamemode:KeyPress( )
   Desc: Player pressed a key (see IN enums)
-----------------------------------------------------------]]
function GM:KeyPress( player, key )
end

--[[---------------------------------------------------------
   Name: gamemode:KeyRelease( )
   Desc: Player released a key (see IN enums)
-----------------------------------------------------------]]
function GM:KeyRelease( player, key )
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerConnect( )
   Desc: Player has connects to the server (hasn't spawned)
-----------------------------------------------------------]]
function GM:PlayerConnect( name, address )
end

--[[---------------------------------------------------------
   Name: gamemode:PropBreak( )
   Desc: Prop has been broken
-----------------------------------------------------------]]
function GM:PropBreak( attacker, prop )
end

--[[---------------------------------------------------------
   Name: gamemode:PhysgunPickup( )
   Desc: Return true if player can pickup entity
-----------------------------------------------------------]]
function GM:PhysgunPickup( ply, ent )

	return false
	/*
	-- Don't pick up players
	if ( ent:GetClass() == "player" ) then return false end

	return true
	*/
end

--[[---------------------------------------------------------
   Name: gamemode:PhysgunDrop( )
   Desc: Dropped an entity
-----------------------------------------------------------]]
function GM:PhysgunDrop( ply, ent )
end

--[[---------------------------------------------------------
   Name: gamemode:PlayerShouldTakeDamage
   Return true if this player should take damage from this attacker
-----------------------------------------------------------]]
function GM:PlayerShouldTakeDamage( ply, attacker )
	return true
end

--[[---------------------------------------------------------
   Name: Text to show in the server browser
-----------------------------------------------------------]]
function GM:GetGameDescription()
	return self.Name
end

--[[---------------------------------------------------------
   Name: Saved
-----------------------------------------------------------]]
function GM:Saved()
end

--[[---------------------------------------------------------
   Name: Restored
-----------------------------------------------------------]]
function GM:Restored()
end

--[[---------------------------------------------------------
   Name: EntityRemoved
   Desc: Called right before an entity is removed. Note that this
   isn't going to be totally reliable on the client since the client
   only knows about entities that it has had in its PVS.
-----------------------------------------------------------]]
function GM:EntityRemoved( ent )
end

--[[---------------------------------------------------------
   Name: Tick
   Desc: Like Think except called every tick on both client and server
-----------------------------------------------------------]]
function GM:Tick()
end

--[[---------------------------------------------------------
   Name: OnEntityCreated
   Desc: Called right after the Entity has been made visible to Lua
-----------------------------------------------------------]]
function GM:OnEntityCreated( Ent )
end

--[[---------------------------------------------------------
   Name: gamemode:EntityKeyValue( ent, key, value )
   Desc: Called when an entity has a keyvalue set
		 Returning a string it will override the value
-----------------------------------------------------------]]
function GM:EntityKeyValue( ent, key, value )
end

--[[---------------------------------------------------------
   Name: gamemode:CreateTeams()
   Desc: Note - HAS to be shared.
-----------------------------------------------------------]]
function GM:CreateTeams()

	-- Don't do this if not teambased. But if it is teambased we
	-- create a few teams here as an example. If you're making a teambased
	-- gamemode you should override this function in your gamemode

	if ( !GAMEMODE.TeamBased ) then return end

	TEAM_BLUE = 1
	team.SetUp( TEAM_BLUE, "Blue Team", Color( 0, 0, 255 ) )
	team.SetSpawnPoint( TEAM_BLUE, "info_player_start" ) -- <-- This would be info_terrorist or some entity that is in your map

	TEAM_ORANGE = 2
	team.SetUp( TEAM_ORANGE, "Orange Team", Color( 255, 150, 0 ) )
	team.SetSpawnPoint( TEAM_ORANGE, "info_player_start" ) -- <-- This would be info_terrorist or some entity that is in your map

	TEAM_SEXY = 3
	team.SetUp( TEAM_SEXY, "Sexy Team", Color( 255, 150, 150 ) )
	team.SetSpawnPoint( TEAM_SEXY, "info_player_start" ) -- <-- This would be info_terrorist or some entity that is in your map

	team.SetSpawnPoint( TEAM_SPECTATOR, "worldspawn" )

end

--[[---------------------------------------------------------
   Name: gamemode:ShouldCollide( Ent1, Ent2 )
   Desc: This should always return true unless you have
		  a good reason for it not to.
-----------------------------------------------------------]]
function GM:ShouldCollide( Ent1, Ent2 )

	return true

end

--[[---------------------------------------------------------
   Name: gamemode:Move
   This basically overrides the NOCLIP, PLAYERMOVE movement stuff.
   It's what actually performs the move.
   Return true to not perform any default movement actions. (completely override)
-----------------------------------------------------------]]
function GM:Move( ply, mv )

	if ( drive.Move( ply, mv ) ) then return true end
	if ( player_manager.RunClass( ply, "Move", mv ) ) then return true end

end

--[[---------------------------------------------------------
-- Purpose: This is called pre player movement and copies all the data necessary
--          from the player for movement. Copy from the usercmd to move.
-----------------------------------------------------------]]
function GM:SetupMove( ply, mv, cmd )

	if ( drive.StartMove( ply, mv, cmd ) ) then return true end
	if ( player_manager.RunClass( ply, "StartMove", mv, cmd ) ) then return true end

end

--[[---------------------------------------------------------
   Name: gamemode:FinishMove( player, movedata )
-----------------------------------------------------------]]
function GM:FinishMove( ply, mv )

	if ( drive.FinishMove( ply, mv ) ) then return true end
	if ( player_manager.RunClass( ply, "FinishMove", mv ) ) then return true end

end

--[[---------------------------------------------------------
	Called after the player's think.
-----------------------------------------------------------]]
function GM:PlayerPostThink( ply )

end

--[[---------------------------------------------------------
	A player has started driving an entity
-----------------------------------------------------------]]
function GM:StartEntityDriving( ent, ply )

	drive.Start( ply, ent )

end

--[[---------------------------------------------------------
	A player has stopped driving an entity
-----------------------------------------------------------]]
function GM:EndEntityDriving( ent, ply )

	drive.End( ply, ent )

end

--[[---------------------------------------------------------
	To update the player's animation during a drive
-----------------------------------------------------------]]
function GM:PlayerDriveAnimate( ply )

end

--[[---------------------------------------------------------
	The gamemode has been reloaded
-----------------------------------------------------------]]
function GM:OnReloaded()
end

function GM:PreGamemodeLoaded()
end

function GM:OnGamemodeLoaded()
end

function GM:PostGamemodeLoaded()
end

--
-- Name: GM:OnViewModelChanged
-- Desc: Called when the player changes their weapon to another one - and their viewmodel model changes
-- Arg1: Entity|viewmodel|The viewmodel that is changing
-- Arg2: string|old|The old model
-- Arg3: string|new|The new model
-- Ret1:
--
function GM:OnViewModelChanged( vm, old, new )

	local ply = vm:GetOwner()
	if ( IsValid( ply ) ) then
		player_manager.RunClass( ply, "ViewModelChanged", vm, old, new )
	end

end

--[[---------------------------------------------------------
	Disable properties serverside for all non-sandbox derived gamemodes.
-----------------------------------------------------------]]
function GM:CanProperty( pl, property, ent )
	return false
end
