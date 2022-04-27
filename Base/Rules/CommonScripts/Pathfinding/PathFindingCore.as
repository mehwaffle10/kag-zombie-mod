
#define SERVER_ONLY

#include "PathFindingCommon.as";

// TODO Add support for doors

void onBlobCreated(CRules@ this, CBlob@ blob)
{
    CMap@ map = getMap();
    if(map.get_bool("Update Nodes") && blob !is null && ((blob.isPlatform() && blob.getName() != "bridge") || blob.isLadder()))
    {
        print("onBlobCreated");
        blob.AddScript("UpdateOnStaticChange");
    }
}

/*
Not needed anymore, handled in UpdateOnStaticChange.as
void onBlobDie(CRules@ this, CBlob@ blob)
{
    CMap@ map = getMap();
    // Platform's attached to something are being held by a builder and not placed yet, they die when going back into your inventory
    if(map.get_bool("Update Nodes") && blob !is null && blob.isPlatform() && !blob.isAttached())
    {
        Vec2f pos = blob.getPosition() / map.tilesize;
        pos = Vec2f(Maths::Floor(pos.x), Maths::Floor(pos.y));
        print("onBlobDie: " + pos);
        UpdateGraph(map, 2, pos, true);
    }
}
*/