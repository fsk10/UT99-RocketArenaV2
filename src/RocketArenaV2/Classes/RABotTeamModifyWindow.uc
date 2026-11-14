class RABotTeamModifyWindow extends UMenuFramedWindow;

function BeginPlay()
{
	Super.BeginPlay();

	ClientClass = class'RABotTeamModifyCW';
	WindowTitle = "RocketArena - Modify Bot Teams";
}

function Created()
{
	bStatusBar = false;
	bSizable = false;

	Super.Created();

	SetSize(240, 200);
	WinLeft = Root.WinWidth/2 - WinWidth/2;
	WinTop = Root.WinHeight/2 - WinHeight/2;

	bLeaveOnScreen = true;
}

function Setup(int TeamSize)
{
	RABotTeamModifyCW(ClientArea).Setup(TeamSize);
}

defaultproperties
{
}
