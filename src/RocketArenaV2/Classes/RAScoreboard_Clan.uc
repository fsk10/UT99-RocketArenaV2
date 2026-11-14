// F1 scoreboard of an arena, in the V2 menu style: a versus bar with the two teams and
// the score, the players of both sides mirrored around the middle, a side panel with
// the queue (Multi) or the spectators (Clan), and under them the kill matrix of the
// players in the arena. Used by RAScoreboard_Multi as well.
class RAScoreboard_Clan extends TeamScoreboard;

var RACanvas P;
var PlayerReplicationInfo ListPRI[32];
var RAReplicationInfo ListRA[32];
var byte ListSide[32];
var int NumList;
var RATeamInfo QueueTeams[16];
var int NumQueue;

var localized string PlayerText, WinText, FragsText, PingText, CloseText, QueueTitle, SpectatorsTitle;
var localized string TeamsText, NoQueueText, NoSpectatorsText, SpectatingText, ReadyText, NeedsText;
var localized string WinsText, FlawlessText, FirstToText, RoundWinsText, RedName, BlueName;
var localized string OtherArenasText, PlayerWord, KillsTitle, KillsHelp;
var int KillOrder[32];			// Kill matrix: ListPRI indexes, both sides first.
var int RowOrder[32];

function ShowScores( canvas C )
{
	local RAGameReplicationInfo RAGRI;
	local RAReplicationInfo RA;
	local ArenaGame AG;
	local float MX, MY, MW, MH, QX, QW, SideH, Rows, KY;
	local bool bVersus;
	local int i, L, R;

	RAGRI = RAGameReplicationInfo(PlayerPawn(Owner).GameReplicationInfo);
	if (RAGRI == None || RAGRI.ArenaInfo == None)
		return;
	class'RATools'.static.GetRepInfo(PlayerPawn(Owner), RAGRI, RA);
	if (RA == None || RAGRI.ArenaGames[RA.Arena] == None)
		return;
	AG = RAGRI.ArenaGames[RA.Arena];

	if (P == None)
		P = new class'RACanvas';
	P.Setup(C);
	C.bCenter = false;

	bVersus = Versus(RAGRI, RA.Arena);
	GatherPlayers(RAGRI, RA.Arena, bVersus);
	GatherQueue(RAGRI, RA.Arena, bVersus);
	for (i=0; i<NumList; i++)
	{
		if (ListSide[i] == 0)
			L++;
		else if (ListSide[i] == 1)
			R++;
	}
	Rows = Max(Max(L, R), 1);

	MW = P.U(590);
	QW = P.U(260);
	MX = (C.ClipX - MW - QW - P.U(12)) / 2;
	QX = MX + MW + P.U(12);
	MY = P.U(35);
	MH = P.U(134 + 24 + 44) + Rows * P.U(22);
	SideH = P.U(64 + 12) + Max(SideCount(), 1) * P.U(56);
	MH = FMax(MH, SideH);

	DrawMain(C, RAGRI, RA, AG, MX, MY, MW, MH, bVersus);
	DrawSide(C, RAGRI, RA.Arena, QX, MY, QW, MH);
	KY = MY + MH + P.U(8);
	KY += DrawKills(C, RA.Arena, MX, KY, MW + P.U(12) + QW, C.ClipY - P.U(46) - KY);
	DrawOtherArenas(C, RAGRI, RA.Arena, MX, KY, MW + P.U(12) + QW);

	C.Style = ERenderStyle.STY_Normal;
	C.DrawColor = P.WhiteColor;
}

// The two teams of the running match are known (also between its rounds).
function bool Versus(RAGameReplicationInfo RAGRI, int Arena)
{
	local ArenaGame AG;

	AG = RAGRI.ArenaGames[Arena];
	if (AG.Teams[0] == None || AG.Teams[1] == None)
		return false;
	if (ArenaGame_Multi(AG) != None)
		return class'RATools'.static.ArenaState(RAGRI, Arena) >= 2 && RATeamInfo(AG.Teams[0]) != None && RATeamInfo(AG.Teams[1]) != None;
	return true;
}

// Players of the arena: side 0/1 = the two teams, 2 = other (queue, spectators).
function GatherPlayers(RAGameReplicationInfo RAGRI, int Arena, bool bVersus)
{
	local PlayerIterator PIter;
	local ArenaGame AG;
	local byte Side;

	AG = RAGRI.ArenaGames[Arena];
	NumList = 0;
	PIter = class'RATools'.static.PlayersInArena(RAGRI, Arena);
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None && NumList < ArrayCount(ListPRI); PIter.Next())
	{
		Side = 2;
		if (ArenaGame_Multi(AG) != None)
		{
			if (bVersus && PIter.RARepInfo.Team != None && PIter.RARepInfo.Team == AG.Teams[0])
				Side = 0;
			else if (bVersus && PIter.RARepInfo.Team != None && PIter.RARepInfo.Team == AG.Teams[1])
				Side = 1;
		}
		else if (PIter.PRI.Team < 2)
			Side = PIter.PRI.Team;
		ListPRI[NumList] = PIter.PRI;
		ListRA[NumList] = PIter.RARepInfo;
		ListSide[NumList] = Side;
		NumList++;
	}
}

// Multi: the teams waiting to play, in queue order.
function GatherQueue(RAGameReplicationInfo RAGRI, int Arena, bool bVersus)
{
	local ArenaGame_Multi Multi;
	local RATeamInfo T, Best;
	local int i, MinPos, LastPos;

	NumQueue = 0;
	Multi = ArenaGame_Multi(RAGRI.ArenaGames[Arena]);
	if (Multi == None)
		return;
	LastPos = -1;
	for (i=0; i<ArrayCount(QueueTeams); i++)
	{
		Best = None;
		MinPos = 999;
		for (T=Multi.TeamList; T!=None; T=T.NextTeam)
		{
			if (T.WaitingPos <= LastPos || T.WaitingPos >= MinPos)
				continue;
			if (bVersus && (T == Multi.Teams[0] || T == Multi.Teams[1]))
				continue;
			Best = T;
			MinPos = T.WaitingPos;
		}
		if (Best == None)
			break;
		QueueTeams[NumQueue++] = Best;
		LastPos = MinPos;
	}
}

function int SideCount()
{
	local int i, N;

	if (NumQueue > 0)
		return NumQueue;
	for (i=0; i<NumList; i++)
		if (ListSide[i] == 2)
			N++;
	return N;
}

function DrawMain(canvas C, RAGameReplicationInfo RAGRI, RAReplicationInfo RA, ArenaGame AG, float X, float Y, float W, float H, bool bVersus)
{
	local float BY, BH, CX, TY, LY, RY, XL, YL;
	local int i, Wins;
	local string S;
	local ArenaGame_Multi Multi;

	Multi = ArenaGame_Multi(AG);
	P.Panel(C, X, Y, W, H);

	// Header: logo, arena and state.
	P.Tex(C, X + P.U(14), Y + P.U(12), P.U(27) * 865 / 128, P.U(27), Texture'RocketArenaV2Media.Logo', 865, 128);
	C.Font = P.GetFont(15, true, MyFonts.GetSmallFont(C.ClipX));
	P.TextRight(C, X + W - P.U(14), Y + P.U(8), RAGRI.ArenaInfo.ArenaNames[RA.Arena]$"  "$Chr(183)$"  "$class'RATools'.static.ArenaMode(RAGRI, RA.Arena), P.GoldColor);
	C.Font = P.GetFont(11, false, MyFonts.GetSmallestFont(C.ClipX));
	Wins = RAGRI.WeaponInfo.Rule(RA.Arena, 0) / 2 + 1;
	P.TextRight(C, X + W - P.U(14), Y + P.U(29), class'RATools'.static.ArenaStatus(RAGRI, RA.Arena)$"  "$Chr(183)$"  "$FirstToText@Wins@RoundWinsText, P.DetailColor);
	P.Fill(C, X, Y + P.U(51), W, P.U(2), P.GoldColor);

	// Versus bar.
	BY = Y + P.U(64);
	BH = P.U(56);
	CX = X + W / 2;
	P.Fill(C, X + P.U(14), BY, W - P.U(28), BH, P.CardColor);
	if (bVersus)
	{
		P.Fill(C, X + P.U(14), BY, P.U(2), BH, P.RedTeamColor);
		P.Fill(C, X + W - P.U(16), BY, P.U(2), BH, P.BlueTeamColor);
		DrawTeamName(C, RAGRI, AG, 0, X + P.U(30), BY, false, RA);
		DrawTeamName(C, RAGRI, AG, 1, X + W - P.U(30), BY, true, RA);
		C.Font = MyFonts.GetHugeFont(C.ClipX);
		S = int(AG.Teams[0].Score)$" - "$int(AG.Teams[1].Score);
		C.StrLen(S, XL, YL);
		P.Text(C, CX - XL / 2, BY + (BH - YL) / 2, S, P.WhiteColor);
	}
	else
	{
		C.Font = P.GetFont(15, false, MyFonts.GetSmallFont(C.ClipX));
		C.StrLen("A", XL, YL);
		P.TextCenter(C, CX, BY + (BH - YL) / 2, class'RATools'.static.ArenaStatus(RAGRI, RA.Arena), P.StateColor(class'RATools'.static.ArenaState(RAGRI, RA.Arena)));
	}

	// Player tables, mirrored around the middle.
	TY = BY + BH + P.U(14);
	C.Font = P.GetFont(10, true, MyFonts.GetSmallestFont(C.ClipX));
	P.Text(C, X + P.U(28), TY, PlayerText, P.TealColor);
	P.TextRight(C, CX - P.U(75), TY, FragsText, P.TealColor);
	P.TextRight(C, CX - P.U(20), TY, PingText, P.TealColor);
	P.Text(C, CX + P.U(20), TY, PingText, P.TealColor);
	P.Text(C, CX + P.U(75), TY, FragsText, P.TealColor);
	P.TextRight(C, X + W - P.U(28), TY, PlayerText, P.TealColor);
	LY = TY + P.U(22);
	RY = LY;
	for (i=0; i<NumList; i++)
	{
		if (ListSide[i] == 0)
		{
			DrawPlayer(C, RAGRI, RA, i, X + P.U(28), CX, LY, false);
			LY += P.U(22);
		}
		else if (ListSide[i] == 1)
		{
			DrawPlayer(C, RAGRI, RA, i, X + W - P.U(28), CX, RY, true);
			RY += P.U(22);
		}
	}
	P.Fill(C, CX, TY, 1, FMax(LY, RY) - TY, P.LineColor);

	// Footer.
	C.Font = P.GetFont(11, false, MyFonts.GetSmallestFont(C.ClipX));
	if (Multi != None)
	{
		S = class'RATools'.static.PlayerNames(RAGRI, RA.Arena, None, 255);
		if (S != "")
		{
			P.Text(C, X + P.U(14), Y + H - P.U(22), SpectatingText, P.DimColor);
			P.Text(C, X + P.U(14) + P.TextW(C, SpectatingText$" "), Y + H - P.U(22), P.Fit(C, S, W - P.U(150)), P.WhiteColor);
		}
	}
	P.TextRight(C, X + W - P.U(14), Y + H - P.U(22), "F1  "$Chr(183)$"  "$CloseText, P.DetailColor);
}

function DrawTeamName(canvas C, RAGameReplicationInfo RAGRI, ArenaGame AG, int Side, float X, float Y, bool bRight, RAReplicationInfo RA)
{
	local string Name, Sub;
	local color Col;
	local RATeamInfo T;

	T = RATeamInfo(AG.Teams[Side]);
	if (ArenaGame_Multi(AG) != None && T != None)
	{
		Name = T.TeamName;
		Sub = T.MatchWins@WinsText$"  "$Chr(183)$"  "$T.MatchFlawless@FlawlessText;
	}
	else if (Side == 0)
		Name = RedName;
	else
		Name = BlueName;
	Col = P.WhiteColor;
	if ((T != None && RA.Team == T) || (ArenaGame_Multi(AG) == None && PlayerPawn(Owner).PlayerReplicationInfo.Team == Side))
		Col = P.GoldColor;

	C.Font = P.GetFont(18, true, MyFonts.GetSmallFont(C.ClipX));
	Name = P.Fit(C, Name, P.U(190));
	if (bRight)
		P.TextRight(C, X, Y + P.U(8), Name, Col);
	else
		P.Text(C, X, Y + P.U(8), Name, Col);
	if (Sub != "")
	{
		C.Font = P.GetFont(10, false, MyFonts.GetSmallestFont(C.ClipX));
		if (bRight)
			P.TextRight(C, X, Y + P.U(35), Sub, P.DetailColor);
		else
			P.Text(C, X, Y + P.U(35), Sub, P.DetailColor);
	}
}

function DrawPlayer(canvas C, RAGameReplicationInfo RAGRI, RAReplicationInfo MyRA, int i, float X, float CX, float Y, bool bRight)
{
	local PlayerReplicationInfo PRI;
	local RAReplicationInfo RA;
	local color NameCol;

	PRI = ListPRI[i];
	RA = ListRA[i];
	NameCol = P.WhiteColor;
	if (PRI == PlayerPawn(Owner).PlayerReplicationInfo)
		NameCol = P.GoldColor;
	else if (RA.Health <= 0)
		NameCol = P.DimColor;

	C.Font = P.GetFont(14, false, MyFonts.GetSmallFont(C.ClipX));
	if (bRight)
	{
		P.TextRight(C, X, Y, P.Fit(C, PRI.PlayerName, X - CX - P.U(125)), NameCol);
		P.Text(C, CX + P.U(20), Y, PRI.Ping, P.DetailColor);
		P.Text(C, CX + P.U(75), Y, int(PRI.Score), P.WhiteColor);
	}
	else
	{
		P.Text(C, X, Y, P.Fit(C, PRI.PlayerName, CX - X - P.U(125)), NameCol);
		P.TextRight(C, CX - P.U(20), Y, PRI.Ping, P.DetailColor);
		P.TextRight(C, CX - P.U(75), Y, int(PRI.Score), P.WhiteColor);
	}
}

// Name for the kill matrix: names longer than MaxChars are cut to it and get ".."
// (not when that would not make them shorter).
function string ShortName(string S, int MaxChars)
{
	if (MaxChars <= 0 || Len(S) <= MaxChars + 2)
		return S;
	return Left(S, MaxChars)$"..";
}

// Kill matrix of the players in the arena: row = killer, column = victim. As many
// columns as fit: when they don't, all long names are cut to the same length, first
// the longest name less 3 characters, then one more at a time. Rows as many as the
// height allows. The own player stays in view. Returns the height used (0 when fewer
// than two players are in the arena).
function float DrawKills(canvas C, int Arena, float X, float Y, float W, float MaxH)
{
	local int i, j, N, NR, NC, Longest, MaxChars, Kills;
	local float LabelW, ColW, NumW, RowH, H, CX, RY;
	local bool bFits;
	local color Col;
	local PlayerReplicationInfo Me;

	// Both sides first, then the others; the order of the tables above.
	for (j=0; j<3; j++)
		for (i=0; i<NumList; i++)
			if (ListSide[i] == j)
				KillOrder[N++] = i;
	RowH = P.U(20);
	NR = Min(N, int((MaxH - P.U(48)) / RowH));
	if (N < 2 || NR < 2)
		return 0;
	Me = PlayerPawn(Owner).PlayerReplicationInfo;
	for (i=0; i<N; i++)
	{
		RowOrder[i] = KillOrder[i];
		Longest = Max(Longest, Len(ListPRI[KillOrder[i]].PlayerName));
	}
	KeepSelf(RowOrder, NR, N);

	C.Font = P.GetFont(12, false, MyFonts.GetSmallFont(C.ClipX));
	NumW = P.TextW(C, "000");
	MaxChars = 0;
	while (true)
	{
		LabelW = 0;
		ColW = NumW;
		for (i=0; i<N; i++)
		{
			ColW = FMax(ColW, P.TextW(C, ShortName(ListPRI[KillOrder[i]].PlayerName, MaxChars)));
			if (i < NR)
				LabelW = FMax(LabelW, P.TextW(C, ShortName(ListPRI[RowOrder[i]].PlayerName, MaxChars)));
		}
		ColW += P.U(14);
		bFits = P.U(28) + LabelW + P.U(16) + N * ColW <= W;
		if (bFits || MaxChars == 3)
			break;
		if (MaxChars == 0)
			MaxChars = Max(3, Longest - 3);
		else
			MaxChars--;
	}
	NC = N;
	if (!bFits)
		NC = Max(2, int((W - P.U(28) - LabelW - P.U(16)) / ColW));
	KeepSelf(KillOrder, NC, N);

	H = P.U(48) + NR * RowH;
	P.Panel(C, X, Y, W, H);
	C.Font = P.GetFont(11, true, MyFonts.GetSmallestFont(C.ClipX));
	P.Text(C, X + P.U(14), Y + P.U(9), KillsTitle, P.TealColor);
	C.Font = P.GetFont(11, false, MyFonts.GetSmallestFont(C.ClipX));
	P.TextRight(C, X + W - P.U(14), Y + P.U(9), KillsHelp, P.DetailColor);

	// Column heads: the victims.
	C.Font = P.GetFont(12, false, MyFonts.GetSmallFont(C.ClipX));
	CX = X + P.U(14) + LabelW + P.U(16);
	for (j=0; j<NC; j++)
	{
		Col = P.TealColor;
		if (ListPRI[KillOrder[j]] == Me)
			Col = P.GoldColor;
		P.TextCenter(C, CX + (j + 0.5) * ColW, Y + P.U(28), ShortName(ListPRI[KillOrder[j]].PlayerName, MaxChars), Col);
	}

	// Rows: the killers.
	RY = Y + P.U(48);
	for (i=0; i<NR; i++)
	{
		if (ListPRI[RowOrder[i]] == Me)
		{
			P.Fill(C, X + P.U(8), RY - P.U(2), W - P.U(16), RowH, P.CardColor);
			Col = P.GoldColor;
		}
		else
			Col = P.WhiteColor;
		P.Text(C, X + P.U(14), RY, ShortName(ListPRI[RowOrder[i]].PlayerName, MaxChars), Col);
		for (j=0; j<NC; j++)
		{
			if (RowOrder[i] == KillOrder[j])
			{
				P.TextCenter(C, CX + (j + 0.5) * ColW, RY, Chr(183), P.DimColor);
				continue;
			}
			Kills = ListRA[RowOrder[i]].KillsOf(ListPRI[KillOrder[j]], Arena);
			if (Kills > 0)
				P.TextCenter(C, CX + (j + 0.5) * ColW, RY, Kills, P.WhiteColor);
			else
				P.TextCenter(C, CX + (j + 0.5) * ColW, RY, "0", P.DimColor);
		}
		RY += RowH;
	}
	return H + P.U(8);
}

// Only the first Shown of Order[0..N-1] are drawn: the own player takes the last
// place if he would not be among them.
function KeepSelf(out int Order[32], int Shown, int N)
{
	local int i;

	for (i=Shown; i<N; i++)
		if (ListPRI[Order[i]] == PlayerPawn(Owner).PlayerReplicationInfo)
			Order[Shown - 1] = Order[i];
}

// A strip under the panels: the other arenas and how many players are in each.
function DrawOtherArenas(canvas C, RAGameReplicationInfo RAGRI, int Arena, float X, float Y, float W)
{
	local int i, n;
	local float TX, NameW, H;
	local string S;
	local color Col;

	for (i=0; i<ArrayCount(RAGRI.ArenaGames); i++)
		if (i != Arena && RAGRI.ArenaGames[i] != None && RAGRI.ArenaInfo.ArenaNames[i] != "")
			n++;
	if (n == 0)
		return;
	H = P.U(30);
	P.Panel(C, X, Y, W, H);
	C.Font = P.GetFont(11, true, MyFonts.GetSmallestFont(C.ClipX));
	P.Text(C, X + P.U(14), Y + P.U(9), OtherArenasText, P.TealColor);
	TX = X + P.U(14) + P.TextW(C, OtherArenasText) + P.U(20);
	for (i=0; i<ArrayCount(RAGRI.ArenaGames); i++)
	{
		if (i == Arena || RAGRI.ArenaGames[i] == None || RAGRI.ArenaInfo.ArenaNames[i] == "")
			continue;
		n = class'RATools'.static.HumanCount(RAGRI, i);
		S = class'RATools'.static.Plural(n, PlayerWord);
		C.Font = P.GetFont(12, true, MyFonts.GetSmallFont(C.ClipX));
		NameW = P.TextW(C, RAGRI.ArenaInfo.ArenaNames[i]$"  ");
		C.Font = P.GetFont(12, false, MyFonts.GetSmallFont(C.ClipX));
		if (TX + NameW + P.TextW(C, S) > X + W - P.U(14))
			break;
		Col = P.WhiteColor;
		if (n == 0)
			Col = P.DimColor;
		C.Font = P.GetFont(12, true, MyFonts.GetSmallFont(C.ClipX));
		P.Text(C, TX, Y + P.U(8), RAGRI.ArenaInfo.ArenaNames[i], Col);
		C.Font = P.GetFont(12, false, MyFonts.GetSmallFont(C.ClipX));
		if (n > 0)
			Col = P.GoldColor;
		P.Text(C, TX + NameW, Y + P.U(8), S, Col);
		TX += NameW + P.TextW(C, S) + P.U(28);
	}
}

// Right panel: the queue in a Multi arena, the spectators otherwise.
function DrawSide(canvas C, RAGameReplicationInfo RAGRI, int Arena, float X, float Y, float W, float H)
{
	local int i, N, TeamSize;
	local float RY;
	local RATeamInfo T;

	P.Panel(C, X, Y, W, H);
	C.Font = P.GetFont(14, true, MyFonts.GetSmallFont(C.ClipX));
	if (ArenaGame_Multi(RAGRI.ArenaGames[Arena]) != None)
		P.Text(C, X + P.U(14), Y + P.U(16), QueueTitle, P.TealColor);
	else
		P.Text(C, X + P.U(14), Y + P.U(16), SpectatorsTitle, P.TealColor);
	P.Fill(C, X, Y + P.U(51), W, P.U(2), P.GoldColor);
	RY = Y + P.U(64);

	if (ArenaGame_Multi(RAGRI.ArenaGames[Arena]) != None)
	{
		C.Font = P.GetFont(11, false, MyFonts.GetSmallestFont(C.ClipX));
		P.TextRight(C, X + W - P.U(14), Y + P.U(19), class'RATools'.static.Plural(NumQueue, TeamsText), P.DetailColor);
		TeamSize = RAGRI.ArenaInfo.ArenaTeamSize[Arena];
		for (i=0; i<NumQueue; i++)
		{
			T = QueueTeams[i];
			P.Fill(C, X + P.U(12), RY, W - P.U(24), P.U(48), P.CardColor);
			C.Font = P.GetFont(22, true, MyFonts.GetSmallFont(C.ClipX));
			if (i == 0)
				P.Text(C, X + P.U(22), RY + P.U(11), i + 1, P.GoldColor);
			else
				P.Text(C, X + P.U(22), RY + P.U(11), i + 1, P.DimColor);
			C.Font = P.GetFont(14, true, MyFonts.GetSmallFont(C.ClipX));
			P.Text(C, X + P.U(50), RY + P.U(6), P.Fit(C, T.TeamName, W - P.U(140)), P.WhiteColor);
			C.Font = P.GetFont(11, false, MyFonts.GetSmallestFont(C.ClipX));
			P.Text(C, X + P.U(50), RY + P.U(27), P.Fit(C, class'RATools'.static.PlayerNames(RAGRI, Arena, T), W - P.U(140)), P.DetailColor);
			C.Font = P.GetFont(11, true, MyFonts.GetSmallestFont(C.ClipX));
			P.TextRight(C, X + W - P.U(24), RY + P.U(7), class'RATools'.static.Plural(T.MatchWins, WinText), P.GoldColor);
			C.Font = P.GetFont(11, false, MyFonts.GetSmallestFont(C.ClipX));
			if (T.bWaitForFull && T.Size < TeamSize)
				P.TextRight(C, X + W - P.U(24), RY + P.U(27), NeedsText@TeamSize - T.Size, P.YellowColor);
			else
				P.TextRight(C, X + W - P.U(24), RY + P.U(27), ReadyText, P.GreenColor);
			RY += P.U(56);
		}
		if (NumQueue == 0)
			P.Text(C, X + P.U(16), RY, NoQueueText, P.DimColor);
		return;
	}

	C.Font = P.GetFont(14, false, MyFonts.GetSmallFont(C.ClipX));
	for (i=0; i<NumList; i++)
	{
		if (ListSide[i] != 2)
			continue;
		P.Text(C, X + P.U(16), RY, P.Fit(C, ListPRI[i].PlayerName, W - P.U(32)), P.WhiteColor);
		RY += P.U(22);
		N++;
	}
	if (N == 0)
	{
		C.Font = P.GetFont(11, false, MyFonts.GetSmallestFont(C.ClipX));
		P.Text(C, X + P.U(16), RY, NoSpectatorsText, P.DimColor);
	}
}

defaultproperties
{
      PlayerText="PLAYER"
      WinText="win"
      FragsText="FRAGS"
      PingText="PING"
      CloseText="close"
      QueueTitle="QUEUE"
      SpectatorsTitle="SPECTATORS"
      TeamsText="team"
      NoQueueText="No teams waiting"
      NoSpectatorsText="Nobody is watching"
      SpectatingText="Spectating:"
      ReadyText="ready"
      NeedsText="needs"
      WinsText="match wins"
      FlawlessText="flawless"
      FirstToText="first to"
      RoundWinsText="wins"
      RedName="Red Team"
      BlueName="Blue Team"
      OtherArenasText="OTHER ARENAS"
      PlayerWord="player"
      KillsTitle="KILLS"
      KillsHelp="row killed column"
}
