// Loot Table For PotCombat

#include "LootCommon.as";

void onInit(CBlob@ this)
{
	// Drop loot when destroyed
	addLoot(this, INDEX_KNIGHT, 1, 0);
}