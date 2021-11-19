
// Simple rules logic script

// #define SERVER_ONLY

#include "RulesCore.as";

// Used for setting the time on the map (the sky)
const float DAWN = .07;
const float DUSK = (1 - DAWN);
const float MAX_DAY = .12;

// Actual game time
const u16 DEFAULT_DAY_LENGTH = 1 * 60 * getTicksASecond();
const u16 DEFAULT_NIGHT_LENGTH = 1 * 60 * getTicksASecond();

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
	getMap().SetDayTime(DAWN);
	if (isServer())
	{
		// Set time to dawn (first day)
		this.set_u16("ticks_left", DEFAULT_DAY_LENGTH);
		this.Sync("ticks_left", true);

		// Reset phase count (1 day and 1 night are 2 phases, starts at phase 0 so even phase is day and odd phase is night and int division works nicely)
		this.set_u16("phase", 0);
		this.Sync("phase", true);

		// Calculate default time intervals
		this.set_u16("day_length", DEFAULT_DAY_LENGTH);
		this.Sync("day_length", true);
		this.set_u16("night_length", DEFAULT_NIGHT_LENGTH);
		this.Sync("night_length", true);

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

void onTick(CRules@ this)
{
	// Artificial day night cycle; The built in one had nights that were much too short
	CMap@ map = getMap();
	u16 phase = this.get_u16("phase");

	if (phase % 2 == 0) // Day time
	{
		f32 new_time = DAWN + (1 - f32(this.get_u16("ticks_left"))/this.get_u16("day_length")) * (MAX_DAY - DAWN)*2;
		
		if (new_time > MAX_DAY) // Skip most of day, keep it gloomy
		{
			new_time += 1.0 - 2 * MAX_DAY;
		}
		
		map.SetDayTime(new_time);
	}
	else // Night time
	{
		f32 new_time = DUSK + (1 - f32(this.get_u16("ticks_left"))/this.get_u16("night_length")) * DAWN*2;
		if (new_time > 1.0) // Reloop night
		{
			new_time -= 1.0;
		}
		map.SetDayTime(new_time);
	}

	// Update timer and phase count
	u16 ticks_left = this.get_u16("ticks_left");
	
	if (ticks_left > 0)
	{
		if (isServer())
		{
			this.set_u16("ticks_left", ticks_left - 1);
			this.Sync("ticks_left", true);
		}
	}
	else
	{
		// Increment and update phase
		phase += 1;
		if (isServer())
		{
			this.set_u16("phase", phase);
			this.Sync("phase", true);

			// Setup next phase
			this.set_u16("ticks_left", phase % 2 == 0 ? this.get_u16("day_length") : this.get_u16("night_length"));
			this.Sync("ticks_left", true);
		}

		// Phase change events	
		if (phase % 2 == 1)
		{
			// Update things that trigger at dusk
			if (getNet().isServer())
			{
				CBlob@[] tagged;
				getBlobsByTag("night", @tagged);
				for (u16 i = 0; i < tagged.length; i++)
				{
					tagged[i].SendCommand(tagged[i].getCommandID("night"));
				}
			}

			// Evil laugh when turning night
			string fileName;
			switch (XORRandom(4))
			{
				case 0:
					fileName = "EvilLaugh.ogg";
					break;

				case 1:
					fileName = "EvilLaughShort1.ogg";
					break;

				case 2:
					fileName = "EvilLaughShort2.ogg";
					break;

				case 3:
					fileName = "EvilNotice.ogg";
					break;
			}
			Sound::Play(fileName);
		}
		else
		{
			// Update things that trigger at dawn
			if (getNet().isServer())
			{
				CBlob@[] tagged;
				getBlobsByTag("day", @tagged);
				for (u16 i = 0; i < tagged.length; i++)
				{
					tagged[i].SendCommand(tagged[i].getCommandID("day"));
				}
			}
		}
	}
}
