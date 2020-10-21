NPCs = {
    {
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
	},

    {
		name = "Silver Combine Cop",
		npc = "npc_metropolice",
		health = function() return math.random(15,22) end,
		size = 1.5,
		weapon = "ai_weapon_pistol",
		type = "metal",
		exp = 380,
		chance = 15,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	},

    {
		name = "Scanner",
		npc = "npc_cscanner",
		health = function() return math.random(5,10) end,
		size = 1,
		weapon = "",
		type = "",
		exp = 50,
		chance = 15,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	},

    {
		name = "Silver Scanner",
		npc = "npc_cscanner",
		health = function() return math.random(9,15) end,
		size = 1.33,
		weapon = "",
		type = "metal",
		exp = 65,
		chance = 10,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	},

	{
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
	},

	{
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
	},

	{
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
	},

	{
		name = "Combine Rogue",
		npc = "npc_combine_s",
		health = function() return math.random(5,8) end,
		size = 1,
		weapon = "ai_weapon_shotgun",
		type = "",
		exp = 300,
		chance = 23,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	},

	{
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
	},

	{
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
	},

	{
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
	},

	{
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
	},

	{
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
	},

	{
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
	},

	{
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
	},

	{
		name = "Silver Manhack",
		npc = "npc_manhack",
		health = function() return math.random(15,20) end,
		size = 2.5,
		weapon = "",
		type = "metal",
		exp = 120,
		chance = 2099999,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	},

	{
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
	},

	{
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
	},

	{
		name = "Poison Zombie",
		npc = "npc_poisonzombie",
		health = function() return math.random(20,25) end,
		size = 1,
		weapon = "",
		type = "",
		exp = 400,
		chance = 15,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_GOOD
	},

	{
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
	},

	{
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
	},

	{
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
	},

	{
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
	},

	{
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
	},

	{
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
	},

	{
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
	},

	{
		name = "Rollermine",
		npc = "npc_rollermine",
		health = function() return math.random(20,30) end,
		size = 1,
		weapon = "",
		type = "",
		exp = 250,
		chance = 14,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	},

	{
		name = "Silver Rollermine",
		npc = "npc_rollermine",
		health = function() return math.random(30, 45) end,
		size = 1,
		weapon = "",
		type = "metal",
		exp = 250,
		chance = 23,
		boss = false,
		proficiency = WEAPON_PROFICIENCY_POOR
	},

	{
		name = "Strider",
		npc = "npc_strider",
		health = function() return math.random(500,550) end,
		size = 1,
		weapon = "",
		type = "",
		exp = 5000,
		chance = 5,
		boss = true,
		proficiency = WEAPON_PROFICIENCY_POOR
	},

	{
		name = "Combine Helicopter",
		npc = "npc_helicopter",
		health = function() return math.random(300,350) end,
		size = 1,
		weapon = "",
		type = "",
		exp = 5000,
		chance = 3,
		boss = true,
		proficiency = WEAPON_PROFICIENCY_POOR
	},
}