
#define SERVER_ONLY

#include "PathFindingCommon.as";

// TODO Add support for doors

void onBlobCreated(CRules@ this, CBlob@ blob)
{
    CMap@ map = getMap();
    if(map.get_bool("Update Nodes") && blob !is null && blob.isPlatform())
    {
        print("onBlobCreated");
        blob.AddScript("UpdateOnStaticChange");
    }
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
    CMap@ map = getMap();
    // TODO Fix nodes being placed on multiple falling platforms
    // Platform's attached to something are being held by a builder and not placed yet, they die when going back into your inventory
    if(map.get_bool("Update Nodes") && blob !is null && blob.isPlatform() && !blob.isAttached())
    {
        Vec2f pos = blob.getPosition() / map.tilesize;
        pos = Vec2f(Maths::Floor(pos.x), Maths::Floor(pos.y));
        print("onBlobDie: " + pos);
        UpdateGraph(map, 2, pos, true);
    }
}

void onBlobCollapse(CBlob@ this)
{
    print("onBlobCollapse");
}