
#define SERVER_ONLY

#include "PathFindingCommon.as";

void onSetTile(CMap@ this, u32 index, TileType newtile, TileType oldtile)
{
    if(this.get_bool("Update Nodes") && this.isTileSolid(newtile) != this.isTileSolid(oldtile))
    {
        print("onSetTile: " + this.getTileSpacePosition(index));
        UpdateGraph(this, 2, this.getTileSpacePosition(index), !this.isTileSolid(newtile));
    }
}

bool onMapTileCollapse(CMap@ this, u32 offset)
{
    // Only update if the block is solid or a platform
    Vec2f pos = this.getTileSpacePosition(offset);
    if(this.get_bool("Update Nodes") && this.isTileSolid(this.getTile(offset).type))
    {
        print("onMapTileCollapse: " + pos);
        UpdateGraph(this, 2, pos, true);
    }
    return true;
}