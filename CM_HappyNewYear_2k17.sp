#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#tryinclude <shop>

#include <clientmod>
#include <morecolors>

public Plugin:myinfo =
{
	name		= "Happy New Year",
	version		= "2k17.b1_fix",
	description	= "ClientMod Edition",
	author		= "Danyas",
	url			= "http://hlmod.ru/threads/34452/"
}

static const String: sDownloadTable[][] =
{
	"models/models_kit/xmas/xmastree.dx80.vtx",
	"models/models_kit/xmas/xmastree.dx90.vtx",
	"models/models_kit/xmas/xmastree.mdl",
	"models/models_kit/xmas/xmastree.phy",
	"models/models_kit/xmas/xmastree.sw.vtx",
	"models/models_kit/xmas/xmastree.vvd",
	"models/models_kit/xmas/xmastree.xbox.vtx",
	"models/logandougall/cel/cel_xmas_snowman.dx80.vtx",
	"models/logandougall/cel/cel_xmas_snowman.dx90.vtx",
	"models/logandougall/cel/cel_xmas_snowman.mdl",
	"models/logandougall/cel/cel_xmas_snowman.phy",
	"models/logandougall/cel/cel_xmas_snowman.sw.vtx",
	"models/logandougall/cel/cel_xmas_snowman.vvd",
	"materials/models/logandougall/cel/carrot.vtf",
	"materials/models/logandougall/cel/carrot.vmt",
	"materials/models/logandougall/cel/toolsblack.vmt",
	"materials/models/logandougall/cel/bark.vmt",
	"materials/models/logandougall/cel/bark.vtf",
	"materials/models/logandougall/cel/snow.vmt",
	"materials/models/logandougall/cel/snow.vtf",
	"models/models_kit/xmas/xmastree_mini.dx80.vtx",
	"models/models_kit/xmas/xmastree_mini.dx90.vtx",
	"models/models_kit/xmas/xmastree_mini.mdl",
	"models/models_kit/xmas/xmastree_mini.phy",
	"models/models_kit/xmas/xmastree_mini.sw.vtx",
	"models/models_kit/xmas/xmastree_mini.vvd",
	"models/models_kit/xmas/xmastree_mini.xbox.vtx",
	"materials/models/models_kit/xmas/xmastree_miscA.vmt",
	"materials/models/models_kit/xmas/xmastree_miscA.vtf",
	"materials/models/models_kit/xmas/xmastree_miscA_skin2.vmt",
	"materials/models/models_kit/xmas/xmastree_miscA_skin2.vtf",
	"materials/models/models_kit/xmas/xmastree_miscB.vmt",
	"materials/models/models_kit/xmas/xmastree_miscB.vtf",
	"materials/models/models_kit/xmas/xmastree_miscB_skin2.vmt",
	"materials/models/models_kit/xmas/xmastree_miscB_skin2.vtf",
	"materials/models/models_kit/xmas/xmastree_miscB_spec.vtf"
}

char g_sFile[64];

bool isdef[65];

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);

	RegAdminCmd("sm_xmas", XmasMenu, ADMFLAG_ROOT);
	RegAdminCmd("sm_tree",CreateTree, ADMFLAG_ROOT);
	RegAdminCmd("sm_del", DeleteTree, ADMFLAG_ROOT);
	RegAdminCmd("sm_snowman", CreateSnowman, ADMFLAG_ROOT);
	RegAdminCmd("sm_large",	CreateLarge, ADMFLAG_ROOT);
}

public CM_OnClientAuth(client,CMAuthType:type) isdef[client] = type == CM_Auth_Original;


public OnMapStart()
{
	for(int i; i < sizeof(sDownloadTable); i++) AddFileToDownloadsTable(sDownloadTable[i]);

	PrecacheModel("sprites/glow01.spr", true);
	PrecacheModel("models/models_kit/xmas/xmastree_mini.mdl", true);
	PrecacheModel("models/logandougall/cel/cel_xmas_snowman.mdl", true);
	PrecacheModel("models/models_kit/xmas/xmas_teddybear.mdl", true);
	PrecacheModel("models/models_kit/xmas/xmastree.mdl", true);

	char g_sCurrentMap[32];
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));

	if(!DirExists("addons/sourcemod/configs/newyear/")) CreateDirectory("addons/sourcemod/configs/newyear/", 511);
	FormatEx(g_sFile, sizeof(g_sFile), "addons/sourcemod/configs/newyear/%s.cfg", g_sCurrentMap);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Handle:kv = CreateKeyValues("tree");
	if(FileToKeyValues(kv, g_sFile) && KvGotoFirstSubKey(kv))
	{
		char KeyName[50];
		do
		{
			if(KvGetSectionName(kv, KeyName, 50))
			{
				decl Float:g_fOrigin[3], Float:g_fAngles[3], String:type[20];
				KvGetVector(kv, "1", g_fOrigin);
				KvGetVector(kv, "2", g_fAngles);
				KvGetString(kv, "type", type, sizeof(type));
				if(!type[0] || StrEqual(type, "tree"))
				{
					SpawnTree(g_fOrigin, g_fAngles);
					new w_color[4] = { 0, 0, 0, 255 };
					decl String: color[20], Float: Ori[3];
					g_fOrigin[2] += 10;
					for(new i = 1; i<= 10; i++)
					{
						for(new q = 0; q < 3; q++) w_color[q] = GetRandomInt(10, 255);
						for(new a = 0; a < 3; a++) Ori[a] = g_fOrigin[a]

						FormatEx(color, sizeof(color), "%i %i %i", w_color[0], w_color[1], w_color[2]);

						new index = CreateEntityByName("env_sprite");
						DispatchKeyValue(index, "rendermode", "5");
						DispatchKeyValue(index, "rendercolor", color);
						DispatchKeyValue(index, "renderamt", "255");
						DispatchKeyValue(index, "scale", "0.6");
						DispatchKeyValue(index, "model", "sprites/glow01.spr");
						DispatchSpawn(index);
						AcceptEntityInput(index, "ShowSprite");
						float crd;
						switch(i)
						{
							case 1: crd = 27.0;
							case 2: crd = -27.0;
							case 3: crd = 22.0;
							case 4: crd = -22.0;
							case 5: crd = 17.0;
							case 6: crd = -17.0;
							case 7: crd = 12.0;
							case 8: crd = -12.0;
							case 9: crd = 7.0;
							case 10: crd = -7.0;
						}

						Ori[2] += 10*i;
						Ori[0] += crd;
						Ori[1] +=  crd;
						TeleportEntity(index, Ori, g_fAngles, NULL_VECTOR);
					}
				}
				else if(StrEqual(type, "snowman"))	SpawnSnowMan(g_fOrigin, g_fAngles);
				else if(StrEqual(type, "large"))		SpawnLarge(g_fOrigin, g_fAngles);
			}
		}
		while(KvGotoNextKey(kv));
	}

	CloseHandle(kv);
}

public Action:CreateTree(client, args)
{
	CreateSomethink(client, "tree");
	return Plugin_Handled;
}

public Action:CreateLarge(client, args)
{
	CreateSomethink(client, "large");
	return Plugin_Handled;
}

public Action:CreateSnowman(client, args)
{
	CreateSomethink(client, "snowman");
	return Plugin_Handled;
}

public Action XmasMenu(int client, int args)
{
	CreateMainMenu(client);
	return Plugin_Handled;
}

public bool:Trace_FilterPlayers(entity, contentsMask, any:data){
	if(entity != data && entity > MaxClients)
		return true;
	return false;
}

CreateSomethink(client, const String: sType[])
{
	decl Float:g_fOrigin[3], Float:g_fAngles[3];
	GetClientEyePosition(client, g_fOrigin);
	GetClientEyeAngles(client, g_fAngles);

	TR_TraceRayFilter(g_fOrigin, g_fAngles, MASK_SOLID, RayType_Infinite, Trace_FilterPlayers, client);

	if(TR_DidHit(INVALID_HANDLE))
	{
		TR_GetEndPosition(g_fOrigin, INVALID_HANDLE);
		TR_GetPlaneNormal(INVALID_HANDLE, g_fAngles);
		GetVectorAngles(g_fAngles, g_fAngles);
		g_fAngles[0] += 90.0;
		switch(sType[0])
		{
			case 't': SpawnTree(g_fOrigin, g_fAngles);
			case 'l': SpawnLarge(g_fOrigin, g_fAngles);
			case 's': SpawnSnowMan(g_fOrigin, g_fAngles);
		}

		new Handle:kv = CreateKeyValues("tree");
		FileToKeyValues(kv, g_sFile);
		decl String:info[60];
		FormatEx(info, sizeof(info), "%f,%f",g_fOrigin[0], g_fOrigin[1]);
		KvJumpToKey(kv, info, true);
		KvSetVector(kv, "1", g_fOrigin);
		KvSetVector(kv, "2", g_fAngles);
		KvSetString(kv, "type", sType);
		KvRewind(kv);
		KeyValuesToFile(kv, g_sFile);
		CloseHandle(kv);
	}
}

SpawnTree(const Float:g_fOrigin[3], const Float:g_fAngles[3])
{
	new index = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(index, "model", "models/models_kit/xmas/xmastree_mini.mdl");
	DispatchKeyValue(index, "Solid", "6");
	DispatchSpawn(index);
	TeleportEntity(index, g_fOrigin, g_fAngles, NULL_VECTOR);
	SetEntityMoveType(index, MOVETYPE_VPHYSICS);
}

SpawnLarge(const Float:g_fOrigin[3], const Float:g_fAngles[3])
{
	new index = CreateEntityByName("prop_dynamic_override");
	if(index == -1) return;
	DispatchKeyValue(index, "model", "models/models_kit/xmas/xmastree.mdl");
	DispatchKeyValue(index, "Solid", "6");
	DispatchSpawn(index);
	TeleportEntity(index, g_fOrigin, g_fAngles, NULL_VECTOR);
	SetEntityMoveType(index, MOVETYPE_VPHYSICS);
}

SpawnSnowMan(const Float:g_fOrigin[3], const Float:g_fAngles[3])
{
	new index = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(index, "model", "models/logandougall/cel/cel_xmas_snowman.mdl");
	DispatchKeyValue(index, "Solid", "6");
	DispatchSpawn(index);
	TeleportEntity(index, g_fOrigin, g_fAngles, NULL_VECTOR);
	SetEntityMoveType(index, MOVETYPE_VPHYSICS);
}

public Action:DeleteTree(client, args)
{
	int index = GetClientAimTarget(client, false);
	if(index  == -1)	return Plugin_Handled;

	decl Float:vec[3]; decl String:coord[15]; decl String:coord1[15], String:buf3[2][25], String:buf4[2][25];
	GetEntPropVector(index, Prop_Data, "m_vecAbsOrigin", vec);
	FloatToString(vec[0], coord, sizeof(coord));
	FloatToString(vec[1], coord1, sizeof(coord1));
	ExplodeString(coord, ".", buf3, 2, 25);
	ExplodeString(coord1, ".", buf4, 2, 25);

	new Handle:kv = CreateKeyValues("tree");
	if(FileToKeyValues(kv, g_sFile) && KvGotoFirstSubKey(kv))
	{
		decl String:KeyName[35];
		do
		{
			if(KvGetSectionName(kv, KeyName, 35))
			{
				char buf[2][25], buf1[2][25], buf2[2][25];

				ExplodeString(String:KeyName, ",", String:buf, 2, 25);
				ExplodeString(String:buf[0], ".", String:buf1, 2, 25);
				ExplodeString(String:buf[1], ".", String:buf2, 2, 25);
				if(StrEqual(buf1[0], buf3[0]) && StrEqual(buf2[0], buf4[0]))
				{
					RemoveEntity(index);
					KvDeleteThis(kv);
					KvRewind(kv);
					KeyValuesToFile(kv, g_sFile);
				}
			}
		}
		while(KvGotoNextKey(kv));

	}
	CloseHandle(kv);
	return Plugin_Handled;
}

public Action:Go(Handle:timer, any:val)
{
	if(IsValidEntity(val)) RemoveEntity(val);
}

void CreateMainMenu(int client)
{
	Menu menu = new Menu(Menu_Handler);

	menu.SetTitle("Main menu");

	menu.AddItem("tree", "Tree");
	menu.AddItem("largetree", "Large Tree");
	menu.AddItem("snowman", "SnowMan");

	menu.ExitButton = true;

	menu.Display(client, 30);
}

void CreateTreeMenu(int client)
{
	Menu menu2 = new Menu(Menu_Handler1);

	menu2.SetTitle("Trees");

	menu2.AddItem("create", "Create Tree");
	menu2.AddItem("delete", "Delete Tree");

	menu2.ExitBackButton = true;

	menu2.Display(client, 30);	
}

void CreateLargeTreeMenu(int client)
{
	Menu menu3 = new Menu(Menu_Handler2);

	menu3.SetTitle("Large Trees");

	menu3.AddItem("create", "Create Large Tree");
	menu3.AddItem("delete", "Delete Large Tree");

	menu3.ExitBackButton = true;

	menu3.Display(client, 30);
}

void CreateSnowManMenu(int client)
{
	Menu menu4 = new Menu(Menu_Handler3);

	menu4.SetTitle("Snow Men");

	menu4.AddItem("create", "Create SnowMen");
	menu4.AddItem("delete", "Delete SnowMen");

	menu4.ExitBackButton = true;

	menu4.Display(client, 30);
}

public int Menu_Handler(Menu menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
	{
		char item[32];
		menu.GetItem(param2, item, sizeof(item));

		if(StrEqual(item, "tree")) CreateTreeMenu(client);	
		else if(StrEqual(item, "largetree")) CreateLargeTreeMenu(client);
		else if(StrEqual(item, "snowman")) CreateSnowManMenu(client);
	}
	else if(action == MenuAction_End) delete menu;
}

public int Menu_Handler1(Menu menu2, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
	{
		char item[32];
		menu2.GetItem(param2, item, sizeof(item));

		if(StrEqual(item, "create")) CreateTree(client, 0);
		else if(StrEqual(item, "delete")) DeleteTree(client, 0);
		CreateTreeMenu(client);
	}
	else if(action == MenuAction_End) delete menu2;
}

public int Menu_Handler2(Menu menu3, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
	{
		char item[32];
		menu3.GetItem(param2, item, sizeof(item));

		if(StrEqual(item, "create")) CreateLarge(client, 0);
		else if(StrEqual(item, "delete")) DeleteTree(client, 0)

		CreateLargeTreeMenu(client);
	}
	else if(action == MenuAction_End) delete menu3;
}

public int Menu_Handler3(Menu menu4, MenuAction action, int client, int param2)
{
	if(action == MenuAction_Select)
	{
		char item[32];
		menu4.GetItem(param2, item, sizeof(item));

		if(StrEqual(item, "create")) CreateSnowman(client, 0);
		else if(StrEqual(item, "delete")) DeleteTree(client, 0);

		CreateSnowManMenu(client);
	}
	else if(action == MenuAction_End) delete menu4;
}