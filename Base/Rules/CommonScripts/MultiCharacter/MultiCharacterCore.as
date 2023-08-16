
#include "MultiCharacterCommon.as"
#include "RandomNames.as"

void Reset(CRules@ this)
{
	// Reset char lists
	MultiCharacterCore@ multicharacter_core = MultiCharacterCore();
	this.set(MULTICHARACTER_CORE, @multicharacter_core);
}

void onInit(CRules@ this)
{
	// Server commands, issued by the client
	this.addCommandID(MULTICHARACTER_SWAP_PLAYER_COMMAND);
	this.addCommandID(MULTICHARACTER_TRANSFER_COMMAND);
	this.addCommandID(MULTICHARACTER_MOVE_UP_COMMAND);
	this.addCommandID(MULTICHARACTER_MOVE_DOWN_COMMAND);
	
	// Server sync commands
	this.addCommandID(MULTICHARACTER_SYNC_COMMAND);
    this.addCommandID(MULTICHARACTER_SYNC_CHARACTER);

	// Client only, used in MultiCharacterUI.as
	this.addCommandID(MULTICHARACTER_PRINT_TRANSFER_COMMAND);
	this.addCommandID(MULTICHARACTER_MOVE_LIST_UP_COMMAND);
	this.addCommandID(MULTICHARACTER_KILL_FEED);

	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CPlayer@ this)
{
	// DebugPrint("Initalizing player char list");
	// Initialize list of the player's characters if it doesn't exist yet
	if (!hasCharList(this.getUsername()))
	{
		// Initialize the list and add it to our rules
		// DebugPrint("Player " + this.getUsername() + " does not have a char list, initializing empty list");
		u16[] char_networkIDs;
		SaveCharList(this.getUsername(), char_networkIDs);
	}
	else
	{
		// DebugPrint("Player " + this.getUsername() + " already has a char list");
	}
}

// Handle class changes and spawning
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (blob is null)
	{
		// DebugPrint("Blob was null");
		return;
	}

	if (player is null)
	{
		// DebugPrint("Player was null");
		return;
	}

	MultiCharacterCore@ multicharacter_core;
	this.get(MULTICHARACTER_CORE, @multicharacter_core);
	MultiCharacterPlayerInfo@ player_info;
	multicharacter_core.players.get(player.getUsername(), @player_info);
	if (player_info is null)
	{
		@player_info = MultiCharacterPlayerInfo();
		multicharacter_core.players.set(player.getUsername(), @player_info);
	}

	if (player_info.previous_char != 0)
	{
		// DebugPrint("Player has previous char networkID");

		// Check if the previous blob was in the char's list or the unclaimed list
		CBlob@ previous_char = getBlobByNetworkID(player_info.previous_char);

		u16[] player_char_networkIDs;
		readCharList(player.getUsername(), player_char_networkIDs);
		int player_char_list_index = player_char_networkIDs.find(player_info.previous_char);

		// print("PLAYER CHAR LIST");
		// PrintCharList(player_char_networkIDs);

		u16[] unclaimed_char_networkIDs;
		readCharList("", player_char_networkIDs);
		int unclaimed_char_list_index = player_char_networkIDs.find(player_info.previous_char);

		// print("UNCLAIMED CHAR LIST");
		// PrintCharList(unclaimed_char_networkIDs);

		// Check if previous blob doesn't exist anymore or is dead or was just created
		if (previous_char is null || previous_char.hasTag("dead") || previous_char.getHealth() <= 0.0f || blob.getTickSinceCreated() <= 1)
		{
			// DebugPrint("Previous char was null or dead or blob was just created");

			// Replace the blob with the new one if possible
			// It should never be in both lists at once, the second one wouldn't update otherwise
			if (player_char_list_index >= 0 || unclaimed_char_list_index >= 0)  // Found in player char list or unclaimed char list
			{
				// Copy the character's traits if possible
				if (previous_char !is null)
				{
					// Name
					if (previous_char.exists(FORENAME) || previous_char.exists(SURNAME))
					{
						blob.set_string(FORENAME, previous_char.get_string(FORENAME));
						blob.set_string(SURNAME, previous_char.get_string(SURNAME));
					}

					// Appearance
					u8 sex = previous_char.getSexNum();
					blob.setSexNum(sex);
					blob.setHeadNum(previous_char.getHeadNum());

					CSprite@ new_sprite = blob.getSprite();
					CSprite@ previous_sprite = previous_char.getSprite();
					if (new_sprite !is null && previous_sprite !is null)
					{
						bool gold = previous_sprite.getFilename().find("Gold") >= 0;
						bool cape = previous_sprite.getFilename().find("Cape") >= 0;
						string class_name = blob.getName();
						SetBody(new_sprite, class_name.substr(0, 1).toUpper() + class_name.substr(1), sex == 0, gold, cape);
					}
				}

				if (player_char_list_index >= 0)
				{
					// Replace the old character in the player's char list
					TransferCharToPlayerList(blob, player.getUsername(), player_char_list_index);	
				}
				else
				{
					// Replace the old character in the unclaimed char list
					TransferCharToPlayerList(blob, "", unclaimed_char_list_index);
				}
			}
			else  // Wasn't in either list, respawning most likely
			{
				TransferCharToPlayerList(blob, player.getUsername(), -1);
			}
		}
		else
		{
			// Just swapping chars. Don't transfer any chars between lists
			// DebugPrint("Previous char was not null or dead and the new blob was not just created");
		}
	}
	else  // Player 
	{
		// DebugPrint("Player does not have previous char networkID");

		// Add to the end of the list
		TransferCharToPlayerList(blob, player.getUsername(), -1);
	}

	// Set the new char networkID
	player_info.previous_char = blob.getNetworkID();
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	// Safety checks
	if (player is null)
	{
		// DebugPrint("Player was null");
		return;
	}

	// Move all characters in this players list to the unclaimed list
	u16[] player_char_networkIDs;
	if (readCharList(player.getUsername(), player_char_networkIDs))
	{
		for(u8 i = 0; i < player_char_networkIDs.length; i++)
		{
			TransferCharToPlayerList(getBlobByNetworkID(player_char_networkIDs[i]), "", -1);
		}
	}
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	// Safety Checks
	if (blob is null)
	{
		return;
	}

	if (blob.hasTag("player") && blob.exists(OWNING_PLAYER) && !blob.hasTag("switch class"))
	{
		// Tell clients to add the char to the kill feed
		CBitStream params;
		params.write_string(blob.get_string(OWNING_PLAYER));
		params.write_netid(blob.getNetworkID());

		this.SendCommand(this.getCommandID(MULTICHARACTER_KILL_FEED), params);
	}

	// Clean up dead blobs
	RemoveCharFromPlayerList(blob);
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	// Safety check
	if (params is null)
	{
		return;
	}

	// No need for safety checks, methods already have them
	// DebugPrint("Received Command");
	if (cmd == this.getCommandID(MULTICHARACTER_SWAP_PLAYER_COMMAND))
	{
		// DebugPrint("Command is swap_player");
		string player_to_swap_username;
		if (!params.saferead_string(player_to_swap_username))
		{
			return;
		}
		u16 target_blob_networkID;
		if (!params.saferead_netid(target_blob_networkID))
		{
			return;
		}

		SwapPlayerControl(player_to_swap_username, target_blob_networkID);
	}
	else if (cmd == this.getCommandID(MULTICHARACTER_TRANSFER_COMMAND))
	{
		// DebugPrint("Command is transfer_char");
		string sending_player;
		if (!params.saferead_string(sending_player))
		{
			return;
		}
		string player_to_swap_username;
		if (!params.saferead_string(player_to_swap_username))
		{
			return;
		}
		u16 target_blob_networkID;
		if (!params.saferead_netid(target_blob_networkID))
		{
			return;
		}

		// Check if the player has claimed the target or if the target is unclaimed first
		if (!hasClaimedChar(sending_player, target_blob_networkID) && !hasClaimedChar("", target_blob_networkID))
		{
			return;
		}

		// Print who's doing what in the chat
		CBlob@ blob = getBlobByNetworkID(target_blob_networkID);
		if (blob !is null)
		{
			// Get the name of the player doing the action and the action
			string message = player_to_swap_username == "" ?
				sending_player + " unclaimed" :
				player_to_swap_username + " claimed";

			// Add the class
			message += " the " + blob.getName();
			
			// Add the first name
			if (blob.exists(FORENAME))
			{
				message += " " + blob.get_string(FORENAME);
			}

			// Add the last name
			if (blob.exists(SURNAME))
			{
				message += " " + blob.get_string(SURNAME);
			}

			// Tell clients to print the char transfer
			CBitStream params;
			params.write_string(message);

			this.SendCommand(this.getCommandID(MULTICHARACTER_PRINT_TRANSFER_COMMAND), params);
		}

		TransferCharToPlayerList(getBlobByNetworkID(target_blob_networkID), player_to_swap_username, -1);
	}
	else if (cmd == this.getCommandID(MULTICHARACTER_MOVE_UP_COMMAND))
	{
		// DebugPrint("Command is move_up_char");
		string sending_player;
		if (!params.saferead_string(sending_player))
		{
			return;
		}
		u16 target_blob_networkID;
		if (!params.saferead_netid(target_blob_networkID))
		{
			return;
		}

		// Get the char's current char list
		u16[] char_networkIDs;
		bool unclaimed = hasClaimedChar("", target_blob_networkID);
		if (hasClaimedChar(sending_player, target_blob_networkID))  // Sending player owns the char
		{
			readCharList(sending_player, char_networkIDs);
		}
		else if (unclaimed)  // Char is unclaimed
		{
			readCharList("", char_networkIDs);
		}
		else  // Someone else has claimed the char
		{
			return;
		}

		// Get the char's index in its list
		int index = char_networkIDs.find(target_blob_networkID);

		// Do nothing if at the top of the list already
		if (index <= 0)
		{
			return;
		}

		TransferCharToPlayerList(getBlobByNetworkID(target_blob_networkID), unclaimed ? "" : sending_player, index - 1);
	}
	else if (cmd == this.getCommandID(MULTICHARACTER_MOVE_DOWN_COMMAND))
	{
		// DebugPrint("Command is move_down_char");
		string sending_player;
		if (!params.saferead_string(sending_player))
		{
			return;
		}
		u16 target_blob_networkID;
		if (!params.saferead_netid(target_blob_networkID))
		{
			return;
		}

		// Get the char's current char list
		u16[] char_networkIDs;
		bool unclaimed = hasClaimedChar("", target_blob_networkID);
		if (hasClaimedChar(sending_player, target_blob_networkID))  // Sending player owns the char
		{
			readCharList(sending_player, char_networkIDs);
		}
		else if (unclaimed)  // Char is unclaimed
		{
			readCharList("", char_networkIDs);
		}
		else  // Someone else has claimed the char
		{
			return;
		}

		// Get the char's index in its list
		int index = char_networkIDs.find(target_blob_networkID);

		// Do nothing if at the bottom of the list already
		if (index >= char_networkIDs.length - 1)
		{
			return;
		}

		TransferCharToPlayerList(getBlobByNetworkID(target_blob_networkID), unclaimed ? "" : sending_player, index + 1);
	}
	else if (cmd == this.getCommandID(MULTICHARACTER_SYNC_COMMAND))
    {
		MultiCharacterCore@ multicharacter_core;
		this.get(MULTICHARACTER_CORE, @multicharacter_core);

		u8 unclaimed_list_length;
		if (!params.saferead_u8(unclaimed_list_length))
		{
			return;
		
		}
		u16 net_id;
		u16[] unclaimed_net_ids;
		for (u8 i = 0; i < unclaimed_list_length; i++)
		{
			if(!params.saferead_netid(net_id))
			{
				return;
			}
			unclaimed_net_ids.push_back(net_id);
		}
		multicharacter_core.unclaimed_char_list = unclaimed_net_ids;

        u8 player_count;
		if (!params.saferead_u8(player_count))
		{
			return;
		}

		for (u8 player_index = 0; player_index < player_count; player_index++)
		{
			string player_name;
			if (!params.saferead_string(player_name))
			{
				return;
			}
			
			u8 length;
			if (!params.saferead_u8(length))
			{
				return;
			}

			u16[] net_ids;
			for (u8 i = 0; i < length; i++)
			{
				if(!params.saferead_netid(net_id))
				{
					return;
				}
				net_ids.push_back(net_id);
			}

			MultiCharacterPlayerInfo@ player_info;
			multicharacter_core.players.get(player_name, @player_info);
			if (player_info is null)
			{
				@player_info = MultiCharacterPlayerInfo();
				multicharacter_core.players.set(player_name, @player_info);
			}
			player_info.char_list = net_ids;
		}
    }
    else if (cmd == this.getCommandID(MULTICHARACTER_SYNC_CHARACTER))
    {
        u16 network_id;
        if (!params.saferead_netid(network_id))
        {
            return;
        }
        bool gold;
        if (!params.saferead_bool(gold))
        {
            return;
        }
        bool cape;
        if (!params.saferead_bool(cape))
        {
            return;
        }
        CBlob@ survivor = getBlobByNetworkID(network_id);
        if (survivor is null || survivor.getSprite() is null)
        {
            return;
        }
        string name = survivor.getName();
        SetBody(survivor.getSprite(), name.substr(0, 1).toUpper() + name.substr(1), survivor.getSexNum() == 0, gold, cape);
    }
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	if (blob.hasTag(SURVIVOR_TAG))
	{
		getRandomName(blob);
		if (!blob.exists(OWNING_PLAYER) || blob.get_string(OWNING_PLAYER) == "")
		{
			TransferCharToPlayerList(blob, "", -1);
		}
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
    if (!isServer())
    {
        return;
    }

	MultiCharacterCore@ multicharacter_core;
	this.get(MULTICHARACTER_CORE, @multicharacter_core);
	if (multicharacter_core is null)
    {
        return;
    }

	// Sync unclaimed list
	CBitStream params;
	params.write_u8(multicharacter_core.unclaimed_char_list.length);
	for (u8 i = 0; i < multicharacter_core.unclaimed_char_list.length; i++)
	{
		params.write_netid(multicharacter_core.unclaimed_char_list[i]);
	}

	// Sync player lists
	u8 player_count = getPlayerCount();
	params.write_u8(player_count);
	for (u8 player_index = 0; player_index < player_count; player_index++)
	{
		CPlayer@ player = getPlayer(player_index);
		if (player is null)
		{
			return;
		}
		string player_name = player.getUsername();
		params.write_string(player_name);
		
		MultiCharacterPlayerInfo@ player_info;
		multicharacter_core.players.get(player_name, @player_info);
		if (player_info is null)
		{
			@player_info = MultiCharacterPlayerInfo();
			multicharacter_core.players.set(player_name, @player_info);
		}

		params.write_u8(player_info.char_list.length);
		for (u8 i = 0; i < player_info.char_list.length; i++)
		{
			params.write_netid(player_info.char_list[i]);
		}
	}
    this.SendCommand(this.getCommandID(MULTICHARACTER_SYNC_COMMAND), params, player);
}