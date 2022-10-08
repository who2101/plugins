#include <sourcemod>
#include <shop>
#include <shavit>
#include <clientmod>
#include <clientmod/multicolors>

#pragma semicolon 1
#pragma newdecls required

#define LG 6
#define SEG 7

public Plugin myinfo =
{
	name = "[Shop] Zone Credits",
	author = "Tonki_Ton",
	version = "1.4.0",
	url = "https://hlmod.ru"
};

enum
{
	BONUS,
	BONUSWR,
	WR,
	ONCE,
	CREDITS
};

ArrayList hWhoFinish;

char g_sCurrentMap[34];

int g_iCurrentPosition,
	g_iEventMode,
	g_iAmount[CREDITS],
	g_iPositionCredits[MAXPLAYERS+1];
	
bool g_bAllChat,
	 g_bSupportedMap;

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);

	hWhoFinish = new ArrayList(ByteCountToCells(32));

	RegAdminCmd("sm_zc_reload", reload, ADMFLAG_ROOT);

	LoadTranslations("shop_zone_credits.phrases");
}

public void OnMapStart()
{
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));
	LoadCfg();

	hWhoFinish.Clear();
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iCurrentPosition = 0;
}

//shavit
public void Shavit_OnFinish(int client, int style, float time, int jumps, int strafes, float sync, int track)
{
	float WrTime;
	Shavit_GetWRTime(style, WrTime, track);

	FinishMapEvent(client, style, (track == 0) ? false:true, !(WrTime == 0.0 || time < WrTime) ? false:true);
}

public Action reload(int client, int args) 
{
	PrintToConsole(client, "Конфиг перезагружен!");
	OnMapStart();

	return Plugin_Handled;
}

void FinishMapEvent(int client, int style, bool bonus, bool wr)
{
	if (!g_bSupportedMap) return;

	if(style != 6 || style != 7)
	{
		if (!g_iEventMode && !bonus && g_iAmount[ONCE] > 0)
		{
			Shop_GiveClientCredits(client, g_iAmount[ONCE]);
			
			CPrintToChatAll("%t", "mapfinish_once_credits", client, g_iAmount[ONCE]);

			g_bSupportedMap = false;
		}
		else
		{
			if (g_iEventMode == 2) 
	   		{
				char id[32];

				GetClientAuthId(client, AuthId_Steam2, id, sizeof(id), false);

				if (hWhoFinish.FindString(id) == -1) hWhoFinish.PushString(id);
				else if (hWhoFinish.FindString(id) != -1) return;
			}
		}

		if (!bonus && !wr)
		{
			if (++g_iCurrentPosition > MAXPLAYERS) g_iCurrentPosition = MAXPLAYERS;
			if (g_iPositionCredits[g_iCurrentPosition] < 1) return;

			Shop_GiveClientCredits(client, g_iPositionCredits[g_iCurrentPosition]);

			if (!g_bAllChat) CPrintToChat(client, "%t", "MapFinish_Credits", g_iPositionCredits[g_iCurrentPosition]);
			else CPrintToChatAll("%t", "MapFinish_Credits_All", client, g_iPositionCredits[g_iCurrentPosition]);
		}
		else if (!bonus && wr && g_iAmount[WR] > 0)
		{
			Shop_GiveClientCredits(client, g_iAmount[WR]);

			if (!g_bAllChat) CPrintToChat(client, "%t", "MapFinish_WR_Credits", g_iAmount[WR]);
			else CPrintToChatAll("%t", "MapFinish_WR_Credits_All", client, g_iAmount[WR]);
		}

		if (bonus && !wr && g_iAmount[BONUS] > 0)
		{
			Shop_GiveClientCredits(client, g_iAmount[BONUS]);

			if (!g_bAllChat) CPrintToChat(client, "%t", "MapFinish_Bonus_Credits", g_iAmount[BONUS]);
			else CPrintToChatAll("%t", "MapFinish_Bonus_Credits_All", client, g_iAmount[BONUS]);
		}
		else if (bonus && wr && g_iAmount[BONUSWR] > 0)
		{
			Shop_GiveClientCredits(client, g_iAmount[BONUSWR]);

			if (!g_bAllChat) CPrintToChat(client, "%t", "MapFinish_Bonus_WR_Credits", g_iAmount[BONUSWR]);
			else CPrintToChatAll("%t", "MapFinish_Bonus_WR_Credits_All", client, g_iAmount[BONUSWR]);
		}	
	}
	else
	{
		if(!bonus) CPrintToChat(client, "%t", "MapFinish_OnBanStyles");
		else CPrintToChat(client, "%t", "BonusFinish_OnBanStyles");
	}
}

void LoadCfg()
{
	char Buffer[128];

	KeyValues KvZc = new KeyValues("Credits");

	BuildPath(Path_SM, Buffer, sizeof(Buffer), "configs/shop/zone_credits.txt");
	if(!KvZc.ImportFromFile(Buffer)) SetFailState("Конфиг zone credits отсутсвует!");
	else
	{
		KvZc.Rewind();

		g_iEventMode = KvZc.GetNum("zc_mode", 1);
		g_bAllChat = view_as<bool>(KvZc.GetNum("announce_to_all", 0));

		if (KvZc.JumpToKey(g_sCurrentMap, false))
		{
			if (!g_iEventMode) g_iAmount[ONCE] = KvZc.GetNum("once_credits", 0);
			else
			{
				g_iAmount[BONUS] = KvZc.GetNum("bonus", 0);
				g_iAmount[BONUSWR] = KvZc.GetNum("bonus_wr", 0);
				g_iAmount[WR] = KvZc.GetNum("wr", 0);

				char sPos[10];
				for (int i = 1; i <= MAXPLAYERS; i++)
				{
					IntToString(i, sPos, sizeof(sPos));
					g_iPositionCredits[i] = KvZc.GetNum(sPos, -1);
					if (g_iPositionCredits[i] == -1)
					{
						g_iPositionCredits[i] = KvZc.GetNum("0");
					}
				}
			}
			g_bSupportedMap = true;
		}
		else g_bSupportedMap = false;
	}
	delete KvZc;
}