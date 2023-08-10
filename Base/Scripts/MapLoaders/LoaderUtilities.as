// LoaderUtilities.as

#include "ZombieBlocksCommon.as"
#include "ZombieBlocksSetTile.as"

// bool onMapTileCollapse(CMap@ map, u32 offset)
// {
// 	// if(isDummyTile(map.getTile(offset).type))
// 	// {
// 	// 	CBlob@ blob = getBlobByNetworkID(server_getDummyGridNetworkID(offset));
// 	// 	if(blob !is null)
// 	// 	{
// 	// 		blob.server_Die();
// 	// 	}
// 	// }
// 	// return true;
// }

/*
TileType server_onTileHit(CMap@ this, f32 damage, u32 index, TileType oldTileType)
{
}
*/

void onSetTile(CMap@ this, u32 index, TileType newtile, TileType oldtile)
{
	// ZombieSetTile(this, index, newtile);
}