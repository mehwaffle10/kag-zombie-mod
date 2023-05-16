
#include "GenericButtonCommon.as"
#include "ZombiesMinimapCommon.as"
#include "ZombieBlocksCommon.as"

const u8 CORRUPTION_RADIUS = 10;

namespace State
{
	enum state_type
	{
		inactive = 0,
		active,
		liberated
	};
};

void onInit(CBlob@ this)
{
	// Spawning
	this.set_u16("spawn_delay", 15 * getTicksASecond());
	this.set_u16("spawn_timer", 0);
	this.set_u16("points_per_day", 10);
	this.set_u16("points", 0);
	this.set_u8("state", State::inactive);
	this.set_string("rank", "basic");
	this.SetLight(true);

	// State changes for day/night
	this.Tag("day");
	this.addCommandID("day");
	this.Tag("night");
	this.addCommandID("night");
	this.set_bool("is_day", true);

	// Other commands
	this.addCommandID("corrupt");
	this.addCommandID("liberate");

	// Animation
	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		u16 netID = this.getNetworkID();
		sprite.animation.frame = (netID % sprite.animation.getFramesCount());
		sprite.SetZ(-10.0f);
	}

	// Minimap. We want this to be initialized every time the client joins so don't set it on the server
	if (isClient())
	{
		this.set_bool("minimap_initialized", false);
	}
}

void UpdateAnim(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	u8 state = this.get_u8("state");
	if (state == State::inactive && !sprite.isAnimation("inactive"))
	{
		sprite.SetAnimation("closed");
		this.SetLightRadius(this.getRadius() * 1.1f);
	}
	else if (state == State::active && !sprite.isAnimation("active"))
	{
		sprite.SetAnimation("open");
		this.SetLightRadius(this.getRadius() * 1.5f);
	}
}

void onTick(CBlob@ this)
{
	u8 state = this.get_u8("state");

	// Initialize minimap
	if (isClient() && !this.get_bool("minimap_initialized") && this.exists("sector") && Texture::exists(ZOMBIE_MINIMAP_TEXTURE))
	{
		setSectorBorderColor(this);
	}

	// Spawn enemies
	if (state == State::active)
	{

		u16 points = this.get_u16("points");
		u16 points_per_day = this.get_u16("points_per_day");

		string rank = this.get_string("rank");
		u16 spawn_timer = this.get_u16("spawn_timer");
		u16 spawn_delay = this.get_u16("spawn delay");

		u8 action = XORRandom(100);

		u8 skeleton_cost = 1;
		u8 zombie_cost = 3;
		u8 upgrade_cost = 10;

		// Close if we're out of points
		if (points == 0)
		{
			this.set_u8("state", State::inactive);
			this.Sync("state", true);
			UpdateAnim(this);
			return;
		}

		// Try to spend points
		if (spawn_timer == 0)
		{
			if (rank == "basic")
			{
				if (action < 70) // Spawn skeleton
				{
					if (points >= skeleton_cost)
					{
						Summon(this, "skeleton", skeleton_cost);
					}
				}
				else if (action >= 70 && action < 95) // Spawn zombie
				{
					if (points >= zombie_cost)
					{
						Summon(this, "log", zombie_cost);
					}
				}
				else // 95 <= action < 100 // Upgrade to advanced
				{
					if (points >= upgrade_cost)
					{
						this.set_u16("points", points - upgrade_cost);
						this.set_u16("spawn_timer", spawn_delay);

						this.set_u16("points_per_day", points_per_day * 2);
						this.set_string("rank", "advanced");
					}
				}
			}
		}
		else
		{
			this.set_u16("spawn_timer", spawn_timer - 1);
		}
	}
}

void Summon(CBlob@ this, string spawn, u8 cost)
{
	if (getNet().isServer())
	{
		this.set_u16("points", this.get_u16("points") - cost);
		this.Sync("points", true);
		this.set_u16("spawn_timer", this.get_u16("spawn_delay"));

		this.getSprite().PlaySound("Thunder" + (XORRandom(2) + 1) + ".ogg");

		CBlob@ b = server_CreateBlob(spawn, this.getTeamNum(), this.getPosition());
		b.AddScript("DieOnDayBreak.as");
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
		// Select corrupt or liberate button
		if (this.get_u8("state") == State::liberated)
		{
			// Add corrupt button. For testing purposes only
			CButton@ corrupt_button = caller.CreateGenericButton(12, Vec2f(0, 8), this, this.getCommandID("corrupt"), getTranslatedString("Corrupt Portal"), params);
			if (corrupt_button !is null)
			{
				corrupt_button.enableRadius = 32.0f;
			}
		}
		else
		{
			// Add liberate button. Will require special item and conditions
			CButton@ liberate_button = caller.CreateGenericButton(12, Vec2f(0, 8), this, this.getCommandID("liberate"), getTranslatedString("Liberate Portal"), params);
			if (liberate_button !is null)
			{
				liberate_button.enableRadius = 32.0f;
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("day"))
	{
		// Turn off and award points for the day
		this.set_bool("is_day", true);
		if (isServer())
		{
			this.set_u8("state", State::inactive);
			this.Sync("state", true);
			this.set_u16("points", this.get_u16("points") + this.get_u16("points_per_day"));
			this.Sync("points", true);
		}

		UpdateAnim(this);
	}
	else if (cmd == this.getCommandID("night"))
	{
		// Activate! It's night time
		this.set_bool("is_day", false);
		if (isServer())
		{
			this.set_u8("state", State::active);
			this.Sync("state", true);

			// Give portals a random spawn timer so that they don't all spawn at the same time
			this.set_u16("spawn_timer", XORRandom(this.get_u16("spawn_delay")));
		}

		UpdateAnim(this);
	}
	else if (cmd == this.getCommandID("corrupt"))
	{
		ModifyWorld(this, true);

		// Set the state
		this.set_u8("state", this.get_bool("is_day") ? State::inactive : State::active);
		this.server_setTeamNum(3);

		// Update the minimap border colors
		CMap@ map = getMap();
		if (!this.exists("sector"))
		{
			return;
		}
		setSectorBorderColor(this);

		// Prevent players from building here
		if (map.getSectorAtPosition(this.getPosition(), "no build") !is null)
		{
			return;
		}
		Vec2f sector = this.get_Vec2f("sector");
		map.server_AddSector(Vec2f(sector.x, 0) * map.tilesize, Vec2f(sector.y, map.tilemapheight) * map.tilesize, "no build");

	}
	else if (cmd == this.getCommandID("liberate"))
	{
		ModifyWorld(this, false);

		// Set the state
		this.set_u8("state", State::liberated);
		this.server_setTeamNum(0);

		// Update the minimap border colors
		CMap@ map = getMap();
		if (!this.exists("sector"))
		{
			return;
		}
		setSectorBorderColor(this);

		// Allow players to build here
		if (map.getSectorAtPosition(this.getPosition(), "no build") is null)
		{
			return;
		}
		map.RemoveSectorsAtPosition(this.getPosition(), "no build");
	}
}

void ModifyWorld(CBlob@ this, bool corrupt)
{
	CMap@ map = getMap();

	if (!isServer() || map is null || this is null)
	{
		return;
	}

	Vec2f pos = map.getTileSpacePosition(this.getPosition());
	for (s32 x = Maths::Max(0, pos.x - CORRUPTION_RADIUS); x < Maths::Min(map.tilemapwidth, pos.x + CORRUPTION_RADIUS); x++)
	{
		for (s32 y = Maths::Max(0, pos.y - CORRUPTION_RADIUS); y < Maths::Min(map.tilemapheight, pos.y + CORRUPTION_RADIUS); y++)
		{
			Vec2f target_pos = Vec2f(x, y);
			if (corrupt)
			{
				ZombifyBlock(map, target_pos);
			}
			else
			{
				UnzombifyBlock(map, target_pos);
			}
		}
	}
	map.UpdateLightingAtPosition(this.getPosition(), CORRUPTION_RADIUS);
}

// s32 getGroundYLevel(CMap@ map, s32 x)
// {
// 	for (s32 y = 0; y < map.tilemapheight; y++)
// 	{
// 		// Check both blocks, pick the highest one so that the border particles always are at the same height and aren't behind blocks
// 		for (u8 x_offset = 0; x_offset <= 1; x_offset++)
// 		{		
// 			Tile t = map.getTile(Vec2f(x - x_offset, y) * map.tilesize);
// 			if (t.type == CMap::tile_ground     ||  // Dirt Blocks
// 				t.type >= 29 && t.type <= 31    ||  // Damaged Dirt Blocks
// 				t.type == CMap::tile_thickstone ||  // Dense Stone Ore
// 				t.type >= 214 && t.type <= 218  ||  // Damaged Dense Stone Ore
// 				t.type == CMap::tile_stone      ||  // Stone Ore
// 				t.type >= 100 && t.type <= 104  ||  // Damaged Stone Ore
// 				t.type == CMap::tile_gold       ||  // Gold Ore
// 				t.type >= 91 && t.type <= 94    ||  // Damaged Gold Ore
// 				t.type == CMap::tile_bedrock)       // Bedrock
// 			{
// 				return y;
// 			}
// 		}
// 	}
// 	return -1;
// }
