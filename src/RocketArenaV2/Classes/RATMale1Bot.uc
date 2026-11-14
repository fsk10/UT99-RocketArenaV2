//=============================================================================
// RATMale1Bot.
//=============================================================================
class RATMale1Bot extends RAMaleBotPlus;

function ForceMeshToExist()
{
	Spawn(class'TMale1');
}

defaultproperties
{
      CarcassType=Class'Botpack.TMale1Carcass'
      LandGrunt=Sound'UnrealShare.Male.MLand3'
      JumpSound=Sound'Botpack.Male.TMJump3'
      FaceSkin=1
      TeamSkin1=2
      TeamSkin2=3
      DefaultSkinName="CommandoSkins.cmdo"
      DefaultPackage="CommandoSkins."
      SelectionMesh="Botpack.SelectionMale1"
      MenuName="Male Commando"
      VoiceType="Botpack.VoiceMaleOne"
      Mesh=LodMesh'Botpack.Commando'
}
