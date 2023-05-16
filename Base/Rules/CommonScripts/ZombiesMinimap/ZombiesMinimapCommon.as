
#include "ZombieBlocksCommon.as"

const string ZOMBIE_MINIMAP_TEXTURE = "zombie_minimap";
const string ZOMBIE_MINIMAP_EXPLORATION_TEXTURE = "pixel";
const string ZOMBIE_MINIMAP_UPDATE_COMMAND = "zombie_minimap_update";
const string ZOMBIE_MINIMAP_NONSTATIC_PREFIX = "zombie_minimap_nonstatic";
const string ZOMBIE_MINIMAP_WATER_PREFIX = "zombie_minimap_water";
const string ZOMBIE_MINIMAP_EXPLORED = "zombie_minimap_explored";
const string ZOMBIE_MINIMAP_FULL = "zombie_minimap_render_full_map";
const string ZOMBIE_MINIMAP_FULL_LEFT_X = "zombie_minimap_full_map_left_x";
const string ZOMBIE_MAP_WIDTH = "zombies_map_width";
const string ZOMBIE_MAP_HEIGHT = "zombies_map_height";
const string ZOMBIE_MINIMAP_SECTOR_NAME = "zombies_minimap_sector_name";

const u8 tile_width = 2;  // pixels
const u8 border_width = 14;  // pixels
const u16 minimap_width = 200;  // number of tiles
const u8 exploration_width = 16;  // number of tiles
const u16 full_map_border = 500;  // pixels
const u16 scroll_width = 300;  // pixels
const u8 scroll_speed = 4;  // number of tiles


// Minimap colors from MinimapHook.as
f32 interpolation = 0.85f;
SColor color_fade            = SColor(0xff2a0b47);
SColor color_corruption      = SColor(0xff2a0b47);
SColor color_sky             = SColor(0xffa5bdc8).getInterpolated(color_fade, interpolation);
SColor color_dirt            = SColor(0xff844715).getInterpolated(color_fade, interpolation);
SColor color_dirt_backwall   = SColor(0xff3b1406).getInterpolated(color_fade, interpolation);
SColor color_stone           = SColor(0xff8b6849).getInterpolated(color_fade, interpolation);
SColor color_thickstone      = SColor(0xff42484b).getInterpolated(color_fade, interpolation);
SColor color_gold            = SColor(0xfffea53d).getInterpolated(color_fade, interpolation);
SColor color_bedrock         = SColor(0xff2d342d).getInterpolated(color_fade, interpolation);
SColor color_wood            = SColor(0xffc48715).getInterpolated(color_fade, interpolation);
SColor color_wood_backwall   = SColor(0xff552a11).getInterpolated(color_fade, interpolation);
SColor color_castle          = SColor(0xff637160).getInterpolated(color_fade, interpolation);
SColor color_castle_backwall = SColor(0xff313412).getInterpolated(color_fade, interpolation);
SColor color_water           = SColor(0xff2cafde).getInterpolated(color_fade, interpolation);
SColor color_fire            = SColor(0xffd5543f).getInterpolated(color_fade, interpolation);
SColor color_grass           = SColor(0xff649b0d).getInterpolated(color_fade, interpolation);
SColor color_moss            = SColor(0xff315212).getInterpolated(color_fade, interpolation);
SColor color_unexplored      = SColor(0xffedcca6);
SColor color_team_blue       = SColor(0xff1d85ab);
SColor color_team_purple     = SColor(0xff9e3abb);

SColor getMapColor(CRules@ rules, CMap@ map, Vec2f world_pos)
{
    return getMapColor(rules, map, world_pos, map.getTile(world_pos).type);
}

SColor getMapColor(CRules@ rules, CMap@ map, Vec2f world_pos, TileType tile_type)
{
    SColor color;
    bool corrupt = false;
    if (tile_type >= WORLD_OFFSET)
    {
        corrupt = true;
    }

    if (isDirt(tile_type))
    {
        color = color_dirt;
    } 
    else if (isBedrock(tile_type))
    {
        color = color_bedrock;
    }
    else if (isStone(tile_type))
    {
        color = color_stone;
    }
    else if (isThickStone(tile_type))
    {
        color = color_thickstone;
    }
    else if (isGold(tile_type))
    {
        color = color_gold;
    }
    else if (isWood(tile_type)) 
    { 
        color = color_wood;
    } 
    else if (isCastle(tile_type))      
    { 
        // Check for Mossy Stone Backwall
        color = isMossyCastle(tile_type) ? color_castle.getInterpolated(color_moss, 0.5f) : color_castle;
    } 
    else
    {
        if (isDirtBackwall(tile_type))  // Dirt Backwall
        {
            color = color_dirt_backwall;
        }
        else if (isWoodBackwall(tile_type))
        {
            color = color_wood_backwall;
        }
        else if (isCastleBackwall(tile_type))
        {
            color = isMossyCastleBackwall(tile_type) ? color_castle_backwall.getInterpolated(color_moss, 0.5f) : color_castle_backwall;
        }
        else if (isGrass(tile_type))
        {
            color = color_grass;
        }
        else 
        {
            color = color_sky;
        } 
    }

    // Add corruption
    if (corrupt)
    {
        color = color.getInterpolated(color_corruption, 0.5f);
    }

    // Add sector borders
    string border_id = "sector_border_" + Maths::Round(world_pos.x / map.tilesize);
    if (rules.exists(border_id))
    {
        CBlob@ border = getBlobByNetworkID(rules.get_netid(border_id));
        if (border !is null)
        {
            color = color.getInterpolated(border.getTeamNum() == 0 ? color_team_blue : color_team_purple, 0.5f);
        }
    }
    return color;
}

void setSectorBorderColor(CBlob@ portal)
{
    if (portal is null)
    {
        return;
    }

	CRules@ rules = getRules();
	CMap@ map = getMap();
	ImageData@ image_data = Texture::data(ZOMBIE_MINIMAP_TEXTURE);
	Vec2f sector = portal.get_Vec2f("sector");

	s32[] borders = {sector.x, sector.y - 1};
	for (u8 i = 0; i < borders.length(); i++)
	{
		s32 x = Maths::Round(borders[i]);
		string border_id = "sector_border_" + x;
		if (!rules.exists(border_id))
		{
			continue;
		}
		
		CBlob@ border = getBlobByNetworkID(rules.get_netid(border_id));
		if (border is null)
		{
			continue;
		}

        // Flag that the minimap has a color on it
        if (isClient())
        {
            portal.set_bool("minimap_initialized", true);
        }

		// Update the color of the sprite
		border.server_setTeamNum(portal.getTeamNum());

		// Update the zombie minimap border colors for clients
		if (isClient() && map !is null)
		{
			for (u8 y = 0; y < map.tilemapheight; y++)
			{
				image_data.put(x, y, getMapColor(rules, map, Vec2f(x, y) * map.tilesize));
			}
		}
	}
	if (isClient())
	{
		Texture::update(ZOMBIE_MINIMAP_TEXTURE, image_data);
	}
}
