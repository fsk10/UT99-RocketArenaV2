class WeaponInfo extends ReplicationInfo
	config(RocketArenaV2);

// Config variables for voting and server administration.
// One for each arena.
var config int UseImpactHammer[8];
var config int UseEnforcer[8];
var config int UseShockRifle[8];
var config int UseBioRifle[8];
var config int UseRipper[8];
var config int UseFlakCannon[8];
var config int UseSniperRifle[8];
var config int UsePulseGun[8];
var config int UseMinigun[8];
var config int UseRocketLauncher[8];
var config int UseArmor[8];

// Starting ammo amounts... -1 means default.
// One for each arena.
var config int EnforcerAmmo[8];
var config int ShockRifleAmmo[8];
var config int BioRifleAmmo[8];
var config int RipperAmmo[8];
var config int FlakCannonAmmo[8];
var config int SniperRifleAmmo[8];
var config int PulseGunAmmo[8];
var config int MinigunAmmo[8];
var config int RocketLauncherAmmo[8];
var config int ArmorAmount[8];

// Damage rules.
var config int RoundLimit[8];
var config int TeamDamage[8];
var config int SelfDamage[8];

// What clients see. Config variables are only replicated when they differ from the class
// default (UT v469d and older), and a client fills them from its own ini, so the server
// copies the settings into these plain arrays (Sync) and the client side reads them.
var int RepUse[88];			// Arena * 11 + weapon index.
var int RepAmmo[88];		// Arena * 11 + weapon index.
var int RepRule[24];		// Arena * 3 + rule: 0 round limit, 1 self damage, 2 team damage.

replication
{
	reliable if ( Role == ROLE_Authority )
		RepUse, RepAmmo, RepRule;
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	Sync();
}

// Saves the settings and passes them on to the clients.
function SaveSettings()
{
	SaveConfig();
	Sync();
}

function Sync()
{
	local int Arena, Weapon;

	for (Arena=0; Arena<8; Arena++)
	{
		for (Weapon=0; Weapon<11; Weapon++)
		{
			RepUse[Arena * 11 + Weapon] = ConfigUse(Arena, Weapon);
			RepAmmo[Arena * 11 + Weapon] = ConfigAmmo(Arena, Weapon);
		}
		RepRule[Arena * 3] = RoundLimit[Arena];
		RepRule[Arena * 3 + 1] = SelfDamage[Arena];
		RepRule[Arena * 3 + 2] = TeamDamage[Arena];
	}
}

// Weapon by index (0 hammer, 1 enforcer, 2 shock, 3 bio, 4 ripper, 5 flak, 6 sniper,
// 7 pulse, 8 minigun, 9 rocket launcher, 10 armor), as RocketArenaGame.ToggleWeapon.
simulated function bool UseWeapon(int Arena, int Weapon)
{
	return RepUse[Arena * 11 + Weapon] == 1;
}

// Starting ammo (armor: its amount); -1 = default. The hammer has none (-1).
simulated function int WeaponAmmo(int Arena, int Weapon)
{
	return RepAmmo[Arena * 11 + Weapon];
}

// 0 round limit, 1 self damage (0/1), 2 team damage (0/1), as RocketArenaGame.AdminSetRule.
simulated function int Rule(int Arena, int Which)
{
	return RepRule[Arena * 3 + Which];
}

function int ConfigUse(int Arena, int Weapon)
{
	switch (Weapon)
	{
	case 0: return UseImpactHammer[Arena];
	case 1: return UseEnforcer[Arena];
	case 2: return UseShockRifle[Arena];
	case 3: return UseBioRifle[Arena];
	case 4: return UseRipper[Arena];
	case 5: return UseFlakCannon[Arena];
	case 6: return UseSniperRifle[Arena];
	case 7: return UsePulseGun[Arena];
	case 8: return UseMinigun[Arena];
	case 9: return UseRocketLauncher[Arena];
	case 10: return UseArmor[Arena];
	}
	return 0;
}

function int ConfigAmmo(int Arena, int Weapon)
{
	switch (Weapon)
	{
	case 1: return EnforcerAmmo[Arena];
	case 2: return ShockRifleAmmo[Arena];
	case 3: return BioRifleAmmo[Arena];
	case 4: return RipperAmmo[Arena];
	case 5: return FlakCannonAmmo[Arena];
	case 6: return SniperRifleAmmo[Arena];
	case 7: return PulseGunAmmo[Arena];
	case 8: return MinigunAmmo[Arena];
	case 9: return RocketLauncherAmmo[Arena];
	case 10: return ArmorAmount[Arena];
	}
	return -1;
}

defaultproperties
{
      UseImpactHammer(0)=1
      UseImpactHammer(1)=1
      UseImpactHammer(2)=1
      UseImpactHammer(3)=1
      UseImpactHammer(4)=1
      UseImpactHammer(5)=1
      UseImpactHammer(6)=1
      UseImpactHammer(7)=1
      UseEnforcer(0)=1
      UseEnforcer(1)=1
      UseEnforcer(2)=1
      UseEnforcer(3)=1
      UseEnforcer(4)=1
      UseEnforcer(5)=1
      UseEnforcer(6)=1
      UseEnforcer(7)=1
      UseShockRifle(0)=1
      UseShockRifle(1)=1
      UseShockRifle(2)=1
      UseShockRifle(3)=1
      UseShockRifle(4)=1
      UseShockRifle(5)=1
      UseShockRifle(6)=1
      UseShockRifle(7)=1
      UseBioRifle(0)=1
      UseBioRifle(1)=1
      UseBioRifle(2)=1
      UseBioRifle(3)=1
      UseBioRifle(4)=1
      UseBioRifle(5)=1
      UseBioRifle(6)=1
      UseBioRifle(7)=1
      UseRipper(0)=1
      UseRipper(1)=1
      UseRipper(2)=1
      UseRipper(3)=1
      UseRipper(4)=1
      UseRipper(5)=1
      UseRipper(6)=1
      UseRipper(7)=1
      UseFlakCannon(0)=1
      UseFlakCannon(1)=1
      UseFlakCannon(2)=1
      UseFlakCannon(3)=1
      UseFlakCannon(4)=1
      UseFlakCannon(5)=1
      UseFlakCannon(6)=1
      UseFlakCannon(7)=1
      UseSniperRifle(0)=1
      UseSniperRifle(1)=1
      UseSniperRifle(2)=1
      UseSniperRifle(3)=1
      UseSniperRifle(4)=1
      UseSniperRifle(5)=1
      UseSniperRifle(6)=1
      UseSniperRifle(7)=1
      UsePulseGun(0)=1
      UsePulseGun(1)=1
      UsePulseGun(2)=1
      UsePulseGun(3)=1
      UsePulseGun(4)=1
      UsePulseGun(5)=1
      UsePulseGun(6)=1
      UsePulseGun(7)=1
      UseMinigun(0)=1
      UseMinigun(1)=1
      UseMinigun(2)=1
      UseMinigun(3)=1
      UseMinigun(4)=1
      UseMinigun(5)=1
      UseMinigun(6)=1
      UseMinigun(7)=1
      UseRocketLauncher(0)=1
      UseRocketLauncher(1)=1
      UseRocketLauncher(2)=1
      UseRocketLauncher(3)=1
      UseRocketLauncher(4)=1
      UseRocketLauncher(5)=1
      UseRocketLauncher(6)=1
      UseRocketLauncher(7)=1
      UseArmor(0)=1
      UseArmor(1)=1
      UseArmor(2)=1
      UseArmor(3)=1
      UseArmor(4)=1
      UseArmor(5)=1
      UseArmor(6)=1
      UseArmor(7)=1
      EnforcerAmmo(0)=-1
      EnforcerAmmo(1)=-1
      EnforcerAmmo(2)=-1
      EnforcerAmmo(3)=-1
      EnforcerAmmo(4)=-1
      EnforcerAmmo(5)=-1
      EnforcerAmmo(6)=-1
      EnforcerAmmo(7)=-1
      ShockRifleAmmo(0)=-1
      ShockRifleAmmo(1)=-1
      ShockRifleAmmo(2)=-1
      ShockRifleAmmo(3)=-1
      ShockRifleAmmo(4)=-1
      ShockRifleAmmo(5)=-1
      ShockRifleAmmo(6)=-1
      ShockRifleAmmo(7)=-1
      BioRifleAmmo(0)=-1
      BioRifleAmmo(1)=-1
      BioRifleAmmo(2)=-1
      BioRifleAmmo(3)=-1
      BioRifleAmmo(4)=-1
      BioRifleAmmo(5)=-1
      BioRifleAmmo(6)=-1
      BioRifleAmmo(7)=-1
      RipperAmmo(0)=-1
      RipperAmmo(1)=-1
      RipperAmmo(2)=-1
      RipperAmmo(3)=-1
      RipperAmmo(4)=-1
      RipperAmmo(5)=-1
      RipperAmmo(6)=-1
      RipperAmmo(7)=-1
      FlakCannonAmmo(0)=-1
      FlakCannonAmmo(1)=-1
      FlakCannonAmmo(2)=-1
      FlakCannonAmmo(3)=-1
      FlakCannonAmmo(4)=-1
      FlakCannonAmmo(5)=-1
      FlakCannonAmmo(6)=-1
      FlakCannonAmmo(7)=-1
      SniperRifleAmmo(0)=-1
      SniperRifleAmmo(1)=-1
      SniperRifleAmmo(2)=-1
      SniperRifleAmmo(3)=-1
      SniperRifleAmmo(4)=-1
      SniperRifleAmmo(5)=-1
      SniperRifleAmmo(6)=-1
      SniperRifleAmmo(7)=-1
      PulseGunAmmo(0)=-1
      PulseGunAmmo(1)=-1
      PulseGunAmmo(2)=-1
      PulseGunAmmo(3)=-1
      PulseGunAmmo(4)=-1
      PulseGunAmmo(5)=-1
      PulseGunAmmo(6)=-1
      PulseGunAmmo(7)=-1
      MinigunAmmo(0)=-1
      MinigunAmmo(1)=-1
      MinigunAmmo(2)=-1
      MinigunAmmo(3)=-1
      MinigunAmmo(4)=-1
      MinigunAmmo(5)=-1
      MinigunAmmo(6)=-1
      MinigunAmmo(7)=-1
      RocketLauncherAmmo(0)=-1
      RocketLauncherAmmo(1)=-1
      RocketLauncherAmmo(2)=-1
      RocketLauncherAmmo(3)=-1
      RocketLauncherAmmo(4)=-1
      RocketLauncherAmmo(5)=-1
      RocketLauncherAmmo(6)=-1
      RocketLauncherAmmo(7)=-1
      ArmorAmount(0)=50
      ArmorAmount(1)=-1
      ArmorAmount(2)=-1
      ArmorAmount(3)=-1
      ArmorAmount(4)=-1
      ArmorAmount(5)=-1
      ArmorAmount(6)=-1
      ArmorAmount(7)=-1
      RoundLimit(0)=3
      RoundLimit(1)=3
      RoundLimit(2)=3
      RoundLimit(3)=3
      RoundLimit(4)=3
      RoundLimit(5)=3
      RoundLimit(6)=3
      RoundLimit(7)=3
      TeamDamage(0)=0
      TeamDamage(1)=0
      TeamDamage(2)=0
      TeamDamage(3)=0
      TeamDamage(4)=0
      TeamDamage(5)=0
      TeamDamage(6)=0
      TeamDamage(7)=0
      SelfDamage(0)=0
      SelfDamage(1)=0
      SelfDamage(2)=0
      SelfDamage(3)=0
      SelfDamage(4)=0
      SelfDamage(5)=0
      SelfDamage(6)=0
      SelfDamage(7)=0
      NetUpdateFrequency=2.000000
}
