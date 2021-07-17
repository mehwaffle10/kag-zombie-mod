// Loot Table For PotRare

#include "LootCommon.as";

void onInit(CBlob@ this)
{
	// Drop loot when destroyed
	addLoot(this, INDEX_ARCHER, 1, 0);
}