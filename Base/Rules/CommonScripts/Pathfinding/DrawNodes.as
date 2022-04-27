
#define CLIENT_ONLY

#include "PathFindingCommon.as";

void onRender(CRules@ this)
{
    CMap@ map = getMap();
    Driver@ driver = getDriver();
    s32 left_x = driver.getWorldPosFromScreenPos(Vec2f(0, 0)).x / map.tilesize - 1;
    s32 right_x = driver.getWorldPosFromScreenPos(Vec2f(driver.getScreenWidth(), 0)).x / map.tilesize + 1;
    for (s32 x = Maths::Max(left_x, 0); x < Maths::Min(right_x, map.tilemapwidth); x++)
    {
        u8[] y_values;
        readX(this, x, y_values);
        for (u8 i = 0; i < y_values.length; i++)
        {
            DrawNode(map, Vec2f(x, y_values[i]), 2);
        }
    }
}

void DrawNode(CMap@ map, Vec2f top_left, u8 size)
{
    top_left *= map.tilesize;
    f32 offset = size * map.tilesize;
    Vec2f bottom_left = top_left + Vec2f(0, offset), 
          top_right = top_left + Vec2f(offset, 0), 
          bottom_right = top_left + Vec2f(offset, offset);

    GUI::DrawLine(top_left, top_right, SColor(255, 255, 255, 255));
    GUI::DrawLine(top_left, bottom_left, SColor(255, 255, 0, 0));
    GUI::DrawLine(bottom_left, bottom_right, SColor(255, 0, 255, 0));
    GUI::DrawLine(top_right, bottom_right, SColor(255, 0, 0, 255));

    // top_left = getDriver().getScreenPosFromWorldPos(Vec2f(map.tilemapwidth / 2, 20) * map.tilesize);
    // GUI::DrawRectangle(top_left, top_left + Vec2f(3, 3) * 2 * map.tilesize * camera.targetDistance);
}
