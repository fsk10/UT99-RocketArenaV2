/*
 * ArenaGame - A Rocket Arena Game Context
 *
 */
class ArenaGame expands Info
	abstract
	config(RocketArenaV2);

var bool bTeamGame;

var RocketArenaGame Game;

var NavigationPoint LastStartSpot;

// Identification
var string GameName;

// Variables for multi-round games.
var int CurrentRound;
var int VictoryTeam;
var enum EPeriod
{
	PERIOD_Shakedown,
	PERIOD_PostRound,
	PERIOD_PostMatch,
	PERIOD_Victory,
	PERIOD_GameTime
} Period;
var int ShakedownTime;
var int PostRoundTime;
var int PostMatchTime;

// Internal timer.
var int Countdown;

// Team management.
var bool bCanChangeTeams;
var int NextBotTeam;
var	TeamInfo			Teams[2];
var int					MaxTeams;
var localized string	TeamColor[4];
var float FriendlyFireScale;

// Global arena value (x of 8)
var int Arena;

// Menus
var class<RASlideMenu>		MainMenuClass;
var class<RABotConfigCW>	BotConfigClass;

// Scoreboard type.
var class<ScoreBoard>		ScoringType;

var int PlayerCount;
var bool bWaitingForPlayers;	// Between matches, not enough (ready) players to start.

replication
{
	reliable if ( Role == ROLE_Authority )
		Countdown, Period, CurrentRound, PlayerCount, Teams, bWaitingForPlayers;
}

event BroadcastLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	local PlayerIterator PIter;

	PIter = class'RATools'.static.PlayersInArena(Game.GameReplicationInfo, Arena);
	PIter.BotsWanted = false;
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
			PIter.Pawn.ReceiveLocalizedMessage( Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
	}
}

// ArenaGame interface.
function InitTeams();
function bool IsSpectateOnDeath();
function bool SafeToMove( Pawn Player );
function CreateTeam( PlayerPawn Player, string TeamName, bool bWaitForFull );
function LeaveTeam( Pawn Player );
function bool CanChangeArenas( Pawn Player );
simulated function bool EnterArena(PlayerPawn Player);

// GameInfo interface.
function InitGame();
function Killed(pawn Killer, pawn Other, name damageType);
function int ReduceDamage(int Damage, name DamageType, pawn injured, pawn instigatedBy);

// False when this arena must not let the hit do anything: no damage and no momentum.
function bool AllowDamage(Pawn Injured, Pawn InstigatedBy, name DamageType)
{
	return true;
}

// False when the own weapon must not push the player either while damage is off.
function bool AllowSelfPush(Pawn P)
{
	return true;
}

// False when a projectile spawned now must be removed before it can hit anything.
function bool AllowNewProjectile(Projectile P)
{
	return true;
}

// Weapons can be replaced by subclasses (e.g. InstaGib+), so look them up by class tree.
static function Weapon FindWeapon(Pawn P, class<Weapon> WeaponClass)
{
	local Inventory Inv;

	for (Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
		if (Weapon(Inv) != None && ClassIsChildOf(Inv.Class, WeaponClass))
			return Weapon(Inv);
	return None;
}

// Overrides the ammo of a weapon in the loadout.  -1 keeps the default.
function SetWeaponAmmo(Pawn P, class<Weapon> WeaponClass, int Amount)
{
	local Weapon Weap;

	if (Amount < 0)
		return;
	Weap = FindWeapon(P, WeaponClass);
	if (Weap == None || Weap.AmmoType == None)
		return;
	Weap.AmmoType.AmmoAmount = Amount;
	Weap.AmmoType.MaxAmmo = Amount;
}

// Refills every weapon to its loadout amount.
function RefillAmmo(Pawn P)
{
	local Inventory Inv;

	for (Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
		if (Weapon(Inv) != None && Weapon(Inv).AmmoType != None)
			Weapon(Inv).AmmoType.AmmoAmount = Weapon(Inv).AmmoType.MaxAmmo;
}

function AddDefaultInventory( pawn PlayerPawn )
{
	local Weapon Weap;
	local Bot B;
	local inventory Inv;
	local float F;
	local RAGameReplicationInfo RAGRI;
	local class<Weapon> WeapClass;

	Game.DiscardInventory(PlayerPawn);

	if ( PlayerPawn.IsA('Spectator') || PlayerPawn.PlayerReplicationInfo.bIsSpectator )
		return;

	RAGRI = RAGameReplicationInfo(Game.GameReplicationInfo);

	PlayerPawn.JumpZ = PlayerPawn.Default.JumpZ * Game.PlayerJumpZScaling();

	// A mutator's own default weapon (e.g. an instagib rifle).  A replaced impact
	// hammer is not one: the hammer follows the UseImpactHammer setting below.
	WeapClass = Level.Game.BaseMutator.MutatedDefaultWeapon();
	if ( WeapClass != None && WeapClass != Level.Game.DefaultWeapon && !ClassIsChildOf(WeapClass, class'ImpactHammer') )
		Game.GiveWeapon(PlayerPawn, string(WeapClass));

	// Give the basic weapon loadout.
	if (RAGRI.WeaponInfo.UseImpactHammer[Arena] == 1)
		Game.GiveWeapon(PlayerPawn, "Botpack.ImpactHammer");

	if (RAGRI.WeaponInfo.UseEnforcer[Arena] == 1)
		Game.GiveWeapon(PlayerPawn, "Botpack.Enforcer");

	if (RAGRI.WeaponInfo.UseShockRifle[Arena] == 1)
		Game.GiveWeapon(PlayerPawn, "Botpack.ShockRifle");

	if (RAGRI.WeaponInfo.UseBioRifle[Arena] == 1)
		Game.GiveWeapon(PlayerPawn, "Botpack.UT_BioRifle");

	if (RAGRI.WeaponInfo.UseRipper[Arena] == 1)
		Game.GiveWeapon(PlayerPawn, "Botpack.Ripper");

	if (RAGRI.WeaponInfo.UseFlakCannon[Arena] == 1)
		Game.GiveWeapon(PlayerPawn, "Botpack.UT_FlakCannon");

	if ( PlayerPawn.IsA('PlayerPawn') )
	{
		if (RAGRI.WeaponInfo.UseSniperRifle[Arena] == 1)
			Game.GiveWeapon(PlayerPawn, "Botpack.SniperRifle");

		if (RAGRI.WeaponInfo.UsePulseGun[Arena] == 1)
			Game.GiveWeapon(PlayerPawn, "Botpack.PulseGun");

		if (RAGRI.WeaponInfo.UseMinigun[Arena] == 1)
			Game.GiveWeapon(PlayerPawn, "Botpack.Minigun2");

		if (RAGRI.WeaponInfo.UseRocketLauncher[Arena] == 1)
			Game.GiveWeapon(PlayerPawn, "Botpack.UT_Eightball");

		PlayerPawn.SwitchToBestWeapon();
	} else {
		// Randomize order for bots so they don't always use the same weapon.
		F = FRand();
		if ( F < 0.7 )
		{
			if (RAGRI.WeaponInfo.UseSniperRifle[Arena] == 1)
				Game.GiveWeapon(PlayerPawn, "Botpack.SniperRifle");

			if (RAGRI.WeaponInfo.UsePulseGun[Arena] == 1)
				Game.GiveWeapon(PlayerPawn, "Botpack.PulseGun");

			if ( F < 0.4 )
			{
				if (RAGRI.WeaponInfo.UseMinigun[Arena] == 1)
					Game.GiveWeapon(PlayerPawn, "Botpack.Minigun2");

				if (RAGRI.WeaponInfo.UseRocketLauncher[Arena] == 1)
					Game.GiveWeapon(PlayerPawn, "Botpack.UT_Eightball");
			} else {
				if (RAGRI.WeaponInfo.UseRocketLauncher[Arena] == 1)
					Game.GiveWeapon(PlayerPawn, "Botpack.UT_Eightball");

				if (RAGRI.WeaponInfo.UseMinigun[Arena] == 1)
					Game.GiveWeapon(PlayerPawn, "Botpack.Minigun2");
			}
		} else {
			if (RAGRI.WeaponInfo.UseMinigun[Arena] == 1)
				Game.GiveWeapon(PlayerPawn, "Botpack.Minigun2");

			if (RAGRI.WeaponInfo.UseRocketLauncher[Arena] == 1)
				Game.GiveWeapon(PlayerPawn, "Botpack.UT_Eightball");

			if ( F < 0.88 )
			{
				if (RAGRI.WeaponInfo.UseSniperRifle[Arena] == 1)
					Game.GiveWeapon(PlayerPawn, "Botpack.SniperRifle");

				if (RAGRI.WeaponInfo.UsePulseGun[Arena] == 1)
					Game.GiveWeapon(PlayerPawn, "Botpack.PulseGun");
			} else {
				if (RAGRI.WeaponInfo.UsePulseGun[Arena] == 1)
					Game.GiveWeapon(PlayerPawn, "Botpack.PulseGun");

				if (RAGRI.WeaponInfo.UseSniperRifle[Arena] == 1)
					Game.GiveWeapon(PlayerPawn, "Botpack.SniperRifle");
			}
		}
	}

	B = Bot(PlayerPawn);
	if ( B != None )
		B.bHasImpactHammer = (FindWeapon(B, class'ImpactHammer') != None);

	// Give the player full ammo.
	for ( inv=PlayerPawn.inventory; inv!=None; inv=inv.inventory )
	{
		weap = Weapon(inv);
		if ( (weap != None) && (weap.AmmoType != None) )
			weap.AmmoType.AmmoAmount = weap.AmmoType.MaxAmmo;
	}

	// Give armor to the player.
	if (RAGRI.WeaponInfo.UseArmor[Arena] == 1)
	{
		inv = Spawn(class'RAArmor');
		if( inv != None )
		{
			inv.bHeldItem = true;
			inv.RespawnTime = 0.0;
			inv.GiveTo(PlayerPawn);
			inv.Charge = Inv.Default.Charge;
			if (RAGRI.WeaponInfo.ArmorAmount[Arena] > -1)
				inv.Charge = RAGRI.WeaponInfo.ArmorAmount[Arena];
		}
	}

	// Tweak ammo amounts.
	SetWeaponAmmo(PlayerPawn, class'Enforcer', RAGRI.WeaponInfo.EnforcerAmmo[Arena]);
	SetWeaponAmmo(PlayerPawn, class'ShockRifle', RAGRI.WeaponInfo.ShockRifleAmmo[Arena]);
	SetWeaponAmmo(PlayerPawn, class'UT_BioRifle', RAGRI.WeaponInfo.BioRifleAmmo[Arena]);
	SetWeaponAmmo(PlayerPawn, class'Ripper', RAGRI.WeaponInfo.RipperAmmo[Arena]);
	SetWeaponAmmo(PlayerPawn, class'UT_FlakCannon', RAGRI.WeaponInfo.FlakCannonAmmo[Arena]);
	SetWeaponAmmo(PlayerPawn, class'SniperRifle', RAGRI.WeaponInfo.SniperRifleAmmo[Arena]);
	SetWeaponAmmo(PlayerPawn, class'PulseGun', RAGRI.WeaponInfo.PulseGunAmmo[Arena]);
	SetWeaponAmmo(PlayerPawn, class'Minigun2', RAGRI.WeaponInfo.MinigunAmmo[Arena]);
	SetWeaponAmmo(PlayerPawn, class'UT_Eightball', RAGRI.WeaponInfo.RocketLauncherAmmo[Arena]);

	if ((TournamentPlayer(PlayerPawn) != None) && Game.ForceInstantRocketFire)
		TournamentPlayer(PlayerPawn).bInstantRocket = true;
}

function bool ChangeTeam(Pawn Other, int NewTeam)
{
	Other.PlayerReplicationInfo.Team = NewTeam;
	return true;
}

function NavigationPoint FindPlayerStart(Pawn Player, optional byte InTeam, optional string incomingName)
{
	local PlayerStart Dest, Candidate[16], Best;
	local float Score[16], BestScore, NextDist;
	local pawn OtherPlayer;
	local int i, num;
	local Teleporter Tel;
	local NavigationPoint N, LastPlayerStartSpot;

	if ( Game.bStartMatch && (Player != None) && Player.IsA('TournamentPlayer')
		&& (Level.NetMode == NM_Standalone)
		&& (TournamentPlayer(Player).StartSpot != None) )
		return TournamentPlayer(Player).StartSpot;

	if( incomingName!="" )
		foreach AllActors( class 'Teleporter', Tel )
			if( string(Tel.Tag)~=incomingName )
				return Tel;

	// Choose candidates, ensure they are in this arena.
	for ( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
	{
		Dest = PlayerStart(N);
		if ( (ArenaPlayerStart(Dest) != None) && Dest.bEnabled && !Dest.Region.Zone.bWaterZone && (ArenaPlayerStart(Dest).ArenaNumber == Arena) )
		{
			if (num<16)
				Candidate[num] = Dest;
			else if (Rand(num) < 16)
				Candidate[Rand(16)] = Dest;
			num++;
		}
	}

	if ( num == 0 )
		foreach AllActors( class'PlayerStart', Dest )
		{
			if ( (ArenaPlayerStart(Dest) != None) && (ArenaPlayerStart(Dest).ArenaNumber == Arena) )
			{
				if (num<16)
					Candidate[num] = Dest;
				else if (Rand(num) < 16)
					Candidate[Rand(16)] = Dest;
				num++;
			}
		}
	// Still none found? Use regular PlayerStarts!
	if ( num == 0 )
		foreach AllActors( class'PlayerStart', Dest )
		{
			if ( ArenaPlayerStart(Dest) == None )
			{
				if (num<16)
					Candidate[num] = Dest;
				else if (Rand(num) < 16)
					Candidate[Rand(16)] = Dest;
				num++;
			}
		}

	if (num>16) num = 16;
	else if (num == 0)
		return None;

	if ( (Player != None) && Player.IsA('TournamentPlayer')
		&& (TournamentPlayer(Player).StartSpot != None) )
		LastPlayerStartSpot = TournamentPlayer(Player).StartSpot;

	// Assess candidates.
	for (i=0;i<num;i++)
	{
		if ( (Candidate[i] == LastStartSpot) || (Candidate[i] == LastPlayerStartSpot) )
			Score[i] = -10000.0;
		else
			Score[i] = 3000 * FRand(); //randomize
	}
	for ( OtherPlayer=Level.PawnList; OtherPlayer!=None; OtherPlayer=OtherPlayer.NextPawn)
		if ( OtherPlayer.bIsPlayer && (OtherPlayer.Health > 0) && !OtherPlayer.IsA('Spectator') )
			for ( i=0; i<num; i++ )
			{
				if ( OtherPlayer.Region.Zone == Candidate[i].Region.Zone )
				{
					Score[i] -= 1500;
					NextDist = VSize(OtherPlayer.Location - Candidate[i].Location);
					if ( NextDist < OtherPlayer.CollisionRadius + OtherPlayer.CollisionHeight )
						Score[i] -= 1000000.0;
					else if ( (NextDist < 2000) && FastTrace(Candidate[i].Location, OtherPlayer.Location) )
						Score[i] -= (10000.0 - NextDist);
				}
				else if ( Game.NumPlayers + Game.NumBots == 2 )
				{
					Score[i] += 2 * VSize(OtherPlayer.Location - Candidate[i].Location);
					if ( FastTrace(Candidate[i].Location, OtherPlayer.Location) )
						Score[i] -= 10000;
				}
			}

	BestScore = Score[0];
	Best = Candidate[0];
	if (num > 1)
	{
		for (i=1;i<num;i++)
			if (Score[i] > BestScore)
			{
				BestScore = Score[i];
				Best = Candidate[i];
			}
	}

	LastStartSpot = Best;
	return Best;
}

function bool RemoveBot()
{
	local Bot LowestScoringBot;
	local Pawn P;

	for (P=Level.PawnList; P != NOne; P = P.NextPawn)
	{
		if (Bot(P) != None)
			if (LowestScoringBot == None || P.PlayerReplicationInfo.Score < LowestScoringBot.PlayerReplicationInfo.Score)
				LowestScoringBot = Bot(P);
	}
	if (LowestScoringBot != None) {
		LowestScoringBot.Destroy();
		return true;
	}
	return false;
}

function bool AddBot()
{
	local bot NewBot;
	local NavigationPoint StartSpot;
	local int DesiredTeam, i, MinSize;
	local RAReplicationInfo RepInfo;

	NewBot = Game.SpawnBot(StartSpot);
	if ( NewBot == None )
	{
		log("RocketArenaV2: failed to spawn a bot");
		return false;
	}

	// Set the bot's arena to the current one.
	class'RATools'.static.GetRepInfo(NewBot, Game.GameReplicationInfo, RepInfo);
	RepInfo.Arena = Arena;

	MinSize = Teams[0].Size;
	DesiredTeam = 0;
	for ( i=1; i<MaxTeams; i++ )
		if ( Teams[i].Size < MinSize )
		{
			MinSize = Teams[i].Size;
			DesiredTeam = i;
		}
	NewBot.PlayerReplicationInfo.Team = 255;
	if ( (DesiredTeam == 255) || !ChangeTeam(NewBot, DesiredTeam) )
	{
		ChangeTeam(NewBot, NextBotTeam);
		NextBotTeam++;
		if ( NextBotTeam >= MaxTeams )
			NextBotTeam = 0;
	}

	StartSpot.PlayTeleportEffect(NewBot, true);

	NewBot.SetOrders('Freelance', None, true);

	return true;
}

function byte AssessBotAttitude(Bot aBot, Pawn Other)
{
	return 1;
}

function Logout(pawn Exiting, RAReplicationInfo RA);

defaultproperties
{
      bTeamGame=False
      Game=None
      LastStartSpot=None
      GameName=""
      CurrentRound=0
      VictoryTeam=0
      Period=PERIOD_Shakedown
      ShakedownTime=5
      PostRoundTime=3
      PostMatchTime=5
      CountDown=0
      bCanChangeTeams=False
      NextBotTeam=0
      Teams(0)=None
      Teams(1)=None
      MaxTeams=2
      TeamColor(0)="Red"
      TeamColor(1)="Blue"
      TeamColor(2)="Green"
      TeamColor(3)="Gold"
      FriendlyFireScale=0.000000
      Arena=0
      MainMenuClass=None
      BotConfigClass=None
      ScoringType=None
      PlayerCount=0
      bAlwaysRelevant=True
      RemoteRole=ROLE_SimulatedProxy
}
