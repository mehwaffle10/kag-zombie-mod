
void onInit(CRules@ this)
{
	this.addCommandID("swap_player");
	this.addCommandID("transfer_char");
}

void onInit(CPlayer@ this)
{
	// Add a list of the player's characters if it doesn't exist yet
	CRules@ rules = getRules();
	string player_list_name = this.getUsername() + "_player_char_list";
	if (!rules.exists(player_list_name))
	{
		// Add the player's initial blob if it exists TODO remove this and add it only for the inital spawn
		u16[] player_char_networkIDs;
		CBlob@ blob = this.getBlob();
		if (blob !is null)
		{
			player_char_networkIDs.push_back(blob.getNetworkID());
			blob.set_string("owning_player", this.getUsername());
		}

		// Add the list to our rules
		rules.set(player_list_name, player_char_networkIDs);
		rules.Sync("player_list_name", true);
	}
}

void onDie(CBlob@ this)
{	
	// Clean up dead blobs
	RemoveCharFromPlayerList(this);
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	// Safety(?) check
	debug_print("Received Command");
	if (!getNet().isServer())
	{
		debug_print("Aborting client execution, execution is server side only");
		return;
	}

	if (cmd == this.getCommandID("swap_player"))
	{
		debug_print("Command is swap_player");
		string player_to_swap_username;
		if (params.saferead_string(player_to_swap_username))
		{
			return;
		}
		u16 target_blob_networkID;
		if (params.saferead_netid(target_blob_networkID))
		{
			return;
		}

		SwapPlayerControl(player_to_swap_username, target_blob_networkID);
	}
	else if (cmd == this.getCommandID("transfer_char"))
	{
		debug_print("Command is transfer_char");
		string sending_player;
		if (params.saferead_string(sending_player))
		{
			return;
		}
		string player_to_swap_username;
		if (params.saferead_string(player_to_swap_username))
		{
			return;
		}
		u16 target_blob_networkID;
		if (params.saferead_netid(target_blob_networkID))
		{
			return;
		}

		if (!PlayerOwnsChar(sending_player, target_blob_networkID))
		{
			return;
		}

		TransferCharToPlayerList(getBlobByNetworkID(target_blob_networkID), player_to_swap_username);
	}
}



// Transfers control of a player to a target blob if the player owns that blob
void SwapPlayerControl(string player_to_swap_username, u16 target_blob_networkID)
{
	debug_print("Attempting to swap the " + player_to_swap_username + "'s control to " + target_blob_networkID);

	if (!PlayerOwnsChar(player_to_swap_username, target_blob_networkID))
	{
		return;
	}

	debug_print("Transferring control");

	// Set the player to control the target blob
	getBlobByNetworkID(target_blob_networkID).server_SetPlayer(getPlayerByUsername(player_to_swap_username));
}

// Removes the blob from any char lists and adds it to owning_player's
// debug_print needs to be set to true for this to do anything
void TransferCharToPlayerList(CBlob@ this, string new_owner)
{
	debug_print("Attempting to transfer char to " + new_owner + "'s' player list");

	// Safety checks
	// Check that the char is not null
	if (this is null)
	{
		debug_print("Null blob");
		return;
	}

	// Check if the new owner exists
	if (getPlayerByUsername(new_owner) is null)
	{
		debug_print("Failed to find new owning player " + new_owner);
		return;
	}

	// Get the new owner's char list
	string player_list_name = new_owner + "_player_char_list";
	u16[] player_char_networkIDs;
	CRules@ rules = getRules();
	if (rules.exists(player_list_name))
	{
		debug_print("Player list for " + new_owner + " found");
		rules.get(player_list_name, @player_char_networkIDs);
	}
	else
	{
		debug_print("Failed to find player list for " + new_owner + ", creating new list");
	}

	// Remove the blob from any char list it may be in
	RemoveCharFromPlayerList(this);

	debug_print("Player list before addition:");
	printCharList(player_char_networkIDs);

	// Add the blob to player's char list
	player_char_networkIDs.push_back(this.getNetworkID());
	debug_print("Player list after addition:");
	printCharList(player_char_networkIDs);

	// Reset the list in rules
	rules.set(player_list_name, player_char_networkIDs);
	rules.Sync("player_list_name", true);

	// Set the object's new owner
	this.set_string("owning_player", new_owner);
}

// Remove this blob from the player's char list if possible
// debug_print needs to be set to true for this to do anything
void RemoveCharFromPlayerList(CBlob@ this)
{
	debug_print("Attempting to remove char from player list");

	// Safety checks
	if (this is null)
	{
		debug_print("Null blob");
		return;
	}

	if (!this.exists("owning_player"))
	{
		debug_print("Could not find owning player");
		return;
	}
	string owning_player = this.get_string("owning_player");

	if (owning_player == "")
	{
		debug_print("Blob has no owning player");
		return;
	}

	// Get the player's char list
	string player_list_name = owning_player + "_player_char_list";
	CRules@ rules = getRules();
	if (!rules.exists(player_list_name))
	{
		debug_print("Failed to find player list for " + owning_player);
		return;
	}
	
	u16[] player_char_networkIDs;
	rules.get(player_list_name, @player_char_networkIDs);
	debug_print("Player list acquired");

	// Find blob in the char list 
	u16 networkID = this.getNetworkID();
	s32 index = player_char_networkIDs.find(networkID);

	if (index < 0)
	{
		debug_print("Failed to find networkID " + networkID + " in " + owning_player + "'s char list");
		return;
	}

	debug_print("Found networkID in char list, removing");
	debug_print("List before removal:");
	printCharList(player_char_networkIDs);

	// Remove the blob from the char list
	player_char_networkIDs.erase(index);
	debug_print("List after removal:");
	printCharList(player_char_networkIDs);

	// Reset the list in rules
	rules.set(player_list_name, player_char_networkIDs);
	rules.Sync("player_list_name", true);

	// Remove the object's owner
	this.set_string("owning_player", "");
}

// Returns true if the player has a char list and owns the networkID provided
bool PlayerOwnsChar(string player_name, u16 char_networkID)
{
	debug_print("Checking if player " + player_name + " owns " + char_networkID);
	
	// Get the player
	CPlayer@ player_to_swap = getPlayerByUsername(player_name);
	if (player_to_swap is null)
	{
		debug_print("Player " + player_name + " not found");
		return false;
	}

	// Get the target blob
	CBlob@ target_blob = getBlobByNetworkID(char_networkID);
	if (target_blob is null)
	{
		debug_print("Failed to find target blob by networkID");
		return false;
	}

	// Get the player's char list
	string player_list_name = player_name + "_player_char_list";
	CRules@ rules = getRules();
	if (!rules.exists(player_list_name))
	{
		debug_print("Failed to find player list for " + player_name);
		return false;
	}
	
	u16[] player_char_networkIDs;
	rules.get(player_list_name, @player_char_networkIDs);
	debug_print("Player list acquired");

	// Check that the player owns the target blob
	if (player_char_networkIDs.find(char_networkID) < 0)
	{
		debug_print("Player " + player_name + " does not own target blob");
		return false;
	}

	debug_print("Player "  + player_name + "owns target blob");
	return true;
}

// Prints each networkID in the player list provided
// debug_print needs to be set to true for this to do anything
void printCharList(u16[]@ player_char_networkIDs)
{
	for (u8 i = 0; i < player_char_networkIDs.length(); i++)
	{
		debug_print("" + player_char_networkIDs[i]);
	}
}

// Print wrapper so I can turn off debugging prints later
// Controls printing for everything in this script
void debug_print(string message)
{
	// Set this to true if you want to print debug information
	if (true)
	{
		print(message);
	}
}

