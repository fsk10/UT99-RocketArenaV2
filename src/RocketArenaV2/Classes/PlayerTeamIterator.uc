class PlayerTeamIterator extends PlayerIterator;

var RATeamInfo Team;

function bool IsCurrentRepValid () {
	if (RARepInfo.Team == Team) return Super.IsCurrentRepValid();
	else return false;
}

defaultproperties
{
      Team=None
}
