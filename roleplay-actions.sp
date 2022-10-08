#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

#define DELAY 5.0

Handle gh_Timer[MAXPLAYERS+1];
Handle gh_Timer2[MAXPLAYERS+1];
Handle gh_Timer3[MAXPLAYERS+1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_choice", CMD_CHOICE);
	RegConsoleCmd("sm_me", CMD_ME);
	RegConsoleCmd("sm_do", CMD_DO);
}

public void OnClientDisconnect(int client)
{
    if(gh_Timer[client])
    {
        KillTimer(gh_Timer[client]);
        gh_Timer[client] = null;
    }
    else if(gh_Timer2[client])
    {
        KillTimer(gh_Timer2[client]);
        gh_Timer2[client] = null;    	
    }
    else if(gh_Timer3[client])
    {
        KillTimer(gh_Timer3[client]);
        gh_Timer3[client] = null;    	
    }    
}

public Action CMD_CHOICE(int client, int args)
{
	if(!gh_Timer3[client])
	{
		if(args < 2)
		{
			ReplyToCommand(client, "[Сервер] Используйте: sm_choice <nickname/#userid> <word>");
			return Plugin_Handled;		
		}
		else if(args == 2)
		{
			char arg[128], arg2[128];

			GetCmdArg(1, arg, sizeof(arg));
			GetCmdArg(2, arg2, sizeof(arg2));

			int target = FindTarget(client, arg, true, false);

			if(client != target) PrintToChatAll(client, "[%N] %N is %s with %i percent", client, target, arg2, GetRandomInt(1, 100));
			else PrintToChat(client, "[Сервер] Выбранный игрок не найден!");
		}		
	}
	else PrintToChat(client, "[Сервер] Подождите немного...");

	return Plugin_Handled;
}

public Action CMD_ME(int client, int args)
{
	if(!gh_Timer[client])
	{
		if(args < 1)
		{
			ReplyToCommand(client, "[Сервер] Используйте: sm_me <any words>");
			return Plugin_Handled;			
		}
		else if(args > 1)
		{
			char msg[128];
			GetCmdArg(1, msg, sizeof(msg));

			PrintToChatAll("%N %s", client, msg);

			gh_Timer[client] = CreateTimer(DELAY, Timer, client, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
		}		
	}
	else ReplyToCommand(client, "[Сервер] Подождите немного...");

	return Plugin_Handled;
}

public Action CMD_DO(int client, int args)
{
	if(!gh_Timer2[client])
	{
		if(args < 1)
		{
			ReplyToCommand(client, "[Сервер] Используйте: sm_do <any words>");
			return Plugin_Handled;			
		}
		else if(args > 1)
		{
			char msg[128];
			GetCmdArg(1, msg, sizeof(msg));

			PrintToChatAll("%N %s", client, msg);

			gh_Timer2[client] = CreateTimer(DELAY, Timer2, client, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
		}		
	}
	else ReplyToCommand(client, "[Сервер] Подождите немного...");

	return Plugin_Handled;
}

public Action Timer3(Handle timer, any client)
{
	KillTimer(gh_Timer3[client]);
	gh_Timer3[client] = null;	
}

public Action Timer(Handle timer, any client)
{
	KillTimer(gh_Timer[client]);
	gh_Timer[client] = null;
}

public Action Timer2(Handle timer, any client)
{
	KillTimer(gh_Timer2[client]);
	gh_Timer2[client] = null;
}
