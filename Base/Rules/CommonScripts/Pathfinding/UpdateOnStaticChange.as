
#include "PathFindingCommon.as";

void onInit(CBlob@ this)
{
    this.set_bool(IS_STATIC, false);
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
    CRules@ rules = getRules();
    CMap@ map = getMap();

    if (this is null)
    {
        return;
    }

    // Update the graph if we need to
    // Platform's attached to something are being held by a builder and not placed yet, they die when going back into your inventory
    if(rules.get_bool("Update Nodes " + isClient()) && !this.isAttached() && this.get_bool(IS_STATIC) != isStatic)
    {
        this.set_bool(IS_STATIC, isStatic);
        Vec2f pos = this.getPosition() / map.tilesize;
        pos = Vec2f(Maths::Floor(pos.x), Maths::Floor(pos.y));
        UpdateGraph(map, pos, false);
    }
}