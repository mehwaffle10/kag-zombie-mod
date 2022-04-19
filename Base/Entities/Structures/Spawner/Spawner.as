// Gravestone logic

#include "LootCommon.as";
#include "GenericButtonCommon.as";
#include "Hitters.as";
#include "FireCommon.as";

u8[] SPAWNER_LOOT_TABLE = INDEX_KNIGHT;
u8 MAX_COOLDOWN = 5 * getTicksASecond(), MIN_COOLDOWN = 2 * getTicksASecond();

void setRandomCooldown(CBlob@ this)
{
	this.set_u8("cooldown", MIN_COOLDOWN + XORRandom(MAX_COOLDOWN - MIN_COOLDOWN));
}

void onInit(CBlob@ this)
{
	setRandomCooldown(this);
	this.set_bool("active", false);
	addLoot(this, SPAWNER_LOOT_TABLE, 1, 0);
	this.Tag("heavy weight");
	this.Tag("ignore fall");
	this.set_s16(burn_duration, 30 * getTicksASecond());
}

void onInit(CSprite@ this)
{
	this.SetZ(-4.0f);
}

void onDie(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.Gib();
		sprite.PlaySound("destroy_wall.ogg", .75f);
	}
}

bool nearbyPlayer(CBlob@ this)
{
	f32 tilesize = getMap().tilesize;
	CBlob@[] players;
    getBlobsByTag("player", @players);
	for (u8 i = 0; i < players.length; i++)
	{
		if (players[i] !is null && (players[i].getPosition() - this.getPosition()).Length() < 20.0f * tilesize)
		{
			return true;
		}
	}
	return false;
}

void onTick(CBlob@ this)
{
	// Spawn enemies if player is nearby
	bool nearby_player = nearbyPlayer(this);
	if (isServer())
	{
		if (nearby_player)
		{
			if (this.get_u8("cooldown") > 0)
			{
				this.set_u8("cooldown", this.get_u8("cooldown") - 1);
			}
			else
			{
				setRandomCooldown(this);
				Vec2f spawn_offset = Vec2f(0.0f, -3.0f);
				// CBlob@ enemy = server_CreateBlob("log", 3, this.getPosition() + spawn_offset);
			}
		}
	}
	else
	{
		if (nearby_player && !this.get_bool("active"))
		{
			this.set_bool("active", true);
			CSprite@ sprite = this.getSprite();
			if (sprite !is null)
			{
				sprite.PlaySound("bridge_open.ogg", 3.0f);
			}
		}
		else if (!nearby_player && this.get_bool("active"))
		{
			this.set_bool("active", false);
			CSprite@ sprite = this.getSprite();
			if (sprite !is null)
			{
				sprite.PlaySound("bridge_close.ogg", 3.0f);
			}
		}
	}
	/*
	// Randomly spawn something identically across clients and server
	u8 body_chance = 2;  // 50% chance to spawn a body/enemy
	u8 enemy_chance = 5;  // 20% chance to spawn an enemy
	u8 total_outcomes = body_chance * enemy_chance;
	u8 outcome = this.getNetworkID() % total_outcomes;

	// Spawn a body or rarely a zombie
	if (outcome < total_outcomes / body_chance)
	{
		Vec2f spawn_offset = Vec2f(0.0f, -3.0f);
		if (outcome < (total_outcomes / body_chance) / enemy_chance)
		{
			// Spawn an enemy
			if (isServer())
			{
				string[] enemies = {"skeleton", "skeleton", "skeleton", "skeleton", "skeleton", "log", "log", "log", "zombie_arm"};
				CBlob@ enemy = server_CreateBlob(enemies[XORRandom(enemies.length)], 3, this.getPosition() + spawn_offset);
				if (enemy !is null)
				{
					addLoot(enemy, GRAVESTONE_LOOT_TABLE, 1, 0);
					enemy.AddScript("DropLootOnDeath.as");
				}
			}
			
			ParticleZombieLightning(this.getPosition() + spawn_offset);
		}
		else
		{
			// Spawn a body (X_X) Death physics taken from RunnerDeath.as
			if (isServer())
			{
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
		}
		
		// Play a wet sound for digging up bodies
		sprite.PlaySound("destroy_dirt.ogg", 3.0f);
	}
	else
	{
		// Drop loot directly when dug if no body is dug up
		if (isServer())
		{
			server_CreateLoot(this, this.getPosition(), 0);
		}
		
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
	*/
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
/*
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
*/