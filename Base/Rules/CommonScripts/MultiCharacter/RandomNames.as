
const string FORENAME = "forename";
const string SURNAME = "surname";

void getRandomName(CBlob@ this)
{
	Random@ random = Random(this.getNetworkID());
	string[]@ forenames = this.getSexNum() == 0 ? male_forenames : female_forenames;
	this.set_string(FORENAME, forenames[random.NextRanged(forenames.length)]);
	this.set_string(SURNAME, surnames[random.NextRanged(surnames.length)]);
}

string[] male_forenames = {
	"Lydan",
	"Syrin",
	"Ptorik",
	"Joz",
	"Varog",
	"Gethrod",
	"Hezra",
	"Feron",
	"Ophni",
	"Colborn",
	"Fintis",
	"Gatlin",
	"Jinto",
	"Hagalbar",
	"Krinn",
	"Lenox",
	"Revvyn",
	"Hodus",
	"Dimian",
	"Paskel",
	"Kontas",
	"Weston",
	"Azamarr",
	"Jather",
	"Tekren",
	"Jareth",
	"Adon",
	"Zaden",
	"Eune",
	"Graff",
	"Tez",
	"Jessop",
	"Gunnar",
	"Pike",
	"Domnhar",
	"Baske",
	"Jerrick",
	"Mavrek",
	"Riordan",
	"Wulfe",
	"Straus",
	"Tyvrik",
	"Henndar",
	"Favroe",
	"Whit",
	"Jaris",
	"Renham",
	"Kagran",
	"Lassrin",
	"Vadim",
	"Arlo",
	"Quintis",
	"Vale",
	"Caelan",
	"Yorjan",
	"Khron",
	"Ishmael",
	"Jakrin",
	"Fangar",
	"Roux",
	"Baxar",
	"Hawke",
	"Gatlen",
	"Barak",
	"Nazim",
	"Kadric",
	"Paquin",
	"Kent",
	"Moki",
	"Rankar",
	"Lothe",
	"Ryven",
	"Clawsen",
	"Pakker",
	"Embre",
	"Cassian",
	"Verssek",
	"Dagfinn",
	"Ebraheim",
	"Nesso",
	"Eldermar",
	"Rivik",
	"Rourke",
	"Barton",
	"Hemm",
	"Sarkin",
	"Blaiz",
	"Talon",
	"Agro",
	"Zagaroth",
	"Turrek",
	"Esdel",
	"Lustros",
	"Zenner",
	"Baashar",
	"Dagrod",
	"Gentar",
	"Festo"
};

string[] female_forenames = {
	"Syrana",
	"Resha",
	"Varin",
	"Wren",
	"Yuni",
	"Talis",
	"Kessa",
	"Magaltie",
	"Aeris",
	"Desmina",
	"Krynna",
	"Asralyn",
	"Herra",
	"Pret",
	"Kory",
	"Afia",
	"Tessel",
	"Rhiannon",
	"Zara",
	"Jesi",
	"Belen",
	"Rei",
	"Ciscra",
	"Temy",
	"Renalee",
	"Estyn",
	"Maarika",
	"Lynorr",
	"Tiv",
	"Annihya",
	"Semet",
	"Tamrin",
	"Antia",
	"Reslyn",
	"Basak",
	"Vixra",
	"Pekka",
	"Xavia",
	"Beatha",
	"Yarri",
	"Liris",
	"Sonali",
	"Razra",
	"Soko",
	"Maeve",
	"Everen",
	"Yelina",
	"Morwena",
	"Hagar",
	"Palra",
	"Elysa",
	"Sage",
	"Ketra",
	"Lynx",
	"Agama",
	"Thesra",
	"Tezani",
	"Ralia",
	"Esmee",
	"Heron",
	"Naima",
	"Rydna",
	"Sparrow",
	"Baakshi",
	"Ibera",
	"Phlox",
	"Dessa",
	"Braithe",
	"Taewen",
	"Larke",
	"Silene",
	"Phressa",
	"Esther",
	"Anika",
	"Rasy",
	"Harper",
	"Indie",
	"Vita",
	"Drusila",
	"Minha",
	"Surane",
	"Lassona",
	"Merula",
	"Kye",
	"Jonna",
	"Lyla",
	"Zet",
	"Orett",
	"Naphtalia",
	"Turi",
	"Rhays",
	"Shike",
	"Hartie",
	"Beela",
	"Leska",
	"Vemery",
	"Lunex",
	"Fidess",
	"Tisette",
	"Parth"
};

string[] surnames = {
	"Commonseeker",
	"Roughwhirl",
	"Laughingsnout",
	"Orbstrike",
	"Ambersnarl",
	"Crowstrike",
	"Runebraid",
	"Stillblade",
	"Hallowedsorrow",
	"Mildbreath",
	"Fogforge",
	"Albilon",
	"Ginerisey",
	"Brichazac",
	"Lomadieu",
	"Bellevé",
	"Dudras",
	"Chanassard",
	"Ronchessac",
	"Chamillet",
	"Bougaitelet",
	"Hallowswift",
	"Sacredpelt",
	"Rapidclaw",
	"Hazerider",
	"Shadegrove",
	"Coldsprinter",
	"Winddane",
	"Ashsorrow",
	"Humblecut",
	"Ashbluff",
	"Marblemaw",
	"Boneflare",
	"Monsterbelly",
	"Truthbelly",
	"Sacredmore",
	"Dawnless",
	"Crestbreeze",
	"Neredras",
	"Dumières",
	"Albimbert",
	"Cremeur",
	"Brichallard",
	"Béchalot",
	"Chabares",
	"Chauveron",
	"Rocheveron",
	"Vernize",
	"Brightdoom",
	"Clanwillow",
	"Wheatglow",
	"Terrarock",
	"Laughingroar",
	"Silverweaver",
	"Clearpunch",
	"Shieldtrap",
	"Foreswift",
	"Softgloom",
	"Treelash",
	"Grandsplitter",
	"Marblewing",
	"Sharpdoom",
	"Terraspear",
	"Rambumoux",
	"Lauregnory",
	"Chanalet",
	"Broffet",
	"Cardaithier",
	"Chauvelet",
	"Astaseul",
	"Bizeveron",
	"Vernillard",
	"Croirral",
	"Wildforce",
	"Frozenscribe",
	"Warbelly",
	"Mournrock",
	"Smartreaper",
	"Sagepunch",
	"Solidcut",
	"Peacescream",
	"Slateflayer",
	"Mistblood",
	"Winterwound",
	"Spiritscribe",
	"Irongrip",
	"Plaingrove",
	"Keenstone",
	"Proudswift",
	"Marshrider",
	"Nicklegrain",
	"Masterfang",
	"Springbender",
	"Paleforce",
	"Strongblaze",
	"Silentbrace",
	"Dreamreaver",
	"Firecrusher",
	"Stoutspirit",
	"Whitemoon",
	"Leafslayer",
	"Frozenreaper",
	"Tarrencloud",
	"Misteyes",
	"Échethier",
	"Vassezac",
	"Albinie",
	"Ginemoux",
	"Angegnac",
	"Gaimbert",
	"Lignichanteau",
	"Castemont",
	"Vegné",
	"Bobeffet",
	"Mildstrike",
	"Deepgrain",
	"Nicklewhisk",
	"Mourningsnow",
	"Cragore",
	"Terrawater",
	"Redshadow",
	"Roserun",
	"Hallowshadow",
	"Fernfang",
	"Cinderbreaker",
	"Nobledane",
	"Dustseeker",
	"Coldblight",
	"Skyfire",
	"Mistbinder",
	"Oattaker",
	"Embershadow",
	"Mountainbane",
	"Shieldgem",
	"Elfscribe",
	"Orbarrow",
	"Bluebleeder",
	"Amberflayer",
	"Lonerider",
	"Steelpike",
	"Hellbough",
	"Longshard",
	"Treeshaper",
	"Noblestrike",
	"Leafwater",
	"Wisekeep",
	"Rosewhisper",
	"Humblebringer",
	"Flameforge",
	"Belemont",
	"Pellelles",
	"Suvau",
	"Bobellon",
	"Jouvempes",
	"Montalli",
	"Bougaimoux",
	"Bonnenie",
	"Massoumbert",
	"Lignignon",
	"Featherswallow",
	"Coldcloud",
	"Ironcut",
	"Nightwind",
	"Warmane",
	"Meadowbrace",
	"Flatwatcher",
	"Swiftbrew",
	"Wisekiller",
	"Lightscream",
	"Wyvernseeker",
	"Cliffless",
	"Serpentbrook",
	"Skysnow",
	"Sternshine",
	"Sharpblade",
	"Voidbend",
	"Oceancut",
	"Hydrabreath",
	"Pridesong",
	"Warmight",
	"Whispercrest",
	"Distantwind",
	"Wildwhirl",
	"Fourswallow",
	"Skyhunter",
	"Terramaul",
	"Saurmaw",
	"Forebluff",
	"Skyshade",
	"Stormorb",
	"Mirthmantle",
	"Rosedreamer",
	"Shadowflaw",
	"Smartlash",
	"Gloryweaver",
	"Cinderhell",
	"Distantfury",
	"Oatshine",
	"Leafdream",
	"Whitwatcher",
	"Wolfgrain",
	"Wheatbrow",
	"Roughdust",
	"Hardshout",
	"Dewbringer",
	"Regalhelm",
	"Havenglow",
	"Proudfollower",
	"Mournmoon",
	"Pellerelli",
	"Rochelieu",
	"Chauvempes",
	"Macherac",
	"Maignes",
	"Credieu",
	"Andilet",
	"Massouchanteau",
	"Alinac",
	"Lamogre",
	"Hazekeep",
	"Havendoom",
	"Fourspire",
	"Warbreaker",
	"Gorelight",
	"Woodlight",
	"Elffire",
	"Richshout",
	"Regalshade",
	"Keenfollower",
	"Voidreaper",
	"Fallenorb",
	"Honorhorn",
	"Pridewood",
	"Flameshaper",
	"Amberflaw",
	"Marblewhisper",
	"Boulderward",
	"Tarrenseeker",
	"Twoaxe",
	"Duskbloom",
	"Voidlash",
	"Proudchaser",
	"Hallowedchaser",
	"Suteuil",
	"Roqueze",
	"Macherral",
	"Astaril",
	"Cretillon",
	"Larmalart",
	"Ronchelieu",
	"Abordieu",
	"Cardaimtal",
	"Croillard",
	"Springspell",
	"Woodflower",
	"Mirthhorn",
	"Sagesun",
	"Clawroot",
	"Oatcrag",
	"Blackmark",
	"Grasshammer",
	"Fallenwinds",
	"Humblereaper",
	"Orbtrap",
	"Havenash",
	"Elfwind",
	"Autumnbow",
	"Youngvigor",
	"Titantoe",
	"Rapidroot",
	"Amberhide",
	"Moltentide",
	"Noblesprinter",
	"Barleyjumper",
	"Mirthcleaver",
	"Elfbreath",
	"Featherdreamer",
	"Masterjumper",
	"Duskstalker",
	"Dulles",
	"Andigre",
	"Mévouitré",
	"Ronchegnac",
	"Montanne",
	"Rochegné",
	"Larmallevé",
	"Vernifelon",
	"Rambugnon",
	"Virac",
	"Moltenore",
	"Oceantoe",
	"Flatstrider",
	"Gloryrock",
	"Sternguard",
	"Frozendreamer",
	"Angebannes",
	"Gaillot",
	"Lamanie",
	"Pouinac",
	"Lamagnon",
	"Abonton",
	"Abilles",
	"Sufelon",
	"Larmanton",
	"Cardairel",
	"Icehand",
	"Stonebender",
	"Snowscar",
	"Deepwing",
	"Nobledrifter",
	"Crystalbone",
	"Featherbrew",
	"Clanwing",
	"Amberore",
	"Thundermourn",
	"Marbletail",
	"Tusksnarl",
	"Steelrunner",
	"Oceanseeker",
	"Rainward",
	"Mourningscribe",
	"Dragoncutter",
	"Hardarm",
	"Maignes",
	"Jouvessac",
	"Larmagnory",
	"Chabaffet",
	"Abiril",
	"Albizac",
	"Machenet",
	"Bronie",
	"Baratillon",
	"Limochanteau",
	"Montarac",
	"Mailon",
	"Verninne",
	"Massoullevé",
	"Gairil",
	"Lamadras",
	"Gaignory",
	"Sarramond",
	"Castedras",
	"Roquenet",
	"Rumbleash",
	"Deepwoods",
	"Covenbreath",
	"Cliffdane",
	"Spiritglade",
	"Clawarm",
	"Roughforest",
	"Nethersteel",
	"Nicklebrow",
	"Pyrefollower",
	"Evenbash",
	"Flatrider",
	"Amberwhirl",
	"Saurflower",
	"Ironcrag",
	"Rockcleaver",
	"Hammerpeak",
	"Woodslayer",
	"Clanwatcher",
	"Spiritshade",
	"Aboges",
	"Vassellon",
	"Kergagné",
	"Sutillon",
	"Angere",
	"Maillon",
	"Rambutré",
	"Lamachade",
	"Bizegnac",
	"Sauzin",
	"Maiveron",
	"Larmare",
	"Ronchefort",
	"Bougailet",
	"Lamazac",
	"Chanagny",
	"Rocheze",
	"Saintirral",
	"Raurisey",
	"Abobannes",
	"Thundershade",
	"Honorchaser",
	"Earthsorrow",
	"Stonesinger",
	"Tworeaver",
	"Greatflare",
	"Keenbrooke",
	"Rambumoux",
	"Sutillon",
	"Albelles",
	"Roffinie",
	"Roffivilliers",
	"Jouvelot",
	"Bromoux",
	"Ravilart",
	"Béchalenet",
	"Saintizin",
	"Threecaller",
	"Lightningcaller",
	"Duranton",
	"Cremond",
	"Lomameur",
	"Abissac",
	"Vellard",
	"Pezin",
	"Chavameur",
	"Jouveffet",
	"Roquethier",
	"Échellane",
	"Sacredward",
	"Tuskhunter",
	"Redbrace",
	"Stonechaser",
	"Lowlight",
	"Shadowsteam",
	"Pinebrew",
	"Forebreeze",
	"Burningshard",
	"Blackspear",
	"Threesnarl",
	"Fallengloom",
	"Vernivau",
	"Roquellevé",
	"Bizegnac",
	"Châtithier",
	"Montanie",
	"Brognac",
	"Albeleilles",
	"Rare",
	"Peteuil",
	"Nereffet",
	"Autumnspell",
	"Tallfist",
	"Covenhunter",
	"Grassless",
	"Duskseeker",
	"Fourshot",
	"Warripper",
	"Phoenixglade",
	"Amberdew",
	"Serpentsoar",
	"Pyrebrace",
	"Truthspark",
	"Winterspire",
	"Evensteel",
	"Alpensorrow",
	"Dustspire",
	"Raventrapper",
	"Flamebrooke",
	"Ironbelly",
	"Serpentgazer",
	"Dragonhelm",
	"Wolftide",
	"Snowhell",
	"Sauvau",
	"Barassard",
	"Nossec",
	"Polassard",
	"Lignifelon",
	"Alillon",
	"Gaivès",
	"Caffamoux",
	"Cardailenet",
	"Montalot",
	"Ragesworn",
	"Skydancer",
	"Ironbender",
	"Wildbrook",
	"Mourningsteel",
	"Stagmane",
	"Gloryforge",
	"Titanwater",
	"Softeyes",
	"Hammersky",
	"Hellflame",
	"Ravenfury",
	"Goredane",
	"Alibannes",
	"Abaril",
	"Neredras",
	"Béchaveron",
	"Machelenet",
	"Lamathier",
	"Larmasseau",
	"Caffallane",
	"Laurenas",
	"Nereffet",
	"Woodenglory",
	"Lowbringer",
	"Saurbrooke",
	"Battlestrength",
	"Willowwoods",
	"Axedust",
	"Ashstalker",
	"Swiftsteel",
	"Ravensinger",
	"Goreflowe"
};