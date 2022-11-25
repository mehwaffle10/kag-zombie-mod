
#include "ZombiesMinimapCommon.as"

#define CLIENT_ONLY

void onSetTile(CMap@ this, u32 index, TileType newtile, TileType oldtile)
{
    if (!Texture::exists(ZOMBIE_MINIMAP_TEXTURE))
    {
        return;
    }
    CRules@ rules = getRules();
    Vec2f pos = Vec2f(index % this.tilemapwidth, index / this.tilemapwidth);
    ImageData@ image_data = Texture::data(ZOMBIE_MINIMAP_TEXTURE);
    image_data.put(pos.x, pos.y, getMapColor(rules, this, pos * this.tilesize, newtile));
    Texture::update(ZOMBIE_MINIMAP_TEXTURE, image_data);
}