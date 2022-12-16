
const string IS_STATIC = "is static";

u8 max_edge_length = 3;

void GenerateGraph(CMap@ map, u8 size)
{
    UpdateGraph(map, size, Vec2f(0, 0), Vec2f(map.tilemapwidth, map.tilemapheight) - Vec2f(1, 1), Vec2f(-1.0f, -1.0f));  // Fix off by one error since UpdateGraph uses <=
}

void UpdateGraph(CMap@ map, u8 size, Vec2f center, bool destroyed)
{
    // Center and Radius in tilespace
    Vec2f offset = Vec2f(max_edge_length, max_edge_length);
    UpdateGraph(map, size, center - offset, center + offset, destroyed ? center : Vec2f(-1.0f, -1.0f));
}

void UpdateGraph(CMap@ map, u8 size, Vec2f top_left, Vec2f bottom_right, Vec2f broken_block)
{ 
    CRules@ rules = getRules();
    // TODO: Check if it's faster to insert in the middle of an array or append to the back and then sort
    // Find all valid nodes
    for (s32 x = Maths::Max(top_left.x, 0); x <= Maths::Min(bottom_right.x, map.tilemapwidth - 1); x++)
    {
        // Clear entries in the range and find starting point for insertion if splicing in 
        u8[] y_values;
        readX(rules, size, x, y_values);

        u8 index = 0;
        while(index < y_values.length() && y_values[index] <= bottom_right.y)
        {
            if (y_values[index] >= top_left.y)
            {
                y_values.erase(index);
            }
            else
            {
                index++;
            }
        }

        // Find new nodes
        for (s32 y = Maths::Max(top_left.y, 0); y <= Maths::Min(bottom_right.y, map.tilemapheight - 1); y++)
        {
            // Check if the spot is size wide and tall and has a standable block below it
            Vec2f pos = Vec2f(x, y);
            if (isBigEnough(pos, size, map, broken_block) && canStand(pos, size, map, broken_block))
            {
                y_values.push_back(y);
            }
        }

        // Sort before saving
        y_values.sortAsc();
        writeX(rules, size, x, y_values);
    }

    // Update Edges
    // Create grid for lookup
    u8[] costs = {1, 2};
    for (s32 x = Maths::Max(top_left.x - max_edge_length, 0); x <= Maths::Min(bottom_right.x + max_edge_length, map.tilemapwidth - 1); x++)
    {
        u8[] y_values;
        readX(rules, size, x, y_values);
        for (u8 i = 0; i < y_values.length(); i++)
        {
            Vec2f[] targets = {Vec2f(x, y_values[i])};
            writeEdges(rules, size, x, y_values[i], targets, costs);
        }
    }
}

// Had to attach to rules instead of map since for some reason map seems to be the only object that doesn't sync when a player joins
void readX(CRules@ rules, u8 size, s32 x, u8[]@ y_values)
{
    for(u8 i = 0; i < rules.get_u8(getXLengthString(x, size)); i++)
    {
        y_values.push_back(rules.get_u8(getXString(x, size, i)));
    }
}

void writeX(CRules@ rules, u8 size, s32 x, u8[]@ y_values)
{
    for(u8 i = 0; i < y_values.length; i++)
    {
        rules.set_u8(getXString(x, size, i), y_values[i]);
        // rules.Sync(getXString(x, size, i), true);
    }
    rules.set_u8(getXLengthString(x, size), y_values.length);
    // rules.Sync(getXLengthString(x, size), true);
}

void readEdges(CRules@ rules, u8 size, s32 x, s32 y, Vec2f[]@ targets, u8[]@ costs)
{
    for(u8 i = 0; i < rules.get_u8(getEdgeLengthString(x, y, size)); i++)
    {
        targets.push_back(rules.get_Vec2f(getEdgeTargetString(x, y, size, i)));
        costs.push_back(rules.get_u8(getEdgeCostString(x, y, size, i)));
    }
}

void writeEdges(CRules@ rules, u8 size, s32 x, s32 y, Vec2f[]@ targets, u8[]@ costs)
{
    for(u8 i = 0; i < targets.length; i++)
    {
        rules.set_Vec2f(getEdgeTargetString(x, y, size, i), targets[i]);
        // rules.Sync(getEdgeTargetString(x, y, size, i), true);
        rules.set_u8(getEdgeCostString(x, y, size, i), costs[i]);
        // rules.Sync(getEdgeCostString(x, y, size, i), true);
    }
    rules.set_u8(getEdgeLengthString(x, y, size), targets.length);
    // rules.Sync(getEdgeLengthString(x, y, size), true);
}

bool isBigEnough(Vec2f top_left, u8 size, CMap@ map, Vec2f broken_block)
{
    for (u8 i = 0; i < size * size; i++)
    {
        Vec2f pos = top_left + Vec2f(i / size, i % size);
        if (pos != broken_block && map.isTileSolid(pos * map.tilesize))
        {
            return false;
        }
    }
    return true;
}

bool isTraversible(Vec2f top_left, u8 size, CMap@ map, Vec2f broken_block, u8 direction)
{
    // Check for blocks
    // Broken block was necessary since hooks trigger on the tick before something is destroyed
    for (u8 i = 0; i < size; i++)
    {
        Vec2f pos = (top_left + Vec2f(i, size)) * map.tilesize;
        if (pos != broken_block * map.tilesize && (map.isTileSolid(pos) || isPlatform(pos, map) == 0.0f))
        {
            return true;
        }
    }

    // Check for ladders
    // if (ladder)
    // {
    //     for (u8 i = 0; i < size * size; i++)
    //     {
    //         if (isLadder((top_left + Vec2f(i / size, i % size)) * map.tilesize, map))
    //         {
    //             return true;
    //         }
    //     }
    // }

    return false;
}

bool canStand(Vec2f top_left, u8 size, CMap@ map, Vec2f broken_block)
{
    // Check for blocks
    // Broken block was necessary since hooks trigger on the tick before something is destroyed
    for (u8 i = 0; i < size; i++)
    {
        Vec2f pos = (top_left + Vec2f(i, size)) * map.tilesize;
        if (pos != broken_block * map.tilesize && (map.isTileSolid(pos) || isPlatform(pos, map) == 0.0f) || isDoor(pos, map))
        {
            return true;
        }
    }

    // Check for ladders and doors
    for (u8 i = 0; i < size * size; i++)
    {
        Vec2f pos = (top_left + Vec2f(i / size, i % size)) * map.tilesize;
        if (isLadder(pos, map))
        {
            return true;
        }
    }

    return false;
}

float isPlatform(Vec2f pos, CMap@ map)
{
    CBlob@[] blobs;
    map.getBlobsInRadius(pos + Vec2f(1, 1) * map.tilesize / 2, 0.1f, blobs);
    for (u16 i = 0; i < blobs.length; i++)
    {
        // We don't need to check for bridges since there will never be enemy bridges TBD
        if (blobs[i] !is null && blobs[i].isPlatform() && blobs[i].get_bool(IS_STATIC))
        {
            return blobs[i].getAngleDegrees();
        }
    }
    return -1.0f;
}

bool isLadder(Vec2f pos, CMap@ map)
{
    CBlob@[] blobs;
    map.getBlobsInRadius(pos + Vec2f(1, 1) * map.tilesize / 2, 0.1f, blobs);
    for (u16 i = 0; i < blobs.length; i++)
    {
        if (blobs[i] !is null && blobs[i].isLadder() && blobs[i].get_bool(IS_STATIC))
        {
            return true;
        }
    }
    return false;
}

bool isDoor(Vec2f pos, CMap@ map)
{
    CBlob@[] blobs;
    map.getBlobsInRadius(pos + Vec2f(1, 1) * map.tilesize / 2, 0.1f, blobs);
    for (u16 i = 0; i < blobs.length; i++)
    {
        if (blobs[i] !is null && blobs[i].hasTag("door") && blobs[i].get_bool(IS_STATIC))
        {
            return true;
        }
    }
    return false;
}

void printX(s32 x, u8[] y_values)
{
    for (u8 i = 0; i < y_values.length; i++)
    {
        print("" + x + ", " + y_values[i]);
    }
}

string getXString(s32 x, u8 size, u8 i)
{
    return x + " " + size + " " + i;
}

string getXLengthString(s32 x, u8 size)
{
    return x + " " + size + " l";
}

string getEdgeTargetString(s32 x, s32 y, u8 size, u8 i)
{
    return x + " " + y + " " + size + " " + i;
}

string getEdgeCostString(s32 x, s32 y, u8 size, u8 i)
{
    return x + " " + y + " " + size + " " + i + " c";
}

string getEdgeLengthString(s32 x, s32 y, u8 size)
{
    return "x " + x + " y " + y + " size " + size + " l";
}
