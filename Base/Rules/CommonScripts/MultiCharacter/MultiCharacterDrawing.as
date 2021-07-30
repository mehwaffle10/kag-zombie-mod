
// Renders a player list from top to bottom as far as possible from the start position
// Renders the unclaimed list if player list is null
void DrawCharacterList(CPlayer@ player, Vec2f upper_left, u16 frame_width)
{
	// Safety checks
	CRules@ rules = getRules();
	if (rules is null)
	{
		return;
	}

	CControls@ controls = getControls();
	if (controls is null)
	{
		return;
	}

	u16 move_list_button_height = 24;

	// Get player's char list
	u16[] char_networkIDs;
	if (readCharList(player !is null ? player.getUsername() : "", @char_networkIDs))
	{
		// Render the player's name
		u16 name_box_height = 28;
		Vec2f bottom_right = Vec2f(upper_left.x + frame_width, upper_left.y + name_box_height);
		Vec2f name_middle = Vec2f((upper_left.x + bottom_right.x)/2, upper_left.y + 14);
		GUI::DrawFramedPane(upper_left, bottom_right);
		GUI::DrawShadowedTextCentered(player !is null ? player.getUsername() : "Unclaimed", name_middle, SColor(255, 255, 255, 255));
		upper_left.y += name_box_height;

		// Render the move up in player's list button
		u8 char_display_index = rules.get_u8((player !is null ? player.getUsername() : "unclaimed") + "_char_display_index");

		if (DrawButton(
			(player !is null ? player.getUsername() : "unclaimed") + "_move_up_list",
			"x",
			upper_left,
			frame_width,
			move_list_button_height,
			char_display_index == 0,
			player !is null,
			"MultiCharacterButtonsWide.png",
			0,
			3
		))
		{
			MoveUpPlayerList(player);
		}

		upper_left.y += move_list_button_height;

		// Render claimed players starting from the top right corner under the button
		bool ended_early = false;
		for (u8 i = char_display_index; i < char_networkIDs.length(); i++)
		{
			// Check that there's enough room for the move down button and the frame
			// The extra distance from the bottom of the screen is to protect the day timer, HUD, and chat on the bottom
			if (upper_left.y + frame_width + move_list_button_height > getScreenHeight() - 95)
			{
				ended_early = true;
				break;
			}

			// Draw the frame
			DrawCharacterFrame(frame_width, upper_left, 1.5f, char_networkIDs[i], player !is null, false, false, i == 0, i == char_networkIDs.length() - 1);

			// Move the top left corner down
			upper_left.y += frame_width - 2;
		}

		// Render the move down in list button
		if(DrawButton(
			(player !is null ? player.getUsername() : "unclaimed") + "_move_down_list",
			"x",
			upper_left,
			frame_width,
			move_list_button_height,
			!ended_early,
			player !is null,
			"MultiCharacterButtonsWide.png",
			1,
			3
		))
		{
			MoveDownPlayerList(player);
		}
	}
}

void DrawCharacterFrame(u16 frame_width, Vec2f upper_left, f32 character_scale, u16 char_networkID, bool claimed, bool lock_swap, bool lock_claim, bool lock_up, bool lock_down)
{
	CRules@ rules = getRules();
	if (rules is null)
	{
		return;
	}

	CControls@ controls = getControls();
	if (controls is null)
	{
		return;
	}

	CPlayer@ player = getLocalPlayer();
	if (player is null)
	{
		return;
	}

	CBlob@ char = getBlobByNetworkID(char_networkID);
	if (char !is null)
	{
		CSprite@ sprite = char.getSprite();
		if (sprite !is null)
		{
			CSpriteLayer@ head = sprite.getSpriteLayer("head");
			if (head !is null)
			{
				// Calculate the bottom right corner
				Vec2f bottom_right = upper_left + Vec2f(frame_width, frame_width);

				// Draw Frame
				GUI::DrawFramedPane(upper_left, bottom_right);

				// Print character's name
				Vec2f middle = Vec2f((upper_left.x + bottom_right.x)/2, upper_left.y + 26);

				// Draw character's sprite
				// Get character's info
				string gender = char.getSexNum() == 0 ? "Male" : "Female";
				string player_class = char.getName();  // sprite.getFilename().split("_")[2];
				player_class = player_class.substr(0, 1).toUpper() + player_class.substr(1, -1);

				// Tuning variables
				middle.y += sprite.getFrameHeight() * character_scale * 0.65f;
				Vec2f body_offset = Vec2f(sprite.getFrameWidth(), sprite.getFrameHeight());
				
				int head_layer = 0;
				Vec2f head_offset = Vec2f(sprite.getFrameWidth() / 2, sprite.getFrameHeight() / 2);
				head_offset -= (getHeadOffset(char, -1, head_layer) - Vec2f(head.getFrameWidth(), head.getFrameHeight())) * 2.0f;
				head_offset -= sprite.getOffset();
				

				f32 scale_x = character_scale;
				f32 scale_y = character_scale;

				// Handle facing left
				if (char.isFacingLeft())
				{
					// Flip the sprite horizontally
					scale_x = -scale_x;

					// Reverse the offsets as well
					body_offset.x = -body_offset.x;
					head_offset.x = -head_offset.x;
				}

				// Scale up the offsets
				body_offset *= character_scale;
				head_offset *= character_scale;

				// Draw the head and body in the correct order based on the frame
				if (head_layer == 0)  // Only draw the body 
				{
					// Draw character's body
					DrawBody(player_class + gender + ".png", sprite, middle, body_offset, head_offset, scale_x, scale_y, char, player_class);
				}
				else if (head_layer == -1)  // Draw Head First
				{
					DrawHead(head, middle, head_offset, scale_x, scale_y, char);
					DrawBody(player_class + gender + ".png", sprite, middle, body_offset, head_offset, scale_x, scale_y, char, player_class);
				}
				else if (head_layer == 1)  // Draw body first
				{
					DrawBody(player_class + gender + ".png", sprite, middle, body_offset, head_offset, scale_x, scale_y, char, player_class);
					DrawHead(head, middle, head_offset, scale_x, scale_y, char);
				}

				// Always draw bow on top
				DrawBow(sprite, middle, body_offset, scale_x, scale_y, char, player_class);

				// Print character's name
				// I moved this down to make it always draw the name over the character,
				// although now it doesn't draw top to bottom
				Vec2f name_middle = Vec2f((upper_left.x + bottom_right.x)/2, upper_left.y + 14);
				if (char.exists("forename"))
				{
					GUI::DrawShadowedTextCentered(char.get_string("forename"), name_middle, SColor(255, 255, 255, 255));
				}
				else
				{
					// Give the character a random name
					string cooldown_string = char.getNetworkID() + "_multichar_ui_name_cooldown";
					u8 name_cooldown = rules.get_u8(cooldown_string);

					if (name_cooldown > 0)
					{
						rules.set_u8(cooldown_string, --name_cooldown);
					}
					else if (name_cooldown == 0)
					{
						CBitStream params;
						params.write_netid(char_networkID);

						rules.SendCommand(rules.getCommandID("give_char_random_name"), params);
						rules.set_u8(cooldown_string, getTicksASecond());
					}
				}
				name_middle.y += 12;
				if (char.exists("surname"))
				{
					GUI::DrawShadowedTextCentered(char.get_string("surname"), name_middle, SColor(255, 255, 255, 255));
				}

				// Draw health bar
				middle.y = bottom_right.y - 27;
				RenderHPBar(char, middle);

				// Draw Buttons
				u16 button_width = 24;
				u8 frame_offset = 4;

				string[] button_names = {"move_up_char", "move_down_char", "swap_player", "claim_char"};
				Vec2f[] button_upper_lefts = {
					Vec2f(bottom_right.x - frame_offset - button_width, bottom_right.y - 2 * button_width - frame_offset),
					Vec2f(bottom_right.x - frame_offset - button_width, bottom_right.y - button_width - frame_offset),
					Vec2f(upper_left.x + frame_offset, bottom_right.y - 2 * button_width - frame_offset),
					Vec2f(upper_left.x + frame_offset, bottom_right.y - button_width - frame_offset),
				};

				// Definitions from MultiCharacterButtons.as
				fxn@[] execute_on_press = {@SendMoveUpCharCmd, @SendMoveDownCharCmd, @SendSwapPlayerCmd, @SendClaimCharCmd};
				bool dead = char.hasTag("dead") || char.getHealth() <= 0.0f;
				CPlayer@ char_player = char.getPlayer();
				bool[] locked = {lock_up, lock_down, dead || char_player !is null || lock_swap, dead || (char_player !is null && char_player !is player) || lock_claim};

				// Create buttons
				for (u8 i = 0; i < button_names.length(); i++)
				{
					if (DrawButton(
						button_names[i],
						"x",
						button_upper_lefts[i],
						button_width,
						button_width,
						locked[i],
						claimed,
						"MultiCharacterButtons.png",
						i == 3 && claimed ? 4 : i,
						3
					))
					{
						execute_on_press[i](player, char_networkID, claimed);
					}
				}
			}
		}
	}
}

// Draw a character's head
void DrawHead(CSpriteLayer@ head, Vec2f middle, Vec2f head_offset, f32 scale_x, f32 scale_y, CBlob@ char)
{
	// Safety checks
	if (head is null || char is null)
	{
		return;
	}

	// IDK what this does but it's needed in any signature that has scale_x and scale_y
	SColor default_color = SColor(255, 255, 255, 255);

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

// Draw a character's body. Draw's an archer's quiver and bow if needed
void DrawBody(string filename, CSprite@ sprite, Vec2f middle, Vec2f body_offset, Vec2f head_offset, f32 scale_x, f32 scale_y, CBlob@ char, string player_class)
{
	// Safety checks
	if (sprite is null || char is null)
	{
		return;
	}

	// IDK what this does but it's needed in any signature that has scale_x and scale_y
	SColor default_color = SColor(255, 255, 255, 255);

	u16 sprite_frame = sprite.getFrame();

	// Draw archer bits if needed
	if (player_class == "Archer")
	{
		// Draw quiver, handles crouching
		Vec2f quiver_offset = sprite_frame == 11 || sprite_frame == 12 || sprite_frame == 13 ? Vec2f(-10.0f, -2.5f) : Vec2f(-8.0f, 6.0f);
		
		// Handle facing left
		if (char.isFacingLeft())
		{
			quiver_offset.x = -quiver_offset.x;
		}

		quiver_offset *= Maths::Abs(scale_x);

		CSpriteLayer@ quiver = sprite.getSpriteLayer("quiver");
		if (quiver !is null)
		{
			// IDK what this does but it's needed in any signature that has scale_x and scale_y
			SColor default_color = SColor(255, 255, 255, 255);

			GUI::DrawIcon(
				"RotatedQuiver.png",
				quiver.getFrame() - 66,
				Vec2f(256, 256),
				middle - head_offset + quiver_offset,
				scale_x / 16,
				scale_y / 16,
				char.getTeamNum(),
				default_color
			);
		}

		// Draw back arm if needed
		if (sprite_frame == 10 || sprite_frame == 27 || sprite_frame == 28 || sprite_frame == 29 || sprite_frame == 30)
		{
			CSpriteLayer@ backarm = sprite.getSpriteLayer("backarm");
			if (backarm !is null)
			{
				// IDK what this does but it's needed in any signature that has scale_x and scale_y
				SColor default_color = SColor(255, 255, 255, 255);

				// Get the frame, is always the same so we use our index in our spritesheet
				u16 backarm_frame = 5;

				Vec2f bow_offset;
				u8 row_offset = getRotationOffsets(char, bow_offset, scale_x);
				u8 bow_frames_per_row = 6;
				backarm_frame += bow_frames_per_row * row_offset;

				GUI::DrawIcon(
					"RotatedBow.png",
					backarm_frame,
					Vec2f(512, 512),
					middle - body_offset + bow_offset,
					scale_x / 16,
					scale_y / 16,
					char.getTeamNum(),
					default_color
				);
			}
		}
	}

	// Draw character's body
	GUI::DrawIcon(
		filename,
		sprite_frame,
		Vec2f(sprite.getFrameWidth(), sprite.getFrameHeight()),
		middle - body_offset,
		scale_x,
		scale_y,
		char.getTeamNum(),
		default_color
	);
}

void DrawBow(CSprite@ sprite, Vec2f middle, Vec2f body_offset, f32 scale_x, f32 scale_y, CBlob@ char, string player_class)
{
	// Safety checks
	if (sprite is null || char is null)
	{
		return;
	}

	// IDK what this does but it's needed in any signature that has scale_x and scale_y
	SColor default_color = SColor(255, 255, 255, 255);

	u16 sprite_frame = sprite.getFrame();

	// Draw archer bits if needed
	if (player_class == "Archer" && (sprite_frame == 10 || sprite_frame == 27 || sprite_frame == 28 || sprite_frame == 29 || sprite_frame == 30))
	{
		CSpriteLayer@ frontarm = sprite.getSpriteLayer("frontarm");
		if (frontarm !is null)
		{
			// Translate the bow frame
			u16 frontarm_frame = frontarm.getFrame();
			if (frontarm_frame == 16)
			{
				frontarm_frame = 0;
			}
			else if (frontarm_frame == 24)
			{
				frontarm_frame = 1;
			}
			else if (frontarm_frame == 32)
			{
				frontarm_frame = 2;
			}
			else if (frontarm_frame == 40)
			{
				frontarm_frame = 3;
			}
			else if (frontarm_frame == 25)
			{
				frontarm_frame = 4;
			}

			Vec2f bow_offset;
			u8 row_offset = getRotationOffsets(char, bow_offset, scale_x);
			u8 bow_frames_per_row = 6;
			frontarm_frame += bow_frames_per_row * row_offset;

			// Draw arrow if needed
			CSpriteLayer@ quiver = sprite.getSpriteLayer("quiver");
			CSpriteLayer@ held_arrow = sprite.getSpriteLayer("held arrow");
			if (held_arrow !is null && quiver !is null && quiver.getFrame() == 66)
			{
				// Translate the arrow frame
				u16 arrow_frame = held_arrow.getFrame();
				if (arrow_frame == 1)  // Normal arrow
				{
					arrow_frame = 0;
				}
				else if (arrow_frame == 9)  // Water arrow
				{
					arrow_frame = 1;
				}
				else if (arrow_frame == 8)  // Fire arrow
				{
					arrow_frame = 2;
				}
				else if (arrow_frame == 14)  // Bomb arrow
				{
					arrow_frame = 3;
				}

				u8 arrow_frames_per_row = 4;
				arrow_frame += arrow_frames_per_row * row_offset; 
				
				// Move arrow back based on frame
				Vec2f arrow_offset = Vec2f(0.0f, -16.0f);
				if (frontarm_frame % bow_frames_per_row == 1)
				{
					arrow_offset.y += 3.0f;
				}
				else if (frontarm_frame % bow_frames_per_row == 2)
				{
					arrow_offset.y += 6.0f;
				}

				// Rotate arrow
				arrow_offset.RotateByDegrees(row_offset * 22.5f);

				// Handle facing left
				if (char.isFacingLeft())
				{
					arrow_offset.x = -arrow_offset.x;
				}


				// Scale arrow
				arrow_offset *= Maths::Abs(scale_x);

				GUI::DrawIcon(
					"RotatedArrow.png",
					arrow_frame,
					Vec2f(256, 256),
					middle - body_offset / 2.0f + bow_offset + arrow_offset,  // body_offset is halved because arrow has half the frame width
					scale_x / 16,
					scale_y / 16,
					char.getTeamNum(),
					default_color
				);
			}
		
			// Draw bow and frontarm
			GUI::DrawIcon(
				"RotatedBow.png",
				frontarm_frame,
				Vec2f(512, 512),
				middle - body_offset + bow_offset,
				scale_x / 16,
				scale_y / 16,
				char.getTeamNum(),
				default_color
			);
		}
	}
}

// Returns the row_offset based on the angle of a char's bow and sets bow_offset to the appropriate offset
u8 getRotationOffsets(CBlob@ char, Vec2f &out bow_offset, f32 scale)
{
	// Add the rotation row offset
	Vec2f v;
	char.getAimDirection(v);
	v = v.RotateByDegrees(90.0f);
	f32 bow_angle = v.AngleDegrees();
	if (bow_angle >= 180.0f)
	{
		bow_angle = 360 - bow_angle;
	}
	u8 row_offset = Maths::Round(bow_angle / 22.5f);

	// Add an offset so the arm is always connected in the right place, indexed by row_offset
	Vec2f[] bow_offsets = {  // Index - Cardinal Direction
		Vec2f(-6.0f, -4.0f),  // 0 - N
		Vec2f(-3.0f, -3.0f),  // 1 - NNE
		Vec2f(0.0f, 0.0f),   // 2 - NE
		Vec2f(2.0f, 2.0f),   // 3 - NEE
		Vec2f(2.0f, 4.0f),   // 4 - E
		Vec2f(1.0f, 8.0f),   // 5 - SEE
		Vec2f(0.0f, 10.0f),  // 6 - SE
		Vec2f(-2.0f, 12.0f),  // 7 - SSE
		Vec2f(-6.0f, 12.0f),  // 8 - S
	};
	bow_offset = bow_offsets[row_offset];

	// Handle facing left
	if (char.isFacingLeft())
	{
		bow_offset.x = -bow_offset.x;
	}

	// Scale up the icon
	bow_offset *= Maths::Abs(scale);

	return row_offset;
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
