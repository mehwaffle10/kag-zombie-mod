
// Thanks to Guift for help with SMesh <3

const u8 tile_width = 2;  // pixels
const u8 border_width = 4;  // pixels
const u16 map_width = 120;  // number of tiles

// Minimap colors from MinimapHook.as
SColor color_sky = SColor(0xffA5BDC8);
SColor color_dirt = SColor(0xff844715);
SColor color_dirt_backwall = SColor(0xff3B1406);
SColor color_stone = SColor(0xff8B6849);
SColor color_thickstone = SColor(0xff42484B);
SColor color_gold = SColor(0xffFEA53D);
SColor color_bedrock = SColor(0xff2D342D);
SColor color_wood = SColor(0xffC48715);
SColor color_wood_backwall = SColor(0xff552A11);
SColor color_castle = SColor(0xff637160);
SColor color_castle_backwall = SColor(0xff313412);
SColor color_water = SColor(0xff2cafde);
SColor color_fire = SColor(0xffd5543f);
SColor color_moss = SColor(0xff315212);

SMesh@ minimap = SMesh();
SMaterial@ pixel = SMaterial();

Vertex[] v_raw;
u16[] v_i;

void Setup()
{
	// Ensure that we don't duplicate a texture
	if (!Texture::exists("pixel"))
	{
		Texture::createFromFile("pixel", "pixel.png");
    }

    // Material initial config
    pixel.AddTexture("pixel", 0);
    pixel.DisableAllFlags();
    pixel.SetFlag(SMaterial::COLOR_MASK, true);
    pixel.SetFlag(SMaterial::ZBUFFER, true);
    pixel.SetFlag(SMaterial::ZWRITE_ENABLE, true);
    pixel.SetMaterialType(SMaterial::TRANSPARENT_VERTEX_ALPHA); //this might need to be changed

    // Mesh initial config 
    minimap.SetMaterial(pixel);
    minimap.SetHardwareMapping(SMesh::STATIC);
}

void onInit(CRules@ this)
{
    if (isClient())
    {
        int cb_id = Render::addScript(Render::layer_posthud, "ZombiesMap.as", "RenderMinimap", 0.0f);
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
    
    if (map is null || controls is null || driver is null)
    {
        return;
    }

    // Draw map
    // if (controls.ActionKeyPressed(AK_MAP))
    // {
    // Draw the border and background. Default background is dirt for optimization
    s32 middle = driver.getScreenWidth() / 2;
    Vec2f upper_left = Vec2f(middle - map_width / 2 * tile_width, 40);
    Vec2f border_offset = Vec2f(border_width, border_width);
    Render::SetTransformScreenspace();
    GUI::DrawWindow(upper_left - border_offset, upper_left + Vec2f(map_width, map.tilemapheight) * tile_width + border_offset);
    GUI::DrawRectangle(upper_left, upper_left + Vec2f(map_width, map.tilemapheight) * tile_width, color_dirt);

    // Get the left position on the tile map
    const f32 tile_size = map.tilesize;
    const f32 tile_map_width = map.tilemapwidth;
    const f32 tile_map_height = map.tilemapheight;
    s32 map_left = Maths::Min(tile_map_width - map_width, Maths::Max(0, driver.getWorldPosFromScreenPos(Vec2f(middle, 0)).x / tile_size - map_width / 2));

    // Draw map
    for (u16 x = 0; x < map_width; x++)
    {
        for(u16 y = 0; y < tile_map_height; y++)
        {
            Vec2f world_pos = Vec2f(map_left + x, y) * tile_size;
            Tile tile = map.getTile(world_pos);
            SColor color;

            if (map.isTileGold(tile.type))  
            { 
                color = color_gold;
            } 
            else if (map.isTileGround(tile.type))
            {
                continue;
                // color = color_dirt;
            }
            else if (map.isTileThickStone(tile.type))
            {
                color = color_thickstone;
            }
            else if (map.isTileStone(tile.type))
            {
                color = color_stone;
            }
            else if (map.isTileBedrock(tile.type))
            {
                color = color_bedrock;
            }
            else if (map.isTileWood(tile.type)) 
            { 
                color = color_wood;
            } 
            else if (map.isTileCastle(tile.type))      
            { 
                color = color_castle;
                if (tile.type == CMap::tile_castle_moss)  // Mossy Stone Backwall
                {
                    color = color.getInterpolated(color_moss, 0.5f);
                }
            } 
            else if (map.isTileBackgroundNonEmpty(tile) && !map.isTileGrass(tile.type)) {
                
                if (tile.type == CMap::tile_ground_back)  // Dirt Backwall
                {
                    color = color_dirt_backwall;
                }
                else if (tile.type == CMap::tile_wood_back ||  // Wood Backwall
                         tile.type == 207)                     // Damaged Wood Backwall
                {
                    color = color_wood_backwall;
                }
                else if (tile.type == CMap::tile_castle_back ||  // Stone Backwall
                         tile.type >= 76 && tile.type <= 79)     // Damaged Stone Backwall
                {
                    color = color_castle_backwall;
                }
                else if (tile.type == CMap::tile_castle_back_moss)  // Mossy Stone Backwall
                {
                    color = color_castle_backwall.getInterpolated(color_moss, 0.5f);
                }

                // TODO(hobey): maybe check if there's a door/platform on this backwall and make a custom color for them?
                // Tint the map based on Fire/Water State
                if (map.isInWater(world_pos))
                {
                    color = color.getInterpolated(color_water, 0.5f);
                }
                else if (map.isInFire(world_pos))
                {
                    color = color.getInterpolated(color_fire, 0.5f);
                } 
            } 
            else 
            {
                color = color_sky;
            }

            DrawPixel(upper_left + Vec2f(x, y) * tile_width, color);
        }
    }

    // Render mesh
    minimap.SetVertex(v_raw);
    minimap.SetIndices(v_i); 
    minimap.BuildMesh();
    minimap.SetDirty(SMesh::VERTEX_INDEX); // when you set it to dirty, you might have to clear the arrays i think v_raw.clear v_i.clear, or just remove that line maybe
    v_raw.clear();
    v_i.clear();
    minimap.RenderMeshWithMaterial();
    // }    
}

void DrawPixel(Vec2f pos, SColor color)
{
    // Update vertices
    Vec2f zero = Vec2f();
    v_raw.push_back(Vertex(pos,                                 1000, zero, color));
    v_raw.push_back(Vertex(pos + Vec2f(tile_width, 0),          1000, zero, color));
    v_raw.push_back(Vertex(pos + Vec2f(tile_width, tile_width), 1000, zero, color));
    v_raw.push_back(Vertex(pos + Vec2f(0, tile_width),          1000, zero, color));

    // Update indices
    u32 length = v_raw.length();

    v_i.push_back(length - 4);  // 0
    v_i.push_back(length - 3);  // 1
    v_i.push_back(length - 2);  // 2

    v_i.push_back(length - 4);  // 0
    v_i.push_back(length - 2);  // 2
    v_i.push_back(length - 1);  // 3
}