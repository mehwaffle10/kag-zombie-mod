
// SHOW KILL MESSAGES ON CLIENT
// Adapted from KillMessages.as

#define CLIENT_ONLY

#include "Hitters.as";
#include "TeamColour.as";
#include "HoverMessage.as";
#include "MultiCharacterButtonLogic.as";

int fade_time = 300;
// Offset to compensate for the player's char list.
// Will probably attach to CRules from MultiCharacterUI.as later to account for hiding the menu
int frame_offset = 124 + 12;

class MultiCharacterKillMessage
{
	string victim;
	string attacker;
	int victim_team;
	int attacker_team;
	u8 hitter;
	s16 time;

	MultiCharacterKillMessage(CBlob@ _victim, CBlob@ _attacker, u8 _hitter)
	{
		if (_victim !is null)
		{
			if (_victim.exists("forename"))
			{
				victim = _victim.get_string("forename");
				victim += _victim.exists("surname") ? " " + _victim.get_string("surname") : "";
			}
			else
			{
				victim = _victim.getName();
			}

			victim_team = _victim.getTeamNum();
		}
		else
		{
			victim = "";
			victim_team = -1;
		}

		if (_attacker !is null)
		{
			if (_attacker.exists("forename"))
			{
				attacker = _attacker.get_string("forename");
				attacker += _attacker.exists("surname") ? " " + _attacker.get_string("surname") : "";
			}
			else
			{
				attacker = _attacker.getName();
			}

			attacker_team = _attacker.getTeamNum();
		}
		else
		{
			attacker = "";
			attacker_team = -1;
		}

		hitter = _hitter;
		time = fade_time;
	}
};

class MultiCharacterKillFeed
{
	MultiCharacterKillMessage[] kill_messages;

	void Update()
	{
		while (kill_messages.length > 10)
		{
			kill_messages.erase(0);
		}

		for (uint message_step = 0; message_step < kill_messages.length; ++message_step)
		{
			MultiCharacterKillMessage@ message = kill_messages[message_step];
			message.time--;

			if (message.time == 0)
				kill_messages.erase(message_step--);
		}
	}

	void Render()
	{
		const uint count = Maths::Min(10, kill_messages.length);
		GUI::SetFont("menu");
		for (uint message_step = 0; message_step < count; ++message_step)
		{
			MultiCharacterKillMessage@ message = kill_messages[message_step];
			Vec2f dim, ul, lr;
			SColor col;
			f32 yOffset = 1.0f;

			Vec2f max_name_size;
			GUI::GetTextDimensions("#########################", max_name_size);  //25 chars
			Vec2f single_space_size;
			GUI::GetTextDimensions("#", single_space_size);//1 char

			//decide icon based on hitter
			string hitterIcon;

			switch (message.hitter)
			{
				case Hitters::fall:     		hitterIcon = "$killfeed_fall$"; break;

				case Hitters::drown:     		hitterIcon = "$killfeed_water$"; break;

				case Hitters::fire:
				case Hitters::burn:     		hitterIcon = "$killfeed_fire$"; break;

				case Hitters::stomp:    		hitterIcon = "$killfeed_stomp$"; break;

				case Hitters::builder:  		hitterIcon = "$killfeed_builder$"; break;

				case Hitters::spikes:  			hitterIcon = "$killfeed_spikes$"; break;

				case Hitters::sword:    		hitterIcon = "$killfeed_sword$"; break;

				case Hitters::shield:   		hitterIcon = "$killfeed_shield$"; break;

				case Hitters::bomb_arrow:		hitterIcon = "$killfeed_bombarrow$"; break;

				case Hitters::bomb:
				case Hitters::explosion:     	hitterIcon = "$killfeed_bomb$"; break;

				case Hitters::keg:     			hitterIcon = "$killfeed_keg$"; break;

				case Hitters::mine:             hitterIcon = "$killfeed_mine$"; break;
				case Hitters::mine_special:     hitterIcon = "$killfeed_mine$"; break;

				case Hitters::arrow:    		hitterIcon = "$killfeed_arrow$"; break;

				case Hitters::ballista: 		hitterIcon = "$killfeed_ballista$"; break;

				case Hitters::boulder:
				case Hitters::cata_stones:
				case Hitters::cata_boulder:  	hitterIcon = "$killfeed_boulder$"; break;

				case Hitters::drill:			hitterIcon = "$killfeed_drill$"; break;
				case Hitters::saw:				hitterIcon = "$killfeed_saw$"; break;

				default: 						hitterIcon = "$killfeed_fall$";
			}

			//draw victim name
			Vec2f victim_name_size;
			GUI::GetTextDimensions(message.victim, victim_name_size);

			dim = Vec2f(getScreenWidth() - victim_name_size.x - frame_offset, 0);

			ul.Set(dim.x, (message_step + yOffset) * 16);
			col = getTeamColor(message.victim_team);
			GUI::DrawText(message.victim, ul, col);

			if (message.attacker_team != -1)
			{
				//draw attacker name

				Vec2f attacker_size;
				GUI::GetTextDimensions(message.attacker, attacker_size);
				dim = Vec2f(getScreenWidth() - victim_name_size.x - attacker_size.x - single_space_size.x - frame_offset - 32, 0);
				ul.Set(dim.x, (message_step + yOffset) * 16);
				col = getTeamColor(message.attacker_team);
				GUI::DrawText(message.attacker, ul, col);
			}

			//draw hitter icon
			if (hitterIcon != "")
			{
				dim = Vec2f(getScreenWidth() - victim_name_size.x - frame_offset - (single_space_size.x * 2) - 32, 0);
				ul.Set(dim.x, ((message_step + yOffset) * 16) - 8);
				GUI::DrawIconByName(hitterIcon, ul);
			}
		}
	}

};

void Reset(CRules@ this)
{
	MultiCharacterKillFeed feed;
	this.set("MultiCharacterKillFeed", feed);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);

	AddIconToken("$killfeed_fall$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 1);
	AddIconToken("$killfeed_water$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 2);
	AddIconToken("$killfeed_fire$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 3);
	AddIconToken("$killfeed_stomp$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 4);

	AddIconToken("$killfeed_builder$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 8);
	AddIconToken("$killfeed_axe$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 9);
	AddIconToken("$killfeed_spikes$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 10);
	AddIconToken("$killfeed_boulder$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 11);

	AddIconToken("$killfeed_sword$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 12);
	AddIconToken("$killfeed_shield$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 13);
	AddIconToken("$killfeed_bomb$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 14);
	AddIconToken("$killfeed_keg$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 15);
	AddIconToken("$killfeed_mine$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 18);

	AddIconToken("$killfeed_arrow$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 16);
	AddIconToken("$killfeed_bombarrow$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 21);
	AddIconToken("$killfeed_ballista$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 17);

	AddIconToken("$killfeed_drill$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 19);
	AddIconToken("$killfeed_saw$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 20);
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	// Safety checks
	if (this is null || params is null)
	{
		return;
	}

	// Only client responds to these commands, but no need to check because of #define CLIENT_ONLY
	if (cmd == this.getCommandID("kill_feed"))
	{
		string player_list_to_move_up;
		if (!params.saferead_string(player_list_to_move_up))
		{
			return;
		}

		u16 victim_blob_networkID;
		if (!params.saferead_netid(victim_blob_networkID))
		{
			return;
		}

		CBlob@ victim = getBlobByNetworkID(victim_blob_networkID);

		if (victim !is null && victim.hasTag("player") && victim.exists("owning_player"))
		{
			// Move up the corresponding player list
			MoveUpPlayerList(player_list_to_move_up == "" ? null : getPlayerByUsername(player_list_to_move_up));

			// Add to the kill feed
			MultiCharacterKillFeed@ feed;
			if (this.get("MultiCharacterKillFeed", @feed) && feed !is null)
			{
				MultiCharacterKillMessage message(victim, null, 0);
				feed.kill_messages.push_back(message);
			}
		}
	}
}

void onTick(CRules@ this)
{
	MultiCharacterKillFeed@ feed;

	if (this.get("MultiCharacterKillFeed", @feed) && feed !is null)
	{
		feed.Update();
	}
}

void onRender(CRules@ this)
{
	if (g_videorecording)
		return;

	MultiCharacterKillFeed@ feed;

	if (this.get("MultiCharacterKillFeed", @feed) && feed !is null)
	{
		feed.Render();
	}
}
