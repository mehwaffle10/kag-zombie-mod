
void actorlimit_setup(CBlob@ this)
{
	u16[] networkIDs;
	this.set("LimitedActors", networkIDs);
}

bool has_hit_actor(CBlob@ this, CBlob@ actor)
{
	u16[]@ networkIDs;
	this.get("LimitedActors", @networkIDs);
	return networkIDs.find(actor.getNetworkID()) >= 0;
}

u32 hit_actor_count(CBlob@ this)
{
	u16[]@ networkIDs;
	this.get("LimitedActors", @networkIDs);
	return networkIDs.length;
}

void add_actor_limit(CBlob@ this, CBlob@ actor)
{
	this.push("LimitedActors", actor.getNetworkID());
}

void clear_actor_limits(CBlob@ this)
{
	this.clear("LimitedActors");
}

CBlob@ getTarget(CBlob@ this, bool chaseLight)
{
	CMap@ map = getMap();
	CBlob@[] blobsInRadius;

	if(map.getBlobsInRadius(this.getPosition(), 10 * map.tilesize, @blobsInRadius))
	{
		if (chaseLight)
		{
			// Look for light sources first
			for(uint i = 0; i < blobsInRadius.length; i++)
			{
				if (blobsInRadius[i] !is null && !blobsInRadius[i].hasTag("player") && blobsInRadius[i].isLight() && blobsInRadius[i].getName() != "portal") 
				{
					return blobsInRadius[i];
				}
			}
		}
		
		// Look for players or structures to attack
		for(uint i = 0; i < blobsInRadius.length; i++)
		{
			if (blobsInRadius[i] !is null && (blobsInRadius[i].hasTag("player") || blobsInRadius[i].hasTag("building")) && blobsInRadius[i].getTeamNum() != this.getTeamNum())
			{
				return blobsInRadius[i];
			}
		}
	}

	return null;
}
