
#include "MultiCharacterCommon.as"

void onInit(CPlayer@ this)
{
	this.set_u8("char_swap_cooldown", 0);
}

void onRender(CRules@ this)
{
	// Safety checks
	if (this is null)
	{
		return;
	}

	CPlayer@ player = getLocalPlayer();
	if (player is null)
	{
		return;
	}

	CControls@ controls = getControls();
	if (controls is null)
	{
		return;
	}

	CMap@ map = getMap();
	if (map is null)
	{
		return;
	}

	// Update the cooldown if active
	u8 cooldown = player.get_u8("char_swap_cooldown");
	if (cooldown > 0)
	{
		player.set_u8("char_swap_cooldown", --cooldown);
	}

	// Check if the player is trying to swap to another char
	if (controls.isKeyPressed(KEY_KEY_R) && cooldown == 0)
	{
		CBlob@[] blobsInRadius;
		map.getBlobsInRadius(controls.getMouseWorldPos(), 1.0f, @blobsInRadius);
		for (u16 i = 0; i < blobsInRadius.length(); i++)
		{
			if (blobsInRadius[i] !is null && blobsInRadius[i].hasTag("player"))
			{
				CBitStream params;
				params.write_string(player.getUsername());
				params.write_netid(blobsInRadius[i].getNetworkID());

				this.SendCommand(this.getCommandID("swap_player"), params);
				player.set_u8("char_swap_cooldown", getTicksASecond() / 2);
				break;
			}
		}
	}

	// Get player's char list
	u16[] player_char_networkIDs;
	if (readCharList(player.getUsername(), @player_char_networkIDs))
	{
		// Render players on the right
		u8 frame_width = 80;
		Vec2f upper_left = Vec2f(getScreenWidth() - frame_width, 0);
		Vec2f bottom_right = Vec2f(getScreenWidth(), frame_width);
		for (u8 i = 0; i < player_char_networkIDs.length(); i++)
		{
			CBlob@ char = getBlobByNetworkID(player_char_networkIDs[i]);
			if (char !is null)
			{
				// Draw Frame
				GUI::DrawFramedPane(upper_left, bottom_right);

				// Draw char sprite
				Vec2f middle = (upper_left + bottom_right)/2;

				// Update corners
				upper_left.y += frame_width - 2;
				bottom_right.y += frame_width - 2;
			}
		}
	}
}