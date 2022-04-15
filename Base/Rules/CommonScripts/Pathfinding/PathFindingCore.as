
#include "PathFindingCommon.as";

void onInit(CMap@ this)
{

}

void onSetTile(CMap@ this, u32 index, TileType newtile, TileType oldtile)
{
    // TODO make the graph update when platforms are placed or broken
    // this.isTilePlatform(newtile) != this.isTilePlatform(oldtile)
    if(isServer() && this.get_bool("Update Nodes") && this.isTileSolid(newtile) != this.isTileSolid(oldtile))
    {
        // Get the boundaries for the update
        u8 radius = 10;
        Vec2f offset = Vec2f(radius, radius);
        Vec2f block = this.getTileSpacePosition(index);
        UpdateGraph(this, 2, block - offset, block + offset);
    }
}

void onRender(CMap@ this)
{
    Driver@ driver = getDriver();
    s32 left_x = driver.getWorldPosFromScreenPos(Vec2f(0, 0)).x / this.tilesize;
    s32 right_x = driver.getWorldPosFromScreenPos(Vec2f(driver.getScreenWidth(), 0)).x / this.tilesize;
    for (s32 x = Maths::Max(left_x, 0); x < Maths::Min(right_x, this.tilemapwidth); x++)
    {
        u8[] y_values;
        readX(this, x, y_values);
        for (u8 i = 0; i < y_values.length; i++)
        {
            DrawNode(this, Vec2f(x, y_values[i]), 2);
        }
    }
}
