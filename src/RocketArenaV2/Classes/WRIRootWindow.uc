class WRIRootWindow extends UMenuRootWindow;

function Created()
{
	Super(UWindowRootWindow).Created();

	StatusBar = UMenuStatusBar(CreateWindow(class'UMenuStatusBar', 0, 0, 50, 16));
	StatusBar.HideWindow();

	MenuBar = UMenuMenuBar(CreateWindow(class'WRIMenuBar', 50, 0, 500, 16));

	BetaFont = Font(DynamicLoadObject("UWindowFonts.UTFont40", class'Font'));
	Resized();
}

defaultproperties
{
}
