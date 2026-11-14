//=============================================================================
// RABot.
//=============================================================================
class RABot extends Bot
	abstract;

var bool bRACanFire;

function bool CanStakeOut()
{
	return false;
}

function Destroyed()
{
	local int i;

	for (i=0;i<32;i++)
	{
		if (DeathMatchPlus(Level.Game).BotConfig.BotNames[i] == PlayerReplicationInfo.PlayerName)
			DeathMatchPlus(Level.Game).BotConfig.ConfigUsed[i] = 0;
	}
	Super.Destroyed();
}

function bool SetEnemy( Pawn NewEnemy )
{
	local bool result, bNotSeen;
	local eAttitude newAttitude;
	local Pawn Friend;

	if (Enemy == NewEnemy)
		return true;
	if ( (NewEnemy == Self) || (NewEnemy == None) || (NewEnemy.Health <= 0) || NewEnemy.IsA('FlockPawn') )
		return false;

	result = false;
	newAttitude = AttitudeTo(NewEnemy);
	if ( newAttitude == ATTITUDE_Friendly )
	{
		Friend = NewEnemy;
		if ( Level.TimeSeconds - Friend.LastSeenTime > 5 )
			return false;
		NewEnemy = NewEnemy.Enemy;
		if ( (NewEnemy == None) || (NewEnemy == Self) || (NewEnemy.Health <= 0) || NewEnemy.IsA('FlockPawn') || NewEnemy.IsA('StationaryPawn') )
			return false;
		if (Enemy == NewEnemy)
			return true;

		bNotSeen = true;
		newAttitude = AttitudeTo(NewEnemy);
	}

	if ( newAttitude >= ATTITUDE_Ignore )
		return false;

	if ( Enemy != None )
	{
		if ( AssessThreat(NewEnemy) > AssessThreat(Enemy) )
		{
			OldEnemy = Enemy;
			Enemy = NewEnemy;
			result = true;
		}
		else if ( OldEnemy == None )
			OldEnemy = NewEnemy;
	}
	else
	{
		result = true;
		Enemy = NewEnemy;
	}

	if ( result )
	{
		if ( bNotSeen )
		{
			LastSeenTime = Friend.LastSeenTime;
			LastSeeingPos = Friend.LastSeeingPos;
			LastSeenPos = Friend.LastSeenPos;
		}
		else
		{
			LastSeenTime = Level.TimeSeconds;
			LastSeeingPos = Location;
			LastSeenPos = Enemy.Location;
		}
		EnemyAcquired();
	}

	return result;
}

function bool CanImpactJump()
{
	return true;
}

function ImpactJump(Actor JumpDest)
{
	SetFall();
	ImpactTarget = JumpDest;
	GotoState('ImpactJumping');
}

state ImpactJumping
{
	function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
							Vector momentum, name damageType)
	{
		local name RealState, RealLabel;

		RealState = NextState;
		RealLabel = NextLabel;
		Global.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType);
		if ( health <= 0 )
			return;
		if ( (Enemy != None) && (Enemy == InstigatedBy) )
		{
			LastSeenPos = Enemy.Location;
			LastSeenTime = Level.TimeSeconds;
		}
		NextState = RealState;
		NextLabel = RealLabel;
		MoveTarget = None;
		bJumpOffPawn = true;
		bImpactJumping = true;
		GotoState('fallingstate');
	}

	function vector ImpactLook()
	{
		local vector result;

		result = 1000 * Normal(ImpactTarget.Location - Location);
		result.Z = Location.Z - 400;
		return Result;
	}

	function AnimEnd()
	{
		bFire = 1;
		PlayWaiting();
		bFire = 0;
	}

	function ChangeToHammer()
	{
		local Inventory MyHammer;

		MyHammer = FindInventoryType(class'ImpactHammer');
		if ( MyHammer == None )
		{
			GotoState('NextState', 'NextLabel');
			return;
		}
		PendingWeapon = Weapon(MyHammer);
		PendingWeapon.AmbientSound = ImpactHammer(MyHammer).TensionSound;
		PendingWeapon.SetLocation(Location);
		if ( Weapon == None )
			ChangedWeapon();
		else if ( Weapon != PendingWeapon )
			Weapon.PutDown();
	}

	function EndState()
	{
		local Inventory MyHammer;
		MyHammer = FindInventoryType(class'ImpactHammer');
		if ( MyHammer != None )
			MyHammer.AmbientSound = None;
	}

	function BeginState()
	{
		if (!bRACanFire)
		{
			WhatToDoNext('','');
			return;
		}
	}

Begin:
	Acceleration = vect(0,0,0);
	if ( !Weapon.IsA('ImpactHammer') && !Weapon.IsA('UT_Eightball') && !Weapon.IsA('UT_FlakCannon'))
		ChangeToHammer();
	else
	{
		Weapon.SetLocation(Location);
		Weapon.AmbientSound = ImpactHammer(Weapon).TensionSound;
	}
	TweenToWaiting(0.2);
	TurnTo(ImpactLook());
	CampTime = Level.TimeSeconds;
	While ( !Weapon.IsA('ImpactHammer') && !Weapon.IsA('UT_Eightball') && !Weapon.IsA('UT_FlakCannon') && (Level.TimeSeconds - Camptime < 2.0) )
		Sleep(0.1);
	CampTime = 1.0;
	MakeNoise(1.0);
	if ( Physics != PHYS_Falling )
	{
		Velocity = ImpactTarget.Location - Location;
		if (Weapon.IsA('ImpactHammer'))
		{
			bFire = 0;
			bAltFire = 1;
			Weapon.AltFire(1.0);
		}
		else if (Weapon.IsA('UT_Eightball'))
		{
			bFire = 1;
			bAltFire = 0;
			Weapon.Fire(1.0);
		}
		else if (Weapon.IsA('UT_FlakCannon'))
		{
			bFire = 0;
			bAltFire = 1;
			Weapon.AltFire(1.0);
		}
	}
	GotoState(NextState, NextLabel);
}

state Attacking
{
ignores SeePlayer, HearNoise, Bump, HitWall;

	function ChooseAttackMode()
	{
		local eAttitude AttitudeToEnemy;
		local pawn changeEn;
		local TeamGamePlus TG;
		local bool bWillHunt;

		bWillHunt = true;
		bMustHunt = false;
		if ((Enemy == None) || (Enemy.Health <= 0))
		{
			WhatToDoNext('','');
			return;
		}
		if ( Weapon == None )
			SwitchToBestWeapon();
		AttitudeToEnemy = AttitudeTo(Enemy);
		TG = TeamGamePlus(Level.Game);
		if ( TG != None )
		{
			if ( (Level.TimeSeconds - LastAttractCheck > 0.5)
				|| (AttitudeToEnemy == ATTITUDE_Fear)
				|| (TG.PriorityObjective(self) > 1) )
			{
				goalstring = "attract check";
				if ( TG.FindSpecialAttractionFor(self) )
					return;
				if ( Enemy == None )
				{
					WhatToDoNext('','');
					return;
				}
			}
			else
			{
				goalstring = "no attract check";
			}
		}

		if (AttitudeToEnemy == ATTITUDE_Fear)
		{
			GotoState('Retreating');
			return;
		}
		else if (AttitudeToEnemy == ATTITUDE_Friendly)
		{
			WhatToDoNext('','');
			return;
		}
		else if ( !LineOfSightTo(Enemy) )
		{
			if ( (OldEnemy != None)
				&& (AttitudeTo(OldEnemy) == ATTITUDE_Hate) && LineOfSightTo(OldEnemy) )
			{
				changeEn = enemy;
				enemy = oldenemy;
				oldenemy = changeEn;
			}
			else
			{
				goalstring = "attract check";
				if ( (TG != None) && TG.FindSpecialAttractionFor(self) )
					return;
				if ( Enemy == None )
				{
					WhatToDoNext('','');
					return;
				}
				if ( (Orders == 'Hold') && (Level.TimeSeconds - LastSeenTime > 5) )
				{
					NumHuntPaths = 0;
					GotoState('StakeOut');
				}
				else if ( bWillHunt || (!bSniping && (VSize(Enemy.Location - Location)
							> 600 + (FRand() * RelativeStrength(Enemy) - CombatStyle) * 600)) )
				{
					bDevious = ( !bNovice && !Level.Game.bTeamGame && Level.Game.IsA('DeathMatchPlus')
								&& (FRand() < 0.52 - 0.12 * DeathMatchPlus(Level.Game).NumBots) );
					GotoState('Hunting');
				}
				else
				{
					NumHuntPaths = 0;
					GotoState('StakeOut');
				}
				return;
			}
		}

		Target = Enemy;
		SetTimer(TimeBetweenAttacks, False);

		GotoState('TacticalMove');
	}

Begin:
	ChooseAttackMode();
}

function TakeFallingDamage()
{
	if (class'RocketArenaGame'.default.FallingDamage) Super.TakeFallingDamage();
}

function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
						Vector momentum, name damageType)
{
	local int actualDamage;
	local bool bAlreadyDead;

	if ( Role < ROLE_Authority )
		return;

	bAlreadyDead = (Health <= 0);

	if (Physics == PHYS_None)
		SetMovementPhysics();
	if (Physics == PHYS_Walking)
		momentum.Z = FMax(momentum.Z, 0.4 * VSize(momentum));
	if ( instigatedBy == self )
		momentum *= 0.6;
	momentum = momentum/Mass;

	actualDamage = Level.Game.ReduceDamage(Damage, DamageType, self, instigatedBy);
	if ( bIsPlayer )
	{
		if (ReducedDamageType == 'All') //God mode
		{
			actualDamage = 0;
		} else if (Inventory != None) //then check if carrying armor
		{
			actualDamage = Inventory.ReduceDamage(actualDamage, DamageType, HitLocation);
		}
	}
	else if ( (InstigatedBy != None) &&
				(InstigatedBy.IsA(Class.Name) || self.IsA(InstigatedBy.Class.Name)) )
		ActualDamage = ActualDamage * FMin(1 - ReducedDamagePct, 0.35);
	else if ( (ReducedDamageType == 'All') ||
		((ReducedDamageType != '') && (ReducedDamageType == damageType)) )
		actualDamage = float(actualDamage) * (1 - ReducedDamagePct);

	if ( Level.Game.DamageMutator != None )
		Level.Game.DamageMutator.MutatorTakeDamage( ActualDamage, Self, InstigatedBy, HitLocation, Momentum, DamageType );

	if (DamageType == 'RocketDeath' && Instigatedby == Self)
	{
		Momentum.X /= class'RocketArenaGame'.default.BouncyHeight;
		Momentum.Y /= class'RocketArenaGame'.default.BouncyHeight;
		Momentum.Z *= class'RocketArenaGame'.default.BouncyHeight;
	}

	AddVelocity( momentum );
	Health -= actualDamage;
	if (CarriedDecoration != None)
		DropDecoration();
	if ( HitLocation == vect(0,0,0) )
		HitLocation = Location;
	if (Health > 0)
	{
		if ( (instigatedBy != None) && (instigatedBy != Self) )
			damageAttitudeTo(instigatedBy);
		PlayHit(actualDamage, hitLocation, damageType, Momentum);
	}
	else if ( !bAlreadyDead )
	{
		NextState = '';
		PlayDeathHit(actualDamage, hitLocation, damageType, Momentum);
		if ( actualDamage > mass )
			Health = -1 * actualDamage;
		if ( (instigatedBy != None) && (instigatedBy != Self) )
			damageAttitudeTo(instigatedBy);
		Died(instigatedBy, damageType, HitLocation);
	}
	else
	{
		if ( bIsPlayer )
		{
			HidePlayer();
			GotoState('Dying');
		}
		else
			Destroy();
	}
	MakeNoise(1.0);
}

function FireWeapon()
{
	if (!bRACanFire) return;

	Super.FireWeapon();
}

function ChangedWeapon()
{
	local int usealt;

	if ( Weapon == PendingWeapon )
	{
		if ( Weapon == None )
			SwitchToBestWeapon();
		else if ( Weapon.GetStateName() == 'DownWeapon' )
			Weapon.GotoState('Idle');
		PendingWeapon = None;
	}
	else
		Super.ChangedWeapon();

	if ( Weapon != None )
	{
		if ( bRACanFire && (bFire > 0) || (bAltFire > 0) )
		{
			Weapon.RateSelf(usealt);
			if ( usealt == 0 )
			{
				bAltFire = 0;
				bFire = 1;
				Weapon.Fire(1.0);
			}
			else
			{
				bAltFire = 0;
				bFire = 1;
				Weapon.AltFire(1.0);
			}
		}
		Weapon.SetHand(0);
	}
}

function SendVoiceMessage(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageID, name broadcasttype)
{
	local bool bNoSpeak;
	local RAReplicationInfo SenderRA;
	local PlayerIterator PIter;
	local RAGameReplicationInfo RAGRI;

	RAGRI = RAGameReplicationInfo(Level.Game.GameReplicationInfo);
	class'RATools'.static.GetRepInfo(Pawn(Sender.Owner), RAGRI, SenderRA);

	if ( Level.TimeSeconds - OldMessageTime < 2.5 )
		bNoSpeak = true;
	else
		OldMessageTime = Level.TimeSeconds;

	if (broadcasttype == 'SUPERGLOBAL')
		PIter = class'RATools'.static.PlayersInGame(RAGRI);
	else
		PIter = class'RATools'.static.PlayersInArena(RAGRI, SenderRA.Arena);
	PIter.Init();
	for (PIter=PIter; PIter.RARepInfo != None; PIter.Next())
	{

		//if they're sending to a person
		if ( PlayerPawn(PIter.Pawn) != None )
		{
			//and they're not spamming
			if ( !bNoSpeak )
			{
				//if it's an arena-level or game-level message, send it to the guy automatically
				if ( broadcasttype == 'GLOBAL' || broadcasttype == 'SUPERGLOBAL')
				{
					PIter.Pawn.ClientVoiceMessage(Sender, Recipient, messagetype, messageID);
				//else its a team based message, so check to make sure they are on the same RA team
				}
				else if ( SenderRA.Team == PIter.RARepInfo.Team )
				{
					PIter.Pawn.ClientVoiceMessage(Sender, Recipient, messagetype, messageID);
				}
			}
		}
		//or if we're sending a message directly to a bot, or if its an order, send it to the bot
		else if ( (PIter.PRI == Recipient) || ((messagetype == 'ORDER') && (Recipient == None)) )
			PIter.Pawn.BotVoiceMessage(messagetype, messageID, self);
	}
}

state Roaming
{
	ignores EnemyNotVisible;

	function PickDestination()
	{
		local float Bestweight;
		local actor BestPath;
		local decoration Dec;
		local NavigationPoint N;
		local int i;
		local bool bTriedToPick, bLockedAndLoaded, bNearPoint;
		local byte TeamPriority;
		local Pawn P;

		bCanTranslocate = ( Level.Game.IsA('DeathMatchPlus') && DeathMatchPlus(Level.Game).CanTranslocate(self) );
		if ( Level.Game.IsA('TeamGamePlus') )
		{
			if ( (Orders == 'FreeLance') && !bStayFreelance
				 &&	(Orders != BotReplicationInfo(PlayerReplicationInfo).RealOrders) )
				SetOrders(BotReplicationInfo(PlayerReplicationInfo).RealOrders, BotReplicationInfo(PlayerReplicationInfo).RealOrderGiver, true);
			if ( FRand() < 0.5 )
				bStayFreelance = false;
			LastAttractCheck = Level.TimeSeconds - 0.1;
			if ( TeamGamePlus(Level.Game).FindSpecialAttractionFor(self) )
			{
				if ( IsInState('Roaming') )
				{
					TeamPriority = TeamGamePlus(Level.Game).PriorityObjective(self);
					if ( TeamPriority > 16 )
					{
						PickLocalInventory(160, 1.8);
						return;
					}
					else if ( TeamPriority > 1 )
					{
						PickLocalInventory(200, 1);
						return;
					}
					else if ( TeamPriority > 0 )
					{
						PickLocalInventory(280, 0.55);
						return;
					}
					PickLocalInventory(400, 0.5);
				}
				return;
			}
		}
		bLockedAndLoaded = true;

		if (  Orders == 'Follow' )
		{
			if ( Pawn(OrderObject) == None )
				SetOrders('FreeLance', None);
			else if ( (Pawn(OrderObject).Health > 0) )
			{
				bNearPoint = CloseToPointMan(Pawn(OrderObject));
				if ( !bNearPoint )
				{
					if ( !bLockedAndLoaded )
					{
						bTriedToPick = true;
						if ( PickLocalInventory(600, 0) )
							return;

						if ( !OrderObject.IsA('PlayerPawn') )
						{
							BestWeight = 0;
							BestPath = FindBestInventoryPath(BestWeight, !bNovice && (skill >= 2));
							if ( BestPath != None )
							{
								MoveTarget = BestPath;
								return;
							}
						}
					}
					if ( ActorReachable(OrderObject) )
						MoveTarget = OrderObject;
					else
						MoveTarget = FindPathToward(OrderObject);
					if ( (MoveTarget != None) && (VSize(Location - MoveTarget.Location) > 2 * CollisionRadius) )
						return;
					if ( (VSize(OrderObject.Location - Location) < 1600) && LineOfSightTo(OrderObject) )
						bNearPoint = true;
					if ( bVerbose )
						log(self$" found no path to "$OrderObject);
				}
				else if ( !bInitLifeMessage && (Pawn(OrderObject).Health > 0)
							&& (VSize(Location - OrderObject.Location) < 500) )
				{
					bInitLifeMessage = true;
					SendTeamMessage(Pawn(OrderObject).PlayerReplicationInfo, 'OTHER', 3, 10);
				}
			}
		}
		if ( (Orders == 'Defend') && bLockedAndLoaded )
		{
			if ( PickLocalInventory(300, 0.55) )
				return;
			if ( FindAmbushSpot() )
				return;
			if ( !LineOfSightTo(OrderObject) )
			{
				MoveTarget = FindPathToward(OrderObject);
				if ( MoveTarget != None )
					return;
			}
			else if ( !bInitLifeMessage )
			{
				bInitLifeMessage = true;
				SendTeamMessage(None, 'OTHER', 9, 10);
			}
		}

		if ( (Orders == 'Hold') && bLockedAndLoaded && !LineOfSightTo(OrderObject) )
		{
			GotoState('Hold');
			return;
		}

		if ( !bTriedToPick && PickLocalInventory(600, 0) )
			return;

		if ( (Orders == 'Hold') && bLockedAndLoaded )
		{
			if ( VSize(Location - OrderObject.Location) < 20 )
				GotoState('Holding');
			else
				GotoState('Hold');
			return;
		}

		if ( ((Orders == 'Follow') && (bNearPoint || (Level.Game.IsA('TeamGamePlus') && TeamGamePlus(Level.Game).WaitForPoint(self))))
			|| ((Orders == 'Defend') && bLockedAndLoaded && LineOfSightTo(OrderObject)) )
		{
			if ( FRand() < 0.35 )
				GotoState('Wandering');
			else
			{
				CampTime = 0.8;
				GotoState('Roaming', 'Camp');
			}
			return;
		}

		bWantsToCamp = false;

		// if none found, check for decorations with inventory
		if ( !bNoShootDecor )
			foreach visiblecollidingactors(class'Decoration', Dec, 500,,true)
				if ( Dec.Contents != None )
				{
					bNoShootDecor = true;
					Target = Dec;
					GotoState('Roaming', 'ShootDecoration');
					return;
				}

		bNoShootDecor = false;
		BestWeight = 0;

		// look for long distance inventory
		BestPath = FindBestInventoryPath(BestWeight, !bNovice && (skill >= 2));
		if ( BestPath != None )
		{
			MoveTarget = BestPath;
			return;
		}

		// nothing around - maybe just wait a little
		if ( (FRand() < 0.35) && bNovice
			&& (!Level.Game.IsA('DeathMatchPlus') || !DeathMatchPlus(Level.Game).OneOnOne())  )
		{
			GoalString = " Nothing cool, so camp ";
			CampTime = 3.5 + FRand() - skill;
			GotoState('Roaming', 'Camp');
		}

		// if roamed to ambush point, stay there maybe
		if ( (AmbushPoint(RoamTarget) != None)
			&& (VSize(Location - RoamTarget.Location) < 2 * CollisionRadius)
			&& (FRand() < 0.4) )
		{
			CampTime = 4.0;
			GotoState('Roaming', 'LongCamp');
			return;
		}

		// hunt player
		if ( (!bNovice || (Level.Game.IsA('DeathMatchPlus') && DeathMatchPlus(Level.Game).OneOnOne()))
			&& (Weapon!=None) && (Weapon.AIRating > 0.5) && (Health > 60) )
		{
			if ( (PlayerPawn(RoamTarget) != None) && !LineOfSightTo(RoamTarget) )
			{
				BestPath = FindPathToward(RoamTarget);
				if ( BestPath != None )
				{
					MoveTarget = BestPath;
					return;
				}
			}
			else
			{
				// high skill bots go hunt player
				for ( P=Level.PawnList; P!=None; P=P.NextPawn )
					if ( P.bIsPlayer && P.IsA('PlayerPawn')
						&& ((VSize(P.Location - Location) > 1500) || !LineOfSightTo(P)) )
					{
						BestPath = FindPathToward(P);
						if ( BestPath != None )
						{
							RoamTarget = P;
							MoveTarget = BestPath;
							return;
						}
					}
			}
			bWantsToCamp = true; // don't camp if couldn't go to player
		}

		// look for ambush spot if didn't already try
		if ( !bWantsToCamp && FindAmbushSpot() )
		{
			RoamTarget = AmbushSpot;
			return;
		}

		// find a roamtarget
		if ( RoamTarget == None )
		{
			i = 0;
			for ( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
				if ( N.IsA('InventorySpot') )
				{
					i++;
					if ( (RoamTarget == None) || (Rand(i) == 0) )
						RoamTarget = N;
				}
		}

		// roam around
		if ( RoamTarget != None )
		{
			if ( ActorReachable(RoamTarget) )
			{
				MoveTarget = RoamTarget;
				RoamTarget = None;
				if ( VSize(MoveTarget.Location - Location) > 2 * CollisionRadius )
					return;
			}
			else
			{
				BestPath = FindPathToward(RoamTarget);
				if ( BestPath != None )
				{
					MoveTarget = BestPath;
					return;
				}
				else
					RoamTarget = None;
			}
		}

		 // wander or camp
		if ( FRand() < 0.35 )
			GotoState('Wandering');
		else
		{
			GoalString = " Nothing cool, so camp ";
			CampTime = 3.5 + FRand() - skill;
			GotoState('Roaming', 'Camp');
		}
	}
LongCamp:
	bCamping = true;
	Acceleration = vect(0,0,0);
	TweenToWaiting(0.15);
	TurnTo(Location + Ambushspot.lookdir);
	Sleep(CampTime);
	Goto('PreBegin');

GiveWay:
	bCamping = true;
	Acceleration = vect(0,0,0);
	if ( GetAnimGroup(AnimSequence) != 'Waiting' )
		TweenToWaiting(0.15);
	if ( NearWall(200) )
	{
		PlayTurning();
		TurnTo(MoveTarget.Location);
	}
	Sleep(CampTime);
	Goto('PreBegin');

Camp:
	bCamping = true;
	Acceleration = vect(0,0,0);
	TweenToWaiting(0.15);
ReCamp:
	if ( NearWall(200) )
	{
		PlayTurning();
		TurnTo(Focus);
	}
	Sleep(CampTime);
	if ( bLeading || bCampOnlyOnce )
	{
		bCampOnlyOnce = false;
		Goto('PreBegin');
	}
	if ( ((Orders != 'Follow') || ((Pawn(OrderObject).Health > 0) && CloseToPointMan(Pawn(OrderObject))))
		&& (Weapon != None) && (Weapon.AIRating > 0.4) && (3 * FRand() > skill + 1) )
		Goto('ReCamp');
PreBegin:
	SetPeripheralVision();
	WaitForLanding();
	bCamping = false;
	PickDestination();
	TweenToRunning(0.1);
	bCanTranslocate = false;
	Goto('SpecialNavig');
Begin:
	SwitchToBestWeapon();
	bCamping = false;
	TweenToRunning(0.1);
	WaitForLanding();

RunAway:
	PickDestination();
	bCanTranslocate = false;
SpecialNavig:
	if (SpecialPause > 0.0)
	{
		Disable('AnimEnd');
		Acceleration = vect(0,0,0);
		TweenToPatrolStop(0.3);
		Sleep(SpecialPause);
		SpecialPause = 0.0;
		Enable('AnimEnd');
		TweenToRunning(0.1);
		Goto('RunAway');
	}
Moving:
	if ( !IsAnimating() )
		AnimEnd();
	if ( MoveTarget == None )
	{
		Acceleration = vect(0,0,0);
		Sleep(0.0);
		Goto('RunAway');
	}
	if ( MoveTarget.IsA('InventorySpot') )
	{
		if ( (!Level.Game.IsA('TeamGamePlus') || (TeamGamePlus(Level.Game).PriorityObjective(self) == 0))
			&& (InventorySpot(MoveTarget).markedItem != None)
			&& (InventorySpot(MoveTarget).markedItem.BotDesireability(self) > 0) )
		{
			if ( InventorySpot(MoveTarget).markedItem.GetStateName() == 'Pickup' )
				MoveTarget = InventorySpot(MoveTarget).markedItem;
			else if (	(InventorySpot(MoveTarget).markedItem.LatentFloat < 5.0)
						&& (InventorySpot(MoveTarget).markedItem.GetStateName() == 'Sleeping')
						&& (abs(Location.Z - MoveTarget.Location.Z) < CollisionHeight)
						&& (VSize(Location - MoveTarget.Location + vect(0,0,1) * (MoveTarget.Location.Z - Location.Z)) < CollisionRadius * CollisionRadius) )
			{
				CampTime = FMin(5, InventorySpot(MoveTarget).markedItem.LatentFloat + 0.5);
				bCampOnlyOnce = true;
				Goto('Camp');
			}
		}
		else if ( MoveTarget.IsA('TrapSpringer')
				&& (abs(Location.Z - MoveTarget.Location.Z) < CollisionHeight)
				&& (VSize(Location - MoveTarget.Location + vect(0,0,1) * (MoveTarget.Location.Z - Location.Z)) < CollisionRadius * CollisionRadius) )
		{
			PlayVictoryDance();
			bCampOnlyOnce = true;
			bCamping = true;
			CampTime = 1.2;
			Acceleration = vect(0,0,0);
			Goto('ReCamp');
		}
	}
	else if ( MoveTarget.IsA('Inventory') && Level.Game.bTeamGame )
	{
		if ( Orders == 'Follow' )
			ShareWith(Pawn(OrderObject));
		else if ( SupportingPlayer != None )
			ShareWith(SupportingPlayer);
	}

	bCamping = false;
	MoveToward(MoveTarget);
	Goto('RunAway');

TakeHit:
	TweenToRunning(0.12);
	Goto('Moving');

Landed:
	if ( MoveTarget == None )
		Goto('RunAway');
	Goto('Moving');

AdjustFromWall:
	if ( !IsAnimating() )
		AnimEnd();
	bWallAdjust = true;
	bCamping = false;
	StrafeTo(Destination, Focus);
	Destination = Focus;
	MoveTo(Destination);
	bWallAdjust = false;
	Goto('Moving');

ShootDecoration:
	TurnToward(Target);
	if ( Target != None )
	{
		FireWeapon();
		bAltFire = 0;
		bFire = 0;
	}
	Goto('RunAway');
}

defaultproperties
{
      bRACanFire=False
}
