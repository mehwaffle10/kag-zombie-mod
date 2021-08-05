
#define SERVER_ONLY

#include "LootCommon.as";

void onDie(CBlob@ this)
{
	server_CreateLoot(this, this.getPosition(), 0);
}