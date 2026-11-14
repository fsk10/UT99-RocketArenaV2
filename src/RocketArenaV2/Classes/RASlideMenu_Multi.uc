class RASlideMenu_Multi expands RASlideMenu;

function OptionClicked(int i)
{
	local RAGameReplicationInfo RAGRI;
	local RAReplicationInfo RepInfo;

	switch (i)
	{
		case 0:
			SetPage(2);
			break;
		case 1:
			SetPage(1);
			break;
		case 2:
			if (GetInfo(RAGRI, RepInfo) && ArenaGame_Multi(RAGRI.ArenaGames[RepInfo.Arena]).EnterArena(GetPlayerOwner()))
				Close();
			break;
		case 3:
			SwitchTeams(255);
			break;
	}
}

function int OptionPage(int i)
{
	if (i == 0)
		return 2;
	if (i == 1)
		return 1;
	return 0;
}

defaultproperties
{
      TitleTex=Texture'RocketArenaV2Media.TitleMulti'
      TitleU=479.000000
      TitleV=85.000000
      NumOptions=4
      OptionText(0)="CREATE A TEAM"
      OptionText(1)="JOIN A TEAM"
      OptionText(2)="ENTER ARENA"
      OptionText(3)="SPECTATE"
      OptionHelp(0)="Start your own team in this arena"
      OptionHelp(1)="Join an existing team in this arena"
      OptionHelp(2)="Enter this arena and queue up"
      OptionHelp(3)="Watch the arena without playing"
      OptionIcon(0)=Texture'RocketArenaV2Media.IconCreate'
      OptionIcon(1)=Texture'RocketArenaV2Media.IconJoin'
      OptionIcon(2)=Texture'RocketArenaV2Media.IconEnter'
      OptionIcon(3)=Texture'RocketArenaV2Media.IconSpectate'
}
