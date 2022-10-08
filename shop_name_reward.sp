#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <shop>

#pragma newdecls required

#define VERSION "1.0"

ConVar gcv_Time, gcv_Credits, gcv_Advert;

Handle g_Timer;

int g_iCredits;
char g_sAdvert[128];

public Plugin myinfo = {
	name = "Name Reward",
	author = "Franc1sco franug, vadrozh",
	description = "",
	version = VERSION,
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	CreateConVar("sm_namereward_version", VERSION, "Version", FCVAR_SPONLY|FCVAR_NOTIFY);
	
	gcv_Time = CreateConVar("sm_namereward_time", "60.0");
	gcv_Credits = CreateConVar("sm_namereward_credits", "15");
	gcv_Advert = CreateConVar("sm_namereward_advert", "csproject.ru");
	
	g_iCredits = GetConVarInt(gcv_Credits);
	GetConVarString(gcv_Advert, g_sAdvert, sizeof(g_sAdvert));
	
	HookConVarChange(gcv_Time, OnSettingChanged);
	HookConVarChange(gcv_Credits, OnSettingChanged);
	HookConVarChange(gcv_Advert, OnSettingChanged);
	
	g_Timer = CreateTimer(GetConVarFloat(gcv_Time), Timer_GetCredits, _, TIMER_REPEAT);
}

public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == gcv_Time)
	{
		if (g_Timer != null) KillTimer(g_Timer);
		g_Timer = CreateTimer(StringToFloat(newValue), Timer_GetCredits, _, TIMER_REPEAT);
	}
	else if (convar == gcv_Credits) g_iCredits = StringToInt(newValue);	
	else if (convar == gcv_Advert) strcopy(g_sAdvert, sizeof(g_sAdvert), newValue);
}

public Action Timer_GetCredits(Handle hTimer)
{
	char sName[128];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) > 1)
		{
			GetClientName(i, sName, 128);
			if(StrContains(sName, g_sAdvert, false) > -1)
			{
				Shop_GiveClientCredits(i, g_iCredits);
				PrintToChat(i, "\x01[\x04Сервер\x01] \x01Вы получили \x04%i монет \x01за наличие \x04%s \x01в нике!", g_iCredits, g_sAdvert);
			}	
			else PrintToChat(i, "\x01[\x04Сервер\x01] \x01Добавьте \x04csproject.ru \x01в ник, чтобы получить доступ к \x04специальным бонусам!");	
		}		
	}
}