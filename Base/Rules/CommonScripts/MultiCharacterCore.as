
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

void onRespawn(CRules@ this, CRespawnQueueActor@ queue, CPlayer@ player, CBlob@ blob)
{
	DebugPrint("Player respawn");
	if (player is null)
	{
		DebugPrint("Player was null");
		return;
	}
	TransferCharToPlayerList(blob, player.getUsername());
}

/*
void onBlobCreated(CRules@ this, CBlob@ blob)
{
	if (blob !is null && blob.hasTag("player") && blob.getPlayer() !is null)
	{
		TransferCharToPlayerList(blob, blob.getPlayer().getUsername());
	}
}
*/

void onBlobDie(CRules@ this, CBlob@ blob)
{	
	// Clean up dead blobs
	RemoveCharFromPlayerList(blob);
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
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

		// Check if the player has claimed the target or if the target is unclaimmed first
		if (!hasClaimedChar(sending_player, target_blob_networkID) && !hasClaimedChar("", target_blob_networkID))
		{
			return;
		}

		TransferCharToPlayerList(getBlobByNetworkID(target_blob_networkID), player_to_swap_username);
	}
}
