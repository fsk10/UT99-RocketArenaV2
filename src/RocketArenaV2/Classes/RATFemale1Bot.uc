//=============================================================================
// RATFemale1Bot.
//=============================================================================
class RATFemale1Bot extends RAFemaleBotPlus;

function ForceMeshToExist()
{
	Spawn(class'TFemale1');
}

defaultproperties
{
      CarcassType=Class'Botpack.TFemale1Carcass'
      FaceSkin=3
      TeamSkin2=1
      DefaultSkinName="FCommandoSkins.cmdo"
      DefaultPackage="FCommandoSkins."
      SelectionMesh="Botpack.SelectionFemale1"
      MenuName="Female Commando"
      VoiceType="Botpack.VoiceFemaleOne"
      Mesh=LodMesh'Botpack.FCommando'
}
