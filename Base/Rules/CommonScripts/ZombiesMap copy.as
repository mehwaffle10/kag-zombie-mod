
// TOO LAGGY

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

SMesh@ minimap;
SMaterial@ pixel = SMaterial();

void onRender(CRules@ this)
{
    CMap@ map = getMap();
    CControls@ controls = getControls();
    Driver@ driver = getDriver();
    
    if (map is null || controls is null || driver is null)
    {
        return;
    }

    // Draw map
    if (controls.ActionKeyPressed(AK_MAP))
    {
        // Draw the border and background. Default background is dirt for optimization
        s32 middle = driver.getScreenWidth() / 2;
        Vec2f upper_left = Vec2f(middle - map_width / 2 * tile_width, 40);
        Vec2f border_offset = Vec2f(border_width, border_width);
        GUI::DrawWindow(upper_left - border_offset, upper_left + Vec2f(map_width, map.tilemapheight) * tile_width + border_offset);
        GUI::DrawRectangle(upper_left, upper_left + Vec2f(map_width, map.tilemapheight) * tile_width, color_dirt);

        // Get the left position on the tile map
        const f32 tile_size = map.tilesize;
        const f32 tile_map_width = map.tilemapwidth;
        const f32 tile_map_height = map.tilemapheight;
        s32 map_left = driver.getWorldPosFromScreenPos(Vec2f(middle, 0)).x / tile_size - map_width / 2;

        // For each column
        for (s32 x = 0; x < map_width; x++)
        {
            // Draw all sky as one rectangle to optimize
            s32 map_x = map_left + x;
            u8 lowest_sky_y;
            if (this.exists(map_x + "_lowest_sky_y"))
            {
                lowest_sky_y = this.get_u8(map_x + "_lowest_sky_y");
            }
            else
            {
                lowest_sky_y = 0;
                Vec2f pos = Vec2f(map_x, lowest_sky_y) * tile_size;
                while (lowest_sky_y < tile_map_height && !map.isTileGroundStuff(map.getTile(pos).type) && !map.isInWater(pos))
                {
                    lowest_sky_y++;
                    pos = Vec2f(map_x, lowest_sky_y) * tile_size;
                }
                this.set_u8(x + "_lowest_sky_y", lowest_sky_y);
            }
            GUI::DrawRectangle(upper_left + Vec2f(x, 0) * tile_width, upper_left + Vec2f(x + 1, lowest_sky_y) * tile_width, color_sky);
            
            // Draw all bedrock as one rectangle to optimize
            u8 highest_bedrock_y;
            if (this.exists(map_x + "_highest_bedrock_y"))
            {
                highest_bedrock_y = this.get_u8(map_x + "_highest_bedrock_y");
            }
            else
            {
                highest_bedrock_y = tile_map_height - 1;
                TileType tile = map.getTile(Vec2f(map_x, highest_bedrock_y) * tile_size).type;
                while (map.isTileBedrock(tile) && highest_bedrock_y > 0)
                {
                    highest_bedrock_y--;
                    tile = map.getTile(Vec2f(map_x, highest_bedrock_y) * tile_size).type;
                }
                highest_bedrock_y++;
                this.set_u8(map_x + "_highest_bedrock_y", highest_bedrock_y);
                print("highest_bedrock_y: " + highest_bedrock_y);
            }
            if (highest_bedrock_y <= tile_map_height)
            {
                GUI::DrawRectangle(upper_left + Vec2f(x, highest_bedrock_y) * tile_width, upper_left + Vec2f(x + 1, tile_map_height) * tile_width, color_bedrock);
            }

            // Draw all other blocks
            for (s32 y = 0; y < tile_map_height; y++)    
            {
                Vec2f drawing_upper_left = upper_left + Vec2f(x, y) * tile_width;
                u32 offset = y * tile_map_width + map_left + x;
                TileType tile = map.getTile(offset).type;
                Vec2f pos = Vec2f(offset % tile_map_width, offset / tile_map_width) * tile_size;

                SColor color;
                if (map.isTileGround(tile))
                {
                    // Can skip it since the default is dirt and other two will never overwrite dirt
                    continue;
                }
                else if (map.isTileGold(tile))  
                {
                    // Lag Optimization
                    continue;
                    // color = color_gold;
                } 
                else if (map.isTileThickStone(tile))
                {
                    // Lag Optimization
                    continue;
                    // color = color_thickstone;
                }
                else if (map.isTileStone(tile))
                {
                    // Lag Optimization
                    continue;
                    // color = color_stone;
                }
                else if (map.isTileBedrock(tile))
                {
                    // Only draw if above the highest_bedrock_y
                    if (y >= highest_bedrock_y)
                    {
                        continue;
                    }
                    color = color_bedrock;
                }
                else if (map.isTileWood(tile)) 
                { 
                    color = color_wood;
                } 
                else if (map.isTileCastle(tile))      
                { 
                    color = color_castle;
                } 
                else if (map.isTileBackgroundNonEmpty(map.getTile(pos)) && !map.isTileGrass(tile)) {
                    
                    // TODO(hobey): maybe check if there's a door/platform on this backwall and make a custom color for them?
                    if (tile == CMap::tile_castle_back) 
                    { 
                        color = color_castle_backwall;
                    } 
                    else if (tile == CMap::tile_wood_back)   
                    { 
                        color = color_wood_backwall;
                    } 
                    else                                     
                    { 
                        color = color_dirt_backwall;
                    }
                    
                } 
                else 
                {
                    // Only draw if below the lowest_sky_y
                    if (y <= lowest_sky_y)
                    {
                        continue;
                    }
                    color = color_sky;
                }
                
                ///Tint the map based on Fire/Water State
                if (map.isInWater(pos))
                {
                    color = color.getInterpolated(color_water, 0.5f);
                }
                else if (map.isInFire(pos))
                {
                    color = color.getInterpolated(color_fire, 0.5f);
                }

                GUI::DrawRectangle(drawing_upper_left, drawing_upper_left + Vec2f(tile_width, tile_width), color);
            }

            // Draw all other blocks
            if (controls.isKeyPressed(KEY_KEY_N))
            {
                for (s32 y = 0; y < tile_map_height; y++)    
                {
                    Vec2f drawing_upper_left = upper_left + Vec2f(x, y) * tile_width;
                    u32 offset = y * tile_map_width + map_left + x;
                    TileType tile = map.getTile(offset).type;
                    Vec2f pos = Vec2f(offset % tile_map_width, offset / tile_map_width) * tile_size;

                    SColor color;
                    if (map.isTileGround(tile))
                    {
                        // continue;
                        color = color_dirt;
                    }
                    else if (map.isTileGold(tile))  
                    { 
                        // continue;
                        color = color_gold;
                    } 
                    else if (map.isTileThickStone(tile))
                    {
                        // continue;
                        color = color_thickstone;
                    }
                    else if (map.isTileStone(tile))
                    {
                        // continue;
                        color = color_stone;
                    }
                    else if (map.isTileBedrock(tile))
                    {
                        // continue;
                        color = color_bedrock;
                    }
                    else if (map.isTileWood(tile)) 
                    { 
                        color = color_wood;
                    } 
                    else if (map.isTileCastle(tile))      
                    { 
                        color = color_castle;
                    } 
                    else if (map.isTileBackgroundNonEmpty(map.getTile(pos)) && !map.isTileGrass(tile)) {
                        
                        // TODO(hobey): maybe check if there's a door/platform on this backwall and make a custom color for them?
                        if (tile == CMap::tile_castle_back) 
                        { 
                            color = color_castle_backwall;
                        } 
                        else if (tile == CMap::tile_wood_back)   
                        { 
                            color = color_wood_backwall;
                        } 
                        else                                     
                        { 
                            color = color_dirt_backwall;
                        }
                        
                    } 
                    else 
                    {
                        color = color_sky;
                    }
                    
                    ///Tint the map based on Fire/Water State
                    if (map.isInWater(pos))
                    {
                        color = color.getInterpolated(color_water, 0.5f);
                    }
                    else if (map.isInFire(pos))
                    {
                        color = color.getInterpolated(color_fire, 0.5f);
                    }

                    GUI::DrawRectangle(drawing_upper_left, drawing_upper_left + Vec2f(tile_width, tile_width), color);
                }
            }
        }
    }    
}
