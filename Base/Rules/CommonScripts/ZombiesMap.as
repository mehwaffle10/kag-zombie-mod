
// Thanks to Guift for help with SMesh <3

const u8 tile_width = 2;
const u8 border_width = 4;
const u16 map_width = 200;

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

SMesh@ minimap = SMesh();
SMaterial@ pixel = SMaterial();

u16[] v_i;
Vertex[] v_raw;

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
    pixel.SetMaterialType(SMaterial::TRANSPARENT_VERTEX_ALPHA);

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
    // GUI::DrawWindow(upper_left - border_offset, upper_left + Vec2f(map_width, map.tilemapheight) * tile_width + border_offset);
    // GUI::DrawRectangle(upper_left, upper_left + Vec2f(map_width, map.tilemapheight) * tile_width, color_dirt);

    // Get the left position on the tile map
    const f32 tile_size = map.tilesize;
    const f32 tile_map_width = map.tilemapwidth;
    const f32 tile_map_height = map.tilemapheight;
    s32 map_left = driver.getWorldPosFromScreenPos(Vec2f(middle, 0)).x / tile_size - map_width / 2;

    // Update vertices
    u8 width = 100;
    v_raw.push_back(Vertex(0,     0,     1000, 0,     0,     SColor(0x70aacdff)));
    v_raw.push_back(Vertex(width, 0,     1000, width, 0,     SColor(0x70aacdff)));
    v_raw.push_back(Vertex(width, width, 1000, width, width, SColor(0x70aacdff)));
    v_raw.push_back(Vertex(0,     width, 1000, 0,     width, SColor(0x70aacdff)));

    // Update indices
    v_i.push_back(0);
    v_i.push_back(1);
    v_i.push_back(2);
    v_i.push_back(0);
    v_i.push_back(2);
    v_i.push_back(3);

    // Render mesh
    minimap.SetVertex(v_raw);
    minimap.SetIndices(v_i); 
    minimap.BuildMesh();
    minimap.SetDirty(SMesh::VERTEX_INDEX);
    minimap.RenderMeshWithMaterial();
    // }    
}