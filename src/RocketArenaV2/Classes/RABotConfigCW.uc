class RABotConfigCW extends UMenuDialogClientWindow
	abstract;

var int Arena;

// # of Bots
var UWindowEditControl NumBotsEdit;
var localized string NumBotsText;
var localized string MinPlayersText;
var localized string NumBotsHelp;

function int GetNumBots()
{
	return int( NumBotsEdit.GetValue() );
}

function ApplyPressed(int Arena);

defaultproperties
{
      Arena=0
      NumBotsEdit=None
      NumBotsText=""
      MinPlayersText=""
      NumBotsHelp=""
}
