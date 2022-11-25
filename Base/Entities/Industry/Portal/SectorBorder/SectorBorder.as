
void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	if (shape !is null)
	{
		shape.SetRotationsAllowed(false);
		shape.getConsts().mapCollisions = false;
		shape.SetGravityScale(0.0f);
	}
	this.setVelocity(Vec2f_zero);

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		u16 netID = this.getNetworkID();
		sprite.animation.frame = (netID % sprite.animation.getFramesCount());
		sprite.SetZ(10.0f);
		sprite.SetLighting(false);
	}
}
