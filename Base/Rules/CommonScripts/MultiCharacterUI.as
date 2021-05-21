
#include "MultiCharacterCommon.as"
#include "RunnerTextures.as"

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
						Vec2f middle = Vec2f((upper_left.x + bottom_right.x)/2, upper_left.y + 14);
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
						// Get character's info
						string gender = char.getSexNum() == 0 ? "Male" : "Female";
						string player_class = sprite.getFilename().split("_")[2];
						player_class = player_class.substr(0, 1).toUpper() + player_class.substr(1, -1);

						// Tuning variables
						f32 scale = 1.5f;
						middle.y += sprite.getFrameHeight() * scale * 0.8f;
						Vec2f body_offset = Vec2f(sprite.getFrameWidth(), sprite.getFrameHeight());
						
						int head_layer = 0;
						Vec2f head_offset = Vec2f(sprite.getFrameWidth() / 2, sprite.getFrameHeight() / 2);
						head_offset -= (getHeadOffset(char, -1, head_layer) - Vec2f(head.getFrameWidth(), head.getFrameHeight())) * 2.0f;
						head_offset -= sprite.getOffset();
						

						f32 scale_x = scale;
						f32 scale_y = scale;
						// IDK what this does but it's needed in any signature that has scale_x and scale_y
						SColor default_color = SColor(255, 255, 255, 255);

						// Handle facing left
						bool facing_left = char.isFacingLeft();
						if (facing_left)
						{
							// Flip the sprite horizontally
							scale_x = -scale_x;

							// Reverse the offsets as well
							body_offset.x = -body_offset.x;
							head_offset.x = -head_offset.x;
							
						}

						// Scale up the offsets
						body_offset *= scale;
						head_offset *= scale;

						// Draw the head and body in the correct order based on the frame
						if (head_layer == 0)  // Only draw the body 
						{
							// Draw character's body
							GUI::DrawIcon(
								player_class + gender + ".png",
								sprite.getFrame(),
								Vec2f(sprite.getFrameWidth() , sprite.getFrameHeight()),
								middle - body_offset,
								scale_x,
								scale_y,
								char.getTeamNum(),
								default_color
							);
						}
						else if (head_layer == -1)  // Draw Head First
						{
							// Draw character's head
							GUI::DrawIcon(
								head.getFilename(),
								head.getFrame(),
								Vec2f(head.getFrameWidth(), head.getFrameHeight()),
								middle - head_offset,
								scale_x,
								scale_y,
								char.getTeamNum(),
								default_color
							);

							// Draw character's body
							GUI::DrawIcon(
								player_class + gender + ".png",
								sprite.getFrame(),
								Vec2f(sprite.getFrameWidth() , sprite.getFrameHeight()),
								middle - body_offset,
								scale_x,
								scale_y,
								char.getTeamNum(),
								default_color
							);
						}
						else if (head_layer == 1)  // Draw body first
						{
							// Draw character's body
							GUI::DrawIcon(
								player_class + gender + ".png",
								sprite.getFrame(),
								Vec2f(sprite.getFrameWidth() , sprite.getFrameHeight()),
								middle - body_offset,
								scale_x,
								scale_y,
								char.getTeamNum(),
								default_color
							);

							// Draw character's head
							GUI::DrawIcon(
								head.getFilename(),
								head.getFrame(),
								Vec2f(head.getFrameWidth(), head.getFrameHeight()),
								middle - head_offset,
								scale_x,
								scale_y,
								char.getTeamNum(),
								default_color
							);
						}

						// Draw health bar
						middle.y = bottom_right.y - 27;
						RenderHPBar(char, middle);

						// Draw Buttons
						u8 button_width = 24;
						u8 frame_offset = 4;
						Vec2f button_upper_left = Vec2f(upper_left.x + frame_offset, bottom_right.y - frame_offset - button_width);
						Vec2f button_bottom_right = Vec2f(upper_left.x + frame_offset + button_width, bottom_right.y - frame_offset);
						Vec2f mouse_pos = controls.getMouseScreenPos();

						// Make the button interactive
						if (mouse_pos.x > button_upper_left.x && mouse_pos.x < button_bottom_right.x
							&& mouse_pos.y > button_upper_left.y && mouse_pos.y < button_bottom_right.y)  // Inside the button
						{ 
							if (controls.mousePressed1) {  // Clicking on the button
								GUI::DrawButtonPressed(button_upper_left, button_bottom_right);

								// Attempt to swap to that character
								CBitStream params;
								params.write_string(player.getUsername());
								params.write_netid(player_char_networkIDs[i]);

								this.SendCommand(this.getCommandID("swap_player"), params);
								player.set_u8("char_swap_cooldown", getTicksASecond() / 2);
							}
							else  // Hovering over the button
							{
								GUI::DrawButtonHover(button_upper_left, button_bottom_right);
							}
						}
						else  // Outside the button
						{
							GUI::DrawButton(button_upper_left, button_bottom_right);
						}

						// Update corners
						upper_left.y += frame_width - 2;
						bottom_right.y += frame_width - 2;
					}
				}
			}
		}

		// Check if the player is trying to use hotkeys to swap to another char
		if (player.get_u8("char_swap_cooldown") == 0 && controls.isKeyPressed(KEY_LCONTROL))
		{
			int[] hotkeys = {KEY_KEY_1, KEY_KEY_2, KEY_KEY_3, KEY_KEY_4, KEY_KEY_5, KEY_KEY_6, KEY_KEY_7, KEY_KEY_8, KEY_KEY_9, KEY_KEY_0};
			for (u8 i = 0; i < Maths::Min(player_char_networkIDs.length(), hotkeys.length()); i++)
			{
				if (controls.isKeyPressed(hotkeys[i]))
				{
					CBitStream params;
					params.write_string(player.getUsername());
					params.write_netid(player_char_networkIDs[i]);

					this.SendCommand(this.getCommandID("swap_player"), params);
					player.set_u8("char_swap_cooldown", getTicksASecond() / 2);
					break;
				}
			}
		}
	}
}

// Render the character's health centered on a point
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
		Vec2f heartframe = Vec2f(iconWidth, iconWidth);

		// Always render the heart's frame
		GUI::DrawIcon(heartFile, 0, heartframe, heartpos, scale);
		if (thisHP <= 0)
		{
			
		}
		else if (thisHP <= 0.125f)
		{
			GUI::DrawIcon(heartFile, 4, heartframe, heartpos, scale);
		}
		else if (thisHP <= 0.25f)
		{
			GUI::DrawIcon(heartFile, 3, heartframe, heartpos, scale);
		}
		else if (thisHP <= 0.375f)
		{
			GUI::DrawIcon(heartFile, 2, heartframe, heartpos, scale);
		}
		else
		{
			GUI::DrawIcon(heartFile, 1, heartframe, heartpos, scale);
		}

		HPs++;
	}
}