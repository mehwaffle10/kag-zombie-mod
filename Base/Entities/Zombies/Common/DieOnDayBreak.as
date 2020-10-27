
void onInit(CBlob@ this)
{
	// Trigger on dawn
	this.Tag("day");
	this.addCommandID("day");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (getNet().isServer() && cmd == this.getCommandID("day"))
	{
		u8 seconds_until_death = 1 + XORRandom(5);
		this.server_SetTimeToDie(seconds_until_death);
		this.set_u32("time to die", getGameTime() + seconds_until_death * getTicksASecond());
		this.Sync("time to die", true);
	}
}

void onDie(CBlob@ this)
{
	// Don't do magic stuff if not killed by day
	if (this is null || Maths::Abs(getGameTime() - this.get_u32("time to die")) > 2 || this.getSprite() is null)
	{
		return;
	}

	// Make magic particles
	ParticleZombieLightning(this.getPosition());
	this.getSprite().Gib();
}
