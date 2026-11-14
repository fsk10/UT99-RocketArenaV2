class PlayerIterator extends Actor;

/**

To be used as follows:

PIter = class'RATools'.static.PlayersInArena(GRI, TeamInfo);
PIter.BotsWanted = false;
PIter.PlayerPawnsWanted = true;
for (PIter=PIter; PIter.RARepInfo != None; PIter.Next()) {
	//in here, can access:
	//PIter.RARepInfo;
	//PIter.PRI;
	//PITer.Pawn;
}

The purpose of this extra 'overhead' is to make reading the code somewhat easier,
and to make bugs more infrequent. By using this, you're forcing yourself to think
about what kind of iterator you want, andso mistakes about forgetting to restrict
the player scope are avoided. I'd like to hear your thoughts on this approach. :)

**/

var RAGameReplicationInfo RAGRI;
var RAReplicationInfo RARepInfo;
var PlayerReplicationInfo PRI;
var Pawn Pawn;
var() bool BotsWanted;
var() bool PlayerPawnsWanted;
var() bool SpectatorsWanted;

//used for when caching PlayerIterators
var bool bInUse;
var PlayerIterator CachedPlayerIterator;

static function PlayerIterator getInstance(class<PlayerIterator> PIClass, GameReplicationInfo GRI, bool MakeNewOne)
{
	local PlayerIterator PIter;
	if (MakeNewOne) {
		PIter = GRI.Spawn(PIClass,,,GRI.Location);
	} else if (PIClass.default.CachedPlayerIterator != None && !PIClass.default.CachedPlayerIterator.bInUse) {
		PIter = PIClass.default.CachedPlayerIterator;
	} else {
		PIter = GRI.Spawn(PIClass,,,GRI.Location);
		PIClass.default.CachedPlayerIterator = PIter;
	}

	PIter.RAGRI = RAGameReplicationInfo(GRI);
	PIter.bInUse = true;
     	PIter.BotsWanted=default.BotsWanted;
     	PIter.PlayerPawnsWanted=default.PlayerPawnsWanted;
     	PIter.SpectatorsWanted=default.SpectatorsWanted;

	return PIter;
}

function Init()
{
	RARepInfo = RAGRI.RepInfoList;
	while (RARepInfo != None && !IsCurrentRepValid())
	{
		RARepInfo = RARepInfo.NextRepInfo;
	}
	if (RARepInfo == None)
	{
		PRI = None;
		Pawn = None;
		bInUse = false;
	} else {
		PRI = RARepInfo.OwnerPRI;
		Pawn = Pawn(PRI.Owner);
	}
}

function bool IsCurrentRepValid ()
{
	return (
		(RARepInfo.OwnerPRI != None) &&
		(Bot(RARepInfo.OwnerPRI.Owner) == None || BotsWanted) &&
		(PlayerPawn(RARepInfo.OwnerPRI.Owner) == None || PlayerPawnsWanted) &&
		(RARepInfo.OwnerPRI.Team != 255 || SpectatorsWanted)
	);

}

function Next() {
	if (RARepInfo == None)
	{
		warn("PlayerIterator read past the end");
		assert(false);
		return;
	}
	do
	{
		RARepInfo = RARepInfo.NextRepInfo;
	} until (RARepInfo == None || IsCurrentRepValid());

	if (RARepInfo == None)
	{
		PRI = None;
		Pawn = None;
		bInUse = false;
	} else {
		PRI = RARepInfo.OwnerPRI;
		Pawn = Pawn(PRI.Owner);
	}
}

defaultproperties
{
      RAGRI=None
      RARepInfo=None
      PRI=None
      Pawn=None
      BotsWanted=True
      PlayerPawnsWanted=True
      SpectatorsWanted=True
      bInUse=False
      CachedPlayerIterator=None
}
