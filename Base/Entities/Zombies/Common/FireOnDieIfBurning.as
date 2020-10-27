
// Explodes into fire on death if on fire
void onDie(CBlob@ this)
{
	if (this.hasTag("burning"))
	{
		u8 radius = this.exists("Fire Death Radius") ? this.get_u8("Fire Death Radius") : 1;
		CMap@ map = getMap();
		Vec2f pos = this.getPosition();

		// Create cross of fire
		for (int y = 0; y <= radius; y++)
		{
			for (int x = 0; x <= radius - y; x++)
			{

				// Ignite 4 corners
				Vec2f[] positions = {
					Vec2f(pos.x + x * map.tilesize, pos.y + y * map.tilesize),
					Vec2f(pos.x - x * map.tilesize, pos.y + y * map.tilesize),
					Vec2f(pos.x + x * map.tilesize, pos.y - y * map.tilesize),
					Vec2f(pos.x - x * map.tilesize, pos.y - y * map.tilesize)
				};

				for (int i = 0; i < positions.length; i++)
				{
					ParticleAnimated("FireFlash.png", positions[i], Vec2f(0, 0.5f), 0.0f, 1.0f, 2, 0.0f, true);
					map.server_setFireWorldspace(positions[i], true);
				}
			}
		}

		// Play sound
		this.getSprite().PlaySound("Bomb.ogg");
	}
}