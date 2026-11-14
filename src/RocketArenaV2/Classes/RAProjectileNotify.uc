//=============================================================================
// RAProjectileNotify.
// Removes projectiles the arena does not allow, e.g. a rocket fired before
// FIGHT that only reaches the server after the round has started.
// Server only.
//=============================================================================
class RAProjectileNotify extends SpawnNotify;

event Actor SpawnNotification(Actor A)
{
	if ( RocketArenaGame(Level.Game) != None && !RocketArenaGame(Level.Game).AllowProjectile(Projectile(A)) )
		A.Destroy();
	// Never return None: the engine passes the result on to the next SpawnNotify
	// in the chain (InstaGib+ has its own), which must get a valid actor.
	return A;
}

defaultproperties
{
      ActorClass=Class'Engine.Projectile'
      RemoteRole=ROLE_None
}
