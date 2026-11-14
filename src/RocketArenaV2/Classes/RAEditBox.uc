// The team name field of the RA menu: a UWindowEditBox in the menu's font, drawn on
// the field the menu paints behind it.
class RAEditBox extends UWindowEditBox;

var Font EditFont;

function Paint(Canvas C, float X, float Y)
{
	local float W, H, FullW;
	local float TextY;

	C.Style = GetPlayerOwner().ERenderStyle.STY_Normal;
	if (EditFont != None)
		C.Font = EditFont;
	else
		C.Font = Root.Fonts[Font];

	TextSize(C, "A", W, H);
	TextY = (WinHeight - H) / 2;

	TextSize(C, Value, FullW, H);
	TextSize(C, Left(Value, CaretOffset), W, H);

	if (Offset < 0 && FullW <= WinWidth - 2)
		Offset = 0;
	else if (W + Offset < 0 || (Offset < 0 && FullW > WinWidth - 2 && W - H + Offset < 0))
		Offset = Min(0, -W + H);
	if (W + Offset > (WinWidth - 2))
	{
		Offset = (WinWidth - 2) - W;
		if (Offset > 0)
			Offset = 0;
	}

	C.DrawColor = TextColor;
	if (bAllSelected)
	{
		// Selected text: teal band, dark text (colors as in RASlideMenu, gamma-adjusted).
		C.DrawColor.R = 0;
		C.DrawColor.G = 115;
		C.DrawColor.B = 143;
		DrawStretchedTexture(C, Offset + 1, TextY, FullW, H, Texture'RocketArenaV2Media.White');
		C.DrawColor.R = 0;
		C.DrawColor.G = 0;
		C.DrawColor.B = 0;
	}
	ClipText(C, Offset + 1, TextY, Value);

	if (!bHasKeyboardFocus || !bCanEdit)
		bShowCaret = False;
	else if (GetLevel().TimeSeconds > LastDrawTime + 0.3 || GetLevel().TimeSeconds < LastDrawTime)
	{
		LastDrawTime = GetLevel().TimeSeconds;
		bShowCaret = !bShowCaret;
	}
	if (bShowCaret)
	{
		C.DrawColor.R = 224;
		C.DrawColor.G = 109;
		C.DrawColor.B = 3;
		ClipText(C, Offset + W - 1, TextY, "|");
	}
}

// Page Up/Down go to the menu (they scroll the chat page).
function KeyDown(int Key, float X, float Y)
{
	local PlayerPawn P;

	P = GetPlayerOwner();
	if (Key == P.EInputKey.IK_PageUp || Key == P.EInputKey.IK_PageDown)
		ParentWindow.KeyDown(Key, X, Y);
	else
		Super.KeyDown(Key, X, Y);
}

defaultproperties
{
}
