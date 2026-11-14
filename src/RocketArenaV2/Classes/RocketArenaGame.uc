class RocketArenaGame extends DeathMatchPlus;

#exec OBJ LOAD FILE=RocketArenaMedia.u PACKAGE=RocketArenaMedia
#exec OBJ LOAD FILE=RocketArenaV2Media.u PACKAGE=RocketArenaV2Media

var() class<ArenaGame> DefaultArenaType;

// Voice Selection
var class<RAVoice> NewVoiceTheme;
var globalconfig string NewVoiceThemeName;

// HUD display
var globalconfig int HUDTeamDisplay;

// Force configs.
var globalconfig bool  Force1on1;
var globalconfig bool  ForceInstantRocketFire;
var globalconfig bool  DisallowSpectatorSpeech;
var globalconfig float BouncyHeight;
var globalconfig bool  FallingDamage;

// Injury tracking.  Track up to 6 player pawns.
var PlayerPawn RecentlyInjured[6];
var float RecentDamage[6];

// Debug control.

// Another GRI reference to simplify code.
var RAGameReplicationInfo RAGRI;

// Pickup gametype classes.
var class<ArenaGame> PickupClasses[8];

var config class<ArenaGame> PreferredPickupClass;

//RA Version Number
var string Version;

// simple code that should make bots aggressive :)

function bool OneOnOne()
{
	return true;
}
function bool NeverStakeOut(bot Other)
{
	return true;
}

event InitGame( string Options, out string Error )
{
	local RAMessageMutator MessageMutator;

	// Don't score by fraglimit or timelimit.
	Fraglimit = 0;

	// Remove external bots setting.
	InitialBots = 0;

	// Force change levels.
	bChangeLevels = true;

	// The arenas run their own matches, so the tournament warmup of DeathMatchPlus never
	// starts or ends here (its CountDown is never counted down). Off, or InstaGib+ treats
	// the whole map as warmup: ready players get its green "ready" flag on their back,
	// its warmup state and autopause.
	bTournament = false;

	Super.InitGame( Options, Error );

	// Spawn message mutator.  BaseMutator only exists after GameInfo.InitGame.
	MessageMutator = spawn(class'RAMessageMutator');

	BaseMutator.AddMutator( MessageMutator );
	RegisterMessageMutator( MessageMutator );

	// Registered after the URL mutators, so it runs last in the damage mutator
	// chain: RA has the final say over damage and momentum.
	RegisterDamageMutator( spawn(class'RADamageMutator') );
	spawn(class'RAProjectileNotify');
}

function PreBeginPlay()
{
	local int i;

	Super.PreBeginPlay();

	RAGRI = RAGameReplicationInfo(GameReplicationInfo);
	RAGRI.WeaponInfo = Spawn(class'WeaponInfo');
	UpdateServerSettings();

	// Create a context for each arena's ArenaType.
	foreach AllActors(class'ArenaInfo', RAGRI.ArenaInfo)
	{
		for (i=0; i<8; i++)
		{
			if (RAGRI.ArenaInfo.ArenaType[i] != 0)
			{
				if (Force1on1)
					RAGRI.ArenaInfo.ArenaTeamSize[i] = 1;
				if (RAGRI.ArenaInfo.ArenaType[i] == 1)
					RAGRI.ArenaGames[i] = Spawn(class'RocketArenaV2.ArenaGame_Multi');
				else
					RAGRI.ArenaGames[i] = Spawn(PreferredPickupClass);
				RAGRI.ArenaGames[i].Game = Self;
				RAGRI.ArenaGames[i].Arena = i;
				RAGRI.ArenaGames[i].InitGame();
				Log("RocketArenaV2: arena"@i@"'"$RAGRI.ArenaInfo.ArenaNames[i]$"'"@RAGRI.ArenaGames[i].GameName@"team size"@RAGRI.ArenaInfo.ArenaTeamSize[i]);
			}
		}
		break;
	}
	if ( RAGRI.ArenaInfo == None )
		Log("RocketArenaV2: no ArenaInfo in this map, using it as a single arena");
	// If no ArenaInfo exists, create a default context.
	if ( RAGRI.ArenaInfo == None )
	{
		RAGRI.ArenaInfo = Spawn(class'ArenaInfo');
		if ( RAGRI.ArenaInfo != None )
		{
			RAGRI.ArenaInfo.ArenaNames[0] = Level.Title;
			RAGRI.ArenaGames[0] = Spawn(DefaultArenaType);
			RAGRI.ArenaGames[0].Game = Self;
			RAGRI.ArenaGames[0].Arena = 0;
			RAGRI.ArenaGames[0].InitGame();
		}
	}
}

function PostBeginPlay()
{
	local Inventory Inv;
	local int i;

	Super.PostBeginPlay();

	// No pickups: weapons and armor are handed out at the start of a round.
	foreach AllActors(class'Inventory', Inv)
		if (!Inv.bHeldItem)
			Inv.Destroy();

	for (i=0; i<8; i++)
	{
		if (RAGRI.ArenaGames[i] != None)
			RAGRI.ArenaGames[i].InitTeams();
	}
}

// Players keep the class the mutators give them (InstaGib+ needs its own player
// class), so RA has no player class of its own.
event playerpawn Login
(
	string Portal,
	string Options,
	out string Error,
	class<playerpawn> SpawnClass
)
{
	local PlayerPawn NewPlayer;

	NewPlayer = Super.Login(Portal, Options, Error, SpawnClass);

	// Add Rocket arena specific replication info.
	if (NewPlayer != None)
		SpawnRepInfo( NewPlayer );

	return NewPlayer;
}

// A new player goes to spectating in an arena right away. Waiting for the client's
// Login call (sent once its UWindow is up) left him in the arena without weapons
// or HUD for a few seconds.
event PostLogin( PlayerPawn NewPlayer )
{
	local RAReplicationInfo RA;

	Super.PostLogin(NewPlayer);

	class'RATools'.static.GetRepInfo(NewPlayer, GameReplicationInfo, RA);
	if (RA != None && !RA.bServerLoggedIn)
	{
		RA.bServerLoggedIn = true;
		MoveToGame(NewPlayer, -1);
	}
}

function Logout( pawn Exiting )
{
	local RAReplicationInfo RA;

	local RAReplicationInfo Other;

	class'RATools'.static.GetRepInfo(Exiting, RAGRI, RA);
	if (RA != None)
	{
		RAGRI.ArenaGames[RA.Arena].Logout( Exiting, RA );
		RA.RemoveThyself();
	}
	// His kill matrix entries go with him.
	for (Other=RAGRI.RepInfoList; Other!=None; Other=Other.NextRepInfo)
		Other.ForgetVictim(Exiting.PlayerReplicationInfo);
	ResetViewersOf(Exiting);
	Super.Logout( Exiting );
}

function CreateTeam( PlayerPawn Player, string TeamName, bool bWaitForFull )
{
	local RAReplicationInfo RA;

	class'RATools'.static.GetRepInfo(Player, GameReplicationInfo, RA);
	if (RA != None)
		RAGRI.ArenaGames[RA.Arena].CreateTeam( Player, TeamName, bWaitForFull );
}

function bool CanChangeArenas( Pawn Player )
{
	local RAReplicationInfo RA;

	class'RATools'.static.GetRepInfo(Player, GameReplicationInfo, RA);
	return RAGRI.ArenaGames[RA.Arena].CanChangeArenas( Player );
}

function LeaveTeam( Pawn Player )
{
	local RAReplicationInfo RA;

	class'RATools'.static.GetRepInfo(Player, GameReplicationInfo, RA);
	RAGRI.ArenaGames[RA.Arena].LeaveTeam( Player );
	Player.PlayerReplicationInfo.Team = 255;
}

function bool ChangeTeam(Pawn Other, int NewTeam)
{
	local RAReplicationInfo RA;

	if ((Other.IsA('PlayerPawn')) && (PlayerPawn(Other).GameReplicationInfo == None))
	{
		// New player, move to spectators.
		Log("RocketArenaV2: ChangeTeam called on a new player");
		return RAGRI.ArenaGames[0].ChangeTeam( Other, -1 );
	} else {
		class'RATools'.static.GetRepInfo(Other, GameReplicationInfo, RA);
		if (RA == None)
			return RAGRI.ArenaGames[0].ChangeTeam( Other, NewTeam );
		else
			return RAGRI.ArenaGames[RA.Arena].ChangeTeam( Other, NewTeam );
	}
}

function AddToGame( Pawn Player, int Game )
{
	local RAReplicationInfo RA;

	class'RATools'.static.GetRepInfo(Player, GameReplicationInfo, RA);

	if (RAGRI.ArenaGames[RA.Arena].SafeToMove( Player ))
	{
		MoveToGame( Player, Game );
	} else
		Player.ClientMessage("The server can't move you to that arena right now.  Weird?!?");
}

function MoveToGame( Pawn Player, int Game )
{
	local ArenaViewCam Cam;
	local RAReplicationInfo RA;
	local PlayerIterator PIter;
	local int GoodArena, EmptyArena, i;

	class'RATools'.static.GetRepInfo(Player, GameReplicationInfo, RA);

	if (Game == -1) // Auto-choose
	{
		GoodArena = -1;
		EmptyArena = -1;
		for (i=0;i<8;i++)
		{
			if (ArenaGame_Multi(RAGRI.ArenaGames[i]) != None)
			{
				if (RAGRI.ArenaGames[i].PlayerCount == 0 && EmptyArena == -1)
					EmptyArena = i;
				if (RAGRI.ArenaInfo.ArenaTeamSize[i]*3 > RAGRI.ArenaGames[i].PlayerCount && GoodArena == -1)
					GoodArena = i;
			}
		}
		if (GoodArena != -1) Game = GoodArena;
		else if (EmptyArena != -1) Game = EmptyArena;
	}

	RA.Arena = Game;

	// Send the player to spectating.
	ChangeTeam(Player, -1);
	Player.GotoState('PlayerSpectating');
	DiscardInventory(Player);
	if (Player.IsA('PlayerPawn'))
	{
		PlayerPawn(Player).EndZoom();
		// The client would only learn the new state from the next position correction
		// and walk around the spawn point until then (long on a slow first connect).
		RA.ClientSpectate();
	}

	foreach AllActors(class'ArenaViewCam', Cam)
	{
		if ((Cam.ArenaNumber == Game) && (Player.IsA('PlayerPawn')))
			RA.SetCamView(Cam);
	}

	PIter = class'RATools'.static.PlayersInArena(GameReplicationInfo, Game);
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
			if (PIter.Pawn != Player) PIter.Pawn.ClientMessage(Player.PlayerReplicationInfo.PlayerName@"has entered this arena.");
	}

	if (Level.NetMode == NM_Standalone)
	{
		if (ArenaGame_Multi(RAGRI.ArenaGames[RA.Arena]) != None)
			ArenaGame_Multi(RAGRI.ArenaGames[RA.Arena]).AddBotTeam();
		else
			for (i=0;i<7;i++)
				RAGRI.ArenaGames[RA.Arena].AddBot();
	}

	RAGRI.ArenaGames[RA.Arena].PlayerCount++;
}

function ChangeArena ( PlayerPawn Player, bool MoveForward )
{
	local RAReplicationInfo RA;
	local int NewArena;
	local int change;

	class'RATools'.static.GetRepInfo(Player, GameReplicationInfo, RA);

	NewArena = RA.Arena;
	if (MoveForward) change = 1;
	else change = -1;

	do
	{
		NewArena += change;
		if (NewArena > 7)
			NewArena = 0;
		else if (NewArena < 0)
			NewArena = 7;
	} until (RAGRI.ArenaGames[NewArena] != None);

	GotoArena( Player, NewArena );
}

// Moves a player (who may change arenas) from the current arena to NewArena.
function GotoArena ( PlayerPawn Player, int NewArena )
{
	local RAReplicationInfo RA;
	local PlayerIterator PIter;

	class'RATools'.static.GetRepInfo(Player, GameReplicationInfo, RA);
	if (RA == None || NewArena < 0 || NewArena > 7 || RAGRI.ArenaGames[NewArena] == None)
		return;

	RAGRI.ArenaGames[RA.Arena].Logout( Player, RA );

	PIter = class'RATools'.static.PlayersInArena(GameReplicationInfo, RA.Arena);
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		if (PIter.Pawn != Player) PIter.Pawn.ClientMessage(Player.PlayerReplicationInfo.PlayerName@"has left this arena.");
	}
	RAGRI.ArenaGames[RA.Arena].PlayerCount--;

	if (Level.NetMode == NM_Standalone)
	{
		if (ArenaGame_Multi(RAGRI.ArenaGames[RA.Arena]) != None)
			ArenaGame_Multi(RAGRI.ArenaGames[RA.Arena]).RemoveBotTeams();
		else
		{
			while (RAGRI.ArenaGames[RA.Arena].RemoveBot()) {}
		}
	}

	Player.Spree = 0;
	Player.PlayerReplicationInfo.Score = 0;
	Player.Health = 100;

	AddToGame( Player, NewArena );

	// Set the player's scoreboard type.
	Player.ScoringType = RAGRI.ArenaGames[NewArena].ScoringType;
}

function NextArena( PlayerPawn Player )
{
	ChangeArena( Player, true );
}

function PrevArena( PlayerPawn Player )
{
	ChangeArena( Player, false );
}

function NavigationPoint FindPlayerStart(Pawn Player, optional byte InTeam, optional string incomingName)
{
	local RAReplicationInfo RA;

	class'RATools'.static.GetRepInfo(Player, GameReplicationInfo, RA);
	if (RA == None)
		return RAGRI.ArenaGames[0].FindPlayerStart(Player, InTeam, incomingName);
	else
		return RAGRI.ArenaGames[RA.Arena].FindPlayerStart(Player, InTeam, incomingName);
}

function bool RestartPlayer( pawn aPlayer )
{
	local RAReplicationInfo RA;
	local bool bSpectate;

	class'RATools'.static.GetRepInfo(aPlayer, GameReplicationInfo, RA);
	if (RA == None)
		bSpectate = true;
	else
		bSpectate = RAGRI.ArenaGames[RA.Arena].IsSpectateOnDeath();

	if ( (aPlayer.Health <= 0) && bSpectate )
	{
		// Send player to the spectator "mode."
		if (aPlayer.IsA('PlayerPawn'))
			aPlayer.Gotostate('PlayerSpectating');

		return false;
	}

	return Super.RestartPlayer( aPlayer );
}

function Bot SpawnBot(out NavigationPoint StartSpot)
{
	local bot NewBot;
	local int BotN;
	local Pawn P;
	local class<Bot> SpawnClass;

	if ( bRatedGame )
		return SpawnRatedBot(StartSpot);

	Difficulty = BotConfig.Difficulty;

	if ( Difficulty >= 4 )
	{
		bNoviceMode = false;
		Difficulty = Difficulty - 4;
	} else {
		if ( Difficulty > 3 )
		{
			Difficulty = 3;
			bThreePlus = true;
		}
		bNoviceMode = true;
	}
	BotN = BotConfig.ChooseBotInfo();

	// Find a start spot.
	StartSpot = FindPlayerStart(None, 255);
	if( StartSpot == None )
	{
		log("RocketArenaV2: no start spot for a bot");
		return None;
	}

	switch (string(BotConfig.CHGetBotClass(BotN))) {
		case "BotPack.TMale1Bot":
			SpawnClass = class'RATMale1Bot';
			break;
		case "BotPack.TMale2Bot":
			SpawnClass = class'RATMale2Bot';
			break;
		case "BotPack.TFemale1Bot":
			SpawnClass = class'RATFemale1Bot';
			break;
		case "BotPack.TFemale2Bot":
			SpawnClass = class'RATFemale2Bot';
			break;
		case "BotPack.TBossBot":
			SpawnClass = class'RATBossBot';
			break;
	}

	// Try to spawn the bot.
	if ( SpawnClass != None )
		NewBot = Spawn(SpawnClass,,,StartSpot.Location,StartSpot.Rotation);

	if ( NewBot == None )
		log("RocketArenaV2: could not spawn a player at"@StartSpot);

	if ( NewBot != None && (bHumansOnly || Level.bHumansOnly) && !NewBot.bIsHuman )
	{
		log("RocketArenaV2: only human-like bots can be added");
		NewBot.Destroy();
		NewBot = None;
	}

	if ( NewBot == None )
		NewBot = Spawn(BotConfig.CHGetBotClass(0),,,StartSpot.Location,StartSpot.Rotation);

	if ( NewBot != None )
	{
		// Set the player's ID.
		NewBot.PlayerReplicationInfo.PlayerID = CurrentID++;

		NewBot.PlayerReplicationInfo.Team = BotConfig.GetBotTeam(BotN);
		BotConfig.CHIndividualize(NewBot, BotN, NumBots);
		NewBot.ViewRotation = StartSpot.Rotation;
		// broadcast a welcome message.
		BroadcastMessage( NewBot.PlayerReplicationInfo.PlayerName$EnteredMessage, false );

		ModifyBehaviour(NewBot);
		AddDefaultInventory( NewBot );
		NumBots++;
		if ( bRequireReady && (CountDown > 0) )
			NewBot.GotoState('Dying', 'WaitingForStart');
		NewBot.AirControl = AirControl;

		if ( (Level.NetMode != NM_Standalone) && (bNetReady || bRequireReady) )
		{
			// replicate skins
			for ( P=Level.PawnList; P!=None; P=P.NextPawn )
				if ( P.bIsPlayer && (P.PlayerReplicationInfo != None) && P.PlayerReplicationInfo.bWaitingPlayer && P.IsA('PlayerPawn') )
				{
					if ( NewBot.bIsMultiSkinned )
						PlayerPawn(P).ClientReplicateSkins(NewBot.MultiSkins[0], NewBot.MultiSkins[1], NewBot.MultiSkins[2], NewBot.MultiSkins[3]);
					else
						PlayerPawn(P).ClientReplicateSkins(NewBot.Skin);
				}
		}
	}

	// Add rocket arena specific replication info.
	if ( NewBot != None )
		SpawnRepInfo( NewBot );

	return NewBot;
}

function SpawnRepInfo( Pawn P )
{
	local RAReplicationInfo NewRepInfo;

	NewRepInfo = spawn(class'RAReplicationInfo', P);
	NewRepInfo.NextRepInfo = RAGRI.RepInfoList;
	if (RAGRI.RepInfoList != None)
		RAGRI.RepInfoList.PrevRepInfo = NewRepInfo;
	RAGRI.RepInfoList = NewRepInfo;
	NewRepInfo.OwnerPRI = P.PlayerReplicationInfo;
}

// A modified default inventory spawn that gives all the weapons to a player.
// Later, this can be used to "vote out" certain weapons or modify the
// starting equipments stats through a voting interface.
function AddDefaultInventory( pawn PlayerPawn )
{
	local RAReplicationInfo RA;

	class'RATools'.static.GetRepInfo( PlayerPawn, GameReplicationInfo, RA );
	if ((RAGRI != None) && (RA != None) && (RAGRI.ArenaGames[RA.Arena] != None))
		RAGRI.ArenaGames[RA.Arena].AddDefaultInventory( PlayerPawn );
}

function GiveWeapon(Pawn PlayerPawn, string aClassName )
{
	local class<Weapon> WeaponClass;
	local Weapon NewWeapon;

	WeaponClass = class<Weapon>(DynamicLoadObject(aClassName, class'Class'));
	if( WeaponClass == None )
		return;

	// Mutators may hand out a subclass instead (e.g. InstaGib+ weapons).
	if( class'ArenaGame'.static.FindWeapon(PlayerPawn, WeaponClass) != None )
		return;
	newWeapon = Spawn(WeaponClass);
	if( newWeapon != None )
	{
		newWeapon.bCanThrow = false;
		newWeapon.RespawnTime = 0.0;
		newWeapon.GiveTo(PlayerPawn);
		newWeapon.bHeldItem = true;
		newWeapon.GiveAmmo(PlayerPawn);
		newWeapon.SetSwitchPriority(PlayerPawn);
		newWeapon.WeaponSet(PlayerPawn);
		newWeapon.AmbientGlow = 0;
		if ( PlayerPawn.IsA('PlayerPawn') )
			newWeapon.SetHand(PlayerPawn(PlayerPawn).Handedness);
		else
			newWeapon.GotoState('Idle');
		if ( PlayerPawn.Weapon != None )
			PlayerPawn.Weapon.GotoState('DownWeapon');
		PlayerPawn.PendingWeapon = None;
		PlayerPawn.Weapon = newWeapon;
	}
}

function ResetAllWeapons()
{
	local int i;

	for (i=0; i<8; i++)
	{
		RAGRI.WeaponInfo.UseImpactHammer[i] = 1;
		RAGRI.WeaponInfo.UseEnforcer[i] = 1;
		RAGRI.WeaponInfo.UseShockRifle[i] = 1;
		RAGRI.WeaponInfo.UseBioRifle[i] = 1;
		RAGRI.WeaponInfo.UseRipper[i] = 1;
		RAGRI.WeaponInfo.UseFlakCannon[i] = 1;
		RAGRI.WeaponInfo.UseSniperRifle[i] = 1;
		RAGRI.WeaponInfo.UsePulseGun[i] = 1;
		RAGRI.WeaponInfo.UseMinigun[i] = 1;
		RAGRI.WeaponInfo.UseRocketLauncher[i] = 1;
		RAGRI.WeaponInfo.UseArmor[i] = 1;

		RAGRI.WeaponInfo.EnforcerAmmo[i] = -1;
		RAGRI.WeaponInfo.ShockRifleAmmo[i] = -1;
		RAGRI.WeaponInfo.BioRifleAmmo[i] = -1;
		RAGRI.WeaponInfo.RipperAmmo[i] = -1;
		RAGRI.WeaponInfo.FlakCannonAmmo[i] = -1;
		RAGRI.WeaponInfo.SniperRifleAmmo[i] = -1;
		RAGRI.WeaponInfo.PulseGunAmmo[i] = -1;
		RAGRI.WeaponInfo.MinigunAmmo[i] = -1;
		RAGRI.WeaponInfo.RocketLauncherAmmo[i] = -1;
		RAGRI.WeaponInfo.ArmorAmount[i] = -1;
	}
}

function ToggleWeapon(int Arena, int WeaponOffset)
{
	switch (WeaponOffset)
	{
		case 0:
			if (RAGRI.WeaponInfo.UseImpactHammer[Arena] == 1)
				RAGRI.WeaponInfo.UseImpactHammer[Arena] = 0;
			else
				RAGRI.WeaponInfo.UseImpactHammer[Arena] = 1;
			break;
		case 1:
			if (RAGRI.WeaponInfo.UseEnforcer[Arena] == 1)
				RAGRI.WeaponInfo.UseEnforcer[Arena] = 0;
			else
				RAGRI.WeaponInfo.UseEnforcer[Arena] = 1;
			break;
		case 2:
			if (RAGRI.WeaponInfo.UseShockRifle[Arena] == 1)
				RAGRI.WeaponInfo.UseShockRifle[Arena] = 0;
			else
				RAGRI.WeaponInfo.UseShockRifle[Arena] = 1;
			break;
		case 3:
			if (RAGRI.WeaponInfo.UseBioRifle[Arena] == 1)
				RAGRI.WeaponInfo.UseBioRifle[Arena] = 0;
			else
				RAGRI.WeaponInfo.UseBioRifle[Arena] = 1;
			break;
		case 4:
			if (RAGRI.WeaponInfo.UseRipper[Arena] == 1)
				RAGRI.WeaponInfo.UseRipper[Arena] = 0;
			else
				RAGRI.WeaponInfo.UseRipper[Arena] = 1;
			break;
		case 5:
			if (RAGRI.WeaponInfo.UseFlakCannon[Arena] == 1)
				RAGRI.WeaponInfo.UseFlakCannon[Arena] = 0;
			else
				RAGRI.WeaponInfo.UseFlakCannon[Arena] = 1;
			break;
		case 6:
			if (RAGRI.WeaponInfo.UseSniperRifle[Arena] == 1)
				RAGRI.WeaponInfo.UseSniperRifle[Arena] = 0;
			else
				RAGRI.WeaponInfo.UseSniperRifle[Arena] = 1;
			break;
		case 7:
			if (RAGRI.WeaponInfo.UsePulseGun[Arena] == 1)
				RAGRI.WeaponInfo.UsePulseGun[Arena] = 0;
			else
				RAGRI.WeaponInfo.UsePulseGun[Arena] = 1;
			break;
		case 8:
			if (RAGRI.WeaponInfo.UseMinigun[Arena] == 1)
				RAGRI.WeaponInfo.UseMinigun[Arena] = 0;
			else
				RAGRI.WeaponInfo.UseMinigun[Arena] = 1;
			break;
		case 9:
			if (RAGRI.WeaponInfo.UseRocketLauncher[Arena] == 1)
				RAGRI.WeaponInfo.UseRocketLauncher[Arena] = 0;
			else
				RAGRI.WeaponInfo.UseRocketLauncher[Arena] = 1;
			break;
		case 10:
			if (RAGRI.WeaponInfo.UseArmor[Arena] == 1)
				RAGRI.WeaponInfo.UseArmor[Arena] = 0;
			else
				RAGRI.WeaponInfo.UseArmor[Arena] = 1;
			break;
	}
}

function ChangeWeaponAmmo(int Arena, int WeaponOffset, int NewAmmoCount)
{
	switch (WeaponOffset)
	{
		case 0:
			break;
		case 1:
			RAGRI.WeaponInfo.EnforcerAmmo[Arena] = NewAmmoCount;
			break;
		case 2:
			RAGRI.WeaponInfo.ShockRifleAmmo[Arena] = NewAmmoCount;
			break;
		case 3:
			RAGRI.WeaponInfo.BioRifleAmmo[Arena] = NewAmmoCount;
			break;
		case 4:
			RAGRI.WeaponInfo.RipperAmmo[Arena] = NewAmmoCount;
			break;
		case 5:
			RAGRI.WeaponInfo.FlakCannonAmmo[Arena] = NewAmmoCount;
			break;
		case 6:
			RAGRI.WeaponInfo.SniperRifleAmmo[Arena] = NewAmmoCount;
			break;
		case 7:
			RAGRI.WeaponInfo.PulseGunAmmo[Arena] = NewAmmoCount;
			break;
		case 8:
			RAGRI.WeaponInfo.MinigunAmmo[Arena] = NewAmmoCount;
			break;
		case 9:
			RAGRI.WeaponInfo.RocketLauncherAmmo[Arena] = NewAmmoCount;
			break;
		case 10:
			RAGRI.WeaponInfo.ArmorAmount[Arena] = NewAmmoCount;
			break;
	}
}

function Timer()
{
	local int i;
	local PlayerIterator PIter;

	// Reset flood watch.
	SentText = 0;

	// Dispatch to all games.
	for (i=0; i<8; i++)
	{
		if (RAGRI.ArenaGames[i] != None)
		{
			RAGRI.ArenaGames[i].Timer();
			RAGRI.ArenaGames[i].PlayerCount = 0;
		}
	}

	// Wipe the injured list.
	// Not entirely accurate, but close enough.
	for (i=0; i<6; i++)
	{
		RecentDamage[i] = 0.0;
		RecentlyInjured[i] = None;
	}

	PIter = class'RATools'.static.PlayersInGame(GameReplicationInfo);
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		if (RAGRI.ArenaGames[PIter.RARepInfo.Arena] != None)
			RAGRI.ArenaGames[PIter.RARepInfo.Arena].PlayerCount++;
	}

	if ( bGameEnded )
	{
		if ( Level.TimeSeconds > EndTime + RestartWait )
			RestartGame();
	}
	else if ( TimeLimit > 0 )
	{
		RemainingTime--;
		GameReplicationInfo.RemainingTime = RemainingTime;
		if ( RemainingTime % 60 == 0 )
			GameReplicationInfo.RemainingMinute = RemainingTime;
		if ( RemainingTime <= 0 )
			EndGame("timelimit");
	} else {
		ElapsedTime++;
		GameReplicationInfo.ElapsedTime = ElapsedTime;
	}
}

function bool VerifyGame(RAReplicationInfo P1RA, RAReplicationInfo P2RA)
{
	if ((P1RA == None) || (P2RA == None))
		return true;

	if (P1RA.Arena == P2RA.Arena)
		return true;
	else
		return false;
}

function Killed(pawn Killer, pawn Other, name damageType)
{
	local RAReplicationInfo KillerRA, OtherRA;

	Super.Killed(Killer, Other, damageType);

	if ( Other.IsA('PlayerPawn') )
	{
		if ( Killer == None || ( Killer == Other && DamageType == 'Fell' ) )
			PlayerPawn(Other).ReceiveLocalizedMessage(class'EnviroKillMessage');
		else if ( Killer == Other && DamageType != 'Fell' )
			PlayerPawn(Other).ReceiveLocalizedMessage(class'SelfKillMessage');
	}

	// Make sure killer and killed are in the same game!
	class'RATools'.static.GetRepInfo(Killer, GameReplicationInfo, KillerRA);
	class'RATools'.static.GetRepInfo(Other,  GameReplicationInfo, OtherRA );
	if (!VerifyGame( KillerRA, OtherRA ))
		Log("RocketArenaV2:" @ Killer @ "killed" @ Other @ "in another arena");

	// Kill matrix: only kills of a player of the other side in the same arena.
	if (KillerRA != None && OtherRA != None && Killer != Other && KillerRA.Arena == OtherRA.Arena
		&& !(Killer.PlayerReplicationInfo.Team < 2 && Killer.PlayerReplicationInfo.Team == Other.PlayerReplicationInfo.Team))
		KillerRA.AddKill(Other.PlayerReplicationInfo);

	// Dispatch to victim's game.
	if (OtherRA != None)
		RAGRI.ArenaGames[OtherRA.Arena].Killed(Killer, Other, damageType);

	ResetViewersOf(Other);
}

// Players watching P go back to their own camera (P died or stopped playing).
function ResetViewersOf(Pawn P)
{
	local Pawn Viewer;

	for ( Viewer=Level.PawnList; Viewer!=None; Viewer=Viewer.NextPawn )
	{
		if ( PlayerPawn(Viewer) != None && PlayerPawn(Viewer).ViewTarget == P )
		{
			PlayerPawn(Viewer).ViewTarget = None;
			PlayerPawn(Viewer).bBehindView = false;
			Viewer.ClientMessage(PlayerPawn(Viewer).ViewingFrom@PlayerPawn(Viewer).OwnCamera, 'Event');
		}
	}
}

// True when a hit must do nothing at all: no damage and no momentum.
function bool DamageBlocked(Pawn Injured, Pawn InstigatedBy, name DamageType)
{
	local RAReplicationInfo InjuredRA;

	if (DamageType == 'Fell')
		return !FallingDamage;

	class'RATools'.static.GetRepInfo(Injured, GameReplicationInfo, InjuredRA);
	if (InjuredRA != None && RAGRI.ArenaGames[InjuredRA.Arena] != None)
		return !RAGRI.ArenaGames[InjuredRA.Arena].AllowDamage(Injured, InstigatedBy, DamageType);
	return false;
}

// A hit by the own weapon that DamageBlocked stopped may still push the player.
function bool SelfPushAllowed(Pawn P)
{
	local RAReplicationInfo RA;

	class'RATools'.static.GetRepInfo(P, GameReplicationInfo, RA);
	if (RA != None && RAGRI.ArenaGames[RA.Arena] != None)
		return RAGRI.ArenaGames[RA.Arena].AllowSelfPush(P);
	return true;
}

// Called by RAProjectileNotify for every projectile spawned on the server.
function bool AllowProjectile(Projectile P)
{
	local RAReplicationInfo RA;

	if (P == None || P.Instigator == None)
		return true;
	class'RATools'.static.GetRepInfo(P.Instigator, GameReplicationInfo, RA);
	if (RA != None && RAGRI.ArenaGames[RA.Arena] != None)
		return RAGRI.ArenaGames[RA.Arena].AllowNewProjectile(P);
	return true;
}

function int ReduceDamage(int Damage, name DamageType, pawn injured, pawn instigatedBy)
{
	local RAReplicationInfo InjuredRA;
	local int i;
	local bool bFoundInjured;

	if (DamageBlocked(injured, instigatedBy, DamageType))
		return 0;

	Damage = Super(DeathMatchPlus).ReduceDamage(Damage, DamageType, injured, instigatedBy);

	if ((PlayerPawn(injured) != None) && (Injured != InstigatedBy))
	{
		// Has this guy been recently injured?
		for (i=0; i<6; i++)
		{
			if (injured == RecentlyInjured[i])
			{
				// Ouch! Maybe we should taunt this guy.
				RecentDamage[i] += Damage;
				if (RecentDamage[i] > 80)
					TauntPlayer(PlayerPawn(injured), 0.15);
				bFoundInjured = True;
			}
		}

		// This guy hasn't been injured recently.
		if (!bFoundInjured)
			AddRecentInjury(PlayerPawn(injured));
	}

	// Dispatch to injured's game.
	class'RATools'.static.GetRepInfo(Injured, GameReplicationInfo, InjuredRA);
	if (InjuredRA != None)
		Damage = RAGRI.ArenaGames[InjuredRA.Arena].ReduceDamage(Damage, DamageType, Injured, InstigatedBy);

	return Damage;
}

function AddRecentInjury(PlayerPawn injured)
{
	local int i;

	for (i=0; i<5; i++)
	{
		RecentlyInjured[i] = RecentlyInjured[i+1];
		RecentDamage[i] = RecentDamage[i+1];
	}
	RecentDamage[5] = 0.0;
	RecentlyInjured[5] = injured;
}

function TauntPlayer(PlayerPawn Target, float Chance)
{
	local RAReplicationInfo RA;

	if (FRand() < Chance)
	{
		class'RATools'.static.GetRepInfo(Target, GameReplicationInfo, RA);
		if (RA != None)
			RA.PlayTaunt();
	}
}

function ResetAllRules()
{
	local int i;

	for (i=0; i<8; i++)
	{
		RAGRI.WeaponInfo.SelfDamage[i] = 0;
		RAGRI.WeaponInfo.TeamDamage[i] = 0;
	}
}

function PlayStartUpMessage(PlayerPawn NewPlayer)
{
}

//
// You may only spectate players that are alive and are in your arena.
//
function bool CanSpectate( pawn Viewer, actor ViewTarget )
{
	local RAReplicationInfo VRA, VTRA;

	if( ViewTarget.IsA('Pawn') )
	{
		if (Pawn(ViewTarget).Health <= 0)
			return false;

		class'RATools'.static.GetRepInfo(Viewer, GameReplicationInfo, VRA);
		class'RATools'.static.GetRepInfo(Pawn(ViewTarget), GameReplicationInfo, VTRA);

		if (VRA == None || VTRA == None)
			return false;

		if (VRA.Arena != VTRA.Arena)
			return false;

		if (ViewTarget.GetStateName() == 'Dying')
			return false;

		if (ViewTarget.GetStateName() == 'PlayerSpectating')
			return false;
	}

	return Super.CanSpectate( Viewer, ViewTarget );
}

function bool TooManyBots()
{
	return false;
}

// Bot AI
function ClearOrders(Pawn Leaving)
{
	local Pawn P;

	for ( P=Level.PawnList; P!=None; P=P.NextPawn )
		if ( P.IsA('Bot') && (Bot(P).OrderObject == Leaving) )
			Bot(P).SetOrders('Freelance', None);
}

function bool AddBot()
{
	// Bots are added per arena (AddBotToArena), never by the stock bot control.
	return false;
}

function AddBotToArena(int Arena)
{
	RAGRI.ArenaGames[Arena].AddBot();
}

function byte AssessBotAttitude(Bot aBot, Pawn Other)
{
	local RAReplicationInfo BotRA, OtherRA;

	class'RATools'.static.GetRepInfo(aBot, GameReplicationInfo, BotRA);
	class'RATools'.static.GetRepInfo(Other, GameReplicationInfo, OtherRA);
	if( !VerifyGame(BotRA, OtherRA) )
		return 3;
	else return RAGRI.ArenaGames[BotRA.Arena].AssessBotAttitude(aBot, Other);
}

function SetBotDifficulty(int NewDifficulty)
{
	local Class<ChallengeBotInfo> BotConfig;

	BotConfig = class'DeathMatchPlus'.default.BotConfigType;
	BotConfig.Default.Difficulty = Clamp(NewDifficulty, 0, 7);
	BotConfig.static.StaticSaveConfig();
	NewDifficulty = BotConfig.Default.Difficulty;
	RAGRI.BotSkill = NewDifficulty;

	Difficulty = NewDifficulty;
	if ( Difficulty >= 4 )
	{
		bNoviceMode = false;
		Difficulty = Difficulty - 4;
	}
	else
	{
		if ( Difficulty > 3 )
		{
			Difficulty = 3;
			bThreePlus = true;
		}
		bNoviceMode = true;
	}
}

function SetBotCount(int NumBots, int Arena)
{
	local int i;
	local PlayerIterator PIter;

	// Update the bots in the currently selected arena.
	PIter = class'RATools'.static.PlayersInArena(GameReplicationInfo, Arena);
	PIter.PlayerPawnsWanted = false;
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		PIter.Pawn.Destroy();
	}

	for (i=0; i<NumBots; i++)
		AddBotToArena(Arena);
}

function SetBotTeams(int NumTeams, int Arena)
{
	local int i, CurrentTeams;

	if (RAGRI.ArenaGames[Arena].IsA('ArenaGame_Multi'))
	{
		CurrentTeams = ArenaGame_Multi(RAGRI.ArenaGames[Arena]).CountBotTeams();
		if (CurrentTeams > NumTeams) {
			for (i=0; i<CurrentTeams-NumTeams; i++)
				ArenaGame_Multi(RAGRI.ArenaGames[Arena]).RemoveBotTeam();
		} else if (NumTeams > CurrentTeams){
			for (i=0; i<NumTeams-CurrentTeams; i++)
				ArenaGame_Multi(RAGRI.ArenaGames[Arena]).AddBotTeam();
		}
	}
}

// Admin page of the menu (V2). The values come from a client, so they are checked here.

// Which: 0 = rounds per match (1-9), 1 = self damage, 2 = team damage (0/1).
function AdminSetRule(int Arena, int Which, int Value)
{
	if (Arena < 0 || Arena >= ArrayCount(RAGRI.ArenaGames) || RAGRI.ArenaGames[Arena] == None)
		return;
	switch (Which)
	{
	case 0:
		RAGRI.WeaponInfo.RoundLimit[Arena] = Clamp(Value, 1, 9);
		break;
	case 1:
		RAGRI.WeaponInfo.SelfDamage[Arena] = Clamp(Value, 0, 1);
		break;
	case 2:
		RAGRI.WeaponInfo.TeamDamage[Arena] = Clamp(Value, 0, 1);
		break;
	default:
		return;
	}
	RAGRI.WeaponInfo.SaveSettings();
}

// Weapon 0-9 as ToggleWeapon, 10 = armor. Ammo -1 = the weapon's default amount.
function AdminSetWeapon(int Arena, int Weapon, bool bUse, int Ammo)
{
	if (Arena < 0 || Arena >= ArrayCount(RAGRI.ArenaGames) || RAGRI.ArenaGames[Arena] == None || Weapon < 0 || Weapon > 10)
		return;
	if (RAGRI.WeaponInfo.UseWeapon(Arena, Weapon) != bUse)
		ToggleWeapon(Arena, Weapon);
	ChangeWeaponAmmo(Arena, Weapon, Clamp(Ammo, -1, 999));
	RAGRI.WeaponInfo.SaveSettings();
}

function AdminResetWeapons()
{
	ResetAllWeapons();
	RAGRI.WeaponInfo.SaveSettings();
}

function AdminResetRules()
{
	ResetAllRules();
	RAGRI.WeaponInfo.SaveSettings();
}

// Which: 0 = force 1on1 (from the next map), 1 = instant rockets, 2 = falling damage,
// 3 = spectators may talk to players, 4 = rocket jump height (1-5).
function AdminSetting(int Which, float Value)
{
	switch (Which)
	{
	case 0:
		class'RocketArenaGame'.default.Force1on1 = Value != 0;
		break;
	case 1:
		class'RocketArenaGame'.default.ForceInstantRocketFire = Value != 0;
		ForceInstantRocketFire = class'RocketArenaGame'.default.ForceInstantRocketFire;
		break;
	case 2:
		class'RocketArenaGame'.default.FallingDamage = Value != 0;
		FallingDamage = class'RocketArenaGame'.default.FallingDamage;
		break;
	case 3:
		class'RocketArenaGame'.default.DisallowSpectatorSpeech = Value == 0;
		DisallowSpectatorSpeech = class'RocketArenaGame'.default.DisallowSpectatorSpeech;
		break;
	case 4:
		class'RocketArenaGame'.default.BouncyHeight = FClamp(Value, 1, 5);
		BouncyHeight = class'RocketArenaGame'.default.BouncyHeight;
		break;
	default:
		return;
	}
	// The settings are globalconfig of RocketArenaGame (the game may be a subclass).
	class'RocketArenaGame'.static.StaticSaveConfig();
	UpdateServerSettings();
}

function UpdateServerSettings()
{
	RAGRI.bForce1on1 = class'RocketArenaGame'.default.Force1on1;
	RAGRI.bInstantRockets = class'RocketArenaGame'.default.ForceInstantRocketFire;
	RAGRI.bFallingDamage = class'RocketArenaGame'.default.FallingDamage;
	RAGRI.bSpectatorSpeech = !class'RocketArenaGame'.default.DisallowSpectatorSpeech;
	RAGRI.BouncyHeight = class'RocketArenaGame'.default.BouncyHeight;
	RAGRI.BotSkill = class'DeathMatchPlus'.default.BotConfigType.default.Difficulty;
}

function bool ForceAddBot()
{
	local PlayerIterator PIter;

	PIter = class'RATools'.static.PlayersInGame(GameReplicationInfo);
	PIter.BotsWanted = false;
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		if (ArenaGame_Multi(RAGRI.ArenaGames[PIter.RARepInfo.Arena]) != None)
			ArenaGame_Multi(RAGRI.ArenaGames[PIter.RARepInfo.Arena]).AddBotTeam();
		else
			RAGRI.ArenaGames[PIter.RARepInfo.Arena].AddBot();
	}
	return true;
}

//Modify killing sprees so they are only sent to people in their arena
function NotifySpree(Pawn Other, int num)
{
	local RAReplicationInfo OwnRA;
	local PlayerIterator PIter;

	if ( num == 5 )
		num = 0;
	else if ( num == 10 )
		num = 1;
	else if ( num == 15 )
		num = 2;
	else if ( num == 20 )
		num = 3;
	else if ( num == 25 )
		num = 4;
	else
		return;

	class'RATools'.static.GetRepInfo(Other, GameReplicationInfo, OwnRA);
	if (OwnRA == None)
		return;

	PIter = class'RATools'.static.PlayersInArena(GameReplicationInfo, OwnRA.Arena);
	PIter.BotsWanted = false;
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		PIter.Pawn.ReceiveLocalizedMessage( class'KillingSpreeMessage', Num, Other.PlayerReplicationInfo );
	}

}

function EndSpree(Pawn Killer, Pawn Other)
{
	local RAReplicationInfo OwnRA;
	local PlayerIterator PIter;

	if ( !Other.bIsPlayer )
		return;

	class'RATools'.static.GetRepInfo(Other, GameReplicationInfo, OwnRA);
	if (OwnRA == None)
		return;

	PIter = class'RATools'.static.PlayersInArena(GameReplicationInfo, OwnRA.Arena);
	PIter.BotsWanted = false;
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		if ( TournamentPlayer(PIter.Pawn) == None )
			continue;
		if ( (Killer == None) || !Killer.bIsPlayer )
			TournamentPlayer(PIter.Pawn).EndSpree(None, Other.PlayerReplicationInfo);
		else
			TournamentPlayer(PIter.Pawn).EndSpree(Killer.PlayerReplicationInfo, Other.PlayerReplicationInfo);
	}
}

function PlayTeleportEffect( actor Incoming, bool bOut, bool bSound)
{
 	local UTTeleportEffect PTE;

	if ( Incoming.bIsPawn && !Incoming.bHidden && (Incoming.Mesh != None) )
	{
		if ( bSound )
		{
 			PTE = Spawn(class'UTTeleportEffect',Incoming,, Incoming.Location, Incoming.Rotation);
 			PTE.Initialize(Pawn(Incoming), bOut);
			PTE.PlaySound(sound'Resp2A',, 10.0);
		}
	}
}

function float PlaySpawnEffect(inventory Inv)
{
	return 0.0;
}

function bool SetEndCams(string Reason)
{
	local pawn P;
	local PlayerPawn Player;
	local RAReplicationInfo RA;
	local ArenaViewCam Cam;

	// check for tie

	EndTime = Level.TimeSeconds + 3.0;
	GameReplicationInfo.GameEndedComments = "";
	for ( P=Level.PawnList; P!=None; P=P.nextPawn )
	{
		if (P.bIsPlayer) {
			Player = PlayerPawn(P);
			if ( Player != None )
			{
				Player.bBehindView = false;

				// Show each player the camera of his own arena.
				class'RATools'.static.GetRepInfo(P, GameReplicationInfo, RA);
				if (RA != None)
				{
					foreach AllActors(class'ArenaViewCam', Cam)
					{
						if (Cam.ArenaNumber == RA.Arena)
							Player.ViewTarget = Cam;
					}
				}
				Player.bFixedCamera = true;
				Player.ClientGameEnded();
			}
			P.bHidden = true;
			P.GotoState('GameEnded');
		}
	}
	CalcEndStats();
	return true;
}

function string GetRules()
{
	local string ResultSet;
	ResultSet = Super.GetRules();

	ResultSet = ResultSet$"\\ra_version\\"$default.Version;
	ResultSet = ResultSet$"\\ra_force_1on1\\"$default.Force1on1;
	ResultSet = ResultSet$"\\ra_instant_rockets\\"$default.ForceInstantRocketFire;
	ResultSet = ResultSet$"\\ra_bouncy_rocket_height\\"$default.BouncyHeight;
	ResultSet = ResultSet$"\\ra_spectator_speech\\"$(!default.DisallowSpectatorSpeech);
	return ResultSet;
}

defaultproperties
{
      DefaultArenaType=Class'RocketArenaV2.ArenaGame_Multi'
      NewVoiceTheme=Class'RocketArenaV2.RAVoiceFemale'
      NewVoiceThemeName="RocketArenaV2.RAVoiceMale"
      HUDTeamDisplay=1
      Force1on1=False
      ForceInstantRocketFire=False
      DisallowSpectatorSpeech=False
      BouncyHeight=2.250000
      FallingDamage=False
      RecentlyInjured(0)=None
      RecentlyInjured(1)=None
      RecentlyInjured(2)=None
      RecentlyInjured(3)=None
      RecentlyInjured(4)=None
      RecentlyInjured(5)=None
      RecentDamage(0)=0.000000
      RecentDamage(1)=0.000000
      RecentDamage(2)=0.000000
      RecentDamage(3)=0.000000
      RecentDamage(4)=0.000000
      RecentDamage(5)=0.000000
      RAGRI=None
      PickupClasses(0)=Class'RocketArenaV2.ArenaGame_Clan'
      PickupClasses(1)=None
      PickupClasses(2)=None
      PickupClasses(3)=None
      PickupClasses(4)=None
      PickupClasses(5)=None
      PickupClasses(6)=None
      PickupClasses(7)=None
      PreferredPickupClass=Class'RocketArenaV2.ArenaGame_Clan'
      Version="1.60"
      TimeLimit=20
      WaitingMessage1=""
      WaitingMessage2=""
      NotReadyMessage=""
      DefaultPlayerClass=Class'Botpack.TMale1'
      ScoreBoardType=Class'RocketArenaV2.RAScoreboard_Multi'
      BotMenuType="RocketArenaV2.RABotSC"
      RulesMenuType="RocketArenaV2.RARulesSC"
      HUDType=Class'RocketArenaV2.RocketArenaHUD'
      MapListType=Class'RocketArenaV2.RAMapList'
      MapPrefix="RA-"
      BeaconName="RocketArena"
      GameName="Rocket Arena"
      DMMessageClass=Class'RocketArenaV2.RADeathMatchMessage'
      MutatorClass=Class'RocketArenaV2.RABaseMutator'
      GameReplicationInfoClass=Class'RocketArenaV2.RAGameReplicationInfo'
}
