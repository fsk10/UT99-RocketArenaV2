class GameOnlyIdentifier extends UWindowWindow;

var() name RequiredGRIClass;
var UWindowMenuBarItem MenuBarItem;

function BeforePaint(Canvas C, float X, float Y)
{
	if (!GetPlayerOwner().GameReplicationInfo.isa(RequiredGRIClass))
	{
		if (MenuBarItem != None) MenuBarItem.Remove();
		HideWindow();
	}

	Super.BeforePaint(C, X, Y);
}

defaultproperties
{
      RequiredGRIClass="RAGameReplicationInfo"
      MenuBarItem=None
}
