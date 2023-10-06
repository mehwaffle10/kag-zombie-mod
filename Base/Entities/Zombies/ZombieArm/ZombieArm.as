
#include "Hitters.as";
#include "RunnerCommon.as";
#include "ShieldCommon.as";
#include "KnockedCommon.as";
#include "ParticleSparks.as";
#include "ZombieCommon.as";

//attacks limited to the one time per-actor before reset.

namespace State
{
	enum state_type
	{
		idle = 0,
		run,
		charging,
		sprang,
		blocked
	};
};

void onInit(CBlob@ this)
{
	// Spawn sound
	if (XORRandom(1) == 0)
	{
		this.getSprite().PlaySound("ZombieHit.ogg");
	}

	RunnerMoveVars moveVars;
	//walking vars
	moveVars.walkSpeed = 2.6f;
	moveVars.walkSpeedInAir = 2.5f;
	moveVars.walkFactor = 1.0f;
	moveVars.walkLadderSpeed.Set(0.15f, 0.6f);
	//jumping vars
	moveVars.jumpMaxVel = 2.9f;
	moveVars.jumpStart = 1.0f;
	moveVars.jumpMid = 0.55f;
	moveVars.jumpEnd = 0.4f;
	moveVars.jumpFactor = 1.0f;
	moveVars.jumpCount = 0;
	moveVars.canVault = true;
	//swimming
	moveVars.swimspeed = 1.2;
	moveVars.swimforce = 30;
	moveVars.swimEdgeScale = 2.0f;
	//the overall scale of movement
	moveVars.overallScale = 0.05f;
	//stopping forces
	moveVars.stoppingForce = 0.80f; //function of mass
	moveVars.stoppingForceAir = 0.30f; //function of mass
	moveVars.stoppingFactor = 1.0f;
	//
	moveVars.walljumped = false;
	moveVars.walljumped_side = Walljump::NONE;
	moveVars.wallclimbing = false;
	moveVars.wallsliding = false;
	//
	this.set("moveVars", moveVars);
	this.getShape().getVars().waterDragScale = 30.0f;
	this.getShape().getConsts().collideWhenAttached = true;

	// Make it so builders don't highlight on hit
	this.Tag("flesh");

	// Make them stompable
	this.Tag("player");

	// Setup knocked
	InitKnockable(this);

	// For limiting to one hit per attack
	actorlimit_setup(this);

	// State for anims/action sync
	this.set_u8("state", State::idle);
	this.Sync("state", true);
	this.set_u16("state timer", 0);
}

// Blame Fuzzle.
bool canHit(CBlob@ this, CBlob@ b)
{
	if (b.hasTag("invincible"))
		return false;

	// Don't hit temp blobs and items carried by teammates.
	if (b.isAttached())
	{

		CBlob@ carrier = b.getCarriedBlob();

		if (carrier !is null)
			if (carrier.hasTag("player")
			        && (this.getTeamNum() == carrier.getTeamNum() || b.hasTag("temp blob")))
				return false;
	}

	if (b.hasTag("dead"))
		return true;

	return b.getTeamNum() != this.getTeamNum();
}

void onTick(CBlob@ this)
{
	// print("" + this.exists("LimitedActors"));
	u8 state = this.get_u8("state");
	CSprite@ sprite = this.getSprite();

	if (getNet().isClient())
	{
		// Update anims
		if (state == State::idle && !sprite.isAnimation("idle"))
		{
			sprite.SetAnimation("idle");
		}
		else if (state == State::run && !sprite.isAnimation("run"))
		{
			sprite.SetAnimation("run");
		}
		else if (state == State::charging && !sprite.isAnimation("charging"))
		{
			sprite.SetAnimation("charging");
		}
		else if (state == State::sprang && !sprite.isAnimation("sprang"))
		{
			sprite.SetAnimation("sprang");
			sprite.PlaySound("thud.ogg");
		}
		else if (state == State::blocked && !sprite.isAnimation("blocked"))
		{
			sprite.SetAnimation("blocked");
			sprite.PlaySound("ShieldHit.ogg");
			sparks(this.getPosition(), 90.0f, 0.25f);
		}
	}

	// Update direction that we're facing (it's backwards for some reason)
	if (this.getAimPos().x < this.getPosition().x)
	{
		this.SetFacingLeft(false);
	}
	else
	{
		this.SetFacingLeft(true);
	}

	// Makes sure the client and server are doing the same thing
	if (!getNet().isServer())
	{
		return;
	}

	// Find closest player
	CMap@ map = getMap();
	CBlob@[] blobsInRadius;
	CBlob@ target = getTarget(this, true);

	// State logic
	u16 state_timer = this.get_u16("state timer");
	if (state_timer > 0)
	{
		this.set_u16("state timer", --state_timer);
	}

	// Update knocked state
	DoKnockedUpdate(this);

	// Attempt to hit things
	if (this.get_u8("state") == State::sprang)
	{
		CBlob@[] overlapping;
		this.getOverlapping(@overlapping);

		for (uint i = 0; i < overlapping.length; i++)
		{
			f32 dmg = .25f;
			CBlob@ blob = overlapping[i];

			if (blob !is null && canHit(this, blob) && !has_hit_actor(this, blob))
			{
				Vec2f vel = blob.getPosition() - this.getPosition();
				if (blockAttack(overlapping[i], vel, dmg))
				{
					this.set_u8("state", State::blocked);
					this.Sync("state", true);
					this.set_u16("state timer", 0);
				}
				else
				{
					add_actor_limit(this, blob);
					this.server_Hit(blob, this.getPosition(), Vec2f(0,0), dmg, Hitters::bite, false);
				}
			}
		}
	}

	// Attack logic
	if ((state == State::idle || state == State::run) && state_timer == 0)
	{
		// Attack if in range
		if (target !is null)
		{
			Vec2f dif = this.getPosition() - target.getPosition();
			bool facingLeft = this.isFacingLeft();
			if (Maths::Abs(dif.y) < 2 * map.tilesize && (!facingLeft && dif.x < 3 * map.tilesize && dif.x > 0 || facingLeft && dif.x > -3 * map.tilesize && dif.x < 0))
			{
				// Stop moving
				this.setKeyPressed(key_left, false);
				this.setKeyPressed(key_right, false);

				// Update state to start attacking
				this.set_u8("state", State::charging);
				this.Sync("state", true);
				this.set_u16("state timer", 1.5 * getTicksASecond());
				// We don't want the aimpos or anim to be updated from the code below
				return;
			}
		}
	}
	else
	{
		if (state == State::charging)
		{
			// Reset if midair
			if (!this.isOnGround() && !this.isOnLadder())
			{
				this.set_u8("state", State::idle);
				this.Sync("state", true);
				this.set_u16("state timer", 0);
			}
			else if (state_timer == 0) // Attack if ready
			{
				this.set_u8("state", State::sprang);
				this.Sync("state", true);
				this.set_u16("state timer", .5 * getTicksASecond());

				// Launch through the air toward target
				if (this.getAimPos().x < this.getPosition().x)
				{
					this.setVelocity(Vec2f(-3, -3));
				}
				else
				{
					this.setVelocity(Vec2f(3, -3));	
				}
			}	
		}
		else if ((state == State::sprang || state == State::blocked) && state_timer == 0 && (this.isOnGround() || this.isOnLadder()))
		{
			this.set_u8("state", State::idle);
			this.Sync("state", true);
			clear_actor_limits(this);
		}

		// We don't want the aimpos or anim to be updated from the code below
		return;
	}

	// Follow target if present, otherwise march towards mid
	bool leftOfTarget;
	if (target !is null)
	{
		leftOfTarget = this.getPosition().x - target.getPosition().x < 0;
		this.setAimPos(target.getPosition());
	}
	else
	{
		Vec2f mid = Vec2f(map.tilemapwidth * map.tilesize / 2, this.getPosition().y);
		leftOfTarget = this.getPosition().x - mid.x < 0;
		this.setAimPos(mid);
	}

	if (leftOfTarget)
	{
		// Walk right
		this.setKeyPressed(key_left, false);
		this.setKeyPressed(key_right, true);
	}
	else
	{
		// Walk left
		this.setKeyPressed(key_right, false);
		this.setKeyPressed(key_left, true);
	}

	// Update State
	if (!this.isOnGround() || this.getVelocity().Length() < .1f)
	{
		this.set_u8("state", State::idle);
		this.Sync("state", true);
	}
	else
	{
		this.set_u8("state", State::run);
		this.Sync("state", true);
	}
}

void onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (damage > 0)
	{
		this.getSprite().PlaySound("ZombieHit.ogg");
	}

	this.set_u8("state", State::idle);
	this.Sync("state", true);
	this.set_u16("state timer", 3);
}

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("ZombieHit.ogg");
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return this.getTeamNum() != blob.getTeamNum();
}
