//=============================================================================
// RAArmor.
// The body armor handed out at spawn.  A plain Armor2 would be replaced by
// mutators (InstaGib+ swaps Armor2 for its own pickup class and destroys the
// original when it was not spawned at a pickup location), so this one is
// game relevant and never goes through mutator replacement.
//=============================================================================
class RAArmor extends Armor2;

defaultproperties
{
      bGameRelevant=True
}
