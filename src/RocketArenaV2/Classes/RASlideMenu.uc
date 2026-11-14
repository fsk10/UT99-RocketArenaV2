// The Rocket Arena V2 main menu: header, a row of buttons, the arenas as cards and a
// footer. Join/Create a team open as pages inside the menu. Everything is drawn here;
// only the logo, the game type title and the icons are textures (RocketArenaV2Media).
// The subclasses (Multi, Clan) set the buttons and what they do.
// Sizes are UWindow units (designed for a 940 unit wide menu) and the window covers
// the whole screen, so the menu can slide in from the sides.
class RASlideMenu extends UWindowDialogClientWindow
	abstract;

var texture			TitleTex;			// Game type title (content TitleU x TitleV texels).
var float			TitleU, TitleV;
var texture			LogoTex;
var float			LogoU, LogoV;

var int				NumOptions;
var localized string OptionText[6];
var localized string OptionHelp[6];
var texture			OptionIcon[6];
var color			OptionTint[6];		// Icon color; black = the normal teal/white.

// Layout, set in Layout().
var float			MaxMenuW, HeaderH, ButtonH, FooterH, Gap, Pad, HeadH, CardH, CardGap, RowH;
var float			MX, MY, MenuW, ContentH;
var float			OptX[6], OptY, OptW;
var int				NumCards, CardArena[16];
var float			CardX[16], CardY[16], CardW;
var float			BoxX, BoxY, BoxW, BoxH, InfoX, InfoW;
var int				NumTeams;
var RATeamInfo		TeamRows[16];
var float			RowY[16];
var float			OkX, OkY, OkW, OkH, CancelX;

var int				Page;				// 0 = arenas, 1 = join a team, 2 = create a team, 3 = admin, 4 = settings, 5 = chat.
var int				HoverOption, FocusOption, HoverCard, FocusCard, HoverTeam, SelTeam, HoverSub;
var RAEditBox		TeamEdit;

var bool			bSlidingIn;
var float			SlideTime;
var int				SlamsPlayed;

var float			Scale;				// Screen pixels per UWindow unit.

// Admin page: tab, arena, and the clickable controls of the last frame (see AddCtl).
var int				AdminTab, AdminArena, NumCtl, HoverCtl, ArmedCtl;
var int				CtlId[96];
var float			CtlX[96], CtlY[96], CtlW[96], CtlH[96];
var float			ArmedTime;
var localized string AdminText, AdminHelp, AdminTitle, AdminNote, AdminTabs[5], WeaponNames[11], SkillNames[8];
var localized string RoundsText, SelfDamageText, TeamDamageText, ResetRulesText, ResetWeaponsText, DefaultText;
var localized string BotTeamsText, BotsCountText, BotSkillText, Force1on1Text, InstantRocketsText, FallingDamageText;
var localized string SpecSpeechText, BouncyText, RestartText, LogoutText, KickText, BanText, SureText, NoOtherPlayersText, OnText, OffText;
// Settings page: this player's own options (the voice themes listed in the .int files).
var int				NumVoices;
var string			VoiceClass[8], VoiceDesc[8];
var string			BuiltInVoice[2];
var localized string	BuiltInVoiceDesc[2];
var int				TeamListMode[3];
var localized string	TeamListModeText[3];
var localized string SettingsText, SettingsHelp, SettingsTitle, SettingsNote, VoiceText, TeamListText;
// Chat page: the chat of the map (kept by RocketArenaHUD) and a line to write in, to
// your arena or to all arenas ("Global: ", see RAMessageMutator).
var RAEditBox		ChatEdit;
var int				ChatScroll;			// Lines scrolled up from the newest.
var int				ChatScope;			// 0 your arena, 1 all arenas; kept in the class default.
var bool			bChatOnly;			// Opened right on the chat page: Esc closes the menu.
var float			ChatLineH, ChatBoxH, ChatFieldX, ChatFieldY, ChatFieldW;
var string			WrapLine[8];

// Low screens (Root height under CompactH): a lower header and button row. A page that
// still does not fit (Join with many teams, Admin) scrolls; the rest stays put.
var bool			bCompact;
var float			CompactH;
var float			ContentScroll, ScrollMax, VisH;	// In units; VisH = visible height of the page.
var bool			bScrollClip;		// Drawing the scrolled page: skip what is above ScrollTop.
var float			ScrollTop;
var localized string ChatButtonText, ChatHelp, ChatTitle, ChatNote, ArenaScopeText, AllScopeText, SendText;
var localized string NoChatText, WriteArenaText, WriteAllText, AllTag, TeamTag;

var int				FontSizes[12];
var Font			Fonts[24];
var byte			FontTried[24];

var color			GoldColor, TealColor, WhiteColor, DetailColor, DimColor, GreenColor;
var color			ButtonColor, ButtonActiveColor, CardColor, CardHoverColor, FieldColor;
var color			SquareOffColor, DarkTextColor, WaitColor, CountColor, PlayColor, BlackColor;

var localized string ArenasText, ClickText, F2Text, EscCloseText, EscBackText, KeysText, ConfirmText;
var localized string JoinTitle, CreateTitle, RegisteredText, NoTeamsText, JoinText, CreateText, CancelText;
var localized string TeamNameText, ArenaText, TeamSizeText, JoinHelp, CreateHelp, OpenText, FullText, BotsText;
var localized string GoHereText, YouAreHereText, SpectatingText, PlayingText, QueueText, NextUpText, RedTeamText, BlueTeamText;

function Created()
{
	Super.Created();

	bLeaveOnScreen = True;
	// The menu takes the keys itself (arrows, Enter) when no edit box has them.
	SetAcceptsFocus();
	HoverOption = -1;
	FocusOption = -1;
	HoverCard = -1;
	FocusCard = -1;
	HoverTeam = -1;
	SelTeam = -1;
	FillScreen();
}

function FillScreen()
{
	WinLeft = 0;
	WinTop = 0;
	WinWidth = Root.WinWidth;
	WinHeight = Root.WinHeight;
}

function SlideIn()
{
	bSlidingIn = true;
	SlideTime = -0.4;
	SlamsPlayed = 0;
}

function FastSlideIn()
{
	DoneSlidingIn();
}

function DoneSlidingIn()
{
	bSlidingIn = false;
}

// Replaced by the menu of another arena type. Only hidden: Close() of a client window
// also closes its parent, here the root with every window on it (and the new menu).
function SlideOut()
{
	CloseEdits();
	HideWindow();
}

function CloseEdits()
{
	if (TeamEdit != None)
	{
		TeamEdit.Close();
		TeamEdit = None;
	}
	if (ChatEdit != None)
	{
		ChatEdit.Close();
		ChatEdit = None;
	}
}

function Close(optional bool bByParent)
{
	Super.Close(bByParent);

	Root.Console.bQuickKeyEnable = False;
	Root.Console.CloseUWindow();
}

// Esc goes back from Join/Create to the arenas, and closes the menu from there (and
// from a chat page that was opened on its own).
function EscClose()
{
	if (Page != 0 && !(Page == 5 && bChatOnly))
		SetPage(0);
	else
		Close();
}

function NotifyBeforeLevelChange()
{
	Super.NotifyBeforeLevelChange();

	Close();
}

function Tick(float Delta)
{
	local int Landed;

	Super.Tick(Delta);

	if (!bSlidingIn)
		return;
	SlideTime += Delta;
	// The four parts land one after the other, each with a slam (as the V1 menu did).
	Landed = Clamp(int((SlideTime - 0.2) / 0.12) + 1, 0, 4);
	if (SlideTime < 0.2)
		Landed = 0;
	while (SlamsPlayed < Landed)
	{
		GetPlayerOwner().PlaySound(sound'MenuSlam', SLOT_Interact);
		if (SlamsPlayed == 0)
			GetPlayerOwner().ReceiveLocalizedMessage(class'WelcomeMessage');
		SlamsPlayed++;
	}
	if (Landed == 4)
		DoneSlidingIn();
}

// Horizontal offset of a sliding part (0 header, 1 buttons, 2 content, 3 footer).
function float SlideOffset(int Part)
{
	local float T;

	if (!bSlidingIn)
		return 0;
	T = FClamp((SlideTime - Part * 0.12) / 0.2, 0, 1);
	T = (1 - T) * (1 - T) * Root.WinWidth;
	if (Part % 2 == 0)
		return -T;
	return T;
}

//-----------------------------------------------------------------------------
// Data

function bool GetInfo(out RAGameReplicationInfo RAGRI, out RAReplicationInfo RA)
{
	RAGRI = RAGameReplicationInfo(GetPlayerOwner().GameReplicationInfo);
	if (RAGRI == None || RAGRI.ArenaInfo == None)
		return false;
	class'RATools'.static.GetRepInfo(GetPlayerOwner(), RAGRI, RA);
	return RA != None && RAGRI.ArenaGames[RA.Arena] != None;
}

function string OptionLabel(int i)
{
	return OptionText[i];
}

// The buttons: the arena type's, plus ADMIN for a logged in admin.
function bool IsAdmin()
{
	return GetPlayerOwner().PlayerReplicationInfo.bAdmin || GetLevel().NetMode == NM_Standalone;
}

function int OptCount()
{
	if (IsAdmin())
		return NumOptions + 1;
	return NumOptions;
}

function string OptLabel(int i)
{
	if (i >= NumOptions)
		return AdminText;
	return OptionLabel(i);
}

function string OptHelp(int i)
{
	if (i >= NumOptions)
		return AdminHelp;
	return OptionHelp[i];
}

function texture OptIcon(int i)
{
	if (i >= NumOptions)
		return Texture'RocketArenaV2Media.IconAdmin';
	return OptionIcon[i];
}

function int OptPage(int i)
{
	if (i >= NumOptions)
		return 3;
	return OptionPage(i);
}

function OptionClicked(int i)
{
}

// The line in the header box: your team and what it does.
function string StatusText(RAGameReplicationInfo RAGRI, RAReplicationInfo RA)
{
	local ArenaGame AG;

	// Short, so it fits next to the title; the team name is in the HUD panels.
	// WaitingPos 0 and 1 are the match, so 2 is first in line.
	AG = RAGRI.ArenaGames[RA.Arena];
	if (RA.Team != None)
	{
		if ((AG.Teams[0] == RA.Team || AG.Teams[1] == RA.Team) && AG.Period == PERIOD_GameTime)
			return PlayingText;
		if (RA.Team.WaitingPos >= 0 && RA.Team.WaitingPos <= 2)
			return NextUpText;
		if (RA.Team.WaitingPos > 2)
			return QueueText$"  "$Chr(183)$"  #"$(RA.Team.WaitingPos - 1);
		return QueueText;
	}
	return SpectatingText;
}

// The dot before the status: green while playing, gold in the queue, dim when watching.
function color StatusColor(RAGameReplicationInfo RAGRI, RAReplicationInfo RA)
{
	local ArenaGame AG;

	AG = RAGRI.ArenaGames[RA.Arena];
	if (RA.Team == None)
		return DimColor;
	if ((AG.Teams[0] == RA.Team || AG.Teams[1] == RA.Team) && AG.Period == PERIOD_GameTime)
		return GreenColor;
	return GoldColor;
}

//-----------------------------------------------------------------------------
// Layout

function BeforePaint(Canvas C, float X, float Y)
{
	Super.BeforePaint(C, X, Y);

	FillScreen();
	Scale = C.SizeX / Root.WinWidth;
	Layout();
}

function Layout()
{
	local RAGameReplicationInfo RAGRI;
	local RAReplicationInfo RA;
	local int i, Cols, Rows, InRow;
	local float Y, RowX, ArenasH;
	local RATeamInfo T;

	MenuW = FMin(MaxMenuW, Root.WinWidth - 16);
	bCompact = Root.WinHeight < CompactH;
	if (bCompact)
	{
		HeaderH = 56;
		ButtonH = 44;
	}
	else
	{
		HeaderH = default.HeaderH;
		ButtonH = default.ButtonH;
	}
	if (Page == 3 && !IsAdmin())
		SetPage(0);
	OptW = (MenuW - (OptCount() - 1) * Gap) / OptCount();
	for (i=0; i<OptCount(); i++)
		OptX[i] = i * (OptW + Gap);
	OptY = HeaderH + Gap;

	NumCards = 0;
	NumTeams = 0;
	if (!GetInfo(RAGRI, RA))
		return;
	for (i=0; i<ArrayCount(RAGRI.ArenaGames) && NumCards<ArrayCount(CardArena); i++)
		if (RAGRI.ArenaGames[i] != None && RAGRI.ArenaInfo.ArenaNames[i] != "")
			CardArena[NumCards++] = i;

	Y = OptY + ButtonH + Gap;
	// Cards in rows of three (fewer when the screen is narrow), last row centered.
	Cols = 3;
	if (MenuW < 700)
		Cols = 2;
	if (MenuW < 420)
		Cols = 1;
	CardW = (MenuW - 2 * Pad - (Cols - 1) * CardGap) / Cols;
	Rows = (NumCards + Cols - 1) / Cols;
	for (i=0; i<NumCards; i++)
	{
		InRow = Min(Cols, NumCards - (i / Cols) * Cols);
		RowX = (MenuW - InRow * CardW - (InRow - 1) * CardGap) / 2;
		CardX[i] = RowX + (i % Cols) * (CardW + CardGap);
		CardY[i] = Y + HeadH + (i / Cols) * (CardH + CardGap);
	}
	ArenasH = HeadH + Rows * CardH + Max(Rows - 1, 0) * CardGap + Pad;
	if (Page == 0)
		ContentH = ArenasH;
	else if (Page == 3)
		ContentH = HeadH + AdminBodyH(RAGRI) + Pad;
	else if (Page == 4)
		ContentH = HeadH + 2 * 40 - 6 + Pad;
	else if (Page == 5)
	{
		// As many lines as fit on the screen, 4 to 12.
		ChatBoxH = Root.WinHeight - 8 - Y - HeadH - 8 - 34 - Pad - Gap - FooterH - 16;
		ChatBoxH = Clamp(int(ChatBoxH / ChatLineH), 4, 12) * ChatLineH + 16;
		ChatFieldX = Pad + 2 * 120 + 6 + 8;
		ChatFieldY = Y + HeadH + ChatBoxH + 8;
		ChatFieldW = MenuW - Pad - ChatFieldX - 8 - 100;
		ContentH = HeadH + ChatBoxH + 8 + 34 + Pad;
	}
	else
	{
		if (Page == 1 && ArenaGame_Multi(RAGRI.ArenaGames[RA.Arena]) != None)
			for (T=ArenaGame_Multi(RAGRI.ArenaGames[RA.Arena]).TeamList; T!=None && NumTeams<ArrayCount(TeamRows); T=T.NextTeam)
				TeamRows[NumTeams++] = T;

		BoxX = Pad;
		BoxY = Y + HeadH;
		BoxW = (MenuW - 3 * Pad) * 0.68;
		InfoX = BoxX + BoxW + Pad;
		InfoW = MenuW - InfoX - Pad;
		if (Page == 1)
		{
			for (i=0; i<NumTeams; i++)
				RowY[i] = BoxY + 36 + i * (RowH + 4);
			BoxH = 36 + Max(NumTeams, 3) * (RowH + 4) + 8 + 34 + 14;
		}
		else
			BoxH = 36 + 34 + 16 + 34 + 14;
		OkW = 120;
		OkH = 34;
		OkY = BoxY + BoxH - 14 - OkH;
		CancelX = BoxX + BoxW - 16 - OkW;
		OkX = CancelX - 12 - OkW;
		ContentH = HeadH + BoxH + Pad;
	}

	// The top stays where the arenas page has it: other pages only move the bottom
	// (up, unless they would not fit).
	// Join and Admin scroll when they are taller than the screen allows.
	VisH = ContentH;
	ScrollMax = 0;
	if ((Page == 1 || Page == 3) && ContentH > Root.WinHeight - 8 - (Y + Gap + FooterH))
	{
		VisH = Root.WinHeight - 8 - (Y + Gap + FooterH);
		ScrollMax = ContentH - VisH;
	}
	ContentScroll = FClamp(ContentScroll, 0, ScrollMax);

	MX = (Root.WinWidth - MenuW) / 2;
	MY = (Root.WinHeight - (Y + ArenasH + Gap + FooterH)) / 2;
	MY = FMax(4, FMin(MY, Root.WinHeight - 4 - (Y + VisH + Gap + FooterH)));

	if (TeamEdit != None)
	{
		TeamEdit.WinLeft = MX + BoxX + 24;
		TeamEdit.WinTop = MY + BoxY + 38;
		TeamEdit.WinWidth = BoxW - 48;
		TeamEdit.WinHeight = 30;
	}
	if (ChatEdit != None)
	{
		ChatEdit.WinLeft = MX + ChatFieldX + 8;
		ChatEdit.WinTop = MY + ChatFieldY + 2;
		ChatEdit.WinWidth = ChatFieldW - 16;
		ChatEdit.WinHeight = 30;
	}
}

//-----------------------------------------------------------------------------
// Drawing

function Paint(Canvas C, float X, float Y)
{
	local RAGameReplicationInfo RAGRI;
	local RAReplicationInfo RA;
	local float CY;

	NumCtl = 0;
	if (!GetInfo(RAGRI, RA))
		return;

	DrawHeader(C, MX + SlideOffset(0), MY, RAGRI, RA);
	DrawOptions(C, MX + SlideOffset(1), MY + OptY);
	CY = MY + OptY + ButtonH + Gap;
	if (ScrollMax > 0)
	{
		DrawScrolled(C, CY, RAGRI, RA);
		DrawFooter(C, MX + SlideOffset(3), CY + VisH + Gap);
		C.Style = GetPlayerOwner().ERenderStyle.STY_Normal;
		C.DrawColor = WhiteColor;
		return;
	}
	if (Page == 0)
		DrawArenas(C, MX + SlideOffset(2), CY, RAGRI, RA);
	else if (Page == 1)
		DrawJoin(C, MX + SlideOffset(2), CY, RAGRI, RA);
	else if (Page == 3)
		DrawAdmin(C, MX + SlideOffset(2), CY, RAGRI, RA);
	else if (Page == 4)
		DrawSettings(C, MX + SlideOffset(2), CY);
	else if (Page == 5)
		DrawChat(C, MX + SlideOffset(2), CY);
	else
		DrawCreate(C, MX + SlideOffset(2), CY, RAGRI, RA);
	DrawFooter(C, MX + SlideOffset(3), CY + ContentH + Gap);

	C.Style = GetPlayerOwner().ERenderStyle.STY_Normal;
	C.DrawColor = WhiteColor;
}

function DrawHeader(Canvas C, float X, float Y, RAGameReplicationInfo RAGRI, RAReplicationInfo RA)
{
	local float LogoH, LogoW, TitleH, TitleW, TX, BX, SX, W, H;
	local string S;

	DrawPanel(C, X, Y, MenuW, HeaderH);
	Fill(C, X, Y + HeaderH - 2, MenuW, 2, GoldColor);

	// The cap height of ROCKET ARENA is 105 of the logo's 128 texels.
	LogoH = 42;
	if (bCompact)
		LogoH = 34;
	LogoW = LogoH * LogoU / LogoV;
	DrawTex(C, X + 14, Y + (HeaderH - LogoH) / 2 + 2, LogoW, LogoH, LogoTex, LogoU, LogoV, WhiteColor);
	TitleH = 24;
	if (bCompact)
		TitleH = 20;
	TitleW = TitleH * TitleU / TitleV;
	TX = X + 14 + LogoW + 14;
	DrawTex(C, TX, Y + (HeaderH - TitleH) / 2 + 3, TitleW, TitleH, TitleTex, TitleU, TitleV, WhiteColor);

	// SETTINGS, right: opens this player's own options. CHAT left of it.
	SX = X + MenuW - 14;
	SX -= DrawHeadButton(C, SX, Y, SettingsText, Texture'RocketArenaV2Media.IconSettings', Page == 4, 1700);
	SX -= 8;
	SX -= DrawHeadButton(C, SX, Y, ChatButtonText, None, Page == 5, 1701);

	// Your status, left of SETTINGS: plain text with a dot, no frame, so it does not
	// look like a button.
	S = StatusText(RAGRI, RA);
	C.Font = MenuFont(14, false);
	TextSize(C, S, W, H);
	W += 14;
	BX = SX - 20 - W;
	// Too long for the space: cut it with "..." rather than hiding it.
	if (BX < TX + TitleW + 10 && SX - 20 - (TX + TitleW + 10) > 60)
	{
		BX = TX + TitleW + 10;
		S = FitText(C, S, SX - 20 - BX - 14);
	}
	if (BX >= TX + TitleW + 10)
	{
		Fill(C, BX, Y + (HeaderH - 6) / 2, 6, 6, StatusColor(RAGRI, RA));
		Text(C, BX + 14, Y + (HeaderH - H) / 2, S, DetailColor);
	}
}

// Join or Admin taller than the screen: drawn moved up by ContentScroll and clipped to
// the visible part, with a scroll bar at the right edge.
function DrawScrolled(Canvas C, float CY, RAGameReplicationInfo RAGRI, RAReplicationInfo RA)
{
	local Region OldClip;
	local float BarH, BarY;

	OldClip = ClippingRegion;
	ClippingRegion.Y = CY;
	ClippingRegion.H = VisH;
	bScrollClip = true;
	ScrollTop = CY;
	if (Page == 1)
		DrawJoin(C, MX + SlideOffset(2), CY - ContentScroll, RAGRI, RA);
	else
		DrawAdmin(C, MX + SlideOffset(2), CY - ContentScroll, RAGRI, RA);
	bScrollClip = false;
	ClippingRegion = OldClip;

	Box(C, MX + SlideOffset(2), CY, MenuW, VisH, TealColor);
	BarH = FMax(20, VisH * VisH / ContentH);
	BarY = CY + (VisH - BarH) * ContentScroll / ScrollMax;
	Fill(C, MX + SlideOffset(2) + MenuW - 5, BarY, 3, BarH, GoldColor);
}

// A framed button in the header, right-aligned at Right; returns its width.
function float DrawHeadButton(Canvas C, float Right, float Y, string Label, texture Icon, bool bOn, int Id)
{
	local float W, H, SW, SX, TX;
	local color Col;

	C.Font = MenuFont(14, true);
	TextSize(C, Label, W, H);
	SW = 14 + W + 14;
	if (Icon != None)
		SW += 20 + 6;
	SX = Right - SW;
	Col = TealColor;
	if (bOn || HoverCtl == Id)
	{
		Fill(C, SX, Y + (HeaderH - 34) / 2, SW, 34, ButtonActiveColor);
		Col = WhiteColor;
	}
	Box(C, SX, Y + (HeaderH - 34) / 2, SW, 34, TealColor);
	TX = SX + 14;
	if (Icon != None)
	{
		DrawTex(C, SX + 12, Y + (HeaderH - 20) / 2, 20, 20, Icon, 64, 64, Col);
		TX = SX + 40;
	}
	Text(C, TX, Y + (HeaderH - H) / 2, Label, Col);
	AddCtl(Id, SX, Y + (HeaderH - 34) / 2, SW, 34);
	return SW;
}

function DrawOptions(Canvas C, float X, float Y)
{
	local int i;
	local bool bActive;
	local float BX, W, H;
	local color IconColor;
	local string S;

	for (i=0; i<OptCount(); i++)
	{
		BX = X + OptX[i];
		bActive = i == HoverOption || i == FocusOption || (Page != 0 && OptPage(i) == Page);
		if (bActive)
		{
			Fill(C, BX, Y, OptW, ButtonH, ButtonActiveColor);
			Box(C, BX, Y, OptW, ButtonH, TealColor);
			Fill(C, BX, Y + ButtonH - 3, OptW, 3, GoldColor);
		}
		else
			Fill(C, BX, Y, OptW, ButtonH, ButtonColor);

		IconColor = OptionTint[Min(i, ArrayCount(OptionTint) - 1)];
		if (i >= NumOptions)
			IconColor = BlackColor;
		if (IconColor.R == 0 && IconColor.G == 0 && IconColor.B == 0)
		{
			if (bActive)
				IconColor = WhiteColor;
			else
				IconColor = TealColor;
		}
		C.Font = MenuFont(15, true);
		if (bCompact)
		{
			// One line: icon, then the label.
			S = FitText(C, OptLabel(i), OptW - 12 - 30);
			TextSize(C, S, W, H);
			DrawTex(C, BX + (OptW - W - 30) / 2, Y + (ButtonH - 22) / 2, 22, 22, OptIcon(i), 64, 64, IconColor);
			if (bActive)
				Text(C, BX + (OptW - W - 30) / 2 + 30, Y + (ButtonH - H) / 2, S, WhiteColor);
			else
				Text(C, BX + (OptW - W - 30) / 2 + 30, Y + (ButtonH - H) / 2, S, TealColor);
			continue;
		}
		DrawTex(C, BX + (OptW - 28) / 2, Y + 17, 28, 28, OptIcon(i), 64, 64, IconColor);

		S = FitText(C, OptLabel(i), OptW - 12);
		TextSize(C, S, W, H);
		if (bActive)
			Text(C, BX + (OptW - W) / 2, Y + 56, S, WhiteColor);
		else
			Text(C, BX + (OptW - W) / 2, Y + 56, S, TealColor);
	}
}

// Which page a button opens (1 join, 2 create), so it stays marked while open.
function int OptionPage(int i)
{
	return 0;
}

function DrawArenas(Canvas C, float X, float Y, RAGameReplicationInfo RAGRI, RAReplicationInfo RA)
{
	local int i;

	DrawPanel(C, X, Y, MenuW, ContentH);
	DrawSectionHead(C, X, Y, ArenasText, class'RATools'.static.Plural(NumCards, "arena")$"  "$Chr(183)$"  "$ClickText$"  "$Chr(183)$"  "$F2Text);
	for (i=0; i<NumCards; i++)
		DrawCard(C, X + CardX[i], MY + CardY[i], i, RAGRI, RA);
}

function DrawSectionHead(Canvas C, float X, float Y, string Title, string Right)
{
	local float W, H;

	C.Font = MenuFont(15, true);
	Text(C, X + 14, Y + 9, Title, TealColor);
	C.Font = MenuFont(13, false);
	TextSize(C, Right, W, H);
	Text(C, X + MenuW - 14 - W, Y + 11, Right, DetailColor);
}

function DrawCard(Canvas C, float X, float Y, int Card, RAGameReplicationInfo RAGRI, RAReplicationInfo RA)
{
	local int Arena, Total, Filled, Active, i;
	local bool bOwn, bHover;
	local float W, H, SX;
	local string S;
	local ArenaGame AG;

	Arena = CardArena[Card];
	AG = RAGRI.ArenaGames[Arena];
	bOwn = Arena == RA.Arena;
	bHover = Card == HoverCard || Card == FocusCard;

	if (bHover)
	{
		Fill(C, X, Y, CardW, CardH, CardHoverColor);
		Box(C, X, Y, CardW, CardH, TealColor);
	}
	else
		Fill(C, X, Y, CardW, CardH, CardColor);
	if (bOwn)
		Fill(C, X, Y, 3, CardH, GoldColor);

	// Mode and players (playing or queued, not spectators), right.
	Active = class'RATools'.static.ActiveCount(RAGRI, Arena);
	C.Font = MenuFont(13, true);
	S = class'RATools'.static.ArenaMode(RAGRI, Arena)$" "$Chr(183)$" "$Active$" pl";
	TextSize(C, S, W, H);
	Text(C, X + CardW - 12 - W, Y + 9, S, WhiteColor);

	// Name, left.
	C.Font = MenuFont(15, true);
	S = FitText(C, RAGRI.ArenaInfo.ArenaNames[Arena], CardW - 40 - W);
	if (bOwn)
		Text(C, X + 14, Y + 7, S, GoldColor);
	else
		Text(C, X + 14, Y + 7, S, WhiteColor);

	// Status, left below.
	C.Font = MenuFont(13, false);
	Text(C, X + 14, Y + 31, class'RATools'.static.ArenaStatus(RAGRI, Arena),
		StateColor(class'RATools'.static.ArenaState(RAGRI, Arena)));

	// One square per player slot (filled = taken). More players than slots add squares.
	Total = Active;
	if (ArenaGame_Multi(AG) != None)
		Total = Max(Total, RAGRI.ArenaInfo.ArenaTeamSize[Arena] * 2);
	Total = Clamp(Max(Total, 2), 2, 10);
	Filled = Min(Active, Total);
	SX = X + CardW - 12 - Total * 10 + 3;
	for (i=0; i<Total; i++)
	{
		if (i < Filled)
			Fill(C, SX + i * 10, Y + CardH - 17, 7, 7, TealColor);
		else
			Fill(C, SX + i * 10, Y + CardH - 17, 7, 7, SquareOffColor);
	}
}

function DrawJoin(Canvas C, float X, float Y, RAGameReplicationInfo RAGRI, RAReplicationInfo RA)
{
	local int i, Size, MaxSize;
	local float W, H, RX, RW, RYY, BY;
	local string S;
	local bool bFull;

	DrawPanel(C, X, Y, MenuW, ContentH);
	DrawSectionHead(C, X, Y, JoinTitle, "Esc  "$Chr(183)$"  "$EscBackText);
	BY = Y + HeadH;
	Fill(C, X + BoxX, BY, BoxW, BoxH, CardColor);
	C.Font = MenuFont(14, false);
	Text(C, X + BoxX + 18, BY + 12, RegisteredText, WhiteColor);

	MaxSize = RAGRI.ArenaInfo.ArenaTeamSize[RA.Arena];
	RX = X + BoxX + 16;
	RW = BoxW - 32;
	if (NumTeams == 0)
	{
		C.Font = MenuFont(14, false);
		Text(C, RX + 4, BY + 44, NoTeamsText, DimColor);
	}
	for (i=0; i<NumTeams; i++)
	{
		RYY = MY + RowY[i] - ContentScroll;
		Size = TeamRows[i].Size;
		bFull = TeamRows[i].bBotTeam || Size >= MaxSize;
		if (i == SelTeam)
		{
			Fill(C, RX, RYY, RW, RowH, CardHoverColor);
			Box(C, RX, RYY, RW, RowH, TealColor);
			Fill(C, RX, RYY + RowH - 2, RW, 2, GoldColor);
		}
		else if (i == HoverTeam)
			Fill(C, RX, RYY, RW, RowH, CardHoverColor);

		C.Font = MenuFont(13, false);
		if (TeamRows[i].bBotTeam)
			S = BotsText;
		else if (bFull)
			S = FullText;
		else
			S = OpenText;
		TextSize(C, S, W, H);
		if (bFull)
			Text(C, RX + RW - 14 - W, RYY + (RowH - H) / 2, S, DimColor);
		else
			Text(C, RX + RW - 14 - W, RYY + (RowH - H) / 2, S, GreenColor);

		C.Font = MenuFont(14, true);
		S = Size$"/"$MaxSize$" pl";
		TextSize(C, S, W, H);
		Text(C, RX + RW - 84 - W, RYY + (RowH - H) / 2, S, WhiteColor);

		C.Font = MenuFont(15, true);
		S = FitText(C, TeamRows[i].TeamName, RW - 180);
		TextSize(C, S, W, H);
		if (bFull)
			Text(C, RX + 16, RYY + (RowH - H) / 2, S, DimColor);
		else
			Text(C, RX + 16, RYY + (RowH - H) / 2, S, WhiteColor);
	}

	DrawSubButtons(C, X, Y, JoinText);
	DrawInfo(C, X, BY, RAGRI, RA, JoinHelp);
}

function DrawCreate(Canvas C, float X, float Y, RAGameReplicationInfo RAGRI, RAReplicationInfo RA)
{
	local float BY;

	DrawPanel(C, X, Y, MenuW, ContentH);
	DrawSectionHead(C, X, Y, CreateTitle, "Esc  "$Chr(183)$"  "$EscBackText);
	BY = Y + HeadH;
	Fill(C, X + BoxX, BY, BoxW, BoxH, CardColor);
	C.Font = MenuFont(14, false);
	Text(C, X + BoxX + 18, BY + 12, TeamNameText, WhiteColor);

	// The edit box (a child window) draws the text on this field.
	Fill(C, X + BoxX + 16, BY + 36, BoxW - 32, 34, FieldColor);
	Box(C, X + BoxX + 16, BY + 36, BoxW - 32, 34, TealColor);
	if (TeamEdit != None)
		TeamEdit.EditFont = MenuFont(16, false);

	DrawSubButtons(C, X, Y, CreateText);
	DrawInfo(C, X, BY, RAGRI, RA, CreateHelp);
}

// The filled OK button (Join/Create) and the outlined Cancel button.
function DrawSubButtons(Canvas C, float X, float Y, string OkText)
{
	local float W, H, BY;

	BY = MY + OkY - ContentScroll;
	C.Font = MenuFont(15, true);

	if (HoverSub == 1)
		Fill(C, X + OkX, BY, OkW, OkH, WhiteColor);
	else
		Fill(C, X + OkX, BY, OkW, OkH, TealColor);
	TextSize(C, OkText, W, H);
	Text(C, X + OkX + (OkW - W) / 2, BY + (OkH - H) / 2, OkText, DarkTextColor);

	if (HoverSub == 2)
		Fill(C, X + CancelX, BY, OkW, OkH, CardHoverColor);
	Box(C, X + CancelX, BY, OkW, OkH, TealColor);
	TextSize(C, CancelText, W, H);
	Text(C, X + CancelX + (OkW - W) / 2, BY + (OkH - H) / 2, CancelText, TealColor);
}

function DrawInfo(Canvas C, float X, float Y, RAGameReplicationInfo RAGRI, RAReplicationInfo RA, string Help)
{
	local float W, H, IX, TY;

	IX = X + InfoX;
	Fill(C, IX, Y, InfoW, BoxH, CardColor);
	C.Font = MenuFont(14, false);
	TextSize(C, ArenaText$" ", W, H);
	Text(C, IX + 18, Y + 14, ArenaText, WhiteColor);
	C.Font = MenuFont(14, true);
	Text(C, IX + 18 + W, Y + 14, FitText(C, RAGRI.ArenaInfo.ArenaNames[RA.Arena], InfoW - 36 - W), GoldColor);
	C.Font = MenuFont(14, false);
	TextSize(C, TeamSizeText$" ", W, H);
	Text(C, IX + 18, Y + 14 + H + 6, TeamSizeText, WhiteColor);
	C.Font = MenuFont(14, true);
	Text(C, IX + 18 + W, Y + 14 + H + 6, RAGRI.ArenaInfo.ArenaTeamSize[RA.Arena], GoldColor);
	C.Font = MenuFont(14, false);
	TY = Y + 14 + (H + 6) * 2 + 4;
	WrapText(C, IX + 18, TY, InfoW - 36, Help, WhiteColor);
}

function DrawFooter(Canvas C, float X, float Y)
{
	local float W, H;
	local string S;

	DrawPanel(C, X, Y, MenuW, FooterH);
	C.Font = MenuFont(13, false);
	TextSize(C, "A", W, H);
	Text(C, X + 14, Y + (FooterH - H) / 2, HintText(), DetailColor);
	if (Page == 0)
		S = KeysText$"  "$Chr(183)$"  Enter "$ConfirmText$"  "$Chr(183)$"  Esc "$EscCloseText;
	else if (Page == 5 && bChatOnly)
		S = "Esc "$EscCloseText;
	else
		S = "Esc "$EscBackText;
	TextSize(C, S, W, H);
	Text(C, X + MenuW - 14 - W, Y + (FooterH - H) / 2, S, DetailColor);
}

function string HintText()
{
	local RAGameReplicationInfo RAGRI;
	local RAReplicationInfo RA;
	local int Card;

	if (HoverOption >= 0)
		return OptHelp(HoverOption);
	if (FocusOption >= 0)
		return OptHelp(FocusOption);
	if (HoverCtl == 1700)
		return SettingsHelp;
	if (HoverCtl == 1701)
		return ChatHelp;
	if (Page == 5)
		return ChatNote;
	if (Page == 3)
		return AdminNote;
	if (Page == 4)
		return SettingsNote;
	Card = HoverCard;
	if (Card < 0)
		Card = FocusCard;
	if (Page == 0 && Card >= 0 && Card < NumCards && GetInfo(RAGRI, RA))
	{
		if (CardArena[Card] == RA.Arena)
			return YouAreHereText;
		return GoHereText@RAGRI.ArenaInfo.ArenaNames[CardArena[Card]];
	}
	if (Page == 1)
		return JoinHelp;
	if (Page == 2)
		return CreateHelp;
	return ClickText;
}

//-----------------------------------------------------------------------------
// Drawing helpers

// Arena state colors (RATools.ArenaState) for the menu.
function color StateColor(int ArenaSt)
{
	switch (ArenaSt)
	{
	case 0:
		return DimColor;
	case 1:
		return WaitColor;
	case 2:
		return CountColor;
	}
	return PlayColor;
}

// Dark see-through panel with a teal frame.
function DrawPanel(Canvas C, float X, float Y, float W, float H)
{
	C.Style = GetPlayerOwner().ERenderStyle.STY_Modulated;
	C.DrawColor = WhiteColor;
	DrawStretchedTexture(C, X, Y, W, H, Texture'RocketArenaV2Media.Panel');
	DrawStretchedTexture(C, X, Y, W, H, Texture'RocketArenaV2Media.Panel');
	Box(C, X, Y, W, H, TealColor);
}

function Fill(Canvas C, float X, float Y, float W, float H, color Col)
{
	C.Style = GetPlayerOwner().ERenderStyle.STY_Normal;
	C.DrawColor = Col;
	DrawStretchedTexture(C, X, Y, W, H, Texture'RocketArenaV2Media.White');
}

function Box(Canvas C, float X, float Y, float W, float H, color Col)
{
	Fill(C, X, Y, W, 1, Col);
	Fill(C, X, Y + H - 1, W, 1, Col);
	Fill(C, X, Y, 1, H, Col);
	Fill(C, X + W - 1, Y, 1, H, Col);
}

// A texture drawn added to the background (black = see-through), U x V texels of it.
function DrawTex(Canvas C, float X, float Y, float W, float H, texture Tex, float U, float V, color Col)
{
	C.Style = GetPlayerOwner().ERenderStyle.STY_Translucent;
	C.DrawColor = Col;
	DrawStretchedTextureSegment(C, X, Y, W, H, 0, 0, U, V, Tex);
}

function Text(Canvas C, float X, float Y, coerce string S, color Col)
{
	if (bScrollClip && Y < ScrollTop - 2)
		return;
	C.Style = GetPlayerOwner().ERenderStyle.STY_Normal;
	C.DrawColor = Col;
	ClipText(C, X, Y, S);
}

// Draws S word-wrapped into width W.
function WrapText(Canvas C, float X, float Y, float W, string S, color Col)
{
	local string Line, Word;
	local float XL, YL;
	local int i;

	while (S != "")
	{
		i = InStr(S, " ");
		if (i < 0)
		{
			Word = S;
			S = "";
		}
		else
		{
			Word = Left(S, i);
			S = Mid(S, i + 1);
		}
		if (Line == "")
			TextSize(C, Word, XL, YL);
		else
			TextSize(C, Line@Word, XL, YL);
		if (XL > W && Line != "")
		{
			Text(C, X, Y, Line, Col);
			Y += YL;
			Line = Word;
		}
		else if (Line == "")
			Line = Word;
		else
			Line = Line@Word;
	}
	if (Line != "")
		Text(C, X, Y, Line, Col);
}

// Cuts S so it fits in MaxW, ending with "...".
function string FitText(Canvas C, string S, float MaxW)
{
	local float XL, YL;

	TextSize(C, S, XL, YL);
	if (XL <= MaxW)
		return S;
	while (Len(S) > 1)
	{
		S = Left(S, Len(S) - 1);
		TextSize(C, S$"...", XL, YL);
		if (XL <= MaxW)
			break;
	}
	return S$"...";
}

// Tahoma at about Units UWindow units high, from the UWindowFonts sizes. Loaded by
// name, so clients without a size fall back to the UWindow font.
function Font MenuFont(float Units, bool bBold)
{
	local int i, Best, Slot;
	local float Px;

	Px = Units * Scale;
	Best = 0;
	for (i=1; i<ArrayCount(FontSizes); i++)
		if (Abs(FontSizes[i] - Px) < Abs(FontSizes[Best] - Px))
			Best = i;
	Slot = Best;
	if (bBold)
		Slot += ArrayCount(FontSizes);
	if (FontTried[Slot] == 0)
	{
		FontTried[Slot] = 1;
		if (bBold)
			Fonts[Slot] = Font(DynamicLoadObject("UWindowFonts.TahomaB"$FontSizes[Best], class'Font', true));
		else
			Fonts[Slot] = Font(DynamicLoadObject("UWindowFonts.Tahoma"$FontSizes[Best], class'Font', true));
	}
	if (Fonts[Slot] != None)
		return Fonts[Slot];
	if (bBold)
		return Root.Fonts[F_Bold];
	return Root.Fonts[F_Normal];
}

//-----------------------------------------------------------------------------
// Input

function bool Inside(float X, float Y, float RX, float RY, float RW, float RH)
{
	return X >= RX && X < RX + RW && Y >= RY && Y < RY + RH;
}

function MouseMove(float X, float Y)
{
	local int i, OldOption;

	Super.MouseMove(X, Y);

	OldOption = HoverOption;
	HoverOption = -1;
	HoverCard = -1;
	HoverTeam = -1;
	HoverSub = 0;
	if (bSlidingIn)
		return;
	X -= MX;
	Y -= MY;
	HoverCtl = -1;
	for (i=0; i<NumCtl; i++)
		if (Inside(X + MX, Y + MY, CtlX[i], CtlY[i], CtlW[i], CtlH[i]))
			HoverCtl = CtlId[i];
	for (i=0; i<OptCount(); i++)
		if (Inside(X, Y, OptX[i], OptY, OptW, ButtonH))
			HoverOption = i;
	if (Page == 0)
	{
		for (i=0; i<NumCards; i++)
			if (Inside(X, Y, CardX[i], CardY[i], CardW, CardH))
				HoverCard = i;
	}
	else
	{
		// Below the button row and above the footer: the (maybe scrolled) page.
		if (Y >= OptY + ButtonH + Gap && Y < OptY + ButtonH + Gap + VisH)
		{
			for (i=0; i<NumTeams; i++)
				if (Inside(X, Y + ContentScroll, BoxX + 16, RowY[i], BoxW - 32, RowH))
					HoverTeam = i;
			if (Inside(X, Y + ContentScroll, OkX, OkY, OkW, OkH))
				HoverSub = 1;
			if (Inside(X, Y + ContentScroll, CancelX, OkY, OkW, OkH))
				HoverSub = 2;
		}
	}
	if (HoverOption >= 0 && HoverOption != OldOption)
		GetPlayerOwner().PlaySound(sound'MenuSelect', SLOT_Interact);
	if (HoverOption >= 0 || HoverCard >= 0)
	{
		FocusOption = -1;
		FocusCard = -1;
	}
}

function MouseLeave()
{
	Super.MouseLeave();
	HoverOption = -1;
	HoverCard = -1;
	HoverTeam = -1;
	HoverSub = 0;
}

function Click(float X, float Y)
{
	Super.Click(X, Y);

	if (bSlidingIn)
	{
		DoneSlidingIn();
		return;
	}
	MouseMove(X, Y);
	// SETTINGS (1700) opens page 4, CHAT (1701) page 5; again goes back to the arenas.
	if (HoverCtl == 1700 || HoverCtl == 1701)
	{
		GetPlayerOwner().PlaySound(sound'MenuClick', SLOT_Interact);
		if (Page == HoverCtl - 1696)
			SetPage(0);
		else
			SetPage(HoverCtl - 1696);
		return;
	}
	if (HoverOption >= 0)
	{
		ClickOption(HoverOption);
		return;
	}
	if (HoverCard >= 0)
	{
		GotoCard(HoverCard);
		return;
	}
	if (HoverTeam >= 0)
	{
		SelTeam = HoverTeam;
		GetPlayerOwner().PlaySound(sound'MenuSelect', SLOT_Interact);
		return;
	}
	if (Page == 3)
	{
		if (HoverCtl >= 0)
			AdminClick(HoverCtl);
		return;
	}
	if (Page == 4)
	{
		if (HoverCtl >= 0)
			SettingsClick(HoverCtl);
		return;
	}
	if (Page == 5)
	{
		if (HoverCtl >= 0)
			ChatClick(HoverCtl);
		if (ChatEdit != None)
			ChatEdit.ActivateWindow(0, false);
		return;
	}
	if (HoverSub == 1)
		Apply();
	else if (HoverSub == 2)
		SetPage(0);
}

function DoubleClick(float X, float Y)
{
	Super.DoubleClick(X, Y);
	if (Page == 1 && HoverTeam >= 0)
	{
		SelTeam = HoverTeam;
		Apply();
	}
}

function ClickOption(int i)
{
	GetPlayerOwner().PlaySound(sound'MenuClick', SLOT_Interact);
	if (i >= NumOptions)
		SetPage(3);
	else
		OptionClicked(i);
}

// Go to another arena (one click, as Next Arena did). Another kind of arena has
// another menu, which replaces this one once the server has moved us there
// (RAReplicationInfo.CheckArenaMenu). The server ignores a click on the own arena;
// RA.Arena here may still be the one before the last click.
function GotoCard(int Card)
{
	local RAGameReplicationInfo RAGRI;
	local RAReplicationInfo RA;
	local int NewArena;

	if (!GetInfo(RAGRI, RA) || Card >= NumCards)
		return;
	NewArena = CardArena[Card];
	GetPlayerOwner().PlaySound(sound'MenuClick', SLOT_Interact);
	RA.GotoArena(NewArena);
}

function KeyDown(int Key, float X, float Y)
{
	local PlayerPawn P;

	Super.KeyDown(Key, X, Y);

	P = GetPlayerOwner();
	if (ScrollMax > 0 && (Key == P.EInputKey.IK_PageUp || Key == P.EInputKey.IK_PageDown))
	{
		if (Key == P.EInputKey.IK_PageUp)
			ScrollBy(-VisH * 0.8);
		else
			ScrollBy(VisH * 0.8);
		return;
	}
	if (Page == 5)
	{
		if (Key == P.EInputKey.IK_PageUp)
			ChatScroll += 6;
		else if (Key == P.EInputKey.IK_PageDown)
			ChatScroll = Max(ChatScroll - 6, 0);
		return;
	}
	switch (Key)
	{
	case P.EInputKey.IK_Enter:
	case P.EInputKey.IK_Space:
		if (Page == 1 || Page == 2)
			Apply();
		else if (FocusOption >= 0)
			ClickOption(FocusOption);
		else if (FocusCard >= 0)
			GotoCard(FocusCard);
		break;
	case P.EInputKey.IK_Left:
		FocusCard = -1;
		FocusOption = (Max(FocusOption, 0) + OptCount() - 1) % OptCount();
		P.PlaySound(sound'MenuSelect', SLOT_Interact);
		break;
	case P.EInputKey.IK_Right:
		FocusCard = -1;
		FocusOption = (FocusOption + 1) % OptCount();
		P.PlaySound(sound'MenuSelect', SLOT_Interact);
		break;
	case P.EInputKey.IK_Up:
		if (Page == 1 && NumTeams > 0)
			SelTeam = (Max(SelTeam, 0) + NumTeams - 1) % NumTeams;
		else if (Page == 0 && NumCards > 0)
		{
			FocusOption = -1;
			FocusCard = (Max(FocusCard, 0) + NumCards - 1) % NumCards;
		}
		break;
	case P.EInputKey.IK_Down:
		if (Page == 1 && NumTeams > 0)
			SelTeam = (SelTeam + 1) % NumTeams;
		else if (Page == 0 && NumCards > 0)
		{
			FocusOption = -1;
			FocusCard = (FocusCard + 1) % NumCards;
		}
		break;
	}
}

//-----------------------------------------------------------------------------
// Pages

function SetPage(int NewPage)
{
	local RAGameReplicationInfo RAGRI;
	local RAReplicationInfo RA;
	local int i;

	Page = NewPage;
	bChatOnly = false;
	ContentScroll = 0;
	HoverTeam = -1;
	HoverCtl = -1;
	ArmedCtl = -1;
	if (Page == 3 && GetInfo(RAGRI, RA))
		AdminArena = RA.Arena;
	if (Page == 4)
		FindVoices();
	HoverSub = 0;
	CloseEdits();
	Layout();
	if (Page == 1)
	{
		// Start on your own team, else the first one that is open.
		SelTeam = -1;
		if (GetInfo(RAGRI, RA))
			for (i=0; i<NumTeams; i++)
				if (TeamRows[i] == RA.Team || (SelTeam < 0 && !TeamRows[i].bBotTeam && TeamRows[i].Size < RAGRI.ArenaInfo.ArenaTeamSize[RA.Arena]))
					SelTeam = i;
	}
	else if (Page == 2)
	{
		TeamEdit = RAEditBox(CreateControl(class'RAEditBox', 0, 0, 100, 30));
		TeamEdit.MaxLength = 30;
		TeamEdit.TextColor = WhiteColor;
		TeamEdit.SetValue(GetPlayerOwner().PlayerReplicationInfo.PlayerName$"'s Team");
		TeamEdit.MoveEnd();
		TeamEdit.ActivateWindow(0, false);
		TeamEdit.SelectAll();
		Layout();
	}
	else if (Page == 5)
	{
		ChatScroll = 0;
		ChatEdit = RAEditBox(CreateControl(class'RAEditBox', 0, 0, 100, 30));
		ChatEdit.MaxLength = 150;
		ChatEdit.TextColor = WhiteColor;
		ChatEdit.SetHistory(true);
		ChatEdit.ActivateWindow(0, false);
		Layout();
	}
}

// The chat page on its own (Open Chat in the UT menu bar, the rachat key).
function OpenChat()
{
	SetPage(5);
	bChatOnly = true;
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C, E);

	if (C == TeamEdit && E == DE_EnterPressed)
		Apply();
	else if (C == ChatEdit && E == DE_EnterPressed)
		SendChat();
}

// Join or Create pressed.
function Apply()
{
	local RAGameReplicationInfo RAGRI;
	local RAReplicationInfo RA;

	if (!GetInfo(RAGRI, RA))
		return;
	if (Page == 1)
	{
		if (SelTeam < 0 || SelTeam >= NumTeams)
			return;
		if (TeamRows[SelTeam].bBotTeam)
		{
			GetPlayerOwner().ClientMessage("That is a bot team.  You cannot join it.");
			return;
		}
		GetPlayerOwner().PlaySound(sound'MenuClick', SLOT_Interact);
		RA.AddToTeam(TeamRows[SelTeam].TeamName);
		Close();
	}
	else if (Page == 2 && TeamEdit != None)
	{
		if (TeamEdit.GetValue() == "")
		{
			GetPlayerOwner().ClientMessage("You cannot create a team that has no name.");
			return;
		}
		GetPlayerOwner().PlaySound(sound'MenuClick', SLOT_Interact);
		RA.CreateTeam(TeamEdit.GetValue());
		Close();
	}
}

//-----------------------------------------------------------------------------
// Admin page (only for a logged in admin). Every change is sent to the server at once
// and saved in RocketArenaV2.ini there; the page shows the replicated values.

function float AdminBodyH(RAGameReplicationInfo RAGRI)
{
	local float H;

	H = 34 + 8;					// Tabs.
	if (AdminTab <= 2)
		H += 30 + 8;			// Arena chips.
	switch (AdminTab)
	{
	case 0:
		return H + 3 * 40 + 44;
	case 1:
		return H + 6 * 36 + 40;
	case 2:
		return H + 2 * 40;
	case 3:
		return H + 3 * 40 + 44;
	}
	return H + Max(CountPlayers(RAGRI), 2) * 36;
}

// A clickable area of this frame, in screen units.
function AddCtl(int Id, float X, float Y, float W, float H)
{
	if (NumCtl >= ArrayCount(CtlId))
		return;
	if (bScrollClip && (Y + H <= ScrollTop || Y >= ScrollTop + VisH))
		return;
	CtlId[NumCtl] = Id;
	CtlX[NumCtl] = X;
	CtlY[NumCtl] = Y;
	CtlW[NumCtl] = W;
	CtlH[NumCtl] = H;
	NumCtl++;
}

function DrawAdmin(Canvas C, float X, float Y, RAGameReplicationInfo RAGRI, RAReplicationInfo RA)
{
	local int i, n;
	local float TW, BY, CW, ColW;
	local WeaponInfo WI;
	local bool bMulti;

	DrawPanel(C, X, Y, MenuW, ContentH);
	DrawSectionHead(C, X, Y, AdminTitle, "Esc  "$Chr(183)$"  "$EscBackText);
	WI = RAGRI.WeaponInfo;
	if (AdminArena < 0 || AdminArena >= ArrayCount(RAGRI.ArenaGames) || RAGRI.ArenaGames[AdminArena] == None)
		AdminArena = RA.Arena;

	// Tabs.
	BY = Y + HeadH;
	TW = (MenuW - 2 * Pad - 4 * 6) / 5;
	for (i=0; i<5; i++)
		DrawChip(C, X + Pad + i * (TW + 6), BY, TW, 34, AdminTabs[i], i == AdminTab, 1000 + i, 14);
	BY += 34 + 8;

	// Arena chips for the per-arena tabs.
	if (AdminTab <= 2)
	{
		CW = (MenuW - 2 * Pad - (NumCards - 1) * 6) / Max(NumCards, 1);
		for (i=0; i<NumCards; i++)
			DrawChip(C, X + Pad + i * (CW + 6), BY, CW, 30, RAGRI.ArenaInfo.ArenaNames[CardArena[i]], CardArena[i] == AdminArena, 1100 + CardArena[i], 13);
		BY += 30 + 8;
	}

	ColW = (MenuW - 2 * Pad - 8) / 2;
	switch (AdminTab)
	{
	case 0:
		DrawStepRow(C, X + Pad, BY, MenuW - 2 * Pad, RoundsText, string(WI.Rule(AdminArena, 0)), 1200);
		DrawToggleRow(C, X + Pad, BY + 40, MenuW - 2 * Pad, SelfDamageText, WI.Rule(AdminArena, 1) == 1, 1202);
		DrawToggleRow(C, X + Pad, BY + 80, MenuW - 2 * Pad, TeamDamageText, WI.Rule(AdminArena, 2) == 1, 1203);
		DrawButton(C, X + Pad, BY + 126, 220, 32, ResetRulesText, 1204);
		break;
	case 1:
		// Ten weapons and the armor in two columns.
		for (i=0; i<11; i++)
			DrawWeaponRow(C, X + Pad + (i / 6) * (ColW + 8), BY + (i % 6) * 36, ColW, WI, i);
		DrawButton(C, X + Pad, BY + 6 * 36 + 4, 220, 30, ResetWeaponsText, 1399);
		break;
	case 2:
		bMulti = ArenaGame_Multi(RAGRI.ArenaGames[AdminArena]) != None;
		n = CountBots(RAGRI, AdminArena, bMulti);
		if (bMulti)
			DrawStepRow(C, X + Pad, BY, MenuW - 2 * Pad, BotTeamsText, string(n), 1400);
		else
			DrawStepRow(C, X + Pad, BY, MenuW - 2 * Pad, BotsCountText, string(n), 1400);
		DrawStepRow(C, X + Pad, BY + 40, MenuW - 2 * Pad, BotSkillText, SkillNames[Clamp(RAGRI.BotSkill, 0, 7)], 1402);
		break;
	case 3:
		DrawToggleRow(C, X + Pad, BY, ColW, Force1on1Text, RAGRI.bForce1on1, 1500);
		DrawToggleRow(C, X + Pad + ColW + 8, BY, ColW, InstantRocketsText, RAGRI.bInstantRockets, 1501);
		DrawToggleRow(C, X + Pad, BY + 40, ColW, FallingDamageText, RAGRI.bFallingDamage, 1502);
		DrawToggleRow(C, X + Pad + ColW + 8, BY + 40, ColW, SpecSpeechText, RAGRI.bSpectatorSpeech, 1503);
		DrawStepRow(C, X + Pad, BY + 80, MenuW - 2 * Pad, BouncyText, FloatText(RAGRI.BouncyHeight)$"x", 1504);
		DrawButton(C, X + Pad, BY + 126, 220, 32, RestartText, 1510);
		DrawButton(C, X + Pad + 232, BY + 126, 220, 32, LogoutText, 1511);
		break;
	case 4:
		DrawPlayers(C, X + Pad, BY, MenuW - 2 * Pad, RAGRI);
		break;
	}
}

function string FloatText(float F)
{
	local string S;

	S = string(F);
	return Left(S, InStr(S, ".") + 3);
}

// Tab or arena chip.
function DrawChip(Canvas C, float X, float Y, float W, float H, string S, bool bOn, int Id, float FontSize)
{
	local float XL, YL;

	if (bOn)
	{
		Fill(C, X, Y, W, H, ButtonActiveColor);
		Box(C, X, Y, W, H, TealColor);
		Fill(C, X, Y + H - 2, W, 2, GoldColor);
	}
	else if (HoverCtl == Id)
		Fill(C, X, Y, W, H, CardHoverColor);
	else
		Fill(C, X, Y, W, H, ButtonColor);
	C.Font = MenuFont(FontSize, true);
	S = FitText(C, S, W - 10);
	TextSize(C, S, XL, YL);
	if (bOn)
		Text(C, X + (W - XL) / 2, Y + (H - YL) / 2, S, WhiteColor);
	else
		Text(C, X + (W - XL) / 2, Y + (H - YL) / 2, S, TealColor);
	AddCtl(Id, X, Y, W, H);
}

function DrawRowBack(Canvas C, float X, float Y, float W, string Label, bool bHover)
{
	local float XL, YL;

	if (bHover)
		Fill(C, X, Y, W, 34, CardHoverColor);
	else
		Fill(C, X, Y, W, 34, CardColor);
	C.Font = MenuFont(14, false);
	TextSize(C, "A", XL, YL);
	Text(C, X + 14, Y + (34 - YL) / 2, FitText(C, Label, W - 180), WhiteColor);
}

// A setting that is on or off: the whole row is the button.
function DrawToggleRow(Canvas C, float X, float Y, float W, string Label, bool bOn, int Id)
{
	DrawRowBack(C, X, Y, W, Label, HoverCtl == Id);
	DrawPill(C, X + W - 14 - 64, Y + 6, bOn);
	AddCtl(Id, X, Y, W, 34);
}

function DrawPill(Canvas C, float X, float Y, bool bOn)
{
	local float XL, YL;

	C.Font = MenuFont(12, true);
	if (bOn)
	{
		Fill(C, X, Y, 64, 22, TealColor);
		TextSize(C, OnText, XL, YL);
		Text(C, X + (64 - XL) / 2, Y + (22 - YL) / 2, OnText, DarkTextColor);
	}
	else
	{
		Box(C, X, Y, 64, 22, TealColor);
		TextSize(C, OffText, XL, YL);
		Text(C, X + (64 - XL) / 2, Y + (22 - YL) / 2, OffText, TealColor);
	}
}

// A value with - and + (Id and Id + 1).
function DrawStepRow(Canvas C, float X, float Y, float W, string Label, string Value, int Id)
{
	DrawRowBack(C, X, Y, W, Label, false);
	DrawStepper(C, X + W - 14 - 140, Y + 6, Value, Id);
}

function DrawStepper(Canvas C, float X, float Y, string Value, int Id)
{
	local float XL, YL;

	DrawStepButton(C, X, Y, "-", Id);
	DrawStepButton(C, X + 140 - 26, Y, "+", Id + 1);
	C.Font = MenuFont(13, true);
	Value = FitText(C, Value, 84);
	TextSize(C, Value, XL, YL);
	Text(C, X + 70 - XL / 2, Y + (22 - YL) / 2, Value, WhiteColor);
}

function DrawStepButton(Canvas C, float X, float Y, string S, int Id)
{
	local float XL, YL;

	if (HoverCtl == Id)
		Fill(C, X, Y, 26, 22, ButtonActiveColor);
	Box(C, X, Y, 26, 22, TealColor);
	C.Font = MenuFont(14, true);
	TextSize(C, S, XL, YL);
	Text(C, X + (26 - XL) / 2, Y + (22 - YL) / 2, S, TealColor);
	AddCtl(Id, X, Y, 26, 22);
}

function DrawWeaponRow(Canvas C, float X, float Y, float W, WeaponInfo WI, int Weapon)
{
	local int Ammo;
	local string S;

	DrawRowBack(C, X, Y, W, WeaponNames[Weapon], HoverCtl == 1300 + Weapon);
	AddCtl(1300 + Weapon, X, Y, W - 14 - 140 - 8, 34);
	DrawPill(C, X + W - 14 - 140 - 8 - 64, Y + 6, WI.UseWeapon(AdminArena, Weapon));
	if (Weapon == 0)
		return;			// The hammer has no ammo.
	Ammo = WI.WeaponAmmo(AdminArena, Weapon);
	S = string(Ammo);
	if (Ammo < 0)
		S = DefaultText;
	DrawStepper(C, X + W - 14 - 140 + 6, Y + 6, S, 1320 + Weapon * 2);
}

// Button that does something big: the first click arms it, the second one does it.
function DrawButton(Canvas C, float X, float Y, float W, float H, string S, int Id)
{
	local float XL, YL;

	if (ArmedCtl == Id && GetLevel().TimeSeconds < ArmedTime + 3)
	{
		Fill(C, X, Y, W, H, GoldColor);
		C.Font = MenuFont(13, true);
		TextSize(C, SureText, XL, YL);
		Text(C, X + (W - XL) / 2, Y + (H - YL) / 2, SureText, DarkTextColor);
	}
	else
	{
		if (HoverCtl == Id)
			Fill(C, X, Y, W, H, CardHoverColor);
		Box(C, X, Y, W, H, TealColor);
		C.Font = MenuFont(13, true);
		S = FitText(C, S, W - 10);
		TextSize(C, S, XL, YL);
		Text(C, X + (W - XL) / 2, Y + (H - YL) / 2, S, TealColor);
	}
	AddCtl(Id, X, Y, W, H);
}

// Players the Players tab lists: humans in the game (with RA data), not you.
function bool ListedPlayer(RAGameReplicationInfo RAGRI, PlayerReplicationInfo PRI)
{
	local RAReplicationInfo RA;

	if (PRI == None || PRI.bIsABot || PRI == GetPlayerOwner().PlayerReplicationInfo)
		return false;
	class'RATools'.static.GetRepInfoFromPRI(PRI, RAGRI, RA);
	return RA != None;
}

function int CountPlayers(RAGameReplicationInfo RAGRI)
{
	local int i, n;

	for (i=0; i<ArrayCount(RAGRI.PRIArray); i++)
		if (ListedPlayer(RAGRI, RAGRI.PRIArray[i]))
			n++;
	return n;
}

// Every human player but you, with Kick and Ban.
function DrawPlayers(Canvas C, float X, float Y, float W, RAGameReplicationInfo RAGRI)
{
	local int i;
	local float XL, YL;
	local PlayerReplicationInfo PRI;
	local RAReplicationInfo RA;
	local string S;

	if (CountPlayers(RAGRI) == 0)
	{
		C.Font = MenuFont(14, false);
		Text(C, X + 4, Y + 8, NoOtherPlayersText, DimColor);
		return;
	}
	for (i=0; i<ArrayCount(RAGRI.PRIArray); i++)
	{
		PRI = RAGRI.PRIArray[i];
		if (!ListedPlayer(RAGRI, PRI))
			continue;
		Fill(C, X, Y, W, 32, CardColor);
		C.Font = MenuFont(14, true);
		TextSize(C, "A", XL, YL);
		Text(C, X + 14, Y + (32 - YL) / 2, FitText(C, PRI.PlayerName, W * 0.35), WhiteColor);
		class'RATools'.static.GetRepInfoFromPRI(PRI, RAGRI, RA);
		S = "";
		if (RA != None && RAGRI.ArenaGames[RA.Arena] != None)
			S = RAGRI.ArenaInfo.ArenaNames[RA.Arena]$"   "$Chr(183)$"   ";
		C.Font = MenuFont(13, false);
		Text(C, X + W * 0.40, Y + (32 - YL) / 2 + 1, S$PRI.Ping$" ms", DetailColor);
		DrawButton(C, X + W - 8 - 2 * 96 - 8, Y + 4, 96, 24, KickText, 1600 + i);
		DrawButton(C, X + W - 8 - 96, Y + 4, 96, 24, BanText, 1650 + i);
		Y += 36;
	}
}

// Bot teams in a Multi arena, bots otherwise.
function int CountBots(RAGameReplicationInfo RAGRI, int Arena, bool bMulti)
{
	local RATeamInfo T;
	local RAReplicationInfo R;
	local int n;

	if (bMulti)
	{
		for (T=ArenaGame_Multi(RAGRI.ArenaGames[Arena]).TeamList; T!=None; T=T.NextTeam)
			if (T.bBotTeam)
				n++;
		return n;
	}
	for (R=RAGRI.RepInfoList; R!=None; R=R.NextRepInfo)
		if (R.Arena == Arena && R.OwnerPRI != None && R.OwnerPRI.bIsABot)
			n++;
	return n;
}

// Buttons that need a second click within 3 seconds.
function bool Confirmed(int Id)
{
	if (ArmedCtl == Id && GetLevel().TimeSeconds < ArmedTime + 3)
	{
		ArmedCtl = -1;
		return true;
	}
	ArmedCtl = Id;
	ArmedTime = GetLevel().TimeSeconds;
	return false;
}

function AdminClick(int Id)
{
	local RAGameReplicationInfo RAGRI;
	local RAReplicationInfo RA;
	local WeaponInfo WI;
	local int W, Ammo, Step, n;
	local bool bMulti;
	local PlayerReplicationInfo PRI;

	if (!GetInfo(RAGRI, RA) || !IsAdmin())
		return;
	WI = RAGRI.WeaponInfo;
	GetPlayerOwner().PlaySound(sound'MenuClick', SLOT_Interact);

	if (Id >= 1000 && Id < 1005)
		AdminTab = Id - 1000;
	else if (Id >= 1100 && Id < 1100 + ArrayCount(RAGRI.ArenaGames))
		AdminArena = Id - 1100;
	else if (Id == 1200 || Id == 1201)
		RA.AdminSetRule(AdminArena, 0, Clamp(WI.Rule(AdminArena, 0) + (Id - 1200) * 4 - 2, 1, 9));	// Best of 1, 3, 5, ...
	else if (Id == 1202)
		RA.AdminSetRule(AdminArena, 1, 1 - WI.Rule(AdminArena, 1));
	else if (Id == 1203)
		RA.AdminSetRule(AdminArena, 2, 1 - WI.Rule(AdminArena, 2));
	else if (Id == 1204)
	{
		if (Confirmed(Id))
			RA.AdminResetRules();
	}
	else if (Id >= 1300 && Id <= 1310)
	{
		W = Id - 1300;
		RA.AdminSetWeapon(AdminArena, W, !WI.UseWeapon(AdminArena, W), WI.WeaponAmmo(AdminArena, W));
	}
	else if (Id >= 1320 && Id < 1342)
	{
		// Ammo: -1 (default), then steps of 5 (armor: 25).
		W = (Id - 1320) / 2;
		Step = 5;
		if (W == 10)
			Step = 25;
		Ammo = WI.WeaponAmmo(AdminArena, W);
		if ((Id - 1320) % 2 == 0)
		{
			Ammo -= Step;
			if (Ammo < Step)
				Ammo = -1;
		}
		else if (Ammo < 0)
			Ammo = Step;
		else
			Ammo = Min(Ammo + Step, 995);
		RA.AdminSetWeapon(AdminArena, W, WI.UseWeapon(AdminArena, W), Ammo);
	}
	else if (Id == 1399)
	{
		if (Confirmed(Id))
			RA.AdminResetWeapons();
	}
	else if (Id == 1400 || Id == 1401)
	{
		bMulti = ArenaGame_Multi(RAGRI.ArenaGames[AdminArena]) != None;
		n = CountBots(RAGRI, AdminArena, bMulti) + (Id - 1400) * 2 - 1;
		if (bMulti)
			RA.SetBotTeams(Clamp(n, 0, 8), AdminArena);
		else
			RA.SetBotCount(Clamp(n, 0, 16), AdminArena);
	}
	else if (Id == 1402 || Id == 1403)
		RA.SetBotDifficulty(Clamp(RAGRI.BotSkill + (Id - 1402) * 2 - 1, 0, 7));
	else if (Id == 1500)
		RA.AdminSetting(0, int(!RAGRI.bForce1on1));
	else if (Id == 1501)
		RA.AdminSetting(1, int(!RAGRI.bInstantRockets));
	else if (Id == 1502)
		RA.AdminSetting(2, int(!RAGRI.bFallingDamage));
	else if (Id == 1503)
		RA.AdminSetting(3, int(!RAGRI.bSpectatorSpeech));
	else if (Id == 1504 || Id == 1505)
		RA.AdminSetting(4, RAGRI.BouncyHeight + ((Id - 1504) * 2 - 1) * 0.25);
	else if (Id == 1510)
	{
		if (Confirmed(Id))
			GetPlayerOwner().Admin("servertravel ?restart");
	}
	else if (Id == 1511)
	{
		GetPlayerOwner().AdminLogout();
		SetPage(0);
	}
	else if (Id >= 1600 && Id < 1700)
	{
		PRI = RAGRI.PRIArray[(Id - 1600) % 50];
		if (PRI != None && Confirmed(Id))
		{
			if (Id < 1650)
				GetPlayerOwner().Kick(PRI.PlayerName);
			else
				GetPlayerOwner().KickBan(PRI.PlayerName);
		}
	}
}

//-----------------------------------------------------------------------------
// Settings page (every player). Saved in this player's own RocketArenaV2.ini.

function FindVoices()
{
	local string NextVoice, NextDesc;

	local int i;

	// The voices of this package always: players who downloaded it from a server
	// have no RocketArenaV2.int, so the .int list below only finds extra voices.
	NumVoices = 0;
	for (i=0; i<ArrayCount(BuiltInVoice); i++)
		AddVoice(BuiltInVoice[i], BuiltInVoiceDesc[i]);
	i = 0;
	GetPlayerOwner().GetNextIntDesc("RocketArenaV2.RAVoice", 0, NextVoice, NextDesc);
	while (NextVoice != "")
	{
		AddVoice(NextVoice, NextDesc);
		GetPlayerOwner().GetNextIntDesc("RocketArenaV2.RAVoice", ++i, NextVoice, NextDesc);
	}
}

function AddVoice(string Voice, string Desc)
{
	local int i;

	if (Voice == "" || NumVoices >= ArrayCount(VoiceClass))
		return;
	for (i=0; i<NumVoices; i++)
		if (VoiceClass[i] ~= Voice)
			return;
	VoiceClass[NumVoices] = Voice;
	VoiceDesc[NumVoices] = Desc;
	NumVoices++;
}

function DrawSettings(Canvas C, float X, float Y)
{
	local int i;
	local float W, CW, CX;
	local string S;
	local bool bOn;

	DrawPanel(C, X, Y, MenuW, ContentH);
	DrawSectionHead(C, X, Y, SettingsTitle, "Esc  "$Chr(183)$"  "$EscBackText);
	Y += HeadH;
	W = MenuW - 2 * Pad;

	// Announcer voice: one chip per voice theme ("Default Male Voice" shown as "Male Voice").
	DrawRowBack(C, X + Pad, Y, W, VoiceText, false);
	CW = FMin(150, (W * 0.6 - (NumVoices - 1) * 6) / Max(NumVoices, 1));
	for (i=0; i<NumVoices; i++)
	{
		S = VoiceDesc[i];
		if (Left(S, 8) ~= "Default ")
			S = Mid(S, 8);
		CX = X + Pad + W - 14 - (NumVoices - i) * (CW + 6) + 6;
		bOn = VoiceClass[i] ~= class'RocketArenaGame'.default.NewVoiceThemeName;
		DrawChip(C, CX, Y + 5, CW, 24, S, bOn, 1710 + i, 13);
		if (!bOn)
			Box(C, CX, Y + 5, CW, 24, TealColor);
	}

	// Team list: On (1), Transparent (2) or Off (0); 1720 + i shows TeamListMode[i].
	Y += 40;
	DrawRowBack(C, X + Pad, Y, W, TeamListText, false);
	for (i=0; i<3; i++)
	{
		CX = X + Pad + W - 14 - (3 - i) * (110 + 6) + 6;
		bOn = class'RocketArenaGame'.default.HUDTeamDisplay == TeamListMode[i];
		DrawChip(C, CX, Y + 5, 110, 24, TeamListModeText[i], bOn, 1720 + i, 13);
		if (!bOn)
			Box(C, CX, Y + 5, 110, 24, TealColor);
	}
}

function SettingsClick(int Id)
{
	local class<RAVoice> Voice;

	GetPlayerOwner().PlaySound(sound'MenuClick', SLOT_Interact);
	if (Id >= 1710 && Id < 1710 + NumVoices)
	{
		Voice = class<RAVoice>(DynamicLoadObject(VoiceClass[Id - 1710], class'Class', true));
		if (Voice == None)
			return;
		class'RocketArenaGame'.default.NewVoiceThemeName = VoiceClass[Id - 1710];
		class'RocketArenaGame'.default.NewVoiceTheme = Voice;
		class'RocketArenaGame'.static.StaticSaveConfig();
		TellPrepare();		// A sample of the new voice.
	}
	else if (Id >= 1720 && Id < 1723)
	{
		class'RocketArenaGame'.default.HUDTeamDisplay = TeamListMode[Id - 1720];
		class'RocketArenaGame'.static.StaticSaveConfig();
	}
}

//-----------------------------------------------------------------------------
// Chat page

function DrawChat(Canvas C, float X, float Y)
{
	local float W, BY, XL, YL;
	local int Scope;
	local string S;

	DrawPanel(C, X, Y, MenuW, ContentH);
	if (bChatOnly)
		DrawSectionHead(C, X, Y, ChatTitle, "Esc  "$Chr(183)$"  "$EscCloseText);
	else
		DrawSectionHead(C, X, Y, ChatTitle, "Esc  "$Chr(183)$"  "$EscBackText);
	W = MenuW - 2 * Pad;
	BY = Y + HeadH;
	Fill(C, X + Pad, BY, W, ChatBoxH, CardColor);
	DrawChatLog(C, X + Pad + 14, BY + 8, W - 28, ChatBoxH - 16);
	if (ChatScroll > 0)
		Fill(C, X + Pad, BY + ChatBoxH - 2, W, 2, GoldColor);	// Scrolled up: newer lines below.

	// Who you write to, the line and Send.
	BY = MY + ChatFieldY;
	Scope = class'RASlideMenu'.default.ChatScope;
	DrawChip(C, X + Pad, BY, 120, 34, ArenaScopeText, Scope == 0, 1730, 13);
	if (Scope != 0)
		Box(C, X + Pad, BY, 120, 34, TealColor);
	DrawChip(C, X + Pad + 126, BY, 120, 34, AllScopeText, Scope == 1, 1731, 13);
	if (Scope != 1)
		Box(C, X + Pad + 126, BY, 120, 34, TealColor);

	Fill(C, X + ChatFieldX, BY, ChatFieldW, 34, FieldColor);
	Box(C, X + ChatFieldX, BY, ChatFieldW, 34, TealColor);
	if (ChatEdit != None)
	{
		ChatEdit.EditFont = MenuFont(15, false);
		if (ChatEdit.GetValue() == "")
		{
			if (Scope == 1)
				S = WriteAllText;
			else
				S = WriteArenaText;
			C.Font = MenuFont(14, false);
			TextSize(C, "A", XL, YL);
			Text(C, X + ChatFieldX + 14, BY + (34 - YL) / 2, FitText(C, S, ChatFieldW - 28), DetailColor);
		}
	}

	if (HoverCtl == 1732)
		Fill(C, X + MenuW - Pad - 100, BY, 100, 34, WhiteColor);
	else
		Fill(C, X + MenuW - Pad - 100, BY, 100, 34, TealColor);
	C.Font = MenuFont(15, true);
	TextSize(C, SendText, XL, YL);
	Text(C, X + MenuW - Pad - 50 - XL / 2, BY + (34 - YL) / 2, SendText, DarkTextColor);
	AddCtl(1732, X + MenuW - Pad - 100, BY, 100, 34);
}

// The newest messages at the bottom, word-wrapped, ChatScroll lines up from the end.
function DrawChatLog(Canvas C, float X, float Y, float W, float H)
{
	local RocketArenaHUD HUD;
	local int n, i, l, Lines, Row, Skip;
	local float XL, YL, TagW, NameW, LY;
	local string Tag, Name;
	local color TagCol, NameCol;

	HUD = RocketArenaHUD(GetPlayerOwner().myHUD);
	C.Font = MenuFont(14, false);
	TextSize(C, "A", XL, YL);
	if (HUD == None || HUD.ChatCount == 0)
	{
		Text(C, X, Y + 4, NoChatText, DetailColor);
		return;
	}

	Row = int(H / ChatLineH) - 1;
	Skip = ChatScroll;
	for (n=HUD.ChatCount-1; n>=Max(0, HUD.ChatCount - ArrayCount(HUD.ChatText)) && Row>=0; n--)
	{
		i = n % ArrayCount(HUD.ChatText);
		Tag = "";
		NameCol = TealColor;
		if (HUD.ChatKind[i] == 1)
		{
			Tag = AllTag$" ";
			TagCol = GoldColor;
			NameCol = GoldColor;
		}
		else if (HUD.ChatKind[i] == 2)
		{
			Tag = TeamTag$" ";
			TagCol = GreenColor;
			NameCol = GreenColor;
		}
		Name = HUD.ChatName[i]$": ";
		C.Font = MenuFont(14, true);
		TextSize(C, Tag, TagW, YL);
		TextSize(C, Name, NameW, YL);
		C.Font = MenuFont(14, false);
		Lines = WrapChat(C, HUD.ChatText[i], W - TagW - NameW, W - 24);
		for (l=Lines-1; l>=0 && Row>=0; l--)
		{
			if (Skip > 0)
			{
				Skip--;
				continue;
			}
			LY = Y + Row * ChatLineH + (ChatLineH - YL) / 2;
			if (l == 0)
			{
				C.Font = MenuFont(14, true);
				if (Tag != "")
					Text(C, X, LY, Tag, TagCol);
				Text(C, X + TagW, LY, Name, NameCol);
				C.Font = MenuFont(14, false);
				Text(C, X + TagW + NameW, LY, WrapLine[0], WhiteColor);
			}
			else
				Text(C, X + 24, LY, WrapLine[l], WhiteColor);
			Row--;
		}
	}
	// Scrolled past the oldest message: back to where it is at the top.
	if (Row >= 0 && ChatScroll > 0)
		ChatScroll = Max(0, ChatScroll - Skip - (Row + 1));
}

// Splits S into WrapLine by words: the first line FirstW wide, the others W. A word
// wider than a line is cut. Returns the number of lines (at least 1).
function int WrapChat(Canvas C, string S, float FirstW, float W)
{
	local string Line, Word, Try;
	local float XL, YL, MaxW;
	local int i, n;

	MaxW = FirstW;
	while ((S != "" || Word != "") && n < ArrayCount(WrapLine))
	{
		if (Word == "")
		{
			i = InStr(S, " ");
			if (i < 0)
			{
				Word = S;
				S = "";
			}
			else
			{
				Word = Left(S, i);
				S = Mid(S, i + 1);
			}
			if (Word == "")
				continue;
		}
		if (Line == "")
			Try = Word;
		else
			Try = Line@Word;
		TextSize(C, Try, XL, YL);
		if (XL <= MaxW)
		{
			Line = Try;
			Word = "";
		}
		else if (Line != "")
		{
			WrapLine[n++] = Line;
			Line = "";
			MaxW = W;
		}
		else
		{
			for (i=Len(Word)-1; i>1; i--)
			{
				TextSize(C, Left(Word, i), XL, YL);
				if (XL <= MaxW)
					break;
			}
			WrapLine[n++] = Left(Word, i);
			Word = Mid(Word, i);
			MaxW = W;
		}
	}
	if (Line != "" && n < ArrayCount(WrapLine))
		WrapLine[n++] = Line;
	if (n == 0)
		WrapLine[n++] = "";
	return n;
}

function ChatClick(int Id)
{
	if (Id == 1730 || Id == 1731)
	{
		GetPlayerOwner().PlaySound(sound'MenuSelect', SLOT_Interact);
		class'RASlideMenu'.default.ChatScope = Id - 1730;
	}
	else if (Id == 1732)
		SendChat();
}

// Says the line: to this arena, or with "Global: " to every arena.
function SendChat()
{
	local string S;

	if (ChatEdit == None || ChatEdit.GetValue() == "")
		return;
	S = ChatEdit.GetValue();
	if (class'RASlideMenu'.default.ChatScope == 1)
		S = "Global: "$S;
	GetPlayerOwner().Say(S);
	ChatEdit.Clear();
	ChatScroll = 0;
}

function bool MouseWheelUp(float ScrollDelta)
{
	if (Page != 5 && ScrollMax > 0)
	{
		ScrollBy(-40);
		return true;
	}
	if (Page != 5)
		return Super.MouseWheelUp(ScrollDelta);
	ChatScroll += 3;
	return true;
}

function bool MouseWheelDown(float ScrollDelta)
{
	if (Page != 5 && ScrollMax > 0)
	{
		ScrollBy(40);
		return true;
	}
	if (Page != 5)
		return Super.MouseWheelDown(ScrollDelta);
	ChatScroll = Max(ChatScroll - 3, 0);
	return true;
}

function ScrollBy(float Delta)
{
	ContentScroll = FClamp(ContentScroll + Delta, 0, ScrollMax);
	MouseMove(Root.MouseX, Root.MouseY);
}

//-----------------------------------------------------------------------------
// Actions shared by the subclasses

function TellPrepare()
{
	GetPlayerOwner().ClientPlaySound(class'RocketArenaGame'.default.NewVoiceTheme.default.Prepare,,true);
}

function SwitchTeams(int NewTeam)
{
	GetPlayerOwner().ChangeTeam(NewTeam);
	Close();
}

// The colors are stored darker than designed: UT (2x blending + Brightness) shows
// canvas colors as about 255*(c/255)^0.3, measured at Brightness 1.0. Designed colors:
// gold 245,197,66  teal 38,200,214  cards 10,40,48 (same curve as tools/make_media.py).
defaultproperties
{
      LogoTex=Texture'RocketArenaV2Media.Logo'
      LogoU=865.000000
      LogoV=128.000000
      MaxMenuW=940.000000
      HeaderH=80.000000
      ButtonH=94.000000
      FooterH=28.000000
      Gap=8.000000
      Pad=12.000000
      HeadH=36.000000
      CardH=56.000000
      CardGap=8.000000
      RowH=30.000000
      CompactH=600.000000
      FontSizes(0)=10
      FontSizes(1)=12
      FontSizes(2)=15
      FontSizes(3)=17
      FontSizes(4)=20
      FontSizes(5)=22
      FontSizes(6)=25
      FontSizes(7)=27
      FontSizes(8)=30
      FontSizes(9)=35
      FontSizes(10)=37
      FontSizes(11)=40
      GoldColor=(R=224,G=109,B=3,A=0)
      TealColor=(R=0,G=115,B=143,A=0)
      WhiteColor=(R=255,G=255,B=255,A=0)
      DetailColor=(R=97,G=124,B=130,A=0)
      DimColor=(R=21,G=31,B=35,A=0)
      GreenColor=(R=6,G=157,B=12,A=0)
      ButtonColor=(R=0,G=1,B=1,A=0)
      ButtonActiveColor=(R=0,G=4,B=6,A=0)
      CardColor=(R=0,G=1,B=1,A=0)
      CardHoverColor=(R=0,G=3,B=5,A=0)
      FieldColor=(R=0,G=0,B=0,A=0)
      SquareOffColor=(R=0,G=6,B=8,A=0)
      DarkTextColor=(R=0,G=0,B=0,A=0)
      WaitColor=(R=115,G=115,B=115,A=0)
      CountColor=(R=255,G=135,B=2,A=0)
      PlayColor=(R=2,G=255,B=8,A=0)
      ArenasText="ARENAS"
      ClickText="Click an arena to go there"
      F2Text="F2 for players"
      EscCloseText="close"
      EscBackText="back to arenas"
      KeysText="Arrow keys select"
      ConfirmText="confirm"
      JoinTitle="JOIN A TEAM"
      CreateTitle="CREATE A TEAM"
      RegisteredText="Registered Teams"
      NoTeamsText="No teams in this arena yet. Create one!"
      JoinText="Join"
      CreateText="Create"
      CancelText="Cancel"
      TeamNameText="Team Name"
      ArenaText="Arena:"
      TeamSizeText="Team Size:"
      JoinHelp="Pick a team with open slots and press Join."
      CreateHelp="You become team captain. Others can join via Join a Team."
      OpenText="Open"
      FullText="Full"
      BotsText="Bots"
      GoHereText="Go to"
      YouAreHereText="You are in this arena"
      SpectatingText="Spectating"
      PlayingText="Playing"
      QueueText="In queue"
      NextUpText="Next up"
      AdminText="ADMIN"
      AdminHelp="Server settings (you are logged in as admin)"
      AdminTitle="ADMIN SETTINGS"
      AdminNote="Changes are saved on the server at once (RocketArenaV2.ini)"
      AdminTabs(0)="RULES"
      AdminTabs(1)="WEAPONS"
      AdminTabs(2)="BOTS"
      AdminTabs(3)="SERVER"
      AdminTabs(4)="PLAYERS"
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
      SkillNames(0)="Novice"
      SkillNames(1)="Average"
      SkillNames(2)="Experienced"
      SkillNames(3)="Skilled"
      SkillNames(4)="Adept"
      SkillNames(5)="Masterful"
      SkillNames(6)="Inhuman"
      SkillNames(7)="Godlike"
      RoundsText="Rounds per match (best of)"
      SelfDamageText="Self damage"
      TeamDamageText="Team damage"
      ResetRulesText="Reset rules (all arenas)"
      ResetWeaponsText="Reset weapons (all arenas)"
      DefaultText="default"
      BotTeamsText="Bot teams"
      BotsCountText="Bots"
      BotSkillText="Bot skill (all arenas)"
      Force1on1Text="Force 1on1 (next map)"
      InstantRocketsText="Instant rocket fire"
      FallingDamageText="Falling damage"
      SpecSpeechText="Spectators can talk to players"
      BouncyText="Rocket jump height"
      RestartText="Restart map"
      LogoutText="Admin logout"
      KickText="Kick"
      BanText="Ban"
      SureText="Click again"
      NoOtherPlayersText="No other players on the server"
      SettingsText="SETTINGS"
      SettingsHelp="Your own options: announcer voice and the team list"
      SettingsTitle="SETTINGS"
      SettingsNote="Saved on your computer and used on every Rocket Arena server"
      VoiceText="Announcer voice"
      BuiltInVoice(0)="RocketArenaV2.RAVoiceMale"
      BuiltInVoice(1)="RocketArenaV2.RAVoiceFemale"
      BuiltInVoiceDesc(0)="Default Male Voice"
      BuiltInVoiceDesc(1)="Default Female Voice"
      TeamListMode(0)=1
      TeamListMode(1)=2
      TeamListMode(2)=0
      TeamListModeText(0)="On"
      TeamListModeText(1)="Transparent"
      TeamListModeText(2)="Off"
      TeamListText="Team list during matches"
      ChatLineH=20.000000
      ChatButtonText="CHAT"
      ChatHelp="Read the chat and write to your arena or to every arena"
      ChatTitle="CHAT"
      ChatNote="Enter sends  /  Up and Down: what you wrote before  /  PgUp, PgDn or the mouse wheel scroll"
      ArenaScopeText="This arena"
      AllScopeText="All arenas"
      SendText="Send"
      NoChatText="No messages yet. Everything said on the server since you joined shows up here."
      WriteArenaText="Write to the players in this arena..."
      WriteAllText="Write to every arena on the server..."
      AllTag="[ALL]"
      TeamTag="[TEAM]"
      OnText="ON"
      OffText="OFF"
}
