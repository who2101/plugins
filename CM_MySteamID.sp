#include <sourcemod>

#include <clientmod>
#include <morecolors>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[ClientMod] My SteamID",
	author = "[HvG] Shitler",
	description = "Покажет в чате игроку его SteamID и IP при вводе команды",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/groups/HighVoltageServers"
};

bool isdef[65];

public void OnPluginStart()
{	
  RegConsoleCmd("sm_steamid", steam, "STEAM ID True Chat!");
  RegConsoleCmd("sm_steam", steam, "STEAM ID True Chat!");
}

public void CM_OnClientAuth(int iClient,CMAuthType:type)
{
	isdef[iClient] = type == CM_Auth_Original;
}

public Action steam(client,args)
{
    char steamid[21];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

    if(isdef[client]) PrintToChat(client, "[Сервер] %N your steamid is %s", client, steamid);
    else CPrintToChat(client, "[Сервер] %N your steamid is %s", client, steamid);

 . .return Plugin_Handled
}
