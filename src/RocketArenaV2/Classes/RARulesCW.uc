class RARulesCW extends UMenuPageWindow;

var UMenuBotmatchClientWindow BotmatchParent;

// Games Rules Button
var UWindowSmallButton GameRulesBtn;
var localized string GameRulesBtnText;
var localized string GameRulesBtnHelp;

// Weapon Button
var UWindowSmallButton WeaponBtn;
var localized string WeaponBtnText;
var localized string WeaponBtnHelp;

// Max Players
var UWindowEditControl MaxPlayersEdit;
var localized string MaxPlayersText;
var localized string MaxPlayersHelp;

// Time Limit
var UWindowEditControl TimeEdit;
var localized string TimeText;
var localized string TimeHelp;

// Force 1on1
var UWindowCheckbox Force1on1Check;
var localized string Force1on1CheckText;
var localized string Force1on1CheckHelp;

// Force Instant Rocket Fire
var UWindowCheckbox InstantRocketCheck;
var localized string InstantRocketCheckText;
var localized string InstantRocketCheckHelp;

// Use Bouncy Rocket Height
var UWindowHSliderControl BouncyHeightSlider;
var localized string BouncyHeightSliderText;
var localized string BouncyHeightSliderHelp;

// Prevent Falling Damage
var UWindowCheckbox FallingDamageCheck;
var localized string FallingDamageCheckText;
var localized string FallingDamageCheckHelp;

// Allow Spectator Global Speech
var UWindowCheckbox SpecSpeechCheck;
var localized string SpecSpeechCheckText;
var localized string SpecSpeechCheckHelp;

var int ControlOffset;

var bool Initialized;

function Created()
{
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos;

    Super.Created();

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	BotmatchParent = UMenuBotmatchClientWindow(GetParent(class'UMenuBotmatchClientWindow'));
	if (BotmatchParent == None)
		Log("RocketArenaV2: rules window without a bot match window parent");

	// Game Rules
    GameRulesBtn = UWindowSmallButton(CreateControl(class'UWindowSmallButton', CenterPos, ControlOffset, CenterWidth, 16));
    GameRulesBtn.SetText(GameRulesBtnText);
    GameRulesBtn.SetFont(F_Normal);
    GameRulesBtn.SetHelpText(GameRulesBtnHelp);

	ControlOffset += 25;
	// Weapon Config
    WeaponBtn = UWindowSmallButton(CreateControl(class'UWindowSmallButton', CenterPos, ControlOffset, CenterWidth, 16));
    WeaponBtn.SetText(WeaponBtnText);
    WeaponBtn.SetFont(F_Normal);
    WeaponBtn.SetHelpText(WeaponBtnHelp);

	ControlOffset += 25;
	// Force 1 on 1
	Force1on1Check = UWindowCheckbox(CreateControl(class'UWindowCheckbox', ControlLeft, ControlOffset, ControlWidth, 1));
	Force1on1Check.SetText(Force1on1CheckText);
	Force1on1Check.SetHelpText(Force1on1CheckHelp);
	Force1on1Check.SetFont(F_Normal);
	Force1on1Check.Align = TA_Left;
	Force1on1Check.bChecked = class'RocketArenaGame'.Default.Force1on1;

	// Spectator Speech
	SpecSpeechCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', ControlRight, ControlOffset, ControlWidth, 1));
	SpecSpeechCheck.SetText(SpecSpeechCheckText);
	SpecSpeechCheck.SetHelpText(SpecSpeechCheckHelp);
	SpecSpeechCheck.SetFont(F_Normal);
	SpecSpeechCheck.Align = TA_Left;
	SpecSpeechCheck.bChecked = !class'RocketArenaGame'.Default.DisallowSpectatorSpeech;

	ControlOffset += 25;

	// Bouncy Rockets Height
	BouncyHeightSlider = UWindowHSliderControl(CreateControl(class'UWindowHSliderControl', CenterPos, ControlOffset, WinWidth-ControlLeft*2, 1));
	BouncyHeightSlider.SliderWidth *= 0.75;
	BouncyHeightSlider.SetText(BouncyHeightSliderText);
	BouncyHeightSlider.SetHelpText(BouncyHeightSliderHelp);
	BouncyHeightSlider.SetFont(F_Normal);
	BouncyHeightSlider.Align = TA_Left;
	BouncyHeightSlider.SetRange(100, 300, 25);
	BouncyHeightSlider.SetValue(class'RocketArenaGame'.Default.BouncyHeight*100);

	ResetText();

	ControlOffset += 25;

	// Force Instant RocketFire
	InstantRocketCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', ControlLeft, ControlOffset, ControlWidth, 1));
	InstantRocketCheck.SetText(InstantRocketCheckText);
	InstantRocketCheck.SetHelpText(InstantRocketCheckHelp);
	InstantRocketCheck.SetFont(F_Normal);
	InstantRocketCheck.Align = TA_Left;
	InstantRocketCheck.bChecked = class'RocketArenaGame'.Default.ForceInstantRocketFire;

	// Falling Damage Toggle
	FallingDamageCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', ControlRight, ControlOffset, ControlWidth, 1));
	FallingDamageCheck.SetText(FallingDamageCheckText);
	FallingDamageCheck.SetHelpText(FallingDamageCheckHelp);
	FallingDamageCheck.SetFont(F_Normal);
	FallingDamageCheck.Align = TA_Left;
	FallingDamageCheck.bChecked = class'RocketArenaGame'.Default.FallingDamage;

	ControlOffset += 25;
	if(BotmatchParent.bNetworkGame)
	{
		// Max Players
		MaxPlayersEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', ControlRight, ControlOffset, ControlWidth, 1));
		MaxPlayersEdit.SetText(MaxPlayersText);
		MaxPlayersEdit.SetHelpText(MaxPlayersHelp);
		MaxPlayersEdit.SetFont(F_Normal);
		MaxPlayersEdit.SetNumericOnly(True);
		MaxPlayersEdit.SetMaxLength(2);
		MaxPlayersEdit.Align = TA_Left;
		MaxPlayersEdit.SetDelayedNotify(True);

		if(MaxPlayersEdit != None)
			MaxPlayersEdit.SetValue(string(Class<DeathMatchPlus>(BotmatchParent.GameClass).Default.MaxPlayers));
	}

	// Time Limit
	TimeEdit = UWindowEditControl(CreateControl(class'UWindowEditControl', ControlLeft, ControlOffset, CenterWidth, 1));
	TimeEdit.SetText(TimeText);
	TimeEdit.SetHelpText(TimeHelp);
	TimeEdit.SetFont(F_Normal);
	TimeEdit.SetNumericOnly(True);
	TimeEdit.SetMaxLength(3);
	TimeEdit.Align = TA_Left;
	TimeEdit.SetValue(string(class'RocketArenaGame'.Default.TimeLimit));

	Initialized = true;
}

function BeforePaint(Canvas C, float X, float Y)
{
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos;

	Super.BeforePaint(C, X, Y);

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	if(MaxPlayersEdit != None)
	{
		MaxPlayersEdit.SetSize(ControlWidth, 1);
		MaxPlayersEdit.WinLeft = ControlRight;
		MaxPlayersEdit.EditBoxWidth = 25;
	}

	TimeEdit.SetSize(ControlWidth, 1);
	TimeEdit.WinLeft = ControlLeft;
	TimeEdit.EditBoxWidth = 25;

	WeaponBtn.WinLeft = (WinWidth - (WinWidth/2)) / 2;
	WeaponBtn.SetSize(WinWidth/2, WeaponBtn.WinHeight);

	GameRulesBtn.WinLeft = (WinWidth - (WinWidth/2)) / 2;
	GameRulesBtn.SetSize(WinWidth/2, GameRulesBtn.WinHeight);

	Force1on1Check.SetSize(ControlWidth, 1);
	Force1on1Check.WinLeft = ControlLeft;

	SpecSpeechCheck.SetSize(ControlWidth, 1);
	SpecSpeechCheck.WinLeft = ControlRight;

	BouncyHeightSlider.SetSize(WinWidth-ControlLeft*2, 1);
	BouncyHeightSlider.WinLeft = ControlLeft;

	InstantRocketCheck.SetSize(ControlWidth, 1);
	InstantRocketCheck.WinLeft = ControlLeft;

	FallingDamageCheck.SetSize(ControlWidth, 1);
	FallingDamageCheck.WinLeft = ControlRight;

}

function Notify(UWindowDialogControl C, byte E)
{
	if (!Initialized)
		return;

	Super.Notify(C, E);

	switch(E)
	{
	case DE_Click:
		switch(C)
		{
			case WeaponBtn:
				GetParent(class'UWindowFramedWindow').ShowModal(Root.CreateWindow(class'RAWeaponWindow', 0, 0, 100, 100, Self));
				break;
			case GameRulesBtn:
				GetParent(class'UWindowFramedWindow').ShowModal(Root.CreateWindow(class'RAGameRulesWindow', 0, 0, 100, 100, Self));
				break;
		}
	case DE_Change:
		switch(C)
		{
			case MaxPlayersEdit:
				MaxPlayersChanged();
				break;
			case TimeEdit:
				TimeChanged();
				break;
			case Force1on1Check:
				Force1on1Checked();
				break;
			case InstantRocketCheck:
				InstantRocketChecked();
				break;
			case BouncyHeightSlider:
				BouncyHeightChanged();
				break;
			case SpecSpeechCheck:
				SpecSpeechChecked();
				break;
			case FallingDamageCheck:
				FallingDamageChecked();
				break;
		}
	}
}

function MaxPlayersChanged()
{
	if(int(MaxPlayersEdit.GetValue()) > 16)
		MaxPlayersEdit.SetValue("16");
	if(int(MaxPlayersEdit.GetValue()) < 1)
		MaxPlayersEdit.SetValue("1");

	class'RocketArenaGame'.Default.MaxPlayers = int(MaxPlayersEdit.GetValue());
}

function TimeChanged()
{
	class'RocketArenaGame'.Default.TimeLimit = int(TimeEdit.GetValue());
}

function Force1on1Checked()
{
	class'RocketArenaGame'.Default.Force1on1 = Force1on1Check.bChecked;
}

function InstantRocketChecked()
{
	class'RocketArenaGame'.Default.ForceInstantRocketFire = InstantRocketCheck.bChecked;
}

function BouncyHeightChanged()
{
	class'RocketArenaGame'.Default.BouncyHeight = BouncyHeightSlider.GetValue()/100;
	ResetText();
}

function ResetText()
{
	local string JumpMultiplier;
	JumpMultiplier = Left( string(class'RocketArenaGame'.Default.BouncyHeight), Instr(string(class'RocketArenaGame'.Default.BouncyHeight), ".") + 3 );
	BouncyHeightSlider.SetText(BouncyHeightSliderText@"("$JumpMultiplier$"X)");
}

function SpecSpeechChecked()
{
	class'RocketArenaGame'.Default.DisallowSpectatorSpeech = !SpecSpeechCheck.bChecked;
}

function FallingDamageChecked()
{
	class'RocketArenaGame'.Default.FallingDamage = FallingDamageCheck.bChecked;
}

defaultproperties
{
      BotmatchParent=None
      GameRulesBtn=None
      GameRulesBtnText="Game Rules Config"
      GameRulesBtnHelp="Select this to set your game rules."
      WeaponBtn=None
      WeaponBtnText="Weapon Config"
      WeaponBtnHelp="Select this to specify the default weapon loadouts for each arena."
      MaxPlayersEdit=None
      MaxPlayersText="Max Players:"
      MaxPlayersHelp="Maximum number of human players allowed to connect to the game."
      TimeEdit=None
      TimeText="Time Limit:"
      TimeHelp="This specifies the time between map changes."
      Force1on1Check=None
      Force1on1CheckText="Force 1 on 1:"
      Force1on1CheckHelp="Toggle this to convert all 2 on 2 arenas to 1 on 1."
      InstantRocketCheck=None
      InstantRocketCheckText="Instant Rocket Fire:"
      InstantRocketCheckHelp="Toggle this to force rocket fire to be instant."
      BouncyHeightSlider=None
      BouncyHeightSliderText="Rocket-Jump Height Multiplier:"
      BouncyHeightSliderHelp="Multipler for rocket-jumping. (1 = Normal, 2 = Twice as high)"
      FallingDamageCheck=None
      FallingDamageCheckText="Falling Damage:"
      FallingDamageCheckHelp="Toggles whether or not damage is taken for falling large distances"
      SpecSpeechCheck=None
      SpecSpeechCheckText="Spectator Speech:"
      SpecSpeechCheckHelp="Toggles spectators' ability to talk to playing members."
      ControlOffset=25
      Initialized=False
}
