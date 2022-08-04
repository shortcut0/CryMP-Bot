---------------------------------------
-- This file is obsolete!
-- Please use BotLauncher to start bots

Config = {

	----------------------------------------------
	-- System disabled
	System = true;
	
	-- System break
	SystemBreak = false;

	----------------------------------------------
	-- Server list
	ServerList = { };
	
	-- Name of the current server
	CurrentServer = "116.203.92.129:50002"; -- tox PS
	CurrentServer = "116.203.92.129:55001"; -- atom 
	CurrentServer = "116.203.92.129:64087"; -- something
	CurrentServer = "94.16.110.182:64005"; -- alien
	CurrentServer = "127.0.0.1:66666:2020"; -- local
	CurrentServer = "116.203.92.129:50001"; -- tox IA
	CurrentServer = "116.203.92.129:64088"; -- something_pro
	
	----------------------------------------------
	-- if true, bot will automatically connect to servers
	AutoConnect = true;
	
	-- if true, game will be quit if disconnected from server for Xth times
	ZombieQuit = true;
	
	-- how often you can get disconnected until Zombie Quit
	ZombieDisconnects = 300;

	-- Check if server can be joined
	ValidateSever = false;
	
	----------------------------------------------
	-- If false, bot will not send chat messages
	BotChatMessages = false; -- !!TEMP!!
	
	-- lower number is higher chance to send a message
	BotMessageChance = 20;
	
	----------------------------------------------
	-- Time between each melee attacks with a gun in hand
	GunMeleeDelay = 0.1;
	
	-- Time between each melee attacks
	MeleeDelay = 0.5;
	
	----------------------------------------------
	-- If the bot will disarm (shoot) explosives
	ShootExplosives = true;
	
	-- If the bot will use claymores and place them around spawns
	ClaymoreMaster = true;
	
	-- If the bot will use c4 and and blow up nearby players
	C4Master = true;
	
	----------------------------------------------
	-- Blacklist for items
	BotBlacklist = { ["socom"] = true };
	
	----------------------------------------------
	-- Buy items in buy zones
	BuyItems = true;
	
	-- buy these kits
	BuyableKits = { ["RadarKit"] = true, ["Lockpick"] = false, ["RepairKit"] = false };
	
	-- priority for buyable kits
	KitPriority = {
		['RadarKit'] = 3,
		['RepairKit'] = 2,
		['LockpickKit'] = 1,
	};
	
	-- buy these explosives
	BuyableExplosives = { ["Claymore"] = true, ["C4"] = true };
	
	-- priority for buyable explosives
	ExplosivePriority = {
		['C4'] = 2,
		['Claymore'] = 1,
	};
	
	-- buy only these items
	BuyableItems = { ["GaussRifle"] = true, ["DSG1"] = true, ["FY71"] = true, ["SCAR"] = true, ["SMG"] = true, ["Claymore"] = true };
	
	-- priority for buyable items
	BuyPriority = {
		['GaussRifle'] = 3.1,
		['DSG1'] = 3.2,
		['FY71'] = 3.0,
		['SCAR'] = 2.5,
		['SMG'] = 1.5,
		['LAW'] = 0,
	};
	
	-- dont buy these items
	ExcludedItems = { };
	
	----------------------------------------------
	-- Default suit modes
	DefaultSuitMode = 'ARMOR';
	
	----------------------------------------------
	-- if true, bot will be able to follow players
	BotFollowSystem = false;
	
	-- if set, players connecting with this name will be automatically selected as follower
	BotFollowSystemAutoName = "";
	
	-- Auto follow mode
	BotAutoFollow = false;
	
	-- Continue on normal pathes if we do not see out following target or the path is blocked
	ResetPathOnFollowerLoose = true;
	
	-- if true, and bot lost original follow target, bot will follow random players hoping to get to his original follow target
	BotSmartFollow = false;
	
	-- config and options for actions bot should copy from players he follows
	BotFollowConfig = {
		NanoSuit = {
			-- copy cloak?
			CLOAK	 = true;
			
			-- copy strength?
			STRENGTH = false;
			
			-- copy speed?
			SPEED	 = false;
			
			-- copy armor?
			ARMOR	 = true;
		};
		
		-- if true bot will try to always select gun which player has selected (if bot still has ammo etc)
		CopyCurrentGun = true; 
		
		-- distance where bot is considered to be 'close' to the player
		NearDistance = 8; 
		
		-- randomize value above
		NearDistanceRandom = true;

		-- if distance > than this bot will stop following this player		
		LooseDistance = 250; 
		
		-- prone spam, box each other, etc, kinda cringy
		FunnyBehavior = true; 
		
		-- copy players current stance
		CopyStance = true; 
	};
	
	-- if true, bot will enter vehicles
	FollowModeUseVehicles = true;
	
	----------------------------------------------
	-- if true, bot will attempt to circle jump
	FollowGruntBoxRunning = true;
	
	-- always go to fursthest visible point on the path
	FollowGruntUseFurthestPoint = true;
	
	-- time in ms until bot is considered stuck
	FollowGruntStuckTimer = 3000;
	
	-- maximum points a path can have (oldest will be removed)
	FollowGruntMaxPathPoints = 1000;
	
	-- something
	FollowGruntPathInsertDistance = 0.04;
	
	-- something
	FollowGruntStuckDist = 0.01;
	
	----------------------------------------------
	-- if true, bot will team with players
	BotTeaming = false;
	
	-- name tag of players the bot will consider teammates
	BotTeamName = "[CRYCLAN]";
	
	----------------------------------------------
	-- if false, bot will not move around
	BotMovement = true;
	
	-- if true, bot will never sprint (like newbies do)
	NoSprinting = false;
	
	-- if true, bot will use WIP circlejumping
	BotCircleJumping = true;
	
	----------------------------------------------
	-- Randomize path pos (Experimental)
	PathRandomizing = true;
	
	-- Randomize path pos by this amount
	PathRandomizing_Max = 20; -- cm
	
	----------------------------------------------
	-- the lean amount for all players (0.25 default)
	LeanAmount = 0.5; -- 0.5 to counter leaning players
	
	----------------------------------------------
	-- time between change of combat move direction
	CombatMovementChangeTimer = 0.8;
	
	-- the distance to run during combat movment (left or right)
	CombatMovementDistance = 1.5;
	
	-- if bots will randomly prone during combat movement
	CombatMovementProne = true;
	
	----------------------------------------------
	-- if true, bot will throw grenades
	UseGrenades = true;
	
	-- if true, bot will use weapon accessories
	UseAttachments = true;
	
	-- if true, bot will pick up weapons
	PickupWeapons = true;
	
	-- list of weapons bot will consider worth picking up
	PickableWeapons = { ["SCAR"] = true, ["FY71"] = true, ["SMG"] = true, ["Shotgun"] = true };
	
	-- list of weapons bot will ALWAYS consider worth picking up (so even when it always has a proper gun)
	PickableGucciWeapons = { ["GaussRifle"] = true, ["Hurricane"] = true };

	----------------------------------------------
	-- the skill set of the bot (-1 = worst, 4 = hacker)
	BotSkillSet = 3;
	
	----------------------------------------------
	-- see defined difficulties below
	BotDefaultDifficulty = "";
	
	-- Bot difficulty modes
	BotDifficulties = {};
	
	----------------------------------------------
	-- Bot aim config
	AimBone = "neck"; -- can be 'random' for random bone, invalid bone names will be overwritten by 'Pelvis'
	
	----------------------------------------------
	-- CVars that will be set when bot entered the server
	AutoCVars = {
	--	['time_scale'] = 3;
		['e_render'] = 1; -- no render
		['sys_flash'] = 1; -- no flash files
		['ai_logconsoleverbosity'] = 4; -- no flash files
		['ai_logfileverbosity'] = 4; -- no flash files
		['sys_maxFPS'] = 60.0; -- maximum allowed FPS, 60 for normal firerate
	};
	
	----------------------------------------------
	-- if true, players with special keyword in name can control the servers
	AdminMode = true;
	
	-- encrypt admin commands
	EncryptCommands = false;
	
	-- keyword for player names for AdminMode
	AdminName = "ryzen"; -- Rise with Ryzen
	
	----------------------------------------------
	-- If true, bot uses names
	BotUseNames = false;
	
	-- If true, bot uses weird random names
	RandomNames = false;
	
	-- The Name of the Bot
	BotName = "Bot";
	
	----------------------------------------------
	-- if true, error box will appear on script error
	UseErrorBox = false;
	
	-- Quit Bot if Hard Script Error occurs (e.g. Error on Init)
	QuitOnHardError = false;
	
	-- Quit Bot if Soft Script Error occurs (e.g. Error in OnHit)
	QuitOnSoftError = false;
	
	----------------------------------------------
	-- if true, will move BotLogs to correct folder
	LogMover = false;
};
