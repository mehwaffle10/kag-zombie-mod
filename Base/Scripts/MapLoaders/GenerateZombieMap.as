// generates from a zombie_gen config
// fileName is "" on client!

#include "LoaderUtilities.as"
#include "CustomBlocks.as"
#include "PNGLoader.as"
#include "PathFindingCommon.as"
#include "ZombiesMinimapCommon.as"
#include "ZombiesMinimapSectorNames.as"

s32 pot_frequency;
s32 gravestone_frequency;
s32 boulder_frequency;
s32 baseline_tiles;

bool loadMap(CMap@ _map, const string& in filename)
{
	CMap@ map = _map;
	CRules@ rules = getRules();
	rules.set_u8("portal_count", 0);
	// MiniMap::Initialise();

	if (!isServer() || filename == "")
	{
		SetupMap(map, 0, 0);
		SetupBackgrounds(map);
		return true;
	}

	if (!map.hasScript("PathFindingMapUpdates"))
	{
		map.AddScript("PathFindingMapUpdates");
	}

	map.set_bool("Update Nodes", false);

	Random@ map_random = Random(map.getMapSeed());
	// TODO display map seed somewhere

	Noise@ map_noise = Noise(map_random.Next());

	Noise@ material_noise = Noise(map_random.Next());

	//read in our config stuff -----------------------------

	ConfigFile cfg = ConfigFile(filename);

	// Zombie Variables
	s32 sector_size_baseline = cfg.read_s32("sector_size_baseline", 80);
	s32 sector_size_deviation = cfg.read_s32("sector_size_deviation", 40);

	pot_frequency = cfg.read_s32("pot_frequency", 8);
	gravestone_frequency = cfg.read_s32("gravestone_frequency", 15);
	boulder_frequency = cfg.read_s32("boulder_frequency", 20);

	// Map Variables
	s32 min_width = cfg.read_s32("min_width", 1000);
	s32 max_width = cfg.read_s32("max_width", 2000);
	s32 min_height = cfg.read_s32("min_height", 80);
	s32 max_height = cfg.read_s32("max_height", 100);

	s32 width = min_width + map_random.NextRanged(max_width - min_width);
	s32 height = min_height + map_random.NextRanged(max_height - min_height);

	s32 baseline = cfg.read_s32("baseline", 50);
	baseline_tiles = height * (1.0f - (baseline / 100.0f));

	s32 deviation = cfg.read_s32("deviation", 40);

	// Erosion Variables
	s32 erode_cycles = cfg.read_s32("erode_cycles", 10);

	// Perturbation Variables
	f32 perturb = cfg.read_f32("perturb", 3.0f);
	f32 perturb_scale = cfg.read_f32("perturb_scale", 0.01);
	f32 perturb_width = cfg.read_f32("perturb_width", deviation);
	if (perturb_width <= 0)
		perturb_width = deviation;

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
	
	int[] heightmap(width);
	for (int x = 0; x < width; ++x)
	{
		heightmap[x] = baseline_tiles - deviation / 2 +
		               (map_noise.Fractal((x + 100) * 0.05, 0) * deviation);
	}

	//erode gradient
	Erode(erode_cycles, heightmap);

	//gen terrain
	int[] naturemap(width);
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

			f32 amp = Maths::Max(0.0f, perturb * Maths::Min(1.0f, 1.0f - Maths::Abs(midline_dist) / (perturb_width / 2 + 0.01f)));
			f32 _n = map_noise.Fractal(x * perturb_scale, y * perturb_scale);

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

	/*
	// DEV - Spawn all single structure type
	s32 middle = map.tilemapwidth / 2;
	for (u8 count = 0; count <= 4; count++)
	{
		s32 x = middle - 20 + count * 50;
		SpawnStructure(map, naturemap, map_random, false, "big_" + count, x, 6, 3);
	}
	*/
	/*
	// DEV - Check a mirrored image
	s32 middle = map.tilemapwidth / 2;
	for (u8 count = 0; count < 2; count++)
	{
		s32 x = middle - 20 + count * 32;
		u8 structure_width = SpawnStructure(map, naturemap, map_random, count % 2 == 1, "mineshaft_entrance_6", x, 6, 3);
		// Test set top left to gold
		for (int y = 0; y < 30; y++)
		{
			map.server_SetTile(Vec2f(x, y) * map.tilesize, CMap::tile_gold);
			map.server_SetTile(Vec2f(x + structure_width, y) * map.tilesize, CMap::tile_wood);
		}
	}
	*/
	// Divide the map into sectors. A sector has one portal and potentially structures
	Vec2f[] sectors;
	s32 left_x = 0;
	s32 border = map.tilemapwidth - sector_size_baseline;
	while (left_x < border)
	{
		s32 right_x = left_x + sector_size_baseline + map_random.NextRanged(sector_size_deviation);
		sectors.push_back(Vec2f(left_x, right_x < border ? right_x : map.tilemapwidth));
		left_x = right_x;
	}
	StructureGrabBag@ bag = StructureGrabBag(map_random, sectors.length * 2);

	// Add portals to sectors
	print("Sector Count: " + sectors.length);
	string[] current_sector_names;
	Vec2f[] subsectors;
	u8[] subsector_sizes;
	for (u8 i = 0; i < sectors.length; i++)
	{
		// Get portal information
		string structure_type = "portal";
		u8 variant_index = bag.getStructureVariant(map_random, structure_type);
		u8 structure_width = bag.getVariantWidth(structure_type, variant_index);

		// Create a portal
		s32 left_x = sectors[i].x;
		s32 right_x = sectors[i].y;
		s32 border_distance = 10;  // How close a portal can get to the border of a sector
		s32 portal_seed = left_x + border_distance + map_random.NextRanged((right_x - left_x - structure_width - 2 * border_distance));
		GenerateStructure(map, naturemap, map_random, structure_type, variant_index, portal_seed);

		// Add the boundaries to the newest portal
		CBlob@ portal = getBlobByNetworkID(rules.get_u16("portal_" + i));
		if (portal !is null)
		{
			// Sector information
			portal.set_Vec2f("sector", sectors[i]);
			portal.Sync("sector", true);
			
			// Sector boundaries
			s32[] borders = {left_x, right_x - 1};
			for (u8 j = 0; j < borders.length(); j++)
			{
				// Find the highest block for two sector borders
				bool left = j % 2 == 0;
				s32 x = borders[j];
				s32 y = getHeighestBlock(map, x);
				if (left && x - 1 > 0)
				{
					y = Maths::Min(getHeighestBlock(map, x - 1), y);
				}
				else if (!left && x + 1 < map.tilemapwidth)
				{
					y = Maths::Min(getHeighestBlock(map, x + 1), y);
				}

				// Spawn the border
				CBlob@ border = server_CreateBlob("sector_border", portal.getTeamNum(), Vec2f(x + 0.5f, y) * map.tilesize);
				if (border !is null)
				{
					border.SetFacingLeft(left);

					// Save the borders for lookup
					string border_id = "sector_border_" + x;
					rules.set_netid(border_id, border.getNetworkID());
					rules.Sync(border_id, true);
				}

				// Name the sector
				bool unique = false;
				string name;
				while(!unique)
				{
					unique = true;
					name = sector_names[map_random.NextRanged(sector_names.length())];
					for (u8 i = 0; i < current_sector_names.length(); i++)
					{
						if (name == current_sector_names[i])
						{
							unique = false;
							break;
						}
					}
				}
				current_sector_names.push_back(name);
				portal.set_string(ZOMBIE_MINIMAP_SECTOR_NAME, name);
				portal.Sync(ZOMBIE_MINIMAP_SECTOR_NAME, true);
			}
		}
		else
		{
			print("Failed to add sector data to portal");
		}

		// Add left and right of the portal as subsectors to be populated sorted by size
		s32 left_subsector_size = portal_seed - left_x;
		subsector_sizes.push_back(left_subsector_size);
		subsector_sizes.sortDesc();
		subsectors.insertAt(subsector_sizes.find(left_subsector_size), Vec2f(left_x, portal_seed));

		s32 right_subsector_size = right_x - portal_seed - structure_width;
		subsector_sizes.push_back(right_subsector_size);
		subsector_sizes.sortDesc();
		subsectors.insertAt(subsector_sizes.find(right_subsector_size), Vec2f(portal_seed + structure_width, right_x));
	}

	// Create a list of structure types and variants ordered by size
	string[] structure_types;
	u8[] structure_sizes, variant_indices;
	for (u8 subsector_index = 0; subsector_index < subsector_sizes.length; subsector_index++)
	{
		// Get a structure and its information
		string structure_type = bag.pickStructure(map_random);
		u8 variant_index = bag.getStructureVariant(map_random, structure_type);
		u8 structure_width = bag.getVariantWidth(structure_type, variant_index);

		// Add the structure into the list
		structure_sizes.push_back(structure_width);
		structure_sizes.sortDesc();
		u8 sorted_index = structure_sizes.find(structure_width);
		structure_types.insertAt(sorted_index, structure_type);
		variant_indices.insertAt(sorted_index, variant_index);
	}

	// Populate subsectors
	for (u8 i = 0; i < subsectors.length; i++)
	{
		s32 left_x = subsectors[i].x;
		s32 right_x = subsectors[i].y;

		// Get a structure variant and width
		string structure_type = structure_types[i];
		u8 variant_index = variant_indices[i];
		u8 structure_width = bag.getVariantWidth(structure_type, variant_index);

		print(getVariantFilename(structure_type, variant_index));

		// Get left seed for structure
		s32 structure_seed = (left_x + right_x - structure_width) / 2;

		// Make structure
		if (structure_seed < left_x + 6 || structure_seed + structure_width > right_x - 6)
		{
			print("Structure " + getVariantFilename(structure_type, variant_index) + " did not fit in subsector of size " + subsector_sizes[i]);
			Populate(map, naturemap, map_random, left_x, right_x);
		}
		else
		{
			GenerateStructure(map, naturemap, map_random, structure_type, variant_index, structure_seed);

			// Populate left and right zones with filler
			Populate(map, naturemap, map_random, left_x, structure_seed);
			Populate(map, naturemap, map_random, structure_seed + structure_width, right_x);
		}
	}

	// DEV - Draw Sector Boundaries
	// for (u8 i = 0; i < sectors.length; i++)
	// {
	// 	for (int y = 0; y < 30; y++)
	// 	{
	// 		map.server_SetTile(Vec2f(sectors[i].y, y) * map.tilesize, CMap::tile_gold);
	// 	}
	// }

	map.set_bool("Update Nodes", true);

	SetupBackgrounds(map);
	return true;
}

class StructureGrabBag
{
	StructureGrabBag(Random@ map_random, u16 _structure_count)
	{
		structure_count = _structure_count;
		Scramble(map_random);
	}

	u16 structure_count;
	u16 structures_left;
	string[] types;  // The type of structure
	u16[] counts;  // How many to spawn on a map
	u8[][] variant_widths;  // Width of each variant

	void Scramble(Random@ map_random)
	{
		structures_left = structure_count;
		u16 slots_left = structure_count;
		types.clear();
		counts.clear();
		variant_widths.clear();

		// Structures with distinct counts
		u16 mineshaft_count = 1 + map_random.NextRanged(2);
		types.push_back("mineshaft_entrance");
		counts.push_back(mineshaft_count);
		slots_left -= mineshaft_count;

		u16 lake_count = 2 + map_random.NextRanged(2);
		types.push_back("lake");
		counts.push_back(lake_count);
		slots_left -= lake_count;

		u16 big_count = 2 + map_random.NextRanged(2);
		types.push_back("big");
		counts.push_back(big_count);
		slots_left -= big_count;

		u16 wall_count = 3 + map_random.NextRanged(2);
		types.push_back("wall");
		counts.push_back(wall_count);
		slots_left -= wall_count;

		// Structures with frequencies
		u16 small_count = u16(f32(30 + map_random.NextRanged(11)) / 100 * slots_left);
		types.push_back("small");
		counts.push_back(small_count);
		slots_left -= small_count;

		// No structure
		types.push_back("");
		counts.push_back(slots_left);

		// Special structures, not part of the bag selection but still need counts
		types.push_back("portal");
		counts.push_back(0);

		// Count the number of variants for each type of structure and width of each variant
		for (u8 type_index = 0; type_index < types.length(); type_index++)
		{
			u8 variant_count = 0;
			u8[] variants;
			CFileImage@ image = CFileImage(types[type_index] + "_" + variant_count);
			while (image.isLoaded())
			{
				variants.push_back(image.getWidth());
				variant_count++;
				@image = CFileImage(types[type_index] + "_" + variant_count);
			}

			if (variants.length == 0)
			{
				variants.push_back(0);
			}

			variant_widths.push_back(variants);
		}

		for (u8 type_index = 0; type_index < types.length(); type_index++)
		{
			print(types[type_index] + ": " + counts[type_index]);
		}
	}

	u8 getStructureVariant(Random@ map_random, string type)
	{
		return map_random.NextRanged(variant_widths[types.find(type)].length);
	}

	u8 getVariantWidth(string type, u8 variant)
	{
		return variant_widths[types.find(type)][variant];
	}

	string pickStructure(Random@ map_random)
	{
		u16 selection = map_random.NextRanged(structures_left);
		u16 running_sum = 0;
		for (u8 i = 0; i < types.length; i++)
		{
			running_sum += counts[i];

			if (running_sum > selection)
			{
				counts[i]--;
				structures_left--;
				return types[i];
			}
		}
		return "";
	}
}

string getVariantFilename(string type, u8 variant_index)
{
	return type == "" ? "" : type + "_" + variant_index;
}

// Fills an area with lootables, nature, and potentially a structure
void Populate(CMap@ map, int[]@ naturemap, Random@ map_random, s32 left_x, s32 right_x)
{
	// Safety check
	if (left_x < 0 || right_x > map.tilemapwidth || left_x > right_x)
	{
		return;
	}

	// Add filler
	s32 width = right_x - left_x;
	Noise@ material_noise = Noise(map_random.Next());
	s32 bush_skip = 0;
	s32 tree_skip = 0;
	bool lootable_spawned = false;
	const s32 tree_limit = 2;
	const s32 bush_limit = 3;
	for (s32 x = left_x; x < right_x; x++)
	{
		if (naturemap[x] == -1)
			continue;

		int y = naturemap[x];
		
		f32 grass_frac = material_noise.Fractal(x * 0.02f, y * 0.02f);
		bool spawned = false;
		Vec2f coords(x * map.tilesize, y * map.tilesize);
		if (map.isTileGround(map.getTile(coords).type) && map.getTile(coords - Vec2f(0, map.tilesize)).type == CMap::tile_empty && grass_frac > 0.5f)
		{
			
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

			// grass control random
			TileType grass_tile = CMap::tile_grass + (spawned ? 0 : map_random.NextRanged(4));
			map.server_SetTile(Vec2f(x, y - 1) * map.tilesize, grass_tile);
		}

		// Spawn lootables
		if (!lootable_spawned && !spawned)
		{
			if (map_random.NextRanged(pot_frequency) == 0)
			{
				lootable_spawned = true;
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
				
				server_CreateBlob(pot_choice, 3, Vec2f(x, naturemap[x] - 1) * map.tilesize);
			}
			else if (map_random.NextRanged(gravestone_frequency) == 0)
			{
				lootable_spawned = true;
				CBlob@ gravestone = server_CreateBlob("gravestone");
				if (gravestone !is null)
				{
					gravestone.server_setTeamNum(3);
					gravestone.setPosition(Vec2f(x, naturemap[x] - 1) * map.tilesize);
					gravestone.Init();
				}
			}
			else if (map_random.NextRanged(boulder_frequency) == 0)
			{
				lootable_spawned = true;
				server_CreateBlob("boulder", 3, Vec2f(x, naturemap[x] - 1) * map.tilesize);
			}
		}
		else
		{
			lootable_spawned = false;
		}
	}
}

u8 GenerateStructure(CMap@ map, int[]@ naturemap, Random@ map_random, string type, u8 variant_index, s32 left_x)
{
	string filename = getVariantFilename(type, variant_index);
	if (type == "mineshaft_entrance")
	{
		return SpawnStructure(map, naturemap, map_random, map_random.NextRanged(2) == 0, filename, left_x, 6, 3);
	}
	else if (type == "")
	{
		return 0;
	}
	else
	{
		return SpawnStructure(map, naturemap, map_random, map_random.NextRanged(2) == 0, filename, left_x, 6, 3);
	}
}

u8 SpawnStructure(CMap@ map, int[]@ naturemap, Random@ map_random, bool mirror, string file_name, s32 left_x, u8 edge_erode_width, u8 edge_erode_cycles)
{
	Vec2f structure_seed = Vec2f(left_x, map.getLandYAtX(left_x));
	PNGLoader@ png_loader = PNGLoader();
	u8 structure_width = png_loader.loadStructure(file_name);
	structure_seed.y -= png_loader.height_offset;
	png_loader.buildStructure(structure_seed, map_random, mirror);

	// Variables for tweaking
	s32 left_erode_x = structure_seed.x - edge_erode_width + 1, right_erode_x = structure_seed.x + structure_width - 1;
	
	// Clear above the structure
	Fill(map, structure_seed.x, GetHeightmap(map, structure_seed.x, structure_width, 0), GetHeightmap(map, structure_seed.x, structure_width, structure_seed.y));

	// Fill below the structure
	s32 structure_bottom = structure_seed.y + png_loader.image.getHeight();
	int[] original_heightmap(structure_width);
	for (s32 x = 0; x < structure_width; x++)
	{
		original_heightmap[x] = Maths::Max(naturemap[structure_seed.x + x], structure_bottom);
	}
	Fill(map, structure_seed.x, original_heightmap, GetHeightmap(map, structure_seed.x, structure_width, structure_bottom));

	// Erode left of the structure
	int[] starting_heightmap = GetHeightmap(map, left_erode_x, edge_erode_width);
	int[] ending_heightmap = GetHeightmap(map, left_erode_x, edge_erode_width);
	Erode(edge_erode_cycles, ending_heightmap, false);
	Fill(map, left_erode_x, starting_heightmap, ending_heightmap);

	// Erode right of the structure
	starting_heightmap = GetHeightmap(map, right_erode_x, edge_erode_width);
	ending_heightmap = GetHeightmap(map, right_erode_x, edge_erode_width);
	Erode(edge_erode_cycles, ending_heightmap, true);
	Fill(map, right_erode_x, starting_heightmap, ending_heightmap);

	// Update naturemap
	ending_heightmap = GetHeightmap(map, left_erode_x, 2 * edge_erode_width + structure_width);
	for (u16 x_offset = 0; x_offset < ending_heightmap.length(); x_offset++)
	{
		naturemap[left_erode_x + x_offset] = ending_heightmap[x_offset];
	}
	
	return structure_width;
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

void Erode(s32 erode_cycles, int[]@ heightmap, bool fix_left)
{
	for (int erode_cycle = 0; erode_cycle < erode_cycles; ++erode_cycle) //cycles
	{
		if (fix_left)
		{
			for (int x = 0; x < heightmap.length() - 1; x++)
			{
				heightmap[x + 1] += (heightmap[x] - heightmap[x + 1]) / 2;
			}
		}
		else
		{
			for (int x = heightmap.length() - 1; x > 0; x--)
			{
				heightmap[x - 1] += (heightmap[x] - heightmap[x - 1]) / 2;
			}
		}
	}
}

void Erode(s32 erode_cycles, int[]@ heightmap)
{
	for (int erode_cycle = 0; erode_cycle < erode_cycles; ++erode_cycle) //cycles
	{
		for (int x = 1; x < heightmap.length() - 1; x++)
		{
			s32 diffleft = heightmap[x] - heightmap[x - 1];
			s32 diffright = heightmap[x] - heightmap[x + 1];

			if (diffleft > 0 && diffleft > diffright)  // If left is higher than this and higher than right
			{
				// Move this up and left down
				heightmap[x] -= (diffleft + 1) / 2;
				heightmap[x - 1] += diffleft / 2;
			}
			else if (diffright > 0 && diffright > diffleft)  // If right is higher than this and higher than left
			{
				// Move this up and right down
				heightmap[x] -= (diffright + 1) / 2;
				heightmap[x + 1] += diffright / 2;
			}
			else if (diffleft == diffright && diffleft > 0)  // If left and right are equal and left is higher than this
			{
				// Move this up, left down, and right down
				heightmap[x] -= (diffright + 1) / 2;
				heightmap[x - 1] += (diffleft + 3) / 4;
				heightmap[x + 1] += (diffleft + 3) / 4;
			}
		}
	}
	heightmap[0] = heightmap[1];
	heightmap[heightmap.length() - 1] = heightmap[heightmap.length() - 2];
}

int[] GetHeightmap(CMap@ map, s32 left_x, u16 width)
{
	return GetHeightmap(map, left_x, width, -1);
}

int[] GetHeightmap(CMap@ map, s32 left_x, u16 width, s32 y)
{
	int[] heightmap(width);
	bool hard_set_y = y >= 0 && y <= map.tilemapheight;
	for (s32 x = 0; x < width; x++)
	{
		heightmap[x] = hard_set_y ? y : getHeighestBlock(map, left_x + x);
	}
	return heightmap;
}

s32 getHeighestBlock(CMap@ map, s32 x)
{
	for (s32 y = 0; y < map.tilemapheight; y++)
	{
		if (map.isTileSolid(Vec2f(x, y) * map.tilesize))
		{
			return y;
		}
	}
	return -1;
}

void Fill(CMap@ map, s32 left_x, int[]@ starting_heightmap, int[]@ ending_heightmap)
{
	for (s32 x = 0; x < starting_heightmap.length(); x++)
	{
		// Fill up with dirt or clear with sky
		Vec2f position = Vec2f(left_x + x, 0);
		bool fill = starting_heightmap[x] > ending_heightmap[x];
		for (position.y = (fill ? ending_heightmap[x] : starting_heightmap[x]); position.y < (fill ? starting_heightmap[x] : ending_heightmap[x]); position.y++)
		{
			map.server_SetTile(position * map.tilesize, fill ? CMap::tile_ground : CMap::tile_empty);
		}
	}
}
