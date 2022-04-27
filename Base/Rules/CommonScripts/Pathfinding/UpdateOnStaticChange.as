
#define SERVER_ONLY

#include "PathFindingCommon.as";

const string HAS_BEEN_NOT_STATIC = "has been not static";

void onSetStatic(CBlob@ this, const bool isStatic)
{
    CMap@ map = getMap();
    
    if (this is null)
    {
        return;
    }

    // Flag since the shape isStatic doesn't get set until after this hook
    this.set_bool(IS_STATIC, isStatic);

    // Update the graph if we need to
    // Platform's attached to something are being held by a builder and not placed yet, they die when going back into your inventory
    bool has_been_not_static = this.hasTag(HAS_BEEN_NOT_STATIC);
    if(map.get_bool("Update Nodes") && !this.isAttached() && !has_been_not_static)
    {
        this.set_bool(IS_STATIC, isStatic);
        Vec2f pos = this.getPosition() / map.tilesize;
        pos = Vec2f(Maths::Floor(pos.x), Maths::Floor(pos.y));
        print("onSetStatic: " + pos + ", " + isStatic);
        UpdateGraph(map, 2, pos, false);
    }

    // Mark that we have been set to not static before
    if (!isStatic && !has_been_not_static)
    {
        this.Tag(HAS_BEEN_NOT_STATIC);
    }
}