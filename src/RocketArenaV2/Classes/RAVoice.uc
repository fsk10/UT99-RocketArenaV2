//=============================================================================
// RAVoice.
//=============================================================================
class RAVoice extends Info
	abstract;

var() sound Welcome;
var() sound Prepare;

var() sound GetReady;
var() sound CountDown[4];

var() sound WinRound[2];
var() sound WinMatch[2];

var() sound Perfect;
var() sound Flawless;

var() sound EnvironmentSuicide;
var() sound WeaponSuicide;

var() sound Taunts[8];
var() int NumTaunts;

defaultproperties
{
      Welcome=None
      prepare=None
      GetReady=None
      CountDown(0)=None
      CountDown(1)=None
      CountDown(2)=None
      CountDown(3)=None
      WinRound(0)=None
      WinRound(1)=None
      WinMatch(0)=None
      WinMatch(1)=None
      Perfect=None
      Flawless=None
      EnvironmentSuicide=None
      WeaponSuicide=None
      Taunts(0)=None
      Taunts(1)=None
      Taunts(2)=None
      Taunts(3)=None
      Taunts(4)=None
      Taunts(5)=None
      Taunts(6)=None
      Taunts(7)=None
      numTaunts=0
      RemoteRole=ROLE_None
}
