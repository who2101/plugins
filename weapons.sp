#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdktools_functions>
#include <entity>
#include <shavit/weapon-stocks>

#pragma newdecls required

public void OnPluginStart()
{
	RegConsoleCmd("sm_scout", Command_Weapon);
	RegConsoleCmd("sm_glock", Command_Weapon);
	RegConsoleCmd("sm_usp", Command_Weapon);
	RegConsoleCmd("sm_knife", Command_Weapon);
}

public Action Command_Weapon(int client, int args)
{
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "\x04[Timer] \x01Вы должны быть \x01живы\x01, чтобы \x04использовать \x01данную команду");

		return Plugin_Handled;
	}

	char sCommand[16];
	GetCmdArg(0, sCommand, 16);

	int iSlot = CS_SLOT_SECONDARY;
	char sWeapon[32];

	if(StrContains(sCommand, "usp", false) != -1)
	{
		strcopy(sWeapon, 32, "weapon_usp");
	}
	else if(StrContains(sCommand, "glock", false) != -1)
	{
		strcopy(sWeapon, 32, "weapon_glock");
	}
	else if(StrContains(sCommand, "scout", false) != -1)
	{
		strcopy(sWeapon, 32, "weapon_scout");
		iSlot = CS_SLOT_PRIMARY;
	}	
	else
	{
		strcopy(sWeapon, 32, "weapon_knife");
		iSlot = CS_SLOT_KNIFE;
	}

	int iWeapon = GetPlayerWeaponSlot(client, iSlot);

	if(iWeapon != -1)
	{
		RemovePlayerItem(client, iWeapon);
		RemoveEntity(iWeapon);
	}

	iWeapon = GivePlayerItem(client, sWeapon);
	FakeClientCommand(client, "use %s", sWeapon);

	if(iSlot != CS_SLOT_KNIFE)
	{
		SetMaxWeaponAmmo(client, iWeapon, false);
	}

	return Plugin_Handled;
}