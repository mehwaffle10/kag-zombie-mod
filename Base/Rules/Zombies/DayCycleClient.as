
#define CLIENT_ONLY

u16 ticks_left = 0;
u16 phase = 0;

void onInit(CRules@ this)
{
	this.addCommandID("set_phase");
	this.addCommandID("do_laugh");

	if (!GUI::isFontLoaded("snes"))
	{
		string snes = CFileMatcher("snes.png").getFirst();
		GUI::LoadFont("snes", snes, 22, true);
	}
}

void onTick(CRules@ this)
{
	// Artificial day night cycle; The built in one had nights that were much too short
	CMap@ map = getMap();
	u16 DAWN = this.get_u16("dawn");

	// Update the daytime
	f32 percent_passed = (1 - f32(ticks_left)/this.get_u16(phase % 2 == 0 ? "day_length" : "night_length"));
	f32 peak = phase % 2 == 0 ? this.get_u16("max_day") : 0;
	map.SetDayTime(percent_passed < 0.5f ? DAWN + percent_passed * (peak - DAWN) * 2 : peak - (percent_passed - 0.5f) * (peak - DAWN) * 2);

	// Update timer
	if (ticks_left > 0)
	{
		ticks_left--;
	}
}

void onRender(CRules@ this)
{
	GUI::SetFont("snes");
	CMap@ map = getMap();
	
	Vec2f pos = Vec2f(10, getScreenHeight() - 50);
	GUI::DrawText((phase % 2 == 0 ? "Day " : "Night ") + (phase / 2 + 1), pos, SColor(0xffffffff));

	pos.y += 17;
	u16 seconds = (ticks_left / getTicksASecond()) % 60;
	GUI::DrawText("" + (ticks_left / getTicksASecond()) / 60 + ":" + (seconds < 10 ? "0" : "") + seconds, pos, SColor(0xffffffff));
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("set_phase"))
	{
		// Set the phase and ticks left
		u16 _phase;
		if (!params.saferead_u16(_phase))
		{
			return;
		}

		u16 _ticks_left;
		if (!params.saferead_u16(_ticks_left))
		{
			return;
		}

		phase = _phase;
		ticks_left = _ticks_left;
	}
	else if (cmd == this.getCommandID("do_laugh"))
	{
		// Evil laugh when turning night
		u8 laugh_index;
		if (!params.saferead_u8(laugh_index))
		{
			return;
		}

		string fileName;
		switch (laugh_index)
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
}
