class RAReplicationInfo expands ReplicationInfo;

var RAReplicationInfo		PrevRepInfo;
var RAReplicationInfo		NextRepInfo;
var PlayerReplicationInfo	OwnerPRI;

var int						Health;
var float					LastHitTime;
var int						ComboHits;
var int						ComboDamage;

var int						Arena;
var RATeamInfo				Team;

// Server side: the match wins of this player's teams per arena, so a team the player
// creates there again starts with them. Kept until the player leaves the server.
var int						SavedWins[8], SavedFlawless[8];

// Kills by this player per victim and arena, for the kill matrix in F1. Only kills of
// players of the other side count. A victim's entries go when he leaves the server.
var PlayerReplicationInfo	KillVictim[32];
var byte					KillArena[32];
var byte					KillCount[32];

// Login control.
var bool					bLoginReady;
var bool					bServerLoggedIn;	// Server side: Login() has been handled.

// Owner state tracking (see TrackOwnerState).
var name					LastOwnerState;
var bool					bOldShowScores;
var name					ServerState;		// The owner's state on the server, for the owning client.
var float					StuckSince;			// Client: since when it is Dying but the server is not.

replication
{
	// Variables the server sends to the client.
	reliable if ( Role == ROLE_Authority )
		PrevRepInfo, NextRepInfo, OwnerPRI, Health, LastHitTime, ComboHits, ComboDamage, Arena, Team, KillVictim, KillArena, KillCount;
	reliable if ( Role == ROLE_Authority && bNetOwner )
		ServerState;

	// Functions the server calls on the client.
	reliable if ( Role == ROLE_Authority )
		SetViewRotation, PopupMainMenu, PlayTaunt, ClientSpectate;

	// Functions the client calls on the server.
	reliable if ( Role < ROLE_Authority )
		NextArena, PrevArena, GotoArena, CreateTeam, AddToTeam, QueueTeam, CreateAndQueueTeam, SetBotDifficulty,
		SetBotCount, SetBotTeams, Login,
		AdminSetRule, AdminSetWeapon, AdminResetWeapons, AdminResetRules, AdminSetting;
}

function PostBeginPlay()
{
	SetTimer(0.25, true);
}

function Timer()
{
	if (Pawn(Owner) != None)
		Health = Pawn(Owner).Health;
	if (Level.TimeSeconds - LastHitTime > 1)
	{
		ComboHits = 0;
		ComboDamage = 0;
	}
}

simulated function Tick(float Delta)
{

	// If not logged in and not ready, check if ready.
	if (!bLoginReady)
	{
		// Only perform this logic on the net owner.
		if ( PlayerPawn(Owner) != None &&
			 Viewport(PlayerPawn(Owner).Player) != None &&
			 PlayerPawn(Owner).PlayerReplicationInfo != None )
		{
			if (LocalLogin())
			{
				Login();
				bLoginReady = true;
			}
		}
	}

	if (Level.NetMode == NM_Client) {
		if (OwnerPRI != None && OwnerPRI.Owner != None)
			Health = Pawn(OwnerPRI.Owner).Health;
	}

	TrackOwnerState();
	CheckArenaMenu();
}

// Another kind of arena has another menu (Clan has Join Red/Blue). The menu follows the
// replicated Arena, i.e. the arena the server has put the owner in, rather than the click,
// so fast clicks cannot leave the menu of one arena kind in another.
simulated function CheckArenaMenu()
{
	local RocketArenaHUD H;
	local RAGameReplicationInfo RAGRI;

	if (PlayerPawn(Owner) == None || Viewport(PlayerPawn(Owner).Player) == None)
		return;
	H = RocketArenaHUD(PlayerPawn(Owner).MyHUD);
	RAGRI = RAGameReplicationInfo(PlayerPawn(Owner).GameReplicationInfo);
	if (H == None || H.Manager == None || H.Manager.MainMenu == None || RAGRI == None
		|| RAGRI.ArenaGames[Arena] == None)
		return;
	if (H.Manager.MainMenu.Class != RAGRI.ArenaGames[Arena].MainMenuClass)
		H.Manager.NewArenaMenu(Arena);
}

// RA has no player class of its own (any class, e.g. the one InstaGib+ forces, must work),
// so the spectating tweaks of RA 1.60's RATournamentPlayer are applied here on state changes.
// Entering PlayerSpectating: the stock BeginState forces the scoreboard on, which hides the
// RA menu and team status, so the previous value is restored.
// Leaving PlayerSpectating: scoreboard off and the own view back. A player with a hold bind
// (showscores | onrelease showscores) keeps the scoreboard as it is: the key may be held,
// and its release toggles the scoreboard.
simulated function TrackOwnerState()
{
	local PlayerPawn P;
	local name NewState;
	local bool bLocal;

	P = PlayerPawn(Owner);
	if (P == None)
		return;
	bLocal = Viewport(P.Player) != None;
	NewState = P.GetStateName();
	if (Role == ROLE_Authority)
		ServerState = NewState;
	else if (bLocal)
		FollowServerState(P, NewState);

	if (NewState != LastOwnerState)
	{
		if (NewState == 'PlayerSpectating')
		{
			if (bLocal)
				P.bShowScores = bOldShowScores;
		}
		else if (LastOwnerState == 'PlayerSpectating')
		{
			if (bLocal && P.bShowScores && !HasHoldScoresBind(P))
				P.bShowScores = false;
			if (Role == ROLE_Authority)
			{
				P.ViewTarget = None;
				P.bBehindView = false;
			}
		}
		LastOwnerState = NewState;
	}
	bOldShowScores = P.bShowScores;
}

// Whether a key toggles the scoreboard again on release, i.e. shows it while held.
simulated function bool HasHoldScoresBind(PlayerPawn P)
{
	local int i;
	local string KeyName;

	for (i=0; i<255; i++)
	{
		KeyName = P.ConsoleCommand("KEYNAME" @ i);
		if (KeyName != "" && InStr(Caps(P.ConsoleCommand("KEYBINDING" @ KeyName)), "ONRELEASE SHOWSCORES") >= 0)
			return true;
	}
	return false;
}

// A dead client sends no position, and InstaGib+ only corrects the client's state together
// with its position. RA moves dead players on without the stock respawn (spectating between
// rounds, spawned at FIGHT), so the client would remain in Dying, unable to move or fire.
// A client still Dying half a second after the server has left that state follows the server.
simulated function FollowServerState(PlayerPawn P, name NewState)
{
	if (NewState != 'Dying' || ServerState == '' || ServerState == 'Dying')
	{
		StuckSince = 0;
		return;
	}
	if (StuckSince == 0)
		StuckSince = Level.TimeSeconds;
	else if (Level.TimeSeconds - StuckSince > 0.5)
	{
		StuckSince = 0;
		if (ServerState == P.PlayerRestartState)
		{
			// As the stock respawn; the position comes with the next correction.
			P.ClientReStart();
			P.SetPhysics(PHYS_Falling);
		}
		else
			P.GotoState(ServerState);
	}
}

simulated function bool LocalLogin()
{
	local UMenuMenuBar MenuBar;
	local bool bInstalled;
	local UWindowList I;
	local GameOnlyIdentifier RAGameIdentifier;
	local UWindowMenuBarItem MBI;

	class'RocketArenaGame'.Default.NewVoiceTheme = class<RAVoice>(DynamicLoadObject(class'RocketArenaGame'.Default.NewVoiceThemeName, class'Class'));

	if (WindowConsole(PlayerPawn(Owner).Player.Console).Root == None) return false;

	MenuBar = UMenuRootWindow(  WindowConsole(PlayerPawn(Owner).Player.Console).Root  ).MenuBar;
	for (I = MenuBar.Items; I != None; I=I.Next)
	{
		if (UWindowMenuBarItem(I).Caption == "RA: UT")
			bInstalled = true;
	}
	if (!bInstalled)
	{
		RAGameIdentifier = GameOnlyIdentifier(MenuBar.Root.CreateWindow(class'GameOnlyIdentifier', 0, 0, 1, 1));
		RAGameIdentifier.SendToBack();
		MBI = MenuBar.AddItem("RA: UT");
		MBI.CreateMenu(class'RocketArenaMenu');
		RAGameIdentifier.MenuBarItem = MBI;
	}
	return true;
}

// The server sent the owner to spectating (see RocketArenaGame.MoveToGame). Right after
// joining his PlayerReplicationInfo is often not here yet (it updates twice a second and
// can take a few seconds on a busy first connect). Waiting for it would let him walk around
// meanwhile, so the state changes at once; the stock BeginState then logs Accessed None for
// the PRI flags, which the server replicates anyway.
simulated function ClientSpectate()
{
	if (Role == ROLE_Authority)
		return;
	if (PlayerPawn(Owner) != None)
		PlayerPawn(Owner).GotoState('PlayerSpectating');
}

function Login()
{
	if (bServerLoggedIn || Pawn(Owner) == None)
		return;
	bServerLoggedIn = true;
	RocketArenaGame(Level.Game).MoveToGame( Pawn(Owner), -1 );
}

function AddKill(PlayerReplicationInfo Victim)
{
	local int i, Slot;

	Slot = -1;
	for (i=0; i<ArrayCount(KillVictim); i++)
	{
		if (KillVictim[i] == Victim && KillArena[i] == Arena)
		{
			if (KillCount[i] < 255)
				KillCount[i]++;
			return;
		}
		// A free entry, else the one with the fewest kills.
		if (Slot < 0 || (KillVictim[Slot] != None && (KillVictim[i] == None || KillCount[i] < KillCount[Slot])))
			Slot = i;
	}
	KillVictim[Slot] = Victim;
	KillArena[Slot] = Arena;
	KillCount[Slot] = 1;
}

function ForgetVictim(PlayerReplicationInfo Victim)
{
	local int i;

	for (i=0; i<ArrayCount(KillVictim); i++)
	{
		if (KillVictim[i] == Victim)
		{
			KillVictim[i] = None;
			KillCount[i] = 0;
		}
	}
}

simulated function int KillsOf(PlayerReplicationInfo Victim, int InArena)
{
	local int i;

	if (Victim == None)
		return 0;
	for (i=0; i<ArrayCount(KillVictim); i++)
		if (KillVictim[i] == Victim && KillArena[i] == InArena)
			return KillCount[i];
	return 0;
}

function RemoveThyself()
{
	RAGameReplicationInfo(Level.Game.GameReplicationInfo).RemoveRepInfo(Self);

	Destroy();
}

// Called on server by client.  Allows player to move to new arena.
// The player is always our owner: a client must not be able to move someone else.
function NextArena()
{
	local PlayerPawn Player;

	Player = PlayerPawn(Owner);
	if (Player == None)
		return;
	if (RocketArenaGame(Level.Game).CanChangeArenas(Player))
	{
		RocketArenaGame(Level.Game).LeaveTeam(Player);
		RocketArenaGame(Level.Game).NextArena(Player);
	} else
		Player.ClientMessage("You cannot leave this arena, you are playing!");
}

// Called on server by client.  Allows player to move to new arena.
function PrevArena()
{
	local PlayerPawn Player;

	Player = PlayerPawn(Owner);
	if (Player == None)
		return;
	if (RocketArenaGame(Level.Game).CanChangeArenas(Player))
	{
		RocketArenaGame(Level.Game).LeaveTeam(Player);
		RocketArenaGame(Level.Game).PrevArena(Player);
	} else
		Player.ClientMessage("You cannot leave this arena, you are playing!");
}

// Called on server by client from the arena overview: go straight to an arena.
function GotoArena(int NewArena)
{
	local PlayerPawn Player;

	Player = PlayerPawn(Owner);
	if (Player == None || NewArena == Arena)
		return;
	if (RocketArenaGame(Level.Game).CanChangeArenas(Player))
	{
		RocketArenaGame(Level.Game).LeaveTeam(Player);
		RocketArenaGame(Level.Game).GotoArena(Player, NewArena);
	} else
		Player.ClientMessage("You cannot leave this arena, you are playing!");
}

// Team names come from the client: trim them to what the menu allows.
function string CleanTeamName(string TeamName)
{
	return Left(TeamName, 30);
}

// Called on server by client from the Create Team menu.  A team created on purpose
// waits in the queue until it is full.
function CreateTeam(string TeamName)
{
	TeamName = CleanTeamName(TeamName);
	if (PlayerPawn(Owner) == None || TeamName == "")
		return;
	RocketArenaGame(Level.Game).CreateTeam(PlayerPawn(Owner), TeamName, true);
	QueueTeam();
}

// Called on server by client.  Adds the player to the team and queues the team.
function AddToTeam(string TeamName)
{
	local RAGameReplicationInfo RAGRI;

	RAGRI = RAGameReplicationInfo(Level.Game.GameReplicationInfo);
	if (Pawn(Owner) == None || ArenaGame_Multi(RAGRI.ArenaGames[Arena]) == None)
		return;
	ArenaGame_Multi(RAGRI.ArenaGames[Arena]).AddPlayerToTeamByName(CleanTeamName(TeamName), Pawn(Owner));
	QueueTeam();
}

// Called on server by client from Enter Arena when the player has no team.  This
// team may play even when it is not full (e.g. one player against a 2 player team).
function CreateAndQueueTeam(string TeamName)
{
	TeamName = CleanTeamName(TeamName);
	if (PlayerPawn(Owner) == None || TeamName == "")
		return;
	RocketArenaGame(Level.Game).CreateTeam(PlayerPawn(Owner), TeamName, false);
	QueueTeam();
}

// Called on server by client.  Adds the player's team to the ready queue.
function QueueTeam()
{
	local RAGameReplicationInfo RAGRI;

	RAGRI = RAGameReplicationInfo(Level.Game.GameReplicationInfo);
	if (Team != None && ArenaGame_Multi(RAGRI.ArenaGames[Arena]) != None)
		ArenaGame_Multi(RAGRI.ArenaGames[Arena]).QueueTeam(Team);
}

function SetCamView(ArenaViewCam Cam)
{
	PlayerPawn(Owner).ViewTarget = None;
	PlayerPawn(Owner).SetLocation(Cam.Location);
	PlayerPawn(Owner).SetRotation(Cam.Rotation);
	SetViewRotation(Cam.Rotation);
}

simulated function SetViewRotation(rotator Rot)
{
	PlayerPawn(Owner).ViewRotation = Rot;
	PlayerPawn(Owner).bShowScores = false;
}

function SetBotDifficulty(int NewDifficulty)
{
	if (Pawn(Owner).PlayerReplicationInfo.bAdmin || (Level.NetMode == NM_Standalone))
		RocketArenaGame(Level.Game).SetBotDifficulty(NewDifficulty);
}

function SetBotCount(int NumBots, int Arena)
{
	if (Pawn(Owner).PlayerReplicationInfo.bAdmin || (Level.NetMode == NM_Standalone))
		RocketArenaGame(Level.Game).SetBotCount(NumBots, Arena);
}

function SetBotTeams(int NumTeams, int Arena)
{
	if (Pawn(Owner).PlayerReplicationInfo.bAdmin || (Level.NetMode == NM_Standalone))
		RocketArenaGame(Level.Game).SetBotTeams(NumTeams, Arena);
}

function bool IsAdmin()
{
	return Pawn(Owner) != None && (Pawn(Owner).PlayerReplicationInfo.bAdmin || Level.NetMode == NM_Standalone);
}

function AdminSetRule(int Arena, int Which, int Value)
{
	if (IsAdmin())
		RocketArenaGame(Level.Game).AdminSetRule(Arena, Which, Value);
}

function AdminSetWeapon(int Arena, int Weapon, bool bUse, int Ammo)
{
	if (IsAdmin())
		RocketArenaGame(Level.Game).AdminSetWeapon(Arena, Weapon, bUse, Ammo);
}

function AdminResetWeapons()
{
	if (IsAdmin())
		RocketArenaGame(Level.Game).AdminResetWeapons();
}

function AdminResetRules()
{
	if (IsAdmin())
		RocketArenaGame(Level.Game).AdminResetRules();
}

function AdminSetting(int Which, float Value)
{
	if (IsAdmin())
		RocketArenaGame(Level.Game).AdminSetting(Which, Value);
}

simulated function PopupMainMenu(int Arena)
{
	if (Owner.IsA('PlayerPawn'))
		RocketArenaHUD(PlayerPawn(Owner).MyHUD).Manager.NewArenaMenu(Arena);
}

simulated function PlayTaunt()
{
	local int NumTaunts;

	NumTaunts = class'RocketArenaGame'.default.NewVoiceTheme.default.NumTaunts;
	PlayerPawn(Owner).ClientPlaySound(class'RocketArenaGame'.default.NewVoiceTheme.default.Taunts[Rand(NumTaunts)],,true);
}

defaultproperties
{
      PrevRepInfo=None
      NextRepInfo=None
      OwnerPRI=None
      Health=0
      LastHitTime=0.000000
      ComboHits=0
      ComboDamage=0
      Arena=0
      Team=None
      bLoginReady=False
      RemoteRole=ROLE_SimulatedProxy
      NetUpdateFrequency=10.000000
}
