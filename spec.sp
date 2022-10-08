#pragma semicolon 1

#include <sourcemod>
#include <cstrike>

#pragma newdecls required

public void OnPluginStart()
{
	RegConsoleCmd("sm_sp", Command_Spec);
	RegConsoleCmd("sm_spec", Command_Spec);	
	RegConsoleCmd("sm_afk", Command_Spec);	
}

public Action Command_Spec(int client, int args)
{	
	if(args == 0)
	{
		if(GetClientTeam(client) == 1) // Если игрок в спеках
		{
			ReplyToCommand(client, "\x01[\x04Сервер\x01] \x01Вы уже \x04находитесь \x01в спеках");	
		}
		else if(GetClientTeam(client) != 1) // Если игрок не в спеках
		{
			ChangeClientTeam(client, 1);
			ReplyToCommand(client, "\x01[\x04Сервер\x01] \x01Вы были \x04перемещены \x01в спеки");		
		}	
	}
	else if(args == 1 && CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC, false))
	{
		char arg[128];
		GetCmdArg(1, arg, sizeof(arg));

		int target = FindTarget(client, arg, true, false);

		if(target && target != client)
		{
			if(GetClientTeam(target) == 1) // Если цель в спеках
			{
				ReplyToCommand(client, "\x01[\x04Сервер\x01] \x04Выбранный \x01вами игрок \x04уже находится \x01в спеках");	
			}
			else if(GetClientTeam(target) != 1) // Если цель не в спеках
			{
				ChangeClientTeam(target, 1);
				ReplyToCommand(client, "\x01[\x04Сервер\x01] \x01Игрок \x04%N \x01был перемещён в спеки", target);
				PrintToChat(target, "\x01[\x04Сервер\x01] \x01Администратор \x04переместил \x01вас в спеки");		
			}				
		}
		else ReplyToCommand(client, "\x01[\x04Сервер\x01] Игрок \x04%N \x01не найден", target);	
	}

	return Plugin_Handled;
}