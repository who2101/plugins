#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME 	"Radar Config"
#define PLUGIN_VERSION 	"1.1.0"

Handle g_hRadarConfig = INVALID_HANDLE;

int g_iPlayerSpotted = -1, g_iBombSpotted = -1, g_iPlayerManager = -1, g_iFlashAlpha = -1, g_iFlashDuration;
bool g_bRadarHooked, g_bFlashHooked;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony",
	description = "Hide or Show all players on the radar",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	/* Find offsets used for the radar and flashbangs. */
	if ((g_iPlayerSpotted = FindSendPropInfo("CCSPlayerResource", "m_bPlayerSpotted")) == -1)
		SetFailState("Failed to find CCSPlayerResource::m_bPlayerSpotted offset");

	if ((g_iBombSpotted = FindSendPropInfo("CCSPlayerResource", "m_bBombSpotted")) == -1)
		SetFailState("Failed to find CCSPlayerResource::m_bBombSpotted offset");
	
	if ((g_iFlashDuration = FindSendPropInfo("CCSPlayer", "m_flFlashDuration")) == -1)
		SetFailState("Failed to find find CCSPlayer::m_flFlashDuration offset");
	
	if ((g_iFlashAlpha = FindSendPropInfo("CCSPlayer", "m_flFlashMaxAlpha")) == -1)
		SetFailState("Failed to find CCSPlayer::m_flFlashMaxAlpha offset");
	
	/* Now we can continue. */
	CreateConVar("sm_radarconfig_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hRadarConfig = CreateConVar("sm_radarconfig", "0", "Determines radar functionality. (0 = Default behaviour, 1 = Disable radar, 2 = Show all players)", FCVAR_NONE, true, 0.0, true, 2.0);
	
	OnRadarModeChange(g_hRadarConfig, "", "");
	HookConVarChange(g_hRadarConfig, OnRadarModeChange);
}

public void OnMapStart()
{
	g_iPlayerManager = FindEntityByClassname(0, "cs_player_manager");
	
	if (g_bRadarHooked) SDKHook(g_iPlayerManager, SDKHook_PostThink, OnEntityThink);
}

public void OnClientPutInServer(int client)
{
	if (g_bRadarHooked) SDKHook(client, SDKHook_PreThink, OnEntityThink);
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client) return;

	if(GetClientTeam(client) != 1) Client_HideRadar(client);
}

public Action Event_PlayerBlind(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	float duration = GetEntDataFloat(client, g_iFlashDuration);
	
	if(!client) return;

	if(GetClientTeam(client) != 1) CreateTimer(duration, Timer_FlashEnd, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_FlashEnd(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client) return Plugin_Stop;

	if(GetClientTeam(client) != 1) Client_HideRadar(client);
		
	return Plugin_Stop;
}

public void OnEntityThink(int entity)
{
	for (int i = 0; i <= 65; i++) SetEntData(g_iPlayerManager, g_iPlayerSpotted + i, true, 4, true);
	
	SetEntData(g_iPlayerManager, g_iBombSpotted, true, 4, true);
}

public void OnRadarModeChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	int iRadarMode = GetConVarInt(convar);

	switch (iRadarMode)
	{
		case 0: // Default behaviour
		{
			if (g_bRadarHooked) Unhook_Radar();
			if (g_bFlashHooked) Unhook_Flash();
		}
		
		case 1: // Disable radar for all
		{
			if (g_bRadarHooked) Unhook_Radar();
			if (!g_bFlashHooked) Hook_Flash();
		}
		
		case 2: // Show all players on radar
		{
			if (!g_bRadarHooked) Hook_Radar();
			if (g_bFlashHooked) Unhook_Flash();
		}
	}
}

void Hook_Radar()
{
	g_bRadarHooked = true;
	
	SDKHook(g_iPlayerManager, SDKHook_PostThink, OnEntityThink);
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i) && IsClientInGame(i)) SDKHook(i, SDKHook_PreThink, OnEntityThink);
}

void Unhook_Radar()
{
	g_bRadarHooked = false;
	
	SDKUnhook(g_iPlayerManager, SDKHook_PostThink, OnEntityThink);
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i) && IsClientInGame(i)) SDKUnhook(i, SDKHook_PreThink, OnEntityThink);
}

void Hook_Flash()
{
	g_bFlashHooked = true;
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_blind", Event_PlayerBlind, EventHookMode_Post);
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) > 1)
			Client_HideRadar(i);
}

void Unhook_Flash()
{
	g_bFlashHooked = false;
	UnhookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	UnhookEvent("player_blind", Event_PlayerBlind, EventHookMode_Post);
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) > 1) Client_ShowRadar(i);
}

void Client_HideRadar(int client)
{
	SetEntDataFloat(client, g_iFlashDuration, 3600.0, true);
	SetEntDataFloat(client, g_iFlashAlpha, 0.5, true);
}

void Client_ShowRadar(int client)
{
	SetEntDataFloat(client, g_iFlashDuration, 0.5, true);
	SetEntDataFloat(client, g_iFlashAlpha, 0.5, true);
}