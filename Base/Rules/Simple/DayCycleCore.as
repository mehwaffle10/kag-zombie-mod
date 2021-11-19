
// Used for setting the time on the map (the sky)
const float DAWN = .07;
const float MAX_DAY = .12;

// Actual game time
const u16 DEFAULT_DAY_LENGTH = 1 * 60 * getTicksASecond();
const u16 DEFAULT_NIGHT_LENGTH = 1 * 60 * getTicksASecond();

void onInit(CRules@ this)
{
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
	}
}

void onTick(CRules@ this)
{
	// Artificial day night cycle; The built in one had nights that were much too short
	CMap@ map = getMap();
	u16 phase = this.get_u16("phase");
	
	// Update the daytime
	f32 percent_passed = (1 - f32(this.get_u16("ticks_left"))/this.get_u16(phase % 2 == 0 ? "day_length" : "night_length"));
	f32 peak = phase % 2 == 0 ? MAX_DAY : 0;
	map.SetDayTime(percent_passed < 0.5f ? DAWN + percent_passed * (peak - DAWN) * 2 : peak - (percent_passed - 0.5f) * (peak - DAWN) * 2);

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
			if (isServer())
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
			if (isServer())
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
