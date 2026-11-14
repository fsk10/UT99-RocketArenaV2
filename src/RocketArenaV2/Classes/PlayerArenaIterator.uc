class PlayerArenaIterator extends PlayerIterator;

var int Arena;

function bool IsCurrentRepValid () {
	if (RARepInfo.Arena == Arena) return Super.IsCurrentRepValid();
	else return false;
}

defaultproperties
{
      Arena=0
}
