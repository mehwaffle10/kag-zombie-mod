
// Thanks to Guift for help with SMesh <3

#include "ZombieBlocksCommon.as"
#include "ZombiesMinimapCommon.as"
#include "TreeCommon.as"

funcdef u8 fxn(CBlob@ blob);

class MinimapIcon
{
    string file;
    string name;
    Vec2f size;
    fxn@ frame;

    MinimapIcon(string _file, string _name, Vec2f _size, fxn@ _frame)
    {
        file = _file;
        name = _name;
        size = _size;
        frame = _frame;
    }
};

SMesh@ minimap = SMesh(), exploration_overlay = SMesh();
SMaterial@ zombie_map = SMaterial(), exploration_material = SMaterial();
Vertex[] v_raw, v_raw_exploration;
u16[] v_i, v_i_exploration;
MinimapIcon[] minimap_icons;
bool minimap_initialized = false;

void Setup()
{
    CMap@ map = getMap();
    Driver@ driver = getDriver();
    CRules@ rules = getRules();

    if (map is null || driver is null)
    {
        return;
    }

    if (isServer())
    {
        rules.set_u32(ZOMBIE_MINIMAP_WIDTH, map.tilemapwidth);
        rules.Sync(ZOMBIE_MINIMAP_WIDTH, true);
    }

    // Reset exploration borders
    u32 tilemapwidth = rules.get_u32(ZOMBIE_MINIMAP_WIDTH);
    ZombieMinimapCore@ zombie_minimap_core = ZombieMinimapCore();
    u8[][] nonstatic_blocks(tilemapwidth, u8[](0)); 
    zombie_minimap_core.nonstatic_blocks = nonstatic_blocks;
    bool[] generated(tilemapwidth, false);
    zombie_minimap_core.generated = generated;
    bool[][] water(tilemapwidth, bool[](0)); 
    zombie_minimap_core.water = water;
    zombie_minimap_core.left = 1000000000;
    zombie_minimap_core.right = 0;
    rules.set(ZOMBIE_MINIMAP_CORE, @zombie_minimap_core);

    if (!isClient())
    {
        return;
    }
    
    // Delay setting up the minimap to allow the map size to sync
    minimap_initialized = false;
    if (Texture::exists(ZOMBIE_MINIMAP_TEXTURE))
    {
        Texture::destroy(ZOMBIE_MINIMAP_TEXTURE);
    }

    // Create exploration overlay texture
    if (!Texture::exists(ZOMBIE_MINIMAP_EXPLORATION_TEXTURE))
    {
        Texture::createFromFile(ZOMBIE_MINIMAP_EXPLORATION_TEXTURE, "pixel.png");
    }

    // Exploration material initial config
    exploration_material.AddTexture(ZOMBIE_MINIMAP_EXPLORATION_TEXTURE, 0);
    exploration_material.DisableAllFlags();
    exploration_material.SetFlag(SMaterial::COLOR_MASK, true);
    exploration_material.SetFlag(SMaterial::ZBUFFER, true);
    exploration_material.SetFlag(SMaterial::ZWRITE_ENABLE, true);
    exploration_material.SetMaterialType(SMaterial::TRANSPARENT_VERTEX_ALPHA); //this might need to be changed

    // Add indices for the mesh
    v_i.clear();
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

    // Add minimap icons, rendered in order
    minimap_icons.clear();
    // portals
    minimap_icons.push_back(MinimapIcon("ZombieMinimapIcons.png", "portal", Vec2f(8, 8), @getPortalFrame));
    // players
    minimap_icons.push_back(MinimapIcon("MinimapIcons.png", "builder", Vec2f(8, 8), @getPlayerFrame));
    minimap_icons.push_back(MinimapIcon("MinimapIcons.png", "knight", Vec2f(8, 8), @getPlayerFrame));
    minimap_icons.push_back(MinimapIcon("MinimapIcons.png", "archer", Vec2f(8, 8), @getPlayerFrame));
    // trees
    minimap_icons.push_back(MinimapIcon("MinimapIcons.png", "tree_bushy", Vec2f(8, 32), @getTreeFrame));
    minimap_icons.push_back(MinimapIcon("MinimapIcons.png", "tree_pine", Vec2f(8, 32), @getTreeFrame));
}

void onShowMenu(CRules@ this)
{
    if (isClient())
    {
        this.set_s32(ZOMBIE_MINIMAP_FULL_LEFT_X, -1);
        this.set_bool(ZOMBIE_MINIMAP_FULL, true);
    }
}

void OnCloseMenu(CRules@ this)
{
    if (isClient())
    {
        this.set_bool(ZOMBIE_MINIMAP_FULL, false);
    }
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
    if (blob !is null && blob.hasTag("player"))
    {
        blob.sendonlyvisible = false;
    }
}

void onInit(CRules@ this)
{
    this.addCommandID(ZOMBIE_MINIMAP_EXPLORE_SYNC_COMMAND);
    if (!GUI::isFontLoaded("snes"))
	{
		string snes = CFileMatcher("snes.png").getFirst();
		GUI::LoadFont("snes", snes, 22, true);
	}

    if (isClient())
    {
        int cb_id = Render::addScript(Render::layer_last, "ZombiesMinimap.as", "RenderMap", 0.0f);
    }
    Setup();
}

void onRestart(CRules@ this)
{
    Setup();
}

void RenderMap(int id)
{
    CRules@ rules = getRules();
	CMap@ map = getMap();
    CControls@ controls = getControls();
    Driver@ driver = getDriver();

    if (map is null || controls is null || driver is null)
    {
        return;
    }

    ZombieMinimapCore@ zombie_minimap_core;
    rules.get(ZOMBIE_MINIMAP_CORE, @zombie_minimap_core);
    
    if (!minimap_initialized && map.tilemapwidth > 0 && map.tilemapheight > 0)
    {
        // Generate minimap
        ImageData@ image_data = ImageData(map.tilemapwidth, map.tilemapheight);
        for (u16 x = 0; x < map.tilemapwidth; x++)
        {
            for(u16 y = 0; y < map.tilemapheight; y++)
            {
                image_data.put(x, y, getMapColor(rules, map, Vec2f(x, y) * map.tilesize));
            }
        }

        // Create minimap texture
        Texture::createFromData(ZOMBIE_MINIMAP_TEXTURE, image_data);

        // Minimap material initial config
        zombie_map.AddTexture(ZOMBIE_MINIMAP_TEXTURE, 0);
        zombie_map.DisableAllFlags();
        zombie_map.SetFlag(SMaterial::COLOR_MASK, true);
        zombie_map.SetFlag(SMaterial::ZBUFFER, true);
        zombie_map.SetFlag(SMaterial::ZWRITE_ENABLE, true);
        zombie_map.SetMaterialType(SMaterial::TRANSPARENT_VERTEX_ALPHA); //this might need to be changed

        minimap_initialized = true;
    }

    // Only render if holding the map key
    bool full_map = rules.get_bool(ZOMBIE_MINIMAP_FULL);
    if (map is null || controls is null || driver is null || !full_map && !controls.ActionKeyPressed(AK_MAP))
    {
        return;
    }

    // See if we're rendering the minimap or the full map. Also limit by exploration so that we don't know how big the map is initially
    u16 min_fog_width = EXPLORATION_WIDTH * 3;
    u16 map_width = Maths::Min(
        zombie_minimap_core.right + min_fog_width * 2 < zombie_minimap_core.left ? 0 :
        zombie_minimap_core.right - zombie_minimap_core.left + min_fog_width * 2,            // Limit to where we've explored, make sure it's positive
        Maths::Min(map.tilemapwidth,                                                         // Limit to size of map
        full_map ? (driver.getScreenWidth() - FULL_MAP_BORDER) / TILE_WIDTH : MINIMAP_WIDTH  // Otherwise pick between our minimap size or full map size
    ));

    // Setup
    Render::SetTransformScreenspace();
    s32 middle = driver.getScreenWidth() / 2;
    Vec2f upper_left = Vec2f(middle - map_width / 2 * TILE_WIDTH, 40), bottom_right = upper_left + Vec2f(map_width, map.tilemapheight) * TILE_WIDTH;

    // Get the left position on the tile map
    s32 full_map_left = rules.get_s32(ZOMBIE_MINIMAP_FULL_LEFT_X);
    s32 left_scroll_limit = zombie_minimap_core.left - min_fog_width, right_scroll_limit = zombie_minimap_core.right - map_width + min_fog_width;
    s32 map_left = Maths::Min(
        map.tilemapwidth - map_width,                                                       // Limit to right side of map
        Maths::Max(0,                                                                       // Limit to left side of map
        Maths::Min(right_scroll_limit,                                                      // Limit to how far we've explored right
        Maths::Max(left_scroll_limit,                                                       // Limit to how far we've explored left
        driver.getWorldPosFromScreenPos(Vec2f(middle, 0)).x / map.tilesize - map_width / 2  // Otherwise center on screen
    ))));
    if (full_map_left < 0)
    {
        full_map_left = map_left;
    }
    if (full_map)
    {
        map_left = full_map_left;

        // Check if we need to scroll
        Vec2f mouse_screen_pos = controls.getMouseScreenPos();
        if (mouse_screen_pos.y > upper_left.y && mouse_screen_pos.y < bottom_right.y)
        {
            // Scroll left
            if (mouse_screen_pos.x > upper_left.x && mouse_screen_pos.x < upper_left.x + SCROLL_WIDTH && map_left > left_scroll_limit)
            {
                // Can only scroll as far as explored or to edge of map
                map_left = Maths::Max(0, Maths::Max(left_scroll_limit, map_left - SCROLL_SPEED));
            }
            // Scroll right
            if (mouse_screen_pos.x < bottom_right.x && mouse_screen_pos.x > bottom_right.x - SCROLL_WIDTH && map_left < right_scroll_limit)
            {
                map_left = Maths::Min(map.tilemapwidth - map_width, Maths::Min(right_scroll_limit, map_left + SCROLL_SPEED));
            }
            rules.set_s32(ZOMBIE_MINIMAP_FULL_LEFT_X, map_left);
        }
    }    

    // Scan for water
    ImageData@ image_data = Texture::data(ZOMBIE_MINIMAP_TEXTURE);
    bool dirty = false;
    for (s32 x = 0; x < map_width; x++)
    {
        s32 map_x = map_left + x;
        u8[]@ nonstatic_blocks = @zombie_minimap_core.nonstatic_blocks[map_x];
        if (!zombie_minimap_core.generated[map_x])
        {
            // Generate the list of nonstatic blocks and save
            for (u8 y = 0; y < map.tilemapheight; y++)
            {
                TileType tile_type = map.getTile(Vec2f(map_x, y) * map.tilesize).type;
                if (!(isDirt(tile_type)       || 
                      isBedrock(tile_type)    || 
                      isStone(tile_type)      ||
                      isThickStone(tile_type) ||
                      isGold(tile_type)       ||
                      isEmpty(tile_type) && !map.isInWater(Vec2f(map_x, y) * map.tilesize))) // Air blocks not spawning in water can never be flooded in my mod
                {
                    nonstatic_blocks.push_back(y);
                    zombie_minimap_core.water[map_x].push_back(false);
                }
            }
            zombie_minimap_core.generated[map_x] = true;
        }

        // Scan for water spaces
        for (u8 i = 0; i < nonstatic_blocks.length; i++)
        {
            Vec2f tile_pos = Vec2f(map_x, nonstatic_blocks[i]);
            Vec2f world_pos = tile_pos * map.tilesize;
            bool water = zombie_minimap_core.water[tile_pos.x][i];

            // Mark that we've updated the color and update the texture
            if (water != map.isInWater(world_pos))
            {
                dirty = true;
                water = !water;
                image_data.put(tile_pos.x, tile_pos.y, water ? image_data.get(tile_pos.x, tile_pos.y).getInterpolated(COLOR_WATER, 0.5f) : getMapColor(rules, map, world_pos));
                zombie_minimap_core.water[tile_pos.x][i] = water;
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
    v_raw.push_back(Vertex(upper_left + Vec2f(map_width, 0)                 * TILE_WIDTH, 1000, Vec2f(f32(map_left + map_width) / map.tilemapwidth, 0), color));
    v_raw.push_back(Vertex(upper_left + Vec2f(map_width, map.tilemapheight) * TILE_WIDTH, 1000, Vec2f(f32(map_left + map_width) / map.tilemapwidth, 1), color));
    v_raw.push_back(Vertex(upper_left + Vec2f(0,         map.tilemapheight) * TILE_WIDTH, 1000, Vec2f(f32(map_left)             / map.tilemapwidth, 1), color));

    // Mesh config 
    minimap.SetMaterial(zombie_map);
    minimap.SetHardwareMapping(SMesh::STATIC);
    minimap.SetVertex(v_raw);
    minimap.SetIndices(v_i);
    minimap.BuildMesh();

    // Render mesh
    minimap.RenderMeshWithMaterial();

    // Draw blobs
    s32 world_left = map_left * map.tilesize;
    s32 world_right = (map_left + map_width) * map.tilesize;

    // Border vars
    Vec2f border_size = Vec2f(BORDER_WIDTH / 2, BORDER_WIDTH);  // Border should overlap a bit to hide icons popping into existence
    Vec2f border_upper_left = upper_left - border_size, border_bottom_right = bottom_right + border_size;

    for (u8 icon_index = 0; icon_index < minimap_icons.length; icon_index++)
    {
        MinimapIcon icon = minimap_icons[icon_index];
        u8 icon_offset = icon.size.x / 2 * TILE_WIDTH;
        CBlob@[] blobs;
        getBlobsByName(icon.name, blobs);
        for (u8 i = 0; i < blobs.length; i++)
        {
            // Make sure the blob exists
            CBlob@ blob = blobs[i];
            if (blob is null)
            {
                continue;
            }

            // Add sector names
            if (icon.name == "portal" && blob.exists("sector") && blob.exists(ZOMBIE_MINIMAP_SECTOR_NAME))
            {
                // Force the font for the UI
                GUI::SetFont("snes");
                Vec2f sector = blob.get_Vec2f("sector");
                string sector_name = blob.get_string(ZOMBIE_MINIMAP_SECTOR_NAME);
                Vec2f name_size;
                GUI::GetTextDimensions(sector_name, name_size);
                s32 sector_middle = upper_left.x + (sector.y - world_left / map.tilesize - (sector.y - sector.x) / 2) * TILE_WIDTH;
                s32 name_left = sector_middle - name_size.x / 2, name_right = name_left + name_size.x;
                
                // Check if we're anywhere on the minimap
                // Use border_upper_left but normal bottom_right since text renders from the left
                if (name_right > border_upper_left.x && name_left < bottom_right.x)
                {
                    if (name_left >= border_upper_left.x)
                    {
                        // Shorten from the right
                        while(name_right > bottom_right.x)
                        {
                            sector_name = sector_name.substr(0, sector_name.length - 1);
                            GUI::GetTextDimensions(sector_name, name_size);
                            name_right = name_left + name_size.x;
                        }
                    }
                    else
                    {
                        // Shorten from the left
                        while(name_left < border_upper_left.x)
                        {
                            sector_name = sector_name.substr(1, sector_name.length);
                            GUI::GetTextDimensions(sector_name, name_size);
                            name_left = name_right - name_size.x;
                        }
                    }

                    GUI::DrawShadowedText(
                        sector_name,
                        Vec2f(name_left, upper_left.y),
                        SColor(0xffffffff)
                    );
                }
            }

            // Only draw blobs that fit on the map
            Vec2f pos = blob.getPosition();
            if (pos.x < world_left || pos.x > world_right)
            {
                continue;
            }

            // Draw the icon
            f32 scale = 1.0f;
            GUI::DrawIcon(
                icon.file,
                icon.frame(blob),
                icon.size,
                upper_left + (pos - Vec2f(world_left + 1, 0)) / map.tilesize * TILE_WIDTH + Vec2f(blob.isFacingLeft() ? icon.size.x * 1.25f : -icon.size.x, -icon.size.y),
                scale * (blob.isFacingLeft() ? -1 : 1),
                scale,
                blob.getTeamNum(),
                SColor(0xffffffff)
            );
        }
    }

    // Overlay the exploration mesh
    v_raw_exploration.clear();
    v_i_exploration.clear();
    u8 fade_width = EXPLORATION_WIDTH / 2;
    s32 fade_gap = EXPLORATION_WIDTH - fade_width;

    // Left
    if (map_left + fade_gap < zombie_minimap_core.left)
    {
        s32 x_width = zombie_minimap_core.left - map_left - fade_gap;
        SColor color = COLOR_UNEXPLORED;
        s32 limit = Maths::Min(fade_width, x_width);

        for (u8 i = 0; i <= limit; i++)
        {
            color.setAlpha(255 / fade_width * i);
            RenderRectangle(
                v_raw_exploration,
                v_i_exploration,
                upper_left + Vec2f(i == fade_width ? 0 : x_width - i, 0) * TILE_WIDTH,
                Vec2f(i == fade_width ? x_width - i + 1 : 1, map.tilemapheight),
                Vec2f(0, 0),
                Vec2f(1, 1),
                color
            );
        }
    }

    // Right
    if (map_left + map_width - fade_gap > zombie_minimap_core.right)
    {
        s32 x_width = map_left + map_width - fade_gap - zombie_minimap_core.right;
        SColor color = COLOR_UNEXPLORED;
        s32 limit = Maths::Min(fade_width, x_width);

        for (u8 i = 0; i <= limit; i++)
        {
            color.setAlpha(255 / fade_width * i);
            RenderRectangle(
                v_raw_exploration,
                v_i_exploration,
                upper_left + Vec2f(map_width - x_width + i, 0) * TILE_WIDTH,
                Vec2f(i == fade_width ? x_width - i : 1, map.tilemapheight),
                Vec2f(0, 0),
                Vec2f(1, 1),
                color
            );
        }
    }

    // Mesh config 
    if (v_raw_exploration.length > 0)
    {
        exploration_overlay.SetMaterial(exploration_material);
        exploration_overlay.SetHardwareMapping(SMesh::STATIC);
        exploration_overlay.SetVertex(v_raw_exploration);
        exploration_overlay.SetIndices(v_i_exploration);
        exploration_overlay.BuildMesh();

        // Render mesh
        exploration_overlay.RenderMeshWithMaterial();
    }

    // Draw the border
    GUI::DrawFramedPane(border_upper_left,                                             Vec2f(upper_left.x + BORDER_WIDTH / 2, border_bottom_right.y));  // Left side
    GUI::DrawFramedPane(Vec2f(bottom_right.x - BORDER_WIDTH / 2, border_upper_left.y), border_bottom_right);                                            // Right Side
    GUI::DrawFramedPane(border_upper_left,                                             Vec2f(border_bottom_right.x, upper_left.y));                     // Top
    GUI::DrawFramedPane(Vec2f(border_upper_left.x, bottom_right.y),                    border_bottom_right);                                            // Bottom
}

u8 getPortalFrame(CBlob@ blob)
{
    return 0;
}

u8 getPlayerFrame(CBlob@ blob)
{
    return blob.getPlayer() is getLocalPlayer() ? 0 : 8;
}

// Adapted from BushyTreeLogic.as and PineTreeLogic.as
u8 getTreeFrame(CBlob@ blob)
{
    TreeVars vars;
    blob.get("TreeVars", vars);
    u8 frame;
	if (vars.grown_times < 5)
	{
		frame = 8;
	}
	else if (vars.grown_times < 10)
	{
		frame = 10;
	}
	else
	{
		frame = 12;
	}
    return frame + (blob.getName() == "tree_pine" ? 1 : 0);
}

void onTick(CRules@ this)
{
    // Explore near players
    CMap@ map = getMap();
    if (map is null)
    {
        return;
    }

    ZombieMinimapCore@ zombie_minimap_core;
    this.get(ZOMBIE_MINIMAP_CORE, @zombie_minimap_core);
    for (u8 i = 0; i < getPlayerCount(); i++)
    {
        CPlayer@ player = getPlayer(i);
        if (player is null)
        {
            continue;
        }

        CBlob@ blob = player.getBlob();
        if (blob is null)
        {
            continue;
        }

        // Explore horizontally
        s32 x = blob.getPosition().x / map.tilesize;
        if (x < zombie_minimap_core.left)
        {
            zombie_minimap_core.left = x;
        }
        if (x > zombie_minimap_core.right)
        {
            zombie_minimap_core.right = x;
        }
    }
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
    if (!isServer())
    {
        return;
    }

    ZombieMinimapCore@ zombie_minimap_core;
    this.get(ZOMBIE_MINIMAP_CORE, @zombie_minimap_core);
    if (zombie_minimap_core is null)
    {
        return;
    }

    CBitStream params;
    params.write_s32(zombie_minimap_core.left);
    params.write_s32(zombie_minimap_core.right);
    this.SendCommand(this.getCommandID(ZOMBIE_MINIMAP_EXPLORE_SYNC_COMMAND), params, player);
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID(ZOMBIE_MINIMAP_EXPLORE_SYNC_COMMAND))
    {
        s32 left, right;
        if (!params.saferead_s32(left) || !params.saferead_s32(right))
        {
            return;
        }

        ZombieMinimapCore@ zombie_minimap_core;
        this.get(ZOMBIE_MINIMAP_CORE, @zombie_minimap_core);
        if (zombie_minimap_core is null)
        {
            return;
        }
        zombie_minimap_core.left = left;
        zombie_minimap_core.right = right;
    }
}

void RenderRectangle(Vertex[]@ vertices, u16[]@ indices, Vec2f upper_left, Vec2f size, Vec2f texture_offset, Vec2f texture_size, SColor color)
{
    // Add vertices
    vertices.push_back(Vertex(upper_left,                                 1000, texture_offset,                            color));
    vertices.push_back(Vertex(upper_left + Vec2f(size.x, 0) * TILE_WIDTH, 1000, texture_offset + Vec2f(texture_size.x, 0), color));
    vertices.push_back(Vertex(upper_left + size             * TILE_WIDTH, 1000, texture_offset + texture_size,             color));
    vertices.push_back(Vertex(upper_left + Vec2f(0, size.y) * TILE_WIDTH, 1000, texture_offset + Vec2f(0, texture_size.y), color));

    // Add indices
    u32 vertices_length = vertices.length;
    indices.push_back(vertices_length - 4);
    indices.push_back(vertices_length - 3);
    indices.push_back(vertices_length - 2);
    indices.push_back(vertices_length - 4);
    indices.push_back(vertices_length - 2);
    indices.push_back(vertices_length - 1);
}