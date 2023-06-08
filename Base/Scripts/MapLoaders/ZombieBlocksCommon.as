
const u16 WORLD_OFFSET = 272;
const u32[] TILEFLAGS = {
	304,  // 0b100110000
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	4100,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,   // 0b000110000
	370,  // 0b101110010
	370,
	370,
	370,
	4100,
	4100,
	4100,
	50,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	4100,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	4100,
	4100,
	4100,
	4100,
	4100,
	4100,
	50,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	4100,
	48,
	4100,
	4100,
	50,
	50,
	306,
	306,
	4100,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	4100,
	4100,
	4100,
	4100,
	48,
	4100,
	48,
	48,
	48,
	4100,
	4100,
	4100,
	4100,
	4100,
	48,
	4100,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	4164,
	4164,
	4164,
	4164,
	4164,
	4164,
	4164,
	4164,
	48,
	114,
	114,
	370,
	4100,
	48,
	48,
	48,
	48,
	48,
	4100,
	4100,
	4100,
	4100,
	4100,
	48,
	48,
	48,
	48,
	48,
	4100,
	48,
	48,
	50,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	4100,
	48,
	48,
	4100,
	4100,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	48,
	4100,
	50,
	58,
	128,
	50,
	4100,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0
};

TileType getTile(CMap@ map, s32 x, s32 y)
{
    return map.getTile(x + y * map.tilemapwidth).type;
}

bool isSolid(TileType type)
{
    return !isEmpty(type) && !isGrass(type) && !isDirtBackwall(type) && !isCastleBackwall(type) && !isWoodBackwall(type);
}

bool isEmpty(TileType type)
{
    type %= WORLD_OFFSET;
    return type == CMap::tile_empty;
}

bool isDirt(TileType type)
{
	type %= WORLD_OFFSET;
	return type >= 16 && type <= 24 ||
		   type >= 29 && type <= 31;
}

bool isDirtBackwall(TileType type)
{
    type %= WORLD_OFFSET;
    return type >= 1 && type <= 4 || type >= 32 && type <= 41;
}

bool isGrass(TileType type)
{
    type %= WORLD_OFFSET;
    return type >= 25 && type <= 28;
}

bool isStone(TileType type)
{
	type %= WORLD_OFFSET;
    return type >= CMap::tile_stone && type <= 97 ||
	       type >= CMap::tile_stone_d1 && type <= CMap::tile_stone_d0;
}

bool isThickStone(TileType type)
{
	type %= WORLD_OFFSET;
    return type >= CMap::tile_thickstone && type <= 209 ||
	       type >= CMap::tile_thickstone_d1 && type <= CMap::tile_thickstone_d0;
}

bool isGold(TileType type)
{
	type %= WORLD_OFFSET;
	return type >= CMap::tile_gold && type <= 85 ||
	       type >= 90 && type <= 94;
}

bool isBedrock(TileType type)
{
	type %= WORLD_OFFSET;
	return type >= CMap::tile_bedrock && type <= 111;
}

bool isWood(TileType type)
{
    type %= WORLD_OFFSET;
    return type >= CMap::tile_wood && type <= 198 ||
	       type >= CMap::tile_wood_d1 && type <= CMap::tile_wood_d0;
}

bool isWoodBackwall(TileType type)
{
    type %= WORLD_OFFSET;
    return type == 173 || type >= 205 && type <= 207;
}

bool isCastle(TileType type)
{
    type %= WORLD_OFFSET;
    return type >= CMap::tile_castle && type <= 54 ||
           type >= CMap::tile_castle_d1 && type <= CMap::tile_castle_d0 ||
           isMossyCastle(type);
}

bool isCastleBackwall(TileType type)
{
    type %= WORLD_OFFSET;
    return type >= CMap::tile_castle_back && type <= 69 ||
           type == CMap::tile_ladder_castle ||
           type >= 76 && type <= 79 ||
           isMossyCastleBackwall(type);
}

bool isMossyCastle(TileType type)
{
	type %= WORLD_OFFSET;
	return type >= CMap::tile_castle_moss && type <= 226;
}

bool isMossyCastleBackwall(TileType type)
{
	type %= WORLD_OFFSET;
	return type >= CMap::tile_castle_back_moss && type <= 231;
}

s32 randomRanged(u32 x, u32 y, u32 range)
{
    // Random@ random = Random(x * y);
    // return random.NextRanged(range);

    return x * y % range;
}