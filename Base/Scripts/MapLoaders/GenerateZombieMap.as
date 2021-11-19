// generates from a zombie_gen config
// fileName is "" on client!

#include "LoaderUtilities.as";
#include "MinimapHook.as";

bool loadMap(CMap@ _map, const string& in filename)
{
	CMap@ map = _map;

	MiniMap::Initialise();

	if (!isServer() || filename == "")
	{
		SetupMap(map, 0, 0);
		SetupBackgrounds(map);
		return true;
	}

	Random@ map_random = Random(map.getMapSeed());

	Noise@ map_noise = Noise(map_random.Next());

	Noise@ material_noise = Noise(map_random.Next());

	//read in our config stuff -----------------------------

	ConfigFile cfg = ConfigFile(filename);

	// Zombie Variables
	s32 safezone_width = cfg.read_s32("safezone_width", 60);
	getRules().set_s32("safezone_width", safezone_width);
	s32 portal_distance_baseline = cfg.read_s32("portal_distance_baseline", 60);
	s32 portal_distance_deviation = cfg.read_s32("portal_distance_deviation", 60);

	s32 pot_frequency = cfg.read_s32("pot_frequency", 8);
	s32 gravestone_frequency = cfg.read_s32("gravestone_frequency", 15);

	// Map Variables
	s32 min_width = cfg.read_s32("min_width", 1000);
	s32 max_width = cfg.read_s32("max_width", 2000);
	s32 min_height = cfg.read_s32("min_height", 80);
	s32 max_height = cfg.read_s32("max_height", 100);

	s32 width = min_width + map_random.NextRanged(max_width - min_width);
	s32 height = min_height + map_random.NextRanged(max_height - min_height);

	s32 baseline = cfg.read_s32("baseline", 50);
	s32 baseline_tiles = height * (1.0f - (baseline / 100.0f));

	s32 deviation = cfg.read_s32("deviation", 40);

	// Erosion Variables
	s32 erode_cycles = cfg.read_s32("erode_cycles", 10);

	// Perturbation Variables
	f32 perturb = cfg.read_f32("perturb", 3.0f);
	f32 pert_scale = cfg.read_f32("pert_scale", 0.01);
	f32 pert_width = cfg.read_f32("pert_width", deviation);
	if (pert_width <= 0)
		pert_width = deviation;

	// Cave Variables
	Random@ cave_random = Random(map.getMapSeed() ^ 0xff00);
	Noise@ cave_noise = Noise(cave_random.Next());

	f32 cave_amount = cfg.read_f32("cave_amount", 0.2f);
	f32 cave_amount_var = cfg.read_f32("cave_amount_var", 0.1f);
	if (cave_amount > 0)
		cave_amount = Maths::Min(1.0f, Maths::Max(0.0f, cave_amount + cave_amount_var * (cave_random.NextFloat() - 0.5f)));

	f32 cave_scale = cfg.read_f32("cave_scale", 5.0f);
	cave_scale = 1.0f / Maths::Max(cave_scale, 0.001);

	f32 cave_detail_amp = cfg.read_f32("cave_detail_amp", 0.5f);
	f32 cave_distort = cfg.read_f32("cave_distort", 2.0f);
	f32 cave_width = cfg.read_f32("cave_width", 0.5f);
	f32 cave_lerp = cfg.read_f32("cave_lerp", 10.0f);
	if (cave_width <= 0)
		cave_width = 0;

	f32 cave_depth = cfg.read_f32("cave_depth", 20.0f);
	f32 cave_depth_var = cfg.read_f32("cave_depth_var", 10.0f);
	cave_depth += cave_depth_var * (cave_random.NextFloat() - 0.5f);

	cave_width *= width; //convert from ratio to tiles

	// Ruins Variables

	Random@ ruins_random = Random(map.getMapSeed() ^ 0x8ff000);

	s32 ruins_count = cfg.read_f32("ruins_count", 3);
	s32 ruins_count_var = cfg.read_f32("ruins_count_var", 2);
	s32 ruins_size = cfg.read_f32("ruins_size", 10);
	f32 ruins_width = cfg.read_f32("ruins_width", 0.5f);

	if (ruins_count > 0)
	{
		// do variation
		ruins_count += ruins_random.NextRanged(ruins_count_var + 1) - ruins_count_var / 2;
		//convert from ratio to tiles
		ruins_width *= width;
	}

	// Water Variables

	s32 water_baseline = cfg.read_s32("water_baseline", 0);
	s32 water_baseline_tiles = (1.0f - (water_baseline) / 100.0f) * height;

	// End Variables --------------------------------

	SetupMap(map, width, height);

	//gen heightmap
	//(generate full width to avoid clamping strangeness)
	array<int> heightmap(width);
	for (int x = 0; x < width; ++x)
	{
		heightmap[x] = baseline_tiles - deviation / 2 +
		               (map_noise.Fractal((x + 100) * 0.05, 0) * deviation);
	}

	//erode gradient

	for (int erode_cycle = 0; erode_cycle < erode_cycles; ++erode_cycle) //cycles
	{
		for (int x = 1; x < width - 1; x++)
		{
			s32 diffleft = heightmap[x] - heightmap[x - 1];
			s32 diffright = heightmap[x] - heightmap[x + 1];

			if (diffleft > 0 && diffleft > diffright)
			{
				heightmap[x] -= (diffleft + 1) / 2;
				heightmap[x - 1] += diffleft / 2;
			}
			else if (diffright > 0 && diffright > diffleft)
			{
				heightmap[x] -= (diffright + 1) / 2;
				heightmap[x + 1] += diffright / 2;
			}
			else if (diffleft == diffright && diffleft > 0)
			{
				heightmap[x] -= (diffright + 1) / 2;
				heightmap[x - 1] += (diffleft + 3) / 4;
				heightmap[x + 1] += (diffleft + 3) / 4;
			}
		}
	}

	//gen terrain
	s32 bush_skip = 0;
	s32 tree_skip = 0;
	const s32 tree_limit = 2;
	const s32 bush_limit = 3;

	array<int> naturemap(width);
	for (int x = 0; x < width; ++x)
	{
		naturemap[x] = -1; //no nature
	}

	for (int x = 0; x < width; ++x)
	{
		f32 overhang = 0;
		for (int y = 0; y < height; y++)
		{
			u32 offset = x + y * width;

			f32 midline_dist = y - heightmap[x];

			f32 midline_frac = (midline_dist + deviation / 2) / (deviation + 0.01f);

			f32 amp = Maths::Max(0.0f, perturb * Maths::Min(1.0f, 1.0f - Maths::Abs(midline_dist) / (pert_width / 2 + 0.01f)));
			f32 _n = map_noise.Fractal(x * pert_scale, y * pert_scale);

			f32 n = midline_frac * (1.0f + (_n - 0.5f) * amp);

			if (n > 0.5f)
			{
				bool add_dirt = true;

				const f32 bedrock_thresh = 1.5f;

				const f32 material_frac = (material_noise.Fractal(x * 0.1f, y * 0.1f) - 0.5f) * 2.0f;

				const f32 n_plus = n + (material_frac * 0.4f);

				f32 cave_n = 0.0f;
				if (cave_amount > 0.0f) //any chance of caves
				{
					const f32 cave_dist = Maths::Max(Maths::Abs(x - width * 0.5f) - cave_width * 0.5f + cave_lerp, 0.0f);
					const f32 cave_mul = 1.0f - (cave_dist / cave_lerp);

					if (cave_mul > 0.0f) //don't bother sampling if theres no cave
					{

						f32 target = heightmap[x] + (cave_depth * cave_mul);

						f32 mul = 1.0f - (Maths::Abs(y - target) / 10.0f) +
						          (cave_noise.Sample(x * 0.1f + 31.0f, y * 0.1f + 10.0f) - 0.5f) * cave_distort * cave_mul;

						cave_n = (cave_noise.Fractal(x * cave_scale + 132.0f, y * cave_scale * 0.1f + 993.0f) * cave_amount -
						          (cave_noise.Fractal(x * 0.1f + 31.0f, y * 0.1f + 10.0f) - 0.5f) * cave_detail_amp * 2.0f
						          + mul
						         ) * 0.5f;
					}
				}

				if (cave_n > 1.0f - cave_amount)
				{
					map.SetTile(offset, CMap::tile_ground_back);
					add_dirt = false;

					overhang -= _n * 2.0f + 0.5f;
					continue;
				}
				else if ((n > 0.55f && n_plus < bedrock_thresh - 0.2f) || n > bedrock_thresh)
				{
					add_dirt = false;

					if (material_frac < 0.7f && n > bedrock_thresh)
					{
						map.SetTile(offset, CMap::tile_bedrock);
					}
					else if (material_frac > -0.5f && material_frac < -0.25f &&
					         n_plus < 0.8f)
					{
						map.SetTile(offset, CMap::tile_gold);
					}
					else if (material_frac > 0.4f && n > 0.9f)
					{
						map.SetTile(offset, CMap::tile_thickstone);
					}
					else if (material_frac > 0.1f && n_plus > 0.8f)
					{
						map.SetTile(offset, CMap::tile_stone);
					}
					else
					{
						add_dirt = true;
					}
				}

				if (add_dirt)
				{
					map.SetTile(offset, CMap::tile_ground);
					if (overhang == 0 && y > 1)
					{
						naturemap[x] = y;
					}
				}

				overhang = 10.0f;
			}
			else if (overhang > 0.3f)
			{
				overhang -= _n * 2.0f + 0.5f;
				map.SetTile(offset, CMap::tile_ground_back);
			}
		}
	}

	for (int i = 0; i < ruins_count; i++)
	{
		int type = ruins_random.NextRanged(3);

		f32 _offset = (ruins_random.NextFloat() - 0.5f);

		s32 x = (width * 0.5f) + s32(_offset * ruins_width);

		s32 _size = ruins_size + ruins_random.NextRanged(ruins_size / 2) - ruins_size / 4;

		x -= _size / 2;

		//first pass -get minimum alt
		s32 floor_height = 0;
		for (int x_step = 0; x_step < _size; ++x_step)
		{
			s32 _x = Maths::Min(width - 1, Maths::Max(0, x + x_step));
			floor_height = Maths::Max(heightmap[_x] + 1, floor_height);
		}


		const int _roofheight = 3 + ruins_random.NextRanged(2);

		for (int x_step = 0; x_step < _size; ++x_step)
		{
			bool is_edge = (x_step == 0 || x_step == _size - 1);

			s32 _x = Maths::Min(width - 1, Maths::Max(0, x + x_step));
			u32 offset = _x + floor_height * width;

			naturemap[_x] = -1;

			if (ruins_random.NextRanged(10) > 3)
				map.SetTile(offset, CMap::tile_castle);

			int _upheight = (ruins_random.NextRanged(_roofheight + 1) +
			                 ruins_random.NextRanged(_roofheight + 1) +
			                 ruins_random.NextRanged(_roofheight + 1) + 4) / 3;
			int _upoffset = offset - width;
			for (int _upstep = 1;
			        //upwards stepping		or underground
			        (_upstep < _upheight || floor_height - _upstep + 1 > heightmap[_x])
			        && _upoffset > 0;

			        ++_upstep)
			{

				TileType solidtile, backtile;

				switch (type)
				{
					//wooden
					case 1:
						solidtile = CMap::tile_wood;
						backtile = CMap::tile_wood_back;
						break;

					//random each time
					case 2:
						if (ruins_random.NextRanged(2) == 0)
						{
							solidtile = CMap::tile_castle;
							backtile = CMap::tile_castle_back;
						}
						else
						{
							solidtile = CMap::tile_wood;
							backtile = CMap::tile_wood_back;
						}
						break;

					//stone
					case 0:
					default:
						solidtile = CMap::tile_castle;
						backtile = CMap::tile_castle_back;
						break;
				}

				if (_upstep == _roofheight)
				{
					map.SetTile(_upoffset, solidtile);
					break;
				}
				else if (is_edge)
				{
					map.SetTile(_upoffset, solidtile);
				}
				else if (_upstep < _upheight)
				{
					map.SetTile(_upoffset, backtile);
				}
				else
				{
					map.SetTile(_upoffset, CMap::tile_ground_back);
				}
				_upoffset -= width;
			}
		}
	}

	//END generating tiles - refining pass

	for (int y = 0; y < height; ++y)
	{
		for (int x = 0; x < width; ++x)
		{
			u32 offset = (x) + (y * width);
			u32 mirror_offset = (width - 1 - x) + (y * width);
			TileType t = map.getTile(offset).type;

			//and write in water if needed
			if(!map.isTileSolid(t) && y > water_baseline_tiles)
			{
				map.server_setFloodWaterOffset(offset, true);
			}
		}
	}


	//START generating blobs
	for (int x = 0; x < width; ++x)
	{
		if (naturemap[x] == -1)
			continue;


		int y = naturemap[x];

		//underwater?
		if(y > water_baseline_tiles)
			continue;

		u32 offset = x + y * width;
		u32 mirror_offset = (width - 1 - x) + y * width;

		f32 grass_frac = material_noise.Fractal(x * 0.02f, y * 0.02f);
		if (grass_frac > 0.5f)
		{
			bool spawned = false;
			//generate vegetation
			if (x % 7 == 0 || x % 23 == 3)
			{
				f32 _g = map_random.NextFloat();

				Vec2f pos = (Vec2f(x, y - 1) * map.tilesize) + Vec2f(4.0f, 4.0f);
				Vec2f mirror_pos = (Vec2f(width - 1 - x, y - 1) * map.tilesize) + Vec2f(4.0f, 4.0f);

				if (tree_skip < tree_limit &&
				        (_g > 0.5f || bush_skip > bush_limit))  //bush
				{
					bush_skip = 0;
					tree_skip++;

					SpawnBush(map, pos);

					spawned = true;
				}
				else if (tree_skip >= tree_limit || _g > 0.25f)  //tree
				{
					tree_skip = 0;
					bush_skip++;

					SpawnTree(map, pos, y < baseline_tiles);

					spawned = true;
				}
			}

			//todo grass control random
			TileType grass_tile = CMap::tile_grass + (spawned ? 0 : map_random.NextRanged(4));
			map.SetTile(offset - width, grass_tile);
		}
	}

	// Define the safezone in the middle of the map where players start
	s32 middle = map.tilemapwidth / 2;

	// Generate portals
	u8 portal_count = 0;

	// To the left of the safezone
	u8 portal_edge_distance = 20;  // How close can a portal get to the edge of the map in tiles
	for (s32 x = middle - (safezone_width / 2 + portal_distance_baseline + map_random.NextRanged(portal_distance_deviation));
		x > portal_edge_distance;
		x -= (portal_distance_baseline + map_random.NextRanged(portal_distance_deviation))
	)
	{
		SpawnPortal(x);
		portal_count++;
	}

	// To the right of the safezone
	for (s32 x = middle + safezone_width / 2 + portal_distance_baseline + map_random.NextRanged(portal_distance_deviation);
		x < map.tilemapwidth - portal_edge_distance;
		x += portal_distance_baseline + map_random.NextRanged(portal_distance_deviation)
	)
	{
		SpawnPortal(x);
		portal_count++;
	}

	// Spawn lootables
	for (s32 x = 0; x < map.tilemapwidth; x += 2)
	{
		if (map_random.NextRanged(pot_frequency) == 0)
		{
			u32 random_pot = map_random.NextRanged(100);
			string pot_choice = "";
			if (random_pot < 60)
			{
				pot_choice = "potcombat";
			}
			else if (random_pot < 90)
			{
				pot_choice = "potbuilder";
			}
			else
			{
				pot_choice = "potrare";
			}
			
			server_CreateBlob(pot_choice, 3, Vec2f(x, map.getLandYAtX(x)) * map.tilesize);
		}
		else if (map_random.NextRanged(gravestone_frequency) == 0)
		{
			CBlob@ gravestone = server_CreateBlob("gravestone");
			if (gravestone !is null)
			{
				gravestone.server_setTeamNum(3);
				gravestone.setPosition(Vec2f(x, map.getLandYAtX(x) - 2) * map.tilesize);
				gravestone.Init();
			}
		}
	}

	SetupBackgrounds(map);
	return true;
}

CBlob@ SpawnPortal(s32 x)
{
	CBlob@ portal = server_CreateBlobNoInit("portal");
	if (portal !is null)
	{
		CMap@ map = getMap();

		portal.server_setTeamNum(3);
		portal.setPosition(Vec2f(x, map.getLandYAtX(x) - 5) * map.tilesize);
		portal.Init();

		// map.SetTile(offset, CMap::tile_ground_back);
		// map.SetTile(offset, CMap::tile_ground);
	}

	return portal;
}

//spawn functions
CBlob@ SpawnBush(CMap@ map, Vec2f pos)
{
	return server_CreateBlob("bush", -1, pos);
}

CBlob@ SpawnTree(CMap@ map, Vec2f pos, bool high_altitude)
{
	CBlob@ tree = server_CreateBlobNoInit(high_altitude ? "tree_pine" : "tree_bushy");
	if (tree !is null)
	{
		tree.Tag("startbig");
		tree.setPosition(pos);
		tree.Init();
	}
	return tree;
}

void SetupMap(CMap@ map, int width, int height)
{
	map.CreateTileMap(width, height, 8.0f, "Sprites/world.png");
}

void SetupBackgrounds(CMap@ map)
{
	// sky

	map.CreateSky(color_black, Vec2f(1.0f, 1.0f), 200, "Sprites/Back/cloud", 0);
	map.CreateSkyGradient("Sprites/skygradient_normal.png");   // override sky color with gradient

	// plains

	map.AddBackground("Sprites/Back/BackgroundPlains.png", Vec2f(0.0f, 0.0f), Vec2f(0.3f, 0.3f), color_white);
	map.AddBackground("Sprites/Back/BackgroundTrees.png", Vec2f(0.0f,  19.0f), Vec2f(0.4f, 0.4f), color_white);
	//map.AddBackground( "Sprites/Back/BackgroundIsland.png", Vec2f(0.0f, 50.0f), Vec2f(0.5f, 0.5f), color_white );
	map.AddBackground("Sprites/Back/BackgroundCastle.png", Vec2f(0.0f, 50.0f), Vec2f(0.6f, 0.6f), color_white);

	// fade in
	SetScreenFlash(255, 0, 0, 0);

	SetupBlocks(map);
}

void SetupBlocks(CMap@ map)
{

}

bool LoadMap(CMap@ map, const string& in fileName)
{
	print("GENERATING ZOMBIE MAP " + fileName);

	return loadMap(map, fileName);
}
