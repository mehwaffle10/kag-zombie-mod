// BasePNGLoader.as
// NSFL if you don't unzoom it out in your editor

// Note for modders upgrading their mod, handlePixel's signature has changed recently!

#include "LoaderColors.as"
#include "CustomBlocks.as"
#include "ZombieBlocksSetTile.as"

enum world_positions_enums
{
	autotile_index = 0,
	tree_index,
	bush_index,
	grain_index,
	flower_index,
	spike_index,
	ladder_index,
	index_count
};

//global
Random@ map_random;

class PNGLoader
{
	PNGLoader()
	{
		Reset();
	}

	CFileImage@ image;
	CMap@ map;
	CRules@ rules;
	Vec2f seed;
	bool mirror;
	int image_width;
	int image_height;
	int height_offset;

	Vec2f[][] world_positions;
	SColor[][] pixels;

	void Reset()
	{
		world_positions = Vec2f[][](index_count, Vec2f[](0));
	}

	u8 loadStructure(const string filename)
	{
		if(!isServer())
		{
			return 0;
		}

		@map = getMap();
		@image = CFileImage(filename);
		@rules = getRules();

		if(image.isLoaded())
		{
			image_width = image.getWidth();
			image_height = image.getHeight();

			pixels = SColor[][](image_width, SColor[](image_height));

			while(image.nextPixel())
			{
				const SColor pixel = image.readPixel();
				int offset = image.getPixelOffset();

				pixels[offset % image_width][offset / image_width] = pixel;
			}

			// pixels[1][0] = map_colors::tile_bedrock;
			// pixels[image_width - 2][0] = map_colors::tile_gold;

			// Find the highest solid tile on the left
			height_offset = 0;
			while(height_offset < pixels[0].length && !isColorSolid(pixels[0][height_offset]))
			{
				height_offset++;
			}

			return image_width;
		}
		return 0;
	}

	u8 buildStructure(Vec2f _seed, Random@ _map_random, bool _mirror)
	{
		Reset();
		seed = _seed;
		@map_random = _map_random;
		mirror = _mirror;

		if(!isServer())
		{
			return 0;
		}

		for(u8 x = 0; x < image_width; x++)
		{
			for (u8 y = 0; y < image_height; y++)
			{
				// Flip offset if mirrored
				int offset = mirror ? (y + 1) * image_width - x - 1 : y * image_width + x;
				handlePixel(pixels[x][y], offset);
				getNet().server_KeepConnectionsAlive();
			}
		}

		// late load - after placing tiles
		for(uint i = 0; i < world_positions.length; ++i)
		{
			Vec2f[]@ world_positions_set = world_positions[i];
			u8 world_position_index = world_positions_set.length;
			for(uint step = 0; step < world_position_index; ++step)
			{
				handleOffset(i, world_positions_set[step]);
				getNet().server_KeepConnectionsAlive();
			}
		}
		return image_width;
	}

	// Queue an offset to be autotiled
	void autotile(Vec2f world_postion)
	{
		world_positions[autotile_index].push_back(world_postion);
	}

	void handlePixel(const SColor &in pixel, int offset)
	{
		u8 alpha = pixel.getAlpha();

		const Vec2f position = getSpawnPosition(map, offset);
		int map_offset = map.getTileOffset(position);

		if(alpha < 255)
		{
			alpha &= ~0x80;
			
			//print("ARGB = "+alpha+", "+pixel.getRed()+", "+pixel.getGreen()+", "+pixel.getBlue());

			// TODO future reader, if the new angelscript release has arrived; consider using named arguments for spawnBlob etc if it doesn't clutter the lines too much.
			// It might be nice for things like the static argument.

			// Test color with alpha 255
			switch (pixel.color | 0xFF000000)
			{
			// Alpha spawn and flag
			case map_colors::alpha_spawn: autotile(position); AddMarker(map, offset, (alpha & 0x01 == 0 ? "blue main spawn" : "red main spawn")); break;
			case map_colors::alpha_flag:  autotile(position); AddMarker(map, offset, (alpha & 0x01 == 0 ? "blue spawn"      : "red spawn"));      break;

			// Alpha various structures
			case map_colors::alpha_stalagmite:      autotile(position); spawnBlob(map, "stalagmite",                            255, position, getAngleFromChannel(alpha), true).set_u8("state", 1); /*stabbing*/ break;
			case map_colors::alpha_ladder:          autotile(position); spawnBlob(map, "ladder",          getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_spikes:          autotile(position); spawnBlob(map, "spikes",          getTeamFromChannel(alpha), position,                             true); break;
			case map_colors::alpha_stone_door:      autotile(position); spawnBlob(map, "stone_door",      getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_trap_block:      autotile(position); spawnBlob(map, "trap_block",      getTeamFromChannel(alpha), position,                             true); break;
			case map_colors::alpha_bridge:          autotile(position); spawnBlob(map, "bridge",      	  getTeamFromChannel(alpha), position,                             true); break;
			case map_colors::alpha_wooden_door:     autotile(position); spawnBlob(map, "wooden_door",     getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_wooden_platform: autotile(position); spawnBlob(map, "wooden_platform", getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;

			// Mechanisms
			case map_colors::alpha_pressure_plate:  autotile(position); spawnBlob(map, "pressure_plate",                        255, position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_push_button:     autotile(position); spawnBlob(map, "push_button",     getTeamFromChannel(alpha), position,                             true); break;
			case map_colors::alpha_coin_slot:       autotile(position); spawnBlob(map, "coin_slot",       getTeamFromChannel(alpha), position,                             true); break;
			case map_colors::alpha_sensor:          autotile(position); spawnBlob(map, "sensor",          getTeamFromChannel(alpha), position,                             true); break;
			case map_colors::alpha_diode:           autotile(position); spawnBlob(map, "diode",           getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_elbow:           autotile(position); spawnBlob(map, "elbow",           getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_emitter:         autotile(position); spawnBlob(map, "emitter",         getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_inverter:        autotile(position); spawnBlob(map, "inverter",        getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_junction:        autotile(position); spawnBlob(map, "junction",        getTeamFromChannel(alpha), position,                             true); break;
			case map_colors::alpha_oscillator:      autotile(position); spawnBlob(map, "oscillator",      getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_randomizer:      autotile(position); spawnBlob(map, "randomizer",      getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_receiver:        autotile(position); spawnBlob(map, "receiver",        getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_resistor:        autotile(position); spawnBlob(map, "resistor",        getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_tee:             autotile(position); spawnBlob(map, "tee",             getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_toggle:          autotile(position); spawnBlob(map, "toggle",          getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_transistor:      autotile(position); spawnBlob(map, "transistor",      getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_wire:            autotile(position); spawnBlob(map, "wire",            getTeamFromChannel(alpha), position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_bolter:          autotile(position); spawnBlob(map, "bolter",                                255, position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_dispenser:       autotile(position); spawnBlob(map, "dispenser",                             255, position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_lamp:            autotile(position); spawnBlob(map, "lamp",                                  255, position,                             true); break;
			case map_colors::alpha_obstructor:      autotile(position); spawnBlob(map, "obstructor",                            255, position,                             true); break;
			case map_colors::alpha_spiker:          autotile(position); spawnBlob(map, "spiker",                                255, position, getAngleFromChannel(alpha), true); break;
			case map_colors::alpha_lever:
			{
				autotile(position);
				CBlob@ blob = spawnBlob(map, "lever", getTeamFromChannel(alpha), position, true);

				// | state          | binary    | hex  | dec |
				// ---------------------vv--------------------
				// | off            | 0000 0000 | 0x00 |   0 |
				// | on             | 0001 0000 | 0x10 |  16 |
				// | random         | 0010 0000 | 0x20 |  32 |

				/*if(alpha & 0x10 != 0 || alpha & 0x20 != 0 && XORRandom(2) == 0) // not implemented at the moment
				{
					blob.SendCommand(blob.getCommandID("toggle"));
				}*/
			}
			break;
			case map_colors::alpha_magazine:
			{
				autotile(position);
				CBlob@ blob = spawnBlob(map, "magazine", 255, position, true);

				const string[] items = {
				"mat_bombs",       // 0
				"mat_waterbombs",  // 1
				"mat_arrows",      // 2
				"mat_waterarrows", // 3
				"mat_firearrows",  // 4
				"mat_bombarrows",  // 5
				"food"};           // 6
				// RANDOM             7

				if(alpha >= items.length + 1) break;

				string name;
				if(alpha == items.length) // random
				{
					name = items[XORRandom(items.length - 1)];
				}
				else
				{
					name = items[alpha];
				}

				CBlob@ item = server_CreateBlob(name, 255, position);
				blob.server_PutInInventory(item);
			}
			break;
			};
		}
		else
		{
			switch (pixel.color)
			{
			// Tiles
			case map_colors::sky:
			{
				TileType empty = CMap::tile_empty;  // + WORLD_OFFSET;
				// map.server_SetTile(position, empty);
				map.SetTile(map_offset, empty);
				break;
			}
			case map_colors::tile_ground:
			{
				TileType ground = CMap::tile_ground;  // + WORLD_OFFSET;
				// map.server_SetTile(position, ground);
				map.SetTile(map_offset, ground);
				break;
			}
			case map_colors::tile_ground_back:
			{
				TileType ground_back = CMap::tile_ground_back;  // + WORLD_OFFSET;
				// map.server_SetTile(position, ground_back);
				map.SetTile(map_offset, ground_back);
				break;
			}
			case map_colors::tile_stone:
			{
				TileType stone = CMap::tile_stone;  // + WORLD_OFFSET;
				// map.server_SetTile(position, stone);
				map.SetTile(map_offset, stone);
				break;
			}
			case map_colors::tile_thickstone:
			{
				TileType thickstone = CMap::tile_thickstone;  // + WORLD_OFFSET;
				// map.server_SetTile(position, thickstone);
				map.SetTile(map_offset, thickstone);
				break;
			}
			case map_colors::tile_bedrock:
			{
				TileType bedrock = CMap::tile_bedrock;  // + WORLD_OFFSET;
				// map.server_SetTile(position, bedrock);
				map.SetTile(map_offset, bedrock);
				break;
			}
			case map_colors::tile_gold:
			{
				TileType gold = CMap::tile_gold;  // + WORLD_OFFSET;
				// map.server_SetTile(position, gold);
				map.SetTile(map_offset, gold);
				break;
			}
			case map_colors::tile_castle:
			{
				TileType castle = CMap::tile_castle;  // + WORLD_OFFSET;
				// map.server_SetTile(position, castle);
				map.SetTile(map_offset, castle);
				break;
			}
			case map_colors::tile_castle_back:
			{
				TileType castle_back = CMap::tile_castle_back;  // + WORLD_OFFSET;
				// map.server_SetTile(position, castle_back);
				map.SetTile(map_offset, castle_back);
				break;
			}
			case map_colors::tile_castle_moss:
			{
				TileType castle_moss = CMap::tile_castle_moss;  // + WORLD_OFFSET;
				// map.server_SetTile(position, castle_moss);
				map.SetTile(map_offset, castle_moss);
				break;
			}
			case map_colors::tile_castle_back_moss:
			{
				TileType castle_back_moss = CMap::tile_castle_back_moss;  // + WORLD_OFFSET;
				// map.server_SetTile(position, castle_back_moss);
				map.SetTile(map_offset, castle_back_moss);
				break;
			}
			case map_colors::tile_wood:
			{
				TileType wood = CMap::tile_wood;  // + WORLD_OFFSET;
				// map.server_SetTile(position, wood);
				map.SetTile(map_offset, wood);
				break;
			}
			case map_colors::tile_wood_back:
			{
				TileType wood_back = CMap::tile_wood_back;  // + WORLD_OFFSET;
				// map.server_SetTile(position, wood_back);
				map.SetTile(map_offset, wood_back);
				break;
			}
			case map_colors::tile_grass:
			{
				TileType grass = CMap::tile_grass + map_random.NextRanged(3);  // + WORLD_OFFSET;
				// map.server_SetTile(position, grass);
				map.SetTile(map_offset, grass);
				break;
			}

			// Water
			case map_colors::water_air:
			{
				TileType empty = CMap::tile_empty;  // + WORLD_OFFSET;
				// map.server_SetTile(position, empty);
				map.SetTile(map_offset, empty);
				map.server_setFloodWaterWorldspace(position, true);
				break;
			}
			case map_colors::water_backdirt:
			{
				TileType ground_back = CMap::tile_ground_back;  // + WORLD_OFFSET;
				// map.server_SetTile(position, ground_back);
				map.SetTile(map_offset, ground_back);
				map.server_setFloodWaterWorldspace(position, true);
				break;
			}

			// Princess & necromancer
			case map_colors::princess:             autotile(position); spawnBlob(map, "princess",    offset, 6); break;
			case map_colors::necromancer:          autotile(position); spawnBlob(map, "necromancer", offset, 3); break;
			case map_colors::necromancer_teleport: autotile(position); AddMarker(map, offset, "necromancer teleport"); break;

			// Main spawns
			case map_colors::blue_main_spawn:   autotile(position); AddMarker(map, offset, "blue main spawn"); break;
			case map_colors::red_main_spawn:    autotile(position); AddMarker(map, offset, "red main spawn");  break;
			case map_colors::green_main_spawn:  autotile(position); spawnHall(map, offset, 2); break;
			case map_colors::purple_main_spawn: autotile(position); spawnHall(map, offset, 3); break;
			case map_colors::orange_main_spawn: autotile(position); spawnHall(map, offset, 4); break;
			case map_colors::aqua_main_spawn:   autotile(position); spawnHall(map, offset, 5); break;
			case map_colors::teal_main_spawn:   autotile(position); spawnHall(map, offset, 6); break;
			case map_colors::gray_main_spawn:   autotile(position); spawnHall(map, offset, 7); break;

			// Red Barrier
			case map_colors::redbarrier:     autotile(position); AddMarker(map, offset, "red barrier");  break;

			// Normal spawns
			case map_colors::blue_spawn:     autotile(position); AddMarker(map, offset, "blue spawn");   break;
			case map_colors::red_spawn:      autotile(position); AddMarker(map, offset, "red spawn");    break;
			/*case map_colors::green_spawn:  autotile(position); AddMarker(map, offset, "green spawn");  break;*/ // same as grass...?
			case map_colors::purple_spawn:   autotile(position); AddMarker(map, offset, "purple spawn"); break;
			/*case map_colors::orange_spawn: autotile(position); AddMarker(map, offset, "orange spawn"); break;*/ // same as dirt...?
			case map_colors::aqua_spawn:     autotile(position); AddMarker(map, offset, "aqua spawn");   break;
			case map_colors::teal_spawn:     autotile(position); AddMarker(map, offset, "teal spawn");   break;
			case map_colors::gray_spawn:     autotile(position); AddMarker(map, offset, "gray spawn");   break;

			// Workshops
			case map_colors::knight_shop:     autotile(position); spawnBlob(map, "knightshop",  offset); break;
			case map_colors::builder_shop:    autotile(position); spawnBlob(map, "buildershop", offset); break;
			case map_colors::archer_shop:     autotile(position); spawnBlob(map, "archershop",  offset); break;
			case map_colors::boat_shop:       autotile(position); spawnBlob(map, "boatshop",    offset); break;
			case map_colors::vehicle_shop:    autotile(position); spawnBlob(map, "vehicleshop", offset); break;
			case map_colors::quarters:        autotile(position); spawnBlob(map, "quarters",    offset); break;
			case map_colors::storage_noteam:  autotile(position); spawnBlob(map, "storage",     offset); break;
			case map_colors::barracks_noteam: autotile(position); spawnBlob(map, "barracks",    offset); break;
			case map_colors::factory_noteam:  autotile(position); spawnBlob(map, "factory",     offset); break;
			case map_colors::tunnel_blue:     autotile(position); spawnBlob(map, "tunnel",      offset, 0); break;
			case map_colors::tunnel_red:      autotile(position); spawnBlob(map, "tunnel",      offset, 1); break;
			case map_colors::tunnel_noteam:   autotile(position); spawnBlob(map, "tunnel",      offset); break;
			case map_colors::kitchen:         autotile(position); spawnBlob(map, "kitchen",     offset); break;
			case map_colors::nursery:         autotile(position); spawnBlob(map, "nursery",     offset); break;
			case map_colors::research:        autotile(position); spawnBlob(map, "research",    offset); break;

			case map_colors::workbench:       autotile(position); spawnBlob(map, "workbench",   offset, 255, true); break;
			case map_colors::campfire:        autotile(position); spawnBlob(map, "fireplace",   offset, 255); break;
			case map_colors::saw:             autotile(position); spawnBlob(map, "saw",         offset); break;

			// Flora
			case map_colors::tree:
			case map_colors::tree + (1 << 4):
			case map_colors::tree + (2 << 4):
			case map_colors::tree + (3 << 4):
				autotile(position);
				world_positions[tree_index].push_back(position);
			break;
			case map_colors::bush:    autotile(position); world_positions[bush_index].push_back(position); break;
			case map_colors::grain:   autotile(position); world_positions[grain_index].push_back(position); break;
			case map_colors::flowers: autotile(position); world_positions[flower_index].push_back(position); break;
			case map_colors::log:     autotile(position); spawnBlob(map, "log",     offset); break;

			// Fauna
			case map_colors::shark:   autotile(position); spawnBlob(map, "shark",   offset); break;
			case map_colors::fish:    autotile(position); spawnBlob(map, "fishy",   offset).set_u8("age", (offset * 997) % 4); break;
			case map_colors::bison:   autotile(position); spawnBlob(map, "bison",   offset); break;
			case map_colors::chicken: autotile(position); spawnBlob(map, "chicken", offset, 255, false, Vec2f(0,-8)); break;

			// Ladders
			case map_colors::ladder:
			//case map_colors::tile_ladder_ground: // same as map_colors::ladder
			case map_colors::tile_ladder_castle:
			case map_colors::tile_ladder_wood:
				autotile(position);
				world_positions[ladder_index].push_back(position);
			break;

			// Platforms
			case map_colors::platform_up:    autotile(position); spawnBlob(map, "wooden_platform", offset, 255, true); break;
			case map_colors::platform_right: autotile(position); spawnBlob(map, "wooden_platform", offset, 255, true, Vec2f_zero,  90); break;
			case map_colors::platform_down:  autotile(position); spawnBlob(map, "wooden_platform", offset, 255, true, Vec2f_zero, 180); break;
			case map_colors::platform_left:  autotile(position); spawnBlob(map, "wooden_platform", offset, 255, true, Vec2f_zero, 270); break;

			// Doors
			case map_colors::wooden_door_h_blue:   autotile(position); spawnBlob(map, "wooden_door", offset,   0, true); break;
			case map_colors::wooden_door_v_blue:   autotile(position); spawnBlob(map, "wooden_door", offset,   0, true, Vec2f_zero, 90); break;
			case map_colors::wooden_door_h_red:    autotile(position); spawnBlob(map, "wooden_door", offset,   1, true); break;
			case map_colors::wooden_door_v_red:    autotile(position); spawnBlob(map, "wooden_door", offset,   1, true, Vec2f_zero, 90); break;
			case map_colors::wooden_door_h_noteam: autotile(position); spawnBlob(map, "wooden_door", offset, 255, true); break;
			case map_colors::wooden_door_v_noteam: autotile(position); spawnBlob(map, "wooden_door", offset, 255, true, Vec2f_zero, 90); break;
			case map_colors::stone_door_h_blue:    autotile(position); spawnBlob(map, "stone_door",  offset,   0, true); break;
			case map_colors::stone_door_v_blue:    autotile(position); spawnBlob(map, "stone_door",  offset,   0, true, Vec2f_zero, 90); break;
			case map_colors::stone_door_h_red:     autotile(position); spawnBlob(map, "stone_door",  offset,   1, true); break;
			case map_colors::stone_door_v_red:     autotile(position); spawnBlob(map, "stone_door",  offset,   1, true, Vec2f_zero, 90); break;
			case map_colors::stone_door_h_noteam:  autotile(position); spawnBlob(map, "stone_door",  offset, 255, true); break;
			case map_colors::stone_door_v_noteam:  autotile(position); spawnBlob(map, "stone_door",  offset, 255, true, Vec2f_zero, 90); break;

			// Trapblocks
			case map_colors::trapblock_blue:   autotile(position); spawnBlob(map, "trap_block", offset,   0, true); break;
			case map_colors::trapblock_red:    autotile(position); spawnBlob(map, "trap_block", offset,   1, true); break;
			case map_colors::trapblock_noteam: autotile(position); spawnBlob(map, "trap_block", offset, 255, true); break;

			// Trap Bridges
			case map_colors::bridge_blue:   autotile(position); spawnBlob(map, "bridge", offset,   0, true); break;
			case map_colors::bridge_red:    autotile(position); spawnBlob(map, "bridge", offset,   1, true); break;
			case map_colors::bridge_noteam: autotile(position); spawnBlob(map, "bridge", offset, 255, true); break;

			// Spikes
			case map_colors::spikes:
				world_positions[spike_index].push_back(position);
				break;
			case map_colors::spikes_ground:
			{
				world_positions[spike_index].push_back(position);
				TileType ground_back = CMap::tile_ground_back;  // + WORLD_OFFSET;
				// map.server_SetTile(position, ground_back);
				map.SetTile(map_offset, ground_back);
				break;
			}
			case map_colors::spikes_castle:
			{
				world_positions[spike_index].push_back(position);
				TileType castle_back = CMap::tile_ground_back;  // + WORLD_OFFSET;
				// map.server_SetTile(position, castle_back);
				map.SetTile(map_offset, castle_back);
				break;
			}
			case map_colors::spikes_wood:
			{
				world_positions[spike_index].push_back(position);
				TileType wood_back = CMap::tile_wood_back;  // + WORLD_OFFSET;
				// map.server_SetTile(position, wood_back);
				map.SetTile(map_offset, wood_back);
				break;
			}

			// Misc stuff
			case map_colors::drill: autotile(position); spawnBlob(map, "drill", offset, -1); break;
			case map_colors::trampoline:
			{
				autotile(position);
				CBlob@ trampoline = server_CreateBlobNoInit("trampoline");
				if (trampoline !is null)
				{
					trampoline.Tag("invincible");
					trampoline.Tag("static");
					trampoline.Tag("no pickup");
					trampoline.setPosition(position);
					trampoline.Init();
				}
			}
			break;
			case map_colors::lantern:     autotile(position); spawnBlob(map, "lantern", offset, 255, true); break;
			case map_colors::crate:       autotile(position); spawnBlob(map, "crate",   offset); break;
			case map_colors::bucket:      autotile(position); spawnBlob(map, "bucket",  offset); break;
			case map_colors::sponge:      autotile(position); spawnBlob(map, "sponge",  offset); break;
			case map_colors::alpha_chest:
			case map_colors::chest:       autotile(position); spawnBlob(map, "chest",   offset); break;

			// Food
			case map_colors::steak:       autotile(position); spawnBlob(map, "steak", offset); break;
			case map_colors::burger:      autotile(position); spawnBlob(map, "food",  offset); break;
			case map_colors::heart:       autotile(position); spawnBlob(map, "heart", offset); break;

			// Ground siege
			case map_colors::catapult:    autotile(position); spawnVehicle(map, "catapult", offset, 0); break; // HACK: team for Challenge
			case map_colors::ballista:    autotile(position); spawnVehicle(map, "ballista", offset); break;
			case map_colors::mountedbow:  autotile(position); spawnBlob(map, "mounted_bow", offset, 255, true, Vec2f(0.0f, 4.0f)); break;

			// Water/air vehicles
			case map_colors::longboat:    autotile(position); spawnVehicle(map, "longboat", offset); break;
			case map_colors::warboat:     autotile(position); spawnVehicle(map, "warboat",  offset); break;
			case map_colors::dinghy:      autotile(position); spawnVehicle(map, "dinghy",   offset); break;
			case map_colors::raft:        autotile(position); spawnVehicle(map, "raft",     offset); break;
			case map_colors::airship:     autotile(position); spawnVehicle(map, "airship",  offset); break;
			case map_colors::bomber:      autotile(position); spawnVehicle(map, "bomber",   offset); break;

			// Ammo
			case map_colors::bombs:       autotile(position); AddMarker(map, offset, "mat_bombs"); break;
			case map_colors::waterbombs:  autotile(position); spawnBlob(map, "mat_waterbombs",  offset); break;
			case map_colors::arrows:      autotile(position); spawnBlob(map, "mat_arrows",      offset); break;
			case map_colors::bombarrows:  autotile(position); spawnBlob(map, "mat_bombarrows",  offset); break;
			case map_colors::waterarrows: autotile(position); spawnBlob(map, "mat_waterarrows", offset); break;
			case map_colors::firearrows:  autotile(position); spawnBlob(map, "mat_firearrows",  offset); break;
			case map_colors::bolts:       autotile(position); spawnBlob(map, "mat_bolts",       offset); break;

			// Mines, explosives
			case map_colors::blue_mine:   autotile(position); spawnBlob(map, "mine", offset, 0); break;
			case map_colors::red_mine:    autotile(position); spawnBlob(map, "mine", offset, 1); break;
			case map_colors::mine_noteam: autotile(position); spawnBlob(map, "mine", offset); break;
			case map_colors::boulder:     autotile(position); spawnBlob(map, "boulder", offset, -1, false, Vec2f(8.0f, -8.0f)); break;
			case map_colors::satchel:     autotile(position); spawnBlob(map, "satchel", offset); break;
			case map_colors::keg:         autotile(position); spawnBlob(map, "keg", offset); break;

			// Materials
			case map_colors::gold:        autotile(position); spawnBlob(map, "mat_gold", offset); break;
			case map_colors::stone:       autotile(position); spawnBlob(map, "mat_stone", offset); break;
			case map_colors::wood:        autotile(position); spawnBlob(map, "mat_wood", offset); break;

			// Mooks
			case map_colors::mook_knight:     autotile(position); AddMarker(map, offset, "mook knight"); break;
			case map_colors::mook_archer:     autotile(position); AddMarker(map, offset, "mook archer"); break;
			case map_colors::mook_spawner:    autotile(position); AddMarker(map, offset, "mook spawner"); break;
			case map_colors::mook_spawner_10: autotile(position); AddMarker(map, offset, "mook spawner 10"); break;
			case map_colors::dummy:           autotile(position); spawnBlob(map, "dummy", offset, 1, true); break;
			
			// Zombies
			case map_colors::portal:		  {
												autotile(position);
												CBlob@ portal = spawnBlob(map, "portal", 3, getSpawnPosition(map, offset) - Vec2f(mirror ? 1 : 0, 2) * map.tilesize);
												u8 portal_count = rules.get_u8("portal_count");
												string portal_i = "portal_" + portal_count;
												rules.set_netid(portal_i, portal.getNetworkID());
												rules.Sync(portal_i, true);
												rules.set_u8("portal_count", portal_count + 1);
												rules.Sync("portal_count", true);
												break;
											  }
			case map_colors::spawner:		  autotile(position); spawnBlob(map, "spawner", 3, getSpawnPosition(map, offset) - Vec2f(0, 1) * map.tilesize); break;
			default:
				HandleCustomTile(map, offset, pixel);
			};
		}
	}

	//override this to add post-load offset types.
	void handleOffset(int type, Vec2f world_position)
	{
		switch (type)
		{
			case autotile_index:
			{
				PlaceMostLikelyTile(world_position);
				break;
			}
			case tree_index:
			{
				// load trees only at the ground
				if(!isSolid(map.getTile(world_position + Vec2f(0, map.tilesize)).type))
				{
					return;
				}

				CBlob@ tree = server_CreateBlobNoInit(map_random.NextRanged(35) < 21 ? "tree_pine" : "tree_bushy" );
				if(tree !is null)
				{
					tree.Tag("startbig");
					tree.setPosition(world_position);
					tree.Init();
					if (isEmpty(map.getTile(world_position).type))
					{
						TileType grass = CMap::tile_grass + map_random.NextRanged(3);  // + WORLD_OFFSET;
						// map.server_SetTile(world_position, grass);
						map.SetTile(map.getTileOffset(world_position), grass); 
					}
				}
				break;
			}
			case bush_index:
			{
				Vec2f pos = world_position + Vec2f(4, 4);
				server_CreateBlob("bush", -1, world_position);
				break;
			}
			case grain_index:
			{
				CBlob@ grain = server_CreateBlobNoInit("grain_plant");
				if(grain !is null)
				{
					grain.Tag("instant_grow");
					grain.setPosition(world_position);
					grain.Init();
				}
				break;
			}
			case flower_index:
			{
				CBlob@ flower = server_CreateBlobNoInit("flowers");
				if(flower !is null)
				{
					flower.Tag("instant_grow");
					flower.setPosition(world_position);
					flower.Init();
				}
				break;
			}
			case spike_index:
			{
				spawnBlob(map, "spikes", -1, world_position, true);
				break;
			}
			case ladder_index:
			{
				spawnLadder(map, world_position);
				break;
			}
		};
	}

	CBlob@ spawnLadder(CMap@ map, Vec2f world_position)
	{
		bool up = false, down = false, right = false, left = false;
		Vec2f[]@ ladders = world_positions[ladder_index];
		for (uint step = 0; step < ladders.length; ++step)
		{
			const Vec2f other_ladder_position = ladders[step];
			if (other_ladder_position == world_position + Vec2f(0, -map.tilesize))
			{
				up = true;
			}
			if (other_ladder_position == world_position + Vec2f(0, map.tilesize))
			{
				down = true;
			}
			if (other_ladder_position == world_position + Vec2f(map.tilesize, 0))
			{
				right = true;
			}
			if (other_ladder_position == world_position + Vec2f(-map.tilesize, 0))
			{
				left = true;
			}
		}

		bool vertical = up && down, horizontal = left && right;
		if (!vertical && !horizontal)
		{
			return null;
		}

		CBlob@ ladder = server_CreateBlob("ladder", -1, world_position);
		if (ladder !is null)
		{
			// check for horizontal placement
			if (!vertical)
			{
				ladder.setAngleDegrees( 90.0f );
			}
			ladder.getShape().SetStatic( true );
		}
		return ladder;
	}

	void PlaceMostLikelyTile(Vec2f position)
	{
		const TileType up = map.getTile(position + Vec2f(0, -map.tilesize)).type;
		const TileType down = map.getTile(position + Vec2f(0, map.tilesize)).type;
		const TileType left = map.getTile(position + Vec2f(-map.tilesize, 0)).type;
		const TileType right = map.getTile(position + Vec2f(map.tilesize, 0)).type;
		u32 offset = map.getTileOffset(position);

		if (!isEmpty(up))
		{
			const TileType[] neighborhood = { up, down, left, right };

			if ((neighborhood.find(CMap::tile_castle) != -1) ||
			    (neighborhood.find(CMap::tile_castle_back) != -1))
			{
				TileType castle_back = CMap::tile_castle_back;  // + WORLD_OFFSET;
				// map.server_SetTile(position, castle_back);
				map.SetTile(offset, castle_back); 
			}
			else if ((neighborhood.find(CMap::tile_wood) != -1) ||
			         (neighborhood.find(CMap::tile_wood_back) != -1))
			{
				TileType wood_back = CMap::tile_wood_back;  // + WORLD_OFFSET;
				// map.server_SetTile(position, wood_back);
				map.SetTile(offset, wood_back); 
			}
			else if ((neighborhood.find(CMap::tile_ground) != -1) ||
			         (neighborhood.find(CMap::tile_ground_back) != -1))
			{
				TileType ground_back = CMap::tile_ground_back;  // + WORLD_OFFSET;
				// map.server_SetTile(position, ground_back);
				map.SetTile(offset, ground_back); 
			}
		}
		else if(isSolid(down) && (isGrass(left) || isGrass(right)))
		{
			TileType grass = CMap::tile_grass + 2 + map_random.NextRanged(2);  // + WORLD_OFFSET;
			// map.server_SetTile(position, grass);
			map.SetTile(offset, grass); 
		}
		else
		{
			TileType empty = CMap::tile_empty;  // + WORLD_OFFSET;
			// map.server_SetTile(position, empty);
			map.SetTile(offset, empty); 
		}
	}

	u8 getTeamFromChannel(u8 channel)
	{
		// only the bits we want
		channel &= 0x0F;

		return (channel > 7)? 255 : channel;
	}

	u8 getChannelFromTeam(u8 team)
	{
		return (team > 7)? 0x0F : team;
	}

	u16 getAngleFromChannel(u8 channel)
	{
		// only the bits we want
		channel &= 0x30;

		switch(channel)
		{
			case 16: return 90;
			case 32: return 180;
			case 48: return 270;
		}

		return 0;
	}

	u8 getChannelFromAngle(u16 angle)
	{
		switch(angle)
		{
			case  90: return 16;
			case 180: return 32;
			case 270: return 48;
		}

		return 0;
	}

	Vec2f getSpawnPosition(CMap@ map, int offset)
	{
		Vec2f pos = (seed + Vec2f(offset % image_width, offset / image_width)) * map.tilesize;
		f32 tile_offset = map.tilesize * 0.5f;
		pos += Vec2f(tile_offset, tile_offset);
		return pos;
	}

	CBlob@ spawnHall(CMap@ map, int offset, u8 team)
	{
		CBlob@ hall = spawnBlob(map, "hall", offset, team);
		if (hall !is null) // add research to first hall
		{
			hall.AddScript("Researching.as");
			hall.Tag("script added");
		}
		return @hall;
	}

	CBlob@ spawnBlob(CMap@ map, const string &in name, u8 team, Vec2f position)
	{
		return server_CreateBlob(name, team, position);
	}

	CBlob@ spawnBlob(CMap@ map, const string &in name, u8 team, Vec2f position, const bool fixed)
	{
		CBlob@ blob = server_CreateBlob(name, team, position);
		blob.getShape().SetStatic(fixed);

		return blob;
	}

	CBlob@ spawnBlob(CMap@ map, const string &in name, u8 team, Vec2f position, s16 angle)
	{
		CBlob@ blob = server_CreateBlob(name, team, position);
		angle = mirror ? -angle : angle;
		while (angle < 0)
		{
			angle += 360;
		}
		blob.setAngleDegrees(angle);

		return blob;
	}

	CBlob@ spawnBlob(CMap@ map, const string &in name, u8 team, Vec2f position, s16 angle, const bool fixed)
	{
		CBlob@ blob = spawnBlob(map, name, team, position, angle);
		blob.getShape().SetStatic(fixed);

		if (blob !is null && blob.isPlatform())
		{
			blob.AddScript("UpdateOnStaticChange");
		}

		return blob;
	}

	CBlob@ spawnBlob(CMap@ map, const string& in name, int offset, u8 team = 255, bool attached_to_map = false, Vec2f posOffset = Vec2f_zero, s16 angle = 0)
	{
		return spawnBlob(map, name, team, getSpawnPosition(map, offset) + posOffset, angle, attached_to_map);
	}

	CBlob@ spawnVehicle(CMap@ map, const string& in name, int offset, int team = -1)
	{
		CBlob@ blob = server_CreateBlob(name, team, getSpawnPosition(map, offset));
		if(blob !is null)
		{
			blob.RemoveScript("DecayIfLeftAlone.as");
		}
		return blob;
	}

	void AddMarker(CMap@ map, int offset, const string& in name)
	{
		map.AddMarker(map.getTileWorldPosition(offset), name);
	}

	void getInfoFromBlob(CBlob@ this, SColor &out color, Vec2f &out offset)
	{
		const string name = this.getName();

		// declare some default values
		color = map_colors::unused;
		offset = Vec2f_zero;

		// BLOCKS
		if(this.getShape().isStatic())
		{
			if(name == "ladder")
			{
				color = map_colors::alpha_ladder;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "spikes")
			{
				color = map_colors::alpha_spikes;
				color.setAlpha(getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "stone_door")
			{
				color = map_colors::alpha_stone_door;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "trap_block")
			{
				color = map_colors::alpha_trap_block;
				color.setAlpha(getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "bridge")
			{
				color = map_colors::alpha_bridge;
				color.setAlpha(getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "wooden_door")
			{
				color = map_colors::alpha_wooden_door;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "wooden_platform")
			{
				color = map_colors::alpha_wooden_platform;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			// MECHANISMS
			else if(name == "coin_slot")
			{
				color = map_colors::alpha_coin_slot;
				color.setAlpha(getChannelFromTeam(255));
			}
			else if(name == "lever")
			{
				color = map_colors::alpha_lever;
				color.setAlpha(getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "pressure_plate")
			{
				color = map_colors::alpha_pressure_plate;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()));
			}
			else if(name == "push_button")
			{
				color = map_colors::alpha_push_button;
				color.setAlpha(getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "sensor")
			{
				color = map_colors::alpha_sensor;
				color.setAlpha(getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "diode")
			{
				color = map_colors::alpha_diode;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "elbow")
			{
				color = map_colors::alpha_elbow;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "emitter")
			{
				color = map_colors::alpha_emitter;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "inverter")
			{
				color = map_colors::alpha_inverter;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "junction")
			{
				color = map_colors::alpha_junction;
				color.setAlpha(getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "magazine")
			{
				color = map_colors::alpha_magazine;

				const string[] MAGAZINE_ITEM = {
				"mat_bombs",
				"mat_waterbombs",
				"mat_arrows",
				"mat_waterarrows",
				"mat_firearrows",
				"mat_bombarrows",
				"food"};

				u8 alpha = MAGAZINE_ITEM.length;

				CInventory@ inventory = this.getInventory();
				if(inventory.isFull())
				{
					CBlob@ blob = inventory.getItem(0);

					s8 element = MAGAZINE_ITEM.find(blob.getName());
					if(element != -1)
					{
						alpha = element;
					}
				}
				color.setAlpha(alpha);
			}
			else if(name == "oscillator")
			{
				color = map_colors::alpha_oscillator;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "randomizer")
			{
				color = map_colors::alpha_randomizer;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "receiver")
			{
				color = map_colors::alpha_receiver;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "resistor")
			{
				color = map_colors::alpha_resistor;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "tee")
			{
				color = map_colors::alpha_tee;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "toggle")
			{
				color = map_colors::alpha_toggle;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "transistor")
			{
				color = map_colors::alpha_transistor;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "wire")
			{
				color = map_colors::alpha_wire;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()) | getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "bolter")
			{
				color = map_colors::alpha_bolter;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()));
			}
			else if(name == "dispenser")
			{
				color = map_colors::alpha_dispenser;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()));
			}
			else if(name == "lamp")
			{
				color = map_colors::alpha_lamp;
				color.setAlpha(getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "obstructor")
			{
				color = map_colors::alpha_obstructor;
				color.setAlpha(getChannelFromTeam(this.getTeamNum()));
			}
			else if(name == "spiker")
			{
				color = map_colors::alpha_spiker;
				color.setAlpha(getChannelFromAngle(this.getAngleDegrees()));
			}
		}

		// FLORA
		if(name == "bush")
		{
			color = map_colors::bush;
		}
		else if(name == "flowers")
		{
			color = map_colors::flowers;
		}
		else if(name == "grain_plant")
		{
			color = map_colors::grain;
		}
		else if(name == "tree_pine" || name == "tree_bushy")
		{
			color = map_colors::tree;
		}
		// FAUNA
		else if(name == "bison")
		{
			color = map_colors::bison;
		}
		else if(name == "chicken")
		{
			color = map_colors::chicken;
		}
		else if(name == "fishy")
		{
			color = map_colors::fish;
		}
		else if(name == "shark")
		{
			color = map_colors::shark;
		}

		// set last bit to true so the minimum alpha is 128
		u8 alpha = color.getAlpha();
		if(alpha != 0xFF)
		{
			color.setAlpha(0x80 | alpha);
		}
	}
}

/*
void SaveMap(CMap@ map, const string &in fileName)
{
	const u32 width = map.tilemapwidth;
	const u32 height = map.tilemapheight;
	const u32 space = width * height;

	CFileImage image(width, height, true);
	image.setFilename(fileName, IMAGE_FILENAME_BASE_MAPS);

	// image starts at -1, 0
	image.nextPixel();

	// iterate through tiles
	for(uint i = 0; i < space; i++)
	{
		SColor color = getColorFromTileType(map.getTile(i).type);
		if(map.isInWater(map.getTileWorldPosition(i)))
		{
			if(color == map_colors::sky)
			{
				color = map_colors::water_air;
			}
			else
			{
				color = map_colors::water_backdirt;
			}
		}
		image.setPixelAndAdvance(color);
	}

	// iterate through blobs
	CBlob@[] blobs;
	getBlobs(@blobs);
	for(uint i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		if(blob.getShape() is null) continue;

		SColor color;
		Vec2f offset;

		getInfoFromBlob(blob, color, offset);
		if(color == map_colors::unused) continue;

		const Vec2f position = map.getTileSpacePosition(blob.getPosition() + offset);

		image.setPixelAtPosition(position.x, position.y, color, false);
	}

	// iterate through markers
	const array<string> TEAM_NAME =
	{
		"blue",
		"red",
		"green",
		"purple",
		"orange",
		"aqua",
		"teal",
		"gray"
	};

	for(u8 i = 0; i < TEAM_NAME.length; i++)
	{
		array<Vec2f> position;

		SColor color;

		if(map.getMarkers(TEAM_NAME[i]+" main spawn", @position))
		{
			for(u8 j = 0; j < position.length; j++)
			{
				color = map_colors::alpha_spawn;
				color.setAlpha(0x80 | getChannelFromTeam(i));
				position[j] = map.getTileSpacePosition(position[j]);

				image.setPixelAtPosition(position[j].x, position[j].y, color, false);
			}
		}

		position.clear();
		if(map.getMarkers(TEAM_NAME[i]+" spawn", @position))
		{
			for(u8 j = 0; j < position.length; j++)
			{
				color = map_colors::alpha_flag;
				color.setAlpha(0x80 | getChannelFromTeam(i));
				position[j] = map.getTileSpacePosition(position[j]);

				image.setPixelAtPosition(position[j].x, position[j].y, color, false);
			}
		}
	}

	image.Save();
}
*/

SColor getColorFromTileType(TileType tile)
{
	if(tile >= TILE_LUT.length)
	{
		return map_colors::unused;
	}
	return TILE_LUT[tile];
}

bool isColorSolid(SColor color)
{
	s32 index = TILE_LUT.find(color);
	return index < 0 ? false : getMap().isTileSolid(index);
}

const SColor[] TILE_LUT = {
map_colors::unused,                // |   0 |
map_colors::unused,                // |   1 |
map_colors::unused,                // |   2 |
map_colors::unused,                // |   3 |
map_colors::unused,                // |   4 |
map_colors::unused,                // |   5 |
map_colors::unused,                // |   6 |
map_colors::unused,                // |   7 |
map_colors::unused,                // |   8 |
map_colors::unused,                // |   9 |
map_colors::unused,                // |  10 |
map_colors::unused,                // |  11 |
map_colors::unused,                // |  12 |
map_colors::unused,                // |  13 |
map_colors::unused,                // |  14 |
map_colors::unused,                // |  15 |
map_colors::tile_ground,           // |  16 |
map_colors::tile_ground,           // |  17 |
map_colors::tile_ground,           // |  18 |
map_colors::tile_ground,           // |  19 |
map_colors::tile_ground,           // |  20 |
map_colors::tile_ground,           // |  21 |
map_colors::tile_ground,           // |  22 |
map_colors::tile_ground,           // |  23 |
map_colors::tile_ground,           // |  24 |
map_colors::tile_grass,            // |  25 |
map_colors::tile_grass,            // |  26 |
map_colors::tile_grass,            // |  27 |
map_colors::tile_grass,            // |  28 |
map_colors::tile_ground,           // |  29 | damaged
map_colors::tile_ground,           // |  30 | damaged
map_colors::tile_ground,           // |  31 | damaged
map_colors::tile_ground_back,      // |  32 |
map_colors::tile_ground_back,      // |  33 |
map_colors::tile_ground_back,      // |  34 |
map_colors::tile_ground_back,      // |  35 |
map_colors::tile_ground_back,      // |  36 |
map_colors::tile_ground_back,      // |  37 |
map_colors::tile_ground_back,      // |  38 |
map_colors::tile_ground_back,      // |  39 |
map_colors::tile_ground_back,      // |  40 |
map_colors::tile_ground_back,      // |  41 |
map_colors::unused,                // |  42 |
map_colors::unused,                // |  43 |
map_colors::unused,                // |  44 |
map_colors::unused,                // |  45 |
map_colors::unused,                // |  46 |
map_colors::unused,                // |  47 |
map_colors::tile_castle,           // |  48 |
map_colors::tile_castle,           // |  49 |
map_colors::tile_castle,           // |  50 |
map_colors::tile_castle,           // |  51 |
map_colors::tile_castle,           // |  52 |
map_colors::tile_castle,           // |  53 |
map_colors::tile_castle,           // |  54 |
map_colors::unused,                // |  55 |
map_colors::unused,                // |  56 |
map_colors::unused,                // |  57 |
map_colors::tile_castle,           // |  58 | damaged
map_colors::tile_castle,           // |  59 | damaged
map_colors::tile_castle,           // |  60 | damaged
map_colors::tile_castle,           // |  61 | damaged
map_colors::tile_castle,           // |  62 | damaged
map_colors::tile_castle,           // |  63 | damaged
map_colors::tile_castle_back,      // |  64 |
map_colors::tile_castle_back,      // |  65 |
map_colors::tile_castle_back,      // |  66 |
map_colors::tile_castle_back,      // |  67 |
map_colors::tile_castle_back,      // |  68 |
map_colors::tile_castle_back,      // |  69 |
map_colors::unused,                // |  70 |
map_colors::unused,                // |  71 |
map_colors::unused,                // |  72 |
map_colors::unused,                // |  73 |
map_colors::unused,                // |  74 |
map_colors::unused,                // |  75 |
map_colors::tile_castle_back,      // |  76 | damaged
map_colors::tile_castle_back,      // |  77 | damaged
map_colors::tile_castle_back,      // |  78 | damaged
map_colors::tile_castle_back,      // |  79 | damaged
map_colors::tile_gold,             // |  80 |
map_colors::tile_gold,             // |  81 |
map_colors::tile_gold,             // |  82 |
map_colors::tile_gold,             // |  83 |
map_colors::tile_gold,             // |  84 |
map_colors::tile_gold,             // |  85 |
map_colors::unused,                // |  86 |
map_colors::unused,                // |  87 |
map_colors::unused,                // |  88 |
map_colors::unused,                // |  89 |
map_colors::tile_gold,             // |  90 | damaged
map_colors::tile_gold,             // |  91 | damaged
map_colors::tile_gold,             // |  92 | damaged
map_colors::tile_gold,             // |  93 | damaged
map_colors::tile_gold,             // |  94 | damaged
map_colors::unused,                // |  95 |
map_colors::tile_stone,            // |  96 |
map_colors::tile_stone,            // |  97 |
map_colors::unused,                // |  98 |
map_colors::unused,                // |  99 |
map_colors::tile_stone,            // | 100 | damaged
map_colors::tile_stone,            // | 101 | damaged
map_colors::tile_stone,            // | 102 | damaged
map_colors::tile_stone,            // | 103 | damaged
map_colors::tile_stone,            // | 104 | damaged
map_colors::unused,                // | 105 |
map_colors::tile_bedrock,          // | 106 |
map_colors::tile_bedrock,          // | 107 |
map_colors::tile_bedrock,          // | 108 |
map_colors::tile_bedrock,          // | 109 |
map_colors::tile_bedrock,          // | 110 |
map_colors::tile_bedrock,          // | 111 |
map_colors::unused,                // | 112 |

map_colors::unused,                // | 113 |
map_colors::unused,                // | 114 |
map_colors::unused,                // | 115 |
map_colors::unused,                // | 116 |
map_colors::unused,                // | 117 |
map_colors::unused,                // | 118 |
map_colors::unused,                // | 119 |
map_colors::unused,                // | 120 |
map_colors::unused,                // | 121 |
map_colors::unused,                // | 122 |
map_colors::unused,                // | 123 |
map_colors::unused,                // | 124 |
map_colors::unused,                // | 125 |
map_colors::unused,                // | 126 |
map_colors::unused,                // | 127 |
map_colors::unused,                // | 128 |
map_colors::unused,                // | 129 |
map_colors::unused,                // | 130 |
map_colors::unused,                // | 131 |
map_colors::unused,                // | 132 |
map_colors::unused,                // | 133 |
map_colors::unused,                // | 134 |
map_colors::unused,                // | 135 |
map_colors::unused,                // | 136 |
map_colors::unused,                // | 137 |
map_colors::unused,                // | 138 |
map_colors::unused,                // | 139 |
map_colors::unused,                // | 140 |
map_colors::unused,                // | 141 |
map_colors::unused,                // | 142 |
map_colors::unused,                // | 143 |
map_colors::unused,                // | 144 |
map_colors::unused,                // | 145 |
map_colors::unused,                // | 146 |
map_colors::unused,                // | 147 |
map_colors::unused,                // | 148 |
map_colors::unused,                // | 149 |
map_colors::unused,                // | 150 |
map_colors::unused,                // | 151 |
map_colors::unused,                // | 152 |
map_colors::unused,                // | 153 |
map_colors::unused,                // | 154 |
map_colors::unused,                // | 155 |
map_colors::unused,                // | 156 |
map_colors::unused,                // | 157 |
map_colors::unused,                // | 158 |
map_colors::unused,                // | 159 |
map_colors::unused,                // | 160 |
map_colors::unused,                // | 161 |
map_colors::unused,                // | 162 |
map_colors::unused,                // | 163 |
map_colors::unused,                // | 164 |
map_colors::unused,                // | 165 |
map_colors::unused,                // | 166 |
map_colors::unused,                // | 167 |
map_colors::unused,                // | 168 |
map_colors::unused,                // | 169 |
map_colors::unused,                // | 170 |
map_colors::unused,                // | 171 |
map_colors::unused,                // | 172 |
map_colors::tile_wood_back,        // | 173 |
map_colors::unused,                // | 174 |
map_colors::unused,                // | 175 |
map_colors::unused,                // | 176 |
map_colors::unused,                // | 177 |
map_colors::unused,                // | 178 |
map_colors::unused,                // | 179 |
map_colors::unused,                // | 180 |
map_colors::unused,                // | 181 |
map_colors::unused,                // | 182 |
map_colors::unused,                // | 183 |
map_colors::unused,                // | 184 |
map_colors::unused,                // | 185 |
map_colors::unused,                // | 186 |
map_colors::unused,                // | 187 |
map_colors::unused,                // | 188 |
map_colors::unused,                // | 189 |
map_colors::unused,                // | 190 |
map_colors::unused,                // | 191 |
map_colors::unused,                // | 192 |
map_colors::unused,                // | 193 |
map_colors::unused,                // | 194 |
map_colors::unused,                // | 195 |
map_colors::tile_wood,             // | 196 |
map_colors::tile_wood,             // | 197 |
map_colors::tile_wood,             // | 198 |
map_colors::unused,                // | 199 |
map_colors::tile_wood,             // | 200 | damaged
map_colors::tile_wood,             // | 201 | damaged
map_colors::tile_wood,             // | 202 | damaged
map_colors::tile_wood,             // | 203 | damaged
map_colors::tile_wood,             // | 204 | damaged
map_colors::tile_wood_back,        // | 205 |
map_colors::tile_wood_back,        // | 206 |
map_colors::tile_wood_back,        // | 207 | damaged
map_colors::tile_thickstone,       // | 208 |
map_colors::tile_thickstone,       // | 209 |
map_colors::unused,                // | 210 |
map_colors::unused,                // | 211 |
map_colors::unused,                // | 212 |
map_colors::unused,                // | 213 |
map_colors::tile_thickstone,       // | 214 | damaged
map_colors::tile_thickstone,       // | 215 | damaged
map_colors::tile_thickstone,       // | 216 | damaged
map_colors::tile_thickstone,       // | 217 | damaged
map_colors::tile_thickstone,       // | 218 | damaged
map_colors::unused,                // | 219 |
map_colors::unused,                // | 220 |
map_colors::unused,                // | 221 |
map_colors::unused,                // | 222 |
map_colors::unused,                // | 223 |
map_colors::tile_castle_moss,      // | 224 |
map_colors::tile_castle_moss,      // | 225 |
map_colors::tile_castle_moss,      // | 226 |
map_colors::tile_castle_back_moss, // | 227 |
map_colors::tile_castle_back_moss, // | 228 |
map_colors::tile_castle_back_moss, // | 229 |
map_colors::tile_castle_back_moss, // | 230 |
map_colors::tile_castle_back_moss, // | 231 |
map_colors::unused,                // | 232 |
map_colors::unused,                // | 233 |
map_colors::unused,                // | 234 |
map_colors::unused,                // | 235 |
map_colors::unused,                // | 236 |
map_colors::unused,                // | 237 |
map_colors::unused,                // | 238 |
map_colors::unused,                // | 239 |
map_colors::unused,                // | 240 |
map_colors::unused,                // | 241 |
map_colors::unused,                // | 242 |
map_colors::unused,                // | 243 |
map_colors::unused,                // | 244 |
map_colors::unused,                // | 245 |
map_colors::unused,                // | 246 |
map_colors::unused,                // | 247 |
map_colors::unused,                // | 248 |
map_colors::unused,                // | 249 |
map_colors::unused,                // | 250 |
map_colors::unused,                // | 251 |
map_colors::unused,                // | 252 |
map_colors::unused,                // | 253 |
map_colors::unused,                // | 254 |
map_colors::unused};               // | 255 |
