
void onRender(CRules@ this)
{
	CMap@ map = getMap();
	f32 time = map.getDayTime();
	u16 ticks_left = this.get_u16("ticks_left");
	u16 phase = this.get_u16("phase");
	Vec2f pos = Vec2f(20, 10);

	string str;
	if (phase % 2 == 0)
	{
		str = "Day ";
	}
	else
	{
		str = "Night ";
	}
	str +=  phase / 2 + 1;
	str += "\n\n" + (ticks_left / getTicksASecond()) / 60 + ":"; 

	u16 seconds = (ticks_left / getTicksASecond()) % 60;
	if (seconds < 10)
	{
		str += "0";
	}
	str += seconds;

	GUI::DrawText(str, pos, SColor(0xffffffff));
}