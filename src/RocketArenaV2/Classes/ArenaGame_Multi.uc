/*
 * ArenaGame_Multi - A multi-arena game context
 *
 */
class ArenaGame_Multi extends ArenaGame_Clan;

var RATeamInfo		TeamList;			// List of ALL Teams.
var RATeamInfo		WaitingList[32];	// List of valid teams waiting to play.

replication
{
	// Variables the server sends to the client.
	reliable if ( Role == ROLE_Authority )
		TeamList;
}

//clientside only...
simulated function bool EnterArena(PlayerPawn Player)
{
	local int i;
	local RAReplicationInfo RepInfo;
	local RAGameReplicationInfo RAGRI;
	local ArenaInfo AI;
	local string TeamName, DefaultTeamName;

	RAGRI = RAGameReplicationInfo(Player.GameReplicationInfo);
	class'RATools'.static.GetRepInfo( Player, RAGRI, RepInfo );
	foreach Player.AllActors(class'ArenaInfo', AI)
	{
		if (RepInfo.Team == None)
		{
			i = 0;
			DefaultTeamName = Player.PlayerReplicationInfo.PlayerName$"'s Team";
			TeamName = DefaultTeamName;
			while (ArenaGame_Multi(RAGRI.ArenaGames[RepInfo.Arena]).TeamOfNameExists(TeamName))
			{
				TeamName  = DefaultTeamName@"#"$i++;
			}
			RepInfo.CreateAndQueueTeam(TeamName);
			Player.ClientPlaySound(class'RocketArenaGame'.default.NewVoiceTheme.default.Prepare,,true);
			return true;
		} else {
			if (RepInfo.Team.Size <= AI.ArenaTeamSize[RepInfo.Arena])
			{
				RepInfo.QueueTeam();
				Player.ClientPlaySound(class'RocketArenaGame'.default.NewVoiceTheme.default.Prepare,,true);
				return true;
			} else {
				Player.ClientMessage(RepInfo.Team.TeamName$" is too large to join this arena. ("$AI.ArenaTeamSize[RepInfo.Arena]$" players maximum.)");
				return false;
			}
		}
	}
}

// Move the players that will play into position.
function PrepareForMatch()
{
	local int i;

	PromoteReadyTeams();

	bBalancing = true;
	// Move all players at the top of the WaitingList to red team.
	Teams[0] = WaitingList[0];
	Teams[0].TeamIndex = 0;
	for(i=0; i<8; i++)
		if (WaitingList[0].TeamMembers[i] != None)
			SecureChangeTeam(WaitingList[0].TeamMembers[i], 0);

	// Move all players second on the WaitingList to blue team.
	Teams[1] = WaitingList[1];
	Teams[1].TeamIndex = 1;
	for(i=0; i<8; i++)
		if (WaitingList[1].TeamMembers[i] != None)
			SecureChangeTeam(WaitingList[1].TeamMembers[i], 1);
	bBalancing = false;

	Super.PrepareForMatch();
}

// A team won the match.
// Move all players to "team 255."
// Move the winner to the front of the WaitingList and move the loser to the end.
function MatchVictory( int Team )
{
	local int i, j;
	Super.MatchVictory( Team );

	// Assign victory points.
	if (WaitingList[Team] != None)
	{
		WaitingList[Team].MatchWins++;
		SaveWins(WaitingList[Team]);
	}

	bBalancing = true;
	for (i=0;i<2;i++)
	{
		if (WaitingList[i] != None)
		{
			for (j=0; j<8; j++)
			{
				if (WaitingList[i].TeamMembers[j] != None)
				{
					SecureChangeTeam(WaitingList[i].TeamMembers[j], 255);
					Game.DiscardInventory(WaitingList[i].TeamMembers[j]);
					if (WaitingList[i].TeamMembers[j].IsA('PlayerPawn'))
					{
						WaitingList[i].TeamMembers[j].GotoState('PlayerSpectating');
						PlayerPawn(WaitingList[i].TeamMembers[j]).EndZoom();
					} else if (WaitingList[i].TeamMembers[j].IsA('Bot')) {
						WaitingList[i].TeamMembers[j].GotoState('Dying', 'WaitingForStart');
					}
					Game.ResetViewersOf(WaitingList[i].TeamMembers[j]);
				}
			}
		}
	}
	bBalancing = false;

	if (Team == 0)
		MoveToBack(1); // The challenger lost.
	else
		MoveToBack(0); // The leader lost.
}

function AwardFlawless(int Team)
{
	WaitingList[Team].MatchFlawless++;
	SaveWins(WaitingList[Team]);
}

// Remembers the team's match wins with each member, for when they come back to this arena.
function SaveWins(RATeamInfo T)
{
	local RAReplicationInfo RA;
	local int i;

	for (i=0; i<8; i++)
	{
		class'RATools'.static.GetRepInfo(T.TeamMembers[i], Game.GameReplicationInfo, RA);
		if (T.TeamMembers[i] != None && RA != None)
		{
			RA.SavedWins[Arena] = T.MatchWins;
			RA.SavedFlawless[Arena] = T.MatchFlawless;
		}
	}
}

// Moves the given team to the back of the waiting list.
function MoveToBack(int Team)
{
	local RATeamInfo TempTeam;
	local int i;

	TempTeam = WaitingList[Team];
	if (Team == 0) WaitingList[0] = WaitingList[2];
	else if (Team == 1) WaitingList[1] = WaitingList[2];

	for (i=2; i<31; i++)
	{
		WaitingList[i] = WaitingList[i+1];
	}
	WaitingList[31] = None;

	for (i=0; i<32; i++)
		if (WaitingList[i] == None)
		{
			WaitingList[i] = TempTeam;
			break;
		}

	UpdateWaitingPositions();
}

// Adds a team to the waiting list.
function QueueTeam(RATeamInfo Team)
{
	local int i;

	// Comb list for this team.
	for (i=0; i<32; i++)
	{
		if (WaitingList[i] == Team)
			return;
	}

	// This team isn't there, add us to the list.
	for (i=0; i<32; i++)
	{
		if (WaitingList[i] == None)
		{
			WaitingList[i] = Team;
			break;
		}
	}

	UpdateWaitingPositions();
}

function UpdateWaitingPositions()
{
	local int i;

	for (i=0; i<32; i++)
	{
		if (WaitingList[i] != None)
			WaitingList[i].WaitingPos = i;
	}
}

// A team created on purpose (Create Team) waits until it is full.  A team made by
// Enter Arena may play short-handed, e.g. one player against a 2 player team.
function bool IsTeamReady(RATeamInfo Team)
{
	if (Team == None)
		return false;
	if (Team.bWaitForFull)
		return Team.NumMembers() >= ArenaInfo.ArenaTeamSize[Arena];
	return Team.NumMembers() > 0;
}

// Returns true if at least two waiting teams are ready to play.
function bool ValidTeamsToStart()
{
	local int TeamCount, i;

	for (i=0; i<32; i++)
	{
		if (IsTeamReady(WaitingList[i]))
			TeamCount++;
	}

	if (TeamCount > 1)
		return true;
	return false;
}

// Moves the first two ready teams to the front of the waiting list (slots 0 and 1
// are the teams that play).  Teams that are not ready keep their order and are
// first in line once they are.
function PromoteReadyTeams()
{
	local RATeamInfo NewList[32];
	local int i, n, First, Second;

	First = -1;
	Second = -1;
	for (i=0; i<32; i++)
	{
		if (IsTeamReady(WaitingList[i]))
		{
			if (First == -1)
				First = i;
			else if (Second == -1)
				Second = i;
		}
	}
	if (Second == -1)
		return;

	NewList[0] = WaitingList[First];
	NewList[1] = WaitingList[Second];
	n = 2;
	for (i=0; i<32; i++)
	{
		if (i != First && i != Second && WaitingList[i] != None)
			NewList[n++] = WaitingList[i];
	}
	for (i=0; i<32; i++)
		WaitingList[i] = NewList[i];

	UpdateWaitingPositions();
}

// The "Teams" array represents teams that are currently playing.
// As such, players in the arena are always team 255 unless they are playing.
function bool ChangeTeam(Pawn Other, int NewTeam)
{
	local RAReplicationInfo RA;

	if (NewTeam == -1)
		return Super.ChangeTeam( Other, -1 );

	// A player who goes to spectate (menu, "Spectate") also leaves the team, as when
	// leaving the server. Otherwise the team stays queued and the next round starts
	// with the player again.
	class'RATools'.static.GetRepInfo(Other, Game.GameReplicationInfo, RA);
	if (PlayerPawn(Other) != None && RA != None && RA.Team != None)
	{
		if (Other.PlayerReplicationInfo.Team < 2 && Teams[Other.PlayerReplicationInfo.Team] != None)
			Teams[Other.PlayerReplicationInfo.Team].Size--;
		LeaveTeam(Other);
	}
	return Super.ChangeTeam( Other, 255 );
}

function bool SecureChangeTeam(Pawn Other, int NewTeam)
{
	return Super.ChangeTeam( Other, NewTeam );
}

function CreateTeam( PlayerPawn Player, string TeamName, bool bWaitForFull )
{
	local RATeamInfo NewTeam;
	local RAReplicationInfo RA;

	if (!CanChangeTeams(Player))
	{
		Player.ClientMessage("You may not join or leave a team now.  You are playing!");
		return;
	}

	if (TeamOfNameExists(TeamName))
	{
		Player.ClientMessage("A team of that name already exists.");
		return;
	}

//	if (IsPlayerInTeam(Player))
	if (!CanAddPlayerToTeam(Player)) return;

	LeaveTeam(Player);

	NewTeam = spawn(class'RATeamInfo');
	NewTeam.TeamName = TeamName;
	NewTeam.bWaitForFull = bWaitForFull && ArenaInfo.ArenaTeamSize[Arena] > 1;
	class'RATools'.static.GetRepInfo(Player, Game.GameReplicationInfo, RA);
	if (RA != None)
	{
		NewTeam.MatchWins = RA.SavedWins[Arena];
		NewTeam.MatchFlawless = RA.SavedFlawless[Arena];
	}

	AddPlayerToTeam( NewTeam, Player );
	AddTeam( NewTeam );

	// If this is a standalone 2 on 2 game, spawn this guy a teammate.
	if ( (ArenaInfo.ArenaTeamSize[Arena] == 2) && (Level.NetMode == NM_Standalone) )
		AddBotsToTeam(NewTeam, 1);
}

simulated function bool TeamOfNameExists(string TeamName)
{
	local RATeamInfo Team;

	for (Team=TeamList; Team!=None; Team=Team.NextTeam)
	{
		if (Team.TeamName ~= TeamName)
			return true;
	}
	return false;
}

function bool IsPlayerInTeam( Pawn Player )
{
	local RATeamInfo Team;
	local int i;

	for (Team=TeamList; Team!=None; Team=Team.NextTeam)
	{
		for (i=0; i<8; i++)
		{
			if (Team.TeamMembers[i] == Player)
				return true;
		}
	}
	return false;
}

function LeaveTeam( Pawn Player )
{
	local RAReplicationInfo RepInfo;
	local RATeamInfo Team;
	local int i;

	class'RATools'.static.GetRepInfo(Player, Game.GameReplicationInfo, RepInfo);
	Team = RepInfo.Team;
	if (Team == None) {
		return;
	}
	for (i=0; i<8; i++)
	{
		if (PlayerPawn(Team.TeamMembers[i]) != None && Team.TeamMembers[i] != Player)
			Team.TeamMembers[i].ClientMessage(Player.PlayerReplicationInfo.PlayerName@"has left your team.");
		if (Team.TeamMembers[i] == Player)
		{
			RepInfo.Team = None;
			Team.TeamMembers[i] = None;
			Player.ClientMessage("You have been removed from"@Team.TeamName);
		}
	}
	CleanUpTeams(); // Force cleanup.
}

function AddPlayerToTeam( RATeamInfo Team, Pawn Player )
{
	local int i, j;
	local RAReplicationInfo RepInfo;

	if (Team != None && Team.bBotTeam && Bot(Player) == None)
	{
		Player.ClientMessage("That is a bot team.  You cannot join it.");
		return;
	}

	if (Team == None)
	{
		Player.ClientMessage("That team does not exist anymore.");
		return;
	}

	class'RATools'.static.GetRepInfo(Player, Game.GameReplicationInfo, RepInfo);
	if (RepInfo == None)
		return;

	//If player already is on this team
	if (RepInfo.Team == Team) {
		Player.ClientMessage("You already are on "@Team.TeamName);
		return;
	}

	if ( Team.NumMembers() >= ArenaInfo.ArenaTeamSize[Arena] )
	{
		Player.ClientMessage("That team is full.");
		return;
	}

	if (!CanAddPlayerToTeam(Player)) return;

	LeaveTeam(Player);

	for (i=0; i<8; i++)
	{
		if (Team.TeamMembers[i] == None)
		{
			// Tell the others only now that the player really is in.
			for (j=0; j<8; j++)
			{
				if (Team.TeamMembers[j] != None)
					Team.TeamMembers[j].ClientMessage(Player.PlayerReplicationInfo.PlayerName@"has joined your team.");
			}
			RepInfo.Team = Team;
			Team.TeamMembers[i] = Player;
			if (Player.IsA('PlayerPawn'))
				Player.ClientMessage("You have been added to"@Team.TeamName);
			Team.Size = Team.NumMembers();
			return;
		}
	}
	Log("RocketArenaV2: no team slot for"@Player);
}

function bool CanAddPlayerToTeam ( Pawn Player )
{
	if (IsPlayerInTeam(Player))
	{
		if (!CanChangeTeams(Player))
		{
			Player.ClientMessage("You may not join or leave a team now.  You are playing!");
			return false;
		}
	}
	return true;
}

function AddPlayerToTeamByName( string TeamName, Pawn Player )
{
	local RATeamInfo Team;

	Team = GetTeamByName( TeamName );
	AddPlayerToTeam( Team, Player );
}

simulated function RATeamInfo GetTeamByName( string TeamName )
{
	local RATeamInfo Team;

	for (Team=TeamList; Team!=None; Team=Team.NextTeam)
	{
		if (Team.TeamName ~= TeamName)
			return Team;
	}
	return None;
}

function AddTeam( RATeamInfo NewTeam )
{
	local RATeamInfo Team;

	if (TeamList == None)
	{
		TeamList = NewTeam;
		return;
	}

	for (Team=TeamList; Team!=None; Team=Team.NextTeam)
	{
		if (Team.NextTeam == None)
		{
			Team.NextTeam = NewTeam;
			NewTeam.PrevTeam = Team;
			return;
		}
	}
}

function CleanUpTeams()
{
	local RATeamInfo Team, NextTeam;
	local int i, PlayerCount, MemberCount;

	for (Team = TeamList; Team != None; Team = NextTeam)
	{
		NextTeam = Team.NextTeam;

		// The two teams in a running match stay where they are, even when a player
		// left: the match is decided first (MatchVictory needs them in slots 0 and 1).
		if (Period != PERIOD_PostMatch && (Team == Teams[0] || Team == Teams[1]))
			continue;

		MemberCount = 0;
		PlayerCount = 0;
		for (i=0; i<8; i++)
		{
			if (Team.TeamMembers[i] != None)
				MemberCount++;
			if (PlayerPawn(Team.TeamMembers[i]) != None)
				PlayerCount++;
		}

		// Teams that are not full stay in the waiting list, so a 2v2 arena can be entered
		// without a second player.

		// Remove empty teams from the master list.
		if ( MemberCount == 0 || ( PlayerCount == 0 && !Team.bBotTeam ) )
		{
			RemoveFromWaitingList(Team);
			DisbandTeam(Team);
		}
	}
}

// Removes a team from the waiting list, if it is in it.
function RemoveFromWaitingList(RATeamInfo Team)
{
	local int i;

	for (i=0; i<32; i++)
	{
		if (WaitingList[i] == Team)
		{
			RemoveWaitingTeam(i);
			return;
		}
	}
}

function RemoveWaitingTeam(int Team)
{
	local int i;

	if (Team < 0 || Team > 31 || WaitingList[Team] == None)
		return;
	WaitingList[Team].WaitingPos = -1;
	for (i=Team; i<31; i++)
	{
		WaitingList[i] = WaitingList[i+1];
	}
	WaitingList[31] = None;

	UpdateWaitingPositions();
}

function DisbandTeam(RATeamInfo Team)
{
	// Repair the team list.
	if (Team == TeamList)
		TeamList = Team.NextTeam;

	Team.Disband();
}

// Count the number of bot teams in the team list
function int CountBotTeams()
{
	local RATeamInfo Team;
	local int TeamCount;

	for (Team=TeamList; Team!=None; Team=Team.NextTeam)
	{
		if (Team.bBotTeam) TeamCount++;
	}

	return TeamCount;
}

// Remove all bot teams from the team list.
function RemoveBotTeams()
{
	local int i;
	local RATeamInfo Team;

	for (Team=TeamList; Team!=None; Team=Team.NextTeam)
	{
		if (Team.bBotTeam)
		{
			for (i=0; i<32; i++)
			{
				if (WaitingList[i] == Team)
					RemoveWaitingTeam(i);
			}
			DisbandTeam(Team);
		}
	}

	UpdateWaitingPositions();
}

// Remove one bot team from the team list.
function RemoveBotTeam()
{
	local int i;
	local RATeamInfo Team, LowestScoringTeam;

	for (Team=TeamList; Team!=None; Team=Team.NextTeam)
	{
		if (Team.bBotTeam)
		{
			if (LowestScoringTeam == None || Team.MatchWins < LowestScoringTeam.MatchWins)
				LowestScoringTeam = Team;
		}
	}
	if (LowestScoringTeam != None) {

		for (i=0; i<32; i++)
		{
			if (WaitingList[i] == LowestScoringTeam)
				RemoveWaitingTeam(i);
		}
		DisbandTeam(LowestScoringTeam);
	}

	UpdateWaitingPositions();
}

function bool NamedTeamExists (string TeamName) {
	local RATeamInfo Team;

	for (Team=TeamList; Team!=None; Team=Team.NextTeam)
	{
		if (Team.bBotTeam && Team.TeamName == TeamName) return true;
	}
	return false;
}
// Add a bot team and spawn members.
function AddBotTeam()
{
	local int i;
	local RATeamInfo NewTeam;

	NewTeam = spawn(class'RATeamInfo');
	do {
		i++;
		NewTeam.TeamName = NewTeam.BotTeamNames[Rand(8)];
		if (i > 32) NewTeam.TeamName = NewTeam.TeamName@Rand(8); //tried already :)
	} until (!NamedTeamExists(NewTeam.TeamName));

	NewTeam.bBotTeam = true;

	AddTeam( NewTeam );

	// Add the right amount of bots.
	AddBotsToTeam(NewTeam, ArenaInfo.ArenaTeamSize[Arena]);

	// Add the team to the waiting list.
	QueueTeam(NewTeam);
}

function AddBotsToTeam(RATeamInfo Team, int NumBots)
{
	local bot NewBot;
	local RAReplicationInfo RepInfo;
	local NavigationPoint StartSpot;
	local int i;

	for (i=0; i<NumBots; i++)
	{
		NewBot = Game.SpawnBot(StartSpot);
		if ( NewBot == None )
		{
			log("RocketArenaV2: failed to spawn a bot");
			return;
		}
		NewBot.CampingRate = 0;
		NewBot.Aggressiveness += 5.0;

		class'RATools'.static.GetRepInfo(NewBot, Game.GameReplicationInfo, RepInfo);
		RepInfo.Arena = Arena;

		NewBot.PlayerReplicationInfo.Team = 255;
		ChangeTeam(NewBot, 255);
		NewBot.SetOrders('Freelance', None, true);

		NewBot.bHidden = true;
		NewBot.GotoState('Dying', 'WaitingForStart');

		AddPlayerToTeam(Team, NewBot);
	}
}

function Timer()
{
	if (Game.bGameEnded) return;

	// Clean up teams.
	CleanUpTeams();

	// During a round (in the countdown nobody is in the arena).
	if (Period == PERIOD_GameTime)
		HelpDumbBots();

	Super.Timer();
}

function HelpDumbBots ()
{
	local int i,j, h;
	local int BotNum;
	//Help Bots Out - Let them know where there enemies are in these small maps

	for (i=0; i<2; i++)
	{
		for (j=0; j<Teams[i].Size ;j++)
		{
			if (Bot(RATeamInfo(Teams[i]).TeamMembers[j]) != None && Bot(RATeamInfo(Teams[i]).TeamMembers[j]).Enemy == None)
			{
				do
				{
					BotNum = Rand(8);
				} until (h++ > 32 || RATeamInfo(Teams[1-i]).TeamMembers[BotNum] != None);
				if (h < 33)
					Bot(RATeamInfo(Teams[i]).TeamMembers[j]).SetEnemy(RATeamInfo(Teams[1-i]).TeamMembers[BotNum]);
			}
		}
	}
}

function Logout(pawn Exiting, RAReplicationInfo RA)
{
	LeaveTeam( Exiting );

	if (Exiting.PlayerReplicationInfo.Team < 2)
		Teams[Exiting.PlayerReplicationInfo.Team].Size--;
}

defaultproperties
{
      TeamList=None
      WaitingList(0)=None
      WaitingList(1)=None
      WaitingList(2)=None
      WaitingList(3)=None
      WaitingList(4)=None
      WaitingList(5)=None
      WaitingList(6)=None
      WaitingList(7)=None
      WaitingList(8)=None
      WaitingList(9)=None
      WaitingList(10)=None
      WaitingList(11)=None
      WaitingList(12)=None
      WaitingList(13)=None
      WaitingList(14)=None
      WaitingList(15)=None
      WaitingList(16)=None
      WaitingList(17)=None
      WaitingList(18)=None
      WaitingList(19)=None
      WaitingList(20)=None
      WaitingList(21)=None
      WaitingList(22)=None
      WaitingList(23)=None
      WaitingList(24)=None
      WaitingList(25)=None
      WaitingList(26)=None
      WaitingList(27)=None
      WaitingList(28)=None
      WaitingList(29)=None
      WaitingList(30)=None
      WaitingList(31)=None
      GameName="Multi Arena"
      MainMenuClass=Class'RocketArenaV2.RASlideMenu_Multi'
      BotConfigClass=Class'RocketArenaV2.RABotConfigCW_Multi'
      ScoringType=Class'RocketArenaV2.RAScoreboard_Multi'
}
