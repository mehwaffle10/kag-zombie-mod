
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
