class SelfKillMessage extends CriticalEventPlus;

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	return "Ridiculous!  Don't shoot yourself, shoot the enemy!";
}

static function ClientReceive(
	PlayerPawn P,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	Super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

	P.ClientPlaySound(class'RocketArenaGame'.default.NewVoiceTheme.default.WeaponSuicide,,true);
}

defaultproperties
{
      bBeep=False
}
