#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public void OnPluginStart()
{
	RegConsoleCmd("sm_surf", CMD_Surf);
	RegConsoleCmd("sm_bhop", CMD_Bhop);
}

public Action CMD_Surf(int client, int args)
{
	ShowMotd(client, "Гайд по сёрфу", "https://www.youtube.com/watch?v=E3tys016mwg");

	return Plugin_Handled;
}

public Action CMD_Bhop(int client, int args)
{
	ShowMotd(client, "Гайд по бхопу", "https://www.youtube.com/watch?v=2zfa9rUQ_YA");

	return Plugin_Handled;
}

void ShowMotd(int client, char[] title, char[] url)
{
	ShowMOTDPanel(client, title, url, MOTDPANEL_TYPE_URL);
}