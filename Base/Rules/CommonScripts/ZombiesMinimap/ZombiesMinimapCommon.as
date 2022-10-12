
const string ZOMBIE_MINIMAP_TEXTURE = "zombie_minimap";
const string ZOMBIE_MINIMAP_UPDATE_COMMAND = "zombie_minimap_update";
const string ZOMBIE_MINIMAP_NONSTATIC_PREFIX = "zombie_minimap_nonstatic";
const string ZOMBIE_MINIMAP_WATER_PREFIX = "zombie_minimap_water";

const u8 tile_width = 2;  // pixels
const u8 border_width = 4;  // pixels
const u16 map_width = 200;  // number of tiles

// Minimap colors from MinimapHook.as
SColor color_sky             = SColor(0xffA5BDC8);
SColor color_dirt            = SColor(0xff844715);
SColor color_dirt_backwall   = SColor(0xff3B1406);
SColor color_stone           = SColor(0xff8B6849);
SColor color_thickstone      = SColor(0xff42484B);
SColor color_gold            = SColor(0xffFEA53D);
SColor color_bedrock         = SColor(0xff2D342D);
SColor color_wood            = SColor(0xffC48715);
SColor color_wood_backwall   = SColor(0xff552A11);
SColor color_castle          = SColor(0xff637160);
SColor color_castle_backwall = SColor(0xff313412);
SColor color_water           = SColor(0xff2cafde);
SColor color_fire            = SColor(0xffd5543f);
SColor color_grass           = SColor(0xff649b0d);
SColor color_moss            = SColor(0xff315212);
SColor color_unexplored      = SColor(0xffedcca6);

SColor getMapColor(CMap@ map, Vec2f world_pos)
{
    return getMapColor(map, world_pos, map.getTile(world_pos).type);
}

SColor getMapColor(CMap@ map, Vec2f world_pos, TileType tile_type)
{
    SColor color;
    if (map.isTileGround(tile_type))  
    {
        color = color_dirt;
    } 
    else if (map.isTileBedrock(tile_type))
    {
        color = color_bedrock;
    }
    else if (map.isTileStone(tile_type))
    {
        color = color_stone;
    }
    else if (map.isTileThickStone(tile_type))
    {
        color = color_thickstone;
    }
    else if (map.isTileGold(tile_type))
    {
        color = color_gold;
    }
    else if (map.isTileWood(tile_type)) 
    { 
        color = color_wood;
    } 
    else if (map.isTileCastle(tile_type))      
    { 
        // Check for Mossy Stone Backwall
        color = tile_type == CMap::tile_castle_moss ? color_castle.getInterpolated(color_moss, 0.5f) : color_castle;
    } 
    else {
        if (tile_type == CMap::tile_ground_back)  // Dirt Backwall
        {
            color = color_dirt_backwall;
        }
        else if (tile_type == CMap::tile_wood_back ||  // Wood Backwall
                tile_type == 207)                     // Damaged Wood Backwall
        {
            color = color_wood_backwall;
        }
        else if (tile_type == CMap::tile_castle_back ||  // Stone Backwall
                tile_type >= 76 && tile_type <= 79)     // Damaged Stone Backwall
        {
            color = color_castle_backwall;
        }
        else if (tile_type == CMap::tile_castle_back_moss)  // Mossy Stone Backwall
        {
            color = color_castle_backwall.getInterpolated(color_moss, 0.5f);
        }
        else if (map.isTileGrass(tile_type))
        {
            color = color_grass;
        }
        else 
        {
            color = color_sky;
        } 
    }
    return color;
}

// // TODO(hobey): maybe check if there's a door/platform on this backwall and make a custom color for them?
//         // Tint the map based on Fire/Water State
//         if (map.isInWater(world_pos))
//         {
//             color = color.getInterpolated(color_water, 0.5f);
//         }
//         else if (map.isInFire(world_pos))
//         {
//             color = color.getInterpolated(color_fire, 0.5f);
//         }