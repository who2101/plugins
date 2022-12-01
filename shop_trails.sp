#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shop>
#include <entity>

#undef REQUIRE_PLUGIN
#include <clientprefs>
#tryinclude <ToggleEffects>

#define PLUGIN_VERSION "2.2.2"
#define CATEGORY "trails"

bool g_bShouldSee[MAXPLAYERS + 1] = true, toggleEffects = false;
int iTeam[MAXPLAYERS+1], g_SpriteModel[MAXPLAYERS + 1] = {-1, ...};

Handle g_hCookie;
KeyValues hKvTrails;
ItemId selected_id[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "[Shop] Trails",
	author = "FrozDark (HLModders LLC)",
	description = "Trails that folows a player",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru/"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath);
	HookEvent("player_team", PlayerTeam);
	HookEvent("round_start", OnRoundStart);
	
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			iTeam[i] = GetClientTeam(i);
	
	RegAdminCmd("sm_trails_reload", Command_TrailsReload, ADMFLAG_ROOT, "Reloads trails config list");
	
	if (Shop_IsStarted()) Shop_Started();
	
	g_hCookie = RegClientCookie("sm_shop_trails", "1 - enabled, 0 - disabled", CookieAccess_Private);
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
	for (new i = 1; i <= MaxClients; i++) KillTrail(i);
}

public void OnAllPluginsLoaded()
{
	toggleEffects = LibraryExists("specialfx");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "specialfx")) toggleEffects = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "specialfx")) toggleEffects = false;
}

public void OnClientCookiesCached(int client)
{
	g_bShouldSee[client] = GetCookieBool(client, g_hCookie);
}

bool GetCookieBool(int iClient, Handle hCookie)
{
	char sBuffer[4];
	GetClientCookie(iClient, hCookie, sBuffer, 4);
	return (StringToInt(sBuffer) == 0 && sBuffer[0] != 0) ? false:true;
}

public void OnClientDisconnect(int client)
{
	SetCookieBool(client, g_hCookie, g_bShouldSee[client]);
	g_bShouldSee[client] = true;
	KillTrail(client);
}

void SetCookieBool(int iClient, Handle hCookie, bool bValue)
{
	if ( bValue ) SetClientCookie(iClient, hCookie, "1");
	else SetClientCookie(iClient, hCookie, "0");
}

public void OnMapStart()
{
	LoadKeyStructure();
	ReadDownloadsFile();
	ReadKvFile();
}

void ReadDownloadsFile()
{
	char FilePath[PLATFORM_MAX_PATH];
	char Line[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, FilePath, sizeof(FilePath), "configs/shop/trails_dlist.txt");
	Handle file = OpenFile(FilePath, "r");

	while(!IsEndOfFile(file) && ReadFileLine(file, Line, sizeof(Line)))
	{
		TrimString(Line);
		AddFileToDownloadsTable(Line);
	}

	delete file;
}

void ReadKvFile()
{
	char FilePath[PLATFORM_MAX_PATH], MaterialPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, FilePath, sizeof(FilePath), "configs/shop/trails.txt");
	KeyValues Kv = new KeyValues("Trails");
	Kv.ImportFromFile(FilePath);
	Kv.GotoFirstSubKey();
	do
	{
		Kv.GetString("material", MaterialPath, sizeof(MaterialPath));
		PrecacheModel(MaterialPath);
	}
	while(Kv.GotoNextKey());
	delete Kv;
}

void LoadKeyStructure()
{
	if (hKvTrails == INVALID_HANDLE)
	{
		hKvTrails = new KeyValues("Trails");
		
		char _buffer[PLATFORM_MAX_PATH];
		Shop_GetCfgFile(_buffer, sizeof(_buffer), "trails.txt");
		
		if (!FileToKeyValues(hKvTrails, _buffer)) SetFailState("\"%s\" not found", _buffer);
		
		KvRewind(hKvTrails);
	}
}

public void Shop_Started()
{
	LoadKeyStructure();
	
	char name[64], description[64];
	KvGetString(hKvTrails, "name", name, sizeof(name), "Trails");
	KvGetString(hKvTrails, "description", description, sizeof(description));
	
	CategoryId category_id = Shop_RegisterCategory(CATEGORY, name, description);
	
	char item[64], item_name[64], item_description[64], buffer[PLATFORM_MAX_PATH];
	KvRewind(hKvTrails);
	if (KvGotoFirstSubKey(hKvTrails))
	{
		do
		{
			KvGetString(hKvTrails, "material", buffer, sizeof(buffer));
			if (!File_ExtEqual(buffer, "vmt")) continue;
			
			KvGetSectionName(hKvTrails, item, sizeof(item));
			
			if (Shop_StartItem(category_id, item))
			{
				KvGetString(hKvTrails, "name", item_name, sizeof(item_name), item);
				KvGetString(hKvTrails, "description", item_description, sizeof(item_description));
				Shop_SetInfo(item_name, item_description, KvGetNum(hKvTrails, "price", 500), KvGetNum(hKvTrails, "sell_price", -1), Item_Togglable, KvGetNum(hKvTrails, "duration", 86400));
				Shop_SetCallbacks(OnItemRegistered, OnEquipItem);
				
				if (KvJumpToKey(hKvTrails, "Attributes", false))
				{
					Shop_KvCopySubKeysCustomInfo(view_as<KeyValues>(hKvTrails));
					KvGoBack(hKvTrails);
				}
				
				Shop_EndItem();
			}
		}
		while (KvGotoNextKey(hKvTrails));
		
		KvRewind(hKvTrails);
	}
	
	Shop_AddToFunctionsMenu(FuncToggleVisibilityDisplay, FuncToggleVisibility);
}

public void FuncToggleVisibilityDisplay(int client, char[] buffer, int maxlength)
{
	Format(buffer, maxlength, "Трейлы: %s", g_bShouldSee[client] ? "Видны" : "Скрыты");
}

public bool FuncToggleVisibility(int client)
{
	g_bShouldSee[client] = !g_bShouldSee[client];

	return false;
}

public void OnItemRegistered(CategoryId category_id, const char[] category, const char[] item, ItemId item_id)
{
	if (KvJumpToKey(hKvTrails, item))
	{
		KvSetNum(hKvTrails, "id", _:item_id);
		KvRewind(hKvTrails);
	}
}

public Action Command_TrailsReload(int client, int args)
{
	if (hKvTrails != INVALID_HANDLE) CloseHandle(hKvTrails);
	
	OnPluginEnd();
	Shop_Started();
	
	ReplyToCommand(client, "Trails config list reloaded successfully!");
	
	return Plugin_Handled;
}

public ShopAction OnEquipItem(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed)
{
	if (isOn || elapsed)
	{
		OnClientDisconnect(client);
		
		selected_id[client] = INVALID_ITEM;
		
		return Shop_UseOff;
	}
	
	Shop_ToggleClientCategoryOff(client, category_id);
	
	selected_id[client] = item_id;
	
	SpriteTrail(client);
	
	return Shop_UseOn;
}

public void OnMapEnd()
{
	for(int client = 1; client <= MAXPLAYERS; client++) g_SpriteModel[client] = -1;
}

public void OnClientDisconnect_Post(int client)
{
	iTeam[client] = 0;
	selected_id[client] = INVALID_ITEM;
	g_SpriteModel[client] = -1;
}

public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, GiveTrail, GetEventInt(event, "userid"));
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_bShouldSee[client] == true) return;

	FuncToggleVisibility(client);		
}

public Action PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	iTeam[client] = GetEventInt(event, "team");

	if(iTeam[client] == 1) FuncToggleVisibility(client);
}

public Action PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	KillTrail(client);
}

public Action GiveTrail(Handle timer, any userid)
{
	SpriteTrail(GetClientOfUserId(userid));
}

bool SpriteTrail(int client)
{
	if (!client) return false;

	KillTrail(client);
	
	if (selected_id[client] == INVALID_ITEM || iTeam[client] == 0 || IsFakeClient(client)) return false;

	if (!IsPlayerAlive(client) || !(1 < iTeam[client] < 4)) return true;
	
	char item[SHOP_MAX_STRING_LENGTH];
	item[0] = '\0';
	Shop_GetItemById(selected_id[client], item, sizeof(item));
	
	if (!item[0] || !KvJumpToKey(hKvTrails, item))
	{
		PrintToServer("Item %s is not exists");
		return false;
	}
	
	g_SpriteModel[client] = CreateEntityByName("env_spritetrail");
	if (g_SpriteModel[client] != -1) 
	{
		char buffer[PLATFORM_MAX_PATH];
		float dest_vector[3];
		
		DispatchKeyValueFloat(g_SpriteModel[client], "lifetime", KvGetFloat(hKvTrails, "lifetime", 1.0));
		
		KvGetString(hKvTrails, "startwidth", buffer, sizeof(buffer), "10");
		DispatchKeyValue(g_SpriteModel[client], "startwidth", buffer);
		
		KvGetString(hKvTrails, "endwidth", buffer, sizeof(buffer), "6");
		DispatchKeyValue(g_SpriteModel[client], "endwidth", buffer);
		
		KvGetString(hKvTrails, "material", buffer, sizeof(buffer));
		DispatchKeyValue(g_SpriteModel[client], "spritename", buffer);
		DispatchKeyValue(g_SpriteModel[client], "renderamt", "255");
		
		KvGetString(hKvTrails, "color", buffer, sizeof(buffer));
		DispatchKeyValue(g_SpriteModel[client], "rendercolor", buffer);
		
		IntToString(KvGetNum(hKvTrails, "rendermode", 1), buffer, sizeof(buffer));
		DispatchKeyValue(g_SpriteModel[client], "rendermode", buffer);
		
		DispatchSpawn(g_SpriteModel[client]);
		
		KvGetVector(hKvTrails, "position", dest_vector);
		
		float or[3], ang[3], fForward[3], fRight[3], fUp[3];
		
		GetClientAbsOrigin(client, or);
		GetClientAbsAngles(client, ang);
		
		GetAngleVectors(ang, fForward, fRight, fUp);

		or[0] += fRight[0]*dest_vector[0] + fForward[0]*dest_vector[1] + fUp[0]*dest_vector[2];
		or[1] += fRight[1]*dest_vector[0] + fForward[1]*dest_vector[1] + fUp[1]*dest_vector[2];
		or[2] += fRight[2]*dest_vector[0] + fForward[2]*dest_vector[1] + fUp[2]*dest_vector[2];
		
		TeleportEntity(g_SpriteModel[client], or, NULL_VECTOR, NULL_VECTOR);
		
		SetVariantString("!activator");
		AcceptEntityInput(g_SpriteModel[client], "SetParent", client); 
		SetEntPropFloat(g_SpriteModel[client], Prop_Send, "m_flTextureRes", 0.05);
		SetEntPropEnt(g_SpriteModel[client], Prop_Send, "m_hOwnerEntity", client);
		
		SDKHook(g_SpriteModel[client], SDKHook_SetTransmit, Hook_TrailShouldHide);
	}
	KvRewind(hKvTrails);
	
	return true;
}

public Action Hook_TrailShouldHide(int entity, int client)
{
#if defined _GlobalEffects_Included_
	if (toggleEffects && !ShowClientEffects(client)) return Plugin_Handled;
#endif

	if (!g_bShouldSee[client]) return Plugin_Handled;
	
	if (g_SpriteModel[client] == entity || iTeam[client] < 2) return Plugin_Continue;

	return Plugin_Continue;
}

void KillTrail(int client)
{
	if (g_SpriteModel[client] > MaxClients && IsValidEdict(g_SpriteModel[client])) RemoveEntity(g_SpriteModel[client]);
	
	g_SpriteModel[client] = -1;
}

stock void File_GetExtension(const char[] path, char[] buffer, int size)
{
	int extpos = FindCharInString(path, '.', true);
	
	if (extpos == -1)
	{
		buffer[0] = '\0';
		return;
	}

	strcopy(buffer, size, path[++extpos]);
}

stock bool File_ExtEqual(const char[] path, const char[] ext, bool caseSensetive = false)
{
	char buf[4];
	File_GetExtension(path, buf, sizeof(buf));
	return StrEqual(buf, ext, caseSensetive);
}