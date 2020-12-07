
// Transfers control of a player to a target blob if the player owns that blob
void SwapPlayerControl(string player_to_swap_username, u16 target_blob_networkID)
{
	if (!isServer())
	{
		return;
	}


	DebugPrint("Attempting to swap the player " + player_to_swap_username + "'s control to " + target_blob_networkID);

	if (!playerOwnsChar(player_to_swap_username, target_blob_networkID))
	{
		return;
	}

	DebugPrint("Transferring control");

	// Set the player to control the target blob
	getBlobByNetworkID(target_blob_networkID).server_SetPlayer(getPlayerByUsername(player_to_swap_username));
}

// Removes the blob from any char lists and adds it to owning_player's
// DebugPrint needs to be set to true for this to print anything
void TransferCharToPlayerList(CBlob@ this, string new_owner)
{
	if (!isServer())
	{
		return;
	}

	DebugPrint("Attempting to transfer char to " + new_owner + "'s' player list");

	// Safety checks
	// Check that the char is not null
	if (this is null)
	{
		DebugPrint("Null blob");
		return;
	}

	// Check if the new owner exists
	if (getPlayerByUsername(new_owner) is null)
	{
		DebugPrint("Failed to find new owning player " + new_owner);
		return;
	}

	// Get the new owner's char list
	u16[] player_char_networkIDs;
	CRules@ rules = getRules();
	if (hasCharList(new_owner))
	{
		DebugPrint("Player list for " + new_owner + " found");
		readCharList(new_owner, player_char_networkIDs);
	}
	else
	{
		DebugPrint("Failed to find player list for " + new_owner + ", creating new list");
	}

	// Remove the blob from any char list it may be in
	RemoveCharFromPlayerList(this);

	DebugPrint("Player list before addition:");
	PrintCharList(player_char_networkIDs);

	// Add the blob to player's char list
	player_char_networkIDs.push_back(this.getNetworkID());
	DebugPrint("Player list after addition:");
	PrintCharList(player_char_networkIDs);

	// Reset the list in rules
	SaveCharList(new_owner, player_char_networkIDs);

	// Set the object's new owner
	this.set_string("owning_player", new_owner);
}

// Remove this blob from the player's char list if possible
// DebugPrint needs to be set to true for this to print anything
void RemoveCharFromPlayerList(CBlob@ this)
{
	if (!isServer())
	{
		return;
	}

	DebugPrint("Attempting to remove char from player list");

	// Safety checks
	if (this is null)
	{
		DebugPrint("Null blob");
		return;
	}

	if (!this.exists("owning_player"))
	{
		DebugPrint("Could not find owning player");
		return;
	}
	string owning_player = this.get_string("owning_player");

	if (owning_player == "")
	{
		DebugPrint("Blob has no owning player");
		return;
	}
	
	// Get the player's char list
	u16[] player_char_networkIDs;
	if (!readCharList(owning_player, @player_char_networkIDs))
	{
		return;
	}

	// Find blob in the char list 
	u16 networkID = this.getNetworkID();
	s32 index = player_char_networkIDs.find(networkID);

	if (index < 0)
	{
		DebugPrint("Failed to find networkID " + networkID + " in " + owning_player + "'s char list");
		return;
	}

	DebugPrint("Found networkID in char list, removing");
	DebugPrint("List before removal:");
	PrintCharList(player_char_networkIDs);

	// Remove the blob from the char list
	player_char_networkIDs.erase(index);
	DebugPrint("List after removal:");
	PrintCharList(player_char_networkIDs);

	// Reset the list in rules
	SaveCharList(owning_player, player_char_networkIDs);

	// Remove the object's owner
	this.set_string("owning_player", "");
}

// Returns true if the player has a char list and owns the networkID provided
bool playerOwnsChar(string player_name, u16 char_networkID)
{
	DebugPrint("Checking if player " + player_name + " owns " + char_networkID);
	
	// Get the player
	CPlayer@ player_to_swap = getPlayerByUsername(player_name);
	if (player_to_swap is null)
	{
		DebugPrint("Player " + player_name + " not found");
		return false;
	}

	// Get the target blob
	CBlob@ target_blob = getBlobByNetworkID(char_networkID);
	if (target_blob is null)
	{
		DebugPrint("Failed to find target blob by networkID");
		return false;
	}
	
	// Get the player's char list
	u16[] player_char_networkIDs;
	if (!readCharList(player_name, @player_char_networkIDs))
	{
		return false;
	}
	PrintCharList(player_char_networkIDs);

	// Check that the player owns the target blob
	if (player_char_networkIDs.find(char_networkID) < 0)
	{
		DebugPrint("Player " + player_name + " does not own target blob");
		return false;
	}

	DebugPrint("Player "  + player_name + " owns target blob");
	return true;
}

// Prints each networkID in the player list provided
// DebugPrint needs to be set to true for this to print anything
void PrintCharList(u16[]@ player_char_networkIDs)
{
	for (u8 i = 0; i < player_char_networkIDs.length(); i++)
	{
		DebugPrint("" + player_char_networkIDs[i]);
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

// Saves a list as a bunch of individual networkIDs because you can't sync lists from server to client
// DebugPrint needs to be set to true for this to print anything
void SaveCharList(string player_name, u16[]@ player_char_networkIDs)
{
	if (!isServer())
	{
		return;
	}

	DebugPrint("Attempting to save player " + player_name + "'s char list");

	CRules@ rules = getRules();
	if (rules is null)
	{
		DebugPrint("Null rules");
		return;
	}

	if (getPlayerByUsername(player_name) is null)
	{
		DebugPrint("Player " + player_name + " not found");
		return;
	}

	if (player_char_networkIDs is null)
	{
		DebugPrint("Player " + player_name + " not found");
		return;
	}

	for (u8 i = 0; i < player_char_networkIDs.length(); i++)
	{
		string player_list_name = player_name + "_player_char_list_" + i;
		rules.set_u16(player_list_name, player_char_networkIDs[i]);
		rules.Sync(player_list_name, true);
	}

	string player_list_length = player_name + "_player_char_list_length";
	rules.set_u8(player_list_length, player_char_networkIDs.length());
	rules.Sync(player_list_length, true);

	DebugPrint(player_name + "'s char list saved successfully");
}

// Reads a list of individual networkIDs because you can't sync lists from server to client
// DebugPrint needs to be set to true for this to print anything
// Returns true if the list was read successfully
bool readCharList(string player_name, u16[]@ player_char_networkIDs)
{
	DebugPrint("Attempting to read player " + player_name + "'s char list");
	CRules@ rules = getRules();
	if (rules is null)
	{
		DebugPrint("Null rules");
		return false;
	}

	if (getPlayerByUsername(player_name) is null)
	{
		DebugPrint("Failed to find player " + player_name);
		return false;
	}

	if (player_char_networkIDs is null)
	{
		DebugPrint("Null array");
		return false;
	}

	if (!hasCharList(player_name))
	{
		DebugPrint("Failed to find char list for " + player_name);
		return false;
	}

	for (u8 i = 0; i < rules.get_u8(player_name + "_player_char_list_length"); i++)
	{
		string player_list_name = player_name + "_player_char_list_" + i;
		player_char_networkIDs.push_back(rules.get_u16(player_list_name));
	}
	DebugPrint(player_name + "'s char list read successfully");

	return true;
}

// Returns true if the player has an existing char table
bool hasCharList(string player_name)
{
	CRules@ rules = getRules();
	if (rules is null)
	{
		return false;
	}

	return rules.exists(player_name + "_player_char_list_length");
}