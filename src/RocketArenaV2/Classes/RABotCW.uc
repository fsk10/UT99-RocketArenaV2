class RABotCW extends UTBotConfigClient;

var string DoItText[26];
var int Level;

function Created()
{
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos;
	local int i;

	Super(UMenuPageWindow).Created();

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	SetBotmatchParent();

	// Base Skill
	BaseCombo = UWindowComboControl(CreateControl(class'UWindowComboControl', ControlLeft, ControlOffset, CenterWidth, 1));
	BaseCombo.SetText(BaseText);
	BaseCombo.SetHelpText(BaseHelp);
	BaseCombo.SetFont(F_Normal);
	BaseCombo.SetEditable(False);
	for (i=0; i<8; i++)
	{
		if (Skills[i] != "")
			BaseCombo.AddItem(Skills[i]);
	}
	ControlOffset += 25;

	// Taunt Label
	TauntLabel = UMenuLabelControl(CreateWindow(class'UMenuLabelControl', ControlLeft, ControlOffset, CenterWidth, 1));
	TauntLabel.Align = TA_Center;
	ControlOffset += 25;

	// Auto Adjust
	AutoAdjustCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', ControlLeft, ControlOffset, ControlWidth, 1));
	AutoAdjustCheck.SetText(AutoAdjustText);
	AutoAdjustCheck.SetHelpText(AutoAdjustHelp);
	AutoAdjustCheck.SetFont(F_Normal);
	AutoAdjustCheck.Align = TA_Right;

	// Random Order
	RandomCheck = UWindowCheckbox(CreateControl(class'UWindowCheckbox', ControlRight, ControlOffset, ControlWidth, 1));
	RandomCheck.SetText(RandomText);
	RandomCheck.SetHelpText(RandomHelp);
	RandomCheck.SetFont(F_Normal);
	RandomCheck.Align = TA_Right;
	ControlOffset += 25;

}

function BeforePaint(Canvas C, float X, float Y)
{
	local int ControlWidth, ControlLeft, ControlRight;
	local int CenterWidth, CenterPos;

	Super(UMenuPageWindow).BeforePaint(C, X, Y);

	ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	BaseCombo.SetSize(CenterWidth, 1);
	BaseCombo.WinLeft = CenterPos;
	BaseCombo.EditBoxWidth = 120;

	TauntLabel.SetSize(CenterWidth, 1);
	TauntLabel.WinLeft = CenterPos;

	AutoAdjustCheck.SetSize(ControlWidth + 10, 1);
	AutoAdjustCheck.WinLeft = ControlLeft - 5;

	RandomCheck.SetSize(ControlWidth + 10, 1);
	RandomCheck.WinLeft = ControlRight - 5;

}

function Paint(Canvas C, float X, float Y)
{
	Super.Paint(C, X, Y);

	C.DrawColor.R = 0;
	C.DrawColor.G = 0;
	C.DrawColor.B = 0;

	ClipText(C, 10, 100, DoItText[Level]);
}

function RClick(float X, float Y)
{
	if (Level < 25) Level++;
}

defaultproperties
{
      DoItText(0)="I told you this space was coming soon."
      DoItText(1)="Actually, this space can be yours for only $19.99/month."
      DoItText(2)="Contact Mongo if you are interested."
      DoItText(3)="Nevermind, the bots have just purchased it."
      DoItText(4)="Sorry, this space is not for sale anymore."
      DoItText(5)="Do you understand English? I said it's not for sale."
      DoItText(6)="You're annoying me. Go away."
      DoItText(7)="Bah! It'll be much easier to just ignore you."
      DoItText(8)="I can't hear you..."
      DoItText(9)="Nope, still can't."
      DoItText(10)="Why don't you go play the game already?"
      DoItText(11)="It took Mongo long enough to release it..."
      DoItText(12)="...so at least make him feel better by playing it."
      DoItText(13)="You're are one of the most annoying people I've met."
      DoItText(14)="(Of course, my experience with humans is limited.)"
      DoItText(15)="Whatever. If you're not gonna play RA:UT, I am."
      DoItText(16)="*Bang* *Bang* *Bang*"
      DoItText(17)="Whoohoo!!"
      DoItText(18)="*Bang* *Bang* *Bang*"
      DoItText(19)="*BOOOOM*"
      DoItText(20)=""
      DoItText(21)=""
      DoItText(22)=""
      DoItText(23)="[Ed: Don't let bot windows out of your sight."
      DoItText(24)="They could get themselves killed.]"
      DoItText(25)=""
      Level=0
}
