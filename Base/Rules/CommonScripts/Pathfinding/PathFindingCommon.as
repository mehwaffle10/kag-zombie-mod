
const string IS_STATIC = "is static";
const u8 max_edge_length = 3;
const u8[] graph_sizes = {2};

// void GenerateGraph(CMap@ map)
// {
//     for (u8 i = 0; i < graph_sizes.length(); i++)
//     {
//         GenerateGraph(map, graph_sizes[i]);
//     }
// }

// void GenerateGraph(CMap@ map, u8 size)
// {
//     UpdateGraph(map, size, Vec2f(0, 0), Vec2f(map.tilemapwidth, map.tilemapheight) - Vec2f(1, 1), Vec2f(-1.0f, -1.0f));  // Fix off by one error since UpdateGraph uses <=
// }

void UpdateGraph(CMap@ map, Vec2f top_left, Vec2f bottom_right)
{
    for (u8 i = 0; i < graph_sizes.length(); i++)
    {
        UpdateGraph(map, graph_sizes[i], top_left, bottom_right, Vec2f(-1, -1));
    }
}

void UpdateGraph(CMap@ map, Vec2f center, bool destroyed)
{
    for (u8 i = 0; i < graph_sizes.length(); i++)
    {
        UpdateGraph(map, graph_sizes[i], center, destroyed);
    }
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
                deleteEdges(rules, size, x, y_values[index]);
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
    Vec2f grid_top_left = top_left - Vec2f(Maths::Min(top_left.x, max_edge_length), Maths::Min(top_left.y, max_edge_length));
    Vec2f grid_bottom_right = bottom_right + Vec2f(Maths::Min(map.tilemapwidth - 1 - bottom_right.x, max_edge_length), Maths::Min(map.tilemapheight - 1 - bottom_right.y, max_edge_length));
    Vec2f grid_size = grid_bottom_right - grid_top_left;
    bool[][] nodes(Maths::Max(grid_size.x, map.tilemapwidth), bool[](Maths::Max(grid_size.y, map.tilemapheight), false));
    bool[][] big_enough(nodes.length(), bool[](nodes[0].length(), false));
    for (s32 x = grid_top_left.x; x <= grid_bottom_right.x; x++)
    {
        u8[] y_values;
        readX(rules, size, x, y_values);
        for (u8 i = 0; i < y_values.length(); i++)
        {
            s32 y = y_values[i];
            if (y >= grid_top_left.y && y <= grid_bottom_right.y)
            {
                nodes[x - grid_top_left.x][y - grid_top_left.y] = true;
            }
        }

        for (s32 y = grid_top_left.y; y <= grid_bottom_right.y; y++)
        {
            big_enough[x - grid_top_left.x][y - grid_top_left.y] = isBigEnough(Vec2f(x, y), size, map, broken_block);
        }
    }

    // Check for edges
    for (s32 x = grid_top_left.x; x <= grid_bottom_right.x; x++)
    {
        for (u8 y = grid_top_left.y; y <= grid_bottom_right.y; y++)
        {
            Vec2f current = Vec2f(x, y);
            Vec2f grid_coords = current - grid_top_left;
            if (nodes[grid_coords.x][grid_coords.y])
            {
                // Check above and below the current node
                u8 max_height = Maths::Min(max_edge_length, grid_coords.y), min_height = Maths::Min(max_edge_length, grid_bottom_right.y - grid_coords.y);
                max_height = ScanVertical(rules, size, nodes, big_enough, max_height, current, grid_coords, x, y, true);
                ScanVertical(rules, size, nodes, big_enough, min_height, current, grid_coords, x, y, false);

                u8 max_left = Maths::Min(max_edge_length, grid_coords.x), max_right = Maths::Min(max_edge_length, grid_bottom_right.x - grid_coords.x);
                ScanHorizontal(rules, size, nodes, big_enough, max_left,  max_height, min_height, current, grid_coords, x, y, true);
                ScanHorizontal(rules, size, nodes, big_enough, max_right, max_height, min_height, current, grid_coords, x, y, false);
            }
        }
    }
}

void ScanHorizontal(CRules@ rules, u8 size, bool[][] nodes, bool[][] big_enough, u8 max, u8 max_height, u8 min_height, Vec2f current, Vec2f grid_coords, s32 x, s32 y, bool left)
{
    for (u8 i = 1; i <= max; i++)
    {
        // Scan up to the max height always
        s8 offset = left ? -i : i;
        Vec2f target = Vec2f(x + offset, y);
        Vec2f target_grid_coords = Vec2f(grid_coords.x + offset, grid_coords.y);
        max_height = ScanVertical(rules, size, nodes, big_enough, max_height, current, target_grid_coords, target.x, target.y, true);

        // Check if there is a pathable node
        if (nodes[target_grid_coords.x][target_grid_coords.y])
        {
            writeEdge(rules, size, x,        y,        target,  i);
            writeEdge(rules, size, target.x, target.y, current, i);
            break;
        }
        // Check if there's something blocking our pathing
        else if (!big_enough[target_grid_coords.x][target_grid_coords.y])
        {
            break;
        }
        else
        {
            // Scan down
            min_height = ScanVertical(rules, size, nodes, big_enough, min_height, current, grid_coords, x, y, false);
        }
    }
}

u8 ScanVertical(CRules@ rules, u8 size, bool[][] nodes, bool[][] big_enough, u8 max, Vec2f current, Vec2f grid_coords, s32 x, s32 y, bool up)
{
    // Check Up
    for (u8 i = 1; i <= max; i++)
    {
        s8 offset = up ? -i : i;
        Vec2f target_grid_coords = Vec2f(grid_coords.x, grid_coords.y + offset);
        // Check if there is a pathable node
        if (nodes[target_grid_coords.x][target_grid_coords.y])
        {
            Vec2f target = Vec2f(x, y + offset);
            writeEdge(rules, size, x,        y,        target,  i);
            writeEdge(rules, size, target.x, target.y, current, i);
            return i;
        }
        // Check if there's something blocking our pathing
        else if (!big_enough[target_grid_coords.x][target_grid_coords.y])
        {
            return i - 1;
        }
    }
    return max;
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
    }
    rules.set_u8(getXLengthString(x, size), y_values.length);
}

void writeEdge(CRules@ rules, u8 size, s32 x, s32 y, Vec2f target, u8 cost)
{
    // Check if we're overwriting an edge
    string length_string = getEdgeLengthString(x, y, size);
    u8 length = rules.get_u8(length_string);
    for(u8 i = 0; i < length; i++)
    {
        if (rules.get_Vec2f(getEdgeTargetString(x, y, size, i)) == target)
        {
            rules.set_s8(getEdgeCostString(x, y, size, i), cost);
            return;
        }    
    }

    // Adding a new edge
    rules.set_Vec2f(getEdgeTargetString(x, y, size, length), target);
    rules.set_s8(getEdgeCostString(x, y, size, length), cost);
    rules.set_u8(length_string, length + 1);
}

void deleteEdges(CRules@ rules, u8 size, s32 x, s32 y)
{
    // Delete all edges connecting to this node
    string length_string = getEdgeLengthString(x, y, size);
    u8 length = rules.get_u8(length_string);
    for(u8 i = 0; i < length; i++)
    {
        Vec2f target = rules.get_Vec2f(getEdgeTargetString(x, y, size, i));
        deleteEdge(rules, size, target.x, target.y, Vec2f(x, y));
    }

    // Reset the array length
    rules.set_u8(length_string, 0);
}

void deleteEdge(CRules@ rules, u8 size, s32 x, s32 y, Vec2f target)
{
    // Check if we're overwriting an edge
    string length_string = getEdgeLengthString(x, y, size);
    u8 length = rules.get_u8(length_string);
    bool deleted = false;
    for(u8 i = 0; i < length; i++)
    {
        if (deleted)
        {
            // Shift up in list
            rules.set_s8(getEdgeCostString(x, y, size, i - 1), rules.get_s8(getEdgeCostString(x, y, size, i)));
        }
        else if (rules.get_Vec2f(getEdgeTargetString(x, y, size, i)) == target)
        {
            // Flag that we need to shift up the rest of the items
            deleted = true;
        }
    }

    // Check if we need to reduce the size of the list
    if (deleted)
    {
        rules.set_u8(getEdgeLengthString(x, y, size), length - 1);
    }
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
