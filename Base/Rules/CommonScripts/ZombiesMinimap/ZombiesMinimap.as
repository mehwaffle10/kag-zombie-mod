
// Thanks to Guift for help with SMesh <3

#include "ZombiesMinimapCommon.as"

SMesh@ minimap = SMesh();
SMaterial@ zombie_map = SMaterial();
Vertex[] v_raw;
u16[] v_i;

void Setup()
{
    CMap@ map = getMap();
    Driver@ driver = getDriver();

    if (map is null || driver is null)
    {
        return;
    }

	// Create minimap texture
    ImageData@ image_data = ImageData(map.tilemapwidth, map.tilemapheight);
    for (u16 x = 0; x < map.tilemapwidth; x++)
    {
        for(u16 y = 0; y < map.tilemapheight; y++)
        {
            image_data.put(x, y, getMapColor(map, Vec2f(x, y) * map.tilesize));
        }
    }
    if (Texture::exists(ZOMBIE_MINIMAP_TEXTURE))
	{
        Texture::destroy(ZOMBIE_MINIMAP_TEXTURE);
    }
    Texture::createFromData(ZOMBIE_MINIMAP_TEXTURE, image_data);

    // Material initial config
    zombie_map.AddTexture(ZOMBIE_MINIMAP_TEXTURE, 0);
    zombie_map.DisableAllFlags();
    zombie_map.SetFlag(SMaterial::COLOR_MASK, true);
    zombie_map.SetFlag(SMaterial::ZBUFFER, true);
    zombie_map.SetFlag(SMaterial::ZWRITE_ENABLE, true);
    zombie_map.SetMaterialType(SMaterial::TRANSPARENT_VERTEX_ALPHA); //this might need to be changed

    // Add indices for the mesh
    v_i.push_back(0);
    v_i.push_back(1);
    v_i.push_back(2);
    v_i.push_back(0);
    v_i.push_back(2);
    v_i.push_back(3);

    // Add script for minimap updates
	if (!map.hasScript("ZombiesMinimapMapUpdates"))
	{
		map.AddScript("ZombiesMinimapMapUpdates");
	}
}

void onInit(CRules@ this)
{
    this.addCommandID(ZOMBIE_MINIMAP_UPDATE_COMMAND);
    if (isClient())
    {
        int cb_id = Render::addScript(Render::layer_posthud, "ZombiesMinimap.as", "RenderMinimap", 0.0f);
        Setup();
    }
}

void onRestart(CRules@ this)
{
    if (isClient())
    {
        Setup();
    }
}

void RenderMinimap(int id)
{
	CMap@ map = getMap();
    CControls@ controls = getControls();
    Driver@ driver = getDriver();
    
    // Only render if holding the map key
    if (map is null || controls is null || driver is null || !controls.ActionKeyPressed(AK_MAP))
    {
        return;
    }

    // Draw the border and background
    s32 middle = driver.getScreenWidth() / 2;
    Vec2f upper_left = Vec2f(middle - map_width / 2 * tile_width, 40);
    Vec2f border_offset = Vec2f(border_width, border_width);
    Render::SetTransformScreenspace();
    GUI::DrawWindow(upper_left - border_offset, upper_left + Vec2f(map_width, map.tilemapheight) * tile_width + border_offset);
    // GUI::DrawRectangle(upper_left, upper_left + Vec2f(map_width, map.tilemapheight) * tile_width, color_dirt);

    // Get the left position on the tile map
    s32 map_left = Maths::Min(map.tilemapwidth - map_width, Maths::Max(0, driver.getWorldPosFromScreenPos(Vec2f(middle, 0)).x / map.tilesize - map_width / 2));

    // Scan for water
    ImageData@ image_data = Texture::data(ZOMBIE_MINIMAP_TEXTURE);
    bool dirty = false;
    for (s32 x = 0; x < map_width; x++)
    {
        s32 map_x = map_left + x;
        string x_prefix = ZOMBIE_MINIMAP_NONSTATIC_PREFIX + "_" + map_x;
        string x_length = x_prefix + "_l";

        u8[] y_values;
        if (map.exists(x_length))
        {
            // Load the list of nonstatic blocks
            for (u8 i = 0; i < map.get_u8(x_length); i++)
            {
                y_values.push_back(map.get_u8(x_prefix + "_" + i));
            }
        }
        else
        {
            // Generate the list of nonstatic blocks and save
            for (u8 y = 0; y < map.tilemapheight; y++)
            {
                TileType tile_type = map.getTile(Vec2f(map_x, y) * map.tilesize).type;
                if (!(map.isTileGround(tile_type)     || 
                      map.isTileBedrock(tile_type)    || 
                      map.isTileStone(tile_type)      ||
                      map.isTileThickStone(tile_type) ||
                      map.isTileGold(tile_type)       ||
                      tile_type == CMap::tile_empty && !map.isInWater(Vec2f(map_x, y) * map.tilesize))) // Air blocks not spawning in water can never be flooded in my mod
                {
                    y_values.push_back(y);
                }
            }

            // Save the nonstatic list
            for (u8 i = 0; i < y_values.length(); i++)
            {
                map.set_u8(x_prefix + "_" + i, y_values[i]);
            }
            map.set_u8(x_length, y_values.length());
        }

        // Scan for water spaces
        for (u8 i = 0; i < y_values.length(); i++)
        {
            Vec2f tile_pos = Vec2f(map_x, y_values[i]);
            Vec2f world_pos = tile_pos * map.tilesize;
            string water_bool = ZOMBIE_MINIMAP_WATER_PREFIX + tile_pos;
            bool water = map.get_bool(water_bool);

            // Mark that we've updated the color and update the texture
            if (water != map.isInWater(world_pos))
            {
                dirty = true;
                water = !water;
                image_data.put(tile_pos.x, tile_pos.y, water ? image_data.get(tile_pos.x, tile_pos.y).getInterpolated(color_water, 0.5f) : getMapColor(map, world_pos));
                map.set_bool(water_bool, water);
            }
        }
    }

    // Update the minimap if any changes were made
    if (dirty)
    {
        Texture::update(ZOMBIE_MINIMAP_TEXTURE, image_data);
    }

    // Add vertices
    SColor color = SColor(0xffffffff);
    v_raw.clear();
    v_raw.push_back(Vertex(upper_left,                                                    1000, Vec2f(f32(map_left)             / map.tilemapwidth, 0), color));
    v_raw.push_back(Vertex(upper_left + Vec2f(map_width, 0)                 * tile_width, 1000, Vec2f(f32(map_left + map_width) / map.tilemapwidth, 0), color));
    v_raw.push_back(Vertex(upper_left + Vec2f(map_width, map.tilemapheight) * tile_width, 1000, Vec2f(f32(map_left + map_width) / map.tilemapwidth, 1), color));
    v_raw.push_back(Vertex(upper_left + Vec2f(0,         map.tilemapheight) * tile_width, 1000, Vec2f(f32(map_left)             / map.tilemapwidth, 1), color));

    // Mesh config 
    minimap.SetMaterial(zombie_map);
    minimap.SetHardwareMapping(SMesh::STATIC);
    minimap.SetVertex(v_raw);
    minimap.SetIndices(v_i); 
    minimap.BuildMesh();

    // Render mesh
    minimap.RenderMeshWithMaterial();    
}
