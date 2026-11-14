class RABotTeamModifyCW extends UMenuDialogClientWindow;

var int ControlOffset;

// Config windows
var UMenuLabelControl HeadLine;
var UMenuLabelControl HeadLine2;

var UWindowComboControl TeamCombo;
var localized string TeamText;
var localized string TeamHelp;

var UWindowComboControl Bot1Combo;
var localized string Bot1Text;

var UWindowComboControl Bot2Combo;
var localized string Bot2Text;

// Control
var UWindowSmallButton DoneButton;
var localized string DoneText;

var bool bInitialized;

function Created()
{
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos;
	local RAGameReplicationInfo RAGRI;

	RAGRI = RAGameReplicationInfo(GetPlayerOwner().GameReplicationInfo);

	Super.Created();

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	HeadLine = UMenuLabelControl(CreateControl(class'UMenuLabelControl', CenterPos, ControlOffset, WinWidth - CenterPos, 1));
	HeadLine.SetText("Modify Bot Teams");
	HeadLine.SetFont(F_Bold);

	ControlOffset += 25;
	TeamCombo = UWindowComboControl(CreateControl(class'UWindowComboControl', CenterPos, ControlOffset, CenterWidth, 1));
	TeamCombo.SetButtons(True);
	TeamCombo.SetText(TeamText);
	TeamCombo.SetFont(F_Normal);
	TeamCombo.SetEditable(True);

	ControlOffset += 25;
	HeadLine2 = UMenuLabelControl(CreateControl(class'UMenuLabelControl', CenterPos, ControlOffset, CenterWidth, 1));
	HeadLine2.SetText("Team Members: 2");
	HeadLine2.SetFont(F_Bold);

	ControlOffset += 15;
	Bot1Combo = UWindowComboControl(CreateControl(class'UWindowComboControl', CenterPos, ControlOffset, CenterWidth, 1));
	Bot1Combo.SetButtons(True);
	Bot1Combo.SetText(Bot1Text);
	Bot1Combo.SetFont(F_Normal);
	Bot1Combo.SetEditable(False);

	ControlOffset += 15;
	Bot2Combo = UWindowComboControl(CreateControl(class'UWindowComboControl', CenterPos, ControlOffset, CenterWidth, 1));
	Bot2Combo.SetButtons(True);
	Bot2Combo.SetText(Bot2Text);
	Bot2Combo.SetFont(F_Normal);
	Bot2Combo.SetEditable(False);

	DoneButton = UWindowSmallButton(CreateControl(class'UWindowSmallButton', WinWidth-56, WinHeight-24, 48, 16));
	DoneButton.SetText(DoneText);

	bInitialized = true;
}

function Setup(int TeamSize)
{
	local int i;

	HeadLine2.SetText("Team Members:"@TeamSize);
	if (TeamSize == 1)
		Bot2Combo.HideWindow();

	for (i=0; i<32; i++)
	{
		if (class'ChallengeBotInfo'.default.BotNames[i] != "")
		{
			Bot1Combo.AddItem(class'ChallengeBotInfo'.default.BotNames[i]);
			Bot1Combo.SetSelectedIndex(0);

			Bot2Combo.AddItem(class'ChallengeBotInfo'.default.BotNames[i]);
			Bot2Combo.SetSelectedIndex(0);
		}
	}
}

function Resized()
{
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos;

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	HeadLine.WinWidth = WinWidth - CenterPos;
	HeadLine2.WinLeft = CenterPos;
	HeadLine2.WinWidth = CenterWidth;

	DoneButton.WinLeft = WinWidth-52;
	DoneButton.WinTop = WinHeight-20;

	TeamCombo.SetSize(CenterWidth, 1);
	TeamCombo.WinLeft = CenterPos;
	TeamCombo.EditBoxWidth = 130;

	Bot1Combo.SetSize(CenterWidth, 1);
	Bot1Combo.WinLeft = CenterPos;
	Bot1Combo.EditBoxWidth = 130;

	Bot2Combo.SetSize(CenterWidth, 1);
	Bot2Combo.WinLeft = CenterPos;
	Bot2Combo.EditBoxWidth = 130;
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C, E);

	switch(E)
	{
	case DE_Click:
		switch (C)
		{
			case DoneButton:
				DonePressed();
				break;
		}
		break;
	}
}

function DonePressed()
{
	Close();
}

defaultproperties
{
      ControlOffset=25
      HeadLine=None
      HeadLine2=None
      TeamCombo=None
      TeamText="Team:"
      TeamHelp=""
      Bot1Combo=None
      Bot1Text="Bot1:"
      Bot2Combo=None
      Bot2Text="Bot2:"
      DoneButton=None
      DoneText="Done"
      bInitialized=False
}
