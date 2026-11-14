class RABaseMutator extends DMMutator;

function AddMutator(Mutator M)
{
	if ( !M.IsA('Relic') )
		Super.AddMutator(M);
}

defaultproperties
{
}
