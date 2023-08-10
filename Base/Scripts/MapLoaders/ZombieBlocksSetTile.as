
#include "ZombieBlocksCommon.as"

void ZombieSetTile(CMap@ this, u32 index, TileType newtile)
{
    TileType tile_type = newtile % WORLD_OFFSET;

    s32 x = index % this.tilemapwidth, y = index / this.tilemapwidth;
    if (x < 0 || y < 0 || x >= this.tilemapwidth || y >= this.tilemapheight) {
        return;
    }
    s32 seed = x * y - 2 * y;

    TileType tback, i, j, k, l, m, n;
    bool mirror = false, flip = false, rotate = false, left = false, right = false, nocollide = false, front = true;

    bool on_left = x == 0;
    bool on_top = y == 0;
    bool on_right = x == this.tilemapwidth-1;
    bool on_bottom = y == this.tilemapheight-1;
    
    switch (tile_type)
    {
        case CMap::tile_ground:
            if (!on_top && isGrass(getTile(this, x, y - 1))) // grass
            {
                newtile += 7 + (x + y) % 2;
            }
            else
            {
                TileType around = ((on_top    || isEmpty(getTile(this, x, y - 1))) ? 1  : 0) |
                                    ((on_bottom || isEmpty(getTile(this, x, y + 1))) ? 2  : 0) |
                                    ((on_left   || isEmpty(getTile(this, x - 1, y))) ? 4  : 0) |
                                    ((on_right  || isEmpty(getTile(this, x + 1, y))) ? 8  : 0) |
                                    ((y <= 1    || isEmpty(getTile(this, x, y - 2))) ? 16 : 0) |
                                    ((on_left   || on_top || isEmpty(getTile(this, x - 1, y - 1))) ? 32 : 0) |
                                    ((on_right  || on_top || isEmpty(getTile(this, x + 1, y - 1))) ? 64 : 0);

                if (around & 1 > 0)
                {
                    ; //nothing, we win
                }
                else if (around & 2 > 0)
                {
                    newtile += 4;
                }
                else if ((around & 4  > 0) && (around & 8 > 0))
                {
                    newtile += (3 + y % 2);
                }
                else if (around & 4 > 0)
                {
                    newtile += 3;
                }
                else if (around & 8 > 0)
                {
                    newtile += 2;
                }
                else if ((around & 16 > 0) || (around & 32 > 0) || (around & 64 > 0))
                {
                    newtile += 1;
                }
                else
                {
                    newtile += 5 + ((x + y) % 2);
                }
            }
    
            // if (isTileUnderGround(offset)) {
            //     tback = CMap::tile_ground_back;
            // }
    
            break;

        case CMap::tile_castle:
            i = on_top ? 0 : getTile(this, x, y - 1);
            j = on_bottom ? 0 : getTile(this, x, y + 1);
            k = y > 3 ? getTile(this, x, y - 2) : 0;
            l = y < this.tilemapheight - 3 ? getTile(this, x, y + 2) : 0;
            m = on_right ? 0 : getTile(this, x + 1, y);
            n = on_left ? 0 : getTile(this, x - 1, y);

            if (isCastleBackwall(i))  // floor
            { 
                newtile += 2;
            }
            else if (isCastleBackwall(j))  // ceiling
            { 
                newtile += 3;
                mirror = (x + y) % 2 == 0;
            }
            else if (isCastleBackwall(m) && isCastleBackwall(n) && isCastle(i) && isCastle(j))
            {
                newtile += 4;
                mirror = (x + y) % 2 == 0;
            }
            else if ((isCastleBackwall(m) || isCastleBackwall(n)) && isCastle(i) && isCastle(j))
            {
                newtile += 4;

                if (isCastleBackwall(n))
                {
                    mirror = true;
                }
            }
            else
            {
                newtile += (x + y) % 2;
            }
            break;
    
        case CMap::tile_castle_moss:
            i = on_top ? 0 : getTile(this, x, y - 1);
            j = on_bottom ? 0 : getTile(this, x, y + 1);
            k = y > 2 ? getTile(this, x, y - 2) : 0;
            l = y < this.tilemapheight - 2 ? getTile(this, x, y + 2) : 0;
    
            if (isCastleBackwall(i)) // floor
            {
                newtile += 2;
            }
            else if (isCastleBackwall(j)) // ceiling
            {
                newtile += 1;
            }
    
            break;
        
        case CMap::tile_castle_back:
            front = false;
            i = on_top ? 0 : getTile(this, x, y - 1);
            j = on_bottom ? 0 : getTile(this, x, y + 1);
            k = on_left ? 0 : getTile(this, x - 1, y);
            l = on_right ? 0 : getTile(this, x + 1, y);
    
            if (isEmpty(i)) {
                newtile += 5;
            }
            else if (isEmpty(k) && isEmpty(l))
            {
                newtile += 4;
                mirror = (x + y) % 2 == 0;
            }
            else if (isEmpty(k) || isEmpty(l))
            {
                newtile += 4;
    
                if (isEmpty(l))
                {
                    mirror = true;
                }
            }
            else if (isSolid(j))
            {
                newtile += 1;
            }
            else if (!isSolid(i))
            {
                newtile += 2 + (x + y) % 2;
            }
            break;
    
        case CMap::tile_castle_back_moss:
            front = false;
            i = on_top ? 0 : getTile(this, x, y - 1);
            j = on_bottom ? 0 : getTile(this, x, y + 1);
            k = on_left ? 0 : getTile(this, x - 1, y);
            l = on_right ? 0 : getTile(this, x + 1, y);
    
            if (isSolid(j))
            {
                newtile += 1;
            }
            else if (isSolid(i))
            {
                newtile += 4;
            }
            else
            {
                newtile += randomRanged(x, y, 4);  // fastrandom(x * y, 4); // hey we don't need cryptographic rand
            }
            break;
        
        case CMap::tile_gold:
            newtile += randomRanged(x, y, 5);
            break;
    
        case CMap::tile_stone:
            newtile += (x + y) % 2;
            break;
    
        case CMap::tile_thickstone:
            newtile += (x + y) % 2;
            break;
    
        case CMap::tile_bedrock:
            if (on_top || !isSolid(getTile(this, x, y - 1)))
            {
                newtile += 3 + randomRanged(x, y, 3);
            }
            else
            {
                newtile += randomRanged(x, y, 4);
            }
    
            break;
        
        case CMap::tile_wood:
            mirror = (x + y) % 2 == 1;
            if ((on_bottom ||
                    isWoodBackwall(getTile(this, x, y + 1)) ||
                    isCastleBackwall(getTile(this, x, y + 1))) &&
                (on_top ||
                    isSolid(getTile(this, x, y - 1))))
            {
                newtile += 1;
            }
            else if ((on_bottom ||
                        isSolid(getTile(this, x, y + 1))) &&
                        (on_top ||
                        isSolid(getTile(this, x, y - 1))))
                {
                newtile += 2;
            }
            break;
    
        case CMap::tile_wood_back:
            front = false;
            i = on_left ? 0 : getTile(this, x - 1, y);
            j = on_right ? 0 : getTile(this, x + 1, y);

            left = isWoodBackwall(i) || isSolid(i);
            right = isWoodBackwall(j) || isSolid(j);

            if (!left && !right)
            {
                newtile -= 32;
            }
            else if (left && !right)
            {
                newtile += 1;
            }
            else if (right && !left)
            {
                newtile += 1;
                mirror = true;
            }
            break;

        // case CMap::tile_tree_chopped_up:
        //     t = 0;
        //     break;
    }
        
    // castle back

    if (isCastleBackwall(newtile))
    {
        // if (isTileUnderGround(offset)) {
        //     tback = tile_ground_back;
        // }

        front = false;
    }

    //woodback (todo: some sort of scripted option for this)

    if (isWoodBackwall(newtile))
    {
        // if (isTileUnderGround(offset)) {
        //     tback = tile_ground_back;
        // }

        front = false;
    }

    // grass

    if (isGrass(newtile))
    {
        nocollide = true;
    }

    if (isDirtBackwall(newtile))
    {
        front = false;
        TileType around = ((on_top    || isEmpty(getTile(this, x, y - 1))) ? 1 : 0) |
                          ((on_bottom || isEmpty(getTile(this, x, y + 1))) ? 2 : 0) |
                          ((on_left   || isEmpty(getTile(this, x - 1, y))) ? 4 : 0) |
                          ((on_right  || isEmpty(getTile(this, x + 1, y))) ? 8 : 0);

        if (around != 0)
        {
            switch (around)
            {
                // endpieces
                case 2 | 4 | 8:
                    flip = true;
    
                case 1 | 4 | 8:
                    newtile += 9;
                    break;
    
                case 1 | 2 | 4:
                    mirror = true;
    
                case 1 | 2 | 8:
                case 1 | 2 | 4 | 8:
                    rotate = true;
                    newtile += 9;
                    break;
    
                // straight pieces
                case 4 | 8:
                    rotate = true;
    
                case 1 | 2:
                    newtile += 8;
                    break;
    
                // edge pieces
                case 2:
                    flip = true;
    
                case 1:
                    newtile += 7;
                    break;
    
                case 4:
                    mirror = true;
    
                case 8:
                    rotate = true;
                    newtile += 7;
                    break;
    
                    //corners
                case 1 | 8:
                    mirror = true;
    
                case 1 | 4:
                    newtile += 6;
                    break;
    
                case 2 | 8:
                    mirror = true;
    
                case 2 | 4:
                    flip = true;
                    newtile += 6;
                    break;
            }
        }
        else if ((on_bottom || isSolid(getTile(this, x, y + 1))) &&
                !(on_top    || isSolid(getTile(this, x, y - 1))))
        {
            newtile += 5;
        }
        else if ((on_top    || isSolid(getTile(this, x, y - 1))) &&
                !(on_bottom || isSolid(getTile(this, x, y + 1))))
        {
            newtile += 4;
        }
        else
        {
            newtile += x % 2 + 2 * (y % 2);    //meta-tiling
        }
    }

    if (isWoodBackwall(newtile))
    {
        front = false;
    }

    if (newtile >= 200 && newtile <= 204)
    {
        rotate = true;
    }

    // if (tback > 0)
    // {
    //     MakeTileVariation_Legacy( x, y, tback, dummy, backmirror, backflip, backrotate, dummybool, dummybool, dummybool, dummybool );
    // }
    
    if (!isServer())
    {
        this.SetTile(index, newtile);
    }
    
    u32 new_flags = ZOMBIE_TILE_FLAGS[tile_type];
    if (mirror)
    {
        new_flags |= Tile::MIRROR;
    }
    if (flip)
    {
        new_flags |= Tile::FLIP;
    }
    if (rotate)
    {
        new_flags |= Tile::ROTATE;
    }
    if (!front)
    {
        // flags |= Tile::SOLID;
        new_flags &= ~Tile::TileFlags::BACKGROUND;
    }
    
    u32 old_flags = this.getTileFlags(index);
    this.RemoveTileFlag(index, old_flags & ~new_flags);
    this.AddTileFlag(index, new_flags & ~old_flags);
    // this.SetTileSupport(index, 255);
}
