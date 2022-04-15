// s32[][]@ nodes;
// @nodes = s32[][](map.tilemapwidth, s32[](0));

void GenerateGraph(CMap@ map, u8 size)
{
    UpdateGraph(map, size, Vec2f(0, 0), Vec2f(map.tilemapwidth, map.tilemapheight) - Vec2f(1, 1));  // Fix off by one error since UpdateGraph uses <=
}

void UpdateGraph(CMap@ map, u8 size, Vec2f top_left, Vec2f bottom_right)
{ 
    // Find all valid nodes
    for (s32 x = Maths::Max(top_left.x, 0); x <= Maths::Min(bottom_right.x, map.tilemapwidth - 1); x++)
    {
        // Clear entries in the range and find starting point for insertion
        u8[] y_values;
        readX(map, x, y_values);
        u8 index = 0;
        while(index < y_values.length && y_values[index] <= bottom_right.y)
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
            if (isBigEnough(pos, size, map) && canStand(pos, size, map))
            {
                y_values.insertAt(index, y);
            }
        }
        writeX(map, x, y_values);
    }
}

void readX(CMap@ map, s32 x, u8[]@ y_values)
{
    for(u8 i = 0; i < map.get_u8(x + " length"); i++)
    {
        y_values.push_back(map.get_u8(x + " index " + i));
    }
}

void writeX(CMap@ map, s32 x, u8[]@ y_values)
{
    for(u8 i = 0; i < y_values.length; i++)
    {
        map.set_u8(x + " index " + i, y_values[i]);
        map.Sync(x + " index " + i, true);
    }
    map.set_u8(x + " length", y_values.length);
    map.Sync(x + " length", true);
}

bool isBigEnough(Vec2f top_left, u8 size, CMap@ map)
{
    for (u8 i = 0; i < size * size; i++)
    {
        if (map.isTileSolid((top_left + Vec2f(i / size, i % size)) * map.tilesize))
        {
            return false;
        }
    }
    return true;
}

bool canStand(Vec2f top_left, u8 size, CMap@ map)
{
    for (u8 i = 0; i < size; i++)
    {
        Vec2f pos = (top_left + Vec2f(i, size)) * map.tilesize;
        if (map.isTileSolid(pos) || isPlatform(pos, map) == 0.0f)
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
        if (blobs[i] !is null && blobs[i].isPlatform())
        {
            return blobs[i].getAngleDegrees();
        }
    }
    return -1.0f;
}

void DrawNode(CMap@ map, Vec2f top_left, u8 size)
{
    top_left *= map.tilesize;
    f32 offset = size * map.tilesize;
    Vec2f bottom_left = top_left + Vec2f(0, offset), 
          top_right = top_left + Vec2f(offset, 0), 
          bottom_right = top_left + Vec2f(offset, offset);

    GUI::DrawLine(top_left, top_right, SColor(255, 255, 255, 255));
    GUI::DrawLine(top_left, bottom_left, SColor(255, 255, 0, 0));
    GUI::DrawLine(bottom_left, bottom_right, SColor(255, 0, 255, 0));
    GUI::DrawLine(top_right, bottom_right, SColor(255, 0, 0, 255));

    // top_left = getDriver().getScreenPosFromWorldPos(Vec2f(map.tilemapwidth / 2, 20) * map.tilesize);
    // GUI::DrawRectangle(top_left, top_left + Vec2f(3, 3) * 2 * map.tilesize * camera.targetDistance);
}
