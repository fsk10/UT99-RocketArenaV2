class StartMatchMessage extends CriticalEventPlus;

var localized string GetReady;

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	return "";
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
			P.ClientPlaySound(class'RocketArenaGame'.default.NewVoiceTheme.default.GetReady,,true);
			RocketArenaHUD(P.myHud).SetCenterMessage(texture'RocketArenaMedia.RA_GetReady', 2);
			break;
	}
}

defaultproperties
{
      GetReady="Get Ready!"
      bBeep=False
}
