class RAWeaponCW extends UMenuDialogClientWindow;

var int ControlOffset;

var UMenuLabelControl HeadLine;

// Arena Selector
var UWindowComboControl ArenaSelector;

// Weapon Selector
var UWindowComboControl WeaponSelector;
var string WeaponNames[11];

// Weapon Enabled
var UWindowCheckbox WeaponCheck;
var localized string WeaponCheckText;
var localized string WeaponCheckHelp;

// Weapon Ammo
var UWindowEditControl WeaponAmmoEdit;
var localized string WeaponAmmoText;
var localized string WeaponAmmoHelp;

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

	Super.Created();

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

    HeadLine = UMenuLabelControl(CreateControl(class'UMenuLabelControl', CenterPos, ControlOffset, CenterWidth, 1));
    HeadLine.SetText("Per-Arena default settings:");
    HeadLine.SetFont(F_Bold);

	ControlOffset += 25;
	ArenaSelector = UWindowComboControl(CreateControl(class'UWindowComboControl', ControlLeft, ControlOffset, ControlWidth, 1));
	ArenaSelector.SetText("Arena:");
	ArenaSelector.SetHelpText("Select the arena to configure bots for.");
	ArenaSelector.SetFont(F_Normal);
	ArenaSelector.SetEditable(False);
	for (i=0; i<8; i++)
		ArenaSelector.AddItem("Arena"@i);
	ArenaSelector.SetSelectedIndex(0);

	ControlOffset += 25;
	// Weapon Selector
	WeaponSelector = UWindowComboControl(CreateControl(class'UWindowComboControl', ControlLeft, ControlOffset, ControlWidth, 1));
	WeaponSelector.SetText("Weapon:");
	WeaponSelector.SetHelpText("Select the weapon to configure.");
	WeaponSelector.SetFont(F_Normal);
	WeaponSelector.SetEditable(False);
	for (i=0; i<11; i++)
		WeaponSelector.AddItem(WeaponNames[i]);
	WeaponSelector.SetSelectedIndex(0);

	ControlOffset += 25;
	// Weapon Enabled
	WeaponCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', CenterPos + 40, ControlOffset, CenterWidth - 80, 1));
	WeaponCheck.SetText(WeaponCheckText);
	WeaponCheck.SetHelpText(WeaponCheckHelp);
	WeaponCheck.SetFont(F_Normal);
	WeaponCheck.Align = TA_Left;
	if (class'WeaponInfo'.default.UseImpactHammer[0] == 1)
		WeaponCheck.bChecked = true;

	ControlOffset += 25;
	// Weapon Ammo
	WeaponAmmoEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', CenterPos + 40, ControlOffset, CenterWidth - 80, 1));
	WeaponAmmoEdit.SetText(WeaponAmmoText);
	WeaponAmmoEdit.SetHelpText(WeaponAmmoHelp);
	WeaponAmmoEdit.SetFont(F_Normal);
	WeaponAmmoEdit.SetNumericOnly(True);
	WeaponAmmoEdit.SetMaxLength(3);
	WeaponAmmoEdit.Align = TA_Left;
	WeaponAmmoEdit.SetValue("-1");

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

	ArenaSelector.SetSize(CenterWidth, 1);
	ArenaSelector.WinLeft = CenterPos;
	ArenaSelector.EditBoxWidth = 120;

	WeaponSelector.SetSize(CenterWidth, 1);
	WeaponSelector.WinLeft = CenterPos;
	WeaponSelector.EditBoxWidth = 120;

	WeaponCheck.SetSize(CenterWidth - 80, 1);
	WeaponCheck.WinLeft = CenterPos + 40;

	WeaponAmmoEdit.SetSize(CenterWidth - 80, 1);
	WeaponAmmoEdit.WinLeft = CenterPos + 40;
	WeaponAmmoEdit.EditBoxWidth = 20;

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
			case WeaponSelector:
				WeaponChanged();
				break;
			case WeaponCheck:
				WeaponChecked();
				break;
			case WeaponAmmoEdit:
				AmmoChanged();
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

function ArenaChanged()
{
	if (!bInitialized)
		return;

	WeaponChanged();
}

function WeaponChanged()
{
	local int Arena;

	if (!bInitialized)
		return;

	bInitialized = false;

	Arena = ArenaSelector.GetSelectedIndex();
	switch (WeaponSelector.GetSelectedIndex())
	{
		case 0:
			if (class'WeaponInfo'.default.UseImpactHammer[Arena] == 0)
				WeaponCheck.bChecked = false;
			else
				WeaponCheck.bChecked = true;
			WeaponAmmoEdit.SetValue("-1");
			break;
		case 1:
			if (class'WeaponInfo'.default.UseEnforcer[Arena] == 0)
				WeaponCheck.bChecked = false;
			else
				WeaponCheck.bChecked = true;
			WeaponAmmoEdit.SetValue(string(class'WeaponInfo'.default.EnforcerAmmo[Arena]));
			break;
		case 2:
			if (class'WeaponInfo'.default.UseShockRifle[Arena] == 0)
				WeaponCheck.bChecked = false;
			else
				WeaponCheck.bChecked = true;
			WeaponAmmoEdit.SetValue(string(class'WeaponInfo'.default.ShockRifleAmmo[Arena]));
			break;
		case 3:
			if (class'WeaponInfo'.default.UseBioRifle[Arena] == 0)
				WeaponCheck.bChecked = false;
			else
				WeaponCheck.bChecked = true;
			WeaponAmmoEdit.SetValue(string(class'WeaponInfo'.default.BioRifleAmmo[Arena]));
			break;
		case 4:
			if (class'WeaponInfo'.default.UseRipper[Arena] == 0)
				WeaponCheck.bChecked = false;
			else
				WeaponCheck.bChecked = true;
			WeaponAmmoEdit.SetValue(string(class'WeaponInfo'.default.RipperAmmo[Arena]));
			break;
		case 5:
			if (class'WeaponInfo'.default.UseFlakCannon[Arena] == 0)
				WeaponCheck.bChecked = false;
			else
				WeaponCheck.bChecked = true;
			WeaponAmmoEdit.SetValue(string(class'WeaponInfo'.default.FlakCannonAmmo[Arena]));
			break;
		case 6:
			if (class'WeaponInfo'.default.UseSniperRifle[Arena] == 0)
				WeaponCheck.bChecked = false;
			else
				WeaponCheck.bChecked = true;
			WeaponAmmoEdit.SetValue(string(class'WeaponInfo'.default.SniperRifleAmmo[Arena]));
			break;
		case 7:
			if (class'WeaponInfo'.default.UsePulseGun[Arena] == 0)
				WeaponCheck.bChecked = false;
			else
				WeaponCheck.bChecked = true;
			WeaponAmmoEdit.SetValue(string(class'WeaponInfo'.default.PulseGunAmmo[Arena]));
			break;
		case 8:
			if (class'WeaponInfo'.default.UseMinigun[Arena] == 0)
				WeaponCheck.bChecked = false;
			else
				WeaponCheck.bChecked = true;
			WeaponAmmoEdit.SetValue(string(class'WeaponInfo'.default.MinigunAmmo[Arena]));
			break;
		case 9:
			if (class'WeaponInfo'.default.UseRocketLauncher[Arena] == 0)
				WeaponCheck.bChecked = false;
			else
				WeaponCheck.bChecked = true;
			WeaponAmmoEdit.SetValue(string(class'WeaponInfo'.default.RocketLauncherAmmo[Arena]));
			break;
		case 10:
			if (class'WeaponInfo'.default.UseArmor[Arena] == 0)
				WeaponCheck.bChecked = false;
			else
				WeaponCheck.bChecked = true;
			WeaponAmmoEdit.SetValue(string(class'WeaponInfo'.default.ArmorAmount[Arena]));
			break;
	}

	bInitialized = true;
}

function WeaponChecked()
{
	if (!bInitialized)
		return;

	ToggleWeapon( ArenaSelector.GetSelectedIndex(), WeaponSelector.GetSelectedIndex() );
}

function ToggleWeapon(int Arena, int WeaponOffset)
{
	switch (WeaponOffset)
	{
		case 0:
			if (class'WeaponInfo'.default.UseImpactHammer[Arena] == 1)
				class'WeaponInfo'.default.UseImpactHammer[Arena] = 0;
			else
				class'WeaponInfo'.default.UseImpactHammer[Arena] = 1;
			break;
		case 1:
			if (class'WeaponInfo'.default.UseEnforcer[Arena] == 1)
				class'WeaponInfo'.default.UseEnforcer[Arena] = 0;
			else
				class'WeaponInfo'.default.UseEnforcer[Arena] = 1;
			break;
		case 2:
			if (class'WeaponInfo'.default.UseShockRifle[Arena] == 1)
				class'WeaponInfo'.default.UseShockRifle[Arena] = 0;
			else
				class'WeaponInfo'.default.UseShockRifle[Arena] = 1;
			break;
		case 3:
			if (class'WeaponInfo'.default.UseBioRifle[Arena] == 1)
				class'WeaponInfo'.default.UseBioRifle[Arena] = 0;
			else
				class'WeaponInfo'.default.UseBioRifle[Arena] = 1;
			break;
		case 4:
			if (class'WeaponInfo'.default.UseRipper[Arena] == 1)
				class'WeaponInfo'.default.UseRipper[Arena] = 0;
			else
				class'WeaponInfo'.default.UseRipper[Arena] = 1;
			break;
		case 5:
			if (class'WeaponInfo'.default.UseFlakCannon[Arena] == 1)
				class'WeaponInfo'.default.UseFlakCannon[Arena] = 0;
			else
				class'WeaponInfo'.default.UseFlakCannon[Arena] = 1;
			break;
		case 6:
			if (class'WeaponInfo'.default.UseSniperRifle[Arena] == 1)
				class'WeaponInfo'.default.UseSniperRifle[Arena] = 0;
			else
				class'WeaponInfo'.default.UseSniperRifle[Arena] = 1;
			break;
		case 7:
			if (class'WeaponInfo'.default.UsePulseGun[Arena] == 1)
				class'WeaponInfo'.default.UsePulseGun[Arena] = 0;
			else
				class'WeaponInfo'.default.UsePulseGun[Arena] = 1;
			break;
		case 8:
			if (class'WeaponInfo'.default.UseMinigun[Arena] == 1)
				class'WeaponInfo'.default.UseMinigun[Arena] = 0;
			else
				class'WeaponInfo'.default.UseMinigun[Arena] = 1;
			break;
		case 9:
			if (class'WeaponInfo'.default.UseRocketLauncher[Arena] == 1)
				class'WeaponInfo'.default.UseRocketLauncher[Arena] = 0;
			else
				class'WeaponInfo'.default.UseRocketLauncher[Arena] = 1;
			break;
		case 10:
			if (class'WeaponInfo'.default.UseArmor[Arena] == 1)
				class'WeaponInfo'.default.UseArmor[Arena] = 0;
			else
				class'WeaponInfo'.default.UseArmor[Arena] = 1;
			break;
	}

	class'WeaponInfo'.static.StaticSaveConfig();
}

function AmmoChanged()
{
	if (!bInitialized)
		return;

	ChangeWeaponAmmo( ArenaSelector.GetSelectedIndex(), WeaponSelector.GetSelectedIndex(), int(WeaponAmmoEdit.GetValue()) );
}

function ChangeWeaponAmmo(int Arena, int WeaponOffset, int NewAmmoCount)
{
	switch (WeaponOffset)
	{
		case 0:
			break;
		case 1:
			class'WeaponInfo'.default.EnforcerAmmo[Arena] = NewAmmoCount;
			break;
		case 2:
			class'WeaponInfo'.default.ShockRifleAmmo[Arena] = NewAmmoCount;
			break;
		case 3:
			class'WeaponInfo'.default.BioRifleAmmo[Arena] = NewAmmoCount;
			break;
		case 4:
			class'WeaponInfo'.default.RipperAmmo[Arena] = NewAmmoCount;
			break;
		case 5:
			class'WeaponInfo'.default.FlakCannonAmmo[Arena] = NewAmmoCount;
			break;
		case 6:
			class'WeaponInfo'.default.SniperRifleAmmo[Arena] = NewAmmoCount;
			break;
		case 7:
			class'WeaponInfo'.default.PulseGunAmmo[Arena] = NewAmmoCount;
			break;
		case 8:
			class'WeaponInfo'.default.MinigunAmmo[Arena] = NewAmmoCount;
			break;
		case 9:
			class'WeaponInfo'.default.RocketLauncherAmmo[Arena] = NewAmmoCount;
			break;
		case 10:
			class'WeaponInfo'.default.ArmorAmount[Arena] = NewAmmoCount;
			break;
	}

	class'WeaponInfo'.static.StaticSaveConfig();
}

function ResetAllPressed()
{
	local int i;

	for (i=0; i<8; i++)
	{
		class'WeaponInfo'.default.UseImpactHammer[i] = 1;

		class'WeaponInfo'.default.UseEnforcer[i] = 1;
		class'WeaponInfo'.default.EnforcerAmmo[i] = -1;

		class'WeaponInfo'.default.UseShockRifle[i] = 1;
		class'WeaponInfo'.default.ShockRifleAmmo[i] = -1;

		class'WeaponInfo'.default.UseBioRifle[i] = 1;
		class'WeaponInfo'.default.BioRifleAmmo[i] = -1;

		class'WeaponInfo'.default.UseRipper[i] = 1;
		class'WeaponInfo'.default.RipperAmmo[i] = -1;

		class'WeaponInfo'.default.UseFlakCannon[i] = 1;
		class'WeaponInfo'.default.FlakCannonAmmo[i] = -1;

		class'WeaponInfo'.default.UseSniperRifle[i] = 1;
		class'WeaponInfo'.default.SniperRifleAmmo[i] = -1;

		class'WeaponInfo'.default.UsePulseGun[i] = 1;
		class'WeaponInfo'.default.PulseGunAmmo[i] = -1;

		class'WeaponInfo'.default.UseMinigun[i] = 1;
		class'WeaponInfo'.default.MinigunAmmo[i] = -1;

		class'WeaponInfo'.default.UseRocketLauncher[i] = 1;
		class'WeaponInfo'.default.RocketLauncherAmmo[i] = -1;

		class'WeaponInfo'.default.UseArmor[i] = 1;
		class'WeaponInfo'.default.ArmorAmount[i] = -1;
	}
	WeaponCheck.bChecked = true;
	WeaponAmmoEdit.SetValue("-1");
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
      WeaponSelector=None
      WeaponNames(0)="Impact Hammer"
      WeaponNames(1)="Enforcer"
      WeaponNames(2)="Shock Rifle"
      WeaponNames(3)="Bio Rifle"
      WeaponNames(4)="Ripper"
      WeaponNames(5)="Flak Cannon"
      WeaponNames(6)="Sniper Rifle"
      WeaponNames(7)="Pulse Gun"
      WeaponNames(8)="Minigun"
      WeaponNames(9)="Rocket Launcher"
      WeaponNames(10)="Armor"
      WeaponCheck=None
      WeaponCheckText="Enabled"
      WeaponCheckHelp="Check to enable or disable the weapon."
      WeaponAmmoEdit=None
      WeaponAmmoText="Initial Ammo"
      WeaponAmmoHelp="Change to modify the initial ammo amount for this weapon. If you specify -1, the UT default will be used."
      ResetAllButton=None
      ResetAllText="Reset All"
      CancelButton=None
      CancelText="Done"
      bInitialized=False
}
