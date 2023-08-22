
#include "GenericButtonCommon.as"
#include "ZombiesMinimapCommon.as"
#include "ZombieBlocksCommon.as"

const u8 CORRUPTION_RADIUS = 1;

const string PORTAL_SPRITE_LAYER = "portal";
const string PORTAL_ACTIVE_ANIMATION = "portal";
const string PORTAL_OPEN_ANIMATION = "portal_open";

const string FIRE_SPRITE_LAYER = "fire";
const string FIRE_ANIMATION = "fire";
const f32 FIRE_RELATIVE_Z = 11.0f;

const string FLAMES_SPRITE_LAYER = "flames";
const string FLAMES_ANIMATION = "flames";

namespace State
{
	enum state_type
	{
		inactive = 0,
		active,
		liberated
	};
};

// class TileUpdates
// {
// 	Vec2f[] queue;
// 	u32 steps;
// }

void onInit(CBlob@ this)
{
	// Spawning
    if (isServer())
    {
        this.set_u16("spawn_delay", 15 * getTicksASecond());
        this.set_u16("spawn_timer", 0);
        this.set_u16("points_per_day", 10);
        this.set_u16("points", 0);
        this.set_u8("state", State::inactive);
        this.set_string("rank", "basic");
    }
    this.SetLight(true);

	// State changes for day/night
	this.Tag("day");
	this.addCommandID("day");
	this.Tag("night");
	this.addCommandID("night");

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

        // Portal
        CSpriteLayer@ portal = sprite.addSpriteLayer(PORTAL_SPRITE_LAYER);
        if (portal !is null)
        {
            portal.SetRelativeZ(10.0f);
            portal.SetOffset(Vec2f(0, -4));
            Animation@ animation = portal.addAnimation(PORTAL_ACTIVE_ANIMATION, 5, true);
            if (animation !is null)
            {
                s32[] frames = {12, 13, 14};
                animation.AddFrames(frames);
            }
            @animation = portal.addAnimation(PORTAL_OPEN_ANIMATION, 5, false);
            if (animation !is null)
            {
                s32[] frames = {0, 6, 7, 8};
                animation.AddFrames(frames);
            }
        }

        // Fire under portal
        CSpriteLayer@ fire = sprite.addSpriteLayer(FIRE_SPRITE_LAYER);
        if (fire !is null)
        { 
            fire.ReloadSprite("Portal.png", 48, 16, this.getTeamNum(), 0);
            fire.SetRelativeZ(FIRE_RELATIVE_Z);
            fire.SetOffset(Vec2f(0, 16));
            Animation@ animation = fire.addAnimation(FIRE_ANIMATION, 5, true);
            if (animation !is null)
            {
                s32[] frames = {2, 8, 14};
                animation.AddFrames(frames);
            }
        }

        // Flames above portal
        CSpriteLayer@ flames = sprite.addSpriteLayer(FLAMES_SPRITE_LAYER);
        if (flames !is null)
        { 
            
            flames.ReloadSprite("Portal.png", 48, 16, this.getTeamNum(), 0);
            flames.SetRelativeZ(FIRE_RELATIVE_Z);
            flames.SetOffset(Vec2f(0, -18));
            Animation@ animation = flames.addAnimation(FLAMES_ANIMATION, 5, true);
            if (animation !is null)
            {
                s32[] frames = {1, 7, 13};
                animation.AddFrames(frames);
            }
        }
	}

	// Minimap. We want this to be initialized every time the client joins so don't set it on the server
	if (isClient())
	{
		this.set_bool("minimap_initialized", false);
	}

	// Corruption effect
	// if (isServer())
	// {
	// 	TileUpdates@ tile_updates = TileUpdates();
	// 	this.set("tile_updates", @tile_updates);
	// }
}

void UpdateAnim(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
    if (sprite is null)
    {
        return;
    }
    CSpriteLayer@ portal = sprite.getSpriteLayer(PORTAL_SPRITE_LAYER);
    if (portal is null)
    {
        return;
    }

	u8 state = this.get_u8("state");
	if (state == State::inactive)
	{
        if (!portal.isAnimation(PORTAL_OPEN_ANIMATION))
        {
            portal.SetAnimation(PORTAL_OPEN_ANIMATION);
            portal.SetFrameIndex(portal.animation.getFramesCount() - 1);
        }
        portal.animation.backward = true;
		this.SetLightRadius(50.0f);
	}
	else if (!portal.isAnimation(PORTAL_ACTIVE_ANIMATION))
	{
		portal.SetAnimation(PORTAL_OPEN_ANIMATION);
        portal.animation.backward = false;
		this.SetLightRadius(80.0f);
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

    // Sprite updates
    CSprite@ sprite = this.getSprite();
    if (sprite !is null)
    {
        CSpriteLayer@ portal = sprite.getSpriteLayer(PORTAL_SPRITE_LAYER);
        if (portal !is null && portal.isAnimation(PORTAL_OPEN_ANIMATION) && portal.isAnimationEnded() && !portal.animation.backward)
        {
            portal.SetAnimation(PORTAL_ACTIVE_ANIMATION);
        }
    }

	// Spawn enemies
	// if (state == State::active)
	// {
	// 	u16 points = this.get_u16("points");
	// 	u16 points_per_day = this.get_u16("points_per_day");

	// 	string rank = this.get_string("rank");
	// 	u16 spawn_timer = this.get_u16("spawn_timer");
	// 	u16 spawn_delay = this.get_u16("spawn delay");

	// 	u8 action = XORRandom(100);

	// 	u8 skeleton_cost = 1;
	// 	u8 zombie_cost = 3;
	// 	u8 upgrade_cost = 10;

	// 	// Close if we're out of points
	// 	if (points == 0)
	// 	{
	// 		this.set_u8("state", State::inactive);
	// 		this.Sync("state", true);
	// 		UpdateAnim(this);
	// 		return;
	// 	}

	// 	// Try to spend points
	// 	if (spawn_timer == 0)
	// 	{
	// 		if (rank == "basic")
	// 		{
	// 			if (action < 70) // Spawn skeleton
	// 			{
	// 				if (points >= skeleton_cost)
	// 				{
	// 					Summon(this, "skeleton", skeleton_cost);
	// 				}
	// 			}
	// 			else if (action >= 70 && action < 95) // Spawn zombie
	// 			{
	// 				if (points >= zombie_cost)
	// 				{
	// 					Summon(this, "log", zombie_cost);
	// 				}
	// 			}
	// 			else // 95 <= action < 100 // Upgrade to advanced
	// 			{
	// 				if (points >= upgrade_cost)
	// 				{
	// 					this.set_u16("points", points - upgrade_cost);
	// 					this.set_u16("spawn_timer", spawn_delay);

	// 					this.set_u16("points_per_day", points_per_day * 2);
	// 					this.set_string("rank", "advanced");
	// 				}
	// 			}
	// 		}
	// 	}
	// 	else
	// 	{
	// 		this.set_u16("spawn_timer", spawn_timer - 1);
	// 	}
	// }

	// string prefix = "" + getGameTime();
	// for (u16 i = 0; i < tile_updates.length; i++)
	// {
	// 	print(prefix + ": tile_updates[" + i + "] = " + tile_updates[i]);
	// }

    /*
	// Block updates
	if (isServer()) // && XORRandom(10) == 0)
	{
		CMap@ map = getMap();
		if (map is null || !this.exists("sector") || !this.exists("tile_updates"))
		{
			return;
		}
		Vec2f sector = this.get_Vec2f("sector");

		TileUpdates@ tile_updates;
		this.get("tile_updates", @tile_updates);
		for (u8 i = 0; i < 3; i++)
		{
			if (tile_updates.queue.isEmpty())
			{
				return;
			}
			// Get the next item
			u32 index = tile_updates.queue.length - 1 - XORRandom(Maths::Min(tile_updates.steps * 3, tile_updates.queue.length - 1));
			Vec2f tile_pos = tile_updates.queue[index];
			tile_updates.queue.removeAt(index);
			tile_updates.steps += 1;
			Vec2f world_pos = tile_pos * map.tilesize;
			TileType type = map.getTile(world_pos).type;

			// Too many issues with the circle
			// Check if we're out of bounds and should just move towards the portal
			// if (outOfBounds(map, tile_pos, sector))  // Out of bounds y
			// {
			// 	// Only move 1 tile in a cardinal direction to maintain the portal as the center
			// 	Vec2f offset;
			// 	if (tile_pos.x < sector.x)
			// 	{
			// 		offset = Vec2f(1, 0);
			// 	}
			// 	else if (tile_pos.x >= sector.y)
			// 	{
			// 		offset = Vec2f(-1, 0);
			// 	}
			// 	else if (tile_pos.y < 0)
			// 	{
			// 		offset = Vec2f(0, 1);
			// 	}
			// 	else
			// 	{
			// 		offset = Vec2f(0, -1);
			// 	}
			// 	tile_updates.queue.push_back(tile_pos + offset * CORRUPTION_RADIUS);
			// 	continue;
			// }

			// Modify this block
			bool corrupt = state != State::liberated;
			Corrupt(map, world_pos, corrupt);

			// Check neighbors
			for (s8 x = -CORRUPTION_RADIUS; x <= CORRUPTION_RADIUS; x++)
			{
				u8 y_limit = CORRUPTION_RADIUS - Maths::Abs(x);
				for (s8 y = -y_limit; y <= y_limit; y++)
				{
					Vec2f target = tile_pos + Vec2f(x, y);
					if (target == tile_pos ||                                    // Current block
						target.x < sector.x || target.x >= sector.y ||           // Out of bounds x
						target.y < 0 || target.y >= map.tilemapheight ||         // Out of bounds y
						(corrupt ? type >= WORLD_OFFSET : type < WORLD_OFFSET))  // Already converted
					{
						continue;
					}
					tile_updates.queue.push_back(target);
				}
			}

			// Modify grass above dirt
			if (tile_pos.y > 0 && isDirt(type))
			{
				Vec2f tile_above = world_pos + Vec2f(0, -map.tilesize);
				TileType above = map.getTile(tile_above).type;
				if (isGrass(above))
				{
					Corrupt(map, tile_above, corrupt);
				}
			}

			// Modify dirt below grass
			if (tile_pos.y < map.tilemapheight && isGrass(type))
			{
				Vec2f tile_below = world_pos + Vec2f(0, map.tilesize);
				TileType below = map.getTile(tile_below).type;
				if (isDirt(below))
				{
					Corrupt(map, tile_below, corrupt);
				}
			}
		}
	}
    */
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
            // Add close button. Debug only
            if (this.get_u8("state") == State::active)
            {
                CButton@ close_button = caller.CreateGenericButton(12, Vec2f(8, 8), this, this.getCommandID("day"), getTranslatedString("Close Portal"), params);
                if (close_button !is null)
                {
                    close_button.enableRadius = 32.0f;
                }
            }
            else
            {
                CButton@ open_button = caller.CreateGenericButton(12, Vec2f(8, 8), this, this.getCommandID("night"), getTranslatedString("Open Portal"), params);
                if (open_button !is null)
                {
                    open_button.enableRadius = 32.0f;
                }
            }
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	u8 state = this.get_u8("state");
	if (cmd == this.getCommandID("day"))
	{
        if (state != State::liberated)
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
        }
		UpdateAnim(this);
	}
	else if (cmd == this.getCommandID("night"))
	{
        if (state != State::liberated)
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
        }
		UpdateAnim(this);
	}
	else if (cmd == this.getCommandID("corrupt"))
	{
		// Set the state
		this.set_u8("state", this.get_bool("is_day") ? State::inactive : State::active);
		this.server_setTeamNum(3);
        UpdateAnim(this);

		// Update the minimap border colors
		CMap@ map = getMap();
		if (!this.exists("sector"))
		{
			return;
		}
		Vec2f sector = this.get_Vec2f("sector");
		setSectorBorderColor(this);
        
        // Prevent players from building here
        if (map.getSectorAtPosition(this.getPosition(), "no build") !is null)
        {
            return;
        }
        map.server_AddSector(Vec2f(sector.x, 0) * map.tilesize, Vec2f(sector.y, map.tilemapheight) * map.tilesize, "no build");

        /*
		// Initiate corruption
		if (isServer() && this.exists("tile_updates"))
		{
			TileUpdates@ tile_updates;
			this.get("tile_updates", @tile_updates);

			// Too many issues with the circle
			// Clear any updates outside the intended area
			// u32 i = 0;
			// while (i < tile_updates.queue.length)
			// {
			// 	Vec2f tile_pos = tile_updates.queue[i];
			// 	if (outOfBounds(map, tile_pos, sector))
			// 	{
			// 		tile_updates.queue.removeAt(i);
			// 	}
			// 	else
			// 	{
			// 		i++;
			// 	}
			// }

			// Start from the center and bias towards it
			tile_updates.queue.push_back(map.getTileSpacePosition(this.getPosition()));
			tile_updates.steps = 0;
		}
        */
	}
	else if (cmd == this.getCommandID("liberate"))
	{
		// Set the state
		this.set_u8("state", State::liberated);
		this.server_setTeamNum(0);
        UpdateAnim(this);

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

        /*
		// Initiate corruption withdrawal
		if (isServer() && this.exists("tile_updates"))
		{
			Vec2f sector = this.get_Vec2f("sector");

			TileUpdates@ tile_updates;
			this.get("tile_updates", @tile_updates);

			// Start from the center and bias towards it
			tile_updates.queue.push_back(map.getTileSpacePosition(this.getPosition()));
			tile_updates.steps = 0;

			// Too many issues with the circle
			// // Want to center withdrawal on the portal
			// Vec2f pos = map.getTileSpacePosition(this.getPosition());
			// s32 x = Maths::Max((pos - Vec2f(sector.x,                     0)).getLength(),
			// 		Maths::Max((pos - Vec2f(sector.y - 1,                 0)).getLength(),
			// 		Maths::Max((pos - Vec2f(sector.x,     map.tilemapheight)).getLength(),
			// 		           (pos - Vec2f(sector.y - 1, map.tilemapheight)).getLength())));

			// // Use midpoint circle to create a circle so the corruption roughly withdraws back to the portal
			// s32 y = 0;
			// s32 error = 1 - x;

			// while (x >= y)
			// {
			// 	tile_updates.queue.push_back(pos + Vec2f(x, y));    // Octant 1
			// 	tile_updates.queue.push_back(pos + Vec2f(y, x));    // Octant 2
			// 	tile_updates.queue.push_back(pos + Vec2f(-y, x));   // Octant 3
			// 	tile_updates.queue.push_back(pos + Vec2f(-x, y));   // Octant 4
			// 	tile_updates.queue.push_back(pos + Vec2f(-x, -y));  // Octant 5
			// 	tile_updates.queue.push_back(pos + Vec2f(-y, -x));  // Octant 6
			// 	tile_updates.queue.push_back(pos + Vec2f(y, -x));   // Octant 7
			// 	tile_updates.queue.push_back(pos + Vec2f(x, -y));   // Octant 8

			// 	y += 1;
			// 	if (error < 0)
			// 	{
			// 		error += 2 * y + 1;
			// 	}
			// 	else
			// 	{
			// 		x -= 1;
			// 		error += 2 * (y - x) + 1;
			// 	}
			// }
		}
        */
	}
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

bool outOfBounds(CMap@ map, Vec2f tile_pos, Vec2f sector)
{
	return tile_pos.x < sector.x || tile_pos.x >= sector.y ||   // Out of bounds x
		   tile_pos.y < 0 || tile_pos.y >= map.tilemapheight;  // Out of bounds y
}

void Corrupt(CMap@ map, Vec2f world_pos, bool corrupt)
{
	TileType type = map.getTile(world_pos).type;
	if (corrupt && type < WORLD_OFFSET)
	{
		map.server_SetTile(world_pos, type + WORLD_OFFSET);
	}
	else if (!corrupt && type >= WORLD_OFFSET)
	{
		map.server_SetTile(world_pos, type - WORLD_OFFSET);
	}
}
