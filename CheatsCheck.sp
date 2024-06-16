#pragma tabsize 0

#include <multicolors>
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define OVERLAY_PATH "overlay_cheats/ban_cheats3"

TopMenu g_hTopMenu = null;

char logFile[100] = "";
enum struct playerinfo_t
{
	char ActionSelect[64];
	int ActionPlayer;
	bool BlockSpec;
	any StatusCheck;
	char Discord[64];
}

enum StatusCheckEnum
{
	STATUS_WAITDISCORD = 0,
	STATUS_WAITCALL = 1,
	STATUS_CHECKING = 2,
	STATUS_RESULT = 3,
}

playerinfo_t player_info[MAXPLAYERS + 1];

int TimeToReady = 10;

public void OnMapStart()
{
	char file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "configs/overlay_downloads2.ini");
	File fileh = OpenFile(file, "r");
	if (fileh != null)
	{
		char sBuffer[256];
		char sBuffer_full[PLATFORM_MAX_PATH];

		while(ReadFileLine(fileh, sBuffer, sizeof(sBuffer)))
		{
			TrimString(sBuffer);
			if ( sBuffer[0]  && sBuffer[0] != '/' && sBuffer[1] != '/' )
			{
				FormatEx(sBuffer_full, sizeof(sBuffer_full), "materials/%s", sBuffer);
				if (FileExists(sBuffer_full))
				{
					PrecacheDecal(sBuffer, true);
					AddFileToDownloadsTable(sBuffer_full);
				}
				else
				{
					PrintToServer("[RCC] File does not exist, check your path to overlay! %s", sBuffer_full);
				}
			}
		}
		delete fileh;
	}
}

public void OnPluginStart()
{
	if (LibraryExists("adminmenu"))
    {
        TopMenu hTopMenu;
        if ((hTopMenu = GetAdminTopMenu()) != null)
        {
            OnAdminMenuReady(hTopMenu);
        }
    }
	
	RegAdminCmd("sm_cheatscheck", cmd_CheckCheats, ADMFLAG_BAN);
	RegConsoleCmd("sm_contact", cmd_contact);
	
	CreateTimer(0.1, Timer_GiveOverlay, _, TIMER_REPEAT);
	
	AddCommandListener(Command_JoinTeam, "jointeam");
	
	LoadTranslations("RCC.phrases.txt");
}

public Action Command_JoinTeam(client, const char[] command, args)
{
	//char strTeam[8];
	//GetCmdArg(1, strTeam, sizeof(strTeam));
	//int team = StringToInt(strTeam);
	if(player_info[client].BlockSpec)
	{
		CPrintToChat(client, "%t %t", "Chat_Prefix", "Chat_SpecBlock");
		return Plugin_Handled;
	}
	return Plugin_Continue;
} 

public Action Timer_GiveOverlay(Handle hTimer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			int client;
			int clientChoose
			for(int x = 1; x <= MaxClients; x++)
			{
				if(IsClientInGame(x))
				{
					if(player_info[x].ActionPlayer == GetClientUserId(i) && StrEqual(player_info[x].ActionSelect, "CheckCheats"))
					{
						client = x;
						clientChoose = GetClientOfUserId(player_info[x].ActionPlayer);
					}
				}
			}
			if(clientChoose)
			{
				GiveOverlay(clientChoose, OVERLAY_PATH);
			}
			if(client)
			{
				Menu_PanelCheck(client);
			}
		}
	}
	
	char time[100];
	FormatTime(time, sizeof(time), "%d-%m");

	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/[%s] RCC.log", time);
	
	return Plugin_Continue;
}

public void OnClientConnected(int client)
{
	player_info[client].ActionSelect[0] = 0;
	player_info[client].ActionPlayer = 0;
	player_info[client].BlockSpec = false;
	player_info[client].StatusCheck = 0;
	player_info[client].Discord[0] = 0;
}

public void OnClientDisconnect(int client)
{
	if(StrEqual(player_info[client].ActionSelect, "CheckCheats"))
	{
		int clientChoose = GetClientOfUserId(player_info[client].ActionPlayer)
		if(clientChoose)
		{
			CPrintToChat(clientChoose, "%t %t", "Chat_Prefix", "Chat_LeaveAdmin");
			LogToFileEx(logFile, "%t", "Log_LeaveAdmin", client, clientChoose);
			player_info[clientChoose].BlockSpec = false;
			player_info[clientChoose].Discord[0] = 0;
		}
		player_info[client].ActionPlayer = 0;
		player_info[client].ActionSelect[0] = 0;
		player_info[client].BlockSpec = false;
		player_info[client].StatusCheck = 0;
	}
	if(HaveCheck(client))
	{
		int clientChoose;
		for(int x = 1; x <= MaxClients; x++)
		{
			if(IsClientInGame(x))
			{
				if(player_info[x].ActionPlayer == GetClientUserId(client) && StrEqual(player_info[x].ActionSelect, "CheckCheats"))
				{
					client = x;
					clientChoose = GetClientOfUserId(player_info[x].ActionPlayer);
				}
			}
		}
		CPrintToChat(client, "%t %t", "Chat_Prefix", "Chat_PlayerLeave");
		LogToFileEx(logFile, "%t", "Log_LeavePlayer", clientChoose, client);
		player_info[client].ActionPlayer = 0;
		player_info[client].ActionSelect[0] = 0;
		GiveOverlay(clientChoose, "");
	}
}

public Action cmd_CheckCheats(int client, any args)
{
	Menu_CheckCheats_PlayerChoose(client);
	
	return Plugin_Continue;
}

public Action cmd_contact(int client, any args)
{
	if(HaveCheck(client))
	{
		int clientChoose;
		for(int x = 1; x <= MaxClients; x++)
		{
			if(IsClientInGame(x))
			{
				if(player_info[x].ActionPlayer == GetClientUserId(client) && StrEqual(player_info[x].ActionSelect, "CheckCheats"))
				{
					client = x;
					clientChoose = GetClientOfUserId(player_info[x].ActionPlayer);
				}
			}
		}
		if(player_info[client].StatusCheck == STATUS_WAITDISCORD)
		{
			if(GetCmdArgs())
			{
				char NameDiscord[64];
				GetCmdArgString(NameDiscord, sizeof(NameDiscord));

				strcopy(player_info[clientChoose].Discord, 100, NameDiscord);

				CPrintToChat(client, "%t %t", "Chat_Prefix", "Chat_SuccessfullyDiscordAdm", clientChoose, NameDiscord);
				CPrintToChat(clientChoose, "%t %t", "Chat_Prefix", "Chat_SuccessfullyDiscordPlayer", NameDiscord);
				LogToFileEx(logFile, "%t", "Log_SuccessfullyDiscord", clientChoose, NameDiscord, client);
				player_info[client].StatusCheck++;
			}
			else
			{
				CPrintToChat(clientChoose, "%t %t", "Chat_Prefix", "Chat_ErrorDiscord");
			}
		}
		else
		{
			CPrintToChat(client, "%t %t", "Chat_Prefix", "Chat_ArleadyDiscordHave");
		}
	}
	else
	{
		CPrintToChat(client, "%t %t", "Chat_Prefix", "Chat_NoCheck");
	}
	
	return Plugin_Continue;
}

public bool HaveCheck(int client)
{
	bool temp = false;
	if(client > 0)
	{
		for(int x = 1; x <= MaxClients; x++)
		{
			if(IsClientInGame(x))
			{
				if(player_info[x].ActionPlayer == GetClientUserId(client) && StrEqual(player_info[x].ActionSelect, "CheckCheats"))
				{
					temp = true
				}
			}
		}
	}
	return temp;
}

public void Menu_PanelCheck(int client)
{
	int clientChoose = GetClientOfUserId(player_info[client].ActionPlayer);
	
	char temp[1280];
	char temp2[128];
	Menu hMenu = new Menu(MenuHandler_PanelCheck);
	Format(temp, sizeof(temp), "%t", "Menu_CheckPanel", clientChoose, GetStatus(player_info[client].StatusCheck));
	hMenu.SetTitle(temp);
	if(player_info[client].StatusCheck != STATUS_RESULT)
	{
		Format(temp2, sizeof(temp2), "%t\n ", "Menu_TopMenuHelpName")
		hMenu.AddItem("HowToCheck", temp2);
	}
	if(player_info[client].StatusCheck == STATUS_WAITDISCORD)
	{
		Format(temp, sizeof(temp), "%s\n ", temp);
		hMenu.SetTitle(temp);
		Format(temp, sizeof(temp), "%t", "Menu_NotifyDiscord")
		hMenu.AddItem("Notif", temp);
	}
	else if(player_info[client].StatusCheck == STATUS_WAITCALL)
	{
		Format(temp, sizeof(temp), "%t", "Menu_CallAccept", player_info[clientChoose].Discord);
		hMenu.AddItem("Status", temp);
	}
	else if(player_info[client].StatusCheck == STATUS_CHECKING)
	{
		Format(temp, sizeof(temp), "%t", "Menu_EndCheck")
		hMenu.AddItem("Status", temp);
	}
	else if(player_info[client].StatusCheck == STATUS_RESULT)
	{
		Format(temp, sizeof(temp), "%t", "Menu_ResultNoCheats")
		hMenu.AddItem("GoodResult", temp);
		Format(temp, sizeof(temp), "%t", "Menu_ResultCheats")
		hMenu.AddItem("BadResult", temp);
	}
	if(!player_info[clientChoose].BlockSpec)
	{
		if(GetClientTeam(clientChoose) != CS_TEAM_SPECTATOR)
		{
			Format(temp, sizeof(temp), "%t", "Menu_ToSpec")
			hMenu.AddItem("ToSpec", temp);
		}
		else
		{
			Format(temp, sizeof(temp), "%t", "Menu_BlockSpec")
			hMenu.AddItem("BlockSpec", temp);
		}
	}
	Format(temp, sizeof(temp), "%t", "Menu_StopCheck")
	hMenu.AddItem("GoodResult", temp);
	hMenu.ExitButton = false;
	hMenu.Display(client, 0);
}

public int MenuHandler_PanelCheck(Menu hMenu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[128];
			hMenu.GetItem(item, info, sizeof(info));
			int clientChoose = GetClientOfUserId(player_info[client].ActionPlayer);
			
			if(clientChoose)
			{
				if(StrEqual(info, "ToSpec"))
				{
					ChangeClientTeam(clientChoose, CS_TEAM_SPECTATOR);
					CPrintToChat(clientChoose, "%t %t", "Chat_Prefix", "Chat_ToSpecPlayer");
					CPrintToChat(client, "%t %t", "Chat_Prefix", "Chat_ToSpecAdm", clientChoose);
				}
				else if(StrEqual(info, "Notif"))
				{
					CPrintToChat(clientChoose, "%t %t", "Chat_Prefix", "Chat_DiscordNotifyPlayer");
					CPrintToChat(client, "%t %t", "Chat_Prefix", "Chat_DiscordNotifyAdm", clientChoose);
				}
				else if(StrEqual(info, "BlockSpec"))
				{
					CPrintToChat(clientChoose, "%t %t", "Chat_Prefix", "Chat_SpecBlockPlayer");
					CPrintToChat(client, "%t %t", "Chat_Prefix", "Chat_SpecBlockAdm", clientChoose);
					player_info[clientChoose].BlockSpec = true;
				}
				else if(StrEqual(info, "Status"))
				{
					player_info[client].StatusCheck++;
				}
				else if(StrEqual(info, "GoodResult"))
				{
					CPrintToChat(clientChoose, "%t %t", "Chat_Prefix", "Chat_EndNoCheatsPlayer");
					CPrintToChat(client, "%t %t", "Chat_Prefix", "Chat_EndNoCheatsAdm");
					LogToFileEx(logFile, "%t", "Log_EndNoCheats", client, clientChoose);
					player_info[client].ActionPlayer = 0;
					player_info[client].ActionSelect = "";
					player_info[client].StatusCheck = 0;
					player_info[clientChoose].Discord[0] = 0;
					player_info[clientChoose].BlockSpec = false;
					GiveOverlay(clientChoose, "");
					
				}
				else if(StrEqual(info, "BadResult"))
				{
					CPrintToChat(clientChoose, "%t %t", "Chat_Prefix", "Chat_EndCheatsPlayer");
					CPrintToChat(client, "%t %t", "Chat_Prefix", "Chat_EndCheatsAdm");
					LogToFileEx(logFile, "%t", "Log_EndCheats", client, clientChoose);
					player_info[client].ActionPlayer = 0;
					player_info[client].ActionSelect[0] = 0;
					player_info[client].StatusCheck = 0;
					player_info[clientChoose].Discord[0] = 0;
					GiveOverlay(clientChoose, "");
				}
				else if(StrEqual(info, "HowToCheck"))
				{
					HowToCheck(client);
				}
			}
		}
		case MenuAction_End:
		{ 
			hMenu.Close();
		}
	}
	
	return 0;
}

public void Menu_CheckCheats_PlayerChoose(int client)
{
	if(StrEqual(player_info[client].ActionSelect, "CheckCheats") && HaveCheck(GetClientOfUserId(player_info[client].ActionPlayer)))
	{
		CPrintToChat(client, "%t %t", "Chat_Prefix", "Chat_ArleadyChecking", GetClientOfUserId(player_info[client].ActionPlayer));
	}
	else
	{
		char temp[128];
		char temp2[128];
		Menu hMenu = new Menu(MenuHandler_CheckCheats_PlayerChoose);
		Format(temp, sizeof(temp), "%t", "Menu_ChoosePlayer")
		hMenu.SetTitle(temp);
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && i != client)
			{
				Format(temp, sizeof(temp), "%i", GetClientUserId(i));
				Format(temp2, sizeof(temp2), "%N", i)
				hMenu.AddItem(temp, temp2, HaveCheck(i) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
			}
		}
		hMenu.Display(client, 0);
	}
}

public int MenuHandler_CheckCheats_PlayerChoose(Menu hMenu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[128];
			hMenu.GetItem(item, info, sizeof(info));
			int clientChoose = GetClientOfUserId(StringToInt(info));
			if(clientChoose)
			{
				strcopy(player_info[client].ActionSelect, sizeof(playerinfo_t::ActionSelect), info);
				MakeVerify(client, clientChoose);
			}
			else
			{
				CPrintToChat(client, "%t %t", "Chat_Prefix", "Chat_PlayerLeave");
			}
		}
		case MenuAction_End: 
		{ 
			hMenu.Close();
		}
	}
	
	return 0;
}

public void HowToCheck(int client)
{
	CPrintToChat(client, "%t", "Chat_HowToCheck");
}

public void MakeVerify(int client, int clientChoose)
{
	strcopy(player_info[client].ActionSelect, 100, "CheckCheats");
	player_info[client].ActionPlayer = GetClientUserId(clientChoose);
	CPrintToChatAll("%t", "Chat_PlayerToCheck", client, clientChoose);
	LogToFileEx(logFile, "%t", "Log_PlayerToCheck", client, clientChoose);
	CPrintToChat(clientChoose, "%t %t\n%t %t, %t", "Chat_Prefix", "Chat_ToCheckPlayer", client, "Chat_Prefix", "Chat_DiscordNotifyPlayer", "Chat_TimeToDiscord", TimeToReady);
}

public void GiveOverlay(int client, char[] path)
{
	ClientCommand(client, "r_screenoverlay \"%s\"", path);
}

public void OnAdminMenuReady(Handle aTopMenu)
{
    TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);

    if (hTopMenu == g_hTopMenu)
    {
        return;
    }

    g_hTopMenu = hTopMenu;
	
	TopMenuObject hMyCategory = g_hTopMenu.AddCategory("check_category", Handler_Admin_CheckCheats, "check_admin", ADMFLAG_BAN, "Проверить на читы");
	
	if (hMyCategory != INVALID_TOPMENUOBJECT)
    {
        g_hTopMenu.AddItem("check_cheats", Handler_Admin_CheckCheats2, hMyCategory, "check_cheats", ADMFLAG_BAN, "check_cheats");
		g_hTopMenu.AddItem("check_cheats_help", Handler_Admin_CheckCheats3, hMyCategory, "check_cheats_help", ADMFLAG_BAN, "check_cheats_help");
	}
}

public void Handler_Admin_CheckCheats(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int client, char[] sBuffer, int maxlength)
{
    switch (action)
    {
		case TopMenuAction_DisplayOption:
		{
			FormatEx(sBuffer, maxlength, "%T", "Menu_CategoryName", client);
		}
		case TopMenuAction_DisplayTitle:
		{
			FormatEx(sBuffer, maxlength, "%T", "Menu_ChooseAction", client);
		}
    }
}

public void Handler_Admin_CheckCheats2(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int client, char[] sBuffer, int maxlength)
{
    switch (action)
    {
		case TopMenuAction_DisplayOption:
        {
            FormatEx(sBuffer, maxlength, "%T", "Menu_TopMenuName", client);
        }
		case TopMenuAction_SelectOption:
        {
            Menu_CheckCheats_PlayerChoose(client);
        }
    }
}

public void Handler_Admin_CheckCheats3(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int client, char[] sBuffer, int maxlength)
{
    switch (action)
    {
		case TopMenuAction_DisplayOption:
        {
            FormatEx(sBuffer, maxlength, "%T", "Menu_TopMenuHelpName", client);
        }
		case TopMenuAction_SelectOption:
        {
            HowToCheck(client);
			RedisplayAdminMenu(hMenu, client);
        }
    }
}

char[] GetStatus(any status)
{
	char status2[100];
	switch(status)
	{
		case STATUS_WAITDISCORD:
		{
			Format(status2, sizeof(status2), "%t", "Status_WAITDISCORD");
		}
		case STATUS_WAITCALL:
		{
			Format(status2, sizeof(status2), "%t", "Status_WAITCALL");
		}
		case STATUS_CHECKING:
		{
			Format(status2, sizeof(status2), "%t", "Status_CHECKING");
		}
		case STATUS_RESULT:
		{
			Format(status2, sizeof(status2), "%t", "Status_RESULT");
		}
	}
	return status2;
}

public void OnLibraryRemoved(const char[] szName)
{
    if (StrEqual(szName, "adminmenu"))
    {
        g_hTopMenu = null;
    }
}