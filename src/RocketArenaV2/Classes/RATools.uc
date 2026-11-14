class RATools extends Info
	abstract;

static function GetRepInfo(Pawn P, GameReplicationInfo GRI, out RAReplicationInfo RepInfo)
{
	if (P == None)
	{
		RepInfo = None;
		return;
	}

	if (RAGameReplicationInfo(GRI) == None)
	{
		RepInfo = None;
		return;
	}

	for (RepInfo=RAGameReplicationinfo(GRI).RepInfoList; RepInfo!=None; RepInfo=RepInfo.NextRepInfo)
	{
		if (RepInfo.OwnerPRI == P.PlayerReplicationInfo)
			return;
	}
	RepInfo = None;
}

static function GetRepInfoFromPRI(PlayerReplicationInfo PRI, GameReplicationInfo GRI, out RAReplicationInfo RepInfo)
{
	if (PRI == None)
	{
		RepInfo = None;
		return;
	}

	if (RAGameReplicationInfo(GRI) == None)
	{
		RepInfo = None;
		return;
	}

	for (RepInfo=RAGameReplicationinfo(GRI).RepInfoList; RepInfo!=None; RepInfo=RepInfo.NextRepInfo)
	{
		if (RepInfo.OwnerPRI == PRI)
			return;
	}
	RepInfo = None;
}

static function PlayerIterator PlayersInGame (GameReplicationInfo GRI, optional bool MakeNewOne)
{
	local PlayerIterator PIter;
	PIter = class'PlayerIterator'.static.getInstance(class'PlayerIterator', GRI, MakeNewOne);
	return PIter;
}

static function PlayerIterator PlayersInArena (GameReplicationInfo GRI, int Arena, optional bool MakeNewOne)
{
	local PlayerIterator PIter;
	PIter = class'PlayerIterator'.static.getInstance(class'PlayerArenaIterator', GRI, MakeNewOne);
	PlayerArenaIterator(PIter).Arena = Arena;
	return PIter;
}

// Arena summaries for F2 and the arena overview next to the menu (client side).

// "2v2", "Clan", ...
static function string ArenaMode(RAGameReplicationInfo RAGRI, int Arena)
{
	if (ArenaGame_Multi(RAGRI.ArenaGames[Arena]) != None)
		return RAGRI.ArenaInfo.ArenaTeamSize[Arena]$"v"$RAGRI.ArenaInfo.ArenaTeamSize[Arena];
	return "Clan";
}

// 0 = empty, 1 = waiting for players, 2 = countdown, 3 = playing.
static function int ArenaState(RAGameReplicationInfo RAGRI, int Arena)
{
	local ArenaGame AG;

	AG = RAGRI.ArenaGames[Arena];
	if (AG.PlayerCount <= 0)
		return 0;
	if (AG.Period == PERIOD_GameTime)
		return 3;
	if (AG.bWaitingForPlayers || AG.Countdown <= 0)
		return 1;
	return 2;
}

static function string ArenaStatus(RAGameReplicationInfo RAGRI, int Arena)
{
	local ArenaGame AG;

	AG = RAGRI.ArenaGames[Arena];
	switch (ArenaState(RAGRI, Arena))
	{
	case 0:
		return "Empty";
	case 1:
		return "Waiting for players";
	case 3:
		return "Round"@AG.CurrentRound@"of"@RAGRI.WeaponInfo.Rule(Arena, 0);
	}
	switch (AG.Period)
	{
	case PERIOD_PostMatch:
		return "Next match in"@AG.Countdown;
	case PERIOD_PostRound:
		return "Next round in"@AG.Countdown;
	}
	return "Get ready"@AG.Countdown;
}

// Names of the players in an arena that match: Team = a Multi team, or ClanTeam = 0/1
// for a Clan arena team, 255 for spectators (players without a team).
static function string PlayerNames(RAGameReplicationInfo RAGRI, int Arena, RATeamInfo Team, optional int ClanTeam)
{
	local PlayerIterator PIter;
	local string S;
	local bool bMatch;

	PIter = PlayersInArena(RAGRI, Arena);
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{
		if (Team != None)
			bMatch = PIter.RARepInfo.Team == Team;
		else if (ClanTeam == 255)
			bMatch = PIter.RARepInfo.Team == None && PIter.PRI.Team == 255;
		else
			bMatch = PIter.PRI.Team == ClanTeam;
		if (bMatch)
		{
			if (S != "")
				S = S$", ";
			S = S$PIter.PRI.PlayerName;
		}
	}
	return S;
}

// Players in an arena that play or wait in the queue (spectators not counted).
static function int ActiveCount(RAGameReplicationInfo RAGRI, int Arena)
{
	local PlayerIterator PIter;
	local int n;

	PIter = PlayersInArena(RAGRI, Arena);
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
		if (PIter.RARepInfo.Team != None || PIter.PRI.Team != 255)
			n++;
	return n;
}

// Human players in an arena, spectators included (bots not counted).
static function int HumanCount(RAGameReplicationInfo RAGRI, int Arena)
{
	local PlayerIterator PIter;
	local int n;

	PIter = PlayersInArena(RAGRI, Arena);
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
		if (!PIter.PRI.bIsABot)
			n++;
	return n;
}

// Human players in every arena but Arena.
static function int OtherArenasCount(RAGameReplicationInfo RAGRI, int Arena)
{
	local int i, n;

	for (i=0; i<ArrayCount(RAGRI.ArenaGames); i++)
		if (i != Arena && RAGRI.ArenaGames[i] != None)
			n += HumanCount(RAGRI, i);
	return n;
}

// "1 player", "2 players".
static function string Plural(int N, string Word)
{
	if (N == 1)
		return N@Word;
	return N@Word$"s";
}

static function string TeamText(RAGameReplicationInfo RAGRI, int Arena, RATeamInfo T)
{
	local string Names;

	Names = PlayerNames(RAGRI, Arena, T);
	if (Names == "" || Names == T.TeamName)
		return T.TeamName;
	return T.TeamName$" ("$Names$")";
}

defaultproperties
{
}
