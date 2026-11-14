//=============================================================================
// RADamageMutator.
// Runs last in the damage mutator chain and enforces the arena rules on every
// hit, whatever player class is in use:
//  - hits the arena does not allow (countdown, shots fired before FIGHT, falling
//    damage when it is off) do nothing: no damage and no momentum.
//    This also covers the stock bug where a player without inventory takes the
//    full damage even when ReduceDamage returned 0.
//  - rocket jumps get the configured BouncyHeight.
//=============================================================================
class RADamageMutator extends Mutator;

function MutatorTakeDamage( out int ActualDamage, Pawn Victim, Pawn InstigatedBy, out Vector HitLocation,
						out Vector Momentum, name DamageType)
{
	local RocketArenaGame Game;

	Game = RocketArenaGame(Level.Game);
	if (Game != None && Victim != None)
	{
		if (Game.DamageBlocked(Victim, InstigatedBy, DamageType))
		{
			ActualDamage = 0;
			// The own rocket still pushes (rocket jumps after the round is decided).
			if (InstigatedBy != Victim || !Game.SelfPushAllowed(Victim))
				Momentum = vect(0,0,0);
		}
		if (DamageType == 'RocketDeath' && InstigatedBy == Victim)
		{
			Momentum.X /= class'RocketArenaGame'.default.BouncyHeight;
			Momentum.Y /= class'RocketArenaGame'.default.BouncyHeight;
			Momentum.Z *= class'RocketArenaGame'.default.BouncyHeight;
		}
	}

	if ( NextDamageMutator != None )
		NextDamageMutator.MutatorTakeDamage( ActualDamage, Victim, InstigatedBy, HitLocation, Momentum, DamageType );
}

defaultproperties
{
}
