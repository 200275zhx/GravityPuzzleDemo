#include "GravityWellWeapon.h"

#include "GravityWellProjectile.h"

AGravityWellWeapon::AGravityWellWeapon()
{
	PrimaryActorTick.bCanEverTick = false;
	BlackHoleProjectileClass = AGravityWellProjectile::StaticClass();
}

void AGravityWellWeapon::BeginPlay()
{
	Super::BeginPlay();

	ProjectileClass = BlackHoleProjectileClass;
}

void AGravityWellWeapon::StartFiring()
{
	HandlePrimaryFire();
}

void AGravityWellWeapon::StopFiring()
{
	Super::StopFiring();
}

void AGravityWellWeapon::StartSecondaryFire()
{
	HandleSecondaryFire();
}

void AGravityWellWeapon::StopSecondaryFire()
{
}

void AGravityWellWeapon::HandlePrimaryFire()
{
	// 1. Check if bullet flying
	if (AGravityWellProjectile* Flying = FlyingProjectile.Get())
	{
		Flying->ActivateBlackHole();

		if (bIsWhiteHoleMode)
		{
			Flying->SetPolarity(true);
		}

		FlyingProjectile.Reset();
		return;
	}

	// 2. If no bullet flying, check if can shoot new bullet
	const float CurrentTime = GetWorld() ? GetWorld()->GetTimeSeconds() : 0.f;
	if (CurrentTime - LastShotTime < RefireRate)
	{
		return;
	}

	if (AGravityWellProjectile* NewProjectile = SpawnGravityProjectile())
	{
		FlyingProjectile = NewProjectile;
		LastShotTime = CurrentTime;

		if (PawnOwner)
		{
			MakeNoise(ShotLoudness, PawnOwner, PawnOwner->GetActorLocation(), ShotNoiseRange, ShotNoiseTag);
		}
	}
}

void AGravityWellWeapon::HandleSecondaryFire()
{
	// 1. Change gun status
	bIsWhiteHoleMode = !bIsWhiteHoleMode;

	// 2. If black/white hole exists, change status
	if (AGravityWellProjectile* ActiveHole = ActiveHoleProjectile.Get())
	{
		ActiveHole->TogglePolarity();
	}
	
	/*
	// === New: When bullet flying, change status ===
	if (AGravityWellProjectile* Flying = FlyingProjectile.Get())
	{
		Flying->SetPendingPolarity(bIsWhiteHoleMode);
	}
	*/

	if (GEngine)
	{
		// 1. Text
		FString ModeStr = bIsWhiteHoleMode ? TEXT("Current Mode: WHITE HOLE (Push)") : TEXT("Current Mode: BLACK HOLE (Pull)");

		// 2. Print Text Color (Cyan for White hole; Purple for Black hole)
		FColor TextColor = bIsWhiteHoleMode ? FColor::Cyan : FColor::Purple;

		// 3. Print Screen
		GEngine->AddOnScreenDebugMessage(10, 2.0f, TextColor, ModeStr);
	}
}

void AGravityWellWeapon::ActivateFlyingProjectile()
{
	if (AGravityWellProjectile* Flying = FlyingProjectile.Get())
	{
		Flying->ActivateBlackHole();
		FlyingProjectile.Reset();
	}
}

AGravityWellProjectile* AGravityWellWeapon::SpawnGravityProjectile()
{
	if (!BlackHoleProjectileClass || !WeaponOwner)
	{
		return nullptr;
	}

	const FVector TargetLocation = WeaponOwner->GetWeaponTargetLocation();
	AShooterProjectile* SpawnedProjectile = SpawnProjectileOfClass(TargetLocation, BlackHoleProjectileClass);
	if (AGravityWellProjectile* GravityProjectile = Cast<AGravityWellProjectile>(SpawnedProjectile))
	{
		// === New: Message bullet the status of gun ===
		GravityProjectile->SetPendingPolarity(bIsWhiteHoleMode);

		BindProjectileDelegates(GravityProjectile);
		return GravityProjectile;
	}

	return nullptr;
}

void AGravityWellWeapon::BindProjectileDelegates(AGravityWellProjectile* Projectile)
{
	if (!Projectile)
	{
		return;
	}

	Projectile->OnBlackHoleActivated.AddUObject(this, &AGravityWellWeapon::HandleProjectileActivated);
	Projectile->OnBlackHoleDeactivated.AddUObject(this, &AGravityWellWeapon::HandleProjectileDeactivated);
	Projectile->OnDestroyed.AddDynamic(this, &AGravityWellWeapon::HandleProjectileDestroyed);
}

void AGravityWellWeapon::HandleProjectileDestroyed(AActor* DestroyedActor)
{
	if (AGravityWellProjectile* Projectile = Cast<AGravityWellProjectile>(DestroyedActor))
	{
		if (FlyingProjectile.Get() == Projectile)
		{
			FlyingProjectile.Reset();
		}

		if (ActiveHoleProjectile.Get() == Projectile)
		{
			ActiveHoleProjectile.Reset();
		}
	}
}

void AGravityWellWeapon::HandleProjectileActivated(AGravityWellProjectile* Projectile)
{
	if (!Projectile)
	{
		return;
	}

	if (AGravityWellProjectile* ExistingActive = ActiveHoleProjectile.Get())
	{
		if (ExistingActive != Projectile && ExistingActive->IsBlackHoleActive())
		{
			ExistingActive->DeactivateBlackHole();
		}
	}

	ActiveHoleProjectile = Projectile;

	if (FlyingProjectile.Get() == Projectile)
	{
		FlyingProjectile.Reset();
	}
}

void AGravityWellWeapon::HandleProjectileDeactivated(AGravityWellProjectile* Projectile)
{
	if (ActiveHoleProjectile.Get() == Projectile)
	{
		ActiveHoleProjectile.Reset();
	}
}
