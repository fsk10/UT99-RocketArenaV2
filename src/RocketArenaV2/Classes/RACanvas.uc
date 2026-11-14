// Drawing helpers for the HUD canvas screens (F1 scoreboard, F2 server info) in the
// style of the V2 menu. Sizes are units of the screen height (720 units), so the
// layout is the same at every resolution: U(x) gives pixels.
// The colors are stored darker than designed, as in RASlideMenu (UT shows a canvas
// color c as about 255*(c/255)^0.3 at Brightness 1.0).
class RACanvas extends Object;

var float	Scale;				// Pixels per unit.
var int		FontSizes[12];
var Font	Fonts[24];
var byte	FontTried[24];

var color	GoldColor, TealColor, WhiteColor, DetailColor, DimColor, GreenColor, YellowColor;
var color	CardColor, LineColor, RedTeamColor, BlueTeamColor;
var color	WaitColor, CountColor, PlayColor;
var bool	bShadow;			// Text gets a dark shadow (HUD text without a panel).

function Setup(Canvas C)
{
	Scale = C.ClipY / 720.0;
}

function float U(float Units)
{
	return Units * Scale;
}

// Dark see-through panel (drawn twice: the HUD canvas comes out brighter) with a teal frame.
function Panel(Canvas C, float X, float Y, float W, float H)
{
	C.Style = 4;	// STY_Modulated
	C.DrawColor = WhiteColor;
	C.SetPos(X, Y);
	C.DrawRect(Texture'RocketArenaV2Media.Panel', W, H);
	C.SetPos(X, Y);
	C.DrawRect(Texture'RocketArenaV2Media.Panel', W, H);
	Box(C, X, Y, W, H, TealColor);
}

function Fill(Canvas C, float X, float Y, float W, float H, color Col)
{
	C.Style = 1;	// STY_Normal
	C.DrawColor = Col;
	C.SetPos(X, Y);
	C.DrawRect(Texture'RocketArenaV2Media.White', W, H);
}

function Box(Canvas C, float X, float Y, float W, float H, color Col)
{
	Fill(C, X, Y, W, 1, Col);
	Fill(C, X, Y + H - 1, W, 1, Col);
	Fill(C, X, Y, 1, H, Col);
	Fill(C, X + W - 1, Y, 1, H, Col);
}

// Texture added to the background (black = see-through), U x V texels of it.
function Tex(Canvas C, float X, float Y, float W, float H, texture T, float TU, float TV)
{
	C.Style = 3;	// STY_Translucent
	C.DrawColor = WhiteColor;
	C.SetPos(X, Y);
	C.DrawTile(T, W, H, 0, 0, TU, TV);
}

function Text(Canvas C, float X, float Y, coerce string S, color Col)
{
	if (bShadow)
	{
		C.Style = 1;
		C.DrawColor.R = 0;
		C.DrawColor.G = 0;
		C.DrawColor.B = 0;
		C.SetPos(X + 1, Y + 1);
		C.DrawText(S, false);
	}
	C.Style = 1;
	C.DrawColor = Col;
	C.SetPos(X, Y);
	C.DrawText(S, false);
}

function TextRight(Canvas C, float Right, float Y, coerce string S, color Col)
{
	local float XL, YL;

	C.StrLen(S, XL, YL);
	Text(C, Right - XL, Y, S, Col);
}

function TextCenter(Canvas C, float Center, float Y, coerce string S, color Col)
{
	local float XL, YL;

	C.StrLen(S, XL, YL);
	Text(C, Center - XL / 2, Y, S, Col);
}

function float TextW(Canvas C, string S)
{
	local float XL, YL;

	C.StrLen(S, XL, YL);
	return XL;
}

// Cuts S so it fits in MaxW, ending with "...".
function string Fit(Canvas C, string S, float MaxW)
{
	if (TextW(C, S) <= MaxW)
		return S;
	while (Len(S) > 1)
	{
		S = Left(S, Len(S) - 1);
		if (TextW(C, S$"...") <= MaxW)
			break;
	}
	return S$"...";
}

// Tahoma about Units high, from the UWindowFonts sizes (loaded by name, so a client
// without a size falls back to the HUD's font).
function Font GetFont(float Units, bool bBold, Font Fallback)
{
	local int i, Best, Slot;
	local float Px;

	Px = U(Units);
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
	return Fallback;
}

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

defaultproperties
{
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
      YellowColor=(R=255,G=135,B=2,A=0)
      CardColor=(R=0,G=1,B=1,A=0)
      LineColor=(R=0,G=6,B=8,A=0)
      RedTeamColor=(R=195,G=2,B=1,A=0)
      BlueTeamColor=(R=4,G=28,B=255,A=0)
      WaitColor=(R=115,G=115,B=115,A=0)
      CountColor=(R=255,G=135,B=2,A=0)
      PlayColor=(R=2,G=255,B=8,A=0)
}
