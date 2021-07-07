
#include "RandomNames.as";

// Transfers control of a player to a target blob if the player owns that blob
void SwapPlayerControl(string player_to_swap_username, u16 target_blob_networkID)
{
	// Only server can swap players around
	if (!isServer())
	{
		return;
	}

	DebugPrint("Attempting to swap the player " + player_to_swap_username + "'s control to " + target_blob_networkID);

	// Safety checks
	// Let the player swap if the target blob is in their char list or the unclaimed char list
	if (!hasClaimedChar(player_to_swap_username, target_blob_networkID) && !hasClaimedChar("", target_blob_networkID))
	{
		DebugPrint("Player " + player_to_swap_username + " can not swap to " + target_blob_networkID);
		return;
	}

	// Check that the player exists
	CPlayer@ player = getPlayerByUsername(player_to_swap_username);
	if (player is null)
	{
		DebugPrint("Player " + player_to_swap_username + " was null");
		return;
	}

	// Check if the target exists and is alive and doesn't already have a player
	CBlob@ target_blob = getBlobByNetworkID(target_blob_networkID);
	if (target_blob is null)
	{
		DebugPrint("Target blob with networkID " + target_blob_networkID + " was null");
		return;
	}
	if (target_blob.hasTag("dead") || target_blob.getHealth() <= 0.0f)
	{
		DebugPrint("Target blob with networkID " + target_blob_networkID + " was dead");
		return;
	}
	if (target_blob.getPlayer() !is null)
	{
		DebugPrint("Target blob with networkID " + target_blob_networkID +
			" had player " + target_blob.getPlayer().getUsername());
		return;
	}

	DebugPrint("Attempting to clear previous character's commands");

	CBlob@ previous_character = player.getBlob();
	if (previous_character !is null)
	{
		// Couldn't find anyway to do this but brute force it
		// Clear any actions
		previous_character.setKeyPressed(key_up, false);
		previous_character.setKeyPressed(key_down, false);
		previous_character.setKeyPressed(key_left, false);
		previous_character.setKeyPressed(key_right, false);
		previous_character.setKeyPressed(key_action1, false);
		previous_character.setKeyPressed(key_action2, false);

		// Clear menus for shops so you don't accidentally buy something swapping back to this character
		previous_character.ClearMenus();
	}
	else
	{
		DebugPrint("Player " + player_to_swap_username + "'s previous character was null, abandoning command clearing");
	}

	// Set the player to control the target blob
	DebugPrint("Transferring control");
	target_blob.server_SetPlayer(player);

	// I added a check in EmoteHotkeys.as so swapping using hotkeys wouldn't emote
	// Unfortunately everything I tried here didn't work, wasn't clean, or wasn't robust

	// Clean up any menus
	getHUD().ClearMenus(true);
}

// Removes the blob from any char lists and adds it to owning_player's char list
// If new_owner is empty, removes the blob from any char lists and adds it to the unclaimed char list instead
// DebugPrint needs to be set to true for this to print anything
void TransferCharToPlayerList(CBlob@ this, string new_owner, int index)
{
	// Only server can save + sync lists
	if (!isServer())
	{
		return;
	}

	CRules@ rules = getRules();
	if (rules is null)
	{
		return;
	}

	DebugPrint(new_owner != "" ?
		"Attempting to transfer char to " + new_owner + "'s' player list" :
		"Attempting to transfer char to unclaimed player list");

	// Safety checks
	// Check that the char is not null
	if (this is null)
	{
		DebugPrint("Null blob");
		return;
	}

	// Check if the new owner exists
	if (new_owner != "" && getPlayerByUsername(new_owner) is null)
	{
		DebugPrint("Failed to find new owning player " + new_owner);
		return;
	}

	// Check that the blob does not have a different player if taking from the unclaimed list
	if (new_owner != "" && this.getPlayer() !is null && this.getPlayer().getUsername() != new_owner)
	{
		DebugPrint("Player " + new_owner + " tried to claim char controlled by player " + this.getPlayer().getUsername());
		return;
	}

	// Remove the blob from any char list it may be in
	RemoveCharFromPlayerList(this);

	// Get the new char list
	u16[] char_networkIDs;
	if (hasCharList(new_owner))
	{
		DebugPrint(new_owner != "" ?
			"Player char list for " + new_owner + " found" :
			"Unclaimed char list found");
		readCharList(new_owner, char_networkIDs);
	}
	else
	{
		DebugPrint(new_owner != "" ?
			"Failed to find player list for " + new_owner + ", creating new list" :
			"Failed to find unclaimed char list, creating new list");
	}

	DebugPrint("Char list before addition:");
	PrintCharList(char_networkIDs);

	// Add the blob to player's char list
	if (index < 0 || index >= char_networkIDs.length())
	{
		char_networkIDs.push_back(this.getNetworkID());
	}
	else
	{
		char_networkIDs.insertAt(index, this.getNetworkID());
	}
	
	DebugPrint("Char list after addition:");
	PrintCharList(char_networkIDs);

	// Reset the list in rules
	SaveCharList(new_owner, char_networkIDs);

	// Set the object's new owner
	this.set_string("owning_player", new_owner);
}

// Remove this blob from the owning char list or unclaimed char list if possible
// DebugPrint needs to be set to true for this to print anything
void RemoveCharFromPlayerList(CBlob@ this)
{
	// Only server can save + sync lists
	if (!isServer())
	{
		return;
	}

	DebugPrint("Attempting to remove char from char list");

	// Safety checks
	if (this is null)
	{
		DebugPrint("Null blob");
		return;
	}

	if (!this.hasTag("player"))
	{
		DebugPrint("Non-player blob");
		return;
	}

	// Player that claimed this blob, or empty if unclaimed
	string owning_player = this.exists("owning_player") ? this.get_string("owning_player") : "";
	DebugPrint(owning_player != "" ? "Owned by player " + owning_player : "Potentially in unclaimed char list");
	
	// Get the player's char list
	u16[] char_networkIDs;
	if (!readCharList(owning_player, @char_networkIDs))
	{
		return;
	}

	// Find blob in the char list 
	u16 networkID = this.getNetworkID();
	s16 index = char_networkIDs.find(networkID);

	if (index < 0)
	{
		DebugPrint(owning_player != "" ?
			"Failed to find networkID " + networkID + " in " + owning_player + "'s char list" :
			"Failed to find networkID " + networkID + " in unclaimed char list");
		return;
	}

	DebugPrint("Found networkID in char list, removing");
	DebugPrint("Char list before removal:");
	PrintCharList(char_networkIDs);

	// Remove the blob from the char list
	char_networkIDs.erase(index);
	DebugPrint("Char list after removal:");
	PrintCharList(char_networkIDs);

	// Reset the list in rules
	SaveCharList(owning_player, char_networkIDs);

	// Remove the object's owner
	this.set_string("owning_player", "");
}

// Returns true if the player has a char list and the networkID provided is in it
// If player_name is empty, returns true if the unclaimed list exists and the networkID provided is in it instead
bool hasClaimedChar(string player_name, u16 char_networkID)
{
	DebugPrint(player_name != "" ?
		"Checking if player " + player_name + " has claimed " + char_networkID :
		"Checking if " + char_networkID + " is in the unclaimed char list");
	
	// Get the player
	CPlayer@ player_to_swap = getPlayerByUsername(player_name);
	if (player_name != "" && player_to_swap is null)
	{
		DebugPrint("Player " + player_name + " not found");
		return false;
	}

	// Get the target blob
	CBlob@ target_blob = getBlobByNetworkID(char_networkID);
	if (target_blob is null)
	{
		DebugPrint("Failed to find a blob with networkID " + char_networkID);
		return false;
	}
	
	// Get the player's char list
	u16[] char_networkIDs;
	if (!readCharList(player_name, @char_networkIDs))
	{
		return false;
	}
	PrintCharList(char_networkIDs);

	// Check that the target blob is in the target char list
	if (char_networkIDs.find(char_networkID) < 0)
	{
		DebugPrint(player_name != "" ?
			"Player " + player_name + " has not claimed target blob with networkID " + char_networkID :
			"Target blob with networkID " + char_networkID + " is not in unclaimed char list");
		return false;
	}

	DebugPrint(player_name != "" ?
		"Player "  + player_name + " has claimed target blob" :
		"Target blob with networkID " + char_networkID + " is in unclaimed char list");
	return true;
}

// Prints each networkID in the char list provided
// DebugPrint needs to be set to true for this to print anything
void PrintCharList(u16[]@ char_networkIDs)
{
	for (u8 i = 0; i < char_networkIDs.length(); i++)
	{
		DebugPrint("" + char_networkIDs[i]);
	}
}

// Print wrapper so I can turn off debugging prints later
// Controls printing for everything in this script
void DebugPrint(string message)
{
	// Set this to true if you want to print debug information
	if (false)
	{
		print(message);
	}
}

// Saves a char list as a bunch of individual networkIDs because you can't sync lists from server to client
// DebugPrint needs to be set to true for this to print anything
void SaveCharList(string player_name, u16[]@ char_networkIDs)
{
	// Only server can save + sync lists
	if (!isServer())
	{
		return;
	}

	DebugPrint(player_name != "" ?
		"Attempting to save player " + player_name + "'s char list" :
		"Attempting to save unclaimed char list");

	// Safety checks
	CRules@ rules = getRules();
	if (rules is null)
	{
		DebugPrint("Null rules");
		return;
	}

	if (player_name != "" && getPlayerByUsername(player_name) is null)
	{
		DebugPrint("Failed to find player " + player_name);
		return;
	}

	if (char_networkIDs is null)
	{
		DebugPrint("Player " + player_name + " not found");
		return;
	}

	// Write the char list
	if (player_name != "")  // Write the player's char list
	{
		for (u8 i = 0; i < char_networkIDs.length(); i++)
		{
			string player_list_name = player_name + "_player_char_list_" + i;
			rules.set_u16(player_list_name, char_networkIDs[i]);
			rules.Sync(player_list_name, true);
		}

		string player_list_length_name = player_name + "_player_char_list_length";
		rules.set_u8(player_list_length_name, char_networkIDs.length());
		rules.Sync(player_list_length_name, true);

		DebugPrint(player_name + "'s char list saved successfully");
	}
	else  // Write the unclaimed char list
	{
		for (u8 i = 0; i < char_networkIDs.length(); i++)
		{
			string unclaimed_list_name = "unclaimed_char_list_" + i;
			rules.set_u16(unclaimed_list_name, char_networkIDs[i]);
			rules.Sync(unclaimed_list_name, true);
		}

		string unclaimed_list_length_name = "unclaimed_char_list_length";
		rules.set_u8(unclaimed_list_length_name, char_networkIDs.length());
		rules.Sync(unclaimed_list_length_name, true);

		DebugPrint("Unclaimed char list saved successfully");
	}
}

// Reads a char list of individual networkIDs because you can't sync lists from server to client
// If player_name is empty, returns the unclaimed list instead
// DebugPrint needs to be set to true for this to print anything
// Returns true if the list was read successfully
bool readCharList(string player_name, u16[]@ char_networkIDs)
{
	/*
	DebugPrint(player_name != "" ?
		"Attempting to read player " + player_name + "'s char list" :
		"Attempting to read unclaimed char list");
	*/

	// Safety checks
	CRules@ rules = getRules();
	if (rules is null)
	{
		DebugPrint("Null rules");
		return false;
	}

	if (player_name != "" && getPlayerByUsername(player_name) is null)
	{
		DebugPrint("Failed to find player " + player_name);
		return false;
	}

	if (char_networkIDs is null)
	{
		DebugPrint("Null array");
		return false;
	}

	if (!hasCharList(player_name))
	{
		DebugPrint(player_name != "" ?
			"Failed to find char list for " + player_name :
			"Failed to find unclaimed char list");
		return false;
	}

	// Read the char list
	if (player_name != "")  // Read the player char list
	{
		for (u8 i = 0; i < rules.get_u8(player_name + "_player_char_list_length"); i++)
		{
			string player_list_name = player_name + "_player_char_list_" + i;
			char_networkIDs.push_back(rules.get_u16(player_list_name));
		}
		// DebugPrint(player_name + "'s char list read successfully");
	}
	else  // Read the unclaimed char list
	{
		for (u8 i = 0; i < rules.get_u8("unclaimed_char_list_length"); i++)
		{
			string player_list_name = "unclaimed_char_list_" + i;
			char_networkIDs.push_back(rules.get_u16(player_list_name));
		}
		// DebugPrint("Unclaimed char list read successfully");
	}
	
	return true;
}

// Returns true if the player has an existing character list
// If player_name is empty, checks if the unclaimed list exists instead
bool hasCharList(string player_name)
{
	CRules@ rules = getRules();
	if (rules is null)
	{
		return false;
	}

	if (player_name != "")
	{
		return rules.exists(player_name + "_player_char_list_length");
	}
	else
	{
		return rules.exists("unclaimed_char_list_length");
	}
}