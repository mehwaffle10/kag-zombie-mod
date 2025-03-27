
#define CLIENT_ONLY

#include "PathFindingCommon.as";

void onRender(CRules@ this)
{
    if (!getControls().isKeyPressed(KEY_NUMPAD9))
    {
        return;
    }

    CMap@ map = getMap();
    Driver@ driver = getDriver();
    Vec2f mouse_world_pos = getControls().getMouseWorldPos();
    Vec2f mouse_screen_pos = getControls().getMouseScreenPos();
    s32 left_x = driver.getWorldPosFromScreenPos(Vec2f(driver.getScreenWidth() / 2 - 50, 0)).x / map.tilesize - 1;
    s32 right_x = driver.getWorldPosFromScreenPos(Vec2f(driver.getScreenWidth() / 2 + 50, 0)).x / map.tilesize + 1;

    PathfindingCore@ pathfinding_core;
    this.get(PATHFINDING_CORE, @pathfinding_core);

    for (s32 x = Maths::Max(left_x, 0); x < Maths::Min(right_x, map.tilemapwidth); x++)
    {
        for (u8 y = 0; y < map.tilemapheight; y++)
        {
            Vec2f tile_pos = Vec2f(x, y);
            u32 offset = map.getTileOffsetFromTileSpace(tile_pos);
            Node@ node = pathfinding_core.nodes[offset];
            if (node.valid)
            {
                DrawNodeWithEdges(map, driver, node, tile_pos, 2, mouse_world_pos, mouse_screen_pos);
            }
        }
    }
}

void DrawNodeWithEdges(CMap@ map, Driver@ driver, Node@ node, Vec2f tile_top_left, u8 size, Vec2f mouse_world_pos, Vec2f mouse_screen_pos)
{
    CRules@ rules        = getRules();
    CControls@ controls  = getControls();
    Vec2f world_top_left = tile_top_left * map.tilesize;
    f32 offset           = size * map.tilesize;
    Vec2f bottom_left    = world_top_left + Vec2f(0, offset), 
          top_right      = world_top_left + Vec2f(offset, 0), 
          bottom_right   = world_top_left + Vec2f(offset, offset);

    // Draw box
    GUI::DrawLine(world_top_left, top_right,    SColor(255, 255, 255, 255));
    GUI::DrawLine(world_top_left, bottom_left,  SColor(255, 255, 0, 0));
    GUI::DrawLine(bottom_left,    bottom_right, SColor(255, 0, 255, 0));
    GUI::DrawLine(top_right,      bottom_right, SColor(255, 0, 0, 255));

    // top_left = getDriver().getScreenPosFromWorldPos(Vec2f(map.tilemapwidth / 2, 20) * map.tilesize);
    // GUI::DrawRectangle(top_left, top_left + Vec2f(3, 3) * 2 * map.tilesize * camera.targetDistance);

    // Add hover area for listing edges
    bool render = true;
    if (false && controls.isKeyPressed(KEY_NUMPAD9))
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
        if (node.cost_up >= 0)
        {
            DrawEdge(driver, world_top_left, (tile_top_left + Vec2f(0, -1)) * map.tilesize, node.cost_up);
        }
        if (node.cost_down >= 0)
        {
            DrawEdge(driver, world_top_left, (tile_top_left + Vec2f(0, 1)) * map.tilesize, node.cost_down);
        }
        if (node.cost_left >= 0)
        {
            DrawEdge(driver, world_top_left, (tile_top_left + Vec2f(-1, 0)) * map.tilesize, node.cost_left);
        }
        if (node.cost_right >= 0)
        {
            DrawEdge(driver, world_top_left, (tile_top_left + Vec2f(1, 0)) * map.tilesize, node.cost_right);
        }
    }
}

void DrawEdge(Driver@ driver, Vec2f source, Vec2f target, s8 cost)
{
    GUI::DrawSplineArrow(
        source,
        target,
        SColor(255, target.x % 5 * 50, 0, target.y % 5 * 50)
    );

    GUI::DrawText(
        " " + cost,
        driver.getScreenPosFromWorldPos(target),
        SColor(255, 255, 255, 255)
    );
}