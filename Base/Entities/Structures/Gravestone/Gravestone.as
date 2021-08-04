// Gravestone logic

#include "LootCommon.as";
#include "GenericButtonCommon.as";
#include "Hitters.as";

string DUG_FLAG_STRING = "dug_flag";
string SHOVEL_ICON_STRING = "shovel_icon";

u8[] GRAVESTONE_LOOT_TABLE = INDEX_KNIGHT;

void SetAnimation(CBlob@ this, bool dug)
{
	// Safety Checks
	if (this is null)
	{
		return;
	}

	CSprite@ sprite = this.getSprite();
	if (sprite is null)
	{
		return;	
	}

	// Give the gravestone a random texture, calculated the same on all clients, taken from Bush.as
	sprite.SetAnimation(dug ? "dug" : "default");
	sprite.SetFrameIndex(this.getNetworkID() % sprite.animation.getFramesCount());
}

void onInit(CBlob@ this)
{
	// Safety Checks
	if (this is null)
	{
		return;
	}

	this.Tag("builder always hit");
	this.addCommandID("dig");
	this.set_bool(DUG_FLAG_STRING, false);
	SetAnimation(this, false);

	// Set the team number to the same team as the survivors so that it will not play a sound when hit in OnHitFailed.as
	this.server_setTeamNum(0);

	// Drop loot when dug
	addLoot(this, GRAVESTONE_LOOT_TABLE, 1, 0);

	// Add the shovel icon
	AddIconToken(SHOVEL_ICON_STRING, "Entities/Structures/Gravestone/ShovelIcon.png", Vec2f(32, 32), 3);
}

void onInit(CSprite@ this)
{
	if (this is null)
	{
		return;
	} 

	this.SetZ(-4.0f);
}

void onDie(CBlob@ this)
{
	if (this is null)
	{
		return;
	}

	MakeMaterial(this, "mat_stone", 15);

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.Gib();
		sprite.PlaySound("destroy_wall.ogg", .75f);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null || this is null || !canSeeButtons(this, caller) || this.get_bool(DUG_FLAG_STRING))
	{
		return;
	}

	if (caller.isOverlapping(this))
	{
		// Create a button and lower the activation radius
		CBitStream params, missing;
		params.write_u16(caller.getNetworkID());

		CButton@ dig_button = caller.CreateGenericButton(SHOVEL_ICON_STRING, Vec2f(0, 0), this, this.getCommandID("dig"), getTranslatedString("Dig Up Grave"));
		if (dig_button !is null)
		{
			dig_button.enableRadius = 16.0f;
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	// Safety Check
	if (this is null)
	{
		return;
	}

	CSprite@ sprite = this.getSprite();
	if (sprite is null)
	{
		return;
	}

	if (cmd == this.getCommandID("dig") && !this.get_bool(DUG_FLAG_STRING))
	{
		// Flag that this grave has been dug
		this.set_bool(DUG_FLAG_STRING, true);

		// Spawn a body or rarely a zombie
		if (XORRandom(2) == 0)  // 50% chance to spawn a body/enemy
		{
			Vec2f spawn_offset = Vec2f(0.0f, -3.0f);
			if (XORRandom(5) == 0)  // 20% chance to spawn an enemy
			{
				// Spawn an enemy
				string[] enemies = {"skeleton", "skeleton", "skeleton", "skeleton", "skeleton", "log", "log", "log", "zombie_arm"};
				CBlob@ enemy = server_CreateBlob(enemies[XORRandom(enemies.length)], 3, this.getPosition() + spawn_offset);
				if (enemy !is null)
				{
					addLoot(enemy, GRAVESTONE_LOOT_TABLE, 1, 0);
					enemy.AddScript("DropLootOnDeath.as");
				}
				ParticleZombieLightning(this.getPosition() + spawn_offset);
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
					body.setPosition(this.getPosition() + spawn_offset);
					body.setVelocity(Vec2f(1 - XORRandom(3), -2));
					body.Init();

					// Make corpse drop loot when destroyed
					addLoot(body, GRAVESTONE_LOOT_TABLE, 1, 0);
					body.AddScript("DropLootOnDeath.as");

					// Prevent the corpse from showing up on the minimap
					body.UnsetMinimapVars();

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

			// Play a wet sound for digging up bodies
			sprite.PlaySound("destroy_dirt.ogg", 3.0f);
		}
		else
		{
			// Drop loot directly when dug if no body is dug up
			server_CreateLoot(this, this.getPosition(), 0);

			// Spawn bone gibs as if there was a decayed corpse
			for (u8 i = 0; i < 5; i++)
			{
				makeGibParticle("GenericGibs", this.getPosition(), getRandomVelocity(90.0f, 2.0f, 45.0f), 5, XORRandom(8), Vec2f(8, 8), 2.0f, 0, XORRandom(2) == 0 ? "bone_fall1.ogg" : "bone_fall2.ogg", this.getTeamNum());
			}

			// Play a dry sound for digging up bones
			sprite.PlaySound("sand_fall.ogg", 3.0f);
		}

		// Play shovel sound and change animation when dug
		SetAnimation(this, true);
		string[] dig_sounds = {"dig_dirt1.ogg", "dig_dirt2.ogg", "dig_dirt3.ogg"};
		sprite.PlaySound(dig_sounds[XORRandom(dig_sounds.length)], 3.0f);

		// Spray dirt particles
		for (u8 i = 0; i < 10; i++)
		{
			ParticlePixel(this.getPosition(), getRandomVelocity(90.0f, 2.0f + 2.0f / (1 + XORRandom(4)), 45.0f), SColor(0xff3b1406), false);
		}
	}	
}

CBlob@ MakeMaterial(CBlob@ this, const string &in name, const int quantity)
{
	// Safety Check
	if (this is null || !isServer())
	{
		return null;
	}

	CBlob@ mat = server_CreateBlobNoInit(name);

	if (mat !is null)
	{
		mat.setPosition(this.getPosition());
		mat.Tag('custom quantity');
		mat.Init();

		mat.server_SetQuantity(quantity);		
	}

	return mat;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this is null || customData == Hitters::bite)
	{
		return 0.0f;
	}

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		string[] rubble_sounds = {"rock_hit1.ogg", "rock_hit2.ogg", "rock_hit3.ogg"};
		// {"dig_stone1.ogg", "dig_stone2.ogg", "dig_stone3.ogg", "Kick.ogg", "Kick.ogg", "Kick.ogg", "Kick.ogg", "Kick.ogg", "Kick.ogg"};
		// {"Kick.ogg"};
		string[] dig_sounds = {"PickStone1.ogg", "PickStone2.ogg", "PickStone3.ogg"};
		sprite.PlaySound(dig_sounds[XORRandom(dig_sounds.length)], .75f);
	
		makeGibParticle("GenericGibs", this.getPosition(), getRandomVelocity(90.0f, 2.0f, 45.0f), 2, XORRandom(8), Vec2f(8, 8), 2.0f, 0, rubble_sounds[XORRandom(rubble_sounds.length)], this.getTeamNum());
	}

	return damage;
}