
// Simple rules logic script

// #define SERVER_ONLY

#include "RulesCore.as";

void onInit(CRules@ this)
{
	// Make sure the default class is builder
	if (!this.exists("default class"))
	{
		this.set_string("default class", "builder");
	}
	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	if (isServer())
	{
		// Try to spawn all players
		for(int i=0; i < getPlayerCount(); i++)
		{
			Respawn(this, getPlayer(i));
		}
	}
}

void onPlayerRequestSpawn(CRules@ this, CPlayer@ player)
{
	Respawn(this, player);
}

CBlob@ Respawn(CRules@ this, CPlayer@ player)
{
	if (isServer() && player !is null)
	{
		// remove previous players blob
		CBlob @blob = player.getBlob();

		if (blob !is null)
		{
			CBlob @blob = player.getBlob();
			blob.server_SetPlayer(null);
			blob.server_Die();
		}

		CBlob@ newBlob = server_CreateBlobNoInit(this.get_string("default class"));
		newBlob.server_setTeamNum(0);
		newBlob.setPosition(getSpawnLocation(player));
		newBlob.server_SetPlayer(player);
		newBlob.Init();
		return newBlob;
	}

	return null;
}

void onPlayerRequestTeamChange(CRules@ this, CPlayer@ player, u8 newTeam)
{
	RulesCore@ core;
	this.get("core", @core);
	if (core is null)
	{
		return;
	}

	int oldTeam = player.getTeamNum();
	bool spect = (oldTeam == this.getSpectatorTeamNum());
	// print("---request team change--- " + oldTeam + " -> " + newTeam);

	print("before oldTeam: " + oldTeam);
	print("before newTeam: " + oldTeam);

	//if a player changes to team 255 (-1), auto-assign
	if (newTeam == 255)
	{
		newTeam = getSmallestTeam(core.teams);
	}
	//if a player changing from team 255 (-1), auto-assign
	if (oldTeam == 255)
	{
		oldTeam = getSmallestTeam(core.teams);
		newTeam = oldTeam;
	}

	print("after oldTeam: " + oldTeam);
	print("after newTeam: " + oldTeam);

	core.ChangePlayerTeam(player, newTeam);
}

Vec2f getSpawnLocation(CPlayer@ player)
{
	// Get middle of map
	CMap@ map = getMap();
	Vec2f mid;
	mid.x = map.tilemapwidth * map.tilesize / 2;

	// Get ground level (built in functions don't seem to work)
	for(u64 y = 0; y < map.tilemapheight; y++)
	{
		mid.y = y * map.tilesize;
		TileType type = map.getTile(mid).type;

		if (map.isTileGround(type))
		{
			break;
		}
	}

	// Go one tile above ground level
	mid.y = mid.y - map.tilesize;

	// Spawn near surface in middle of map
	return mid;
}

void onBlobDie(CRules@ this, CBlob@ blob)
{

}
