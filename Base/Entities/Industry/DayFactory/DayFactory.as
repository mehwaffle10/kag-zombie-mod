// Factory

#include "ShopCommon.as"
#include "Help.as"
#include "Costs.as"
#include "Hitters.as"
#include "GenericButtonCommon.as"
#include "FireParticle.as";
#include "Requirements.as";
#include "MaterialCommon.as";

const string children_destructible_tag = "children destructible";
const string children_destructible_label = "children destruct label";

class FactoryItem
{
	string display_name, item, file_name;
	u8 count, display_amount, frame;
	s8 sign_offset;
	f32 sign_scale;
	CBitStream requirements;
	

	FactoryItem(string name, string it, string file, u8 ct, u8 amt, u8 fr, s8 offset, f32 scale)
	{
		display_name = name;
		item = it;
		file_name = file;
		count = ct;
		display_amount = amt;
		frame = fr;
		sign_offset = offset;
		sign_scale = scale;
	}

	void AddReq(string material, string display_name, u16 amount)
	{
		AddRequirement(requirements, "blob", material, display_name, amount);
	}
}

FactoryItem@[] initFactoryItems()
{
	FactoryItem@[] items;   	// Display Name,  Item Name,          Image File,	Number to Spawn, Number of Items, Frame, Sign Offset, Sign Scale
	items.push_back(FactoryItem("Arrows", 		"mat_arrows", 		"Materials.png", 		2, 			60, 			27, 	-4, 		1.0f));
	items.push_back(FactoryItem("Water Arrows", "mat_waterarrows", 	"Materials.png", 		2, 			4, 				28, 	-1,			0.8f));
	items.push_back(FactoryItem("Fire Arrows", 	"mat_firearrows", 	"Materials.png", 		2, 			4, 				12,		-2,			0.85f));
	items.push_back(FactoryItem("Bomb Arrows", 	"mat_bombarrows", 	"Materials.png", 		2, 			2, 				5,		-1,			0.8f));
	items.push_back(FactoryItem("Bombs", 		"mat_bombs", 		"Materials.png", 		2, 			2, 				13,		-2,			0.95f));
	items.push_back(FactoryItem("Water Bombs", 	"mat_waterbombs", 	"Materials.png", 		2, 			2, 				21,		-2,			0.95f));
	items.push_back(FactoryItem("Mines", 		"mine", 			"Mine.png", 	 		2, 			2, 				1,		0,			0.75f));
	items.push_back(FactoryItem("Kegs", 		"keg", 				"Keg.png", 				1, 			1, 				0,		0,			0.7f));
	items.push_back(FactoryItem("Burgers", 		"food", 			"Food.png", 			2, 			2, 				6,		0,			1.0f));

	// Arrows
	items[0].AddReq("mat_wood", "Wood", 50);
	items[0].AddReq("mat_gold", "Gold", 50);

	// Water Arrows
	items[1].AddReq("mat_wood", "Wood", 50);
	items[1].AddReq("mat_gold", "Gold", 50);

	// Fire Arrows
	items[2].AddReq("mat_wood", "Wood", 50);
	items[2].AddReq("mat_gold", "Gold", 50);

	// Bomb Arrows
	items[3].AddReq("mat_wood", "Wood", 50);
	items[3].AddReq("mat_gold", "Gold", 50);

	// Bombs
	items[4].AddReq("mat_wood", "Wood", 50);
	items[4].AddReq("mat_gold", "Gold", 50);

	// Water Bombs
	items[5].AddReq("mat_wood", "Wood", 50);
	items[5].AddReq("mat_gold", "Gold", 50);

	// Mines
	items[6].AddReq("mat_wood", "Wood", 50);
	items[6].AddReq("mat_gold", "Gold", 50);

	// Kegs
	items[7].AddReq("mat_wood", "Wood", 50);
	items[7].AddReq("mat_gold", "Gold", 50);

	// Burgers
	items[8].AddReq("mat_wood", "Wood", 50);
	items[8].AddReq("mat_gold", "Gold", 50);

	return items;
}

namespace FactoryItems
{
	FactoryItem@[] items = initFactoryItems();
}

FactoryItem@ getFactoryItemByName(string item)
{
	for (u8 i = 0; i < FactoryItems::items.length; i++)
	{
		if (FactoryItems::items[i].item == item)
		{
			return FactoryItems::items[i];
		}
	}

	return null;
}

bool hasTech(CBlob@ this)
{
	return this.get_string("tech name").size() > 0;
}

void onInit(CBlob@ this)
{
	InitCosts(); //read from cfg

	this.addCommandID("select item menu");
	this.addCommandID("refund");
	this.addCommandID("select item");
	this.addCommandID("pause production");
	this.addCommandID("unpause production");
	
	// Produce on dawn
	this.Tag("day");
	this.addCommandID("day");

	// Make it so builders can break them even when on the same team
	this.Tag("builder always hit");

	if (getNet().isServer())
	{
		this.set_TileType("background tile", CMap::tile_wood_back);

		SetHelp(this, "help use", "builder", getTranslatedString("$workshop$Convert factory    $KEY_E$"), "", 3);

		this.set_Vec2f("production offset", Vec2f(-8.0f, 0.0f));

		// Start powered off
		this.SendCommand(this.getCommandID("pause production"));
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null || !canSeeButtons(this, caller))
	{
		return;
	}

	CBitStream params, missing;
	params.write_u16(caller.getNetworkID());

	if (caller.isOverlapping(this))
	{
		// Select tech or refund button
		if (hasTech(this))
		{
			CButton@ selectItem = caller.CreateGenericButton(12, Vec2f(0, 0), this, this.getCommandID("refund"), getTranslatedString("Refund Item Selection"), params);
		}
		else
		{
			CButton@ selectItem = caller.CreateGenericButton(12, Vec2f(0, 0), this, this.getCommandID("select item menu"), getTranslatedString("Select Item to Produce"), params);
		}
	}
}

void BuildUpgradeMenu(CBlob@ this, CBlob@ caller)
{
	if (caller !is null && caller.isMyPlayer())
	{
		caller.ClearMenus();

		CGridMenu@ menu = CreateGridMenu(caller.getScreenPos() + Vec2f(0.0f, 50.0f), this, Vec2f(4, 3), getTranslatedString("Produce..."));
		if (menu !is null)
		{
			menu.deleteAfterClick = true;
			AddButtons(this, menu, FactoryItems::items, caller);
		}
	}
}

void AddButtons(CBlob@ this, CGridMenu@ menu, FactoryItem@[] items, CBlob@ caller)
{
	if (this is null || menu is null || items is null || caller is null)
	{
		return;
	}

	CInventory@ inv = this.getInventory();
	for (u8 i = 0; i < items.length; i++)
	{
	
		CBitStream params;
		params.write_string(items[i].item);
		params.write_netid(caller.getNetworkID());
		
		CGridButton@ button = menu.AddButton(items[i].file_name, items[i].frame, Vec2f(16, 16), items[i].display_name, this.getCommandID("select item"), Vec2f(1, 1), params);
		
		if (button !is null)
		{
			button.SetNumber(items[i].display_amount);
			SetItemDescription(button, caller, items[i].requirements, items[i].display_name);

			CInventory@ inv = caller.getInventory();
			if (inv !is null)
			{
				CBitStream missing;
				if(hasRequirements(inv, items[i].requirements, missing))
				{
					button.SetEnabled(true);
				}
				else
				{
					button.SetEnabled(false);
				}
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();
	if (this is null)
	{
		return;
	}

	if (cmd == this.getCommandID("select item menu"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		BuildUpgradeMenu(this, caller);
	}
	else if (cmd == this.getCommandID("refund"))
	{
		this.getSprite().PlaySound("/ConstructShort.ogg");

		if (isServer)
		{
			if (!hasTech(this))
			{
				return;
			}

			FactoryItem	factory_item = getFactoryItemByName(this.get_string("tech name"));
			CBlob@ caller = getBlobByNetworkID(params.read_netid());
			if (factory_item is null || caller is null || caller.getInventory() is null)
			{
				return;
			}

			// Couldn't find where the stream was being exhausted, probably should find that instead though
			factory_item.requirements.ResetBitIndex();
			while (!factory_item.requirements.isBufferEnd())
			{
				string req, material, display_name;
				u16 amount;
				ReadRequirement(factory_item.requirements, req, material, display_name, amount);

				Material::createFor(caller, material, amount);
			}
			factory_item.requirements.ResetBitIndex();

			this.set_string("tech name", "");
			this.Sync("tech name", true);

			this.set_u8("production count", 0);
			this.Sync("production count", true);

			this.set_string("icon file", "");
			this.Sync("icon file", true);

			this.set_u8("icon frame", 0);
			this.Sync("icon frame", true);

			this.set_s8("sign offset", 0);
			this.Sync("sign offset", true);

			this.set_f32("sign scale", 0);
			this.Sync("sign scale", true);

			this.SendCommand(this.getCommandID("pause production"));
		}
	}
	else if (cmd == this.getCommandID("select item"))
	{
		this.getSprite().PlaySound("/ConstructShort.ogg");

		if (this.hasTag("production paused"))
		{
			this.getSprite().PlaySound("/PowerDown.ogg");
		}
		else
		{
			this.getSprite().PlaySound("/PowerUp.ogg");
		}

		if (isServer)
		{
			if (hasTech(this))
			{
				return;
			}

			const string item = params.read_string();
			CBlob@ caller = getBlobByNetworkID(params.read_netid());
			FactoryItem	factory_item = getFactoryItemByName(item);

			if (caller is null || caller.getInventory() is null || factory_item is null)
			{
				return;
			}

			this.set_string("tech name", factory_item.item);
			this.Sync("tech name", true);

			this.set_u8("production count", factory_item.count);
			this.Sync("production count", true);

			this.set_string("icon file", factory_item.file_name);
			this.Sync("icon file", true);

			this.set_u8("icon frame", factory_item.frame);
			this.Sync("icon frame", true);

			this.set_s8("sign offset", factory_item.sign_offset);
			this.Sync("sign offset", true);

			this.set_f32("sign scale", factory_item.sign_scale);
			this.Sync("sign scale", true);

			this.set_s8("sign x", 4 - XORRandom(8));
			this.Sync("sign x", true);

			this.set_s8("sign rotation", 15 - XORRandom(30));
			this.Sync("sign rotation", true);

			server_TakeRequirements(caller.getInventory(), factory_item.requirements);
			this.SendCommand(this.getCommandID("unpause production"));
		}
	}
	else if (cmd == this.getCommandID("pause production"))
	{
		this.Tag("production paused");
		this.getSprite().PlaySound("/PowerDown.ogg");

	}
	else if (cmd == this.getCommandID("unpause production"))
	{
		this.Untag("production paused");
		this.getSprite().PlaySound("/PowerUp.ogg");
	}
	else if (cmd == this.getCommandID("day"))
	{
		if (this.hasTag("production paused"))
		{
			this.getSprite().PlaySound("/PowerDown.ogg");
			return;
		}

		if (!hasTech(this))
		{
			this.getSprite().PlaySound("/PowerDown.ogg");
			return;
		}

		string tech = this.get_string("tech name");
		Vec2f pos = this.getPosition() + this.get_Vec2f("production offset");

		this.getSprite().PlaySound(tech == "mat_bombs" ? "/BombMake.ogg" : "/ProduceSound.ogg");
		makeSmokeParticle(this.getPosition() + Vec2f(0.0f, -this.getRadius() / 2.0f));

		if (getNet().isServer())
		{
			for(u8 i = 0; i < this.get_u8("production count"); i++)
			{
				CBlob@ produce = server_CreateBlob(tech, this.getTeamNum(), pos);
			}
		}
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return false;
}
