
#include "PathFindingCommon.as";

// TODO Add support for doors

const u8 scan_width = 40;
const s8 delay = getTicksASecond() / 3;
s8 timer = delay;
s32 current_x = 0;


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
    CMap@ map = getMap();
    if (map is null)
    {
        return;
    }

    if (!map.hasScript("PathFindingMapUpdates"))
    {
        map.AddScript("PathFindingMapUpdates");
    }

    PathfindingCore@ pathfinding_core = PathfindingCore();
    Node[] nodes(map.tilemapwidth * map.tilemapheight); 
    pathfinding_core.nodes = nodes;
    this.set(PATHFINDING_CORE, @pathfinding_core);
    GenerateGraph(map);
}

void onRender(CRules@ this)
{
    if (isClient() && getControls().isKeyPressed(KEY_NUMPAD8))
    {
        a_star();
    }
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
    CMap@ map = getMap();
    if (blob !is null && (blob.isPlatform() || blob.hasTag("door") || blob.isLadder()))  // getRules().get_bool("Update Nodes " + isClient()) && 
    {
        blob.AddScript("UpdateOnStaticChange");
    }
}
