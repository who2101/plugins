#pragma semicolon 1

#include <sourcemod>

#define PREFIX "\x01[\x04Сервер\x01]"
#define DS "\x01[\x04Сервер\x01] \x01Наш дискорд: \x04discord.gg/MWMDtqBy"
#define vk_group "\x01[\x04Сервер\x01] \x01Наша группа вк: \x04vk.com/di_project9"
#define vk_beseda "\x01[\x04Сервер\x01] \x01Наша беседа вк: \x04https://vk.cc/cfKkWo"
#define DONATE "\x01[\x04Сервер\x01] \x01Приобрести донат можно здесь: \x04https://csproject.ru/store"
#define RULES "\x01[\x04Сервер\x01] \x01Правила сервера: \x04csproject.ru/rules"
#define GM_RULES "\x01[\x04Сервер\x01] \x01Правила режимов: \x04csproject.ru/rules_for_modes"

#pragma newdecls required

char g_CurrentMap[128];

public void OnPluginStart()
{
	RegConsoleCmd("sm_reloadrtv", CMD_ReloadRTV);
	RegConsoleCmd("sm_fmc", CMD_FMC);	
	RegConsoleCmd("sm_vk", CMD_VK);
	RegConsoleCmd("sm_ds", CMD_DS);	
	RegConsoleCmd("sm_discord", CMD_DS);
	RegConsoleCmd("sm_donate", CMD_DONATE);	
	RegConsoleCmd("sm_rules", CMD_RULES);
}

/*
// TODO: Добавить возможность использовать !ртв / !hnd
public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(StrEqual(command, "!ртв") || StrEqual(command, "!hnd"))
	{
		ClientCommand(client, "sm_rtv");
	}
}
*/

public void OnMapStart()
{
	GetCurrentMap(g_CurrentMap, sizeof(g_CurrentMap));
}

public Action CMD_VK(int client, int args)
{
	ReplyToCommand(client, vk_group);
	ReplyToCommand(client, vk_beseda);	

	return Plugin_Handled;
}

public Action CMD_DS(int client, int args)
{
	ReplyToCommand(client, DS);

	return Plugin_Handled;
}

public Action CMD_DONATE(int client, int args)
{
	ReplyToCommand(client, DONATE);
	
	return Plugin_Handled;
}

public Action CMD_RULES(int client, int args)
{
	ReplyToCommand(client, RULES);
	ReplyToCommand(client, GM_RULES);

	return Plugin_Handled;	
}

public Action CMD_ReloadRTV(int client, int args)
{
	if(CheckCommandAccess(client, "sm_votemap", ADMFLAG_GENERIC, false))
	{
		ServerCommand("sm plugins reload umc/umc-core");
		ServerCommand("sm plugins reload umc/umc-rockthevote");
		ServerCommand("sm plugins reload umc/umc-adminmenu");	

		ReplyToCommand(client, "%s \x01Голосование было \x04перезапущено", PREFIX);	
	}
	return Plugin_Handled;
}

public Action CMD_FMC(int client, int args)
{
	if(CheckCommandAccess(client, "sm_delete", ADMFLAG_GENERIC, false))
	{
		char reason[1];

		if(args == 0) ForceChangeLevel(g_CurrentMap, reason);
		else if(args == 1)
		{
			char foundmap[128];
			char arg[128];		

			GetCmdArg(1, arg, sizeof(arg));		
				
			if(FindMap(arg, foundmap, sizeof(foundmap))) ForceChangeLevel(foundmap, reason);
			else PrintToChat(client, "%s \x01Выбранная карта \x04не найдена", PREFIX);
		}
	}
	else ReplyToCommand(client, "%s \x01У вас недостаточно прав!", PREFIX);
	
	return Plugin_Handled;
}
