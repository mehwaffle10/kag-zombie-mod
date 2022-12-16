
// #define SERVER_ONLY

#include "PathFindingCommon.as";

// TODO Add support for doors

const string delay_string = "graph generation delay";

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
    this.set_s8(delay_string, 2);
}

void onTick(CRules@ this)
{
    if (this.exists(delay_string))
    {
        s8 delay = this.get_s8(delay_string);
        if (delay == 0)
        {
            GenerateGraph(getMap(), 2);
        }

        if (delay >= 0)
        {
            this.set_s8(delay_string, delay - 1);
        }
    }   
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
    CMap@ map = getMap();
    if(map.get_bool("Update Nodes") && blob !is null && (blob.isPlatform() || blob.hasTag("door") || blob.isLadder()))
    {
        blob.AddScript("UpdateOnStaticChange");
    }
}
