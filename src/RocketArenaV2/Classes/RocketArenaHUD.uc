class RocketArenaHUD extends ChallengeTeamHUD;

var color YellowColor;

// Center graphics.
var texture CenterTexture;
var float CenterTime, MaxCenterTime;

var bool bPoppedMain;
var RAWindowManager Manager;

var class<ScoreBoard> LastScoringType;

var RACanvas P;				// V2 drawing helpers (team list, queue panel, up next notice).
var bool bUpNextShown;

// The chat of this map (since you joined), for the chat page of the menu. A ring of
// the last 64 messages; ChatCount counts every message, so the newest is at
// (ChatCount - 1) % 64. ChatKind: 0 arena, 1 all arenas ("Global: "), 2 team.
var string ChatName[64], ChatText[64];
var byte ChatKind[64];
var int ChatCount;

simulated function HUDSetup(canvas canvas)
{
	Super(ChallengeHUD).HUDSetup(canvas);
	if ( (PawnOwner.PlayerReplicationInfo != None)
		&& (PawnOwner.PlayerReplicationInfo.Team < 4) )
	{
		HUDColor = TeamColor[PawnOwner.PlayerReplicationInfo.Team];
		SolidHUDColor = HUDColor;
		if ( Level.bHighDetailMode )
			HUDColor = Opacity * 0.0625 * HUDColor;
	}
}

simulated function Tick(float Delta)
{
	Super.Tick(Delta);
	if (CenterTime > 0)
		CenterTime -= Delta;
}

// Key binding commands (see ExtraRABindings). They live in the HUD so that RA works
// with any player class, e.g. the ones InstaGib+ forces on players.
exec function raMainMenu()
{
	local RAReplicationInfo RA;

	class'RATools'.static.GetRepInfo(PlayerOwner, PlayerOwner.GameReplicationInfo, RA);
	if (RA != None)
		RA.PopupMainMenu(RA.Arena);
}

exec function raPrevArena()
{
	local RAReplicationInfo RA;

	class'RATools'.static.GetRepInfo(PlayerOwner, PlayerOwner.GameReplicationInfo, RA);
	if (RA != None)
		RA.PrevArena();
}

exec function raNextArena()
{
	local RAReplicationInfo RA;

	class'RATools'.static.GetRepInfo(PlayerOwner, PlayerOwner.GameReplicationInfo, RA);
	if (RA != None)
		RA.NextArena();
}

exec function raEnterArena()
{
	local RAReplicationInfo RA;
	local RAGameReplicationInfo RAGRI;

	RAGRI = RAGameReplicationInfo(PlayerOwner.GameReplicationInfo);
	class'RATools'.static.GetRepInfo(PlayerOwner, RAGRI, RA);
	if (RA != None && RAGRI.ArenaGames[RA.Arena] != None)
		RAGRI.ArenaGames[RA.Arena].EnterArena(PlayerOwner);
}

// Opens the menu on its chat page.
exec function raChat()
{
	OpenChat();
}

function OpenChat()
{
	local RAReplicationInfo RA;

	class'RATools'.static.GetRepInfo(PlayerOwner, PlayerOwner.GameReplicationInfo, RA);
	if (RA == None)
		return;
	RA.PopupMainMenu(RA.Arena);
	if (Manager != None && Manager.MainMenu != None)
		Manager.MainMenu.OpenChat();
}

simulated function Message(PlayerReplicationInfo PRI, coerce string Msg, name MsgType)
{
	if ((MsgType == 'Say' || MsgType == 'TeamSay') && Msg != "")
		AddChat(PRI, Msg, MsgType == 'TeamSay');
	Super.Message(PRI, Msg, MsgType);
}

simulated function AddChat(PlayerReplicationInfo PRI, string Msg, bool bTeam)
{
	local int i;

	i = ChatCount % ArrayCount(ChatText);
	ChatName[i] = "";
	if (PRI != None)
		ChatName[i] = PRI.PlayerName;
	ChatKind[i] = 0;
	if (Left(Msg, 8) ~= "Global: ")
	{
		ChatKind[i] = 1;
		Msg = Mid(Msg, 8);
	}
	else if (bTeam)
		ChatKind[i] = 2;
	ChatText[i] = Msg;
	ChatCount++;
}

exec function GlobalTalk()
{
	PlayerOwner.Player.Console.TypedStr = "Say Global: ";
	PlayerOwner.Player.Console.bNoStuff = true;
	PlayerOwner.Player.Console.GotoState('Typing');
}

simulated function SetCenterMessage(texture Tex, int Time)
{
	CenterTexture = Tex;
	CenterTime = Time;
	MaxCenterTime = Time;
}

simulated function DrawCenterTexture(Canvas Canvas)
{
	local float Width, Height, X, Y, DrawScale, CenterRatio, ColorRatio;

	CenterRatio = (MaxCenterTime+1) / FClamp(CenterTime+1, MaxCenterTime, MaxCenterTime+1);
	ColorRatio = CenterTime / MaxCenterTime;
	DrawScale = Scale * CenterRatio;

	Width = CenterTexture.USize * DrawScale;
	X = (Canvas.ClipX - Width) / 2;

	Height = CenterTexture.VSize * DrawScale;
	Y = (Canvas.ClipY - Height - CenterTexture.VSize*4) / 2;

	Canvas.Style = 3;
	Canvas.DrawColor.R = 255 * ColorRatio;
	Canvas.DrawColor.G = 255 * ColorRatio;
	Canvas.DrawColor.B = 255 * ColorRatio;
	Canvas.SetPos(X, Y);
	Canvas.DrawIcon(CenterTexture, DrawScale);
	Canvas.Style = 1;
}

simulated function PostRender(canvas Canvas)
{

	if ((PlayerOwner != None) && (PlayerOwner.Scoring != None) && (PlayerOwner.ScoringType != LastScoringType))
	{
		PlayerOwner.Scoring.Destroy();
		PlayerOwner.Scoring = spawn(PlayerOwner.ScoringType, PlayerOwner);
		LastScoringType = PlayerOwner.ScoringType;
	}

	Super.PostRender(Canvas);

	if (PlayerOwner == None)
		return;

	if (PlayerOwner.PlayerReplicationInfo == None)
		return;

	if (bShowInfo)
		return;

	if (!PlayerOwner.bShowScores)
		DrawTeamStatus(Canvas);

	if (CenterTime > 0)
		DrawCenterTexture(Canvas);
}

simulated function DrawGameSynopsis(canvas Canvas)
{
}

simulated function DrawTeamStatus(canvas Canvas)
{
	local RAGameReplicationInfo RAGRI;
	local RAReplicationInfo RepInfo;

	RAGRI = RAGameReplicationInfo(PlayerOwner.GameReplicationInfo);
	class'RATools'.static.GetRepInfo(PlayerOwner, RAGRI, RepInfo);
	if (RepInfo == None || RAGRI.ArenaGames[RepInfo.Arena] == None)
		return;

	if (!bPoppedMain)
	{
		bPoppedMain = true;

		// Create a window manager for this player.
		Manager = Spawn(class'RAWindowManager', PlayerOwner);
		Manager.QuickKeyMode();
		Manager.CreateMainMenu( RAGRI.ArenaGames[0].MainMenuClass );
	}

	if (P == None)
		P = new class'RACanvas';
	P.Setup(Canvas);
	Canvas.bCenter = false;

	// The RA menu shows all of this itself, and the panels would overlap it.
	if (Manager != None && Manager.MainMenu != None && Manager.MainMenu.bWindowVisible
		&& Manager.LocalConsole != None && Manager.LocalConsole.IsInState('UWindow'))
		return;
	// Team list setting: 0 off, 1 on, 2 transparent.
	if (class'RocketArenaGame'.default.HUDTeamDisplay > 0)
		DrawTeamPanel(Canvas, RAGRI, RepInfo, class'RocketArenaGame'.default.HUDTeamDisplay == 2);
	if (PlayerOwner.PlayerReplicationInfo.Team == 255)
		DrawQueuePanel(Canvas, RAGRI, RepInfo);
	DrawUpNext(Canvas, RAGRI, RepInfo);
	DrawGetReady(Canvas, RAGRI, RepInfo);

	Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.DrawColor = WhiteColor;
}

// What the arena does now, above the team list.
simulated function string PeriodText(ArenaGame AG, RAGameReplicationInfo RAGRI, int Arena)
{
	if (AG.Period == PERIOD_PostMatch && AG.bWaitingForPlayers)
		return "Waiting for players";
	if (AG.Period == PERIOD_PostMatch && AG.Countdown > 0)
		return "Next match:"@AG.Countdown;
	if (AG.Period == PERIOD_PostRound && AG.Countdown > 0)
		return "Next round:"@AG.Countdown;
	if (AG.Period == PERIOD_Shakedown && AG.Countdown > 0)
		return "Get ready:"@AG.Countdown;
	return "Round"@AG.CurrentRound@"of"@RAGRI.WeaponInfo.Rule(Arena, 0);
}

// Right side: the round, and both teams (round wins before the name) with the health of their players
// (your team always; the other team when you are dead, spectating or between rounds).
// bLite: the transparent version, only the text (with a shadow) and the team lines.
simulated function DrawTeamPanel(canvas C, RAGameReplicationInfo RAGRI, RAReplicationInfo MyRA, bool bLite)
{
	local ArenaGame AG;
	local float X, Y, W, H;
	local int FirstTeam, N0, N1;
	local bool bShowOther;

	AG = RAGRI.ArenaGames[MyRA.Arena];
	FirstTeam = PlayerOwner.PlayerReplicationInfo.Team;
	if (FirstTeam > 1)
		FirstTeam = 0;
	bShowOther = PlayerOwner.PlayerReplicationInfo.Team == 255 || PlayerOwner.Health <= 0 || AG.Period != PERIOD_GameTime;
	N0 = CountTeam(RAGRI, MyRA.Arena, FirstTeam);
	N1 = CountTeam(RAGRI, MyRA.Arena, 1 - FirstTeam);

	W = P.U(170);
	X = C.ClipX - W - P.U(10);
	Y = C.ClipY / 3 - P.U(30);
	H = P.U(28);
	if (N0 > 0)
		H += P.U(15 + 17 * N0 + 3);
	if (N1 > 0)
		H += P.U(15 + 17 * N1 + 3);
	H += P.U(4);

	if (!bLite)
	{
		P.Panel(C, X, Y, W, H);
		P.Fill(C, X, Y, W, P.U(2), P.GoldColor);
	}
	P.bShadow = bLite;
	C.Font = P.GetFont(11, true, MyFonts.GetSmallestFont(C.ClipX));
	P.Text(C, X + P.U(8), Y + P.U(7), PeriodText(AG, RAGRI, MyRA.Arena), P.WhiteColor);
	Y += P.U(28);
	if (N0 > 0)
		Y = DrawTeamBlock(C, RAGRI, AG, MyRA, FirstTeam, X, Y, W, true);
	if (N1 > 0)
		DrawTeamBlock(C, RAGRI, AG, MyRA, 1 - FirstTeam, X, Y, W, bShowOther);
	P.bShadow = false;
}

simulated function int CountTeam(RAGameReplicationInfo RAGRI, int Arena, int Team)
{
	local RAReplicationInfo R;
	local int N;

	for (R=RAGRI.RepInfoList; R!=None; R=R.NextRepInfo)
		if (R.OwnerPRI != None && R.OwnerPRI.Team == Team && R.Arena == Arena)
			N++;
	return N;
}

simulated function float DrawTeamBlock(canvas C, RAGameReplicationInfo RAGRI, ArenaGame AG, RAReplicationInfo MyRA, int Team, float X, float Y, float W, bool bShowHealth)
{
	local RAReplicationInfo R;
	local float Top, NameW;
	local string Name;
	local color TeamCol, Col;

	Top = Y;
	if (Team == 0)
		TeamCol = P.RedTeamColor;
	else
		TeamCol = P.BlueTeamColor;
	if (RATeamInfo(AG.Teams[Team]) != None)
		Name = AG.Teams[Team].TeamName;
	else if (Team == 0)
		Name = "Red Team";
	else
		Name = "Blue Team";
	if (AG.Teams[0] != None && AG.Teams[1] != None)
		Name = "("$int(AG.Teams[Team].Score)$")"@Name;
	C.Font = P.GetFont(10, true, MyFonts.GetSmallestFont(C.ClipX));
	if (Team == PlayerOwner.PlayerReplicationInfo.Team)
		P.Text(C, X + P.U(12), Y, P.Fit(C, Name, W - P.U(20)), P.GoldColor);
	else
		P.Text(C, X + P.U(12), Y, P.Fit(C, Name, W - P.U(20)), P.DetailColor);
	Y += P.U(15);

	NameW = W - P.U(12 + 8 + 36);
	for (R=RAGRI.RepInfoList; R!=None; R=R.NextRepInfo)
	{
		if (R.OwnerPRI == None || R.OwnerPRI.Team != Team || R.Arena != MyRA.Arena)
			continue;
		C.Font = P.GetFont(11, false, MyFonts.GetSmallestFont(C.ClipX));
		if (R.Health <= 0)
			Col = P.DimColor;
		else
			Col = P.WhiteColor;
		P.Text(C, X + P.U(12), Y, P.Fit(C, R.OwnerPRI.PlayerName, NameW), Col);

		C.Font = P.GetFont(10, true, MyFonts.GetSmallestFont(C.ClipX));
		if (!bShowHealth)
			P.TextRight(C, X + W - P.U(8), Y, "?", P.DimColor);
		else if (R.Health <= 0)
			P.TextRight(C, X + W - P.U(8), Y, "dead", P.DimColor);
		else
		{
			Col = P.GreenColor;
			if (R.Health < 50)
				Col = P.YellowColor;
			P.TextRight(C, X + W - P.U(8), Y, R.Health, Col);
		}
		Y += P.U(17);
	}
	P.Fill(C, X + P.U(5), Top, P.U(2), Y - Top - P.U(2), TeamCol);
	return Y + P.U(3);
}

// Bottom left, while you are not playing: one thing to know, in two lines. Your team and
// what it waits for, or how to join when you only watch. Plus the players in the other
// arenas, when there are any.
simulated function DrawQueuePanel(canvas C, RAGameReplicationInfo RAGRI, RAReplicationInfo MyRA)
{
	local float X, Y, W, H;
	local string Title, S, OthersText;
	local color Col;
	local int TeamSize, Others;

	if (MyRA.Team != None)
	{
		Title = MyRA.Team.TeamName;
		TeamSize = RAGRI.ArenaInfo.ArenaTeamSize[MyRA.Arena];
		// WaitingPos 0 and 1 are the teams of the match (or, between matches, the next
		// two), so 2 is first in line.
		if (MyRA.Team.Size < TeamSize && MyRA.Team.bWaitForFull)
		{
			S = "Waiting for"@class'RATools'.static.Plural(TeamSize - MyRA.Team.Size, "more player");
			Col = P.YellowColor;
		}
		else if (MyRA.Team.WaitingPos == -1)
		{
			S = "Not in the queue";
			Col = P.YellowColor;
		}
		else if (MyRA.Team.WaitingPos <= 2)
		{
			S = "Next up, plays the winner";
			Col = P.GreenColor;
		}
		else
		{
			S = "Queue position"@MyRA.Team.WaitingPos - 1;
			Col = P.WhiteColor;
		}
	}
	else
	{
		Title = "Spectating";
		S = "Press the menu key to join";
		Col = P.DimColor;
	}

	// A third line while there are players elsewhere, so you know you could go there.
	Others = class'RATools'.static.OtherArenasCount(RAGRI, MyRA.Arena);
	if (Others > 0)
		OthersText = class'RATools'.static.Plural(Others, "player")@"in other arenas";

	C.Font = P.GetFont(12, true, MyFonts.GetSmallFont(C.ClipX));
	W = P.TextW(C, Title);
	C.Font = P.GetFont(10, false, MyFonts.GetSmallestFont(C.ClipX));
	W = FClamp(FMax(FMax(W, P.TextW(C, S)), P.TextW(C, OthersText)) + P.U(16), P.U(150), P.U(235));
	H = P.U(40);
	if (OthersText != "")
		H += P.U(15);
	X = P.U(16);
	Y = C.ClipY - H - P.U(24);
	P.Panel(C, X, Y, W, H);

	C.Font = P.GetFont(12, true, MyFonts.GetSmallFont(C.ClipX));
	if (MyRA.Team != None)
		P.Text(C, X + P.U(8), Y + P.U(5), P.Fit(C, Title, W - P.U(16)), P.GoldColor);
	else
		P.Text(C, X + P.U(8), Y + P.U(5), Title, P.WhiteColor);
	C.Font = P.GetFont(10, false, MyFonts.GetSmallestFont(C.ClipX));
	P.Text(C, X + P.U(8), Y + P.U(22), P.Fit(C, S, W - P.U(16)), Col);
	if (OthersText != "")
		P.Text(C, X + P.U(8), Y + P.U(37), P.Fit(C, OthersText, W - P.U(16)), P.DetailColor);
}

// "You're up next": the match before yours just ended and your queued team plays the
// next one. Shown during that countdown only, with one sound when it appears.
simulated function DrawUpNext(canvas C, RAGameReplicationInfo RAGRI, RAReplicationInfo MyRA)
{
	local ArenaGame_Multi AG;
	local RATeamInfo T, Other;
	local float X, Y, W, H, XL, YL;
	local string S;

	AG = ArenaGame_Multi(RAGRI.ArenaGames[MyRA.Arena]);
	if (AG == None || MyRA.Team == None || PlayerOwner.PlayerReplicationInfo.Team != 255
		|| AG.Period != PERIOD_PostMatch || AG.bWaitingForPlayers || AG.Countdown <= 0
		|| MyRA.Team.WaitingPos < 0 || MyRA.Team.WaitingPos > 1
		|| MyRA.Team == AG.Teams[0] || MyRA.Team == AG.Teams[1])
	{
		bUpNextShown = false;
		return;
	}
	// The sound waits until the "... wins the match" announcement (sent when the
	// countdown starts) is over, so the two voices do not overlap.
	if (!bUpNextShown && AG.Countdown <= 3)
	{
		bUpNextShown = true;
		if (class'RocketArenaGame'.default.NewVoiceTheme != None)
			PlayerOwner.ClientPlaySound(class'RocketArenaGame'.default.NewVoiceTheme.default.Prepare,, true);
	}
	for (T=AG.TeamList; T!=None; T=T.NextTeam)
		if (T != MyRA.Team && (T.WaitingPos == 0 || T.WaitingPos == 1))
			Other = T;

	W = P.U(380);
	H = P.U(75);
	X = (C.ClipX - W) / 2;
	Y = P.U(150);
	P.Panel(C, X, Y, W, H);
	P.Fill(C, X, Y, W, P.U(2), P.GoldColor);
	P.Tex(C, X + (W - P.U(36) * 512 / 76) / 2, Y + P.U(9), P.U(36) * 512 / 76, P.U(36), Texture'RocketArenaV2Media.TitleUpNext', 512, 76);
	S = MyRA.Team.TeamName;
	if (Other != None)
		S = S$"  vs  "$Other.TeamName;
	S = S$"   "$Chr(183)$"   match starts in"@AG.Countdown;
	C.Font = P.GetFont(13, false, MyFonts.GetSmallFont(C.ClipX));
	C.StrLen(S, XL, YL);
	P.Text(C, X + (W - XL) / 2, Y + P.U(52), S, P.WhiteColor);
}

// "Get ready": the countdown before each round, for the players who spawn at FIGHT
// (everyone waits as a spectator until then). The countdown itself is the big 3-2-1.
simulated function DrawGetReady(canvas C, RAGameReplicationInfo RAGRI, RAReplicationInfo MyRA)
{
	local ArenaGame_Clan AG;
	local int Me;
	local float X, Y, W, H, XL, YL;
	local string S;

	AG = ArenaGame_Clan(RAGRI.ArenaGames[MyRA.Arena]);
	Me = PlayerOwner.PlayerReplicationInfo.Team;
	if (AG == None || Me > 1 || AG.Period != PERIOD_Shakedown || AG.Countdown <= 0
		|| AG.Teams[0] == None || AG.Teams[1] == None)
		return;

	W = P.U(380);
	H = P.U(75);
	X = (C.ClipX - W) / 2;
	Y = P.U(70);
	P.Panel(C, X, Y, W, H);
	P.Fill(C, X, Y, W, P.U(2), P.GoldColor);
	P.Tex(C, X + (W - P.U(36) * 390 / 86) / 2, Y + P.U(9), P.U(36) * 390 / 86, P.U(36), Texture'RocketArenaV2Media.TitleGetReady', 390, 86);
	S = "Round"@AG.CurrentRound@"of"@RAGRI.WeaponInfo.Rule(MyRA.Arena, 0)$"   "$Chr(183)$"   "
		$AG.Teams[Me].TeamName$"  vs  "$AG.Teams[1 - Me].TeamName$"   "$Chr(183)$"   "
		$int(AG.Teams[Me].Score)$" - "$int(AG.Teams[1 - Me].Score);
	C.Font = P.GetFont(13, false, MyFonts.GetSmallFont(C.ClipX));
	S = P.Fit(C, S, W - P.U(16));
	C.StrLen(S, XL, YL);
	P.Text(C, X + (W - XL) / 2, Y + P.U(52), S, P.WhiteColor);
}

simulated function SetIDColor( Canvas Canvas, int type )
{
	if (IdentifyTarget.Team == 255)
		Canvas.DrawColor = WhiteColor;
	else
		Super.SetIdColor(Canvas, Type);
}

defaultproperties
{
      YellowColor=(R=255,G=255,B=0,A=0)
      CenterTexture=None
      CenterTime=0.000000
      MaxCenterTime=0.000000
      bPoppedMain=False
      Manager=None
      LastScoringType=None
      ServerInfoClass=Class'RocketArenaV2.RAServerInfo'
}
