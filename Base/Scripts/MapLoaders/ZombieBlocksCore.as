
#include "ZombieBlocksCommon.as";

void onInit(CRules@ this)
{
    Reset();
}

void onRestart(CRules@ this)
{
    Reset();
}

void Reset()
{
    CMap@ map = getMap();
    if (map !is null)
    {
        map.AddScript("ZombieBlocksCore.as");
    }
}

void onSetTile(CMap@ this, u32 index, TileType newtile, TileType oldtile)
{
    // Only trigger on corruption events
    if (newtile + WORLD_OFFSET != oldtile && oldtile + WORLD_OFFSET != newtile)
    {
        return;
    }

    // Corrupt blobs
    if (!this.hasTileFlag(index, Tile::TileFlags::SOLID))
    {
        CBlob@[] blobs;
        this.getBlobsAtPosition(this.getTileWorldPosition(index) + Vec2f(1, 1) * this.tilesize / 2, blobs);
        for (u32 i = 0; i < blobs.length; i++)
        {
            CBlob@ blob = blobs[i];
            if (blob !is null && (
                blob.hasTag("tree") ||                                                             // Trees
                blob.hasTag("scenary") ||                                                          // Bushes, flowers, and grain 
                blob.hasTag("wooden") && blob.getShape() !is null && blob.getShape().isStatic()))  // Wooden structures
            {
                print("" + index + ": " + blobs[i].getName());
            }
        }
    }

    // Only need to handle custom blocks
    if (newtile < WORLD_OFFSET || oldtile >= WORLD_OFFSET || oldtile < 0)
    {
        return;
    }

    if (isServer())
    {
        this.AddTileFlag(index, TILEFLAGS[oldtile]);
    }
    else
    {
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

        switch (oldtile)
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
        
        u32 flags = TILEFLAGS[oldtile];
        if (mirror)
        {
            flags |= Tile::TileFlags::MIRROR;
        }
        if (flip)
        {
            flags |= Tile::TileFlags::FLIP;
        }
        if (rotate)
        {
            flags |= Tile::TileFlags::ROTATE;
        }
        if (front)
        {
            flags &= ~Tile::TileFlags::BACKGROUND;
        }
        this.AddTileFlag(index, flags);
        this.SetTile(index, newtile);
    }
}

/*
void CMap::MakeTileVariation_Legacy( int x, int y, TileType& t, TileType& tback, bool& mirror, bool& flip, bool& rotate, bool& backmirror, bool& backflip, bool& backrotate, bool& front )
{
    if (x < 0 || y < 0 || x > tilemapwidth-1 || y > tilemapheight-1) {
        return;
    }
 
    int seed = x * y - 2 * y;
 
    int i, j, k, l, type;
    TileType dummy = 0;
    bool dummybool = false;
    mirror = flip = rotate = backmirror = backflip = backrotate = false;
    front = true;
    tback = 0;
    int offset = MAPOFFSET(x,y);
 
    bool on_left = (x == 0);
    bool on_top = (y == 0);
    bool on_right = (x == tilemapwidth-1);
    bool on_bottom = (y == tilemapheight-1);
 
    switch (t)
    {
    case tile_ground:
        if ( !on_top && isTileGrass(tilemap[offset-tilemapwidth].type) ) { // grass
            t += 7 + (x + y) % 2;
        }
        else
        {
            TileType around = ((on_top || tilemap [MAPOFFSET(x,y-1)].type == tile_empty) ? 1 : 0) |
                              ((on_bottom || tilemap [MAPOFFSET(x,y+1)].type == tile_empty) ? 2 : 0) |
                              ((on_left || tilemap [MAPOFFSET(x-1,y)].type == tile_empty) ? 4 : 0) |
                              ((on_right || tilemap [MAPOFFSET(x+1,y)].type== tile_empty) ? 8 : 0) |
                              ((y <= 1 || tilemap [MAPOFFSET(x,y-2)].type == tile_empty) ? 16 : 0) |
                              ((on_left || on_top || tilemap [MAPOFFSET(x-1,y-1)].type == tile_empty) ? 32 : 0) |
                              ((on_right || on_top || tilemap [MAPOFFSET(x+1,y-1)].type == tile_empty) ? 64 : 0);
 
            if (around & 1)
                ; //nothing, we win
            else if (around & 2) {
                t += 4;
            }
            else if ((around & 4) && (around & 8)) {
                t += (3 + y%2);
            }
            else if (around & 4) {
                t += 3;
            }
            else if (around & 8) {
                t += 2;
            }
            else if ((around & 16) || (around & 32) || (around & 64)) {
                t += 1;
            }
            else {
                t += 5 + ((x+y)%2);
            }
        }
 
        if (isTileUnderGround(offset)) {
            tback = tile_ground_back;
        }
 
        break;
 
    case tile_castle:
        i = on_top ? 0 : tilemap[ MAPOFFSET(x, y-1) ].type;
        j = on_bottom ? 0 : tilemap[ MAPOFFSET(x, y+1) ].type;
        {
            k = y > 3 ? tilemap[ MAPOFFSET(x, y-2) ].type : 0;
            l = y < tilemapheight-3 ? tilemap[ MAPOFFSET(x, y+2) ].type : 0;
            TileType m = on_right ? 0 : tilemap [MAPOFFSET(x+1,y)].type;
            TileType n = on_left ? 0 : tilemap [MAPOFFSET(x-1,y)].type;
 
            if ( (i == tile_castle_back || i == tile_ladder_castle || (i >= tile_castle_back_d1 && i <= tile_castle_back_d0) || isTileDoor(i) ) &&
                      (!isTileSolid(k)) )
            { //floor
                t += 2;
            }
            else if ( (j == tile_castle_back || j == tile_ladder_castle || (j >= tile_castle_back_d1 && j <= tile_castle_back_d0) || isTileDoor(j) ) &&
                      (!isTileSolid(l) || isTileDoor(l) ) )
            { //ceiling
                t += 3;
                mirror = ((x+y)%2 == 0);
            }
            else if ( isTileCastleBack(m) && isTileCastleBack(n) && isTileCastle(i) && isTileCastle(j) )
            {
                t += 4;
                mirror = ((x+y)%2 == 0);
            }
            else if ((isTileCastleBack(m) || isTileCastleBack(n) ) && isTileCastle(i) && isTileCastle(j))
            {
                t += 4;
 
                if (isTileCastleBack(n)) {
                    mirror = true;
                }
            }
            else {
                t += ((x + y) % 2);
            }
        }
        break;
 
    case tile_castle_moss:
        i = on_top ? 0 : tilemap[ MAPOFFSET(x, y-1) ].type;
        j = on_bottom ? 0 : tilemap[ MAPOFFSET(x, y+1) ].type;
        k = y > 1 ? tilemap[ MAPOFFSET(x, y-2) ].type : 0;
        l = y < tilemapheight-2 ? tilemap[ MAPOFFSET(x, y+2) ].type : 0;
 
        if ( (i == tile_castle_back || i == tile_ladder_castle || (i >= tile_castle_back_d1 && i <= tile_castle_back_d0) || isTileDoor(i) ) &&
                (!isTileSolid(k) || isTileDoor(k) ) ) { //floor
            t += 2;
        }
        else if ( (j == tile_castle_back || j == tile_ladder_castle || (j >= tile_castle_back_d1 && j <= tile_castle_back_d0) || isTileDoor(j) ) &&
                  (!isTileSolid(l) || isTileDoor(l) ) ) { //cieling
            t += 1;
        }
 
        break;
 
    case tile_castle_back:
        front = false;
        i = on_top ? 0 : tilemap[ MAPOFFSET(x, y-1) ].type;
        j = on_bottom ? 0 : tilemap[ MAPOFFSET(x, y+1) ].type;
        k = on_left ? 0 : tilemap[ MAPOFFSET(x-1, y) ].type;
        l = on_right ? 0 : tilemap[ MAPOFFSET(x+1, y) ].type;
 
        if (i == tile_empty) {
            t += 5;
        }
        else if (k == tile_empty && l == tile_empty)
        {
            t += 4;
            mirror = ((x+y)%2 == 0);
        }
        else if (k == tile_empty || l == tile_empty)
        {
            t += 4;
 
            if (l == tile_empty) {
                mirror = true;
            }
        }
        else if (isTileSolid(j)) {
            t += 1;
        }
        else if (!isTileSolid(i)) {
            t += 2 + (x+y)%2;
        }
 
        break;
 
    case tile_castle_back_moss:
        front = false;
        i = on_top ? 0 : tilemap[ MAPOFFSET(x, y-1) ].type;
        j = on_bottom ? 0 : tilemap[ MAPOFFSET(x, y+1) ].type;
        k = on_left ? 0 : tilemap[ MAPOFFSET(x-1, y) ].type;
        l = on_right ? 0 : tilemap[ MAPOFFSET(x+1, y) ].type;
 
        if (isTileSolid(j)) {
            t += 1;
        }
        else if (isTileSolid(i)) {
            t += 4;
        }
        else {
            t += fastrandom(x * y, 4); // hey we don't need cryptographic rand
        }
 
        break;
 
    case tile_gold:
        t += fastrandom(x * y, 5);
        break;
 
    case tile_stone:
        t += (x+y)%2;
        break;
 
    case tile_thickstone:
        t += (x+y)%2;
        break;
 
    case tile_bedrock:
        if (on_top || !isTileSolid(tilemap[ MAPOFFSET(x, y-1) ].type)) {
            t += 3 + fastrandom(x * y, 3);
        }
        else {
            t += fastrandom(x * y, 4);
        }
 
        break;
 
    case tile_door_1:
        if ((on_top || tilemap[ MAPOFFSET(x, y-1) ].type == tile_door_1) &&
            (on_bottom || tilemap[ MAPOFFSET(x, y+1) ].type != tile_door_1))
        {
            t += 1;
        }
 
        //// vertical
        //if (!isTileDoor( tilemap[ MAPOFFSET(x, y-1) ] ) || !isTileDoor(tilemap[ MAPOFFSET(x, y+1) ]))
        //{
        //  if (isTileDoor(tilemap[ MAPOFFSET(x-1, y) ])|| isTileDoor(tilemap[ MAPOFFSET(x+1, y) ]))
        //      rotate = true;
        //}
        break;
 
    case tile_door_2:
        if ((on_top || tilemap[ MAPOFFSET(x, y-1) ].type == tile_door_2) &&
            (on_bottom || tilemap[ MAPOFFSET(x, y+1) ].type != tile_door_2))
        {
            t += 1;
        }
 
        break;
 
    case tile_bridge_1_open:
        front = false;
 
        if (on_left || tilemap[ MAPOFFSET(x-1, y) ].type != tile_bridge_1_open) // left
        {
            mirror = true;
        }
 
        break;
 
    case tile_bridge_1:
        if (on_left || tilemap[ MAPOFFSET(x-1, y) ].type != tile_bridge_1) // left
        {
            t += 1;
            mirror = true;
        }
        else if (on_right || tilemap[ MAPOFFSET(x+1, y) ].type != tile_bridge_1) {
            t += 1;
        }
 
        break;
 
    case tile_bridge_2_open:
        front = false;
 
        if (on_left || tilemap[ MAPOFFSET(x-1, y) ].type != tile_bridge_2_open) // left
        {
            mirror = true;
        }
 
        break;
 
    case tile_bridge_2:
        if (on_left || tilemap[ MAPOFFSET(x-1, y) ].type != tile_bridge_2) // left
        {
            t += 1;
            mirror = true;
        }
        else if (on_right || tilemap[ MAPOFFSET(x+1, y) ].type != tile_bridge_2) {
            t += 1;
        }
 
        break;
 
        //back bridge
 
    case tile_bridge_1_open+BRIDGE_BACKADD:
        front = false;
 
        if (on_left || tilemap[ MAPOFFSET(x-1, y) ].type != tile_bridge_1_open+BRIDGE_BACKADD) // left
        {
            mirror = true;
        }
 
        break;
 
    case tile_bridge_1+BRIDGE_BACKADD:
        if (on_left || tilemap[ MAPOFFSET(x-1, y) ].type != tile_bridge_1+BRIDGE_BACKADD) // left
        {
            t += 1;
            mirror = true;
        }
        else if (on_right || tilemap[ MAPOFFSET(x+1, y) ].type != tile_bridge_1+BRIDGE_BACKADD) {
            t += 1;
        }
 
        tback = tile_ground_back;
        break;
 
    case tile_bridge_2_open+BRIDGE_BACKADD:
        front = false;
 
        if (on_left || tilemap[ MAPOFFSET(x-1, y) ].type != tile_bridge_2_open+BRIDGE_BACKADD) // left
        {
            mirror = true;
        }
 
        break;
 
    case tile_bridge_2+BRIDGE_BACKADD:
        if (on_left || tilemap[ MAPOFFSET(x-1, y) ].type != tile_bridge_2+BRIDGE_BACKADD) // left
        {
            t += 1;
            mirror = true;
        }
        else if (on_right || tilemap[ MAPOFFSET(x+1, y) ].type != tile_bridge_2+BRIDGE_BACKADD) {
            t += 1;
        }
 
        tback = tile_ground_back;
        break;
 
    case tile_ladder:
        front = false;
        break;
 
    case tile_ladder_ground:
        front = false;
        t = tile_ladder;
        tback = tile_ground_back;
        break;
 
    case tile_ladder_castle:
        front = false;
        t = tile_ladder;
        tback = tile_castle_back;
        break;
 
    case tile_ladder_wood:
        front = false;
        t = tile_ladder;
        tback = tile_wood_back;
        break;
 
    case tile_door_1_open:
        front = false;
        break;
 
    case tile_door_2_open:
        front = false;
        break;
 
    case tile_rubble:
        if ((on_top || !isTileSolid(tilemap[ MAPOFFSET(x, y-1) ].type)) &&
                !(on_left || isTileSolid(tilemap[ MAPOFFSET(x-1, y) ].type) && on_right || isTileSolid(tilemap[ MAPOFFSET(x+1, y) ].type))
           )//open above, one side free
        {
            if (on_right || isTileSolid(tilemap[ MAPOFFSET(x+1, y) ].type)) {
                t += 2;
            }
            else if (on_left || isTileSolid(tilemap[ MAPOFFSET(x-1, y) ].type)) {
                t += 3;
            }
            else {
                t += 4;
            }
        }
        else {
            t += fastrandom(x * y, 2);
        }
 
        break;
 
    case tile_wood:
    {
        mirror = (bool)((x+y) % 2);
        if ((on_bottom || isTileWoodBack( tilemap[ MAPOFFSET (x,y+1) ].type ) || isTileCastleBack( tilemap[ MAPOFFSET (x,y+1) ].type )) &&
            (on_top || isTileSolid( tilemap [ MAPOFFSET(x,y-1) ].type )) ) {
            t += 1;
        }
        else if ((on_bottom || isTileSolid( tilemap[ MAPOFFSET (x,y+1) ].type )) &&
            (on_top || isTileSolid( tilemap[ MAPOFFSET (x,y-1) ].type ))) {
            t += 2;
        }
    }
    break;
 
    case tile_wood_back:
 
        {
            front = false;
            i = on_left ? 0 : tilemap[ MAPOFFSET(x-1, y) ].type;
            j = on_right ? 0 : tilemap[ MAPOFFSET(x+1, y) ].type;
 
            bool left = isTileWoodBack(i) || isTileSolid(i);
            bool right = isTileWoodBack(j) || isTileSolid(j);
 
            if ( !left && !right )
            {
                t -= 32;
            }
            else if (left && !right)
            {
                t += 1;
            }
            else if (right && !left)
            {
                t += 1;
                mirror = true;
            }
        }
 
        break;
 
    case tile_tree_chopped_up:
        t = 0;
        break;
    }
 
    // castle back
 
    if (isTileCastleBack(t))
    {
        if (isTileUnderGround(offset)) {
            tback = tile_ground_back;
        }
 
        front = false;
    }
 
    //woodback (todo: some sort of scripted option for this)
 
    if (isTileWoodBack(t))
    {
        if (isTileUnderGround(offset)) {
            tback = tile_ground_back;
        }
 
        front = false;
    }
 
    // rubble
 
    if (isTileRubble(t))
    {
        front = true;
 
        if (isTileUnderGround(offset)) {
            tback = tile_ground_back;
        }
 
        if (y > 1)
        {
            if (t > tile_rubble+1 && (isTileSolid(tilemap[MAPOFFSET(x,y-1)].type) || isTileRubble(tilemap[MAPOFFSET(x,y-1)].type)))
            {
                tback = tile_thickstone_d1;
            }
            else
            {
                if (x > 0 && x < tilemapwidth-1)
                {
                    if (isTileCastleBack(tilemap[MAPOFFSET(x-1,y)].type) || isTileCastleBack(tilemap[MAPOFFSET(x+1,y)].type) || isTileCastleBack(tilemap[MAPOFFSET(x,y-1)].type)) {
                        tback = tile_castle_back_d1;
                    }
                }
            }
        }
    }
 
       // grass
 
    if (isTileGrass(t))
    {
        front = true;
    }
 
    if (t == tile_ground_back)
    {
        front = false;
        TileType around = ((on_top || tilemap [MAPOFFSET(x,y-1)].type == tile_empty) ? 1 : 0) |
                          ((on_bottom || tilemap [MAPOFFSET(x,y+1)].type == tile_empty) ? 2 : 0) |
                          ((on_left || tilemap [MAPOFFSET(x-1,y)].type == tile_empty) ? 4 : 0) |
                          ((on_right || tilemap [MAPOFFSET(x+1,y)].type == tile_empty) ? 8 : 0);
 
        if (around != 0)
        {
            switch (around)
            {
                //endpieces
            case 2|4|8:
                flip = true;
 
            case 1|4|8:
                t += 9;
                break;
 
            case 1|2|4:
                mirror = true;
 
            case 1|2|8:
            case 1|2|4|8:
                rotate = true;
                t += 9;
                break;
 
                //straight pieces
            case 4|8:
                rotate = true;
 
            case 1|2:
                t += 8;
                break;
 
                //edge pieces
            case 2:
                flip = true;
 
            case 1:
                t += 7;
                break;
 
            case 4:
                mirror = true;
 
            case 8:
                rotate = true;
                t += 7;
                break;
 
                //corners
            case 1|8:
                mirror = true;
 
            case 1|4:
                t += 6;
                break;
 
            case 2|8:
                mirror = true;
 
            case 2|4:
                flip = true;
                t += 6;
                break;
            }
        }
        else if ((on_bottom || isTileSolid(tilemap[ MAPOFFSET (x,y+1)].type)) &&
            !(on_top || isTileSolid(tilemap[ MAPOFFSET (x,y-1)].type)))
        {
            t += 5;
        }
        else if ((on_top || isTileSolid(tilemap[ MAPOFFSET (x,y-1)].type)) &&
            !(on_bottom || isTileSolid(tilemap[ MAPOFFSET (x,y+1)].type)))
        {
            t += 4;
        }
        else {
            t += x%2 + 2*(y%2);    //meta-tiling
        }
    }
 
    if (isTileWoodBack(t))
    {
        front = false;
    }
 
    if (t >= tile_wood_d1 && t <= tile_wood_d0)
    {
        rotate = true;
    }
 
    if (tback > 0)
    {
        MakeTileVariation_Legacy( x, y, tback, dummy, backmirror, backflip, backrotate, dummybool, dummybool, dummybool, dummybool );
    }
}
*/