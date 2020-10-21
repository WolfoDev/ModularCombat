include( "shared.lua" )
include( "modules.lua" )


modulesLevels = {}
modulesCooldowns = {}
quests = {
	{
		title = "Quest #1",
		cur = 0,
		max = 10
	},
	{
		title = "Quest #2",
		cur = 2,
		max = 5
	}
}
local exp = 0;
local stamina = 100;
local points = 0;
local kickCooldown = 0;

local weakened = false
local poisoned = false
local vulnerable = false
local burned = false

local scoreboard
local scoreboardRefresh = true

local modulesMenu
local modulesChoice
local modulesRefresh = true
local selectedModule = 0

local profileLevels = {}
local selectedProfile = 1

local vignette = Material( "materials/ui/vignette_white.png" )
local sprintAlpha = 0
local hudBoxAlpha = 200;
local npcBoxMaxAlpha = 150;
local hudBoxHeight = 392
local crosshairSpace = 20
local expWidth = 0
local staminaWidth = 0
local dmgTexts = {}
local dmgTexts2d = {}
local drawnModules = {}
local moduleChoiceDelay = 0

local healEffect = 0
local vignetteColor = Color(10, 10, 10, 255)
local originalVignetteColor = Color(10, 10, 10, 255)
local healingVignetteColor = Color(175, 220, 230, 255)
local weakenVignetteColor = Color(60, 170, 140, 255)
local burnVignetteColor = Color(255, 60, 0, 255)
local poisonVignetteColor = Color(180, 180, 50, 255)

local experienceColor = Color(225, 85, 255)

local lastPlayersCount = 0
local pvpVotes = 0
local mapVotes = 0
local mouseWheel = 0
local moduleKeys = {}
local keypressDelay = 0



local function ValueToScreenRect( x, y, w, h )
	
	local base_w, screen_w = 640, ScrW( );
	local base_h, screen_h = 480, ScrH( );
	
	screen_w = screen_h * ( base_w / base_h );
	
	local screen_scale_w = screen_w / base_w;
	local screen_scale_h = screen_h / base_h;
	
	x = screen_scale_w * x;
	y = screen_scale_h * y;
	w = screen_scale_w * w;
	h = screen_scale_h * h;
	
	return x, y, w, h;
	
end

net.Receive("SyncLevel", function()
	local ply = net.ReadEntity()
	ply.level = net.ReadUInt(8)
end)

net.Receive("SyncExperience", function()
	exp = net.ReadUInt(16)
end)

net.Receive("SyncProfile", function()
	local index = net.ReadUInt(16)
	local profileLevel = net.ReadUInt(16)
	profileLevels[index] = profileLevel
end)

net.Receive("SyncSelectedProfile", function()
	selectedProfile = net.ReadUInt(16)
end)

net.Receive("SyncStamina", function()
	stamina = net.ReadUInt(10)
end)

net.Receive("SyncModules", function()
	modulesLevels = net.ReadTable()
	//PrintTable(modulesLevels)
end)

net.Receive("SyncModulesCd", function()
	local index = net.ReadUInt(8)
	modulesCooldowns[index] = 0
	//PrintTable(modulesLevels)
end)

net.Receive("SyncPoints", function()
	local ply = net.ReadEntity()
	ply.points = net.ReadUInt(10)
end)

net.Receive("SyncShop", function()
	modulesLevels = net.ReadTable()
	modulesRefresh = true
end)

net.Receive("SyncStatus", function()
	vulnerable = net.ReadBool()
	weakened = net.ReadBool()
	burned = net.ReadBool()
	poisoned = net.ReadBool()
end)

net.Receive("SyncNpcDeath", function(len, ply)
	local ent = net.ReadEntity()
	ent.isDead = true
end)

net.Receive("SyncNpcStats", function(len, ply)
	local ent = net.ReadEntity()
	local lv = net.ReadUInt(8)
	local hp = net.ReadFloat()
	local maxhp = net.ReadFloat()
	local boss = net.ReadBool()
	local name = net.ReadString()
	local _friendly = net.ReadBool()
	local owner = net.ReadEntity()

	if (IsValid(ent)) then
		ent.level = lv
		ent.name = name
		ent:SetHealth(hp)
		ent.maxHealth = maxhp
		ent.boss = boss
		ent.minion = _friendly
		ent.owner = owner
	end
end)

net.Receive("SyncVotes", function()
	pvpVotes = net.ReadInt(16)
	mapVotes = net.ReadInt(16)
end)

net.Receive("UseModuleCL", function(len, ply)
	local ply = net.ReadEntity()
	local modId = net.ReadUInt(8)
	local moduleLv = net.ReadUInt(8)
	local modulePos = net.ReadVector()
	ply:UseModuleCL(modId, moduleLv, modulePos)
end)

net.Receive("SetModuleCooldownCL", function(len, ply)
	local moduleNum = net.ReadUInt(8)
	local mod = MC.modules[moduleNum]
	modulesCooldowns[moduleNum] = mod.cooldown
end)

net.Receive("SelectModuleCL", function(len, ply)
	local moduleNum = net.ReadInt(8)
	LocalPlayer().useModule = moduleNum
end)

net.Receive("HealEffectCL", function(len, ply)
	healEffect = net.ReadFloat()
end)


local musicTable = {"music/HL2_song26_trainstation1.mp3"}
local function LoopMusicRandom()
	local length = 1
	if (table.Count(musicTable) > 1) then
		local music = table.Random(musicTable)
		//local musicSource = CreateSound( LocalPlayer(), music )
		//musicSource:Play()
		//musicSource:ChangeVolume(0.5, 0)
		surface.PlaySound( music )
		length = SoundDuration(music)
	end
	timer.Simple(length, LoopMusicRandom)
end

net.Receive("PlayMusicCL", function(len, ply)
	musicTable = net.ReadTable()
	LoopMusicRandom()
	//game.AddParticles("particles/effects/spark.pcf")
end)

net.Receive("CriticalEffectCL", function(len, ply)
	local pos = net.ReadVector()
	local emitter = ParticleEmitter( pos )
	for i = 0, 20 do
		local part = emitter:Add( "effects/spark", pos )
		local color = Color(220, 25, 25)
		if ( part ) then
			part:SetDieTime( 2.2 )
			part:SetPos( pos )
			part:SetColor(color.r, color.g, color.b)

			part:SetStartAlpha( 255 )
			part:SetEndAlpha( 0 )

			part:SetStartSize( 10 )
			part:SetEndSize( 0 )

			part:SetGravity( Vector( 0, 0, -400 ) )
			local vel = VectorRand() * 70
			part:SetVelocity( vel + Vector(0, 0, 120) )
		end
	end
	emitter:Finish()
end)

net.Receive("SkillHitEffectCL", function(len, ply)
	local pos = net.ReadVector()
	local color = net.ReadColor()
	local amount = net.ReadInt(16)
	local sprite = net.ReadString()
	local emitter = ParticleEmitter( pos )
	for i = 0, amount do
		local part = emitter:Add( Material(sprite), pos )
		if ( part ) then
			part:SetDieTime( 2.2 )
			part:SetPos( pos )
			part:SetColor(color.r, color.g, color.b)

			part:SetStartAlpha( 255 )
			part:SetEndAlpha( 0 )

			part:SetStartSize( 10 )
			part:SetEndSize( 0 )

			part:SetGravity( Vector( 0, 0, -400 ) )
			local vel = VectorRand() * 70
			part:SetVelocity( vel + Vector(0, 0, 120) )
		end
	end
	emitter:Finish()
end)

net.Receive("SyncDamageAmount", function()
	local dmgText = {pos = net.ReadVector(), dmg = net.ReadInt(16), type = net.ReadString(), alpha = 200, height = 0}
	dmgText.pos = dmgText.pos + LocalPlayer():GetRight() * math.random(-10, 10)
	dmgText.pos = dmgText.pos + LocalPlayer():GetForward() * math.random(-10, 10)
	local added = false
	if (dmgText.dmg < 1) then
		if (dmgText.dmg <= 0) then
			return
		else
			dmgText.dmg = "<1"
			added = true
		end
	end

	for k, v in pairs (dmgTexts) do
		if (v.pos:Distance(dmgText.pos) <= 50 && v.alpha >= 110 && dmgText.type == v.type && !added) then
			dmgTexts[k].dmg = dmgTexts[k].dmg + dmgText.dmg
			added = true
			break
		end
	end
	if (!added) then
		local pos = table.insert(dmgTexts, dmgText)
	end
end)

net.Receive("DrawWorldTextCL", function()
	local dmgText = {pos = net.ReadVector(), dmg = net.ReadString(), type = net.ReadString(), alpha = 200, height = 0}
	dmgText.pos = dmgText.pos + LocalPlayer():GetRight() * math.random(-10, 10)
	dmgText.pos = dmgText.pos + LocalPlayer():GetForward() * math.random(-10, 10)
	
	local pos = table.insert(dmgTexts, dmgText)
end)

net.Receive("DrawScreenTextCL", function()
	local dmgText2d = {pos = (net.ReadVector()):ToScreen(), dmg = net.ReadString(), type = net.ReadString(), alpha = 200, height = 0}
	
	local pos = table.insert(dmgTexts2d, dmgText2d)
end)

function DamageTextCheck()
	for k, dmgText in pairs (dmgTexts) do
		if (dmgText != nil) then
			local decreaseAlpha = 4
			if (dmgText.type == "exp") then
				decreaseAlpha = 1
			end
			dmgText.alpha = dmgText.alpha - decreaseAlpha
			dmgText.height = dmgText.height + decreaseAlpha / 16
			if (dmgText.alpha <= 0) then
				table.remove(dmgTexts, k)
			end
		end
	end
	for k, dmgText in pairs (dmgTexts2d) do
		if (dmgText != nil) then
			local decreaseAlpha = 4
			if (dmgText.type == "exp") then
				decreaseAlpha = 1
			end
			dmgText.alpha = dmgText.alpha - decreaseAlpha
			dmgText.height = dmgText.height + decreaseAlpha / 16
			if (dmgText.alpha <= 0) then
				table.remove(dmgTexts2d, k)
			end
		end
	end
end
timer.Create("DamageTextCheck", 0.025, 0, DamageTextCheck)

function ModuleCooldownCheck()
	for k, v in pairs (modulesCooldowns) do
		if (modulesCooldowns[k] > 0.1) then
			modulesCooldowns[k] = modulesCooldowns[k] - 0.1
		end
	end
	if (healEffect > 0) then healEffect = healEffect - 0.1 end
	if (healEffect < 0) then healEffect = 0 end
end
timer.Create("ModuleCooldownCheck", 0.1, 0, ModuleCooldownCheck)

hook.Add("Think", "UpdateCL", function()	
	local ply = LocalPlayer()
	local trace = { start = ply:GetShootPos(), endpos = ply:GetShootPos() + ply:GetForward() * 3000, filter = player.GetAll() }

	local tr = util.TraceLine( trace )
		if (ply:IsRunning()) then
			crosshairSpace = Lerp(0.125, crosshairSpace, 50)
		elseif ( tr.Hit && IsValid(tr.Entity) && tr.Entity:IsNPC() ) then
			crosshairSpace = Lerp(0.125, crosshairSpace, 25)
		else
			crosshairSpace = Lerp(0.125, crosshairSpace, 35)
		end

	expWidth = Lerp(0.05, expWidth, math.Clamp(exp / ply:NextExpFormula(), 0, 1))
	staminaWidth = Lerp(0.035, staminaWidth, math.Clamp(stamina / ply:StaminaFormula(), 0, 1))
end)

local function LoadModuleKeys()
	local data = file.Read( "modulekeys.txt", "DATA" )//GetPData("modulekeys", "")
	if !data then return end
	
	local serializedKeys = string.Explode("\n", data)
	for k, v in pairs (serializedKeys) do
		local _keys = string.Explode(";", v)
		local module = tonumber(_keys[1])
		local key = tonumber(_keys[2])
		if (isnumber(module) && isnumber(key)) then
			moduleKeys[module] = key
		end
	end
end
hook.Add( "Initialize", "LoadModuleKeys", LoadModuleKeys)

local function SaveModuleKeys()
	local count = 0
	local serializedString = ""
	for module, key in pairs (moduleKeys) do
		count = count + 1
		
		serializedString = serializedString .. module .. ";" .. key

		if (count < table.Count(moduleKeys)) then
			serializedString = serializedString .. "\n"
		end
	end
	file.Write("modulekeys.txt", serializedString)
	//LocalPlayer():SetPData("modulekeys", serializedString)
end

local function loadFonts()
	surface.CreateFont( "HL2Num", {
		font = "HudNumbers",
		extended = false,
		size = 40,
		weight = 200,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
	surface.CreateFont( "HL2NumBig", {
		font = "HudNumbers",
		extended = false,
		size = 60,
		weight = 200,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = true,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
	surface.CreateFont( "HL2NumExp", {
		font = "HudNumbers",
		extended = false,
		size = 50,
		weight = 200,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = true,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
	surface.CreateFont( "Objects", {
		font = "BudgetLabel",
		extended = false,
		size = 60,
		weight = 200,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
	
	surface.CreateFont( "ExpFont", {
		font = "Default",
		extended = false,
		size = 18,
		weight = 200,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = t,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = t,
	} )
	
	surface.CreateFont( "StandardText", {
		font = "Trebuchet24",
		extended = false,
		size = 24,
		weight = 200,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = t,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
	
	surface.CreateFont( "StandardTextSmall", {
		font = "Trebuchet24",
		extended = false,
		size = 20,
		weight = 200,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = t,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
	
	surface.CreateFont("HL2Text", {
		size = 22,
		weight = 500,
		antialias = true,
		shadow = false,
		font = "HudSelectionText"
	})
end
loadFonts()
hook.Add("InitPostEntity", "LoadFonts_Fix", loadFonts)


hook.Add( "HUDPaint", "DrawDamageText", function()
	local ply = LocalPlayer();

	for k, v in pairs (dmgTexts) do
		if (ply:GetPos():Distance(v.pos) <= 1500) then
			local color = {r = 255, g = 236, b = 200}
			local pos = v.pos;
			local height = v.height;
			local alpha = v.alpha;
			local screenPos = (pos + ply:GetUp() * height):ToScreen()
			local font = "HL2Num"
			if (v.type == "critical") then
				color.r = 200
				font = "HL2NumBig"
			end
			if (v.type == "skill") then
				color.b = 100
				color.g = 100
				font = "HL2NumBig"
			end
			if (v.type == "exp") then
				color = experienceColor
				font = "HL2NumExp"
			end
			if (v.type == "heal") then
				color = healingVignetteColor
				font = "HL2NumExp"
			end
			draw.DrawText( v.dmg, font, screenPos.x, screenPos.y, Color( color.r, color.g, color.b, alpha ), TEXT_ALIGN_CENTER )
		end
	end

	for k, v in pairs (dmgTexts2d) do
		local color = {r = 255, g = 236, b = 200}
		local pos = v.pos;
		local height = v.height;
		local alpha = v.alpha;
		local font = "HL2Num"
		if (v.type == "critical") then
			color.r = 200
			font = "HL2NumBig"
		end
		if (v.type == "skill") then
			color.b = 100
			color.g = 100
			font = "HL2NumBig"
		end
		if (v.type == "cd") then
			color.b = 100
			color.g = 100
			font = "StandardTextSmall"
		end
		if (v.type == "exp") then
			color = experienceColor
			font = "HL2NumExp"
		end
		if (v.type == "heal") then
			color = healingVignetteColor
			font = "HL2NumExp"
		end
		draw.DrawText( v.dmg, font, pos.x, pos.y - height * 3, Color( color.r, color.g, color.b, alpha ), TEXT_ALIGN_CENTER )
	end
end)


hook.Add( "HUDPaint", "DrawNPCStats", function()
	local ply = LocalPlayer();
	local maxRange = 600
	local w = 80
	local h = 10
	local spacing = 0.5
	for k, ent in pairs (ents.GetAll()) do
		local w = 80
		local h = 10
		local entToPlyDir = (ply:GetPos() - ent:GetPos())
		entToPlyDir:Normalize()
		local height = math.Clamp(ply:GetPos():Distance(ent:GetPos()) * 0.05 - 5, -5, 30);
		local width = math.Clamp(ply:GetPos():Distance(ent:GetPos()) * 0.05, 10, 500);
		//local head = ent:OBBCenter()
		//head.z = ent:OBBMaxs().z + height
		local head = (ent:LocalToWorld(ent:OBBCenter()))
		head.z = head.z + (ent:LocalToWorld(ent:OBBMaxs()):Distance(ent:LocalToWorld(ent:OBBMins())) * 0.25) + height
		head = head - entToPlyDir:Cross(Vector(0, 0, 1)) * width

		local screenPos = head:ToScreen()
		local distX = (math.abs(math.Clamp(screenPos.x - ScrW() / 2, -ScrW() / 2, ScrW() / 2)) / (ScrW() / 2))
		local distY = (math.abs(math.Clamp(screenPos.y - ScrH() / 2, -ScrH() / 2, ScrH() / 2)) / (ScrH() / 2))
		if (distX <= 1 && distY <= 1 && (ent:IsNPC() || (ent:IsPlayer() && ent != ply)) && (ent:IsLineOfSightClear( ply ) || ent.boss)) then
			local color = {r = 255, g = 236, b = 200}
			local alpha = (1 - math.max(distX , distY)) * 200
			local font = "Default"
			local health = ent:GetHealthPercent();
			if (ent.isDead) then health = 0 end
			if (ent:IsPlayer() && !ent:Alive()) then health = 0 end

			local hpColor = Color( 150, 50, 50, alpha )
			local nick = ent.name || "ENEMY"
			local lvText = string.upper(nick) .. " - Lv "
			if (ent.boss) then
				lvText = "BOSS - Lv "
				hpColor = Color( 125, 45, 90, alpha )
				w = 120
			elseif (ent:IsPlayer() && ent:Team() == ply:Team()) then
				lvText = string.upper(ent:Nick()) .. " - Lv "
				hpColor = Color( 0, 160, 255, alpha )
				w = 120
			elseif (ent:IsPlayer()) then
				lvText = "ENEMY - Lv "
				hpColor = Color( 150, 50, 50, alpha )
				w = 120
			elseif (ent.minion && ent:IsMinion(LocalPlayer())) then
				lvText = "MINION - Lv "
				hpColor = Color( 0, 160, 255, alpha )
				w = 100
			elseif (ent.minion) then
				lvText = "MINION - Lv "
				hpColor = Color( 150, 50, 50, alpha )
				w = 100
			end

			draw.RoundedBox( 4, screenPos.x - w/2, screenPos.y + h / 2, w, h, Color( 50, 50, 50, alpha ) )
			draw.RoundedBox( 4, screenPos.x - w/2, screenPos.y + h / 2, health * w, h, hpColor )

			surface.SetFont(font)
			local textw, texth = surface.GetTextSize(lvText .. (ent.level || 1))
			
			draw.RoundedBox( 4, screenPos.x - w/2, screenPos.y - texth / 2, textw, texth, Color( 50, 50, 50, alpha ) )
			draw.DrawText( lvText .. (ent.level || 1), font, screenPos.x - w/2, screenPos.y - texth / 2, Color( color.r, color.g, color.b, alpha ), TEXT_ALIGN_LEFT )
		end
	end
end)

--[[
	local x, y, w, h = ValueToScreenRect(42, hudBoxHeight - 20, 42, 32);
	draw.DrawText( #ents.FindByClass("npc_*"), "HL2Num", x, y, Color( 0, 0, 125, hudBoxAlpha ), TEXT_ALIGN_LEFT )
	
	for k, v in ipairs( ents.FindByClass( "npc_*" ) ) do
		local screenPos = (v:GetPos() + ply:GetUp() * 50):ToScreen()
		local w = 32
		local h = 32
		local alpha = npcBoxMaxAlpha / math.max(math.Distance(ScrW() / 2, ScrH() / 2, screenPos.x, screenPos.y), 1)
		alpha = 200
		draw.RoundedBox( 32, screenPos.x, screenPos.y, w, h, Color( 255, 0, 0, alpha ) )
	end
--]]


hook.Add( "HUDPaint", "DrawModuleBox", function()
	local ply = LocalPlayer();
	local mod = MC.modules[ply.useModule]
	local cd = modulesCooldowns[ply.useModule]
	if (mod != nil && mod.execute != nil && modulesLevels[ply.useModule] != nil) then
		local x, y, w, h = ValueToScreenRect(16, 400, 50, 50);
		x = ScrW() / 2

		draw.RoundedBox( 8, x, y, w, h, Color( 0, 0, 0, 80 ) )
		
		surface.SetDrawColor( hex(mod.color) )
		surface.SetMaterial( Material("ui/icons/" .. mod.icon .. ".png") )
		surface.DrawTexturedRect( x, y, w, h )

		if (cd != nil && cd >= 0.1) then
			local cdText = TransformCooldown(cd)
			draw.RoundedBox( 8, x, y, w, h, Color( 255, 255, 255, 80 ) )
			draw.DrawText( cdText .. "s", "HL2Num", x + w / 2, y + h * 0.25, Color( 50, 50, 50, 150 ), TEXT_ALIGN_CENTER )
		end
	end
end)

hook.Add( "HUDPaint", "HUDExtras", function()
	local stamy = hudBoxHeight + 36
	local ply = LocalPlayer();
	local barHeight = 0.75
	local barPadding = 0.12

	if (ply:Alive()) then
		hudBoxAlpha = 200
	else
		hudBoxAlpha = 0
	end
	
	local limit = 1
	local levelText = ply.level || 1
	if (levelText >= MAX_LEVEL) then
		levelText = "MAX"
		limit = 0
	end
	local x, y, w, h = ValueToScreenRect(16, hudBoxHeight, 42, 32);
	draw.RoundedBox( 8, x, y, w, h, Color( 0, 0, 0, hudBoxAlpha / 2.5 ) )
	local x, y, w, h = ValueToScreenRect(24, hudBoxHeight + 14, 42, 32)
	draw.DrawText( "LV", "HL2Text", x, y, Color( 255, 236, 12, hudBoxAlpha ), TEXT_ALIGN_LEFT )
	local x, y, w, h = ValueToScreenRect(42, hudBoxHeight + 8, 42, 32)
	draw.DrawText( levelText, "HL2Num", x, y, Color( 255, 255, 125, hudBoxAlpha ), TEXT_ALIGN_LEFT )

	
	if (ply.points == nil) then ply.points = 0 end
	local x, y, w, h = ValueToScreenRect(16, hudBoxHeight - 42, 48, 32);
	draw.RoundedBox( 8, x, y, w, h, Color( 0, 0, 0, hudBoxAlpha / 2.5 ) )
	local x, y, w, h = ValueToScreenRect(24, hudBoxHeight + 14 - 42, 48, 32)
	draw.DrawText( "PTs", "HL2Text", x, y, Color( 255, 236, 12, hudBoxAlpha ), TEXT_ALIGN_LEFT )
	local x, y, w, h = ValueToScreenRect(48, hudBoxHeight + 8 - 42, 48, 32)
	draw.DrawText( ply.points, "HL2Num", x, y, Color( 255, 255, 125, hudBoxAlpha ), TEXT_ALIGN_LEFT )


	draw.DrawText( "(", "Objects", ScrW() / 2 - crosshairSpace, ScrH() / 2 - 35, Color( 255, 236, 12, hudBoxAlpha * 0.25 ), TEXT_ALIGN_CENTER )
	draw.DrawText( ")", "Objects", ScrW() / 2 + crosshairSpace, ScrH() / 2 - 35, Color( 255, 236, 12, hudBoxAlpha * 0.25 ), TEXT_ALIGN_CENTER )
	
	local x, y, w, h = ValueToScreenRect(42 + 16, hudBoxHeight + 16, 64 + 22, 16);
	draw.RoundedBox( 8, x, y, w, h, Color( 0, 0, 0, hudBoxAlpha / 2.5 ) )
	draw.RoundedBox( 8, x, y + h * barPadding, w * expWidth * limit, h * barHeight, Color( experienceColor.r, experienceColor.g, experienceColor.b, hudBoxAlpha / 2.5 ) )
	
	if (stamina < math.Round(ply:StaminaFormula())) then
		sprintAlpha = Lerp(0.12, sprintAlpha, hudBoxAlpha)
		hudBoxHeight = Lerp(0.125, hudBoxHeight, 376)
	else
		sprintAlpha = Lerp(0.12, sprintAlpha, 0)
		hudBoxHeight = Lerp(0.125, hudBoxHeight, 392)
	end
	
	local x, y, w, h = ValueToScreenRect(16, stamy, 128, 16);
	draw.RoundedBox( 8, x, y, w, h, Color( 0, 0, 0, sprintAlpha / 2.5 ) )
	local color = Color( 255, 255, 125, sprintAlpha )
	if (stamina < ply:StaminaFormula() * 0.2) then
		color = Color( 255, 85, 0, sprintAlpha )
	end
	draw.RoundedBox( 8, x, y + h * barPadding, w * staminaWidth, h * barHeight, color )
	
	if (healEffect > 0) then
		vignetteColor = Color(
			Lerp(0.05, vignetteColor.r, healingVignetteColor.r),
			Lerp(0.05, vignetteColor.g, healingVignetteColor.g),
			Lerp(0.05, vignetteColor.b, healingVignetteColor.b),
			Lerp(0.05, vignetteColor.a, healingVignetteColor.a)
		)
	elseif (vulnerable) then
		vignetteColor = Color(
			Lerp(0.05, vignetteColor.r, 255),
			Lerp(0.05, vignetteColor.g, 50),
			Lerp(0.05, vignetteColor.b, 50),
			Lerp(0.05, vignetteColor.a, 200)
		)
	elseif (weakened) then
		vignetteColor = Color(
			Lerp(0.05, vignetteColor.r, weakenVignetteColor.r),
			Lerp(0.05, vignetteColor.g, weakenVignetteColor.g),
			Lerp(0.05, vignetteColor.b, weakenVignetteColor.b),
			Lerp(0.05, vignetteColor.a, weakenVignetteColor.a)
		)
	elseif (burned) then
		vignetteColor = Color(
			Lerp(0.05, vignetteColor.r, burnVignetteColor.r),
			Lerp(0.05, vignetteColor.g, burnVignetteColor.g),
			Lerp(0.05, vignetteColor.b, burnVignetteColor.b),
			Lerp(0.05, vignetteColor.a, burnVignetteColor.a)
		)
	elseif (poisoned) then
		vignetteColor = Color(
			Lerp(0.05, vignetteColor.r, poisonVignetteColor.r),
			Lerp(0.05, vignetteColor.g, poisonVignetteColor.g),
			Lerp(0.05, vignetteColor.b, poisonVignetteColor.b),
			Lerp(0.05, vignetteColor.a, poisonVignetteColor.a)
		)
	else
		vignetteColor = Color(
			Lerp(0.05, vignetteColor.r, originalVignetteColor.r),
			Lerp(0.05, vignetteColor.g, originalVignetteColor.g),
			Lerp(0.05, vignetteColor.b, originalVignetteColor.b),
			Lerp(0.05, vignetteColor.a, originalVignetteColor.a)
		)
	end
	surface.SetDrawColor( vignetteColor )
	surface.SetMaterial( vignette )
	surface.DrawTexturedRect( 0, 0, ScrW(), ScrH() )
end )

local function OpenModulesMenu( )
	return false
end
hook.Add( "SpawnMenuOpen", "OpenModulesMenu", OpenModulesMenu)

local function SelectUsedModule(moduleNum)
	local ply = LocalPlayer()
	ply.useModule = moduleNum
	net.Start( "SelectModuleSV" )
	net.WriteUInt(moduleNum, 8)
	net.SendToServer()
end

local function BuyModule(moduleNum)
	net.Start( "BuyModuleSV" )
	net.WriteUInt(moduleNum, 8)
	net.SendToServer()
	surface.PlaySound("buttons/button9.wav")
end

local function BuildModuleInfo(infoText, descText, infoIcon, infoTab, infoButton, bindButton, resetBindButton)
	local ply = LocalPlayer()
	if (selectedModule >= 0 && selectedModule <= table.Count(MC.modules) && MC.modules[selectedModule]) then
		local modLv = modulesLevels[selectedModule] || 0
		infoText:SetText("")

		local mod = MC.modules[selectedModule]
		local color = hex(mod.color)
		infoText:AppendText(" ")

		infoText:InsertColorChange( 200, 200, 200, 255 )
		infoText:AppendText("Name: ")
		infoText:InsertColorChange( 255, 255, 255, 255 )
		infoText:AppendText(mod.name)

		infoText:AppendText("\n")
		infoText:AppendText(" ")

		infoText:InsertColorChange( 200, 200, 200, 255 )
		infoText:AppendText("Type: ")
		infoText:InsertColorChange( 255, 255, 255, 255 )
		infoText:AppendText(mod.type)

		infoText:AppendText("\n")
		infoText:AppendText(" ")

		if (modLv > 0) then
			infoText:InsertColorChange( 200, 200, 200, 255 )
			infoText:AppendText("Level: ")
			infoText:InsertColorChange( 150, 200, 255, 255 )
			infoText:AppendText(modLv .. " / 10")
		else
			infoText:InsertColorChange( 200, 200, 200, 255 )
			infoText:AppendText("Not yet acquired")
		end

		infoText:AppendText("\n\n")
		infoText:AppendText(" ")

		infoText:InsertColorChange( 200, 200, 200, 255 )
		infoText:AppendText("Drains: ")
		infoText:InsertColorChange( 150, 200, 255, 255 )
		infoText:AppendText(mod.drain .. " AUX")

		infoText:AppendText("\n")
		infoText:AppendText(" ")

		infoText:InsertColorChange( 200, 200, 200, 255 )
		infoText:AppendText("Cooldown: ")
		infoText:InsertColorChange( 150, 200, 255, 255 )
		infoText:AppendText(mod.cooldown .. "s")

		infoText:AppendText("\n")
		infoText:AppendText(" ")

		infoText:InsertColorChange( 200, 200, 200, 255 )
		infoText:AppendText("Cast time: ")
		infoText:InsertColorChange( 150, 200, 255, 255 )
		infoText:AppendText(mod.casttime .. "s")

		
		descText:InsertColorChange( 220, 220, 220, 255 )
		descText:SetText("")
		local inBold = false
		local inItalic = false
		local words = string.Explode(" ", mod.description)
		for k, v in pairs (words) do
			local word = v
			if (string.find(word, "<b>")) then
				word = string.gsub(word, "<b>", "")
				inBold = true
			end
			if (string.find(word, "<i>")) then
				word = string.gsub(word, "<i>", "")
				inItalic = true
			end

			if (inBold) then
				descText:InsertColorChange( 255, 230, 220, 255 ) //color.r, color.g, color.b, 255 )
			elseif (inItalic) then
				descText:InsertColorChange( 255, 255, 255, 255 )
			else
				descText:InsertColorChange( 220, 220, 220, 255 )
			end

			if (string.find(word, "</b>")) then
				word = string.gsub(word, "</b>", "")
				inBold = false
			end

			if (string.find(word, "</i>")) then
				word = string.gsub(word, "</i>", "")
				inItalic = false
			end

			descText:AppendText(word)
			descText:AppendText(" ")
		end
		//descText:SetText(mod.description)

		infoIcon:SetImage( "ui/icons/" .. mod.icon .. ".png" )
		infoIcon:SetImageColor( color )
		
		function infoTab:Paint(w, h)
			local amount = 11
			local pos = {x = 0, y = 0}
			local size = {x = 0, y = 0}
			local extra = w / amount
			size.x = w / amount
			size.y = h / 2
			for i = 0,amount do
				pos.y = (h / 2)

				local color = Color( 255, 255, 255, 150 )
				if (i == modLv) then
					color = Color(100, 100, 200, 150)
				end

				local text = mod.upgrade
				size.x = w / amount + extra
				pos.x = 0
				if (i >= 1 && mod.upgrades[i] != nil) then
					text = mod.parseUpgrade(mod.upgrades[i])
					size.x = w / amount - extra / (amount - 1)
					pos.x = size.x * (i - 1) + w / amount + extra
				end
				surface.SetFont("StandardText")
				local height = select(2, surface.GetTextSize(text))

				draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, color )
				draw.DrawText(text, "StandardText", pos.x + size.x / 2, pos.y + size.y / 2 - height / 2, Color(50, 50, 50, 255), TEXT_ALIGN_CENTER)

				pos.x = w / amount * i
				pos.y = 0

				local text2 = "Level"
				size.x = w / amount + extra
				pos.x = 0
				if (i >= 1) then
					text2 = tostring(i)
					size.x = w / amount - extra / (amount - 1)
					pos.x = size.x * (i - 1) + w / amount + extra
				end
				surface.SetFont("StandardText")
				local height = select(2, surface.GetTextSize(text2))

				draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, color )
				draw.DrawText(text2, "StandardText", pos.x + size.x / 2, pos.y + size.y / 2 - height / 2, Color(50, 50, 50, 255), TEXT_ALIGN_CENTER)
			end
		end


		function infoButton:DoClick()
			local cost = mod.cost || 99
			if (modLv >= 1) then cost = 1 end
			if (ply.points < cost || modLv >= 10) then
				surface.PlaySound("common/wpn_denyselect.wav")
			else
				BuyModule(selectedModule)
			end
		end

		function infoButton:Paint(w, h)
			local alpha = 200
			local color = Color(50, 200, 50, 255)
			local cost = mod.cost
			if (modLv >= 1) then cost = 1 end

			if (ply.points < cost) then
				alpha = 50
				color = Color( 200, 50, 50, 255 )
			end
			draw.RoundedBox( 8, 0, 0, w, h, Color( 255, 255, 255, 200 ) )

			local currency = "point"
			if (cost > 1) then currency = currency .. "s" end
			
			local text = "BUY\n" .. cost .. " " .. currency
			if (modLv >= 1 && modLv < 10) then
				text = "UPGRADE\n" .. cost .. " " .. currency
			elseif (modLv >= 10) then
				text = "MAXED\nOUT"
				alpha = 50
				color = Color( 50, 50, 50, 255 )
			end
			surface.SetFont("StandardText")
			local height = select(2, surface.GetTextSize(text))
			draw.DrawText(text, "StandardText", w/2, h/2 - height / 2, color, TEXT_ALIGN_CENTER)
			//draw.SimpleTextOutlined(text, "Trebuchet24", w/2, h/2 - height / 2, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(50, 50, 50, 200))
		end

		function infoButton:Think()
			local ex = mod.execute || nil
			if (!mod.execute || modLv <= 0) then
				bindButton:SetVisible(false)
				resetBindButton:SetVisible(false)
				return
			end

			//bindButton:SetValue()
			bindButton:SetVisible(true)
			resetBindButton:SetVisible(true)
			local posX, posY = self:GetPos()
			local panelWidth = 200
			local buttonSize = 105
			local bindSize = 40
			local resetSize = 20
			self:SetSize(panelWidth, buttonSize)
			bindButton:SetPos(posX, buttonSize)
			bindButton:SetSize(panelWidth, bindSize)
			resetBindButton:SetPos(posX, buttonSize + bindSize)
			resetBindButton:SetSize(panelWidth, resetSize)
		end

		function resetBindButton:DoClick()
			bindButton:SetValue(KEY_NONE)
		end

		function bindButton:OnChange(num)
			moduleKeys[selectedModule] = num
			SaveModuleKeys()
		end

		local keyBind = moduleKeys[selectedModule]
		if (keyBind) then
			bindButton:SetValue(keyBind)
		else
			bindButton:SetValue(KEY_NONE)
		end
	end
end


function PointOnCircle( ang, radius, offX, offY )
	ang =  math.rad( ang )
	local x = math.cos( ang ) * radius + offX
	local y = math.sin( ang ) * radius + offY
	return x, y
end

local function CreateModulesChoice()
	local size = math.min(ScrW(), ScrH())
	local pos = {x = ScrW() / 2 - size / 2, y = ScrH() / 2 - size / 2}
	local iconSize = 75
	modulesChoice = vgui.Create( "DFrame" )
	modulesChoice:SetPos( pos.x, pos.y )
	modulesChoice:SetSize( size, size)
	modulesChoice:SetTitle( "" )
	modulesChoice:SetVisible( false )
	modulesChoice:SetDraggable( false )
	modulesChoice:ShowCloseButton( false )
	modulesChoice:MakePopup()
	function modulesChoice:OnMouseWheeled(scroll)
		if (scroll >= 0.5 ) then
			mouseWheel = 1
		elseif (scroll <= -0.5 ) then
			mouseWheel = -1
		end
	end
	function modulesChoice:Paint(w, h)
		local ply = LocalPlayer()
		if (modulesRefresh) then
			modulesRefresh = false
			drawnModules = {}
			for k, mod in ipairs (MC.modules) do
				if (mod.execute != nil && modulesLevels[k] != nil && modulesLevels[k] >= 1) then
					local i = table.insert(drawnModules, mod)
					drawnModules[i].index = k
				end
			end
		end

		local numSquares = table.Count(drawnModules)
		local interval = 360 / numSquares
		local radius = h * 0.25
		local centerX, centerY = w / 2, h / 2
		local index = 1
		local mouseX, mouseY = gui.MousePos()
		if (ply.useModule == nil) then ply.useModule = 0 end
		for degrees = 1, 360, interval do
			local mod = drawnModules[index]
			if (mod != nil) then
				local x, y = PointOnCircle( degrees, radius, centerX, centerY )
				local color = Color(50, 50, 50, 150)
				if ((mouseX >= pos.x + x - iconSize / 2 && mouseX <= pos.x + x + iconSize / 2)
					&& (mouseY >= pos.y + y - iconSize / 2 && mouseY <= pos.y + y + iconSize / 2)) then
					color = Color(50, 200, 50, 150)
					if (input.IsMouseDown(MOUSE_FIRST) && moduleChoiceDelay <= CurTime()) then
						moduleChoiceDelay = CurTime() + 0.15
						ply.useModule = mod.index
						net.Start( "SelectModuleSV" )
						net.WriteUInt(ply.useModule, 8)
						net.SendToServer()
						surface.PlaySound("common/wpn_select.wav")
					end
				end
				if (mod.index == ply.useModule) then
					if (mouseWheel >= 1 && moduleChoiceDelay <= CurTime()) then
						moduleChoiceDelay = CurTime() + 0.1
						ply.useModule = (drawnModules[index + 1] || drawnModules[1]).index
						net.Start( "SelectModuleSV" )
						net.WriteUInt(ply.useModule, 8)
						net.SendToServer()
						surface.PlaySound("common/wpn_select.wav")
					elseif (mouseWheel <= -1 && moduleChoiceDelay <= CurTime()) then
						moduleChoiceDelay = CurTime() + 0.1
						ply.useModule = (drawnModules[index - 1] || drawnModules[numSquares]).index
						net.Start( "SelectModuleSV" )
						net.WriteUInt(ply.useModule, 8)
						net.SendToServer()
						surface.PlaySound("common/wpn_select.wav")
					end
					mouseWheel = 0
				end
				
				if (ply.useModule == mod.index) then
					color = Color(50, 50, 200, 150)
				end
		
				draw.RoundedBox( 4, x - iconSize / 2, y - iconSize / 2, iconSize, iconSize, color )

				surface.SetDrawColor( hex(mod.color) )
				surface.SetMaterial( Material("ui/icons/" .. mod.icon .. ".png") )
				surface.DrawTexturedRect( x - iconSize / 2, y - iconSize / 2, iconSize, iconSize )
				index = index + 1
			end
		end
	end
end
hook.Add( "Initialize", "CreateModulesChoice", CreateModulesChoice)

concommand.Add("choiceMenu", CreateModulesChoice)

local function CreateMenu()
	local size = {x = ScrW() * 0.8, y = ScrH() * 0.8}
	modulesMenu = vgui.Create( "DFrame" )
	modulesMenu:SetPos( 120, ScrH() * 0.1 )
	modulesMenu:SetSize( size.x, size.y )
	modulesMenu:SetTitle( "" )
	modulesMenu:SetVisible( false )
	modulesMenu:SetDraggable( false )
	modulesMenu:ShowCloseButton( false )
	modulesMenu:MakePopup()
	function modulesMenu:Paint(w, h)
		draw.RoundedBox( 8, 0, 0, w, h, Color( 90, 90, 90, 150 ) )
	end
	


	local sheet = vgui.Create( "DPropertySheet", modulesMenu )
	sheet:Dock( FILL )

	local panel1 = vgui.Create( "DPanel", sheet )
	panel1.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 0 ) ) end
	sheet:AddSheet( "Modules", panel1, "icon16/cog_add.png" ) //cart_put

	/*local panel2 = vgui.Create( "DPanel", sheet )
	panel2.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 0 ) ) end
	sheet:AddSheet( "Bindings", panel2, "icon16/controller.png" ) // wrench / wrench_orange*/

	local panel3 = vgui.Create( "DScrollPanel", sheet )
	panel3.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 0 ) ) end
	sheet:AddSheet( "Profiles", panel3, "icon16/vcard_edit.png" ) //user_edit


	for i = 1, PROFILES_AMOUNT do
		local accPanel = vgui.Create("DPanel")
		accPanel:Dock( TOP )
		accPanel:SetHeight(50)
		accPanel:DockMargin( 0, 0, 0, 15 )
		panel3:AddItem( accPanel )
		function accPanel:Paint(w, h)
			draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 0 ) )
		end
		function accPanel:Think()
			self:SizeToContents()
		end
		
		local accButton = vgui.Create( "DButton", accPanel )
		accButton:SetText( "" )
		//accButton:Dock( FILL )
		function accButton:Think()
			local panelWidth, panelHeight = accPanel:GetSize()
			self:SetPos(0, 0)
			self:SetSize(panelWidth * 0.5 - panelHeight, panelHeight)
		end
		function accButton:Paint(w, h)
			local alpha = 0
			if (selectedProfile == i) then
				alpha = 50
			end

			local size = {x = w * 0.5, y = h}
			local pos = {x = 0, y = 0}
			size = {x = w, y = h}
			pos = {x = 0, y = 0}
			draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, Color( 255, 255, 255, alpha ) )
			draw.SimpleText("Profile #" .. i, "StandardTextSmall", pos.x + size.x / 2, pos.y + size.y / 2 + 5, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("Level " .. (profileLevels[i] || 1), "Default", pos.x + size.x / 2, pos.y + size.y / 2 + 10, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end


		local accButton2 = vgui.Create( "DButton", accPanel )
		//accButton2:Dock( FILL )
		accButton2:SetText( "" )
		function accButton2:Think()
			local panelWidth, panelHeight = accPanel:GetSize()
			self:SetPos(panelWidth * 0.5, 0)
			self:SetSize(panelWidth * 0.25, panelHeight)
		end
		accButton2:SetTooltip("Click to select this profile and respawn.")
		function accButton2:Paint(w, h)
			local alpha = 150
			local text = "Select"
			if (selectedProfile == i) then
				alpha = 50
				text = "In-Use"
			end

			local size = {x = w * 0.25, y = h}
			local pos = {x = w * 0.5, y = 0}
			size = {x = w, y = h}
			pos = {x = 0, y = 0}
			draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, Color( 255, 255, 255, alpha ) )
			draw.SimpleText(text, "StandardTextSmall", pos.x + size.x / 2, pos.y + size.y / 2, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		function accButton2:DoClick()
			if (selectedProfile == i) then
				surface.PlaySound("common/wpn_denyselect.wav")
				return
			end
			net.Start( "SelectProfileSV" )
			net.WriteUInt(i, 16)
			net.SendToServer()
			surface.PlaySound("buttons/button9.wav")

		end


		local accButton3 = vgui.Create( "DButton", accPanel )
		//accButton3:Dock( FILL )
		accButton3:SetText( "" )
		function accButton3:Think()
			local panelWidth, panelHeight = accPanel:GetSize()
			self:SetPos(panelWidth * 0.75, 0)
			self:SetSize(panelWidth * 0.25, panelHeight)
		end
		accButton3:SetTooltip("Click to delete this profile's data PERMANENTLY.")
		function accButton3:Paint(w, h)
			local size = {x = w * 0.25, y = h}
			local pos = {x = w - size.x, y = 0}
			size = {x = w, y = h}
			pos = {x = 0, y = 0}
			draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, Color( 255, 200, 200, 150 ) )
			draw.SimpleText("Reset", "StandardTextSmall", pos.x + size.x / 2, pos.y + size.y / 2, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		function accButton3:DoClick()
			net.Start( "ResetProfileSV" )
			net.WriteUInt(i, 16)
			net.SendToServer()
			surface.PlaySound("buttons/combine_button1.wav")
		end

		local accButton4 = vgui.Create( "DImageButton", accPanel )
		//accButton3:Dock( FILL )
		accButton4:SetImage("icon16/database_save.png")
		function accButton4:Think()
			local panelWidth, panelHeight = accPanel:GetSize()
			local size = panelHeight * 0.5
			local diff = (panelHeight - size) / 2
			self:SetSize(size, size)
			self:SetPos(panelWidth * 0.5 - panelHeight + diff, diff)
		end
		accButton4:SetTooltip("Click to save this profile's data.")
		function accButton4:DoClick()
			surface.PlaySound("buttons/lever8.wav")
			if (selectedProfile != i) then
				return
			end
			net.Start( "SaveDataSV" )
			net.SendToServer()
		end
		/*function accButton:OnEnter()
			chat.AddText( "Changed profile name to " .. self:GetValue() )

			net.Start( "ChangeProfileNameSV" )
			net.WriteUInt(i, 16)
			net.WriteString(self:GetValue())
			net.SendToServer()
		end*/
	end


	local leftPanel = vgui.Create( "DCategoryList", panel1 )
	local rightPanel = vgui.Create( "DScrollPanel", panel1 )

	local div = vgui.Create( "DHorizontalDivider", panel1 )
	div:Dock( FILL ) -- Make the divider fill the space of the DFrame
	div:SetLeft( leftPanel ) -- Set what panel is in left side of the divider
	div:SetRight( rightPanel )
	div:SetDividerWidth( 8 ) -- Set the divider width. Default is 8
	div:SetLeftMin( size.x * 0.2 ) -- Set the Minimum width of left side
	div:SetLeftWidth( size.x * 0.2 ) -- Set the default left side width
	div:SetRightMin( 20 )

	local catAmount = 1
	local lastCategory

	local dCategories = {}
	local addedCategories = {}
	for k, v in pairs (MC.modules) do
		local _category = v.category
		if (!table.HasValue(addedCategories, _category)) then
			local cat = leftPanel:Add( _category )
			dCategories[_category] = vgui.Create( "DScrollPanel" )
			cat:SetContents(dCategories[_category]);
			cat:SetHeight(40)
			function cat:Paint(w, h)
				draw.RoundedBox( 8, 0, 0, w, h, Color( 90, 90, 90, 150 ) )
			end
			table.insert(addedCategories, _category)
		end
	end

	for k, v in pairs (MC.modules) do
		if (dCategories[v.category] != nil) then
			local button = vgui.Create( "DButton" )
			button:SetText( v.name )
			button:Dock( TOP )
			button:DockMargin( 0, 0, 0, 5 )
			button:SetFont("StandardTextSmall")
			button:SetHeight(40)
			dCategories[v.category]:AddItem( button )
			function button:Paint(w, h)
				draw.RoundedBox( 8, 0, 0, w, h, Color( 255, 255, 255, 150 ) )
			end
			function button:DoClick()
				selectedModule = k
				modulesRefresh = true
				surface.PlaySound("common/wpn_select.wav")
			end
		end
	end
	
	local textWidth, panelHeight = div:GetRight():GetSize()
	local topInfo = vgui.Create( "DScrollPanel" )
	rightPanel:AddItem( topInfo )
	topInfo:SetSize( textWidth, size.y * 0.5 )
	topInfo:Dock( FILL )
	topInfo:SetPadding(4)

	local infoIcon = vgui.Create( "DImage" )
	infoIcon:Dock( LEFT )
	infoIcon:SetSize( 175, 175 )
	//infoIcon:SetImage( "scripted/breen_fakemonitor_1" )
	topInfo:AddItem( infoIcon )

	local infoButton = vgui.Create( "DButton" )
	infoButton:Dock( RIGHT )
	infoButton:SetText("")
	infoButton:SetSize( 200, 175 )
	topInfo:AddItem( infoButton )
	function infoButton:Paint(w, h)
		draw.RoundedBox( 8, 0, 0, w, h, Color( 50, 50, 50, 50 ) )
	end
	local bindButton = vgui.Create( "DBinder", topInfo )
	bindButton:SetVisible(false)
	bindButton:SetFont("StandardTextSmall")
	function bindButton:Paint(w, h)
		draw.RoundedBox( 8, 0, 0, w, h, Color( 255, 255, 255, 255 ) )
		//draw.SimpleText("Bind a key", "StandardTextSmall", pos.x + size.x / 2, pos.y + size.y / 2 - 20, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end
	local resetBindButton = vgui.Create( "DButton", topInfo )
	resetBindButton:SetText("")
	resetBindButton:SetVisible(false)
	function resetBindButton:Paint(w, h)
		draw.RoundedBox( 8, 0, 0, w, h, Color( 255, 55, 55, 200 ) )
		draw.SimpleText("Reset key", "Default", w / 2, h / 2, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local infoText = vgui.Create( "RichText" )
	infoText:Dock( FILL )
	topInfo:AddItem( infoText )
	function infoText:PerformLayout()
		self:SetFontInternal( "StandardText" )
		self:SetFGColor( Color( 255, 255, 255 ) )
	end



	local descText = vgui.Create( "RichText", rightPanel )
	function descText:PerformLayout()
		self:SetFontInternal( "StandardText" )
		self:SetFGColor( Color( 255, 255, 255 ) )
	end
	descText:SetPos(0, 200)
	descText:SizeToContents()
	function descText:Think()	
		local sizex, sizey = rightPanel:GetSize()
		self:SetSize(sizex, sizey * 0.5)
	end


	local levelsTab2 = vgui.Create( "DPanel", rightPanel )
	//levelsTab2:Dock( BOTTOM )
	function levelsTab2:Think()	
		local sizex, sizey = rightPanel:GetSize()
		self:SetPos(0, sizey - 175)
		self:SetSize(sizex, 150)
	end


	function modulesMenu:Think()
		if (modulesRefresh) then
			modulesRefresh = false
			BuildModuleInfo(infoText, descText, infoIcon, levelsTab2, infoButton, bindButton, resetBindButton)
		end
	end
end
hook.Add( "Initialize", "CreateShopMenu", CreateMenu)

concommand.Add("shopMenu", CreateMenu)


function AddVoteButtons(panel)
	local accPanel = vgui.Create("DPanel")
	accPanel:Dock( TOP )
	accPanel:SetHeight(25)
	accPanel:DockMargin( 0, 0, 0, 15 )
	panel:AddItem( accPanel )
	function accPanel:Paint(w, h)
		draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 0 ) )
	end
	
	local accButton = vgui.Create( "DButton", accPanel )
	accButton:SetText( "" )
	function accButton:Think()
		local panelWidth, panelHeight = accPanel:GetSize()
		self:SetPos(0, 0)
		self:SetSize(panelWidth * 0.5, panelHeight)
	end
	function accButton:Paint(w, h)
		local text = "PvP mode votes: " .. pvpVotes .. " / " .. table.Count(player.GetAll())
		local alpha = 50

		local size = {x = w * 0.5, y = h}
		local pos = {x = 0, y = 0}
		size = {x = w, y = h}
		pos = {x = 0, y = 0}
		draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, Color( 255, 255, 255, alpha ) )
		draw.SimpleText(text, "StandardTextSmall", pos.x + size.x / 2, pos.y + size.y / 2, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	local accButton2 = vgui.Create( "DButton", accPanel )
	accButton2:SetText( "" )
	function accButton2:Think()
		local panelWidth, panelHeight = accPanel:GetSize()
		self:SetPos(panelWidth * 0.5, 0)
		self:SetSize(panelWidth * 0.25, panelHeight)
	end
	function accButton2:Paint(w, h)
		local text = "Vote"
		local alpha = 150

		local size = {x = w * 0.5, y = h}
		local pos = {x = 0, y = 0}
		size = {x = w, y = h}
		pos = {x = 0, y = 0}
		draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, Color( 255, 255, 255, alpha ) )
		draw.SimpleText(text, "StandardTextSmall", pos.x + size.x / 2, pos.y + size.y / 2, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function accButton2:DoClick()
		surface.PlaySound("UI/buttonclick.wav")
		net.Start( "VoteSV" )
		net.WriteString("pvp")
		net.SendToServer()
	end
	
	local accButton3 = vgui.Create( "DButton", accPanel )
	accButton3:SetText( "" )
	function accButton3:Think()
		local panelWidth, panelHeight = accPanel:GetSize()
		self:SetPos(panelWidth * 0.75, 0)
		self:SetSize(panelWidth * 0.25, panelHeight)
	end
	function accButton3:Paint(w, h)
		local text = "Cancel"
		local alpha = 150

		local size = {x = w * 0.5, y = h}
		local pos = {x = 0, y = 0}
		size = {x = w, y = h}
		pos = {x = 0, y = 0}
		draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, Color( 255, 200, 200, alpha ) )
		draw.SimpleText(text, "StandardTextSmall", pos.x + size.x / 2, pos.y + size.y / 2, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function accButton3:DoClick()
		surface.PlaySound("UI/buttonclickrelease.wav")
		net.Start( "VoteSV" )
		net.WriteString("cancel_pvp")
		net.SendToServer()
	end




	

	
	local accPanel = vgui.Create("DPanel")
	accPanel:Dock( TOP )
	accPanel:SetHeight(25)
	accPanel:DockMargin( 0, 0, 0, 15 )
	panel:AddItem( accPanel )
	function accPanel:Paint(w, h)
		draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 0 ) )
	end
	
	local accButton = vgui.Create( "DButton", accPanel )
	accButton:SetText( "" )
	function accButton:Think()
		local panelWidth, panelHeight = accPanel:GetSize()
		self:SetPos(0, 0)
		self:SetSize(panelWidth * 0.5, panelHeight)
	end
	function accButton:Paint(w, h)
		local text = "Map-chnage votes: " .. mapVotes .. " / " .. table.Count(player.GetAll())
		local alpha = 50

		local size = {x = w * 0.5, y = h}
		local pos = {x = 0, y = 0}
		size = {x = w, y = h}
		pos = {x = 0, y = 0}
		draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, Color( 255, 255, 255, alpha ) )
		draw.SimpleText(text, "StandardTextSmall", pos.x + size.x / 2, pos.y + size.y / 2, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	local accButton2 = vgui.Create( "DButton", accPanel )
	accButton2:SetText( "" )
	function accButton2:Think()
		local panelWidth, panelHeight = accPanel:GetSize()
		self:SetPos(panelWidth * 0.5, 0)
		self:SetSize(panelWidth * 0.25, panelHeight)
	end
	function accButton2:Paint(w, h)
		local text = "Vote"
		local alpha = 150

		local size = {x = w * 0.5, y = h}
		local pos = {x = 0, y = 0}
		size = {x = w, y = h}
		pos = {x = 0, y = 0}
		draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, Color( 255, 255, 255, alpha ) )
		draw.SimpleText(text, "StandardTextSmall", pos.x + size.x / 2, pos.y + size.y / 2, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function accButton2:DoClick()
		surface.PlaySound("UI/buttonclick.wav")
		net.Start( "VoteSV" )
		net.WriteString("map")
		net.SendToServer()
	end
	
	local accButton3 = vgui.Create( "DButton", accPanel )
	accButton3:SetText( "" )
	function accButton3:Think()
		local panelWidth, panelHeight = accPanel:GetSize()
		self:SetPos(panelWidth * 0.75, 0)
		self:SetSize(panelWidth * 0.25, panelHeight)
	end
	function accButton3:Paint(w, h)
		local text = "Cancel"
		local alpha = 150

		local size = {x = w * 0.5, y = h}
		local pos = {x = 0, y = 0}
		size = {x = w, y = h}
		pos = {x = 0, y = 0}
		draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, Color( 255, 200, 200, alpha ) )
		draw.SimpleText(text, "StandardTextSmall", pos.x + size.x / 2, pos.y + size.y / 2, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function accButton3:DoClick()
		surface.PlaySound("UI/buttonclickrelease.wav")
		net.Start( "VoteSV" )
		net.WriteString("cancel_map")
		net.SendToServer()
	end
end

function AddSeparator(panel)
	local separator = vgui.Create("DPanel")
	separator:Dock( TOP )
	separator:SetHeight(50)
	separator:DockMargin( 0, 0, 0, 15 )
	panel:AddItem( separator )
	function separator:Paint(w, h)
		draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 0 ) )
	end
		
	local accButton = vgui.Create( "DLabel", separator )
	accButton:SetText( "" )
	function accButton:Think()
		local panelWidth, panelHeight = separator:GetSize()
		self:SetPos(0, 0)
		self:SetSize(panelWidth * 0.5, panelHeight)
	end
	function accButton:Paint(w, h)
		local text = "Name"
		local alpha = 50

		local size = {x = w * 0.5, y = h}
		local pos = {x = 0, y = 0}
		size = {x = w, y = h}
		pos = {x = 0, y = 0}
		draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, Color( 255, 255, 255, alpha ) )
		draw.SimpleText(text, "StandardTextSmall", pos.x + size.x / 2, pos.y + size.y / 2, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	local accButton2 = vgui.Create( "DLabel", separator )
	accButton2:SetText( "" )
	function accButton2:Think()
		local panelWidth, panelHeight = separator:GetSize()
		self:SetPos(panelWidth * 0.5, 0)
		self:SetSize(panelWidth * 0.5, panelHeight)
	end
	function accButton2:Paint(w, h)
		local text = "Level"
		local alpha = 50

		local size = {x = w * 0.5, y = h}
		local pos = {x = 0, y = 0}
		size = {x = w, y = h}
		pos = {x = 0, y = 0}
		draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, Color( 255, 255, 255, alpha ) )
		draw.SimpleText(text, "StandardTextSmall", pos.x + size.x / 2, pos.y + size.y / 2, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function CreateScoreboard()
	local size = {x = ScrW() * 0.75, y = ScrH() * 0.75}
	scoreboard = vgui.Create( "DFrame" )
	scoreboard:SetSize( size.x, size.y )
	scoreboard:SetTitle( "" )
	scoreboard:SetVisible( false )
	scoreboard:ShowCloseButton( false )
	scoreboard:SetDraggable( false )
	scoreboard:Center()
	function scoreboard:Paint(w, h)
		surface.SetFont("StandardText")
		local textHeight = select(2, surface.GetTextSize("nickname"))
		draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 80 ) )
		//for i, v in ipairs (player.GetAll()) do
		//	draw.DrawText(v:Nick(), "StandardText", w/2, i * textHeight, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER)
		//end
	end

	local panel = vgui.Create( "DScrollPanel", scoreboard )
	panel:Dock( FILL )
	panel.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 0 ) ) end

	/*local sheet = vgui.Create( "DPropertySheet", scoreboard )
	sheet.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 0 ) ) end
	sheet:Dock( FILL )

	local panel = vgui.Create( "DScrollPanel", sheet )
	panel.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 0 ) ) end
	sheet:AddSheet( "Players", panel, "icon16/application_view_list.png" ) //user_edit

	local panel2 = vgui.Create( "DScrollPanel", sheet )
	panel2.Paint = function( self, w, h ) draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 0 ) ) end
	sheet:AddSheet( "Vote", panel2, "icon16/application_form.png" )*/

	function scoreboard:Think()
		if (scoreboardRefresh || table.Count(player.GetAll()) != lastPlayersCount) then
			scoreboardRefresh = false
			lastPlayersCount = table.Count(player.GetAll())
			panel:Clear()
			AddVoteButtons(panel)

			AddSeparator(panel)

			for k, v in pairs (player.GetAll()) do
				local accPanel = vgui.Create("DPanel")
				accPanel:Dock( TOP )
				accPanel:SetHeight(35)
				accPanel:DockMargin( 0, 0, 0, 15 )
				panel:AddItem( accPanel )
				function accPanel:Paint(w, h)
					draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 0 ) )
				end
				
				local accButton = vgui.Create( "DButton", accPanel )
				accButton:SetText( "" )
				function accButton:Think()
					local panelWidth, panelHeight = accPanel:GetSize()
					self:SetPos(0, 0)
					self:SetSize(panelWidth * 0.5, panelHeight)
				end
				function accButton:Paint(w, h)
					local text = "Player"
					if (IsValid(v)) then text = v:Nick() end
					local alpha = 150

					local size = {x = w * 0.5, y = h}
					local pos = {x = 0, y = 0}
					size = {x = w, y = h}
					pos = {x = 0, y = 0}
					draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, Color( 255, 255, 255, alpha ) )
					draw.SimpleText(text, "StandardTextSmall", pos.x + size.x / 2, pos.y + size.y / 2, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				
				local accButton2 = vgui.Create( "DButton", accPanel )
				accButton2:SetText( "" )
				function accButton2:Think()
					local panelWidth, panelHeight = accPanel:GetSize()
					self:SetPos(panelWidth * 0.5, 0)
					self:SetSize(panelWidth * 0.5 - panelHeight, panelHeight)
				end
				function accButton2:Paint(w, h)
					local text = "Level " .. (v.level || 1)
					local alpha = 150

					local size = {x = w * 0.5, y = h}
					local pos = {x = 0, y = 0}
					size = {x = w, y = h}
					pos = {x = 0, y = 0}
					draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, Color( 255, 255, 255, alpha ) )
					draw.SimpleText(text, "StandardTextSmall", pos.x + size.x / 2, pos.y + size.y / 2, Color( 0, 0, 0, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				
				local kickButton = vgui.Create( "DImageButton", accPanel )
				kickButton:SetImage("icon16/cancel.png")
				kickButton:SetTooltip("Click to vote-kick this Player.")
				function kickButton:Think()
					local panelWidth, panelHeight = accPanel:GetSize()
					local size = panelHeight * 0.75
					local diff = (panelHeight - size) / 2
					self:SetSize(size, size)
					self:SetPos(panelWidth - panelHeight + diff, diff)

					if (LocalPlayer():IsAdmin()) then
						self:SetTooltip("Click to kick this Player instantly.")
					else
						self:SetTooltip("Click to vote-kick this Player.")
					end
				end
				function kickButton:Paint(w, h)
					local alpha = 150

					local size = {x = w * 0.5, y = h}
					local pos = {x = 0, y = 0}
					size = {x = w, y = h}
					pos = {x = 0, y = 0}
					//draw.RoundedBox( 8, pos.x, pos.y, size.x, size.y, Color( 255, 255, 255, alpha ) )
				end
				function kickButton:DoClick()
					if (kickCooldown <= CurTime()) then
						surface.PlaySound("common/wpn_denyselect.wav")
					else
						kickCooldown = CurTime() + 1
						surface.PlaySound("buttons/lever4.wav")
						net.Start( "VoteKickSV" )
						net.WriteString(v:SteamID())
						net.SendToServer()
					end
				end
			end
		end
	end
end
hook.Add( "Initialize", "CreateScorePanel", CreateScoreboard)
concommand.Add("refreshScoreboard", CreateScoreboard)

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
	for module, key in pairs (moduleKeys) do
		if (!input.IsKeyDown( key ) || key == KEY_SPACE) then
			continue
		end

		local mod = MC.modules[module]
		local modLv = modulesLevels[module]
		if (keypressDelay <= CurTime() && mod && modLv && modLv >= 1 && mod.execute != nil) then
			net.Start( "UseModuleSV" )
			net.WriteUInt(module, 8)
			net.SendToServer()
			keypressDelay = CurTime() + 0.5
		end
	end
end

--[[---------------------------------------------------------
	Name: gamemode:PlayerBindPress()
	Desc: A player pressed a bound key - return true to override action
-----------------------------------------------------------]]
function GM:PlayerBindPress( ply, bind, down )
	local override = false

	if (string.find(bind, "menu_context")) then
		override = true
		if (modulesChoice != nil) then
			modulesRefresh = true
			modulesChoice:SetVisible(down)
		end
	elseif (string.find(bind, "menu")) then
		override = true
		if (modulesMenu != nil) then
			modulesRefresh = true
			modulesMenu:SetVisible(down)
		end
	end

	if (string.find(bind, "gmod_undo")) then
		local selectableModules = {}
		local index = 1
		for k, mod in ipairs (MC.modules) do
			if (mod.execute != nil && modulesLevels[k] != nil && modulesLevels[k] >= 1) then
				local i = table.insert(selectableModules, mod)
				selectableModules[i].index = k
				if (k == ply.useModule) then
					index = i
				end
			end
		end
		if (table.Count(selectableModules) >= 1) then
			ply.useModule = (selectableModules[index + 1] || selectableModules[1]).index
			net.Start( "SelectModuleSV" )
			net.WriteUInt(ply.useModule, 8)
			net.SendToServer()
			surface.PlaySound("common/wpn_select.wav")
		end
	end

	return override
end



--[[---------------------------------------------------------
   Name: gamemode:PlayerNoClip( ply, active )
-----------------------------------------------------------]]
function GM:PlayerNoClip( ply, active )
	return false
end

--[[---------------------------------------------------------
	Name: gamemode:HUDShouldDraw( name )
	Desc: return true if we should draw the named element
-----------------------------------------------------------]]
function GM:HUDShouldDraw( name )

	-- Allow the weapon to override this
	local ply = LocalPlayer()
	if ( IsValid( ply ) ) then

		local wep = ply:GetActiveWeapon()

		if ( IsValid( wep ) && wep.HUDShouldDraw != nil ) then

			return wep.HUDShouldDraw( wep, name )

		end

	end

	return true

end

--[[---------------------------------------------------------
	Name: gamemode:HUDPaint()
	Desc: Use this section to paint your HUD
-----------------------------------------------------------]]
function GM:HUDPaint()

	//hook.Run( "HUDDrawTargetID" )
	hook.Run( "HUDDrawPickupHistory" )
	//hook.Run( "DrawDeathNotice", 0.85, 0.04 )

end

--[[---------------------------------------------------------
	Name: gamemode:HUDPaintBackground()
	Desc: Same as HUDPaint except drawn before
-----------------------------------------------------------]]
function GM:HUDPaintBackground()
end

--[[---------------------------------------------------------
	Name: gamemode:GUIMouseReleased( mousecode )
	Desc: The mouse was double clicked
-----------------------------------------------------------]]
function GM:GUIMouseDoublePressed( mousecode, AimVector )
	-- We don't capture double clicks by default,
	-- We just treat them as regular presses
	GAMEMODE:GUIMousePressed( mousecode, AimVector )
end

--[[---------------------------------------------------------
	Name: gamemode:ShutDown( )
	Desc: Called when the Lua system is about to shut down
-----------------------------------------------------------]]
function GM:ShutDown()
end

--[[---------------------------------------------------------
	Name: gamemode:RenderScreenspaceEffects( )
	Desc: Bloom etc should be drawn here (or using this hook)
-----------------------------------------------------------]]
function GM:RenderScreenspaceEffects()
end

--[[---------------------------------------------------------
	Name: gamemode:GetTeamColor( ent )
	Desc: Return the color for this ent's team
		This is for chat and deathnotice text
-----------------------------------------------------------]]
function GM:GetTeamColor( ent )

	local team = TEAM_UNASSIGNED
	if ( ent.Team ) then team = ent:Team() end
	return GAMEMODE:GetTeamNumColor( team )

end

--[[---------------------------------------------------------
	Name: gamemode:GetTeamNumColor( num )
	Desc: returns the colour for this team num
-----------------------------------------------------------]]
function GM:GetTeamNumColor( num )

	return team.GetColor( num )

end

--[[---------------------------------------------------------
	Name: gamemode:OnPlayerChat()
		Process the player's chat.. return true for no default
-----------------------------------------------------------]]
function GM:OnPlayerChat( player, strText, bTeamOnly, bPlayerIsDead )

	--
	-- I've made this all look more complicated than it is. Here's the easy version
	--
	-- chat.AddText( player, Color( 255, 255, 255 ), ": ", strText )
	--

	local tab = {}

	if ( bPlayerIsDead ) then
		table.insert( tab, Color( 255, 30, 40 ) )
		table.insert( tab, "*DEAD* " )
	end

	if ( bTeamOnly ) then
		table.insert( tab, Color( 30, 160, 40 ) )
		table.insert( tab, "(TEAM) " )
	end

	if ( IsValid( player ) ) then
		table.insert( tab, player )
	else
		table.insert( tab, "Console" )
	end

	table.insert( tab, Color( 255, 255, 255 ) )
	table.insert( tab, ": " .. strText )

	chat.AddText( unpack(tab) )

	return true

end

--[[---------------------------------------------------------
	Name: gamemode:OnChatTab( str )
	Desc: Tab is pressed when typing (Auto-complete names, IRC style)
-----------------------------------------------------------]]
function GM:OnChatTab( str )

	str = string.TrimRight(str)
	
	local LastWord
	for word in string.gmatch( str, "[^ ]+" ) do
		LastWord = word
	end

	if ( LastWord == nil ) then return str end

	for k, v in pairs( player.GetAll() ) do

		local nickname = v:Nick()

		if ( string.len( LastWord ) < string.len( nickname ) && string.find( string.lower( nickname ), string.lower( LastWord ), 0, true ) == 1 ) then

			str = string.sub( str, 1, ( string.len( LastWord ) * -1 ) - 1 )
			str = str .. nickname
			return str

		end

	end

	return str

end

--[[---------------------------------------------------------
	Name: gamemode:StartChat( teamsay )
	Desc: Start Chat.

			If you want to display your chat shit different here's what you'd do:
			In StartChat show your text box and return true to hide the default
			Update the text in your box with the text passed to ChatTextChanged
			Close and clear your text box when FinishChat is called.
			Return true in ChatText to not show the default chat text

-----------------------------------------------------------]]
function GM:StartChat( teamsay )

	return false

end

--[[---------------------------------------------------------
	Name: gamemode:FinishChat()
-----------------------------------------------------------]]
function GM:FinishChat()
end

--[[---------------------------------------------------------
	Name: gamemode:ChatTextChanged( text)
-----------------------------------------------------------]]
function GM:ChatTextChanged( text )
end

--[[---------------------------------------------------------
	Name: ChatText
	Allows override of the chat text
-----------------------------------------------------------]]
function GM:ChatText( playerindex, playername, text, filter )

	if ( filter == "chat" ) then
		Msg( playername, ": ", text, "\n" )
	else
		Msg( text, "\n" )
	end

	return false

end

--[[---------------------------------------------------------
	Name: gamemode:PostProcessPermitted( str )
	Desc: return true/false depending on whether this post process should be allowed
-----------------------------------------------------------]]
function GM:PostProcessPermitted( str )

	return true

end

--[[---------------------------------------------------------
	Name: gamemode:PostRenderVGUI( )
	Desc: Called after VGUI has been rendered
-----------------------------------------------------------]]
function GM:PostRenderVGUI()
end

--[[---------------------------------------------------------
	Name: gamemode:PreRender( )
	Desc: Called before all rendering
		Return true to NOT render this frame for some reason (danger!)
-----------------------------------------------------------]]
function GM:PreRender()
	return false
end

--[[---------------------------------------------------------
	Name: gamemode:PostRender( )
	Desc: Called after all rendering
-----------------------------------------------------------]]
function GM:PostRender()
end

--[[---------------------------------------------------------
	Name: gamemode:RenderScene( )
	Desc: Render the scene
-----------------------------------------------------------]]
function GM:RenderScene( origin, angle, fov )
end

--[[---------------------------------------------------------
	Name: CalcVehicleView
-----------------------------------------------------------]]
function GM:CalcVehicleView( Vehicle, ply, view )

	if ( Vehicle.GetThirdPersonMode == nil || ply:GetViewEntity() != ply ) then
		-- This hsouldn't ever happen.
		return
	end

	--
	-- If we're not in third person mode - then get outa here stalker
	--
	if ( !Vehicle:GetThirdPersonMode() ) then return view end

	-- Don't roll the camera
	-- view.angles.roll = 0

	local mn, mx = Vehicle:GetRenderBounds()
	local radius = ( mn - mx ):Length()
	local radius = radius + radius * Vehicle:GetCameraDistance()

	-- Trace back from the original eye position, so we don't clip through walls/objects
	local TargetOrigin = view.origin + ( view.angles:Forward() * -radius )
	local WallOffset = 4

	local tr = util.TraceHull( {
		start = view.origin,
		endpos = TargetOrigin,
		filter = function( e )
			local c = e:GetClass() -- Avoid contact with entities that can potentially be attached to the vehicle. Ideally, we should check if "e" is constrained to "Vehicle".
			return !c:StartWith( "prop_physics" ) &&!c:StartWith( "prop_dynamic" ) && !c:StartWith( "prop_ragdoll" ) && !e:IsVehicle() && !c:StartWith( "gmod_" )
		end,
		mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
		maxs = Vector( WallOffset, WallOffset, WallOffset ),
	} )

	view.origin = tr.HitPos
	view.drawviewer = true

	--
	-- If the trace hit something, put the camera there.
	--
	if ( tr.Hit && !tr.StartSolid) then
		view.origin = view.origin + tr.HitNormal * WallOffset
	end

	return view

end

--[[---------------------------------------------------------
	Name: CalcView
	Allows override of the default view
-----------------------------------------------------------]]
function GM:CalcView( ply, origin, angles, fov, znear, zfar )

	local Vehicle	= ply:GetVehicle()
	local Weapon	= ply:GetActiveWeapon()

	local view = {}
	view.origin		= origin
	view.angles		= angles
	view.fov		= fov
	view.znear		= znear
	view.zfar		= zfar
	view.drawviewer	= false

	--
	-- Let the vehicle override the view and allows the vehicle view to be hooked
	--
	if ( IsValid( Vehicle ) ) then return hook.Run( "CalcVehicleView", Vehicle, ply, view ) end

	--
	-- Let drive possibly alter the view
	--
	if ( drive.CalcView( ply, view ) ) then return view end

	--
	-- Give the player manager a turn at altering the view
	--
	player_manager.RunClass( ply, "CalcView", view )

	-- Give the active weapon a go at changing the viewmodel position
	if ( IsValid( Weapon ) ) then

		local func = Weapon.CalcView
		if ( func ) then
			view.origin, view.angles, view.fov = func( Weapon, ply, origin * 1, angles * 1, fov ) -- Note: *1 to copy the object so the child function can't edit it.
		end

	end

	return view

end

--
-- If return true:		Will draw the local player
-- If return false:		Won't draw the local player
-- If return nil:		Will carry out default action
--
function GM:ShouldDrawLocalPlayer( ply )

	return player_manager.RunClass( ply, "ShouldDrawLocal" )

end

--[[---------------------------------------------------------
	Name: gamemode:AdjustMouseSensitivity()
	Desc: Allows you to adjust the mouse sensitivity.
		The return is a fraction of the normal sensitivity (0.5 would be half as sensitive)
		Return -1 to not override.
-----------------------------------------------------------]]
function GM:AdjustMouseSensitivity( fDefault )

	local ply = LocalPlayer()
	if ( !IsValid( ply ) ) then return -1 end

	local wep = ply:GetActiveWeapon()
	if ( wep && wep.AdjustMouseSensitivity ) then
		return wep:AdjustMouseSensitivity()
	end

	return -1

end

--[[---------------------------------------------------------
	Name: gamemode:ForceDermaSkin()
	Desc: Return the name of skin this gamemode should use.
		If nil is returned the skin will use default
-----------------------------------------------------------]]
function GM:ForceDermaSkin()

	--return "example"
	return nil

end

--[[---------------------------------------------------------
	Name: gamemode:PostPlayerDraw()
	Desc: The player has just been drawn.
-----------------------------------------------------------]]
function GM:PostPlayerDraw( ply )
end

--[[---------------------------------------------------------
	Name: gamemode:PrePlayerDraw()
	Desc: The player is just about to be drawn.
-----------------------------------------------------------]]
function GM:PrePlayerDraw( ply )
end

--[[---------------------------------------------------------
	Name: gamemode:GetMotionBlurSettings()
	Desc: Allows you to edit the motion blur values
-----------------------------------------------------------]]
function GM:GetMotionBlurValues( x, y, fwd, spin )

	-- fwd = 0.5 + math.sin( CurTime() * 5 ) * 0.5

	return x, y, fwd, spin

end

--[[---------------------------------------------------------
	Name: gamemode:InputMouseApply()
	Desc: Allows you to control how moving the mouse affects the view angles
-----------------------------------------------------------]]
function GM:InputMouseApply( cmd, x, y, angle )

	--angle.roll = angle.roll + 1
	--cmd:SetViewAngles( Ang )
	--return true

end

--[[---------------------------------------------------------
	Name: gamemode:OnAchievementAchieved()
-----------------------------------------------------------]]
function GM:OnAchievementAchieved( ply, achid )

	chat.AddText( ply, Color( 230, 230, 230 ), " earned the achievement ", Color( 255, 200, 0 ), achievements.GetName( achid ) )

end

--[[---------------------------------------------------------
	Name: gamemode:PreDrawSkyBox()
	Desc: Called before drawing the skybox. Return true to not draw the skybox.
-----------------------------------------------------------]]
function GM:PreDrawSkyBox()

	--return true

end

--[[---------------------------------------------------------
	Name: gamemode:PostDrawSkyBox()
	Desc: Called after drawing the skybox
-----------------------------------------------------------]]
function GM:PostDrawSkyBox()
end

--
-- Name: GM:PostDraw2DSkyBox
-- Desc: Called right after the 2D skybox has been drawn - allowing you to draw over it.
-- Arg1:
-- Ret1:
--
function GM:PostDraw2DSkyBox()
end

--[[---------------------------------------------------------
	Name: gamemode:PreDrawOpaqueRenderables()
	Desc: Called before drawing opaque entities
-----------------------------------------------------------]]
function GM:PreDrawOpaqueRenderables( bDrawingDepth, bDrawingSkybox )

	-- return true

end

--[[---------------------------------------------------------
	Name: gamemode:PreDrawOpaqueRenderables()
	Desc: Called before drawing opaque entities
-----------------------------------------------------------]]
function GM:PostDrawOpaqueRenderables( bDrawingDepth, bDrawingSkybox )
end

--[[---------------------------------------------------------
	Name: gamemode:PreDrawOpaqueRenderables()
	Desc: Called before drawing opaque entities
-----------------------------------------------------------]]
function GM:PreDrawTranslucentRenderables( bDrawingDepth, bDrawingSkybox )

	-- return true

end

--[[---------------------------------------------------------
	Name: gamemode:PreDrawOpaqueRenderables()
	Desc: Called before drawing opaque entities
-----------------------------------------------------------]]
function GM:PostDrawTranslucentRenderables( bDrawingDepth, bDrawingSkybox )
end

--[[---------------------------------------------------------
	Name: gamemode:CalcViewModelView()
	Desc: Called to set the view model's position
-----------------------------------------------------------]]
function GM:CalcViewModelView( Weapon, ViewModel, OldEyePos, OldEyeAng, EyePos, EyeAng )

	if ( !IsValid( Weapon ) ) then return end

	local vm_origin, vm_angles = EyePos, EyeAng

	-- Controls the position of all viewmodels
	local func = Weapon.GetViewModelPosition
	if ( func ) then
		local pos, ang = func( Weapon, EyePos*1, EyeAng*1 )
		vm_origin = pos or vm_origin
		vm_angles = ang or vm_angles
	end

	-- Controls the position of individual viewmodels
	func = Weapon.CalcViewModelView
	if ( func ) then
		local pos, ang = func( Weapon, ViewModel, OldEyePos*1, OldEyeAng*1, EyePos*1, EyeAng*1 )
		vm_origin = pos or vm_origin
		vm_angles = ang or vm_angles
	end

	return vm_origin, vm_angles

end

--[[---------------------------------------------------------
	Name: gamemode:PreDrawViewModel()
	Desc: Called before drawing the view model
-----------------------------------------------------------]]
function GM:PreDrawViewModel( ViewModel, Player, Weapon )

	if ( !IsValid( Weapon ) ) then return false end

	player_manager.RunClass( Player, "PreDrawViewModel", ViewModel, Weapon )

	if ( Weapon.PreDrawViewModel == nil ) then return false end
	return Weapon:PreDrawViewModel( ViewModel, Weapon, Player )

end

--[[---------------------------------------------------------
	Name: gamemode:PostDrawViewModel()
	Desc: Called after drawing the view model
-----------------------------------------------------------]]
function GM:PostDrawViewModel( ViewModel, Player, Weapon )

	if ( !IsValid( Weapon ) ) then return false end

	if ( Weapon.UseHands || !Weapon:IsScripted() ) then

		local hands = Player:GetHands()
		if ( IsValid( hands ) ) then

			if ( not hook.Call( "PreDrawPlayerHands", self, hands, ViewModel, Player, Weapon ) ) then

				if ( Weapon.ViewModelFlip ) then render.CullMode( MATERIAL_CULLMODE_CW ) end
				hands:DrawModel()
				render.CullMode( MATERIAL_CULLMODE_CCW )

			end

			hook.Call( "PostDrawPlayerHands", self, hands, ViewModel, Player, Weapon )
			
		end

	end

	player_manager.RunClass( Player, "PostDrawViewModel", ViewModel, Weapon )

	if ( Weapon.PostDrawViewModel == nil ) then return false end
	return Weapon:PostDrawViewModel( ViewModel, Weapon, Player )

end

--[[---------------------------------------------------------
	Name: gamemode:DrawPhysgunBeam()
	Desc: Return false to override completely
-----------------------------------------------------------]]
function GM:DrawPhysgunBeam( ply, weapon, bOn, target, boneid, pos )

	-- Do nothing
	return true

end

--[[---------------------------------------------------------
	Name: gamemode:NetworkEntityCreated()
	Desc: Entity is created over the network
-----------------------------------------------------------]]
function GM:NetworkEntityCreated( ent )
end

--[[---------------------------------------------------------
	Name: gamemode:CreateMove( command )
	Desc: Allows the client to change the move commands
			before it's send to the server
-----------------------------------------------------------]]
function GM:CreateMove( cmd )

	if ( drive.CreateMove( cmd ) ) then return true end

	if ( player_manager.RunClass( LocalPlayer(), "CreateMove", cmd ) ) then return true end

end

--[[---------------------------------------------------------
	Name: gamemode:PreventScreenClicks()
	Desc: The player is hovering over a ScreenClickable world
-----------------------------------------------------------]]
function GM:PreventScreenClicks( cmd )

	--
	-- Returning true in this hook will prevent screen clicking sending IN_ATTACK
	-- commands to the weapons. We want to do this in the properties system, so
	-- that you don't fire guns when opening the properties menu. Holla!
	--

	return false

end

--[[---------------------------------------------------------
	Name: gamemode:GUIMousePressed( mousecode )
	Desc: The mouse has been pressed on the game screen
-----------------------------------------------------------]]
function GM:GUIMousePressed( mousecode, AimVector )
end

--[[---------------------------------------------------------
	Name: gamemode:GUIMouseReleased( mousecode )
	Desc: The mouse has been released on the game screen
-----------------------------------------------------------]]
function GM:GUIMouseReleased( mousecode, AimVector )
end

function GM:PreDrawHUD()
end

function GM:PostDrawHUD()
end

function GM:DrawOverlay()
end

function GM:DrawMonitors()
end

function GM:PreDrawEffects()
end

function GM:PostDrawEffects()
end

function GM:PreDrawHalos()
end

function GM:CloseDermaMenus()
end

function GM:CreateClientsideRagdoll( entity, ragdoll )
end

function GM:VehicleMove( ply, vehicle, mv )
end

function GM:ScoreboardShow()
	if (scoreboard != nil) then
		scoreboardRefresh = true
		scoreboard:SetVisible(true)
		scoreboard:MakePopup()
	end
	return false
end

function GM:ScoreboardHide()
	if (scoreboard != nil) then
		scoreboard:SetVisible(false)
	end
	return false
end