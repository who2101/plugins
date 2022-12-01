#include <sdktools_stringtables>
#include <sdktools_sound>

#pragma semicolon 1
#pragma newdecls required
	
ArrayList hSoundList;
	
public Plugin myinfo =
{
	name		= "[Any] Welcome Sound/Музыка при входе",
	author		= "Nek.'a 2x2 | ggwp.site ",
	description	= "Музыка при входе",
	version		= "1.0",
	url			= "https://ggwp.site/"
};
	
public void OnPluginStart() 
{
	hSoundList = new ArrayList(ByteCountToCells(128));
	HookEvent("player_activate", Event_Activate, EventHookMode_Pre);
}

public void OnMapStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/welcome_sound.ini");
	
	Handle hFile = OpenFile(sPath, "r");
	
	if(hFile == INVALID_HANDLE) ThrowError("Файл [%s] не существует !", sPath);
	
	ClearArray(hSoundList);
		
	while(!IsEndOfFile(hFile))
	{
		if (!ReadFileLine(hFile, sPath, sizeof(sPath))) continue;
	
		int iComments = StrContains((sPath), "//");
		if (iComments != -1) sPath[iComments] = '\0';
	
		iComments = StrContains((sPath), "#");
		if (iComments != -1) sPath[iComments] = '\0';
			
		iComments = StrContains((sPath), ";");
		if (iComments != -1) sPath[iComments] = '\0';
	
		TrimString(sPath);
		
		if (sPath[0] == '\0') continue;
		
		if(sPath[0])
		{
			char sBuffer[512];
			Format(sBuffer, sizeof(sBuffer), "sound/%s", sPath);
			AddFileToDownloadsTable(sBuffer);
			PrecacheSound(sPath, true);
			PushArrayString(hSoundList, sPath);
		}
	}
}

public Action Event_Activate(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsFakeClient(client)) return;
		
	char sSound[128];
	GetArrayString(hSoundList, GetRandomInt(0, GetArraySize(hSoundList) - 1), sSound, sizeof(sSound));
	EmitSoundToClient(client, sSound);
}