#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public void OnPluginStart()
{
	RegConsoleCmd("sm_rules", CMD_RULES);
	RegConsoleCmd("sm_gmrules", CMD_GMRULES);
	RegConsoleCmd("sm_drules", CMD_DRULES);
}

public Action CMD_RULES(int client, int args)
{
	ShowMotd(client, "Правила сервера", "https://csproject.ru/rules");
	return Plugin_Handled;
}

public Action CMD_GMRULES(int client, int args)
{
	ShowMotd(client, "Правила режимов", "https://csproject.ru/rules_for_modes");
	return Plugin_Handled;	
}

public Action CMD_DRULES(int client, int args)
{
	ShowMotd(client, "Правила привилегий", "https://csproject.ru/rules_of_donates");
	return Plugin_Handled;	
}

void ShowMotd(int client, char[] title, char[] path) 
{ 
	ShowMOTDPanel(client, title, path, MOTDPANEL_TYPE_URL); 
}