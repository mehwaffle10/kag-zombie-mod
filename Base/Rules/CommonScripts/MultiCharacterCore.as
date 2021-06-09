
#include "MultiCharacterCommon.as"

void onInit(CRules@ this)
{
	// Safety check
	if (this is null)
	{
		DebugPrint("Rules was null");
		return;
	}

	this.addCommandID("swap_player");
	this.addCommandID("transfer_char");
	this.addCommandID("move_down_char");
	this.addCommandID("move_up_char");
	this.addCommandID("give_char_random_name");
	this.addCommandID("spawn_char");

	// Only server can save + sync lists
	if (!isServer())
	{
		return;
	}

	// Initialize list of the unclaimed characters if it doesn't exist yet
	DebugPrint("Initializing unclaimed char list");
	if (!hasCharList(""))
	{
		// Initialize the list and add it to our rules
		DebugPrint("No existing unclaimed char list, initializing empty list");
		u16[] char_networkIDs;
		SaveCharList("", char_networkIDs);
	}
	else
	{
		DebugPrint("Unclaimed char list already exists");
	}
}

void onInit(CPlayer@ this)
{
	// Only server can save + sync lists
	if (!isServer())
	{
		return;
	}

	DebugPrint("Initalizing player char list");
	if (this is null)
	{
		DebugPrint("Player was null");
		return;
	}

	// Initialize list of the player's characters if it doesn't exist yet
	if (!hasCharList(this.getUsername()))
	{
		// Initialize the list and add it to our rules
		DebugPrint("Player " + this.getUsername() + " does not have a char list, initializing empty list");
		u16[] char_networkIDs;
		SaveCharList(this.getUsername(), char_networkIDs);
	}
	else
	{
		DebugPrint("Player " + this.getUsername() + " already has a char list");
	}
}

// Handle class changes and spawning
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	// Only server can set players
	if (!isServer())
	{
		return;
	}

	DebugPrint("Entering onSetPlayer");

	// Safety checks
	if (this is null)
	{
		DebugPrint("Rules was null");
		return;
	}

	if (blob is null)
	{
		DebugPrint("Blob was null");
		return;
	}

	print("" + blob.getNetworkID());

	if (player is null)
	{
		DebugPrint("Player was null");
		return;
	}

	if (player.exists("previous_char_networkID"))
	{
		DebugPrint("Player has previous char networkID");

		// Check if the previous blob was in the char's list or the unclaimed list
		u16 previous_char_networkID = player.get_u16("previous_char_networkID");
		CBlob@ previous_char = getBlobByNetworkID(previous_char_networkID);

		u16[] player_char_networkIDs;
		readCharList(player.getUsername(), @player_char_networkIDs);
		int player_char_list_index = player_char_networkIDs.find(previous_char_networkID);

		u16[] unclaimed_char_networkIDs;
		readCharList("", @player_char_networkIDs);
		int unclaimed_char_list_index = player_char_networkIDs.find(previous_char_networkID);

		// Check if previous blob doesn't exist anymore or is dead or was just created
		if (previous_char is null || previous_char.hasTag("dead") || previous_char.getHealth() <= 0.0f || blob.getTickSinceCreated() <= 1)
		{
			DebugPrint("Previous char was null or dead or blob was just created");

			// Replace the blob with the new one if possible
			// It should never be in both lists at once, the second one wouldn't update otherwise
			if (player_char_list_index >= 0)  // Found in player char list
			{
				// Copy the character's name if possible
				if (previous_char !is null && previous_char.exists("forename") && previous_char.exists("surname"))
				{
					blob.set_string("forename", previous_char.get_string("forename"));
					blob.set_string("surname", previous_char.get_string("surname"));
				}

				// Replace the old character in the player's char list
				TransferCharToPlayerList(blob, player.getUsername(), player_char_list_index);
			}
			else if (unclaimed_char_list_index >= 0)  // Found in unclaimed char list
			{
				// Copy the character's name if possible
				if (previous_char !is null && previous_char.exists("forename") && previous_char.exists("surname"))
				{
					blob.set_string("forename", previous_char.get_string("forename"));
					blob.set_string("surname", previous_char.get_string("surname"));
				}

				// Replace the old character in the unclaimed char list
				TransferCharToPlayerList(blob, "", unclaimed_char_list_index);
			}
			else  // Wasn't in either list, respawning most likely
			{
				TransferCharToPlayerList(blob, player.getUsername(), -1);
			}
		}
		else
		{
			// Just swapping chars. Don't transfer any chars between lists
			DebugPrint("Previous char was not null or dead and the new blob was not just created");
		}
	}
	else  // Player 
	{
		DebugPrint("Player does not have previous char networkID");

		// Add to the end of the list
		TransferCharToPlayerList(blob, player.getUsername(), -1);
	}

	// Set the new char networkID
	player.set_u16("previous_char_networkID", blob.getNetworkID());
}

void onBlobDie(CRules@ this, CBlob@ blob)
{	
	// Clean up dead blobs
	RemoveCharFromPlayerList(blob);
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	// Only server responds to commands
	if (!isServer())
	{
		return;
	}

	// No need for safety checks, methods already have them
	DebugPrint("Received Command");
	if (cmd == this.getCommandID("swap_player"))
	{
		DebugPrint("Command is swap_player");
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
	else if (cmd == this.getCommandID("transfer_char"))
	{
		DebugPrint("Command is transfer_char");
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

		TransferCharToPlayerList(getBlobByNetworkID(target_blob_networkID), player_to_swap_username, -1);
	}
	else if (cmd == this.getCommandID("move_up_char"))
	{
		DebugPrint("Command is move_up_char");
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
	else if (cmd == this.getCommandID("move_down_char"))
	{
		DebugPrint("Command is move_down_char");
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
		if (index >= char_networkIDs.length() - 1)
		{
			return;
		}

		TransferCharToPlayerList(getBlobByNetworkID(target_blob_networkID), unclaimed ? "" : sending_player, index + 1);
	}
	else if (cmd == this.getCommandID("give_char_random_name"))
	{
		DebugPrint("Command is give_char_random_name");
		u16 target_blob_networkID;
		if (!params.saferead_netid(target_blob_networkID))
		{
			return;
		}
		CBlob@ char = getBlobByNetworkID(target_blob_networkID);
		if (char is null)
		{
			return;
		}

		// Give the char a name if they don't have one already
		if (!char.exists("forename"))
		{
			char.set_string("forename", getRandomForename(char));
			char.set_string("surname", getRandomSurname());
		}

		char.Sync("forename", true);
		char.Sync("surname", true);
	}
	else if (cmd == this.getCommandID("spawn_char"))  // This is just for debugging purposes
	{
		DebugPrint("Command is spawn_char");

		CMap@ map = getMap();
		if (map is null)
		{
			return;
		}
		
		CBlob@ newBlob = server_CreateBlobNoInit(this.get_string("default class"));
		newBlob.server_setTeamNum(0);
		u64 x = map.tilemapwidth * map.tilesize;
		newBlob.setPosition(Vec2f(x / 2, map.getLandYAtX(x) * map.tilesize / 2));
		newBlob.Init();
		TransferCharToPlayerList(newBlob, "", -1);
	}
}
