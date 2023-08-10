
// Binary spaces for tile flags
// SPARE_4|SPARE_3|SPARE_2|COLLISION ROTATE|FLIP|MIRROR|LIGHT_SOURCE PLATFORM|FLAMMABLE|WATER_PASSES|LIGHT_PASSES LADDER|SOLID|BACKGROUND|SPARE_0

const u32 EMPTY = Tile::LIGHT_PASSES | Tile::WATER_PASSES;
const u32 AIR = Tile::LIGHT_SOURCE | EMPTY;
const u32 GRASS = Tile::FLAMMABLE | Tile::BACKGROUND | AIR;

const u32 BACKWALL = Tile::BACKGROUND | EMPTY;
const u32 LIGHT_BACKWALL = Tile::LIGHT_SOURCE | BACKWALL;
const u32 WOOD_BACKWALL = Tile::FLAMMABLE | BACKWALL;
const u32 LIGHT_WOOD_BACKWALL = Tile::FLAMMABLE | LIGHT_BACKWALL;

const u32 SOLID = Tile::SOLID | Tile::COLLISION;
const u32 WOOD_BLOCK = Tile::FLAMMABLE | SOLID;

const u16 WORLD_OFFSET = 272;
const u32[] ZOMBIE_TILE_FLAGS = {
    // Air
    AIR,  // 0

    // Unused dirt backwall?
    EMPTY,  // 1
    EMPTY,  // 2
    EMPTY,  // 3
    EMPTY,  // 4

    // Empty
    EMPTY,  // 5 
    EMPTY,  // 6 
    EMPTY,  // 7 
    EMPTY,  // 8 
    EMPTY,  // 9 
    EMPTY,  // 10
    EMPTY,  // 11
    EMPTY,  // 12
    EMPTY,  // 13
    EMPTY,  // 14
    EMPTY,  // 15

    // Dirt blocks
    SOLID,  // 16
    SOLID,  // 17
    SOLID,  // 18
    SOLID,  // 19
    SOLID,  // 20
    SOLID,  // 21
    SOLID,  // 22

    // Dirt blocks with grass on top
    SOLID,  // 23
    SOLID,  // 24

    // Grass blocks
    GRASS,  // 25
    GRASS,  // 26 
    GRASS,  // 27
    GRASS,  // 28

    // Damaged dirt blocks
    SOLID,  // 29
    SOLID,  // 30
    SOLID,  // 31

    // Dirt backwall
    BACKWALL,  // 32
    BACKWALL,  // 33
    BACKWALL,  // 34
    BACKWALL,  // 35
    BACKWALL,  // 36
    BACKWALL,  // 37
    BACKWALL,  // 38
    BACKWALL,  // 39
    BACKWALL,  // 40
    BACKWALL,  // 41

    // Empty
    EMPTY,  // 42
    EMPTY,  // 43
    EMPTY,  // 44
    EMPTY,  // 45
    EMPTY,  // 46
    EMPTY,  // 47

    // Stone blocks
    SOLID,  // 48
    SOLID,  // 49
    SOLID,  // 50
    SOLID,  // 51
    SOLID,  // 52
    SOLID,  // 53
    SOLID,  // 54

    // Empty
    EMPTY,  // 55
    EMPTY,  // 56
    EMPTY,  // 57

    // Damaged stone blocks
    SOLID,  // 58
    SOLID,  // 59
    SOLID,  // 60
    SOLID,  // 61
    SOLID,  // 62
    SOLID,  // 63

    // Stone backwall
    BACKWALL,  // 64
    BACKWALL,  // 65
    BACKWALL,  // 66
    BACKWALL,  // 67
    BACKWALL,  // 68
    BACKWALL,  // 69

    // Empty
    EMPTY,  // 70
    EMPTY,  // 71
    EMPTY,  // 72
    EMPTY,  // 73

    // Weird unused dirt arches
    SOLID,  // 74
    SOLID,  // 75

    // Damaged stone backwall
    BACKWALL,        // 76
    BACKWALL,        // 77
    LIGHT_BACKWALL,  // 78
    LIGHT_BACKWALL,  // 79

    // Gold blocks
    SOLID,  // 80
    SOLID,  // 81
    SOLID,  // 82
    SOLID,  // 83
    SOLID,  // 84
    SOLID,  // 85

    // Empty
    EMPTY,  // 86
    EMPTY,  // 87
    EMPTY,  // 88
    EMPTY,  // 89

    // Damaged gold blocks
    SOLID,  // 90
    SOLID,  // 91
    SOLID,  // 92
    SOLID,  // 93
    SOLID,  // 94

    // Empty
    EMPTY,  // 95

    // Stone ore
    SOLID,  // 96
    SOLID,  // 97

    // Empty
    EMPTY,  // 98
    EMPTY,  // 99

    // Damaged stone ore
    SOLID,  // 100
    SOLID,  // 101
    SOLID,  // 102
    SOLID,  // 103
    SOLID,  // 104

    // Empty
    EMPTY,  // 105

    // Bedrock
    SOLID,  // 106
    SOLID,  // 107
    SOLID,  // 108
    SOLID,  // 109
    SOLID,  // 110
    SOLID,  // 111

    // Empty
    EMPTY,  // 112
    EMPTY,  // 113
    EMPTY,  // 114
    EMPTY,  // 115
    EMPTY,  // 116
    EMPTY,  // 117
    EMPTY,  // 118
    EMPTY,  // 119
    EMPTY,  // 120
    EMPTY,  // 121
    EMPTY,  // 122
    EMPTY,  // 123
    EMPTY,  // 124
    EMPTY,  // 125
    EMPTY,  // 126
    EMPTY,  // 127
    
    EMPTY,  // 128
    EMPTY,  // 129
    EMPTY,  // 130
    EMPTY,  // 131
    EMPTY,  // 132
    EMPTY,  // 133
    EMPTY,  // 134
    EMPTY,  // 135
    EMPTY,  // 136
    EMPTY,  // 137
    EMPTY,  // 138
    EMPTY,  // 139
    EMPTY,  // 140
    EMPTY,  // 141
    EMPTY,  // 142
    EMPTY,  // 143

    EMPTY,  // 144
    EMPTY,  // 145
    EMPTY,  // 146
    EMPTY,  // 147
    EMPTY,  // 148
    EMPTY,  // 149
    EMPTY,  // 150
    EMPTY,  // 151
    EMPTY,  // 152
    EMPTY,  // 153
    EMPTY,  // 154

    // Solid stone rubble
    SOLID,  // 155
    SOLID,  // 156

    // Nonsolid stone rubble
    LIGHT_BACKWALL,  // 157
    LIGHT_BACKWALL,  // 158
    LIGHT_BACKWALL,  // 159

    // Empty
    EMPTY,  // 160
    EMPTY,  // 161
    EMPTY,  // 162
    EMPTY,  // 163
    EMPTY,  // 164
    EMPTY,  // 165
    EMPTY,  // 166
    EMPTY,  // 167
    EMPTY,  // 168
    EMPTY,  // 169
    EMPTY,  // 170
    EMPTY,  // 171
    EMPTY,  // 172

    // Wood backwall
    BACKWALL,  // 173
    
    // Empty
    EMPTY,  // 174
    EMPTY,  // 175

    EMPTY,  // 176
    EMPTY,  // 177
    EMPTY,  // 178
    EMPTY,  // 179
    EMPTY,  // 180
    EMPTY,  // 181
    EMPTY,  // 182
    EMPTY,  // 183
    EMPTY,  // 184
    EMPTY,  // 185
    EMPTY,  // 186
    EMPTY,  // 187
    EMPTY,  // 188
    EMPTY,  // 189
    EMPTY,  // 190
    EMPTY,  // 191

    EMPTY,  // 192
    EMPTY,  // 193
    EMPTY,  // 194
    EMPTY,  // 195

    // Wood blocks
    WOOD_BLOCK,  // 196
    WOOD_BLOCK,  // 197
    WOOD_BLOCK,  // 198
    WOOD_BLOCK,  // 199
    WOOD_BLOCK,  // 200
    WOOD_BLOCK,  // 201
    WOOD_BLOCK,  // 202
    WOOD_BLOCK,  // 203
    WOOD_BLOCK,  // 204

    // Wood backwall
    WOOD_BACKWALL,        // 205
    WOOD_BACKWALL,        // 206
    LIGHT_WOOD_BACKWALL,  // 207

    // Thickstone ore
    SOLID,  // 208
    SOLID,  // 209

    // Empty
    EMPTY,  // 210
    EMPTY,  // 211
    EMPTY,  // 212
    EMPTY,  // 213

    // Damaged thickstone ore
    SOLID,  // 214
    SOLID,  // 215
    SOLID,  // 216
    SOLID,  // 217
    SOLID,  // 218

    // Empty
    EMPTY,  // 219

    // Sand?
    SOLID,  // 220
    SOLID,  // 221
    SOLID,  // 222
    SOLID,  // 223

    // Mossy stone blocks
    SOLID,  // 224
    SOLID,  // 225
    SOLID,  // 226

    // Mossy stone backwall 
    BACKWALL,  // 227
    BACKWALL,  // 228
    BACKWALL,  // 229
    BACKWALL,  // 230
    BACKWALL,  // 231

    // Empty
    EMPTY,  // 232
    EMPTY,  // 233
    EMPTY,  // 234
    EMPTY,  // 235
    EMPTY,  // 236
    EMPTY,  // 237
    EMPTY,  // 238
    EMPTY,  // 239

    EMPTY,  // 240
    EMPTY,  // 241
    EMPTY,  // 242
    EMPTY,  // 243
    EMPTY,  // 244
    EMPTY,  // 245
    EMPTY,  // 246
    EMPTY,  // 247
    EMPTY,  // 248
    EMPTY,  // 249
    EMPTY,  // 250
    EMPTY,  // 251
    EMPTY,  // 252
    EMPTY,  // 253
    EMPTY,  // 254
    EMPTY,  // 255
    
    // Trap blocks
    EMPTY,  // 256
    EMPTY,  // 257
    EMPTY,  // 258
    EMPTY,  // 259
    EMPTY,  // 260
    EMPTY,  // 261

    // Empty
    EMPTY,  // 262
    EMPTY,  // 263
    EMPTY,  // 264
    EMPTY,  // 265
    EMPTY,  // 266
    EMPTY,  // 267
    EMPTY,  // 268
    EMPTY,  // 269
    EMPTY,  // 270
    EMPTY   // 271
};

TileType getTile(CMap@ map, s32 x, s32 y)
{
    return map.getTile(x + y * map.tilemapwidth).type;
}

bool isNaturalSolid(TileType type)
{
    return isDirt(type) || isStone(type) || isThickStone(type) || isGold(type);
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

// u32 getTileFlags(TileType type)
// {
//     switch (type)
//     {
//         // Air
//         case 0:
//             return AIR;

//         // Unused dirt backwall?
//         case 1:
//         case 2:
//         case 3:
//         case 4:
//             return EMPTY;

//         // Empty
//         case 5: 
//         case 6: 
//         case 7: 
//         case 8: 
//         case 9: 
//         case 10:
//         case 11:
//         case 12:
//         case 13:
//         case 14:
//         case 15:
//             return EMPTY;

//         // Dirt blocks
//         case 16:
//         case 17:
//         case 18:
//         case 19:
//         case 20:
//         case 21:
//         case 22:
//             return SOLID;

//         // Dirt blocks with grass on top
//         case 23:
//         case 24:
//             return SOLID;

//         // Grass blocks
//         case 25:
//         case 26: 
//         case 27:
//         case 28:
//             return GRASS;

//         // Damaged dirt blocks
//         case 29:
//         case 30:
//         case 31:
//             return SOLID;

//         // Dirt backwall
//         case 32:
//         case 33:
//         case 34:
//         case 35:
//         case 36:
//         case 37:
//         case 38:
//         case 39:
//         case 40:
//         case 41:
//             return BACKWALL;

//         // Empty
//         case 42:
//         case 43:
//         case 44:
//         case 45:
//         case 46:
//         case 47:
//             return EMPTY;

//         // Stone blocks
//         case 48:
//         case 49:
//         case 50:
//         case 51:
//         case 52:
//         case 53:
//         case 54:
//             return SOLID;

//         // Empty
//         case 55:
//         case 56:
//         case 57:
//             return EMPTY;

//         // Damaged stone blocks
//         case 58:
//         case 59:
//         case 60:
//         case 61:
//         case 62:
//         case 63:
//             return SOLID;

//         // Stone backwall
//         case 64:
//         case 65:
//         case 66:
//         case 67:
//         case 68:
//         case 69:
//             return BACKWALL;

//         // Empty
//         case 70:
//         case 71:
//         case 72:
//         case 73:
//             return EMPTY;

//         // Weird unused dirt arches
//         case 74:
//         case 75:
//             return SOLID;

//         // Damaged stone backwall
//         case 76:
//         case 77:
//             return BACKWALL;
//         case 78:
//         case 79:
//             return LIGHT_BACKWALL;
        
//         // Gold blocks
//         case 80:
//         case 81:
//         case 82:
//         case 83:
//         case 84:
//         case 85:
//             return SOLID;

//         // Empty
//         case 86:
//         case 87:
//         case 88:
//         case 89:
//             return EMPTY;

//         // Damaged gold blocks
//         case 90:
//         case 91:
//         case 92:
//         case 93:
//         case 94:
//             return SOLID;

//         // Empty
//         case 95:
//             return EMPTY;

//         // Stone ore
//         case 96:
//         case 97:
//             return SOLID;

//         // Empty
//         case 98:
//         case 99:
//             return EMPTY;

//         // Damaged stone ore
//         case 100:
//         case 101:
//         case 102:
//         case 103:
//         case 104:
//             return SOLID;

//         // Empty
//         case 105:
//             return EMPTY;

//         // Bedrock
//         case 106:
//         case 107:
//         case 108:
//         case 109:
//         case 110:
//         case 111:
//             return SOLID;

//         // Empty
//         case 112:
//         case 113:
//         case 114:
//         case 115:
//         case 116:
//         case 117:
//         case 118:
//         case 119:
//         case 120:
//         case 121:
//         case 122:
//         case 123:
//         case 124:
//         case 125:
//         case 126:
//         case 127:
        
//         case 128:
//         case 129:
//         case 130:
//         case 131:
//         case 132:
//         case 133:
//         case 134:
//         case 135:
//         case 136:
//         case 137:
//         case 138:
//         case 139:
//         case 140:
//         case 141:
//         case 142:
//         case 143:

//         case 144:
//         case 145:
//         case 146:
//         case 147:
//         case 148:
//         case 149:
//         case 150:
//         case 151:
//         case 152:
//         case 153:
//         case 154:
//             return EMPTY;
        
//         // Solid stone rubble
//         case 155:
//         case 156:
//             return SOLID;

//         // Nonsolid stone rubble
//         case 157:
//         case 158:
//         case 159:
//             return LIGHT_BACKWALL;

//         // Empty
//         case 160:
//         case 161:
//         case 162:
//         case 163:
//         case 164:
//         case 165:
//         case 166:
//         case 167:
//         case 168:
//         case 169:
//         case 170:
//         case 171:
//         case 172:
//             return EMPTY;

//         // Wood backwall
//         case 173:
//             return BACKWALL;
        
//         // Empty
//         case 174:
//         case 175:

//         case 176:
//         case 177:
//         case 178:
//         case 179:
//         case 180:
//         case 181:
//         case 182:
//         case 183:
//         case 184:
//         case 185:
//         case 186:
//         case 187:
//         case 188:
//         case 189:
//         case 190:
//         case 191:

//         case 192:
//         case 193:
//         case 194:
//         case 195:
//             return EMPTY;

//         // Wood blocks
//         case 196:
//         case 197:
//         case 198:
//         case 199:
//         case 200:
//         case 201:
//         case 202:
//         case 203:
//         case 204:
//             return WOOD_BLOCK;

//         // Wood backwall
//         case 205:
//         case 206:
//             return WOOD_BACKWALL;
//         case 207:
//             return LIGHT_WOOD_BACKWALL;

//         // Thickstone ore
//         case 208:
//         case 209:
//             return SOLID;

//         // Empty
//         case 210:
//         case 211:
//         case 212:
//         case 213:
//             return EMPTY;

//         // Damaged thickstone ore
//         case 214:
//         case 215:
//         case 216:
//         case 217:
//         case 218:
//             return SOLID;

//         // Empty
//         case 219:
//             return EMPTY;

//         // Sand?
//         case 220:
//         case 221:
//         case 222:
//         case 223:
//             return SOLID;

//         // Mossy stone blocks
//         case 224:
//         case 225:
//         case 226:
//             return SOLID;

//         // Mossy stone backwall 
//         case 227:
//         case 228:
//         case 229:
//         case 230:
//         case 231:
//             return BACKWALL;

//         // Empty
//         case 232:
//         case 233:
//         case 234:
//         case 235:
//         case 236:
//         case 237:
//         case 238:
//         case 239:

//         case 240:
//         case 241:
//         case 242:
//         case 243:
//         case 244:
//         case 245:
//         case 246:
//         case 247:
//         case 248:
//         case 249:
//         case 250:
//         case 251:
//         case 252:
//         case 253:
//         case 254:
//         case 255:
        
//         // Trap blocks
//         case 256:
//         case 257:
//         case 258:
//         case 259:
//         case 260:
//         case 261:

//         // Empty
//         case 262:
//         case 263:
//         case 264:
//         case 265:
//         case 266:
//         case 267:
//         case 268:
//         case 269:
//         case 270:
//         case 271:
//             return EMPTY;
//     }
//     return 0;
// }