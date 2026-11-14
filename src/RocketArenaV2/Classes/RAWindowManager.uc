class RAWindowManager extends Info;

var WindowConsole LocalConsole;
var RASlideMenu MainMenu;

function Spawned()
{
	if (Level.NetMode == NM_DedicatedServer)
		return;

	LocalConsole = WindowConsole(PlayerPawn(Owner).Player.Console);
}

function QuickKeyMode()
{
	if (LocalConsole.Root==None)
	{
		// Tell it to use our special root when creating it
		LocalConsole.RootWindow = "RocketArenaV2.WRIRootWindow";

		LocalConsole.CreateRootWindow(None);
	}
	LocalConsole.bQuickKeyEnable = true;
	LocalConsole.LaunchUWindow();
}

function CreateWindow(class<UWindowWindow> WindowClass)
{
	QuickKeyMode();
	LocalConsole.Root.CreateWindow(WindowClass, 100, 100, 100, 100);
}

function CreateMainMenu(class<RASlideMenu> WindowClass)
{
	QuickKeyMode();
	MainMenu = RASlideMenu(LocalConsole.Root.CreateWindow(WindowClass, 100, 100, 100, 100));
	MainMenu.SlideIn();
}

function NewArenaMenu(int NewArena)
{
	local RAGameReplicationInfo RAGRI;

	QuickKeyMode();

	MainMenu.SlideOut();

	RAGRI = RAGameReplicationInfo(PlayerPawn(Owner).GameReplicationInfo);
	MainMenu = RASlideMenu(LocalConsole.Root.CreateWindow(RAGRI.ArenaGames[NewArena].MainMenuClass, 100, 100, 100, 100));
	MainMenu.FastSlideIn();
}

defaultproperties
{
      LocalConsole=None
      MainMenu=None
}
