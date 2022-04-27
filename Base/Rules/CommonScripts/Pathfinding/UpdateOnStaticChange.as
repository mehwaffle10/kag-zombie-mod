
#define SERVER_ONLY

#include "PathFindingCommon.as";

/*
void onInit(CBlob@ this)
{
    this.set_u8("Delayed Update Timer", 1);
}

void onTick(CBlob@ this)
{
    if (this.get_u8("Delayed Update Timer") > 0)
    {
        this.set_u8("Delayed Update Timer", this.get_u8("Delayed Update Timer") - 1);
    }
    else
    {
*/

void onSetStatic(CBlob@ this, const bool isStatic)
{
    CMap@ map = getMap();
    // Platform's attached to something are being held by a builder and not placed yet, they die when going back into your inventory
    if(map.get_bool("Update Nodes") && this !is null)
    {
        Vec2f pos = this.getPosition() / map.tilesize;
        pos = Vec2f(Maths::Floor(pos.x), Maths::Floor(pos.y));
        print("onSetStatic: " + pos);
        UpdateGraph(map, 2, pos, false);
    }
}