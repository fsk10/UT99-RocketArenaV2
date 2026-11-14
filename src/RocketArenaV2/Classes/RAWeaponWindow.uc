class RAWeaponWindow extends UMenuFramedWindow;

function BeginPlay()
{
	Super.BeginPlay();

	ClientClass = class'RAWeaponCW';
	WindowTitle = "RocketArena - Weapon Configuration";
}

function Created()
{
	bStatusBar = false;
	bSizable = false;

	Super.Created();

	SetSize(240, 205);
	WinLeft = Root.WinWidth/2 - WinWidth/2;
	WinTop = Root.WinHeight/2 - WinHeight/2;
}

defaultproperties
{
}
