class CountdownMessage extends CriticalEventPlus;

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

	P.ClientPlaySound(class'RocketArenaGame'.default.NewVoiceTheme.default.Countdown[Switch],,true);
	switch (Switch)
	{
		case 0:
			RocketArenaHUD(P.myHud).SetCenterMessage(texture'RocketArenaMedia.RA_Fight', 2);
			break;
		case 1:
			RocketArenaHUD(P.myHud).SetCenterMessage(texture'RocketArenaMedia.RA_1', 1);
			break;
		case 2:
			RocketArenaHUD(P.myHud).SetCenterMessage(texture'RocketArenaMedia.RA_2', 1);
			break;
		case 3:
			RocketArenaHUD(P.myHud).SetCenterMessage(texture'RocketArenaMedia.RA_3', 1);
			break;
	}
}

defaultproperties
{
      bBeep=False
      DrawColor=(R=255,G=0,B=0)
}
