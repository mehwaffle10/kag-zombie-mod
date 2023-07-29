
#define CLIENT_ONLY

#include "MultiCharacterCommon.as"
#include "MultiCharacterButtonLogic.as"
#include "MultiCharacterDrawing.as"
#include "RunnerTextures.as"

string CONFIG_FILE_NAME = "MultiCharacterKeyBindings.cfg";
string LOAD_CONFIG_DELAY_STRING = "load_config_delay";
string SWAP_ON_MOUSE_STRING = "swap_on_mouse_key";
string CLAIM_ON_MOUSE_STRING = "claim_on_mouse_key";
string SWAP_ON_NUMBER_MODIFIER_STRING = "swap_on_number_modifier_key";
string TOGGLE_DISPLAY_MODE_STRING = "toggle_display_mode_key";
string DISPLAY_MODE_STRING = "display_mode";
string TOGGLE_OTHER_PLAYERCARDS_STRING = "toggle_other_playercards_key";
string RENDER_OTHER_PLAYERCARDS_STRING = "render_other_playercards";
string CAN_TOGGLE_OTHER_PLAYERCARDS_STRING = "can_toggle_other_playercards";

u16 full_frame_width = 124;
u16 simple_frame_width = 70;

string[] mod_binding_button_names = {
	SWAP_ON_MOUSE_STRING,
	CLAIM_ON_MOUSE_STRING,
	SWAP_ON_NUMBER_MODIFIER_STRING,
	TOGGLE_DISPLAY_MODE_STRING,
	TOGGLE_OTHER_PLAYERCARDS_STRING
};

void onInit(CRules@ this)
{
	this.set_u8(UI_ACTION_COOLDOWN_STRING, 0);
	this.set_bool(RENDER_OTHER_PLAYERCARDS_STRING, false);
	this.set_bool(CAN_TOGGLE_OTHER_PLAYERCARDS_STRING, true);
	this.set_u8(LOAD_CONFIG_DELAY_STRING, 1);
	this.set_u8(DISPLAY_MODE_STRING, 0);

	if (!GUI::isFontLoaded("snes"))
	{
		string snes = CFileMatcher("snes.png").getFirst();
		GUI::LoadFont("snes", snes, 22, true);
	}
}

void LoadConfig(CRules@ this)
{
	// Load key bindings from the configfile
	ConfigFile@ cfg = openMultiCharacterKeyBindingsConfig();

	this.set_s32(SWAP_ON_MOUSE_STRING, read_key_binding(cfg, SWAP_ON_MOUSE_STRING, KEY_KEY_R));
	this.set_s32(CLAIM_ON_MOUSE_STRING, read_key_binding(cfg, CLAIM_ON_MOUSE_STRING, KEY_KEY_G));
	this.set_s32(SWAP_ON_NUMBER_MODIFIER_STRING, read_key_binding(cfg, SWAP_ON_NUMBER_MODIFIER_STRING, KEY_LCONTROL));
	this.set_s32(TOGGLE_DISPLAY_MODE_STRING, read_key_binding(cfg, TOGGLE_DISPLAY_MODE_STRING, KEY_COMMA));
	this.set_s32(TOGGLE_OTHER_PLAYERCARDS_STRING, read_key_binding(cfg, TOGGLE_OTHER_PLAYERCARDS_STRING, KEY_PERIOD));
}

void onRender(CRules@ this)
{
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

	// Load the config shortly after init
	u8 config_delay = this.get_u8(LOAD_CONFIG_DELAY_STRING);
	if (config_delay > 0)
	{
		this.set_u8(LOAD_CONFIG_DELAY_STRING, --config_delay);
	}
	else
	{
		LoadConfig(this);
	}

	// Update cooldowns if active
	u8 cooldown = this.get_u8(UI_ACTION_COOLDOWN_STRING);
	if (cooldown > 0)
	{
		this.set_u8(UI_ACTION_COOLDOWN_STRING, --cooldown);
	}

	// Force the font for the UI
	GUI::SetFont("snes");

	// Draw Bindings Menu
	if (this.get_bool(RENDER_BINDINGS_MENU_STRING))
	{
		DrawMultiCharBindingsMenu();
	}
	else
	{
		// Toggle Other Player Cards
		if (this.get_bool(CAN_TOGGLE_OTHER_PLAYERCARDS_STRING) && controls.isKeyPressed(this.get_s32(TOGGLE_OTHER_PLAYERCARDS_STRING)))
		{
			this.set_bool(RENDER_OTHER_PLAYERCARDS_STRING, !this.get_bool(RENDER_OTHER_PLAYERCARDS_STRING));
			this.set_bool(CAN_TOGGLE_OTHER_PLAYERCARDS_STRING, false);
		}
		else
		{
			if (!controls.isKeyPressed(this.get_s32(TOGGLE_OTHER_PLAYERCARDS_STRING)))
			{
				this.set_bool(CAN_TOGGLE_OTHER_PLAYERCARDS_STRING, true);
			}
		}

		// Render Other Player Cards
		if (this.get_bool(RENDER_OTHER_PLAYERCARDS_STRING))
		{
			RenderOtherPlayerCards();
		}

		// Check if the player is trying to swap to another char
		if (controls.isKeyPressed(this.get_s32(SWAP_ON_MOUSE_STRING)) && cooldown == 0)
		{
			CBlob@[] blobsInRadius;
			map.getBlobsInRadius(controls.getMouseWorldPos(), 1.0f, @blobsInRadius);
			for (u16 i = 0; i < blobsInRadius.length; i++)
			{
				if (blobsInRadius[i] !is null && blobsInRadius[i].hasTag("player"))
				{
					SendSwapPlayerCmd(player, blobsInRadius[i].getNetworkID());
					break;
				}
			}
		}

		// Get player's char list
		u16[] player_char_networkIDs;
		if (readCharList(player.getUsername(), player_char_networkIDs))
		{
			// Check if the player is trying to use hotkeys to swap to another char
			if (cooldown == 0 && controls.isKeyPressed(this.get_s32(SWAP_ON_NUMBER_MODIFIER_STRING)))
			{
				int[] hotkeys = {KEY_KEY_1, KEY_KEY_2, KEY_KEY_3, KEY_KEY_4, KEY_KEY_5, KEY_KEY_6, KEY_KEY_7, KEY_KEY_8, KEY_KEY_9, KEY_KEY_0};
				for (u8 i = 0; i < Maths::Min(player_char_networkIDs.length, hotkeys.length); i++)
				{
					if (controls.isKeyPressed(hotkeys[i]))
					{
						SendSwapPlayerCmd(player, player_char_networkIDs[i]);
						break;
					}
				}
			}

			// Check if the player is trying to claim/unclaim to another char
			if (controls.isKeyPressed(this.get_s32(CLAIM_ON_MOUSE_STRING)) && cooldown == 0)
			{
				CBlob@[] blobsInRadius;
				map.getBlobsInRadius(controls.getMouseWorldPos(), 1.0f, @blobsInRadius);
				for (u16 i = 0; i < blobsInRadius.length; i++)
				{
					if (blobsInRadius[i] !is null && blobsInRadius[i].hasTag("player"))
					{
						SendClaimCharCmd(
							player,
							blobsInRadius[i].getNetworkID(),
							player_char_networkIDs.find(blobsInRadius[i].getNetworkID()) >= 0
						);
						break;
					}
				}
			}
		}
	}

	u8 display_mode = this.get_u8(DISPLAY_MODE_STRING);
	if (controls.isKeyPressed(this.get_s32(TOGGLE_DISPLAY_MODE_STRING)) && cooldown == 0)
	{
		display_mode++;
		if (display_mode > 2)
		{
			display_mode = 0;
		}
		this.set_u8(DISPLAY_MODE_STRING, display_mode);
		this.set_u8(UI_ACTION_COOLDOWN_STRING, getTicksASecond() / 2);
	}

	// Toggle which display to show
	if (display_mode == 0)  // Full Display
	{
		// Draw player's char list in the top right
		Vec2f upper_left = Vec2f(getScreenWidth() - full_frame_width, 0);
		DrawCharacterList(player, upper_left, full_frame_width, false);

		// Draw unclaimed char list in the top left
		upper_left = Vec2f(0, 0);
		DrawCharacterList(null, upper_left, full_frame_width, false);
	}
	else if (display_mode == 1)  // Small Display
	{
		// Draw player's char list in the top right
		Vec2f upper_left = Vec2f(getScreenWidth() - simple_frame_width, 0);
		DrawCharacterList(player, upper_left, simple_frame_width, true);

		// Draw unclaimed char list in the top left
		upper_left = Vec2f(0, 0);
		DrawCharacterList(null, upper_left, simple_frame_width, true);
	}
	else  // No Display
	{

	}
	
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	/*
	// Safety checks
	if (params is null)
	{
		return;
	}
	*/

	// Only client responds to these commands, but no need to check because of #define CLIENT_ONLY
	// DebugPrint("Client Received Command");
	if (cmd == this.getCommandID("move_up_char_list"))
	{
		string player_list_to_move_up;
		if (!params.saferead_string(player_list_to_move_up))
		{
			return;
		}

		// Move up the corresponding player list
		MoveUpPlayerList(player_list_to_move_up == "" ? null : getPlayerByUsername(player_list_to_move_up));
	}
	else if (cmd == this.getCommandID("print_transfer_char"))
	{
		// DebugPrint("Command is print_transfer_char");
		string message;
		if (!params.saferead_string(message))
		{
			return;
		}

		string[] split_message = message.split(" ");

		CPlayer@ player = getPlayerByUsername(split_message[0]);
		bool claimed = split_message[1] == "claimed";

		SColor color = claimed ? SColor(0, 100, 0, 192) : SColor(0, 192, 0, 100);
		if (player !is null && player is getLocalPlayer())
		{
			color.setGreen(100);
		}

		client_AddToChat(message, color);
	}
}

void onRenderScoreboard(CRules@ this)
{
	// Close the mod binding menu and stop rendering other player cards
	CloseBindingsMenu();
}

void RenderOtherPlayerCards()
{
	// Safety checks
	CRules@ rules = getRules();
	if (rules is null)
	{
		return;
	}

	//  Sort players
	CPlayer@[] players;
	CPlayer@[] spectators;
	for (u32 i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		int teamNum = p.getTeamNum();
		if (teamNum == rules.getSpectatorTeamNum())
		{
			spectators.push_back(p);
		}
		else
		{
			// Don't render local player
			if (p !is getLocalPlayer())
			{
				players.push_back(p);
			}
		}
	}

	bool simple = rules.get_u8(DISPLAY_MODE_STRING) != 0;
	u16 frame_width = simple ? simple_frame_width : full_frame_width;
	s32 min_y = 0;

	// Middle of the screen shifted by player count
	Vec2f upper_left = Vec2f(getScreenWidth() / 2, min_y) - Vec2f(frame_width / 2.0f, 0) * players.length;

	// Draw each player's character list
	for (u8 player_index = 0; player_index < players.length; player_index++)
	{
		// Safety check
		CPlayer@ player = players[player_index];
		if (player is null)
		{
			continue;
		}

		// Draw player's char list
		DrawCharacterList(player, upper_left, frame_width, simple);

		// Move over and to the top for the next player
		upper_left.x += frame_width - 2;
		upper_left.y = min_y;
	}
	
	/*
	if (spectators.length > 0)
	{
		//draw spectators
		f32 stepheight = 16;
		Vec2f bottomright(Maths::Min(getScreenWidth() - 100, screenMidX+maxMenuWidth), topleft.y + stepheight * 2);
		f32 specy = topleft.y + stepheight * 0.5;
		GUI::DrawPane(topleft, bottomright, SColor(0xffc0c0c0));

		Vec2f textdim;
		string s = getTranslatedString("Spectators:");
		GUI::GetTextDimensions(s, textdim);

		GUI::DrawText(s, Vec2f(topleft.x + 5, specy), SColor(0xffaaaaaa));

		f32 specx = topleft.x + textdim.x + 15;
		for (u32 i = 0; i < spectators.length; i++)
		{
			CPlayer@ p = spectators[i];
			if (specx < bottomright.x - 100)
			{
				string name = p.getCharacterName();
				if (i != spectators.length - 1)
					name += ",";
				GUI::GetTextDimensions(name, textdim);
				SColor namecolour = getNameColour(p);
				GUI::DrawText(name, Vec2f(specx, specy), namecolour);
				specx += textdim.x + 10;
			}
			else
			{
				GUI::DrawText(getTranslatedString("and more ..."), Vec2f(specx, specy), SColor(0xffaaaaaa));
				break;
			}
		}

		topleft.y += 52;
	}

	float other_playercardsHeight = topleft.y + scrollOffset;
	float screenHeight = getScreenHeight();
	CControls@ controls = getControls();

	if(other_playercardsHeight > screenHeight) {
		Vec2f mousePos = controls.getMouseScreenPos();

		float fullOffset = (other_playercardsHeight + other_playercardsMargin) - screenHeight;

		if(scrollOffset < fullOffset && mousePos.y > screenHeight*0.83f) {
			scrollOffset += scrollSpeed;
		}
		else if(scrollOffset > 0.0f && mousePos.y < screenHeight*0.16f) {
			scrollOffset -= scrollSpeed;
		}

		scrollOffset = Maths::Clamp(scrollOffset, 0.0f, fullOffset);
	}

	drawPlayerCard(hoveredPlayer, hoveredPos);

	drawHoverExplanation(hovered_accolade, hovered_age, hovered_tier, Vec2f(getScreenWidth() * 0.5, topleft.y));

	mouseWasPressed2 = controls.mousePressed2;
	*/
}

void DrawFancyCopiedText(string username, Vec2f mousePos, uint duration)
{
	string text = "Username copied: " + username;
	Vec2f pos = mousePos - Vec2f(0, duration);
	int col = (255 - duration * 3);

	GUI::DrawTextCentered(text, pos, SColor((255 - duration * 4), col, col, col));
}

// Add mod bindings menu
void onMainMenuCreated(CRules@ this, CContextMenu@ menu)
{
	Menu::addContextItem(menu, getTranslatedString("Mod Bindings"), "MultiCharacterUI.as", "void TurnOnMultiCharacterBindingsMenu()");
}

void TurnOnMultiCharacterBindingsMenu()
{
	// Safety check
	CRules@ rules = getRules();
	if (rules is null)
	{
		return;
	}

	// Hide main menu and other gui
	Menu::CloseAllMenus();
	getHUD().ClearMenus(true);

	// Tell the client to render the menu
	rules.set_bool(RENDER_BINDINGS_MENU_STRING, true);

	// Reset the offset
	u16 vertical_margin = 95;
	rules.set_Vec2f(BINDINGS_MENU_OFFSET_STRING, Vec2f(getDriver().getScreenCenterPos().x, vertical_margin));
}

ConfigFile@ openMultiCharacterKeyBindingsConfig()
{
	ConfigFile cfg = ConfigFile();
	if (!cfg.loadFile("../Cache/" + CONFIG_FILE_NAME))
	{
		// Save the config to the cache if it doesn't exist already
		cfg.saveFile(CONFIG_FILE_NAME);
	}

	return cfg;
}

int read_key_binding(ConfigFile@ cfg, string name, int default_value)
{
	return cfg.read_s32(name, default_value);
}

void DrawMultiCharBindingsMenu()
{
	CRules@ rules = getRules();
	if (rules is null)
	{
		return;
	}
	
	// string description = getTranslatedString("Builder Block Hotkey Binder");
	Vec2f center = rules.get_Vec2f(BINDINGS_MENU_OFFSET_STRING);
	u16 width = 324;
	u16 spacing = 6;
	u16 button_horizontal_margin = 10;
	u16 button_height = 20;
	u16 x_button_width = 20;

	// Check if the player is trying to close the menu with escape
	CControls@ controls = getControls();
	if (controls is null)
	{
		return;
	}

	if (controls.isKeyPressed(KEY_ESCAPE))
	{
		rules.set_bool(RENDER_BINDINGS_MENU_STRING, false);

		// hide main menu and other gui
		Menu::CloseAllMenus();
		getHUD().ClearMenus(true);
	}

	u8 mouse_centering = 15;
	Vec2f upper_left = Vec2f(center.x - width / 2, center.y - mouse_centering);
	Vec2f bottom_right = Vec2f(center.x + width / 2, center.y - mouse_centering + 30);

	// Check if we need to move the menu
	bool left_clicking = controls.isKeyPressed(KEY_LBUTTON);
	Vec2f mouse_pos = controls.getMouseScreenPos();
	if (rules.get_bool(DRAGGING_BINDING_MENU_STRING))
	{
		if (!left_clicking)
		{
			rules.set_bool(DRAGGING_BINDING_MENU_STRING, false);
		}
	}
	else
	{
		// Check if we are trying to drag the menu
		if (left_clicking
			&& mouse_pos.x > upper_left.x && mouse_pos.x < bottom_right.x - x_button_width
			&& mouse_pos.y > upper_left.y && mouse_pos.y < bottom_right.y)
		{
			rules.set_bool(DRAGGING_BINDING_MENU_STRING, true);
		}
	}
	
	// Move the menu
	if (rules.get_bool(DRAGGING_BINDING_MENU_STRING) && left_clicking)
	{
		center = mouse_pos;
		rules.set_Vec2f(BINDINGS_MENU_OFFSET_STRING, center);
		upper_left = Vec2f(center.x - width / 2, center.y - mouse_centering);
		bottom_right = Vec2f(center.x + width / 2, center.y - mouse_centering + 30);
	}

	// Draw the bounding box for the top
	GUI::DrawFramedPane(upper_left, bottom_right);

	// Draw the x button in the top right
	if (DrawButton(
		"CloseBindingsMenuButton",
		"x",
		Vec2f(bottom_right.x - 4 - x_button_width, upper_left.y + 4),
		x_button_width,
		x_button_width,
		false,
		false,
		"",
		0,
		0
	))
	{
		CloseBindingsMenu();
	}

	// Draw the title at the top
	center.y = upper_left.y + 14;
	GUI::DrawShadowedTextCentered("Mod Bindings", center, SColor(255, 255, 255, 255));

	// Draw the bounding box for the bottom
	upper_left.y = bottom_right.y - 2;
	center.y = upper_left.y + 2 * spacing;
	bottom_right.y = upper_left.y + mod_binding_button_names.length * (spacing + button_height) + 3 * spacing;
	GUI::DrawFramedPane(upper_left, bottom_right);

	// Draw config buttons
	string[] display_text = {
		"Swap On Mouse Key",
		"Claim/Unclaim On Mouse Key",
		"Swap to Number Modifier",
		"Toggle Display Mode",
		"Toggle Other Player Cards"
	};

	// Check if any button is selected to lock all buttons
	s8 selected_index = -1;
	for (u8 i = 0; i < mod_binding_button_names.length; i++)
	{
		string selected_string = mod_binding_button_names[i] + "_selected";
		if (rules.exists(selected_string) && rules.get_bool(selected_string))
		{
			selected_index = i;
			break;
		}
	}

	// Draw the buttons
	for (u8 i = 0; i < mod_binding_button_names.length; i++)
	{
		// See if this button is pressed
		string selected_string = mod_binding_button_names[i] + "_selected";
		bool selected = rules.exists(selected_string) && rules.get_bool(selected_string);

		// Draw the button
		s32 index = key_enums.find(rules.get_s32(mod_binding_button_names[i]));
		if (DrawButton(
			mod_binding_button_names[i],
			selected ? "***Press a new key***" : display_text[i] + " [" + (index < 0 || index >= key_names.length ? index + "" : key_names[index]) + "]",
			Vec2f(upper_left.x + button_horizontal_margin, center.y),
			width - button_horizontal_margin * 2,
			button_height,
			selected_index >= 0,
			false,
			"",
			0,
			0
		))
		{
			// Select the button
			rules.set_bool(selected_string, true);
		}

		// Move down for the next button
		center.y += spacing + button_height;
	}

	// Wait until the player presses a key if a player has pressed a button
	if (selected_index >= 0)
	{
		// Unfortunately we have to check each key one at a time
		for (u8 i = 0; i < key_enums.length; i++)
		{
			if (controls.isKeyPressed(key_enums[i]))
			{
				// Play a sound
				Sound::Play("buttonclick.ogg");

				// Deselect the button
				rules.set_bool(mod_binding_button_names[selected_index] + "_selected", false);

				// Set the hotkey in the current session
				rules.set_s32(mod_binding_button_names[selected_index], key_enums[i]);

				// Write the new key to the config
				ConfigFile@ cfg = openMultiCharacterKeyBindingsConfig();
				cfg.add_s32(mod_binding_button_names[selected_index], key_enums[i]);
				cfg.saveFile(CONFIG_FILE_NAME);

				return;
			}
		}
	}

	/*
	CGridMenu@ menu = CreateGridMenu(center, null, Vec2f(MENU_WIDTH, MENU_HEIGHT), description);
	if (menu !is null)
	{
		menu.deleteAfterClick = false;

		CBitStream params;

		params.write_u8(CLOSE_MENU);
		params.write_string(player.getUsername());

		menu.AddKeyCommand(KEY_ESCAPE, rules.getCommandID(BUILD_CMD), params);
		menu.SetDefaultCommand(rules.getCommandID(BUILD_CMD), params);

		for (uint i = 0; i < blocks[0].length; i++)
		{
			BuildBlock@ b = blocks[0][i];
			string block_desc = getTranslatedString(b.description);

			CBitStream params;
			params.write_u8(BIND_BLOCK);
			params.write_string(player.getUsername());
			params.write_u8(i);

			CGridButton@ button = menu.AddButton(b.icon, block_desc, rules.getCommandID(BUILD_CMD), Vec2f(1, 1), params);

		}

		if (menu.getButtonsCount() % MENU_WIDTH != 0)
		{
			menu.FillUpRow();
		}

		CGridButton@ separator = menu.AddTextButton(getTranslatedString("Select a keybind below, then select the block you want"), Vec2f(MENU_WIDTH, 1));
		if (separator !is null)
		{
			separator.clickable = false;
			separator.SetEnabled(false);
		}

		//get current block keybinds
		ConfigFile@ cfg = openBlockBindingsConfig();

		array<u8> blockBinds = {
			read_block(cfg, "block_1", 0),
			read_block(cfg, "block_2", 1),
			read_block(cfg, "block_3", 2),
			read_block(cfg, "block_4", 3),
			read_block(cfg, "block_5", 4),
			read_block(cfg, "block_6", 5),
			read_block(cfg, "block_7", 6),
			read_block(cfg, "block_8", 7),
			read_block(cfg, "block_9", 8)
		};

		string propname = SELECTED_PROP + player.getUsername();
		u8 selected = rules.get_u8(propname);

		for (int i = 0; i < 9; i++)
		{
			CBitStream params;
			params.write_u8(SELECT_KEYBIND);
			params.write_string(player.getUsername());
			params.write_u8(i);

			BuildBlock@ b = blocks[0][blockBinds[i]];

			CGridButton@ button = menu.AddButton(b.icon, getTranslatedString("Select key {KEY_NUM}").replace("{KEY_NUM}", (i + 1) + ""), rules.getCommandID(BUILD_CMD), Vec2f(1, 1), params);
			button.selectOneOnClick = true;

			if (selected == i)
			{
				button.SetSelected(1);
			}
		}
	}
	*/
}

void CloseBindingsMenu()
{
	CRules@ rules = getRules();
	if (rules is null)
	{
		return;
	}

	// Hide the bindings menu
	rules.set_bool(RENDER_BINDINGS_MENU_STRING, false);

	// Deselect any pressed buttons
	for (u8 i = 0; i < mod_binding_button_names.length; i++)
	{
		rules.set_bool(mod_binding_button_names[i] + "_selected", false);
	}

	// Hide the other player cards
	rules.set_bool(RENDER_OTHER_PLAYERCARDS_STRING, false);
	rules.set_bool(CAN_TOGGLE_OTHER_PLAYERCARDS_STRING, true);
}

s32[] key_enums = {
	// KEY_LBUTTON,
	// KEY_RBUTTON,
	KEY_CANCEL,
	KEY_MBUTTON,
	KEY_XBUTTON1,
	KEY_XBUTTON2,
	KEY_BACK,
	KEY_TAB,
	KEY_CLEAR,
	KEY_RETURN,
	KEY_SHIFT,
	KEY_CONTROL,
	KEY_MENU,
	KEY_PAUSE,
	KEY_CAPITAL,
	// KEY_ESCAPE,
	KEY_SPACE,
	KEY_PRIOR,
	KEY_NEXT,
	KEY_END,
	KEY_HOME,
	KEY_LEFT,
	KEY_UP,
	KEY_RIGHT,
	KEY_DOWN,
	KEY_SELECT,
	KEY_PRINT,
	KEY_EXECUT,
	KEY_INSERT,
	KEY_DELETE,
	KEY_HELP,
	KEY_KEY_0,
	KEY_KEY_1,
	KEY_KEY_2,
	KEY_KEY_3,
	KEY_KEY_4,
	KEY_KEY_5,
	KEY_KEY_6,
	KEY_KEY_7,
	KEY_KEY_8,
	KEY_KEY_9,
	KEY_KEY_A,
	KEY_KEY_B,
	KEY_KEY_C,
	KEY_KEY_D,
	KEY_KEY_E,
	KEY_KEY_F,
	KEY_KEY_G,
	KEY_KEY_H,
	KEY_KEY_I,
	KEY_KEY_J,
	KEY_KEY_K,
	KEY_KEY_L,
	KEY_KEY_M,
	KEY_KEY_N,
	KEY_KEY_O,
	KEY_KEY_P,
	KEY_KEY_Q,
	KEY_KEY_R,
	KEY_KEY_S,
	KEY_KEY_T,
	KEY_KEY_U,
	KEY_KEY_V,
	KEY_KEY_W,
	KEY_KEY_X,
	KEY_KEY_Y,
	KEY_KEY_Z,
	KEY_LWIN,
	KEY_RWIN,
	KEY_APPS,
	KEY_SLEEP,
	KEY_NUMPAD0,
	KEY_NUMPAD1,
	KEY_NUMPAD2,
	KEY_NUMPAD3,
	KEY_NUMPAD4,
	KEY_NUMPAD5,
	KEY_NUMPAD6,
	KEY_NUMPAD7,
	KEY_NUMPAD8,
	KEY_NUMPAD9,
	KEY_MULTIPLY,
	KEY_ADD,
	KEY_SEPARATOR,
	KEY_SUBTRACT,
	KEY_DECIMAL,
	KEY_DIVIDE,
	KEY_F1,
	KEY_F2,
	KEY_F3,
	KEY_F4,
	KEY_F5,
	KEY_F6,
	KEY_F7,
	KEY_F8,
	KEY_F9,
	KEY_F10,
	KEY_F11,
	KEY_F12,
	KEY_NUMLOCK,
	KEY_SCROLL,
	KEY_LSHIFT,
	KEY_RSHIFT,
	KEY_LCONTROL,
	KEY_RCONTROL,
	KEY_LMENU,
	KEY_RMENU,
	KEY_PLUS,
	KEY_COMMA,
	KEY_MINUS,
	KEY_PERIOD,
	KEY_PLAY,
	MOUSE_SCROLL_UP,
	MOUSE_SCROLL_DOWN,
	JOYSTICK_1_MOVE_LEFT,
	JOYSTICK_1_MOVE_RIGHT,
	JOYSTICK_1_MOVE_UP,
	JOYSTICK_1_MOVE_DOWN,
	JOYSTICK_1_BUTTON,
	JOYSTICK_1_BUTTON_LAST,
	JOYSTICK_2_MOVE_LEFT,
	JOYSTICK_2_MOVE_RIGHT,
	JOYSTICK_2_MOVE_UP,
	JOYSTICK_2_MOVE_DOWN,
	JOYSTICK_2_BUTTON,
	JOYSTICK_2_BUTTON_LAST,
	JOYSTICK_3_MOVE_LEFT,
	JOYSTICK_3_MOVE_RIGHT,
	JOYSTICK_3_MOVE_UP,
	JOYSTICK_3_MOVE_DOWN,
	JOYSTICK_3_BUTTON,
	JOYSTICK_3_BUTTON_LAST,
	JOYSTICK_4_MOVE_LEFT,
	JOYSTICK_4_MOVE_RIGHT,
	JOYSTICK_4_MOVE_UP,
	JOYSTICK_4_MOVE_DOWN,
	JOYSTICK_4_BUTTON,
	JOYSTICK_4_BUTTON_LAST
};

string[] key_names = {
	// "LBUTTON",
	// "RBUTTON",
	"CANCEL",
	"MBUTTON",
	"XBUTTON1",
	"XBUTTON2",
	"BACK",
	"TAB",
	"CLEAR",
	"RETURN",
	"SHIFT",
	"CONTROL",
	"MENU",
	"PAUSE",
	"CAPITAL",
	// "ESCAPE",
	"SPACE",
	"PRIOR",
	"NEXT",
	"END",
	"HOME",
	"LEFT",
	"UP",
	"RIGHT",
	"DOWN",
	"SELECT",
	"PRINT",
	"EXECUT",
	"INSERT",
	"DELETE",
	"HELP",
	"0",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"H",
	"I",
	"J",
	"K",
	"L",
	"M",
	"N",
	"O",
	"P",
	"Q",
	"R",
	"S",
	"T",
	"U",
	"V",
	"W",
	"X",
	"Y",
	"Z",
	"LWIN",
	"RWIN",
	"APPS",
	"SLEEP",
	"NUMPAD0",
	"NUMPAD1",
	"NUMPAD2",
	"NUMPAD3",
	"NUMPAD4",
	"NUMPAD5",
	"NUMPAD6",
	"NUMPAD7",
	"NUMPAD8",
	"NUMPAD9",
	"MULTIPLY",
	"ADD",
	"SEPARATOR",
	"SUBTRACT",
	"DECIMAL",
	"DIVIDE",
	"F1",
	"F2",
	"F3",
	"F4",
	"F5",
	"F6",
	"F7",
	"F8",
	"F9",
	"F10",
	"F11",
	"F12",
	"NUMLOCK",
	"SCROLL",
	"LSHIFT",
	"RSHIFT",
	"LCONTROL",
	"RCONTROL",
	"LMENU",
	"RMENU",
	"PLUS",
	"COMMA",
	"MINUS",
	"PERIOD",
	"PLAY",
	"MOUSE_SCROLL_UP",
	"MOUSE_SCROLL_DOWN",
	"JOYSTICK_1_MOVE_LEFT",
	"JOYSTICK_1_MOVE_RIGHT",
	"JOYSTICK_1_MOVE_UP",
	"JOYSTICK_1_MOVE_DOWN",
	"JOYSTICK_1_BUTTON",
	"JOYSTICK_1_BUTTON_LAST",
	"JOYSTICK_2_MOVE_LEFT",
	"JOYSTICK_2_MOVE_RIGHT",
	"JOYSTICK_2_MOVE_UP",
	"JOYSTICK_2_MOVE_DOWN",
	"JOYSTICK_2_BUTTON",
	"JOYSTICK_2_BUTTON_LAST",
	"JOYSTICK_3_MOVE_LEFT",
	"JOYSTICK_3_MOVE_RIGHT",
	"JOYSTICK_3_MOVE_UP",
	"JOYSTICK_3_MOVE_DOWN",
	"JOYSTICK_3_BUTTON",
	"JOYSTICK_3_BUTTON_LAST",
	"JOYSTICK_4_MOVE_LEFT",
	"JOYSTICK_4_MOVE_RIGHT",
	"JOYSTICK_4_MOVE_UP",
	"JOYSTICK_4_MOVE_DOWN",
	"JOYSTICK_4_BUTTON",
	"JOYSTICK_4_BUTTON_LAST"
};