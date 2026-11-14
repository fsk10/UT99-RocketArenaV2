/*
 * ArenaGame_Clan - A pickup match context.
 *
 */
class ArenaGame_Clan extends ArenaGame;

var	bool				bBalancing;
var ArenaInfo			ArenaInfo;
var int					PerfectTimer, PerfectType;
var int					PerfectCount[2];
var float				RoundStartTime;		// Level.TimeSeconds when the last round started (FIGHT).

simulated function bool EnterArena(PlayerPawn Player)
{
	local RAGameReplicationInfo RAGRI;
	local RAReplicationInfo RA;
	RAGRI = RAGameReplicationInfo(Player.GameReplicationInfo);
	class'RATools'.static.GetRepInfo(Player, RAGRI, RA);

	if (RAGRI.ArenaGames[RA.Arena].Teams[0].Size > RAGRI.ArenaGames[RA.Arena].Teams[1].Size)
		Player.ChangeTeam(1);
	else
		Player.ChangeTeam(0);
	return true;
}

function InitGame()
{
	local ArenaInfo AI;

	CurrentRound = 1;
	Period = PERIOD_PostMatch;
	Countdown = PostMatchTime;

	foreach AllActors(class'ArenaInfo', AI)
	{
		ArenaInfo = AI;
	}

	PerfectTimer = -1;
}

function InitTeams()
{
	local int i;

	for (i=0;i<2;i++)
	{
		Teams[i] = Spawn(class'TeamInfo');
		Teams[i].Size = 0;
		Teams[i].Score = 0;
		Teams[i].TeamName = TeamColor[i];
		Teams[i].TeamIndex = i;
		TournamentGameReplicationInfo(Game.GameReplicationInfo).Teams[i] = Teams[i];
	}
}

function bool ChangeTeam(Pawn Other, int NewTeam)
{
	local int i, s;
	local teaminfo SmallestTeam;

	Other.Health = 0;

	if (NewTeam == -1 )
	{
		// Special for players that are totally new.
		AddToTeam( 255, Other );
		return true;
	}

	if (!CanChangeTeams(Other))
	{
		if (Other.IsA('PlayerPawn'))
			PlayerPawn(Other).ClientMessage("You cannot change teams while a game is in progress.");
		return false;
	}

	if (NewTeam == 255)
	{
		AddToTeam( NewTeam, Other );
		return true;
	}

	if (NewTeam > 1)
		NewTeam -= 2;

	for( i=0; i<MaxTeams; i++ )
		if ( (SmallestTeam == None)
			|| (SmallestTeam.Size > Teams[i].Size) )
		{
			s = i;
			SmallestTeam = Teams[i];
		}

	if ( NewTeam >= MaxTeams )
		NewTeam = s;

	if ( Other.IsA('Spectator') )
	{
		Other.PlayerReplicationInfo.Team = 255;
		return true;
	}

	if ( Other.IsA('TournamentPlayer') )
		TournamentPlayer(Other).StartSpot = None;

	if ( Other.PlayerReplicationInfo.Team != 255 )
	{
		Game.ClearOrders(Other);
		Teams[Other.PlayerReplicationInfo.Team].Size--;
	}

	if ( Teams[NewTeam].Size < 16 )
	{
		AddToTeam(NewTeam, Other);
		return true;
	}

	if ( (Other.PlayerReplicationInfo.Team == 255)
		|| ((SmallestTeam != None) && (SmallestTeam.Size < 16)) )
	{
		if ( s == 255 )
			s = 0;
		AddToTeam(s, Other);
		return true;
	}

	return false;
}

function bool CanChangeTeams(pawn Other)
{
	return true;
}

function bool CanChangeArenas( Pawn Player )
{
	return true;
}

function AddToTeam( int num, Pawn Other )
{
	local Pawn P;
	local TeamInfo aTeam;
	local bool bSuccess;
	local string SkinName, FaceName;
	local PlayerIterator PIter;

	if (num == 255)
	{
		if ( Other.CarriedDecoration != None )
			Other.DropDecoration();
		Game.DiscardInventory(Other);
		Other.PlayerReplicationInfo.Team = num;
		Other.static.GetMultiSkin(Other, SkinName, FaceName);
		Other.static.SetMultiSkin(Other, SkinName, FaceName, num);
		if (Other.IsA('PlayerPawn'))
			PlayerPawn(Other).GotoState('PlayerSpectating');
		Other.PlayerReplicationInfo.bWaitingPlayer = false;

		// Correct team sizes.
		Teams[0].Size = 0;
		Teams[1].Size = 0;
		PIter = class'RATools'.static.PlayersInArena(Game.GameReplicationInfo, Arena);
		PIter.Init();
		for(PIter=PIter;PIter.RARepInfo != None;PIter.Next())
		{
			if (PIter.PRI.Team < 2) Teams[PIter.PRI.Team].Size++;
		}

		// Rebalance teams.
		Rebalance();
		return;
	}

	if ( Other == None )
		return;

	aTeam = Teams[num];

	aTeam.Size++;
	Other.PlayerReplicationInfo.Team = num;
	Other.PlayerReplicationInfo.TeamName = aTeam.TeamName;
	bSuccess = false;
	if ( Other.IsA('PlayerPawn') )
	{
		Other.PlayerReplicationInfo.TeamID = 0;
		PlayerPawn(Other).ClientChangeTeam(Other.PlayerReplicationInfo.Team);
	}
	else
		Other.PlayerReplicationInfo.TeamID = 1;

	while ( !bSuccess )
	{
		bSuccess = true;
		for ( P=Level.PawnList; P!=None; P=P.nextPawn )
            if ( P.bIsPlayer && (P != Other)
				&& (P.PlayerReplicationInfo.Team == Other.PlayerReplicationInfo.Team)
				&& (P.PlayerReplicationInfo.TeamId == Other.PlayerReplicationInfo.TeamId) )
				bSuccess = false;
		if ( !bSuccess )
			Other.PlayerReplicationInfo.TeamID++;
	}

	Other.static.GetMultiSkin(Other, SkinName, FaceName);
	Other.static.SetMultiSkin(Other, SkinName, FaceName, num);

	Rebalance();
}

function Rebalance()
{
	local int big, small, i, bigsize, smallsize;
	local Pawn P, A;
	local Bot B;

	if ( bBalancing || (Game.NumBots == 0) )
		return;

	big = 0;
	small = 0;
	bigsize = Teams[0].Size;
	smallsize = Teams[0].Size;
	for ( i=1; i<MaxTeams; i++ )
	{
		if ( Teams[i].Size > bigsize )
		{
			big = i;
			bigsize = Teams[i].Size;
		}
		else if ( Teams[i].Size < smallsize )
		{
			small = i;
			smallsize = Teams[i].Size;
		}
	}

	bBalancing = true;
	while ( bigsize - smallsize > 1 )
	{
		for ( P=Level.PawnList; P!=None; P=P.NextPawn )
			if ( P.bIsPlayer && (P.PlayerReplicationInfo.Team == big)
				&& P.IsA('Bot') )
			{
				B = Bot(P);
				break;
			}
		if ( B != None )
		{
			B.Health = 0;
			B.Died( None, 'Suicided', B.Location );
			bigsize--;
			smallsize++;
			ChangeTeam(B, small);
			B.Health = 100;
			B.RestartPlayer();
		}
		else
			Break;
	}
	bBalancing = false;

	// re-assign orders to follower bots with no leaders
	for ( P=Level.PawnList; P!=None; P=P.NextPawn )
		if ( P.bIsPlayer && P.IsA('Bot') && (BotReplicationInfo(P.PlayerReplicationInfo).RealOrders == 'Follow') )
		{
			A = Pawn(Bot(P).OrderObject);
			if ( (A == None) || A.bDeleteMe || !A.bIsPlayer || (A.PlayerReplicationInfo.Team != P.PlayerReplicationInfo.Team) )
			{
				Bot(P).OrderObject = None;
				Bot(P).SetOrders('Freelance', None, true);
			}
		}

}

function Timer()
{
	local int WinningTeam;

	if (Game.bGameEnded) return;

	// Perfect / flawless announcement, two seconds after the round was won.
	if (PerfectTimer > 1)
	{
		PerfectTimer--;
	} else if (PerfectTimer == 1) {
		PerfectTimer = -1;
		BroadcastLocalizedMessage(class'PerfectMessage', PerfectType);
	}

	// If there are not enough people to play a game, don't
	// count down the timer.  If people leave during the middle
	// of a game and there aren't enough players award a match
	// victory to the remaining team.
	bWaitingForPlayers = false;
	if (Period == PERIOD_PostMatch)
	{
		if (!ValidTeamsToStart())
		{
			// Reset the countdown.
			Countdown = PostMatchTime;
			bWaitingForPlayers = true;
			return;
		} //else we want to start a match

	} else { //else were in the middle of a match or game, and need to adjust

		if (!ValidTeamsForMatch(WinningTeam)) //retrieve WinningTeam
		{
			// Reward match to remaining team.
			VictoryTeam = WinningTeam;
			MatchVictory(WinningTeam);
			return;
		}

		//if we're in play, and suddenly an entire team is dead, via validteamsforround(), end it
		if (CountDown == -1 && !ValidTeamsForRound(WinningTeam)) //retrieve victoryteam
		{
			VictoryTeam = WinningTeam;
			// Reward match to remaining team.
			Period = PERIOD_Victory;
			Countdown = 3;
			return;
		}
	}

	// Decrement the appropriate counter depending on the current game period.
	if (Countdown > 1) {
		Countdown--;
		if ((Period == PERIOD_Shakedown) && (Countdown < 4))
		{
			BroadcastLocalizedMessage(class'CountdownMessage', Countdown);
		}
	} else if (Countdown == 1) {
		Countdown = -1;
		if (Period == PERIOD_PostMatch)
		{
			// Time is up.  Start the next match.
			PrepareForMatch();
			StartMatch();
		} else if (Period == PERIOD_PostRound) {
			RestartRound();
		} else if (Period == PERIOD_Shakedown) {
			BroadcastLocalizedMessage(class'CountdownMessage', 0);
			StartRound();
		} else if (Period == PERIOD_Victory) {
			TeamVictory(VictoryTeam);
		}
	}
}

function PrepareForMatch()
{
	local PlayerIterator PIter;

	PIter = class'RATools'.static.PlayersInArena(Game.GameReplicationInfo, Arena);
	PIter.SpectatorsWanted = false;
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		if (!PIter.PRI.bIsABot)
		{
			// Setup players for restart.
			PIter.Pawn.Health = 100;
			PlayerPawn(PIter.Pawn).ViewTarget = None;
			PlayerPawn(PIter.Pawn).bBehindView = False;
			PIter.Pawn.PlayerRestartState = PIter.Pawn.Default.PlayerRestartState;
			PIter.Pawn.GotoState(PIter.Pawn.Default.PlayerRestartState);
		} else {
			// Setup bots for restart.
			PIter.Pawn.Health = 100;
			PIter.Pawn.GotoState('Dying', 'WaitingForStart');
		}
	}

}

// Returns true if there are enough players to run a game.
function bool ValidTeamsToStart()
{
	local int TeamCounts[2];
	local PlayerIterator PIter;

	if (Level.Netmode == NM_Standalone)
	{
		//check to make sure the playerpawn is on a team if we're in a standalone game
		PIter = class'RATools'.static.PlayersInArena(Game.GameReplicationInfo, Arena);
		PIter.SpectatorsWanted = false;
		PIter.BotsWanted = false;
		PIter.Init();
		for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
		{
			TeamCounts[PIter.PRI.Team]++;
		}
		if ((TeamCounts[0] == 0) && (TeamCounts[1] == 0))
			return false;
	}
	PIter = class'RATools'.static.PlayersInArena(Game.GameReplicationInfo, Arena);
	PIter.SpectatorsWanted = false;
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		TeamCounts[PIter.PRI.Team]++;
	}
	if ((TeamCounts[0] > 0) && (TeamCounts[1] > 0))
		return true;
	else
		return false;
}

function bool ValidTeamsForMatch(out int WinningTeam)
{
	local int TeamCounts[2];
	local PlayerIterator PIter;

	if (Period == PERIOD_PostMatch)
		return true;

	PIter = class'RATools'.static.PlayersInArena(Game.GameReplicationInfo, Arena);
	PIter.SpectatorsWanted = false;
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		TeamCounts[PIter.PRI.Team]++;
	}

	WinningTeam = -1;
	if ((TeamCounts[0] > 0) && (TeamCounts[1] > 0))
		return true;
	else
	{
		if (TeamCounts[0] == 0) WinningTeam = 1;
		else if (TeamCounts[1] == 0) WinningTeam = 0;
		return false;
	}
}

function bool ValidTeamsForRound (out int WinningTeam)
{
	local int TeamAliveCounts[2];
	local PlayerIterator PIter;

	PIter = class'RATools'.static.PlayersInArena(Game.GameReplicationInfo, Arena);
	PIter.SpectatorsWanted = false;
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		if (PIter.Pawn.Health > 0) TeamAliveCounts[PIter.PRI.Team]++;
	}

	WinningTeam = -1;
	if ((TeamAliveCounts[0] > 0) && (TeamAliveCounts[1] > 0))
		return true;
	else
	{
		if (TeamAliveCounts[0] == 0) WinningTeam = 1;
		else if (TeamAliveCounts[1] == 0) WinningTeam = 0;
		return false;
	}
}

// Start a round (FIGHT): everyone is spawned now, nobody was in the arena during the
// countdown. Projectiles of the arena that are still flying are removed.
function StartRound()
{
	local PlayerIterator PIter;
	local Projectile P;
	local RAReplicationInfo RA;

	Period = PERIOD_GameTime;
	RoundStartTime = Level.TimeSeconds;

	foreach AllActors(class'Projectile', P)
	{
		class'RATools'.static.GetRepInfo(P.Instigator, Game.GameReplicationInfo, RA);
		if (RA != None && RA.Arena == Arena)
			P.Destroy();
	}

	SpawnPlayers();

	PIter = class'RATools'.static.PlayersInArena(Game.GameReplicationInfo, Arena);
	PIter.SpectatorsWanted = false;
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		RefillAmmo(PIter.Pawn);
		if (PIter.PRI.bIsABot)
			RABot(PIter.Pawn).bRACanFire = true;
	}
}

// The countdown before a round: the players of the arena wait as spectators (not in
// the arena, nothing to shoot with) until StartRound spawns them.
function HoldPlayers()
{
	local PlayerIterator PIter;

	PIter = class'RATools'.static.PlayersInArena(Game.GameReplicationInfo, Arena);
	PIter.SpectatorsWanted = false;
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		Game.ResetViewersOf(PIter.Pawn);
		Game.DiscardInventory(PIter.Pawn);
		PIter.Pawn.Health = 100;
		if (!PIter.PRI.bIsABot)
		{
			PlayerPawn(PIter.Pawn).EndZoom();
			PlayerPawn(PIter.Pawn).ViewTarget = None;
			PlayerPawn(PIter.Pawn).bBehindView = False;
			PIter.Pawn.GotoState('PlayerSpectating');
		}
		else
		{
			PIter.Pawn.GotoState('Dying', 'WaitingForStart');
			RABot(PIter.Pawn).bRACanFire = False;
			PIter.Pawn.bHidden = true;
			PIter.Pawn.SetCollision(false, false, false);
		}
	}
	BroadcastLocalizedMessage(class'StartMatchMessage', 0);
}

// FIGHT: everyone in the arena is spawned with full health and inventory.
function SpawnPlayers()
{
	local PlayerIterator PIter;

	PIter = class'RATools'.static.PlayersInArena(Game.GameReplicationInfo, Arena);
	PIter.SpectatorsWanted = false;
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		PIter.Pawn.Health = 100;
		if (!PIter.PRI.bIsABot)
		{
			PIter.Pawn.PlayerRestartState = PIter.Pawn.Default.PlayerRestartState;
			PIter.Pawn.GotoState(PIter.Pawn.Default.PlayerRestartState);
			Game.RestartPlayer(PIter.Pawn);
		}
		else
		{
			PIter.Pawn.bHidden = false;
			PIter.Pawn.SetCollision(true, true, true);
			AddDefaultInventory(PIter.Pawn);
			PIter.Pawn.RestartPlayer();
			Bot(PIter.Pawn).StartMatch();
		}
		PIter.Pawn.PlaySound(None, SLOT_Misc);
	}
}

// Nothing hurts or pushes anyone outside of round time, and a shot only counts
// once its shooter can have seen FIGHT (see ShotAfterRoundStart).
function bool AllowDamage(Pawn Injured, Pawn InstigatedBy, name DamageType)
{
	if (DamageType == 'SpecialDamage')
		return true;
	if (Period != PERIOD_GameTime)
		return false;
	if (InstigatedBy != None && !ShotAfterRoundStart(InstigatedBy))
		return false;
	return true;
}

// After the round is decided the own rockets push but don't hurt; during the
// countdown nobody moves anyone.
function bool AllowSelfPush(Pawn P)
{
	return Period != PERIOD_Shakedown;
}

// Projectiles fired during the countdown are removed at FIGHT.  One that reaches
// the server just after FIGHT, but was fired before the shooter saw it, goes too.
function bool AllowNewProjectile(Projectile P)
{
	if (Period == PERIOD_GameTime && P.Instigator != None && !ShotAfterRoundStart(P.Instigator))
		return false;
	return true;
}

// The server starts the round at RoundStartTime.  The shooter sees FIGHT half a
// ping later, and a shot fired then arrives another half ping later, so anything
// from him that reaches the server before RoundStartTime + ping was fired before
// he saw FIGHT.  This also covers InstaGib+, which compensates shots for ping.
function bool ShotAfterRoundStart(Pawn Shooter)
{
	local float Lag;

	if (PlayerPawn(Shooter) != None && Shooter.PlayerReplicationInfo != None)
		Lag = FClamp(Shooter.PlayerReplicationInfo.Ping, 0, 500) / 1000.0 * Level.TimeDilation;
	return Level.TimeSeconds >= RoundStartTime + Lag;
}

// Start the "match" but don't start the "round": the countdown, then StartRound.
function StartMatch()
{
	local TimedTrigger T;

	bCanChangeTeams = false;
	Period = PERIOD_Shakedown;
	Countdown = ShakedownTime;

	ForEach AllActors(class'TimedTrigger', T)
		T.SetTimer(T.DelaySeconds, T.bRepeating);
	if ( Level.NetMode != NM_Standalone )
		Game.RemainingBots = 0;
	Game.GameReplicationInfo.RemainingMinute = Game.RemainingTime;

	HoldPlayers();
}

// A team has won a round but not the match.  Count down to the next round.
function RestartRound()
{
	HoldPlayers();
	Period = PERIOD_Shakedown;
	Countdown = ShakedownTime;
	CurrentRound++;
}

function Killed(pawn Killer, pawn Other, name damageType)
{
	local int WinningTeam;

	// The last player of a team died: the remaining team wins the round.
	if (CountDown == -1 && !ValidTeamsForRound(WinningTeam))
	{
		VictoryTeam = WinningTeam;
		Period = PERIOD_Victory;
		Countdown = 3;
	}
}

// Grant a team a round victory and then check for match victory or start a new round.
function TeamVictory( int Team )
{
	local TeamInfo Winners, Losers;
	local bool WinnerDamaged;
	local PlayerIterator PIter;
	local int RoundsNeeded;

	Winners = Teams[Team];
	Losers = Teams[1 - Team];
	Winners.Score += 1;

	// Calculate health and discard inventory.
	PIter = class'RATools'.static.PlayersInArena(Game.GameReplicationInfo, Arena);
	PIter.SpectatorsWanted = false;
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		if (PIter.PRI.Team == Team)
			WinnerDamaged = ( WinnerDamaged || PIter.Pawn.Health < 100 );

		Game.DiscardInventory(PIter.Pawn);
	}

	// Send the "perfect" message.
	if ( !WinnerDamaged )
	{
		PerfectType = 0;
		PerfectTimer = 2;
		PerfectCount[Team]++;
	}

	RoundsNeeded = (Game.RAGRI.WeaponInfo.RoundLimit[Arena] / 2) + 1;
	//if it's a Match Victory
	if ( Winners.Score >= RoundsNeeded )
	{
		// Override and send the "flawless" message if necessary.
		if ( PerfectCount[Team] == RoundsNeeded && Losers.Score == 0 )
		{
			PerfectType = 1;
			AwardFlawless(Team);
		}

		// This team has a match victory.
		MatchVictory( Team );
	} else {
		// Start a new round.
		Period = PERIOD_PostRound;
		Countdown = PostRoundTime;
		BroadcastLocalizedMessage(class'RoundVictoryMessage', Team);
	}
}

function MatchVictory( int Team )
{
	local PlayerIterator PIter;

	// Send everyone to a spectator state.
	bCanChangeTeams = true;
	// Check to see if everyone on a team is dead.
	PIter = class'RATools'.static.PlayersInArena(Game.GameReplicationInfo, Arena);
	PIter.SpectatorsWanted = false;
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		Game.ResetViewersOf(PIter.Pawn);
		if (!PIter.PRI.bIsABot)
		{
			PIter.Pawn.GotoState('PlayerSpectating');
			Game.DiscardInventory(PIter.Pawn);
			PlayerPawn(PIter.Pawn).EndZoom();
		} else {
			PIter.Pawn.GotoState('Dying', 'WaitingForStart');
		}
	}

	BroadcastLocalizedMessage(class'RoundVictoryMessage', Team + 2);
	Period = PERIOD_PostMatch;
	Countdown = PostMatchTime;
	CurrentRound = 1;

	// Reset team scores.
	Teams[0].Score = 0;
	Teams[1].Score = 0;

	// Reset perfect counts.
	PerfectCount[0] = 0;
	PerfectCount[1] = 0;
}

// Players can't hurt other players during the shakedown.
// Also, check for SelfDamage and TeamDamage.
function int ReduceDamage(int Damage, name DamageType, pawn injured, pawn instigatedBy)
{
	if (DamageType != 'SpecialDamage' && (Injured == InstigatedBy) && (Game.RAGRI.WeaponInfo.SelfDamage[Arena] == 0))
		return 0;

	if ( instigatedBy == None )
		return Damage;

	if ( (instigatedBy != injured) && injured.bIsPlayer && instigatedBy.bIsPlayer
		&& (injured.PlayerReplicationInfo.Team == instigatedBy.PlayerReplicationInfo.Team) && (Game.RAGRI.WeaponInfo.TeamDamage[Arena] == 0) )
	{
		if ( injured.IsA('Bot') )
			Bot(Injured).YellAt(instigatedBy);
		return (Damage * FriendlyFireScale);
	} else {
		return Damage;
	}
}

function SendStartMessage(PlayerPawn P)
{
	BroadcastLocalizedMessage(class'StartMatchMessage', 0);
}

function bool IsSpectateOnDeath()
{
	return true;
}

function bool SafeToMove( Pawn Player )
{
	if (Player.PlayerReplicationInfo.Team == 255)
		return true;
	return bCanChangeTeams;
}

// Prevent bots from reacting to spectating or dead players.
function byte AssessBotAttitude(Bot aBot, Pawn Other)
{
	if ( Other.PlayerReplicationInfo.Team == 255 )
		return 2;
	else if ( Other.PlayerReplicationInfo.bIsSpectator )
		return 2;
	else if ( (Other.bIsPlayer && (aBot.PlayerReplicationInfo.Team == Other.PlayerReplicationInfo.Team))
		|| (Other.IsA('TeamCannon')
			&& (StationaryPawn(Other).SameTeamAs(aBot.PlayerReplicationInfo.Team))) )
		return 3;
	else
		return Super.AssessBotAttitude(aBot, Other);
}

function Logout(pawn Exiting, RAReplicationInfo RA)
{
	if (Exiting.PlayerReplicationInfo.Team < 2)
		Teams[Exiting.PlayerReplicationInfo.Team].Size--;

	Rebalance();
}

function AwardFlawless(int Team)
{
}

defaultproperties
{
      bBalancing=False
      ArenaInfo=None
      PerfectTimer=0
      PerfectType=0
      PerfectCount(0)=0
      PerfectCount(1)=0
      bTeamGame=True
      GameName="Clan Arena"
      MainMenuClass=Class'RocketArenaV2.RASlideMenu_Clan'
      BotConfigClass=Class'RocketArenaV2.RABotConfigCW_Clan'
      ScoringType=Class'RocketArenaV2.RAScoreboard_Clan'
}
