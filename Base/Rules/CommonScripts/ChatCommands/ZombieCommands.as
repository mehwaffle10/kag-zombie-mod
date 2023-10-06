
#include "ChatCommand.as"
#include "MultiCharacterCommon.as";
#include "ZombiesMinimapCommon.as";

void onInit(CRules@ this)
{
	ChatCommands::RegisterCommand(ExploreCommand());
	ChatCommands::RegisterCommand(SurvivorCommand());
}

class ExploreCommand : ChatCommand
{
	ExploreCommand()
	{
		super("explore", "Explore the entire map");
	}

	void Execute(string[] args, CPlayer@ player)
	{
        CRules@ rules = getRules();
		CBitStream params;
        params.write_s32(-10);
        params.write_s32(32000);
        rules.SendCommand(rules.getCommandID(ZOMBIE_MINIMAP_EXPLORE_SYNC_COMMAND), params);
	}
}

class SurvivorCommand : ChatCommand
{
	SurvivorCommand()
	{
		super("survivor", "Spawn a survivor");
	}

	void Execute(string[] args, CPlayer@ player)
	{
        if (player is null)
        {
            return;
        }
        CBlob@ blob = player.getBlob();
        if (blob !is null)
        {
		    SpawnSurvivor(blob.getPosition());
        }
	}
}
