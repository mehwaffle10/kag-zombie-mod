
namespace State
{
	enum state_type
	{
		inactive = 0,
		active
	};
};

void onInit(CBlob@ this)
{
	this.set_u16("spawn_delay", 15 * getTicksASecond());
	this.set_u16("spawn_timer", 0);
	this.set_u16("points_per_day", 10);
	this.set_u16("points", 0);
	this.set_u8("state", State::inactive);
	this.set_string("rank", "basic");
	this.SetLight(true);

	// State changes for day/night
	this.Tag("day");
	this.addCommandID("day");
	this.Tag("night");
	this.addCommandID("night");
}

void UpdateAnim(CBlob@ this)
{
	CSprite@ sprite = this.getSprite();
	u8 state = this.get_u8("state");
	if (state == State::inactive && !sprite.isAnimation("inactive"))
	{
		sprite.SetAnimation("closed");
		this.SetLightRadius(this.getRadius() * 1.1f);
	}
	else if (state == State::active && !sprite.isAnimation("active"))
	{
		sprite.SetAnimation("open");
		this.SetLightRadius(this.getRadius() * 1.5f);
	}
}

void onTick(CBlob@ this)
{	
	if (this.get_u8("state") == State::active)
	{
		u16 points = this.get_u16("points");
		u16 points_per_day = this.get_u16("points_per_day");

		string rank = this.get_string("rank");
		u16 spawn_timer = this.get_u16("spawn_timer");
		u16 spawn_delay = this.get_u16("spawn delay");

		u8 action = XORRandom(100);

		u8 skeleton_cost = 1;
		u8 zombie_cost = 3;
		u8 upgrade_cost = 10;

		// Close if we're out of points
		if (points == 0)
		{
			this.set_u8("state", State::inactive);
			this.Sync("state", true);
			UpdateAnim(this);
			return;
		}

		// Try to spend points
		if (spawn_timer == 0)
		{
			if (rank == "basic")
			{
				if (action < 70) // Spawn skeleton
				{
					if (points >= skeleton_cost)
					{
						Summon(this, "skeleton", skeleton_cost);
					}
				}
				else if (action >= 70 && action < 95) // Spawn zombie
				{
					if (points >= zombie_cost)
					{
						Summon(this, "log", zombie_cost);
					}
				}
				else // 95 <= action < 100 // Upgrade to advanced
				{
					if (points >= upgrade_cost)
					{
						this.set_u16("points", points - upgrade_cost);
						this.set_u16("spawn_timer", spawn_delay);

						this.set_u16("points_per_day", points_per_day * 2);
						this.set_string("rank", "advanced");
					}
				}
			}
		}
		else
		{
			this.set_u16("spawn_timer", spawn_timer - 1);
		}
	}
}

void Summon(CBlob@ this, string spawn, u8 cost)
{
	if (getNet().isServer())
	{
		this.set_u16("points", this.get_u16("points") - cost);
		this.Sync("points", true);
		this.set_u16("spawn_timer", this.get_u16("spawn_delay"));

		if (XORRandom(2) == 0)
		{
			this.getSprite().PlaySound("Thunder1.ogg");
		}
		else
		{
			this.getSprite().PlaySound("Thunder2.ogg");
		}

		CBlob@ b = server_CreateBlob(spawn, this.getTeamNum(), this.getPosition());
		b.AddScript("DieOnDayBreak.as");
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	/*
	if (!canSeeButtons(this, caller)) return;

	if (this.isOverlapping(caller))
		this.set_bool("shop available", !builder_only || caller.getName() == "builder");
	else
		this.set_bool("shop available", false);
	*/
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("day"))
	{
		// Turn off and award points for the day
		if (getNet().isServer())
		{
			this.set_u8("state", State::inactive);
			this.Sync("state", true);
			this.set_u16("points", this.get_u16("points") + this.get_u16("points_per_day"));
			this.Sync("points", true);
		}

		UpdateAnim(this);
	}
	else if (cmd == this.getCommandID("night"))
	{
		// Activate! It's night time
		if (getNet().isServer())
		{
			this.set_u8("state", State::active);
			this.Sync("state", true);

			// Give portals a random spawn timer so that they don't all spawn at the same time
			this.set_u16("spawn_timer", XORRandom(this.get_u16("spawn_delay")));
		}

		UpdateAnim(this);
	}
}
