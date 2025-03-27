
#include "PathFindingCommon.as";

void onSetTile(CMap@ this, u32 index, TileType newtile, TileType oldtile)
{
    if (this.isTileSolid(newtile) != this.isTileSolid(oldtile))  // getRules().get_bool("Update Nodes " + isClient()) && 
    {
        UpdateGraph(this, this.getTileSpacePosition(index), !this.isTileSolid(newtile));
    }
}

bool onMapTileCollapse(CMap@ this, u32 offset)
{
    // Only update if the block is solid or a platform
    Vec2f pos = this.getTileSpacePosition(offset);
    if (this.isTileSolid(this.getTile(offset).type))  // getRules().get_bool("Update Nodes " + isClient()) && 
    {
        UpdateGraph(this, pos, true);
    }
    return true;
}
