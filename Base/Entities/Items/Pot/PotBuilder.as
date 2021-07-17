// Loot Table For PotBuilder

#include "LootCommon.as";

void onInit(CBlob@ this)
{
	// Drop loot when destroyed
	addLoot(this, INDEX_BUILDER, 1, 0);
}