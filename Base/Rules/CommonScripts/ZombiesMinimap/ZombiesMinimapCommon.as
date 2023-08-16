
#include "ZombieBlocksCommon.as"

class ZombieMinimapCore
{
    u8[][] nonstatic_blocks;
    bool[] generated;
    bool[][] water;
    s32 left;
    s32 right;
}

const string ZOMBIE_MINIMAP_CORE = "zombie_minimap_core";
const string ZOMBIE_MINIMAP_TEXTURE = "zombie_minimap";
const string ZOMBIE_MINIMAP_EXPLORATION_TEXTURE = "pixel";
const string ZOMBIE_MINIMAP_UPDATE_COMMAND = "zombie_minimap_update";
const string ZOMBIE_MINIMAP_FULL = "zombie_minimap_render_full_map";
const string ZOMBIE_MINIMAP_FULL_LEFT_X = "zombie_minimap_full_map_left_x";
const string ZOMBIE_MAP_WIDTH = "zombies_map_width";
const string ZOMBIE_MAP_HEIGHT = "zombies_map_height";
const string ZOMBIE_MINIMAP_SECTOR_NAME = "zombies_minimap_sector_name";
const string ZOMBIE_MINIMAP_WIDTH = "zombies_minimap_map_width";
const string ZOMBIE_MINIMAP_EXPLORE_SYNC_COMMAND = "zombies_minimap_explore_sync";

const u8 TILE_WIDTH = 2;          // pixels
const u8 BORDER_WIDTH = 14;       // pixels
const u16 MINIMAP_WIDTH = 200;    // number of tiles
const u8 EXPLORATION_WIDTH = 16;  // number of tiles
const u16 FULL_MAP_BORDER = 500;  // pixels
const u16 SCROLL_WIDTH = 300;     // pixels
const u8 SCROLL_SPEED = 4;        // number of tiles


// Minimap colors from MinimapHook.as
const f32 INTERPOLATION = 0.85f;
const SColor COLOR_FADE            = SColor(0xff2a0b47);
const SColor COLOR_CORRUPTION      = SColor(0xff2a0b47);
const SColor COLOR_SKY             = SColor(0xffa5bdc8).getInterpolated(COLOR_FADE, INTERPOLATION);
const SColor COLOR_DIRT            = SColor(0xff844715).getInterpolated(COLOR_FADE, INTERPOLATION);
const SColor COLOR_DIRT_BACKWALL   = SColor(0xff3b1406).getInterpolated(COLOR_FADE, INTERPOLATION);
const SColor COLOR_STONE           = SColor(0xff8b6849).getInterpolated(COLOR_FADE, INTERPOLATION);
const SColor COLOR_THICKSTONE      = SColor(0xff42484b).getInterpolated(COLOR_FADE, INTERPOLATION);
const SColor COLOR_GOLD            = SColor(0xfffea53d).getInterpolated(COLOR_FADE, INTERPOLATION);
const SColor COLOR_BEDROCK         = SColor(0xff2d342d).getInterpolated(COLOR_FADE, INTERPOLATION);
const SColor COLOR_WOOD            = SColor(0xffc48715).getInterpolated(COLOR_FADE, INTERPOLATION);
const SColor COLOR_WOOD_BACKWALL   = SColor(0xff552a11).getInterpolated(COLOR_FADE, INTERPOLATION);
const SColor COLOR_CASTLE          = SColor(0xff637160).getInterpolated(COLOR_FADE, INTERPOLATION);
const SColor COLOR_CASTLE_BACKWALL = SColor(0xff313412).getInterpolated(COLOR_FADE, INTERPOLATION);
const SColor COLOR_WATER           = SColor(0xff2cafde).getInterpolated(COLOR_FADE, INTERPOLATION);
const SColor COLOR_FIRE            = SColor(0xffd5543f).getInterpolated(COLOR_FADE, INTERPOLATION);
const SColor COLOR_GRASS           = SColor(0xff649b0d).getInterpolated(COLOR_FADE, INTERPOLATION);
const SColor COLOR_MOSS            = SColor(0xff315212).getInterpolated(COLOR_FADE, INTERPOLATION);
const SColor COLOR_UNEXPLORED      = SColor(0xffedcca6);
const SColor COLOR_TEAM_BLUE       = SColor(0xff1d85ab);
const SColor COLOR_TEAM_PURPLE     = SColor(0xff9e3abb);

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
        color = COLOR_DIRT;
    } 
    else if (isBedrock(tile_type))
    {
        color = COLOR_BEDROCK;
    }
    else if (isStone(tile_type))
    {
        color = COLOR_STONE;
    }
    else if (isThickStone(tile_type))
    {
        color = COLOR_THICKSTONE;
    }
    else if (isGold(tile_type))
    {
        color = COLOR_GOLD;
    }
    else if (isWood(tile_type)) 
    { 
        color = COLOR_WOOD;
    } 
    else if (isCastle(tile_type))      
    { 
        // Check for Mossy Stone Backwall
        color = isMossyCastle(tile_type) ? COLOR_CASTLE.getInterpolated(COLOR_MOSS, 0.5f) : COLOR_CASTLE;
    } 
    else
    {
        if (isDirtBackwall(tile_type))  // Dirt Backwall
        {
            color = COLOR_DIRT_BACKWALL;
        }
        else if (isWoodBackwall(tile_type))
        {
            color = COLOR_WOOD_BACKWALL;
        }
        else if (isCastleBackwall(tile_type))
        {
            color = isMossyCastleBackwall(tile_type) ? COLOR_CASTLE_BACKWALL.getInterpolated(COLOR_MOSS, 0.5f) : COLOR_CASTLE_BACKWALL;
        }
        else if (isGrass(tile_type))
        {
            color = COLOR_GRASS;
        }
        else 
        {
            color = COLOR_SKY;
        } 
    }

    // Add corruption
    if (corrupt)
    {
        color = color.getInterpolated(COLOR_CORRUPTION, 0.5f);
    }

    // Add sector borders
    string border_id = "sector_border_" + Maths::Round(world_pos.x / map.tilesize);
    if (rules.exists(border_id))
    {
        CBlob@ border = getBlobByNetworkID(rules.get_netid(border_id));
        if (border !is null)
        {
            color = color.getInterpolated(border.getTeamNum() == 0 ? COLOR_TEAM_BLUE : COLOR_TEAM_PURPLE, 0.5f);
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
	for (u8 i = 0; i < borders.length; i++)
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
