class RAAdminBotCW extends UMenuDialogClientWindow;

var int ControlOffset;

// Arena Selector
var UWindowComboControl ArenaSelector;

// Skill Level
var UWindowComboControl SkillCombo;
var localized string SkillText;
var localized string Skills[8];
var localized string SkillHelp;

// Config windows
var UMenuLabelControl HeadLine;
var RABotConfigCW ConfigWindow;

// Control
var UWindowSmallButton ApplyButton;
var localized string ApplyText;

var UWindowSmallButton CancelButton;
var localized string CancelText;

var bool bInitialized;

function Created()
{
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos, i;
	local Class<ChallengeBotInfo> BotConfig;
	local RAGameReplicationInfo RAGRI;
	local RAReplicationInfo RA;

	RAGRI = RAGameReplicationInfo(GetPlayerOwner().GameReplicationInfo);
	class'RATools'.static.GetRepInfo(GetPlayerOwner(), RAGRI, RA);

	Super.Created();

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	// Skill Level
	SkillCombo = UWindowComboControl(CreateControl(class'UWindowComboControl', ControlLeft, ControlOffset, ControlWidth, 1));
	SkillCombo.SetText(SkillText);
	SkillCombo.SetHelpText(SkillHelp);
	SkillCombo.SetFont(F_Normal);
	SkillCombo.SetEditable(False);
	for (i=0; i<8; i++)
		SkillCombo.AddItem(Skills[i]);
	BotConfig = class'DeathMatchPlus'.default.BotConfigType;
	SkillCombo.SetSelectedIndex(BotConfig.Default.Difficulty);

	ControlOffset += 25;
	ArenaSelector = UWindowComboControl(CreateControl(class'UWindowComboControl', ControlLeft, ControlOffset, ControlWidth, 1));
	ArenaSelector.SetText("Arena:");
	ArenaSelector.SetHelpText("Select the arena to configure bots for.");
	ArenaSelector.SetFont(F_Normal);
	ArenaSelector.SetEditable(False);
	for (i=0; i<8; i++)
	{
		if (RAGRI.ArenaGames[i] != None)
			ArenaSelector.AddItem(RAGRI.ArenaInfo.ArenaNames[i] $ " (" $ RAGRI.ArenaGames[i].GameName $ ")");
	}
	ArenaSelector.SetSelectedIndex(RA.Arena);

	ControlOffset += 25;
	HeadLine = UMenuLabelControl(CreateControl(class'UMenuLabelControl', CenterPos, ControlOffset, WinWidth - CenterPos, 1));
	HeadLine.SetText(RAGRI.ArenaInfo.ArenaNames[RA.Arena] $ " (" $ RAGRI.ArenaGames[RA.Arena].GameName $ ")");
	HeadLine.SetFont(F_Bold);

	ControlOffset += 10;
	ConfigWindow = RABotConfigCW(CreateWindow(RAGRI.ArenaGames[RA.Arena].BotConfigClass, CenterPos, ControlOffset, CenterWidth, 1));

	ApplyButton = UWindowSmallButton(CreateControl(class'UWindowSmallButton', WinWidth-56-60, WinHeight-24, 48, 16));
	ApplyButton.SetText(ApplyText);

	CancelButton = UWindowSmallButton(CreateControl(class'UWindowSmallButton', WinWidth-56, WinHeight-24, 48, 16));
	CancelButton.SetText(CancelText);

	bInitialized = true;
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

	ArenaSelector.SetSize(CenterWidth, 1);
	ArenaSelector.WinLeft = CenterPos;
	ArenaSelector.EditBoxWidth = 120;

	SkillCombo.SetSize(CenterWidth, 1);
	SkillCombo.WinLeft = CenterPos;
	SkillCombo.EditBoxWidth = 120;

	ApplyButton.WinLeft = WinWidth-52-60;
	ApplyButton.WinTop = WinHeight-20;

	CancelButton.WinLeft = WinWidth-52;
	CancelButton.WinTop = WinHeight-20;
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C, E);

	switch(E)
	{
	case DE_Change:
		switch (C)
		{
			case ArenaSelector:
				ArenaChanged();
				break;
		}
		break;
	case DE_Click:
		switch (C)
		{
			case ApplyButton:
				ApplyPressed();
				break;
			case CancelButton:
				CancelPressed();
				break;
		}
		break;
	}
}

function ArenaChanged()
{
	local RAGameReplicationInfo RAGRI;
	local int ArenaNum;
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos;

	if (!bInitialized)
		return;

	RAGRI = RAGameReplicationInfo(GetPlayerOwner().GameReplicationInfo);

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	ConfigWindow.HideWindow();

	ArenaNum = ArenaSelector.GetSelectedIndex();
	HeadLine.SetText(RAGRI.ArenaInfo.ArenaNames[ArenaNum] $ " (" $ RAGRI.ArenaGames[ArenaNum].GameName $ ")");

	ConfigWindow = RABotConfigCW(CreateWindow(RAGRI.ArenaGames[ArenaNum].BotConfigClass, CenterPos, ControlOffset, CenterWidth, 1));
}

function ApplyPressed()
{
	local RAReplicationInfo RA;
	local RAGameReplicationInfo RAGRI;

	// Update current difficulty.
	RAGRI = RAGameReplicationInfo(GetPlayerOwner().GameReplicationInfo);
	class'RATools'.static.GetRepInfo(GetPlayerOwner(), RAGRI, RA);
	RA.SetBotDifficulty( SkillCombo.GetSelectedIndex() );

	ConfigWindow.ApplyPressed(ArenaSelector.GetSelectedIndex());
}

function CancelPressed()
{
	Close();
}

defaultproperties
{
      ControlOffset=25
      ArenaSelector=None
      SkillCombo=None
      SkillText="Skill Level:"
      Skills(0)="Novice"
      Skills(1)="Average"
      Skills(2)="Experienced"
      Skills(3)="Skilled"
      Skills(4)="Adept"
      Skills(5)="Masterful"
      Skills(6)="Inhuman"
      Skills(7)="Godlike"
      SkillHelp="Use this dropdown to change the bot skill level."
      HeadLine=None
      ConfigWindow=None
      ApplyButton=None
      ApplyText="Apply"
      CancelButton=None
      CancelText="Close"
      bInitialized=False
}
