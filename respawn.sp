#include <sourcemod>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define prefix "\x01[\x04Сервер\x01]"

public void OnPluginStart()
{
	RegAdminCmd("sm_respawn", CMD_Respawn, ADMFLAG_ROOT);
}

public Action CMD_Respawn(int client, int args)
{
	if(args != 1)
	{
		if(GetClientTeam(client) == 1)
		{
			PrintToChat(client, "%s \x04Зайдите за команду\x01, чтобы \x04использовать \x01данную команду", prefix);
			return Plugin_Handled;
		}
		if(IsPlayerAlive(client))
		{
			PrintToChat(client, "%s Вы должны быть \x04мертвы\x01, чтобы \x04использовать \x01данную команду", prefix);
			return Plugin_Handled;
		}		

		PrintToChat(client, "%s Вы были \x04возрождены", prefix);
		CS_RespawnPlayer(client);

		return Plugin_Handled;
	}

	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));

	int target = FindTarget(client, arg, true, false);

	if(!target || target == client)
	{
		PrintToChat(client, "%s Данная команда не работает на самом себе", prefix);
		return Plugin_Handled;
	}
	if(GetClientTeam(target) == 1)
	{
		PrintToChat(client, "%s Игрок \x04находится \x01в спектрах");
		return Plugin_Handled;
	}
	if(IsPlayerAlive(target))
	{
		PrintToChat(client, "%s Игрок в данный момент жив");
		return Plugin_Handled;
	}

	PrintToChat(target, "%s Модератор \x04%N \x01возродил вас", prefix, client);
	CS_RespawnPlayer(target);

	return Plugin_Handled;
}