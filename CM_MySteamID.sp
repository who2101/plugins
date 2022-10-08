#include <sourcemod>

#include <clientmod>
#include <morecolors>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "[ClientMod] My SteamID",
	author = "[HvG] Shitler",
	description = "Покажет в чате игроку его SteamID и IP при вводе команды",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/groups/HighVoltageServers"
};

new bool:isdef[65];

public void OnPluginStart()
{	
	RegConsoleCmd("sm_steamid", steam, "STEAM ID True Chat!");
	RegConsoleCmd("sm_steam", steam, "STEAM ID True Chat!");
	RegConsoleCmd("sm_ip", steam, "STEAM ID True Chat!");
}

public void CM_OnClientAuth(iClient,CMAuthType:type)
{
	isdef[iClient] = type == CM_Auth_Original;
}

public Action:steam(client,args)
{
	if (args < 1)
	{
		char steamid[21];
		char name[32];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)); // Получение стим айди
		GetClientName(client, name, sizeof(name));

		if(isdef[client]) // ClientMod
			PrintToChat(client, "[Сервер] %N your steamid is %s", name, steamid);
		else // Default CS:S
			CPrintToChat(client, "[Сервер] %N your steamid is %s", name, steamid);
	}
	return Plugin_Handled
}