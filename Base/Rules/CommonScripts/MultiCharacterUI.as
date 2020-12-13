
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
		u8 frame_width = 124;
		Vec2f upper_left = Vec2f(getScreenWidth() - frame_width, 0);
		Vec2f bottom_right = Vec2f(getScreenWidth(), frame_width);
		for (u8 i = 0; i < player_char_networkIDs.length(); i++)
		{
			CBlob@ char = getBlobByNetworkID(player_char_networkIDs[i]);
			if (char !is null)
			{
				CSprite@ sprite = char.getSprite();
				if (sprite !is null)
				{
					CSpriteLayer@ head = sprite.getSpriteLayer("head");
					if (head !is null)
					{
						// Draw Frame
						GUI::DrawFramedPane(upper_left, bottom_right);

						// Print character's name
						Vec2f middle = Vec2f((upper_left.x + bottom_right.x)/2, upper_left.y + 12);
						if (char.exists("forename"))
						{
							GUI::DrawShadowedTextCentered(char.get_string("forename"), middle, SColor(255, 255, 255, 255));
						}
						middle.y += 12;
						if (char.exists("surname"))
						{
							GUI::DrawShadowedTextCentered(char.get_string("surname"), middle, SColor(255, 255, 255, 255));
						}

						// Draw character's sprite
						middle.y = bottom_right.y - frame_width/2;
						GUI::DrawFramedPane(middle, bottom_right);
						string gender = char.getSexNum() == 0 ? "Male" : "Female";
						string player_class = sprite.getFilename().split("_")[2];
						player_class = player_class.substr(0, 1).toUpper() + player_class.substr(1, -1);
						GUI::DrawIcon(
							player_class + gender + ".png",
							sprite.getFrame(),
							Vec2f(sprite.getFrameWidth(), sprite.getFrameHeight()),
							middle - Vec2f(13, 30),
							1.0f,
							char.getTeamNum()
						);
						GUI::DrawIcon(
							head.getFilename(),
							head.getFrame(),
							Vec2f(head.getFrameWidth(), head.getFrameHeight()),
							middle - Vec2f(13, 30),
							1.2f,
							char.getTeamNum()
						);

						/*
						for (u8 j = 0; j < sprite.getSpriteLayerCount(); j++)
						{
							print(sprite.getSpriteLayer(j).name);
						}
						print("");
						*/

						// Draw health bar
						middle.y += 20;
						RenderHPBar(char, middle);

						// Update corners
						upper_left.y += frame_width - 2;
						bottom_right.y += frame_width - 2;
					}
				}
			}
		}
	}
}

void RenderHPBar(CBlob@ blob, Vec2f middle)
{
	if (blob is null)
	{
		return;
	}

	string heartFile = "GUI/HeartNBubble.png";
	int segmentWidth = 18;
	int iconWidth = 12;
	int HPs = 0;
	f32 scale = 1.0f;

	for (f32 step = 0.0f; step < blob.getInitialHealth(); step += 0.5f)
	{
		f32 thisHP = blob.getHealth() - step;

		Vec2f heartoffset = Vec2f(segmentWidth * -blob.getInitialHealth()/2 - 1, 0) * 2;
		Vec2f heartpos = middle + Vec2f(segmentWidth * HPs, 0) + heartoffset;

		// Always render the frame
		GUI::DrawIcon(heartFile, 0, Vec2f(iconWidth, iconWidth), heartpos, scale);
		if (thisHP <= 0)
		{
			
		}
		else if (thisHP <= 0.125f)
		{
			GUI::DrawIcon(heartFile, 4, Vec2f(iconWidth, iconWidth), heartpos, scale);
		}
		else if (thisHP <= 0.25f)
		{
			GUI::DrawIcon(heartFile, 3, Vec2f(iconWidth, iconWidth), heartpos, scale);
		}
		else if (thisHP <= 0.375f)
		{
			GUI::DrawIcon(heartFile, 2, Vec2f(iconWidth, iconWidth), heartpos, scale);
		}
		else
		{
			GUI::DrawIcon(heartFile, 1, Vec2f(iconWidth, iconWidth), heartpos, scale);
		}

		HPs++;
	}
}