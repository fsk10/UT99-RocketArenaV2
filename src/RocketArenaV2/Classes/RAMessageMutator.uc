class RAMessageMutator extends Mutator;

/*
This class ensures that messages:
	stay within the arena from which they were sent (unless its a global message)
	get sent to spectators if you are a spectator, to prevent cheating with telling of enemy healths (if that option is enabled)
*/

function bool MutatorTeamMessage( Actor Sender, Pawn Receiver, PlayerReplicationInfo PRI, coerce string S, name Type, optional bool bBeep )
{
	local RAReplicationInfo RA_R, RA_S;

	if (Sender.IsA('Pawn') && !(Left(S,8) ~= "Global: "))
	{
		class'RATools'.static.GetRepInfo(Receiver, Level.Game.GameReplicationInfo, RA_R);
		class'RATools'.static.GetRepInfo(Pawn(Sender), Level.Game.GameReplicationInfo, RA_S);
		if (RA_R == None || RA_S == None || RA_R.Arena != RA_S.Arena)
			return false;
	}

	//if we are a spectator trying to talk to a non-spectator, disallow it
	if ( class'RocketArenaGame'.default.DisallowSpectatorSpeech && Pawn(Sender) != None && (Pawn(Sender).Health <= 0 || Pawn(Sender).PlayerReplicationInfo.Team == 255) && (Receiver.Health > 0 && Receiver.PlayerReplicationInfo.Team != 255) )
		return false;

	if ( NextMessageMutator != None )
		return NextMessageMutator.MutatorTeamMessage( Sender, Receiver, PRI, S, Type, bBeep );
	else
		return true;
}

function bool MutatorBroadcastMessage( Actor Sender, Pawn Receiver, out coerce string Msg, optional bool bBeep, out optional name Type )
{
	local RAReplicationInfo RA_R, RA_S;

	if (Sender.IsA('Pawn'))
	{
		class'RATools'.static.GetRepInfo(Receiver, Level.Game.GameReplicationInfo, RA_R);
		class'RATools'.static.GetRepInfo(Pawn(Sender), Level.Game.GameReplicationInfo, RA_S);
		if (RA_R == None || RA_S == None || RA_R.Arena != RA_S.Arena)
			return false;
	}

	//if we are a spectator trying to talk to a non-spectator, disallow it
	if ( class'RocketArenaGame'.default.DisallowSpectatorSpeech && Pawn(Sender) != None && (Pawn(Sender).Health <= 0 || Pawn(Sender).PlayerReplicationInfo.Team == 255) && (Receiver.Health > 0 && Receiver.PlayerReplicationInfo.Team != 255) )
		return false;

	if ( NextMessageMutator != None )
		return NextMessageMutator.MutatorBroadcastMessage( Sender, Receiver, Msg, bBeep, Type );
	else
		return true;
}

function bool MutatorBroadcastLocalizedMessage( Actor Sender, Pawn Receiver, out class<LocalMessage> Message, out optional int Switch, out optional PlayerReplicationInfo RelatedPRI_1, out optional PlayerReplicationInfo RelatedPRI_2, out optional Object OptionalObject )
{
	local RAReplicationInfo RA_R, RA_S;
	local RAReplicationInfo RA_Rep1, RA_Rep2;

	if (Pawn(Sender) != None)
	{
		class'RATools'.static.GetRepInfo(Receiver, Level.Game.GameReplicationInfo, RA_R);
		class'RATools'.static.GetRepInfo(Pawn(Sender), Level.Game.GameReplicationInfo, RA_S);
		if (RA_R == None || RA_S == None || RA_R.Arena != RA_S.Arena)
			return false;
	}

	if (GameInfo(Sender) != None)
	{
		class'RATools'.static.GetRepInfo(Receiver, Level.Game.GameReplicationInfo, RA_R);
		if (RelatedPRI_1 != None)
			class'RATools'.static.GetRepInfo(Pawn(RelatedPRI_1.Owner), Level.Game.GameReplicationInfo, RA_Rep1);
		if (RelatedPRI_2 != None)
			class'RATools'.static.GetRepInfo(Pawn(RelatedPRI_2.Owner), Level.Game.GameReplicationInfo, RA_Rep2);

		if (RA_R != None)
		{
			if (RA_Rep1 != None && RA_Rep2 != None)
			{
				if ((RA_Rep1.Arena != RA_R.Arena) || (RA_Rep2.Arena != RA_R.Arena))
					return false;
			} else if (RA_Rep1 != None) {
				if (RA_Rep1.Arena != RA_R.Arena)
					return false;
			} else if (RA_Rep2 != None) {
				if (RA_Rep2.Arena != RA_R.Arena)
					return false;
			}
		}
	}

	if ( NextMessageMutator != None )
		return NextMessageMutator.MutatorBroadcastLocalizedMessage( Sender, Receiver, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
	else
		return true;
}

defaultproperties
{
}
