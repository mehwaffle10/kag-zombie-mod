

#define CLIENT_ONLY

string RENDER_BINDINGS_MENU_STRING = "render_bindings_menu";
string BINDINGS_MENU_OFFSET_STRING = "bindings_menu_offset";
string UI_ACTION_COOLDOWN_STRING = "multichar_ui_action_cooldown";

funcdef void fxn(CPlayer@ player, u16 char_networkID, bool claimed);

namespace ButtonStates
{
	enum state_type
	{
		idle = 0,
		hovered,
		pressed,
		locked
	};
};

// void DrawButton(CPlayer@ player, u16 char_networkID, string button_name, string button_text, Vec2f upper_left,
// 	u16 button_width, u16 button_height, bool locked, bool claimed, fxn@ execute_on_press,
//	string icon_filename, u8 row_offset, u8 frames_per_row)
bool DrawButton(string button_name, string button_text, Vec2f upper_left,
	u16 button_width, u16 button_height, bool locked, bool claimed,
	string icon_filename, u8 row_offset, u8 frames_per_row)
{
	// Safety checks. Intentionally does not check if player is null
	CRules@ rules = getRules();
	if (rules is null)
	{
		return false;
	}

	CControls@ controls = getControls();
	if (controls is null)
	{
		return false;
	}

	// Create buttons
	Vec2f bottom_right = Vec2f(upper_left.x + button_width, upper_left.y + button_height);
	Vec2f mouse_pos = controls.getMouseScreenPos();
	// Had to attach this to rules instead of the player, as it didn't work on the player for some reason
	string button_state_string = upper_left.x + "_" + upper_left.y + "_" + button_name + "_button_state";
	u8 button_state = rules.get_u8(button_state_string);

	// Update state and make the button interactive
	if (locked)  // Button is locked ie at top of list for up button or rendered elsewhere, etc
	{
		button_state = ButtonStates::locked;
	}
	else if (mouse_pos.x > upper_left.x && mouse_pos.x < bottom_right.x
		&& mouse_pos.y > upper_left.y && mouse_pos.y < bottom_right.y)  // Inside the button
	{ 
		if (button_state == ButtonStates::hovered && rules.get_u8(UI_ACTION_COOLDOWN_STRING) == 0 && controls.mousePressed1)  // Clicking on the button
		{ 
			if (button_state != ButtonStates::pressed)  // Only play the sound once
			{
				Sound::Play("buttonclick.ogg");
			}

			button_state = ButtonStates::pressed;
			// rules.set_u8(UI_ACTION_COOLDOWN_STRING, getTicksASecond() / 2);
			// execute_on_press(player, char_networkID, claimed);
		}
		else  // Hovering over the button
		{
			// Don't let players press the button by holding m1 and then mousing over the button
			// and make the state not change back until m1 is released or the mouse moves off the button ie button stays pressed
			if (!controls.mousePressed1)  
			{
				if (button_state != ButtonStates::hovered)  // Only play the sound once
				{
					Sound::Play("select.ogg");
				}

				button_state = ButtonStates::hovered;
			}
		}
	}
	else  // Outside the button
	{
		button_state = ButtonStates::idle;
	}
	rules.set_u8(button_state_string, button_state);
	
	// Draw the buttom
	if (icon_filename != "")
	{
		// Button has an icon
		u8 frame_offset = row_offset * frames_per_row;
		if (button_state == ButtonStates::idle)
		{
			GUI::DrawIcon(icon_filename, frame_offset, Vec2f(button_width / 2, button_height / 2), upper_left);
		}
		else if (button_state == ButtonStates::hovered)
		{
			GUI::DrawIcon(icon_filename, frame_offset + 1, Vec2f(button_width / 2, button_height / 2), upper_left);
		}
		else if (button_state == ButtonStates::pressed)
		{
			GUI::DrawIcon(icon_filename, frame_offset + 2, Vec2f(button_width / 2, button_height / 2), upper_left);
		}
		else if (button_state == ButtonStates::locked)
		{
			// 
			GUI::DrawIcon(icon_filename, frame_offset + 2, Vec2f(button_width / 2, button_height / 2), upper_left);
		}
	}
	else
	{
		// Use default button with text
		if (button_state == ButtonStates::idle)
		{
			GUI::DrawButton(upper_left, bottom_right);
		}
		else if (button_state == ButtonStates::hovered)
		{
			GUI::DrawButtonHover(upper_left, bottom_right);
		}
		else if (button_state == ButtonStates::pressed)
		{
			GUI::DrawButtonPressed(upper_left, bottom_right);
		}
		else if (button_state == ButtonStates::locked)
		{
			GUI::DrawButtonPressed(upper_left, bottom_right);
		}

		// Draw text
		GUI::DrawShadowedTextCentered(button_text, Vec2f(upper_left.x + button_width / 2, upper_left.y + button_height / 2), SColor(255, 255, 255, 255));
	}

	// Return true if pressed
	return button_state == ButtonStates::pressed;
}

void MoveUpPlayerList(CPlayer@ player)
{
	// Safety checks
	CRules@ rules = getRules();
	if (rules is null)
	{
		return;
	}

	// Get the current index
	string char_display_index_string = player is null ? "unclaimed_char_display_index" : player.getUsername() + "_char_display_index";
	u8 char_display_index = rules.get_u8(char_display_index_string);

	// Avoid underflow
	if (char_display_index > 0)
	{
		rules.set_u8(char_display_index_string, char_display_index - 1);
	}
}

void MoveDownPlayerList(CPlayer@ player)
{
	// Safety checks
	CRules@ rules = getRules();
	if (rules is null)
	{
		return;
	}

	// Get the current index
	string char_display_index_string = player is null ? "unclaimed_char_display_index" : player.getUsername() + "_char_display_index";
	u8 char_display_index = rules.get_u8(char_display_index_string);

	// Avoid overflow
	if (char_display_index < 255)
	{
		rules.set_u8(char_display_index_string, char_display_index + 1);
	}
}

void SendSwapPlayerCmd(CPlayer@ player, u16 char_networkID)
{
	SendSwapPlayerCmd(player, char_networkID, false);
}

// claimed is just to match the function signature at the top so I can pass functions around
void SendSwapPlayerCmd(CPlayer@ player, u16 char_networkID, bool claimed)
{
	CRules@ rules = getRules();
	if (rules is null || player is null || rules.get_u8(UI_ACTION_COOLDOWN_STRING) > 0)
	{
		return;
	}

	// Attempt to swap to that character
	CBitStream params;
	params.write_string(player.getUsername());
	params.write_netid(char_networkID);

	rules.SendCommand(rules.getCommandID("swap_player"), params);
	rules.set_u8(UI_ACTION_COOLDOWN_STRING, getTicksASecond() / 2);
}

void SendClaimCharCmd(CPlayer@ player, u16 char_networkID, bool claimed)
{
	CRules@ rules = getRules();
	if (rules is null || player is null || rules.get_u8(UI_ACTION_COOLDOWN_STRING) > 0)
	{
		return;
	}

	// Send an empty string to send the char to the unlaimed list
	CBitStream params;
	params.write_string(player.getUsername());
	params.write_string(claimed ? "" : player.getUsername());
	params.write_netid(char_networkID);

	rules.SendCommand(rules.getCommandID("transfer_char"), params);
	rules.set_u8(UI_ACTION_COOLDOWN_STRING, getTicksASecond() / 2);
}

void SendMoveUpCharCmd(CPlayer@ player, u16 char_networkID)
{
	SendMoveUpCharCmd(player, char_networkID, false);
}

// claimed is just to match the function signature at the top so I can pass functions around
void SendMoveUpCharCmd(CPlayer@ player, u16 char_networkID, bool claimed)
{
	CRules@ rules = getRules();
	if (rules is null || player is null || rules.get_u8(UI_ACTION_COOLDOWN_STRING) > 0)
	{
		return;
	}

	CBitStream params;
	params.write_string(player.getUsername());
	params.write_netid(char_networkID);

	rules.SendCommand(rules.getCommandID("move_up_char"), params);
	rules.set_u8(UI_ACTION_COOLDOWN_STRING, getTicksASecond() / 2);
}

void SendMoveDownCharCmd(CPlayer@ player, u16 char_networkID)
{
	SendMoveDownCharCmd(player, char_networkID, false);
}

// claimed is just to match the function signature at the top so I can pass functions around
void SendMoveDownCharCmd(CPlayer@ player, u16 char_networkID, bool claimed)
{
	CRules@ rules = getRules();
	if (rules is null || player is null || rules.get_u8(UI_ACTION_COOLDOWN_STRING) > 0)
	{
		return;
	}

	CBitStream params;
	params.write_string(player.getUsername());
	params.write_netid(char_networkID);

	rules.SendCommand(rules.getCommandID("move_down_char"), params);
	rules.set_u8(UI_ACTION_COOLDOWN_STRING, getTicksASecond() / 2);
}
