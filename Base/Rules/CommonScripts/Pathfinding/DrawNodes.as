
#define CLIENT_ONLY

#include "PathFindingCommon.as";

void onRender(CRules@ this)
{
    CMap@ map = getMap();
    Driver@ driver = getDriver();
    Vec2f mouse_world_pos = getControls().getMouseWorldPos();
    Vec2f mouse_screen_pos = getControls().getMouseScreenPos();
    s32 left_x = driver.getWorldPosFromScreenPos(Vec2f(0, 0)).x / map.tilesize - 1;
    s32 right_x = driver.getWorldPosFromScreenPos(Vec2f(driver.getScreenWidth(), 0)).x / map.tilesize + 1;
    for (s32 x = Maths::Max(left_x, 0); x < Maths::Min(right_x, map.tilemapwidth); x++)
    {
        u8[] y_values;
        readX(this, 2, x, y_values);
        for (u8 i = 0; i < y_values.length; i++)
        {
            DrawNode(map, driver, Vec2f(x, y_values[i]), 2, mouse_world_pos, mouse_screen_pos);
        }
    }
}

void DrawNode(CMap@ map, Driver@ driver, Vec2f tile_top_left, u8 size, Vec2f mouse_world_pos, Vec2f mouse_screen_pos)
{
    CRules@ rules = getRules();
    CControls@ controls = getControls();
    Vec2f world_top_left = tile_top_left * map.tilesize;
    f32 offset = size * map.tilesize;
    Vec2f bottom_left = world_top_left + Vec2f(0, offset), 
          top_right = world_top_left + Vec2f(offset, 0), 
          bottom_right = world_top_left + Vec2f(offset, offset);

    // Draw box
    GUI::DrawLine(world_top_left, top_right, SColor(255, 255, 255, 255));
    GUI::DrawLine(world_top_left, bottom_left, SColor(255, 255, 0, 0));
    GUI::DrawLine(bottom_left, bottom_right, SColor(255, 0, 255, 0));
    GUI::DrawLine(top_right, bottom_right, SColor(255, 0, 0, 255));

    // top_left = getDriver().getScreenPosFromWorldPos(Vec2f(map.tilemapwidth / 2, 20) * map.tilesize);
    // GUI::DrawRectangle(top_left, top_left + Vec2f(3, 3) * 2 * map.tilesize * camera.targetDistance);

    // Add hover area for listing edges
    bool render = true;
    if (controls.isKeyPressed(KEY_NUMPAD9))
    {
        render = false;
        f32 hover_area_size = map.tilesize / 2;
        Vec2f hover_bottom_right = world_top_left + Vec2f(1, 1) * hover_area_size;
        GUI::DrawLine(world_top_left + Vec2f(hover_area_size, 0), hover_bottom_right, SColor(255, 255, 0, 255));
        GUI::DrawLine(world_top_left + Vec2f(0, hover_area_size), hover_bottom_right, SColor(255, 255, 255, 0));
        if (mouse_world_pos.x >= world_top_left.x && mouse_world_pos.x <= hover_bottom_right.x &&
            mouse_world_pos.y >= world_top_left.y && mouse_world_pos.y <= hover_bottom_right.y)
        {
            render = true;   
        }
    }

    if (render)
    {
        Vec2f tile_pos = map.getTileSpacePosition(mouse_world_pos);
        u8 line_offset = 12;
        u8 length = rules.get_u8(getEdgeLengthString(tile_top_left.x, tile_top_left.y, 2));
        for (u8 i = 0; i < length; i++)
        {
            Vec2f target = rules.get_Vec2f(getEdgeTargetString(tile_top_left.x, tile_top_left.y, 2, i)) * map.tilesize;
            GUI::DrawSplineArrow(
                world_top_left,
                target,
                SColor(255, tile_top_left.x % 5 * 50, 0, tile_top_left.y % 5 * 50)
            );

            GUI::DrawText(
                " " + rules.get_s8(getEdgeCostString(tile_top_left.x, tile_top_left.y, 2, i)),
                driver.getScreenPosFromWorldPos(target),
                SColor(255, 255, 255, 255)
            );
        }
    }
}
