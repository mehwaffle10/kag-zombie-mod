// Bush logic

#include "LootCommon.as";

void onInit(CBlob@ this)
{
	this.server_setTeamNum(3);
}

//void onDie( CBlob@ this )
//{
//	//TODO: make random item
//}


//sprite

void onInit(CSprite@ this)
{
	// Give the pot a random texture
	this.SetFrameIndex(XORRandom(4));
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	// Safety Checks
	if (this is null || blob is null)
	{
		return false;
	}

	// Only collide if hit by arrow
	return blob.getName() == "arrow";

}

void onDie(CBlob@ this)
{
	// Drop loot when destroyed
	addLoot(this, INDEX_KNIGHT, 1, 0);
	server_CreateLoot(this, this.getPosition(), this.getTeamNum());

	// Play a sound on death
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
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
	this.AddScript("CheapFakeRolling.as");
}