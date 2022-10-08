#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>

#pragma newdecls required

public void OnPluginStart()
{
	RegConsoleCmd("sm_glock", CMD_GLOCK);
	RegConsoleCmd("sm_usp", CMD_USP);
	RegConsoleCmd("sm_scout", CMD_SCOUT);
	RegConsoleCmd("sm_knife", CMD_KNIFE);
}

void SetClientWeapon(int client, char[] weapon)
{
	GivePlayerItem(client, weapon);
}

public Action CMD_KNIFE(int client, int args)
{
	SetClientWeapon(client, "weapon_knife");
	return Plugin_Handled;	
}

public Action CMD_GLOCK(int client, int args)
{
	SetClientWeapon(client, "weapon_glock");
	return Plugin_Handled;
}

public Action CMD_USP(int client, int args)
{
	SetClientWeapon(client, "weapon_usp");
	return Plugin_Handled;
}

public Action CMD_SCOUT(int client, int args)
{
	SetClientWeapon(client, "weapon_scout");
	return Plugin_Handled;
}