
#include "PathFindingCommon.as";

void onSetTile(CMap@ this, u32 index, TileType newtile, TileType oldtile)
{
    if(getRules().get_bool("Update Nodes " + isClient()) && this.isTileSolid(newtile) != this.isTileSolid(oldtile))
    {
        print("onSetTile: " + this.getTileSpacePosition(index));
        UpdateGraph(this, this.getTileSpacePosition(index), !this.isTileSolid(newtile));
    }
}

bool onMapTileCollapse(CMap@ this, u32 offset)
{
    // Only update if the block is solid or a platform
    Vec2f pos = this.getTileSpacePosition(offset);
    if(getRules().get_bool("Update Nodes " + isClient()) && this.isTileSolid(this.getTile(offset).type))
    {
        UpdateGraph(this, pos, true);
    }
    return true;
}
