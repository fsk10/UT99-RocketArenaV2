class PerfectMessage extends CriticalEventPlus;

var localized string Perfect;
var localized string Flawless;

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	switch (Switch)
	{
		case 0:
			return Default.Perfect;
			break;
		case 1:
			return Default.Flawless;
			break;
	}
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

	switch (Switch)
	{
		case 0:
			P.ClientPlaySound(class'RocketArenaGame'.default.NewVoiceTheme.default.Perfect,,true);
			break;
		case 1:
			P.ClientPlaySound(class'RocketArenaGame'.default.NewVoiceTheme.default.Flawless,,true);
			break;
	}
}

defaultproperties
{
      Perfect="Perfect Round!"
      Flawless="Flawless Victory!"
      bBeep=False
      DrawColor=(R=255,G=0,B=0)
}
