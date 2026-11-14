class RADeathMatchMessage extends DeathMatchMessage;

// RocketArena suppresses "TeamChange" messages because
// team changes are common and annoying.
static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	if (Switch == 2)
		return "";
	else
		return Super.GetString(Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}

defaultproperties
{
}
