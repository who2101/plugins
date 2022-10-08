#include <sourcemod>
#include <morecolors>
#include <shop>
#include <clientprefs>
#include <sdktools>

#pragma semicolon 1

char pl_tag[] =	"\x03[\x04Монетка\x03]";

char cFlipCoin[][] = {"Орёл", "Решка"};
int iClientCoin[MAXPLAYERS+1][2]; //Сторона монетки | 0 - до игры | 1 - фикс в игре
int iPreCredits[MAXPLAYERS+1][3]; //0 - хочет поставить | 1 - уже поставил | 2 - отправил предложение
bool IsClientInPlay[MAXPLAYERS+1]; //Если игрок в игре
int iFlipTime[MAXPLAYERS+1]; //Таймер игры

float UpTimer[MAXPLAYERS+1];
int UTimer[MAXPLAYERS+1];
int iWin[MAXPLAYERS+1];
char USussces[MAXPLAYERS+1][4][64];

int iStats[MAXPLAYERS+1][5];
Handle:g_hCookie;
Handle:hWriteTimer[MAXPLAYERS+1] = INVALID_HANDLE;
bool bWaitTime[MAXPLAYERS+1];

//cvar
int iTimeGame;
int iCvarCredits[2]; //0 - минимум кредитов | 1 - максимум кредитов
float fCommission;
int iChangeWrite;
float fWriteTime;
float fWaitTime;

public Plugin myinfo = {
	name        = "[Shop] FlipGame",
	author      = "FLASHER",
	description = "Монетка на кредиты",
	version     = "2.1.1",
	url = "discord: FLASHER#4704"
};

public OnPluginStart ()
{
	RegConsoleCmd ("sm_flip", MainMenu);
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	g_hCookie = RegClientCookie("Shop_FlipGame", "Shop_FlipGame", CookieAccess_Private);
	
	ConVar cvar;
	
	(cvar = CreateConVar("flip_time", "5",	"Время, через которое будет проведена игра между игроками", _, true, 1.0)).AddChangeHook(ChangeCvar_TimeGame);
	iTimeGame = cvar.IntValue;
	
	(cvar = CreateConVar("flip_maxcredits", "1000",	"Максимум кредитов для ставки [0 - без ограничений]", _, true, 0.0)).AddChangeHook(ChangeCvar_MaxCredits);
	iCvarCredits[1] = cvar.IntValue;
	
	(cvar = CreateConVar("flip_mincredits", "1",	"Минимум кредитов для ставки", _, true, 1.0)).AddChangeHook(ChangeCvar_MinCredits);
	iCvarCredits[0] = cvar.IntValue;
	
	(cvar = CreateConVar("flip_percent", "0.0",	"Комиссия, которая будет взиматься с выигрыша (В процентах) [0 - нет комиссии]", _, true, 0.0, true, 49.0)).AddChangeHook(ChangeCvar_fCommission);
	fCommission = cvar.FloatValue;
	
	(cvar = CreateConVar("flip_changewrite", "0",	"тип вывода процесса игры [Hud - 0 | Чат - 1]", _, true, 0.0, true, 1.0)).AddChangeHook(ChangeCvar_ChangeWrite);
	iChangeWrite = cvar.IntValue;
	
	(cvar = CreateConVar("flip_writetime", "10.0",	"Время ввода ставки в чат", _, true, 1.0)).AddChangeHook(ChangeCvar_fWriteTime);
	fWriteTime = cvar.FloatValue;
	
	(cvar = CreateConVar("flip_waittime", "2.0",	"Время кд отправки предложений другим игрокам", _, true, 0.1)).AddChangeHook(ChangeCvar_fWaitTime);
	fWaitTime = cvar.FloatValue;
	
	AutoExecConfig(true, "shop_flipgame", "shop");
}

public void ChangeCvar_TimeGame(ConVar convar, const char[] oldValue, const char[] newValue)
{
	iTimeGame = convar.IntValue;
}
public void ChangeCvar_MaxCredits(ConVar convar, const char[] oldValue, const char[] newValue)
{
	iCvarCredits[1] = convar.IntValue;
}
public void ChangeCvar_MinCredits(ConVar convar, const char[] oldValue, const char[] newValue)
{
	iCvarCredits[0] = convar.IntValue;
}
public void ChangeCvar_fCommission(ConVar convar, const char[] oldValue, const char[] newValue)
{
	fCommission = convar.FloatValue;
}
public void ChangeCvar_fWriteTime(ConVar convar, const char[] oldValue, const char[] newValue)
{
	fWriteTime = convar.FloatValue;
}
public void ChangeCvar_ChangeWrite(ConVar convar, const char[] oldValue, const char[] newValue)
{
	iChangeWrite = convar.IntValue;
}
public void ChangeCvar_fWaitTime(ConVar convar, const char[] oldValue, const char[] newValue)
{
	fWaitTime = convar.FloatValue;
}

public OnMapStart()
{
	AddFileToDownloadsTable("sound/ui/csgo_ui_crate_item_scroll.wav");
	PrecacheSound("UI/hint.wav");
	PrecacheSound("ui/csgo_ui_crate_item_scroll.wav");
}

public void OnMapEnd() {
	for(int i = 1; i <= MaxClients; i++) {
		hWriteTimer[i] = INVALID_HANDLE;
	}
}

public void OnClientCookiesCached(int iClient)
{
	char szValue[64];
	GetClientCookie(iClient, g_hCookie, szValue, sizeof(szValue));
	if(szValue[0])
	{
		new String:sNew[5][128];
		ExplodeString(szValue, ":", sNew, 5, 128, false);
		iStats[iClient][0] = StringToInt(sNew[0]);
		iStats[iClient][1] = StringToInt(sNew[1]);
		iStats[iClient][2] = StringToInt(sNew[2]);
		iStats[iClient][3] = StringToInt(sNew[3]);
		iStats[iClient][4] = StringToInt(sNew[4]);
	}
}

public Action:MainMenu(client, args)
{
	MoneyGameMenu(client);
	return Plugin_Handled;
}

MoneyGameMenu(client)
{
	Menu menu = new Menu(FlipGameMenu);
	menu.SetTitle("Монетка\n \n");
	menu.AddItem("", "Начать игру");
	
	if(!iStats[client][4]) menu.AddItem("", "Выключить предложения");
	else menu.AddItem("", "Включить предложения");
	
	menu.AddItem("", "Моя статистика");
	menu.ExitButton = true;
	menu.ExitBackButton = false;
	menu.Display(client, 0);
}

ShowStartGameMenu(client)
{
	if(iPreCredits[client][1] > Shop_GetClientCredits(client) || iPreCredits[client][1] == 0 || iPreCredits[client][1] < iCvarCredits[0]) iPreCredits[client][1] = iCvarCredits[0];
	
	Menu menu = new Menu(StartGameHadler);
	menu.SetTitle("Монетка\n \nВаша ставка: %i кредитов\nСторона монетки: %s\n \n", iPreCredits[client][1], cFlipCoin[iClientCoin[client][0]]);
	menu.AddItem("", "Изменить ставку");
	menu.AddItem("", "Изменить сторону монетки\n \n");
	
	if(iPreCredits[client][1] > Shop_GetClientCredits(client)) menu.AddItem("", "Найти игрока\n \n", 1);
	else menu.AddItem("", "Найти игрока\n \n");
	
	menu.AddItem("", "Назад");
	
	menu.ExitButton = true;
	menu.ExitBackButton = false;
	menu.Display(client, 0);
}

ShowStatsMenu(client)
{
	Menu menu = new Menu(StatsMenu);
	menu.SetTitle("Статистика\n \nНик: %N\nКоличество игр: %i\nПобед: %i\nПоражений: %i\nЗаработано кредитов: %i\nПроиграно кредитов: %i\n \n", client, iStats[client][0], iStats[client][1], iStats[client][0]-iStats[client][1],iStats[client][2],iStats[client][3]);
	menu.AddItem("", "Назад");
	menu.ExitButton = true;
	menu.ExitBackButton = false;
	menu.Display(client, 0);
}

public int StatsMenu(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End) 
		delete menu;
	else if (action == MenuAction_Select)
		if(!param) MoneyGameMenu(client);
}

public int StartGameHadler(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End) 
		delete menu;
	else if (action == MenuAction_Select)
	{
		if(param == 3) MoneyGameMenu(client);
		else if(param == 0) //Изменить ставку
		{
			CPrintToChat(client, "%s Введите сумму ставки в чат:", pl_tag);
			Kill_Timer(client);
			hWriteTimer[client] = CreateTimer(fWriteTime, Timer_Write, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else if(param == 1) //Изменить сторону монетки
		{
			if(iClientCoin[client][0]) iClientCoin[client][0] = 0;
			else iClientCoin[client][0] = 1;
			ShowStartGameMenu(client);
		}
		else if(param == 2) //Найти игрока
		{
			if(!bWaitTime[client]) {
				Menu pmenu = new Menu(ChoicePlayer); 
				pmenu.SetTitle("Выберите игрока\nСтавка: %i кредитов:\n \n", iPreCredits[client][1]); 
				decl String:userid[15], String:name[32]; 
				int count = 0;
				for (int i = 1; i <= MaxClients; i++) 
				{
					if (IsClientInGame(i) && !IsFakeClient(i) && Shop_GetClientCredits(i) >= iPreCredits[client][1] && !IsClientInPlay[i] && client != i && !iStats[i][4]) 
					{ 
						IntToString(GetClientUserId(i), userid, 15); 
						GetClientName(i, name, 32); 
						pmenu.AddItem(userid, name); 
						count++;
					}
				}
				
				if(!count) pmenu.AddItem("", "Нет подходящих игроков", 1);
				
				pmenu.ExitButton = true;
				pmenu.ExitBackButton = true;
				pmenu.Display(client, 0); 
			}
			else { 
				CPrintToChat(client, "%s Не так быстро! Ожидайте...", pl_tag);
				ShowStartGameMenu(client);
			}
		}
	}
}

public Action:Timer_Write(Handle:timer, any:userid){
	int iClient = GetClientOfUserId(userid);
	if(iClient > 0)
		CPrintToChat(iClient, "%s Время ввода значения вышло.", pl_tag);
	hWriteTimer[iClient] = INVALID_HANDLE;
}

stock Kill_Timer(client){
	if(hWriteTimer[client] != INVALID_HANDLE){
		KillTimer(hWriteTimer[client]);
		hWriteTimer[client] = INVALID_HANDLE;
	}
}

public int ChoicePlayer(Menu pmenu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End) 
		delete pmenu;
	else if (action == MenuAction_Select)
	{
		if (Shop_GetClientCredits(client) >= iPreCredits[client][1]) //Остались ли кредиты у игрока
		{
			if(!IsClientInPlay[client]) //Если игрок ещё не в игре
			{
				CPrintToChat(client, "%s Предложение отправлено", pl_tag);
				
				//Ставим кд
				bWaitTime[client] = true;
				CreateTimer(fWaitTime, Timer_Wait, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
				
				decl String:userid[15]; 
				pmenu.GetItem(param, userid, 15); 
				int target = GetClientOfUserId(StringToInt(userid)); 
				if (target > 0) 
				{
					if(!IsClientInPlay[target]) //Проверяем, не в игре ли цель
					{
						if(Shop_GetClientCredits(target) >= iPreCredits[client][1]) //Есть ли у него кредиты
						{
							iPreCredits[target][2] = iPreCredits[client][1]; //Фиксируем ставку

							Menu menu = new Menu(TargetFlipMenu);
							
							decl String:sBuffer[128];
							Format(sBuffer, sizeof(sBuffer), "%i", client);
							
							menu.SetTitle("Монетка\n \nПредложение сыграть с игроком: %N\nСтавка: %i кредитов\n \n", client, iPreCredits[target][2]); 
							menu.AddItem(sBuffer, "Принять предложение");
							menu.AddItem(sBuffer, "Отказаться от предложения");
							menu.ExitButton = true;
							menu.ExitBackButton = false;
							menu.Display(target, 0);
						}
						else
						{
							CPrintToChat(client, "%s У игрока уже нет достаточного количества кредитов", pl_tag);
							ShowStartGameMenu(client); 
						}
					}
					else
					{
						CPrintToChat(client, "%s Игрок принял игру с другим игроком", pl_tag);
					}
				}
				else
				{				
					CPrintToChat(client, "%s Игрок вышел с сервера", pl_tag); 
					ShowStartGameMenu(client); 
				}
			}
			else
			{
				CPrintToChat(client, "%s Вы находитесь в игре", pl_tag);
				ShowStartGameMenu(client);
			}
		}
		else
		{
			CPrintToChat(client, "%s У вас уже нет достаточного количества кредитов", pl_tag);
			ShowStartGameMenu(client);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param == MenuCancel_ExitBack)
		{
			ShowStartGameMenu(client);
		}
	}
}

public Action:Timer_Wait(Handle:timer, any:userid){
	int iClient = GetClientOfUserId(userid);
	if(iClient > 0)
		bWaitTime[iClient] = false;
}

public int TargetFlipMenu(Menu pmenu, MenuAction action, int target, int param)
{
	if (action == MenuAction_End) 
		delete pmenu;
	else if (action == MenuAction_Select)
	{
		decl String:sId[15]; 
		pmenu.GetItem(param, sId, 15); 
		int Inviter = StringToInt(sId);
		
		if(param) 
		{
			if(IsClientInGame(Inviter)) CPrintToChat(Inviter, "%s \x03%N \x04отказался от игры", pl_tag, target);
			iPreCredits[target][2] = 0;
		}
		else
		{
			if(IsClientInGame(Inviter)) // Проверяем, находится ли игрок на сервере
			{
				if(!IsClientInPlay[Inviter]) //Если игрок ещё не в игре с другим игроком
				{
					if(Shop_GetClientCredits(Inviter) >= iPreCredits[target][2]) //Есть ли у игрока креды
					{
						if(Shop_GetClientCredits(target) >= iPreCredits[target][2]) //Есть ли у цели креды
						{
							CPrintToChat(Inviter, "%s Игрок \x03%N \x04согласился", pl_tag, target);
						
							//Игроки в игре
							IsClientInPlay[Inviter] = true;
							IsClientInPlay[target] = true;
							
							//Статистика игр
							iStats[Inviter][0]++;
							iStats[target][0]++;
							
							//Присваиваем сторону монетки цели
							if(!iClientCoin[Inviter][0]) iClientCoin[target][1] = 1;
							else iClientCoin[target][1] = 0;
							//Присваиваем сторону монетки себе
							iClientCoin[Inviter][1] = iClientCoin[Inviter][0];
							
							//Снимаем кредиты
							Shop_SetClientCredits(Inviter, Shop_GetClientCredits(Inviter) - iPreCredits[target][2]);
							Shop_SetClientCredits(target, Shop_GetClientCredits(target) - iPreCredits[target][2]);
							
							//Приравниваем ставки
							iPreCredits[Inviter][2] = iPreCredits[target][2];
							
							//Статистика: проигранные кредиты
							iStats[Inviter][3] += iPreCredits[target][2];
							iStats[target][3] += iPreCredits[target][2];
							
							//Запускаем игру
							iFlipTime[Inviter] = iTimeGame; //Время таймера
							new Handle:datapack = CreateDataPack();
							WritePackCell(datapack, Inviter);
							WritePackCell(datapack, target);
							
							//Сообщаем игрокам о их стороне монетки в чат
							CPrintToChat(Inviter, "%s Ваша сторона монетки: \x03%s", pl_tag, cFlipCoin[iClientCoin[Inviter][1]]);
							CPrintToChat(target, "%s Ваша сторона монетки: \x03%s", pl_tag, cFlipCoin[iClientCoin[target][1]]);
							
							CreateTimer(1.0, FlipTime, datapack, TIMER_REPEAT);	
						}
						else
						{
							CPrintToChat(target, "%s У вас не хватает кредитов", pl_tag);
						}
					}
					else
					{
						CPrintToChat(target, "%s У \x03%N \x04уже нет кредитов", pl_tag, Inviter);
					}
				}
				else
				{
					CPrintToChat(target, "%s \x03%N \x04уже в другой игре", pl_tag, Inviter);
				}
			}
			else
			{
				CPrintToChat(target, "%s Игрок уже вышел с сервера", pl_tag);
			}
		}
	}
}

public Action:FlipTime(Handle:timer, Handle:datapack)
{
	ResetPack(datapack, false);
	int inviter = ReadPackCell(datapack);
	int target = ReadPackCell(datapack);
	
	if(iFlipTime[inviter]) //Идёт игра
	{
		if(IsClientInGame(inviter) && IsClientInGame(target))
		{
			if(!iChangeWrite)
			{
				char g_mText[512];
				Format(g_mText, sizeof(g_mText), "У тебя: %s\nНа кону: %i кредит(а)\nДо игры %i сек.", cFlipCoin[iClientCoin[inviter][1]], iPreCredits[target][2]*2, iFlipTime[inviter]);
				PrintHintText(inviter, g_mText);
				Format(g_mText, sizeof(g_mText), "У тебя: %s\nНа кону: %i кредит(а)\nДо игры %i сек.", cFlipCoin[iClientCoin[target][1]], iPreCredits[target][2]*2, iFlipTime[inviter]);
				PrintHintText(target, g_mText);
			}
			else //Для тех немногих, у кого занят hud
			{
				if(iFlipTime[inviter] == iTimeGame)
				{
					CPrintToChat(inviter, "%s До выбора победителя: \x03%i \x04сек.", pl_tag, iFlipTime[inviter]);
					CPrintToChat(target, "%s До выбора победителя: \x03%i \x04сек.", pl_tag, iFlipTime[inviter]);
				}
			}
		}
		else //Если кто то выышел из игры - выбираем победителя
		{
			if(!IsClientInGame(inviter)) PlayerWin(target, inviter);
			else if (!IsClientInGame(target)) PlayerWin(inviter, target);
			CloseHandle(datapack);
			return Plugin_Stop;
		}
		
		iFlipTime[inviter]--; //Таймер
		return Plugin_Continue;
	}
	else //Выбор победителя
	{
		if(!iChangeWrite)
		{
			//Запуск рулетки
			UpTimer[inviter] = 0.03;
			UTimer[inviter] = 20;
			CreateTimer(0.03, flipwin, datapack);
		}
		else //Для тех немногих, у кого занят hud
		{
			int iChance = GetRandomInt(0, 1); //Супер рандом
			
			//Сообщаем игрокам, что выпало
			if(IsClientInGame(inviter))
				CPrintToChat(inviter, "%s У нас \x03%s", pl_tag, cFlipCoin[iChance]);
			if(IsClientInGame(target))
				CPrintToChat(target, "%s У нас \x03%s", pl_tag, cFlipCoin[iChance]);
			
			//Определение победителя
			if(iClientCoin[inviter][1] == iChance) PlayerWin(inviter, target);
			else PlayerWin(target, inviter);
			CloseHandle(datapack);
		}
		return Plugin_Stop;
	}
}

public Action flipwin(Handle:timer, Handle:datapack)
{
	ResetPack(datapack, false);
	int inviter = ReadPackCell(datapack);
	int target = ReadPackCell(datapack);
	
	if(IsClientInGame(inviter) && IsClientInGame(target))
	{
		int iChance = GetRandomInt(0, 1); //Супер рандом
		if(iChance)
		{
			USussces[inviter][3] = cFlipCoin[1];
			if(UTimer[inviter] == 3) iWin[inviter] = 1;
		}
		else
		{
			USussces[inviter][3] = cFlipCoin[0];
		}
		
		//Вывод сообщения в центр
		PrintHintText(inviter, "%s\n%s\n%s ◄◄◄\n%s",USussces[inviter][3], USussces[inviter][2], USussces[inviter][1], USussces[inviter][0]);
		StopSound(inviter, 6, "UI/hint.wav");
		ClientCommand(inviter, "playgamesound ui/csgo_ui_crate_item_scroll.wav");
		
		PrintHintText(target, "%s\n%s\n%s ◄◄◄\n%s",USussces[inviter][3], USussces[inviter][2], USussces[inviter][1], USussces[inviter][0]);
		StopSound(target, 6, "UI/hint.wav");
		ClientCommand(target, "playgamesound ui/csgo_ui_crate_item_scroll.wav");
		
		for(int i = 1; i <= 3; ++i)
		{
			USussces[inviter][i-1] = USussces[inviter][i];
		}
		
		UTimer[inviter]--;
		
		if(!UTimer[inviter])
		{
			CPrintToChat(inviter, "%s У нас \x03%s", pl_tag, cFlipCoin[iWin[inviter]]);
			CPrintToChat(target, "%s У нас \x03%s", pl_tag, cFlipCoin[iWin[inviter]]);
			
			//Определение победителя
			if(iClientCoin[inviter][1] == iWin[inviter]) PlayerWin(inviter, target);
			else PlayerWin(target, inviter);
				
			iWin[inviter] = 0;
			CloseHandle(datapack);
			return Plugin_Stop;
		}
		//Для ускорения таймера
		if(UTimer[inviter] <= 7)
		{
			UpTimer[inviter] += 0.15;
		}
		
		CreateTimer(UpTimer[inviter], flipwin, datapack);
		return Plugin_Stop;
	}
	else //Если кто то выышел из игры - выбираем победителя
	{
		if(!IsClientInGame(inviter)) PlayerWin(target, inviter);
		else if (!IsClientInGame(target)) PlayerWin(inviter, target);
		CloseHandle(datapack);
		return Plugin_Stop;
	}
}

PlayerWin(winner, looser)
{
	int CreditsWin; //Ставка одного игрока
	if(iPreCredits[winner][2]) CreditsWin = iPreCredits[winner][2];
	else CreditsWin = iPreCredits[looser][2];
	int CreditsWinCommission = RoundFloat((CreditsWin * 2) - (CreditsWin * 2 * fCommission / 100)); //Полный выигрыш с комиссией
		
	if(IsClientInGame(winner))
	{
		iStats[winner][1]++; //Статистика: победы
		iStats[winner][2] += CreditsWinCommission - CreditsWin; //Статистика: заработано кредитов
		iStats[winner][3] -= CreditsWin; //Статистика: возвращаем проигрыш
		
		if(!IsClientInGame(looser))
		{
			Shop_SetClientCredits(winner, Shop_GetClientCredits(winner) + CreditsWin);
			CPrintToChat(winner, "%s Игрок вышел. Вы победили! Вам вернули \x03%i \x04кредитов", pl_tag, CreditsWin);
		}
		else
		{
			Shop_SetClientCredits(winner, Shop_GetClientCredits(winner) + CreditsWinCommission);
			CPrintToChat(winner, "%s Вы заработали \x03%i \x04кредитов", pl_tag, CreditsWinCommission);
		}
		
		IsClientInPlay[winner] = false;
	}
	if(IsClientInGame(looser))
	{
		CPrintToChat(looser, "%s Вы проиграли \x03%i {white}кредитов", pl_tag, CreditsWin);
		IsClientInPlay[looser] = false;
	}
	
	if(IsClientInGame(looser) && IsClientInGame(winner))
	{
		CPrintToChatAll("%s \x03%N \x04выиграл \x03%N и заработал \x03%i \x04кредитов", pl_tag, winner, looser, CreditsWinCommission);
	}
}

public int FlipGameMenu(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_End) 
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{	
		if(!param) ShowStartGameMenu(client);
		else if (param == 2) 
		{
			ShowStatsMenu(client);
		}
		else if(param == 1)
		{
			if(!iStats[client][4]) iStats[client][4] = 1;
			else iStats[client][4] = 0;
		
			MoneyGameMenu(client);
		}
	}
}

public Action Command_Say(int client, const char[] command, int argc)
{
	if(client > 0 && client <= MaxClients)
	{
		char text[64];
		if (!GetCmdArgString(text, sizeof(text)) || !text[0])
		{
			return Plugin_Continue;
		}
		if(hWriteTimer[client] != INVALID_HANDLE) {
			Kill_Timer(client);
			StripQuotes(text);
			TrimString(text);
			
			int PreCredits = StringToInt(text);
			if(PreCredits > 0)
			{
				if(Shop_GetClientCredits(client) >= PreCredits) //Проверка на наличие кредитов
				{
					if(PreCredits <= iCvarCredits[1] || iCvarCredits[1] == 0) //Проверка на максимальную ставку
					{
						if(PreCredits >= iCvarCredits[0]) //Проверка на минисальную ставку
						{
							CPrintToChat(client, "%s Вы изменили ставку на \x01%i \x04кредитов", pl_tag, PreCredits);
							iPreCredits[client][1] = PreCredits;
						}
						else
						{
							CPrintToChat(client, "%s Ошибка! Минимальная сумма ставки \x01%i \x04кредитов", pl_tag, iCvarCredits[0]);
						}
					}
					else
					{
						CPrintToChat(client, "%s Ошибка! Максимальная сумма ставки \x01%i \x04кредитов", pl_tag, iCvarCredits[1]);
					}
				}
				else
				{
					CPrintToChat(client, "%s Ошибка! У вас не достаточно кредитов", pl_tag);
				}
			}
			else
			{
				CPrintToChat(client, "%s Неправильное число", pl_tag);
			}
			ShowStartGameMenu(client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public OnClientDisconnect(iClient) // Ловим выход игрока
{
	//Сохраняем статистику
	decl String:sBuffer[128];
	Format(sBuffer, sizeof(sBuffer), "%i:%i:%i:%i:%i", iStats[iClient][0],iStats[iClient][1],iStats[iClient][2],iStats[iClient][3],iStats[iClient][4]);
	SetClientCookie(iClient, g_hCookie, sBuffer);
	IsClientInPlay[iClient] = false; //Игрок не в игре - монетка
	bWaitTime[iClient] = false;
}