
#include "Heap.as"
#include "HeapElement.as"

const string PATHFINDING_CORE = "pathfinding_core";
const string IS_STATIC = "is static";
const u8[] graph_sizes = {2};

void GenerateGraph(CMap@ map)
{
    for (u8 i = 0; i < graph_sizes.length; i++)
    {
        GenerateGraph(map, graph_sizes[i]);
    }
}

void GenerateGraph(CMap@ map, u8 size)
{
    UpdateGraph(map, size, Vec2f(0, 0), Vec2f(map.tilemapwidth, map.tilemapheight) - Vec2f(1, 1), Vec2f(-1.0f, -1.0f));  // Fix off by one error since UpdateGraph uses <=
}

class Node
{
    bool valid;
    s8 cost_up;
    s8 cost_down;
    s8 cost_left;
    s8 cost_right;
    bool break_up;
    bool break_down;
    bool break_left;
    bool break_right;

    Node()
    {
        valid = false;
        cost_up = -1;
        cost_down = -1;
        cost_left = -1;
        cost_right = -1;
        break_up = false;
        break_down = false;
        break_left = false;
        break_right = false;
    }
}
  
class PathfindingCore
{
	Node[] nodes;
}

void UpdateGraph(CMap@ map, Vec2f top_left, Vec2f bottom_right)
{
    for (u8 i = 0; i < graph_sizes.length; i++)
    {
        UpdateGraph(map, graph_sizes[i], top_left, bottom_right, Vec2f(-1, -1));
    }
}

void UpdateGraph(CMap@ map, Vec2f center, bool destroyed)
{
    for (u8 i = 0; i < graph_sizes.length; i++)
    {
        UpdateGraph(map, graph_sizes[i], center, destroyed);
    }
}

void UpdateGraph(CMap@ map, u8 size, Vec2f center, bool destroyed)
{
    // Center and Radius in tilespace
    Vec2f offset = Vec2f(size, size);
    UpdateGraph(map, size, center - offset, center + offset, destroyed ? center : Vec2f(-1.0f, -1.0f));
}

void UpdateGraph(CMap@ map, u8 size, Vec2f top_left, Vec2f bottom_right, Vec2f broken_block)
{ 
    CRules@ rules = getRules();
    PathfindingCore@ pathfinding_core;
    rules.get(PATHFINDING_CORE, @pathfinding_core);

    // Find all valid nodes
    for (s32 x = Maths::Max(top_left.x, 0); x <= Maths::Min(bottom_right.x, map.tilemapwidth - 1); x++)
    {        
        for (s32 y = Maths::Max(top_left.y, 0); y <= Maths::Min(bottom_right.y, map.tilemapheight - 1); y++)
        {
            Vec2f tile_pos = Vec2f(x, y);
            pathfinding_core.nodes[map.getTileOffsetFromTileSpace(tile_pos)].valid = isBigEnough(tile_pos, size, map, broken_block);
        }
    }

    // Check for edges
    for (s32 x = Maths::Max(top_left.x, 0); x <= Maths::Min(bottom_right.x, map.tilemapwidth - 1); x++)
    {        
        for (s32 y = Maths::Max(top_left.y, 0); y <= Maths::Min(bottom_right.y, map.tilemapheight - 1); y++)
        {
            Vec2f tile_pos = Vec2f(x, y);
            Node@ node = @pathfinding_core.nodes[map.getTileOffsetFromTileSpace(tile_pos)];
            if (node.valid)
            {
                // if (getGameTime() > 200)
                // {
                //     print("tile_pos: " + tile_pos);
                // }
                /* TODO: Handle the following cases
                - Water - Does incur jump cost if at least lower half is water
                - Doors - Can potentially break through wood doors
                - Platforms - Can walk through most directions and potentially break through in another
                - Jumping - Needs to convey max jump height
                - Falling - Potentially fall damage
                - Wall climbing - Hard to implement
                */

                // Check each side of the node
                node.cost_up = -1;
                if (y - 1 >= 0)
                {
                    Vec2f up_pos = tile_pos + Vec2f(0, -1);
                    if (pathfinding_core.nodes[map.getTileOffsetFromTileSpace(up_pos)].valid)
                    {
                        node.cost_up = getCost(map, up_pos, size, 180);
                    }
                }

                node.cost_down = -1;
                if (y + 1 < map.tilemapheight)
                {
                    Vec2f down_pos = tile_pos + Vec2f(0, 1);
                    if (pathfinding_core.nodes[map.getTileOffsetFromTileSpace(down_pos)].valid)
                    {
                        node.cost_down = getCost(map, down_pos + Vec2f(0, size - 1), size, 0);
                    }
                }

                node.cost_left = -1;
                if (x - 1 >= 0)
                {
                    Vec2f left_pos = tile_pos + Vec2f(-1, 0);
                    if (pathfinding_core.nodes[map.getTileOffsetFromTileSpace(left_pos)].valid)
                    {
                        node.cost_left = getCost(map, left_pos, size, 90);
                    }
                }

                node.cost_right = -1;
                if (x + 1 < map.tilemapwidth)
                {
                    Vec2f right_pos = tile_pos + Vec2f(1, 0);
                    if (pathfinding_core.nodes[map.getTileOffsetFromTileSpace(right_pos)].valid)
                    {
                        node.cost_right = getCost(map, right_pos + Vec2f(size - 1, 0), size, 270);
                    }
                }
            }
        }
    }
}

s8 getCost(CMap@ map, Vec2f tile_pos, u8 size, u16 angle)
{
    // Check for blobs that influence cost
    CBlob@[] blobs;
    Vec2f center = (tile_pos + Vec2f(1, 1)) * map.tilesize / 2;
    map.getBlobsInBox(center, center + (angle % 180 == 0 ? Vec2f(size - 1, 0) : Vec2f(0, size - 1)) * map.tilesize, blobs);
    // if (getGameTime() > 200)
    // {
    //     print("TILE_POS: " + tile_pos + " ANGLE: " + angle + " CENTER: " + center + " RIGHT: " + (center + (angle % 180 == 0 ? Vec2f(size * map.tilesize, 1) : Vec2f(1, size * map.tilesize))));
    // }
    for (u16 i = 0; i < blobs.length; i++)
    {
        CBlob@ blob = blobs[i];
        if (blob !is null && blob.get_bool(IS_STATIC))
        {
            if (blob.hasTag("door") && blob.getTeamNum() == 0 || blob.isPlatform() && blob.getAngleDegrees() == angle)
            {
                return Maths::Ceil(blob.getInitialHealth()) * 2;
            }
        }
    }
    return 1;
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

void a_star()
{
    PathfindingCore@ pathfinding_core;
    getRules().get(PATHFINDING_CORE, @pathfinding_core);
    CMap@ map = getMap();
    Vec2f target = map.getTileSpacePosition(getControls().getMouseWorldPos());
    CPlayer@ local = getLocalPlayer();
    if (local is null)
    {
        return;
    }
    CBlob@ local_blob = local.getBlob();
    if (local_blob is null)
    {
        return;
    }
    Vec2f start = map.getTileSpacePosition(local_blob.getPosition() - Vec2f(local_blob.getWidth(), local_blob.getHeight()) / 2);
    if (!pathfinding_core.nodes[map.getTileOffsetFromTileSpace(start)].valid ||
        !pathfinding_core.nodes[map.getTileOffsetFromTileSpace(target)].valid)
    {
        return;
    }

    // Create our data structures
    MinHeap@ heap = MinHeap(1024);
    heap.push(HeapElement(manhattan(start, target), 0, start, null));
    bool[] visited(pathfinding_core.nodes.length, false);

    u16 count = 0;

    // Loop until we find our target or the queue is empty
    while (heap.size > 0 && heap.size < heap.capacity - 1) {
        HeapElement@ current = heap.pop();
        DrawNode(map, current.pos, 2, false);
        count++;
        u32 current_index = map.getTileOffsetFromTileSpace(current.pos);
        Node@ current_node = pathfinding_core.nodes[current_index];
        visited[current_index] = true;
        if (current.pos == target)
        {
            // Recreate our path
            DrawNode(map, current.pos, 2, true);
            while (current.parent !is null)
            {
                DrawNode(map, current.parent.pos, 2, true);
                @current = @current.parent;
            }
            print("COUNT YES: " + count);
            return;
        }

        // Add each neighbor to the list if we need to
        if (current_node.cost_up >= 0)
        {
            CheckNeighbor(map, heap, visited, current, target, current.cost + current_node.cost_up, current.pos + Vec2f(0, -1));
        }
        if (current_node.cost_down >= 0)
        {
            CheckNeighbor(map, heap, visited, current, target, current.cost + current_node.cost_down, current.pos + Vec2f(0, 1));
        }
        if (current_node.cost_left >= 0)
        {
            CheckNeighbor(map, heap, visited, current, target, current.cost + current_node.cost_left, current.pos + Vec2f(-1, 0));
        }
        if (current_node.cost_right >= 0)
        {
            CheckNeighbor(map, heap, visited, current, target, current.cost + current_node.cost_right, current.pos + Vec2f(1, 0));
        }
    }
    print("COUNT NO: " + count);
}

void CheckNeighbor(CMap@ map, MinHeap@ heap, bool[] visited, HeapElement@ parent, Vec2f target, s16 cost, Vec2f pos)
{
    if (!visited[map.getTileOffsetFromTileSpace(pos)])
    {
        heap.push(HeapElement(cost + manhattan(pos, target), cost, pos, parent));
    }
}

s16 manhattan(Vec2f current, Vec2f target)
{
    return Maths::Abs(current.x - target.x) + Maths::Abs(current.y - target.y);
}

void DrawNode(CMap@ map, Vec2f tile_top_left, u8 size, bool path)
{
    Vec2f world_top_left = tile_top_left * map.tilesize;
    f32 offset           = size * map.tilesize - 1;
    Vec2f bottom_left    = world_top_left + Vec2f(0,      offset), 
          top_right      = world_top_left + Vec2f(offset, 0), 
          bottom_right   = world_top_left + Vec2f(offset, offset);

    // Draw box
    SColor color = path ? SColor(255, 0, 255, 0) : SColor(255, 255, 255, 255);
    GUI::DrawLine(world_top_left, top_right,    color);
    GUI::DrawLine(world_top_left, bottom_left,  color);
    GUI::DrawLine(bottom_left,    bottom_right, color);
    GUI::DrawLine(top_right,      bottom_right, color);
}
