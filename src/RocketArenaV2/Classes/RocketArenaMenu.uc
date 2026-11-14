// "RA: UT" in the UT menu bar: opens the RA menu, or its chat page. Everything else
// (arenas, teams, admin settings) is in that menu now.
class RocketArenaMenu extends UWindowPulldownMenu;

var UWindowPulldownMenuItem MainMenu, ChatMenu;

var localized string MainMenuName, ChatMenuName;
var localized string MainMenuHelp, ChatMenuHelp;

function Created()
{
	Super.Created();

	MainMenu = AddMenuItem(MainMenuName, None);
	ChatMenu = AddMenuItem(ChatMenuName, None);
}

function ExecuteItem(UWindowPulldownMenuItem I)
{
	local RAReplicationInfo RepInfo;

	class'RATools'.static.GetRepInfo(Root.GetPlayerOwner(), Root.GetPlayerOwner().GameReplicationInfo, RepInfo);

	if (I == MainMenu || I == ChatMenu)
	{
		if (RepInfo == None)
		{
			MessageBox("Rocket Arena", "You must be in a Rocket Arena game to open the Rocket Arena menu.", MB_OK, MR_OK, MR_OK);
			return;
		}
		if (I == ChatMenu && RocketArenaHUD(Root.GetPlayerOwner().MyHUD) != None)
			RocketArenaHUD(Root.GetPlayerOwner().MyHUD).OpenChat();
		else
			RepInfo.PopupMainMenu(RepInfo.Arena);
	}

	Super.ExecuteItem(I);
}

function Select(UWindowPulldownMenuItem I)
{
	if (I == MainMenu)
		UMenuMenuBar(GetMenuBar()).SetHelp(MainMenuHelp);
	else if (I == ChatMenu)
		UMenuMenuBar(GetMenuBar()).SetHelp(ChatMenuHelp);

	Super.Select(I);
}

defaultproperties
{
      MainMenuName="Open Menu"
      MainMenuHelp="Open the Rocket Arena menu: arenas, teams, and admin settings"
      ChatMenuName="Open Chat"
      ChatMenuHelp="Read and write chat: your arena or all arenas"
}
