// Gravestone logic

#include "LootCommon.as";
#include "GenericButtonCommon.as";

void onInit(CBlob@ this)
{
	// Safety Checks
	if (this is null)
	{
		return;
	}

	this.addCommandID("dig");

	this.server_setTeamNum(3);

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		// Give the gravestone a random texture, calculated the same on all clients, taken from Bush.as
		sprite.SetFrameIndex(this.getNetworkID() % sprite.animation.getFramesCount());
	}

	// Drop loot when destroyed
	addLoot(this, INDEX_KNIGHT, 1, 0);
}

void onDie(CBlob@ this)
{
	// Drop loot when destroyed
	server_CreateLoot(this, this.getPosition(), this.getTeamNum());

	// Spawn a body or rarely a zombie
	if (XORRandom(2) == 0)  // 50% chance to spawn a body/enemy
	{
		if (XORRandom(10) == 0)  // 10% chance to spawn an enemy
		{
			// Spawn an enemy
			string[] enemies = {"skeleton", "skeleton", "skeleton", "skeleton", "skeleton", "log", "log", "log", "zombie_arm"};
			server_CreateBlob(enemies[XORRandom(enemies.length)], 3, this.getPosition());
		}
		else
		{
			// Spawn a body (X_X) Death physics taken from RunnerDeath.as
			string[] bodies = {"archer", "knight", "builder"};
			CBlob@ body = server_CreateBlobNoInit(bodies[XORRandom(bodies.length)]);
			if (body !is null)
			{				
				body.Tag("dead");
				body.server_SetHealth(0.0f);
				body.server_setTeamNum(3);
				body.setPosition(this.getPosition());
				//body.setVelocity(Vec2f(2 - XORRandom(5), -2));
				body.Init();

				// Prevent the corpse from taunting
				body.RemoveScript("TauntAI.as");

				// add pickup attachment so we can pickup body
				CAttachment@ a = body.getAttachments();
				if (a !is null)
				{
					AttachmentPoint@ ap = a.AddAttachmentPoint("PICKUP", false);
				}
				
				// new physics vars so bodies don't slide
				body.getShape().setFriction(0.75f);
				body.getShape().setElasticity(0.2f);

				// disable tags
				body.Untag("shielding");
				body.Untag("player");
				body.getShape().getVars().isladder = false;
				body.getShape().getVars().onladder = false;
				body.getShape().checkCollisionsAgain = true;
				body.getShape().SetGravityScale(1.0f);	
			}
		}
	}

	// Play a sound and gib on death
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.Gib();
		sprite.PlaySound("sand_fall.ogg", 3.0f);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null || !canSeeButtons(this, caller))
	{
		return;
	}

	CBitStream params, missing;
	params.write_u16(caller.getNetworkID());

	if (caller.isOverlapping(this))
	{
		CButton@ dig_button = caller.CreateGenericButton(12, Vec2f(0, 0), this, this.getCommandID("dig"), getTranslatedString("Dig Up Grave"), params);
		if (dig_button !is null)
		{
			dig_button.enableRadius = 16.0f;
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (!isServer())
	{
		return;
	}

	if (cmd == this.getCommandID("dig"))
	{
		this.server_Die();
	}		
}
