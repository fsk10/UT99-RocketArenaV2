class RAGameRulesWindow extends UMenuFramedWindow;

function BeginPlay()
{
	Super.BeginPlay();

	ClientClass = class'RAGameRulesCW';
	WindowTitle = "RocketArena - Rules Configuration";
}

function Created()
{
	bStatusBar = false;
	bSizable = false;

	Super.Created();

	SetSize(240, 195);
	WinLeft = Root.WinWidth/2 - WinWidth/2;
	WinTop = Root.WinHeight/2 - WinHeight/2;
}

defaultproperties
{
}
