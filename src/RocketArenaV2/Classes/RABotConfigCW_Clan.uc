class RABotConfigCW_Clan extends RABotConfigCW;

var int ControlOffset;

function Created()
{
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos, BotCount;
	local RAReplicationInfo RepInfo;

	Super.Created();

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	// # of Bots
	NumBotsEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', CenterPos, ControlOffset, CenterWidth, 1));
	NumBotsEdit.SetHelpText(NumBotsHelp);
	NumBotsEdit.SetFont(F_Normal);
	NumBotsEdit.SetNumericOnly(True);
	NumBotsEdit.SetMaxLength(2);
	NumBotsEdit.Align = TA_Left;

	foreach GetPlayerOwner().AllActors(class'RAReplicationInfo', RepInfo)
	{
		if ( (RepInfo.OwnerPRI.bIsABot) && (RepInfo.Arena == RAAdminBotCW(ParentWindow).ArenaSelector.GetSelectedIndex()) )
			BotCount++;
	}

	NumBotsEdit.SetValue(string(BotCount));
	NumBotsEdit.SetText(NumBotsText);

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

	NumBotsEdit.SetSize(CenterWidth, 1);
	NumBotsEdit.WinLeft = CenterPos;
	NumBotsEdit.EditBoxWidth = 20;
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
	}
}

function NumBotsChanged()
{
	if (int(NumBotsEdit.GetValue()) > 15)
		NumBotsEdit.SetValue("15");
}

function ApplyPressed(int Arena)
{
	local RAReplicationInfo RA;
	local RAGameReplicationInfo RAGRI;

	// Update current difficulty.
	RAGRI = RAGameReplicationInfo(GetPlayerOwner().GameReplicationInfo);
	class'RATools'.static.GetRepInfo(GetPlayerOwner(), RAGRI, RA);
	RA.SetBotCount( GetNumBots(), Arena );
}

defaultproperties
{
      ControlOffset=10
      NumBotsText="Number of Bots:"
      MinPlayersText="Min # of Players:"
      NumBotsHelp="This is the number of bots that you will play against."
}
