// F2 screen: server info and one row per arena (status, who plays, queue, spectators),
// in the V2 menu style, anchored near the top of the screen.
class RAServerInfo extends ServerInfo;

var RACanvas P;
var localized string ArenasTitle, CloseText, AdminLabel, ContactText;
var localized string NoPlayersText, QueueText, SpectatingText;

function RenderInfo( canvas C )
{
	local GameReplicationInfo GRI;

	GRI = PlayerPawn(Owner).GameReplicationInfo;
	if (C.ClipX > 512 && RAGameReplicationInfo(GRI) != None && RAGameReplicationInfo(GRI).ArenaInfo != None)
		DrawPanel(C, RAGameReplicationInfo(GRI));
	else
	{
		DrawTitle(C);
		DrawShortContactInfo(C, GRI);
	}
}

function DrawPanel( canvas C, RAGameReplicationInfo RAGRI )
{
	local RAReplicationInfo RA;
	local float PX, PY, PW, PH, X, Y, RowH, RowGap, ColStatus, ColMatch;
	local int i, Rows, MyArena;
	local string S;

	if (P == None)
		P = new class'RACanvas';
	P.Setup(C);
	C.bCenter = false;

	class'RATools'.static.GetRepInfo(PlayerPawn(Owner), RAGRI, RA);
	MyArena = -1;
	if (RA != None)
		MyArena = RA.Arena;

	for (i=0; i<ArrayCount(RAGRI.ArenaGames); i++)
		if (ArenaShown(RAGRI, i))
			Rows++;

	RowH = P.U(55);
	RowGap = P.U(6);
	PW = FMin(P.U(940), C.ClipX - 16);
	PX = (C.ClipX - PW) / 2;
	PY = P.U(35);
	PH = P.U(111) + Rows * (RowH + RowGap) + P.U(8);
	ColStatus = PX + PW * 0.23;
	ColMatch = PX + PW * 0.41;

	P.Panel(C, PX, PY, PW, PH);

	// Header: title, server name, admin, contact.
	P.Tex(C, PX + P.U(16), PY + P.U(16), P.U(40) * 457 / 86, P.U(40), Texture'RocketArenaV2Media.TitleServerInfo', 457, 86);
	C.Font = P.GetFont(12, false, MyFonts.GetSmallFont(C.ClipX));
	X = PX + P.U(250);
	Y = PY + P.U(12);
	P.Text(C, X, Y, NameText, P.DetailColor);
	P.Text(C, X + P.U(60), Y, RAGRI.ServerName, P.WhiteColor);
	P.Text(C, X, Y + P.U(17), AdminLabel, P.DetailColor);
	S = RAGRI.AdminName;
	if (S == "")
		S = UnknownText;
	P.Text(C, X + P.U(60), Y + P.U(17), S, P.WhiteColor);
	if (RAGRI.AdminEmail != "")
	{
		P.Text(C, X, Y + P.U(34), ContactText, P.DetailColor);
		P.Text(C, X + P.U(60), Y + P.U(34), RAGRI.AdminEmail, P.WhiteColor);
	}
	C.Font = P.GetFont(11, false, MyFonts.GetSmallestFont(C.ClipX));
	P.TextRight(C, PX + PW - P.U(14), PY + P.U(12), "F2  "$Chr(183)$"  "$CloseText, P.DetailColor);
	P.Fill(C, PX + P.U(12), PY + P.U(74), PW - P.U(24), P.U(2), P.GoldColor);

	C.Font = P.GetFont(14, true, MyFonts.GetSmallFont(C.ClipX));
	P.Text(C, PX + P.U(16), PY + P.U(84), ArenasTitle, P.TealColor);

	Y = PY + P.U(111);
	for (i=0; i<ArrayCount(RAGRI.ArenaGames); i++)
	{
		if (!ArenaShown(RAGRI, i))
			continue;
		DrawArenaRow(C, RAGRI, i, i == MyArena, PX + P.U(12), Y, PW - P.U(24), RowH, ColStatus, ColMatch);
		Y += RowH + RowGap;
	}
	C.Style = ERenderStyle.STY_Normal;
	C.DrawColor = P.WhiteColor;
}

function DrawArenaRow( canvas C, RAGameReplicationInfo RAGRI, int Arena, bool bMine, float X, float Y, float W, float H, float ColStatus, float ColMatch )
{
	local ArenaGame AG;
	local ArenaGame_Multi Multi;
	local RATeamInfo T;
	local string TeamA, TeamB, Score, Queue, Spec, S;
	local float MX, MW;
	local int ArenaSt;

	AG = RAGRI.ArenaGames[Arena];
	Multi = ArenaGame_Multi(AG);
	ArenaSt = class'RATools'.static.ArenaState(RAGRI, Arena);

	P.Fill(C, X, Y, W, H, P.CardColor);
	if (bMine)
		P.Fill(C, X, Y, P.U(2), H, P.GoldColor);

	// Name and mode, status.
	C.Font = P.GetFont(15, true, MyFonts.GetSmallFont(C.ClipX));
	S = P.Fit(C, RAGRI.ArenaInfo.ArenaNames[Arena], ColStatus - X - P.U(24));
	if (bMine)
		P.Text(C, X + P.U(14), Y + P.U(8), S, P.GoldColor);
	else
		P.Text(C, X + P.U(14), Y + P.U(8), S, P.WhiteColor);
	C.Font = P.GetFont(11, false, MyFonts.GetSmallestFont(C.ClipX));
	P.Text(C, X + P.U(14), Y + P.U(31), class'RATools'.static.ArenaMode(RAGRI, Arena)$" "$Chr(183)$" "$class'RATools'.static.ActiveCount(RAGRI, Arena)$" pl", P.DetailColor);
	C.Font = P.GetFont(13, false, MyFonts.GetSmallFont(C.ClipX));
	P.Text(C, ColStatus, Y + P.U(10), class'RATools'.static.ArenaStatus(RAGRI, Arena), P.StateColor(ArenaSt));

	// Who plays: team A  score  team B.
	if (Multi != None)
	{
		if (ArenaSt >= 2 && RATeamInfo(AG.Teams[0]) != None && RATeamInfo(AG.Teams[1]) != None)
		{
			TeamA = class'RATools'.static.TeamText(RAGRI, Arena, RATeamInfo(AG.Teams[0]));
			TeamB = class'RATools'.static.TeamText(RAGRI, Arena, RATeamInfo(AG.Teams[1]));
			Score = int(AG.Teams[0].Score)$" - "$int(AG.Teams[1].Score);
		}
		for (T=Multi.TeamList; T!=None; T=T.NextTeam)
		{
			if (TeamA != "" && (T == AG.Teams[0] || T == AG.Teams[1]))
				continue;
			if (Queue != "")
				Queue = Queue$",  ";
			Queue = Queue$class'RATools'.static.TeamText(RAGRI, Arena, T);
			if (T.bWaitForFull && T.Size < RAGRI.ArenaInfo.ArenaTeamSize[Arena])
				Queue = Queue$" (needs"@RAGRI.ArenaInfo.ArenaTeamSize[Arena] - T.Size$")";
		}
	}
	else if (ArenaGame_Clan(AG) != None)
	{
		S = class'RATools'.static.PlayerNames(RAGRI, Arena, None, 0);
		Spec = class'RATools'.static.PlayerNames(RAGRI, Arena, None, 1);
		if (S != "" || Spec != "")
		{
			TeamA = "Red ("$S$")";
			TeamB = "Blue ("$Spec$")";
			Score = int(AG.Teams[0].Score)$" - "$int(AG.Teams[1].Score);
		}
	}
	else
	{
		S = class'RATools'.static.PlayerNames(RAGRI, Arena, None, 0);
		if (S != "")
			TeamA = PlayersText@S;
	}
	Spec = class'RATools'.static.PlayerNames(RAGRI, Arena, None, 255);

	MX = ColMatch;
	MW = X + W - P.U(14) - MX;
	if (TeamA != "")
	{
		C.Font = P.GetFont(13, true, MyFonts.GetSmallFont(C.ClipX));
		if (Score != "")
		{
			// Each team gets at most 42% of the width, so the score stays between them.
			S = P.Fit(C, TeamA, MW * 0.42);
			P.Text(C, MX, Y + P.U(9), S, P.WhiteColor);
			MX += P.TextW(C, S) + P.U(12);
			C.Font = P.GetFont(17, true, MyFonts.GetSmallFont(C.ClipX));
			P.Text(C, MX, Y + P.U(7), Score, P.GoldColor);
			MX += P.TextW(C, Score) + P.U(12);
			C.Font = P.GetFont(13, true, MyFonts.GetSmallFont(C.ClipX));
			P.Text(C, MX, Y + P.U(9), P.Fit(C, TeamB, X + W - P.U(14) - MX), P.WhiteColor);
		}
		else
			P.Text(C, MX, Y + P.U(9), P.Fit(C, TeamA, MW), P.WhiteColor);
	}

	// Queue and spectators on the second line.
	S = "";
	if (Queue != "")
		S = QueueText$" "$Queue;
	if (Spec != "")
	{
		if (S != "")
			S = S$"      ";
		S = S$SpectatingText$" "$Spec;
	}
	C.Font = P.GetFont(11, false, MyFonts.GetSmallestFont(C.ClipX));
	if (S != "")
	{
		if (TeamA != "")
			P.Text(C, ColMatch, Y + P.U(32), P.Fit(C, S, MW), P.DetailColor);
		else
			P.Text(C, ColMatch, Y + P.U(20), P.Fit(C, S, MW), P.DetailColor);
	}
	else if (TeamA == "")
		P.Text(C, ColMatch, Y + P.U(20), NoPlayersText, P.DimColor);
}

function bool ArenaShown( RAGameReplicationInfo RAGRI, int i )
{
	return RAGRI.ArenaInfo.ArenaNames[i] != "" && RAGRI.ArenaGames[i] != None;
}

defaultproperties
{
      ArenasTitle="ARENAS / PLAYERS"
      CloseText="close"
      NameText="Name"
      AdminLabel="Admin"
      ContactText="Contact"
      NoPlayersText="No players"
      QueueText="Queue:"
      SpectatingText="Spectating:"
      PlayersText="Players:"
}
