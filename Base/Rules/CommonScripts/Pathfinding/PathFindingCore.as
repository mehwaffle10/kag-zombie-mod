
#include "PathFindingCommon.as";

// TODO Add support for doors

s8 delay = 2;

void onInit(CRules@ this)
{
    Reset(this);
}

void onRestart(CRules@ this)
{
    Reset(this);
}

void Reset(CRules@ this)
{
    this.set_bool("Update Nodes " + isClient(), false);
    delay = 2;
    CMap@ map = getMap();
    if (map !is null && !map.hasScript("PathFindingMapUpdates"))
    {
        map.AddScript("PathFindingMapUpdates");
    }
}

void onTick(CRules@ this)
{
    if (delay == 0)
    {
        CMap@ map = getMap();
        if (map !is null)
        {
            GenerateGraph(map);
        }
        this.set_bool("Update Nodes " + isClient(), true);
    }

    if (delay >= 0)
    {
        delay--;
    }
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
    CMap@ map = getMap();
    if(getRules().get_bool("Update Nodes " + isClient()) && blob !is null && (blob.isPlatform() || blob.hasTag("door") || blob.isLadder()))
    {
        blob.AddScript("UpdateOnStaticChange");
    }
}
