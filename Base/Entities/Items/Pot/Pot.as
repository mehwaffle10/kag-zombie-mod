// Pot logic

#include "LootCommon.as";

void onInit(CBlob@ this)
{
	// Safety Checks
	if (this is null)
	{
		return;
	}

	this.server_setTeamNum(3);

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		// Give the pot a random texture, calculated the same on all clients, taken from Bush.as
		sprite.SetFrameIndex(this.getNetworkID() % sprite.animation.getFramesCount());
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	// Safety Checks
	if (this is null || blob is null)
	{
		return false;
	}

	// Make pots collide with platforms and doors
	if (blob !is null && (blob.hasTag("door") || blob.getName() == "wooden_platform" || blob.getName() == "bridge"))
	{
		return true;	
	}

	// Only collide if hit by arrow
	return blob.getName() == "arrow";
}

void onDie(CBlob@ this)
{
	// Drop loot when destroyed
	server_CreateLoot(this, this.getPosition(), this.getTeamNum());

	// Play a sound and gib on death
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.Gib();
		sprite.PlaySound(XORRandom(2) == 0 ? "Rubble1.ogg" : "Rubble2.ogg", 3.0f);
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	// Safety Check
	if (this is null)
	{
		return;
	}

	// Break if thrown
	f32 threshold = 2.0f;
	if (isServer() && solid && !this.isAttached() && this.hasScript("CheapFakeRolling.as")) // (this.getVelocity().Length() > threshold || this.getOldVelocity().getLength() > threshold))
	{
		this.server_Die();
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	// Safety Check
	if (this is null)
	{
		return;
	}

	// Tag so that it breaks on contact no matter what
	if (!this.hasScript("CheapFakeRolling.as"))
	{
		this.AddScript("CheapFakeRolling.as");
	}

	// Reset the rotation when picked up to avoid holding it weird
	ResetRotation(this);
	
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	// Had to do this when thrown too because of onInit
	ResetRotation(this);
}

void ResetRotation(CBlob@ this)
{
	// Reset the rotation when picked up from CheapFakeRolling.as
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		f32 angle = 0.0f;
		this.set_f32("angle", angle);
		sprite.ResetTransform();
		sprite.RotateBy(angle, Vec2f());
	}
}
