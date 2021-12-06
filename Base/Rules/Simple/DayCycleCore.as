
#define SERVER_ONLY

u16 ticks_left = 0;
u16 phase = 0;
bool rain = false;

// Used for setting the time on the map (the sky)
const float DAWN = .07;
const float MAX_DAY = .12;

// Actual game time
const u16 DEFAULT_DAY_LENGTH = 5 * 60 * getTicksASecond();
const u16 DEFAULT_NIGHT_LENGTH = 3 * 60 * getTicksASecond();

void onInit(CRules@ this)
{
	this.addCommandID("set_phase");
	this.addCommandID("do_laugh");
	Reset(this);
} 

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	CMap@ map = getMap();
	if (map !is null)
	{
		map.SetDayTime(DAWN);
	}

	// Sync phase lengths
	this.set_u16("dawn", DAWN);
	this.Sync("dawn", true);
	this.set_u16("max_day", MAX_DAY);
	this.Sync("max_day", true);

	// Set time to dawn (first day)
	ticks_left = DEFAULT_DAY_LENGTH;

	// Reset phase count (1 day and 1 night are 2 phases, starts at phase 0 so even phase is day and odd phase is night and int division works nicely)
	phase = 0;
	SetPhase(this);

	// Calculate default time intervals
	this.set_u16("day_length", DEFAULT_DAY_LENGTH);
	this.Sync("day_length", true);
	this.set_u16("night_length", DEFAULT_NIGHT_LENGTH);
	this.Sync("night_length", true);
}

void onNewPlayerJoin( CRules@ this, CPlayer@ player )
{
	SetPhase(this);
}

void onTick(CRules@ this)
{
	// Artificial day night cycle; The built in one had nights that were much too short
	CMap@ map = getMap();
	
	// Update the daytime
	f32 percent_passed = (1 - f32(ticks_left)/this.get_u16(phase % 2 == 0 ? "day_length" : "night_length"));
	f32 peak = phase % 2 == 0 ? MAX_DAY : 0;
	map.SetDayTime(percent_passed < 0.5f ? DAWN + percent_passed * (peak - DAWN) * 2 : peak - (percent_passed - 0.5f) * (peak - DAWN) * 2);

	// Update timer and phase count
	if (ticks_left > 0)
	{
		ticks_left--;
	}
	else
	{
		// Setup next phase
		phase += 1;
		ticks_left = phase % 2 == 0 ? this.get_u16("day_length") : this.get_u16("night_length");

		SetPhase(this);

		// Phase change events	
		if (phase % 2 == 1)
		{
			// Update things that trigger at dusk
			CBlob@[] tagged;
			getBlobsByTag("night", @tagged);
			for (u16 i = 0; i < tagged.length(); i++)
			{
				tagged[i].SendCommand(tagged[i].getCommandID("night"));
			}

			// Evil laugh when turning night
			CBitStream params;
			params.write_u8(XORRandom(4));
			this.SendCommand(this.getCommandID("do_laugh"), params);
		}
		else
		{
			// Update things that trigger at dawn
			CBlob@[] tagged;
			getBlobsByTag("day", @tagged);
			for (u16 i = 0; i < tagged.length(); i++)
			{
				tagged[i].SendCommand(tagged[i].getCommandID("day"));
			}

			// Chance of rain
			if (!rain && XORRandom(7) == 0)
			{
				rain = true;
				server_CreateBlob("rain");
			}
			else
			{
				rain = false;
			}
		}
	}
}

void SetPhase(CRules@ this)
{
	CBitStream params;
	params.write_u16(phase);
	params.write_u16(ticks_left);
	this.SendCommand(this.getCommandID("set_phase"), params);
}