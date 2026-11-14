class RAGameReplicationInfo expands TournamentGameReplicationInfo;

var RAReplicationInfo	RepInfoList;

// Game contexts.
var ArenaGame ArenaGames[8];

// Configuration information.
var WeaponInfo WeaponInfo;

// Arena information
var ArenaInfo ArenaInfo;

// Server settings, for the admin page of the menu (set by RocketArenaGame).
var bool	bForce1on1, bInstantRockets, bFallingDamage, bSpectatorSpeech;
var float	BouncyHeight;
var byte	BotSkill;

replication
{
	// Variables the server sends to the client.
	reliable if ( Role == ROLE_Authority )
		RepInfoList, ArenaGames, WeaponInfo, ArenaInfo,
		bForce1on1, bInstantRockets, bFallingDamage, bSpectatorSpeech, BouncyHeight, BotSkill;

}

function RemoveRepInfo(RAReplicationInfo RepInfo)
{
	if (RepInfo.NextRepInfo != None)
		RepInfo.NextRepInfo.PrevRepInfo = RepInfo.PrevRepInfo;
	if (RepInfo.PrevRepInfo != None)
		RepInfo.PrevRepInfo.NextRepInfo = RepInfo.NextRepInfo;
	else
		RepInfoList = RepInfo.NextRepInfo;
}

defaultproperties
{
      RepInfoList=None
      ArenaGames(0)=None
      ArenaGames(1)=None
      ArenaGames(2)=None
      ArenaGames(3)=None
      ArenaGames(4)=None
      ArenaGames(5)=None
      ArenaGames(6)=None
      ArenaGames(7)=None
      WeaponInfo=None
      ArenaInfo=None
}
