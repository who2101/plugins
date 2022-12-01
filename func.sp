#pragma semicolon 1

#include <sourcemod>

#define PREFIX "\x01[\x04Сервер\x01]"
#define DS "\x01[\x04Сервер\x01] \x01Наш дискорд: \x04discord.gg/MWMDtqBy"
#define vk_group "\x01[\x04Сервер\x01] \x01Наша группа вк: \x04vk.com/di_project9"
#define vk_beseda "\x01[\x04Сервер\x01] \x01Наша беседа вк: \x04https://vk.cc/cfKkWo"
#define DONATE "\x01[\x04Сервер\x01] \x01Приобрести донат можно здесь: \x04https://csproject.ru/store"

#pragma newdecls required

char g_CurrentMap[128];

public void OnPluginStart()
{
	RegAdminCmd("sm_fmc", CMD_FMC, ADMFLAG_ROOT);	
	RegConsoleCmd("sm_vk", CMD_VK);
	RegConsoleCmd("sm_ds", CMD_DS);	
	RegConsoleCmd("sm_discord", CMD_DS);
	RegConsoleCmd("sm_donate", CMD_DONATE);	
}

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

public Action CMD_FMC(int client, int args)
{
	if(args != 1) ForceChangeLevel(g_CurrentMap, "");

	char arg[128];		
	GetCmdArg(1, arg, sizeof(arg));		
				
	if(!IsMapValid(arg))
	{
		PrintToChat(client, "%s \x01Выбранная карта \x04не найдена", PREFIX);

		return Plugin_Handled;
	}

	ForceChangeLevel(arg, "");
	
	return Plugin_Handled;
}
