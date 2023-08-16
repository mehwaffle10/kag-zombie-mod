
#include "MultiCharacterCommon.as"

void onInit(CBlob@ this)
{
    this.Tag(SURVIVOR_TAG);
    Random@ random = Random(this.getNetworkID());
    u8 gender = random.NextRanged(2);

    // Chance to make the char have gold armor or a cape
    CSprite@ sprite = this.getSprite();
    if (sprite !is null)
    {
        print("SPRITE IS NULL");
        bool gold = false;
        bool cape = false;

        // Add special armor types
        if (random.NextRanged(4) == 0)  // 25% chance to be special
        { 
            // 25% chance to have a cape
            if (random.NextRanged(4) == 0)
            {
                cape = true;
            }
            else
            {
                gold = true;
            }
        }

        string name = this.getName();
        SetBody(sprite, name.substr(0, 1).toUpper() + name.substr(1), this.getNetworkID() % 2 == 0, gold, cape);
    }
    this.setSexNum(gender);  // 50/50 Male/Female
    this.setHeadNum(random.NextRanged(100));  // Random head

    this.getCurrentScript().tickFrequency = 0;
}

void onInit(CSprite@ this)
{
    print("ONINIT SPRITE");
}