class ArenaInfo expands Info;

var() string ArenaNames[8];
var() int ArenaTeamSize[8];
var() enum EArenaType
{
	ET_None,
	ET_Multi,
	ET_Pickup
} ArenaType[8];

replication
{
	reliable if ( Role == ROLE_Authority )
		ArenaNames, ArenaTeamSize;
}

defaultproperties
{
      ArenaNames(0)=""
      ArenaNames(1)=""
      ArenaNames(2)=""
      ArenaNames(3)=""
      ArenaNames(4)=""
      ArenaNames(5)=""
      ArenaNames(6)=""
      ArenaNames(7)=""
      ArenaTeamSize(0)=1
      ArenaTeamSize(1)=1
      ArenaTeamSize(2)=1
      ArenaTeamSize(3)=1
      ArenaTeamSize(4)=1
      ArenaTeamSize(5)=1
      ArenaTeamSize(6)=1
      ArenaTeamSize(7)=1
      ArenaType(0)=ET_None
      ArenaType(1)=ET_None
      ArenaType(2)=ET_None
      ArenaType(3)=ET_None
      ArenaType(4)=ET_None
      ArenaType(5)=ET_None
      ArenaType(6)=ET_None
      ArenaType(7)=ET_None
      bAlwaysRelevant=True
}
