
#define CLIENT_ONLY

#include "MultiCharacterCommon"

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

void DrawButton(CPlayer@ player, u16 char_networkID, string button_name, Vec2f upper_left,
	u8 button_width, u8 button_height, bool locked, bool claimed, fxn@ execute_on_press,
	string icon_filename, u8 row_offset, u8 frames_per_row)
{
	// Safety checks. Intentionally does not check if player is null
	CRules@ rules = getRules();
	if (rules is null)
	{
		DebugPrint("Rules was null");
		return;
	}

	CControls@ controls = getControls();
	if (controls is null)
	{
		DebugPrint("Controls was null");
		return;
	}

	// Create buttons
	Vec2f bottom_right = Vec2f(upper_left.x + button_width, upper_left.y + button_height);
	Vec2f mouse_pos = controls.getMouseScreenPos();
	// Had to attach this to rules instead of the player, as it didn't work on the player for some reason
	string button_state_string = upper_left.x + "_" + upper_left.y + "_" + char_networkID + "_" + button_name + "_button_state";
	u8 button_state = rules.get_u8(button_state_string);

	// Update state and make the button interactive
	if (locked)  // Button is locked ie at top of list for up button or rendered elsewhere, etc
	{
		button_state = ButtonStates::locked;
	}
	else if (mouse_pos.x > upper_left.x && mouse_pos.x < bottom_right.x
		&& mouse_pos.y > upper_left.y && mouse_pos.y < bottom_right.y)  // Inside the button
	{ 
		if (button_state == ButtonStates::hovered && rules.get_u8("multichar_ui_action_cooldown") == 0 && controls.mousePressed1)  // Clicking on the button
		{ 
			if (button_state != ButtonStates::pressed)  // Only play the sound once
			{
				Sound::Play("buttonclick.ogg");
			}

			button_state = ButtonStates::pressed;
			GUI::DrawButtonPressed(upper_left, bottom_right);
			execute_on_press(player, char_networkID, claimed);
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
	u8 frame_offset = row_offset * frames_per_row;
	if (button_state == ButtonStates::idle)
	{
		// GUI::DrawButton(upper_left, bottom_right);
		GUI::DrawIcon(icon_filename, frame_offset, Vec2f(button_width / 2, button_height / 2), upper_left);
	}
	else if (button_state == ButtonStates::hovered)
	{
		// GUI::DrawButtonHover(upper_left, bottom_right);
		GUI::DrawIcon(icon_filename, frame_offset + 1, Vec2f(button_width / 2, button_height / 2), upper_left);
	}
	else if (button_state == ButtonStates::pressed)
	{
		// GUI::DrawButtonPressed(upper_left, bottom_right);
		GUI::DrawIcon(icon_filename, frame_offset + 2, Vec2f(button_width / 2, button_height / 2), upper_left);
	}
	else if (button_state == ButtonStates::locked)
	{
		// GUI::DrawButtonPressed(upper_left, bottom_right);
		GUI::DrawIcon(icon_filename, frame_offset + 2, Vec2f(button_width / 2, button_height / 2), upper_left);
	}
}

void MoveUpPlayerList(CPlayer@ player, u16 char_networkID, bool claimed)
{
	// Safety checks
	print("MoveUpPlayerList Enter");
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
		print(char_display_index_string + " - 1");
		rules.set_u8(char_display_index_string, char_display_index - 1);
	}
}

void MoveDownPlayerList(CPlayer@ player, u16 char_networkID, bool claimed)
{
	// Safety checks
	print("MoveUpPlayerList Down");
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
		print(char_display_index_string + " + 1");
		rules.set_u8(char_display_index_string, char_display_index + 1);
	}
}

void SendSwapPlayerCmd(CPlayer@ player, u16 char_networkID, bool claimed)
{
	CRules@ rules = getRules();
	if (rules is null || player is null)
	{
		return;
	}

	// Attempt to swap to that character
	CBitStream params;
	params.write_string(player.getUsername());
	params.write_netid(char_networkID);

	rules.SendCommand(rules.getCommandID("swap_player"), params);
	rules.set_u8("multichar_ui_action_cooldown", getTicksASecond() / 2);
}

void SendClaimCharCmd(CPlayer@ player, u16 char_networkID, bool claimed)
{
	CRules@ rules = getRules();
	if (rules is null || player is null)
	{
		return;
	}

	// Send an empty string to send the char to the unlaimed list
	CBitStream params;
	params.write_string(player.getUsername());
	params.write_string(claimed ? "" : player.getUsername());
	params.write_netid(char_networkID);

	rules.SendCommand(rules.getCommandID("transfer_char"), params);
	rules.set_u8("multichar_ui_action_cooldown", getTicksASecond() / 2);
}

void SendMoveUpCharCmd(CPlayer@ player, u16 char_networkID, bool claimed)
{
	CRules@ rules = getRules();
	if (rules is null || player is null)
	{
		return;
	}

	CBitStream params;
	params.write_string(player.getUsername());
	params.write_netid(char_networkID);

	rules.SendCommand(rules.getCommandID("move_up_char"), params);
	rules.set_u8("multichar_ui_action_cooldown", getTicksASecond() / 2);
}

void SendMoveDownCharCmd(CPlayer@ player, u16 char_networkID, bool claimed)
{
	CRules@ rules = getRules();
	if (rules is null || player is null)
	{
		return;
	}

	CBitStream params;
	params.write_string(player.getUsername());
	params.write_netid(char_networkID);

	rules.SendCommand(rules.getCommandID("move_down_char"), params);
	rules.set_u8("multichar_ui_action_cooldown", getTicksASecond() / 2);
}