
#include "Hitters.as";
#include "RunnerCommon.as";
#include "KnockedCommon.as";
#include "ZombieCommon.as";

//attacks limited to the one time per-actor before reset.

namespace State
{
	enum state_type
	{
		idle = 0,
		run,
		fall,
		charging,
		swinging,
		swung,
		stunned
	};
};

void onInit(CBlob@ this)
{
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
	moveVars.overallScale = 1.0f;
	//stopping forces
	moveVars.stoppingForce = 0.80f; //function of mass
	moveVars.stoppingForceAir = 0.30f; //function of mass
	moveVars.stoppingFactor = 1.0f;
	//
	moveVars.walljumped = false;
	moveVars.walljumped_side = Walljump::NONE;
	moveVars.wallrun_length = 2;
	moveVars.wallrun_start = -1.0f;
	moveVars.wallrun_current = -1.0f;
	moveVars.wallclimbing = false;
	moveVars.wallsliding = false;
	//
	this.set("moveVars", moveVars);
	this.getShape().getVars().waterDragScale = 30.0f;
	this.getShape().getConsts().collideWhenAttached = true;

	// Spawn sound
	if (XORRandom(2) == 0)
	{
		this.getSprite().PlaySound("SkeletonSpawn1.ogg");
	}
	else
	{
		this.getSprite().PlaySound("SkeletonSpawn2.ogg");
	}

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

	// For ExplodeOnDie.as
	this.set_f32("explosive_radius", 64.0f);
	this.set_f32("explosive_damage", 3.0f);
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
	// Find closest player
	CMap@ map = getMap();
	CSprite@ sprite = this.getSprite();
	CBlob@[] blobsInRadius;
	CBlob@ target = getTarget(this, true);

	// State logic
	u8 state = this.get_u8("state");
	u16 state_timer = this.get_u16("state timer");

	if (getNet().isServer())
	{
		if (state_timer > 0)
		{
			this.set_u16("state timer", --state_timer);
			this.Sync("state timer", true);
		}
	
		// Update knocked state
		DoKnockedUpdate(this);
	}

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
		else if (state == State::fall && !sprite.isAnimation("fall"))
		{
			sprite.SetAnimation("fall");
		}
		else if (state == State::charging && !sprite.isAnimation("charging"))
		{
			sprite.SetAnimation("charging");
		}
		else if ((state == State::swinging || state == State::swung) && !sprite.isAnimation("swung"))
		{
			sprite.SetAnimation("swung");
			sprite.PlaySound("SkeletonAttack.ogg");
		}
		else if (state == State::stunned && !sprite.isAnimation("stunned"))
		{
			sprite.SetAnimation("stunned");
			return;
		}
	}

	// Explode on die
	if (this.hasTag("burning") && !this.hasTag("exploding"))
	{
		sprite.PlaySound("SkeletonSayDuh.ogg");
		this.Tag("exploding");
	}
	else if (!this.hasTag("burning") && this.hasTag("exploding"))
	{
		this.Untag("exploding");
	}

	// Make stuns work
	if (isKnocked(this) || this.hasTag("dazzled"))
	{
		if (getNet().isServer())
		{
			this.set_u8("state", State::stunned);
			this.Sync("state", true);
			this.set_u16("state timer", 0);
			this.setKeyPressed(key_left, false);
			this.setKeyPressed(key_right, false);
			this.setKeyPressed(key_up, false);
			this.set_u8("hold jump", 0);
		}
		return;
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

	// Attack logic
	if (state != State::charging && state != State::swinging && state != State::swung)
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
				this.setKeyPressed(key_up, false);

				// Update state to start attacking
				this.set_u8("state", State::charging);
				this.Sync("state", true);
				this.set_u16("state timer", .5 * getTicksASecond());

				// We don't want the aimpos or anim to be updated from the code below
				return;
			}
		}
	}
	else
	{
		if (state == State::charging && state_timer == 0)
		{
			this.set_u8("state", State::swinging);
			this.Sync("state", true);
		}
		else if (state == State::swinging)
		{
			DoAttack(this, .25f, this.isFacingLeft() ? 0.0f : 180.0f, 60.0f, Hitters::bite);
			this.set_u8("state", State::swung);
			this.Sync("state", true);
			this.set_u16("state timer", .25 * getTicksASecond());
		}
		else if (state == State::swung && state_timer == 0)
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
	

	// Jump if terrain is in the way or if we're on a ladder and below our target and have a chance to randomly jump
	u8 hold_jump = this.get_u8("hold jump");
	if (Maths::Abs(this.getVelocity().x) < .1f && hold_jump == 0 || target !is null && target.getPosition().y < this.getPosition().y && this.isOnLadder() || XORRandom(30) == 0 && hold_jump == 0)
	{
		this.setKeyPressed(key_up, true);
		this.set_u8("hold jump", 10);
	}

	// Stop holding jump
	if (hold_jump > 0)
	{
		hold_jump -= 1;
		this.set_u8("hold jump", hold_jump);
		if (hold_jump == 0)
		{
			this.setKeyPressed(key_up, false);
		}	
	}

	// Update State
	if (!this.isOnGround())
	{
		this.set_u8("state", State::fall);
		this.Sync("state", true);
	}
	else if (this.getVelocity().Length() < .1f)
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

void DoAttack(CBlob@ this, f32 damage, f32 aimangle, f32 arcdegrees, u8 type)
{
	if (!getNet().isServer())
	{
		return;
	}

	Vec2f blobPos = this.getPosition();
	Vec2f vel = this.getVelocity();
	Vec2f thinghy(1, 0);
	thinghy.RotateByDegrees(aimangle);
	Vec2f pos = blobPos - thinghy * 6.0f + vel + Vec2f(0, -2);
	vel.Normalize();

	f32 radius = this.getRadius();
	CMap@ map = this.getMap();
	bool dontHitMore = false;
	bool dontHitMoreMap = false;

	f32 attack_distance = 2 * map.tilesize;

	// this gathers HitInfo objects which contain blob or tile hit information
	HitInfo@[] hitInfos;
	if (map.getHitInfosFromArc(pos, aimangle, arcdegrees, radius + attack_distance, this, @hitInfos))
	{
		//HitInfo objects are sorted, first come closest hits
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;
			if (b !is null && !dontHitMore) // blob
			{
				if (b.hasTag("ignore sword")) continue;

				//big things block attacks
				const bool large = b.hasTag("blocks sword") && !b.isAttached() && b.isCollidable();

				if (!canHit(this, b))
				{
					// no TK
					if (large)
						dontHitMore = true;

					continue;
				}

				if (has_hit_actor(this, b))
				{
					if (large)
						dontHitMore = true;

					continue;
				}

				add_actor_limit(this, b);

				if (!dontHitMore)
				{
					Vec2f velocity = b.getPosition() - pos;
					this.server_Hit(b, hi.hitpos, velocity, damage, type, false);  // server_Hit() is server-side only

					// end hitting if we hit something solid, don't if its flesh
					if (large)
					{
						dontHitMore = true;
					}
				}
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	KnockedCommands(this, cmd, params);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	this.getSprite().PlaySound("SkeletonHit.ogg");
	makeGibParticle("ZombieGibs.png", this.getPosition(), -velocity, 0, XORRandom(3) * 2 + 4, Vec2f(8, 8), 1.0f, 0, XORRandom(2) == 1 ? "bone_fall1.ogg" : "bone_fall2.ogg", this.getTeamNum());
	setKnocked(this, 1 * getTicksASecond(), true);

	return damage;
}

void onDie(CBlob@ this)
{
	this.getSprite().PlaySound("SkeletonBreak1.ogg");
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return this.getTeamNum() != blob.getTeamNum();
}