
#include "Requirements.as"
#include "BuilderCommon.as"

// Waffle: Add user feedback
void onRender(CSprite@ this)
{
    CBlob@ blob = this.getBlob();
    if (blob is null)
    {
        return;
    }
    HitData@ hitdata;
    blob.get("hitdata", @hitdata);
    Driver@ driver = getDriver();
    if (hitdata is null || driver is null || hitdata.ticks == 0)
    {
        return;
    }

    GUI::DrawRectangle(
        driver.getScreenPosFromWorldPos(hitdata.upper_left),
        driver.getScreenPosFromWorldPos(hitdata.lower_right),
        SColor(0x65ed1202)
    );
    hitdata.ticks -= 1;
}