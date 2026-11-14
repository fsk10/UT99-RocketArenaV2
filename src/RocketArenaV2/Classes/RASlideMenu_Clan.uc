class RASlideMenu_Clan extends RASlideMenu;

function OptionClicked(int i)
{
	switch (i)
	{
		case 0:
			TellPrepare();
			SwitchTeams(0);
			break;
		case 1:
			TellPrepare();
			SwitchTeams(1);
			break;
		case 2:
			TellPrepare();
			AutoTeam();
			break;
		case 3:
			SwitchTeams(255);
			break;
	}
}

// The join buttons show how many players each team has.
function string OptionLabel(int i)
{
	local RAGameReplicationInfo RAGRI;
	local RAReplicationInfo RA;

	if (i < 2 && GetInfo(RAGRI, RA) && RAGRI.ArenaGames[RA.Arena].Teams[i] != None)
		return OptionText[i]$" ("$RAGRI.ArenaGames[RA.Arena].Teams[i].Size$")";
	return OptionText[i];
}

function string StatusText(RAGameReplicationInfo RAGRI, RAReplicationInfo RA)
{
	local PlayerReplicationInfo PRI;

	PRI = GetPlayerOwner().PlayerReplicationInfo;
	if (PRI != None && PRI.Team == 0)
		return RedTeamText;
	if (PRI != None && PRI.Team == 1)
		return BlueTeamText;
	return SpectatingText;
}

function AutoTeam()
{
	local RAGameReplicationInfo RAGRI;
	local RAReplicationInfo RA;

	if (GetInfo(RAGRI, RA))
		RAGRI.ArenaGames[RA.Arena].EnterArena(GetPlayerOwner());

	Close();
}

defaultproperties
{
      TitleTex=Texture'RocketArenaV2Media.TitleClan'
      TitleU=444.000000
      TitleV=86.000000
      NumOptions=4
      OptionText(0)="JOIN RED"
      OptionText(1)="JOIN BLUE"
      OptionText(2)="AUTO PICK"
      OptionText(3)="SPECTATE"
      OptionHelp(0)="Play for the red team"
      OptionHelp(1)="Play for the blue team"
      OptionHelp(2)="Join the team that needs players"
      OptionHelp(3)="Watch the arena without playing"
      OptionIcon(0)=Texture'RocketArenaV2Media.IconJoin'
      OptionIcon(1)=Texture'RocketArenaV2Media.IconJoin'
      OptionIcon(2)=Texture'RocketArenaV2Media.IconAuto'
      OptionIcon(3)=Texture'RocketArenaV2Media.IconSpectate'
      OptionTint(0)=(R=195,G=2,B=1,A=0)
      OptionTint(1)=(R=4,G=28,B=255,A=0)
      RedTeamText="Red team"
      BlueTeamText="Blue team"
}
