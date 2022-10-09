#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

EngineVersion gEV_Type;

public void OnPluginStart()
{
	RegConsoleCmd("sm_getengine", CMD_GETENGINE);
	gEV_Type = GetEngineVersion();	
}

public Action CMD_GETENGINE(int client, int args)
{
	PrintToChat(client, "\x01[\x04Сервер\x01] \x04Текущий \x01движок игры: \x04%s", gEV_Type);

	return Plugin_Handled;
}