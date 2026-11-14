class RAGameRulesCW extends UMenuDialogClientWindow;

var int ControlOffset;

var UMenuLabelControl HeadLine;

// Arena Selector
var UWindowComboControl ArenaSelector;

// Pickup Selector
var UWindowComboControl PickupSelector;

// Damage Self
var UWindowCheckbox DamageSelfCheck;
var localized string DamageSelfCheckText;
var localized string DamageSelfCheckHelp;

// Damage Team
var UWindowCheckbox DamageTeamCheck;
var localized string DamageTeamCheckText;
var localized string DamageTeamCheckHelp;

// Round Limit
var UWindowEditControl RoundEdit;
var localized string RoundText;
var localized string RoundHelp;

// Control
var UWindowSmallButton ResetAllButton;
var localized string ResetAllText;

var UWindowSmallButton CancelButton;
var localized string CancelText;

var bool bInitialized;

function Created()
{
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos, i;
	local bool bFoundSavedArenaGameClass;
	local int MaxGames;

	Super.Created();

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	// Pickup Selector
	PickupSelector = UWindowComboControl(CreateControl(class'UWindowComboControl', CenterPos - 20, ControlOffset, CenterWidth + 40, 1));
	PickupSelector.SetText("Pickup Game:");
	PickupSelector.SetHelpText("Select the gametype to be played in the pickup map!");
	PickupSelector.SetFont(F_Normal);
	PickupSelector.SetEditable(False);
	PickupSelector.SetSelectedIndex(0);

	// Compile a list of all pickup gametypes from int files.
	MaxGames = -1;
	do {
		MaxGames++;
		class'RocketArenaGame'.default.PickupClasses[MaxGames] =  Class<ArenaGame>(DynamicLoadObject(GetPlayerOwner().GetNextInt("ArenaGame", MaxGames), class'Class'));
	} until (class'RocketArenaGame'.default.PickupClasses[MaxGames] == None);

	for (i=0;i<256;i++) {
		if (class'RocketArenaGame'.default.PickupClasses[i] == None) break;

		PickupSelector.AddItem(class'RocketArenaGame'.default.PickupClasses[i].default.GameName);

		if ( !bFoundSavedArenaGameClass && class'RocketArenaGame'.default.PickupClasses[i] == class'RocketArenaGame'.default.PreferredPickupClass )
		{
			bFoundSavedArenaGameClass = true;
			PickupSelector.SetSelectedIndex(i);
		}
	}

	ControlOffset += 25;
	// HeadLine
    HeadLine = UMenuLabelControl(CreateControl(class'UMenuLabelControl', CenterPos, ControlOffset, CenterWidth, 1));
    HeadLine.SetText("Per-Arena default settings:");
    HeadLine.SetFont(F_Bold);

	ControlOffset += 25;
	// Arena Selector
	ArenaSelector = UWindowComboControl(CreateControl(class'UWindowComboControl', CenterPos - 20, ControlOffset, CenterWidth + 40, 1));
	ArenaSelector.SetText("Arena:");
	ArenaSelector.SetHelpText("Select the arena to configure options for.");
	ArenaSelector.SetFont(F_Normal);
	ArenaSelector.SetEditable(False);
	for (i=0; i<8; i++)
		ArenaSelector.AddItem("Arena"@i);
	ArenaSelector.SetSelectedIndex(0);

	ControlOffset += 25;
	// Round Limit
	RoundEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', CenterPos + 40, ControlOffset, CenterWidth - 80, 1));
	RoundEdit.SetText(RoundText);
	RoundEdit.SetHelpText(RoundHelp);
	RoundEdit.SetFont(F_Normal);
	RoundEdit.SetNumericOnly(True);
	RoundEdit.SetMaxLength(1);
	RoundEdit.Align = TA_Left;
	RoundEdit.SetValue(string(class'WeaponInfo'.default.RoundLimit[0]));

	ControlOffset += 25;
	// Damage Self Enabled
	DamageSelfCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', ControlLeft, ControlOffset, ControlWidth, 1));
	DamageSelfCheck.SetText(DamageSelfCheckText);
	DamageSelfCheck.SetHelpText(DamageSelfCheckHelp);
	DamageSelfCheck.SetFont(F_Normal);
	DamageSelfCheck.Align = TA_Left;
	if (class'WeaponInfo'.default.SelfDamage[0] == 1)
		DamageSelfCheck.bChecked = true;

	// Damage Self Enabled
	DamageTeamCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', ControlRight, ControlOffset, ControlWidth, 1));
	DamageTeamCheck.SetText(DamageTeamCheckText);
	DamageTeamCheck.SetHelpText(DamageTeamCheckHelp);
	DamageTeamCheck.SetFont(F_Normal);
	DamageTeamCheck.Align = TA_Left;
	if (class'WeaponInfo'.default.TeamDamage[0] == 1)
		DamageTeamCheck.bChecked = true;

	ResetAllButton = UWindowSmallButton(CreateControl(class'UWindowSmallButton', WinWidth-56-60, WinHeight-24, 48, 16));
	ResetAllButton.SetText(ResetAllText);

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

	ArenaSelector.SetSize(CenterWidth+40, 1);
	ArenaSelector.WinLeft = CenterPos-20;
	ArenaSelector.EditBoxWidth = 120;

	RoundEdit.SetSize(CenterWidth - 80, 1);
	RoundEdit.WinLeft = CenterPos + 40;
	RoundEdit.EditBoxWidth = 25;

	PickupSelector.SetSize(CenterWidth+40, 1);
	PickupSelector.WinLeft = CenterPos-20;
	PickupSelector.EditBoxWidth = 120;

	DamageSelfCheck.SetSize(ControlWidth, 1);
	DamageSelfCheck.WinLeft = ControlLeft;

	DamageTeamCheck.SetSize(ControlWidth, 1);
	DamageTeamCheck.WinLeft = ControlRight;

	ResetAllButton.WinLeft = WinWidth-52-60;
	ResetAllButton.WinTop = WinHeight-20;

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
			case PickupSelector:
				PickupChanged();
				break;
			case DamageSelfCheck:
				DamageSelfChecked();
				break;
			case DamageTeamCheck:
				DamageTeamChecked();
				break;
			case RoundEdit:
				RoundEdited();
				break;
		}
		break;
	case DE_Click:
		switch (C)
		{
			case ResetAllButton:
				ResetAllPressed();
				break;
			case CancelButton:
				CancelPressed();
				break;
		}
		break;
	}
}

function PickupChanged()
{
	if (!bInitialized)
		return;

	class'RocketArenaGame'.default.PreferredPickupClass = class'RocketArenaGame'.default.PickupClasses[PickupSelector.GetSelectedIndex()];
	class'RocketArenaGame'.static.StaticSaveConfig();
}

function ArenaChanged()
{
	if (!bInitialized)
		return;

	if (class'WeaponInfo'.default.SelfDamage[ArenaSelector.GetSelectedIndex()] == 1)
		DamageSelfCheck.bChecked = true;
	else
		DamageSelfCheck.bChecked = false;

	if (class'WeaponInfo'.default.TeamDamage[ArenaSelector.GetSelectedIndex()] == 1)
		DamageTeamCheck.bChecked = true;
	else
		DamageTeamCheck.bChecked = false;
}

function DamageSelfChecked()
{
	if (!bInitialized)
		return;

	if (DamageSelfCheck.bChecked)
		class'WeaponInfo'.default.SelfDamage[ArenaSelector.GetSelectedIndex()] = 1;
	else
		class'WeaponInfo'.default.SelfDamage[ArenaSelector.GetSelectedIndex()] = 0;

	class'WeaponInfo'.static.StaticSaveConfig();
}

function DamageTeamChecked()
{
	if (!bInitialized)
		return;

	if (DamageTeamCheck.bChecked)
		class'WeaponInfo'.default.TeamDamage[ArenaSelector.GetSelectedIndex()] = 1;
	else
		class'WeaponInfo'.default.TeamDamage[ArenaSelector.GetSelectedIndex()] = 0;

	class'WeaponInfo'.static.StaticSaveConfig();
}

function RoundEdited()
{
	if (!bInitialized)
		return;

	class'WeaponInfo'.default.RoundLimit[ArenaSelector.GetSelectedIndex()] = int(RoundEdit.GetValue());
	class'WeaponInfo'.static.StaticSaveConfig();
}

function ResetAllPressed()
{
	local int i;

	for (i=0; i<8; i++)
	{
		class'WeaponInfo'.default.SelfDamage[i] = 0;
		class'WeaponInfo'.default.TeamDamage[i] = 0;
	}

	DamageSelfCheck.bChecked = false;
	DamageTeamCheck.bChecked = false;
	class'WeaponInfo'.static.StaticSaveConfig();
}

function CancelPressed()
{
	Close();
}

defaultproperties
{
      ControlOffset=25
      HeadLine=None
      ArenaSelector=None
      PickupSelector=None
      DamageSelfCheck=None
      DamageSelfCheckText="Damage Self:"
      DamageSelfCheckHelp="If turned on, players can damage themselves."
      DamageTeamCheck=None
      DamageTeamCheckText="Damage Team:"
      DamageTeamCheckHelp="If turned on, players can damage their teammates."
      RoundEdit=None
      RoundText="Round Limit:"
      RoundHelp="Enter the number of rounds per match in this arena."
      ResetAllButton=None
      ResetAllText="Reset All"
      CancelButton=None
      CancelText="Done"
      bInitialized=False
}
