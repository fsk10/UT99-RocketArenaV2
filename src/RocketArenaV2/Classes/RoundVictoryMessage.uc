class RoundVictoryMessage extends CriticalEventPlus;

var localized string Team0RoundVictory;
var localized string Team1RoundVictory;
var localized string Team0MatchVictory;
var localized string Team1MatchVictory;

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
			return Default.Team0RoundVictory;
			break;
		case 1:
			return Default.Team1RoundVictory;
			break;
		case 2:
			return Default.Team0MatchVictory;
			break;
		case 3:
			return Default.Team1MatchVictory;
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
			P.ClientPlaySound(class'RocketArenaGame'.default.NewVoiceTheme.default.WinRound[Switch],,true);
			break;
		case 1:
			P.ClientPlaySound(class'RocketArenaGame'.default.NewVoiceTheme.default.WinRound[Switch],,true);
			break;
		case 2:
			P.ClientPlaySound(class'RocketArenaGame'.default.NewVoiceTheme.default.WinMatch[Switch-2],,true);
			break;
		case 3:
			P.ClientPlaySound(class'RocketArenaGame'.default.NewVoiceTheme.default.WinMatch[Switch-2],,true);
			break;
	}
}

defaultproperties
{
      Team0RoundVictory="Red team wins the round."
      Team1RoundVictory="Blue team wins the round."
      Team0MatchVictory="Red team wins the match."
      Team1MatchVictory="Blue team wins the match."
      bBeep=False
}
