
void LoadDefaultMapLoaders()
{
	printf("############ GAMEMODE " + sv_gamemode);

	RegisterFileExtensionScript("Scripts/MapLoaders/GenerateZombieMap.as", "kaggen.cfg");
}
