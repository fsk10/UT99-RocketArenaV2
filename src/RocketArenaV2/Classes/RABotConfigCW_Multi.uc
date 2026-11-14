class RABotConfigCW_Multi extends RABotConfigCW;

var int ControlOffset;

var UWindowSmallButton EditButton;
var localized string EditText;

var RABotTeamModifyWindow TeamModify;

function Created()
{
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos, BotCount;
	local ArenaGame_Multi Game;
	local RATeamInfo Team;

	Super.Created();

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	// # of Bot Teams
	NumBotsEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', CenterPos, ControlOffset, CenterWidth - 52, 1));
	NumBotsEdit.SetHelpText(NumBotsHelp);
	NumBotsEdit.SetFont(F_Normal);
	NumBotsEdit.SetNumericOnly(True);
	NumBotsEdit.SetMaxLength(1);
	NumBotsEdit.Align = TA_Left;

	Game = ArenaGame_Multi(RAGameReplicationInfo(GetPlayerOwner().GameReplicationInfo).ArenaGames[RAAdminBotCW(ParentWindow).ArenaSelector.GetSelectedIndex()]);
	for (Team=Game.TeamList; Team!=None; Team=Team.NextTeam)
	{
		if (Team.bBotTeam)
			BotCount++;
	}
	NumBotsEdit.SetValue(string(BotCount));
	NumBotsEdit.SetText(NumBotsText);

	EditButton = UWindowSmallButton(CreateControl(class'UWindowSmallButton', CenterPos + CenterWidth - 48, ControlOffset, 48, 16));
	EditButton.SetText(EditText);
	EditButton.bDisabled = true;

	WinLeft = ParentWindow.WinLeft;
	WinWidth = ParentWindow.WinWidth;

	WinHeight = 35;
}

function Paint(Canvas C, float X, float Y)
{
}

function BeforePaint(Canvas C, float X, float Y)
{
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos;

	WinLeft = ParentWindow.WinLeft;
	WinWidth = ParentWindow.WinWidth;

	WinHeight = 35;

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	NumBotsEdit.SetSize(CenterWidth - 52, 1);
	NumBotsEdit.WinLeft = CenterPos;
	NumBotsEdit.EditBoxWidth = 20;

	EditButton.WinLeft = CenterPos + CenterWidth - 48;
	EditButton.WinTop = ControlOffset;
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C, E);

	switch(E)
	{
	case DE_Change:
		switch (C)
		{
			case NumBotsEdit:
				NumBotsChanged();
				break;
		}
		break;
	case DE_Click:
		switch (C)
		{
			case EditButton:
				if (!EditButton.bDisabled)
					EditPressed();
				break;
		}
		break;
	}
}

function EditPressed()
{
	local int Arena, TeamSize;
	local ArenaInfo AI;

	Arena = RAAdminBotCW(ParentWindow).ArenaSelector.GetSelectedIndex();
	foreach GetPlayerOwner().AllActors( class'ArenaInfo', AI )
	{
		TeamSize = AI.ArenaTeamSize[Arena];
	}

	TeamModify = RABotTeamModifyWindow(Root.CreateWindow(class'RABotTeamModifyWindow', 100, 100, 100, 100, Self));
	TeamModify.Setup(TeamSize);
}

function ApplyPressed(int Arena)
{
	local RAReplicationInfo RA;
	local RAGameReplicationInfo RAGRI;

	// Update current difficulty.
	RAGRI = RAGameReplicationInfo(GetPlayerOwner().GameReplicationInfo);
	class'RATools'.static.GetRepInfo(GetPlayerOwner(), RAGRI, RA);
	RA.SetBotTeams(GetNumBots(), Arena);
}

function NumBotsChanged()
{
	if (int(NumBotsEdit.GetValue()) > 6)
		NumBotsEdit.SetValue("6");
}

defaultproperties
{
      ControlOffset=10
      EditButton=None
      EditText="Modify"
      TeamModify=None
      NumBotsText="Bot Teams:"
      NumBotsHelp="This is the number of bot teams in this arena."
}
