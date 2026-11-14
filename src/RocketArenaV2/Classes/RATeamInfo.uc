class RATeamInfo expands TeamInfo;

var Pawn		TeamMembers[8];

var RATeamInfo	PrevTeam;
var RATeamInfo	NextTeam;

var bool		bBotTeam;

var localized string	BotTeamNames[8];

var int			WaitingPos;

var int			MatchWins, MatchFlawless;
var bool		bWaitForFull;	// Created on purpose: only plays once the team is full.

replication
{
	reliable if ( Role == ROLE_Authority )
		bBotTeam, PrevTeam, NextTeam, WaitingPos, MatchWins, MatchFlawless, bWaitForFull;
}

function PostBeginPlay()
{
	SetTimer(0.3, true);
	WaitingPos = -1;
}

function Timer()
{
	// Update our size.
	Size = NumMembers();
}

// Size is only refreshed by the timer; this is the current count.
function int NumMembers()
{
	local int i, Count;

	for (i=0; i<8; i++)
	{
		if (TeamMembers[i] != None)
			Count++;
	}
	return Count;
}

function Disband()
{
	local int i;

	if (PrevTeam != None)
		PrevTeam.NextTeam = NextTeam;

	if (NextTeam != None)
		NextTeam.PrevTeam = PrevTeam;

	// Remove team members.
	for (i=0; i<8; i++)
	{
		if (Bot(TeamMembers[i]) != None) {
			TeamMembers[i].Destroy();
		}
	}

	Destroy();
}

defaultproperties
{
      TeamMembers(0)=None
      TeamMembers(1)=None
      TeamMembers(2)=None
      TeamMembers(3)=None
      TeamMembers(4)=None
      TeamMembers(5)=None
      TeamMembers(6)=None
      TeamMembers(7)=None
      PrevTeam=None
      NextTeam=None
      bBotTeam=False
      BotTeamNames(0)="The Iron Eagles"
      BotTeamNames(1)="The Blood Claw"
      BotTeamNames(2)="Dragon's Breath"
      BotTeamNames(3)="Asskickers Inc."
      BotTeamNames(4)="The Beef Eaters"
      BotTeamNames(5)="The Black Reapers"
      BotTeamNames(6)="Bad Mojo"
      BotTeamNames(7)="Low Riders"
      WaitingPos=0
      MatchWins=0
      MatchFlawless=0
}
