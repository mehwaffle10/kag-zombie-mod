
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
    this.set_bool("Update Nodes " + isClient(), false);
    current_x = 0;
    timer = delay;
    CMap@ map = getMap();
    if (map !is null && !map.hasScript("PathFindingMapUpdates"))
    {
        map.AddScript("PathFindingMapUpdates");
    }
}

void onTick(CRules@ this)
{
    if (timer == 0)
    {
        CMap@ map = getMap();
        if (map !is null)
        {
            print("Updating Graph, Current_X: " + current_x);
            UpdateGraph(map, Vec2f(current_x, 0), Vec2f(Maths::Min(current_x + scan_width, map.tilemapwidth - 1), map.tilemapheight - 1));
            current_x += scan_width;
            if (current_x < map.tilemapwidth)
            {
                timer = delay;
            }
            this.set_bool("Update Nodes " + isClient(), true);
        }
    }

    if (timer >= 0)
    {
        timer--;
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
