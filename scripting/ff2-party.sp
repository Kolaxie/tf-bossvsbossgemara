#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <ff2-party>

#define MAX_PARTIES 16

ConVar convar_Enabled;
ConVar convar_MaxMembers;

enum struct Party {
	char name[64];
	ArrayList players;
	int owner;

	void Init(const char[] name) {
		strcopy(this.name, sizeof(Party::name), name);
		this.players = new ArrayList();
	}

	bool AddPlayer(int client) {
		if (this.players.FindValue(client) != -1) {
			return false;
		}

		this.players.Push(client);
		return true;
	}

	bool RemovePlayer(int client) {
		int index = this.players.FindValue(client);
		if (index == -1) {
			return false;
		}

		this.players.Erase(index);
		return true;
	}

	bool IsInParty(int client) {
		return this.players.FindValue(client) != -1;
	}

	void Clear() {
		this.name[0] = '\0';
		delete this.players;
		this.owner = 0;
	}
}

Party g_Party[MAX_PARTIES + 1];
int g_TotalParties;

public Plugin myinfo = {
	name = "[FF2] Party",
	author = "Drixevel",
	description = "A plugin that allows you to party up with friends and play together.",
	version = "1.0.0",
	url = "https://drixevel.dev/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("ff2-party");

	CreateNative("FF2Party_IsEnabled", Native_IsEnabled);
	CreateNative("FF2Party_GetClients", Native_GetClients);
	CreateNative("FF2Party_GetParty", Native_GetParty);

	return APLRes_Success;
}

public void OnPluginStart() {
	CreateConVar("sm_ff2_party_version", "1.0.0", "Version control for this plugin.", FCVAR_DONTRECORD);
	convar_Enabled = CreateConVar("sm_ff2_party_enabled", "1", "Should this plugin be enabled or disabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_MaxMembers = CreateConVar("sm_ff2_party_max_members", "6", "The maximum amount of members a party can have.", FCVAR_NOTIFY, true, 1.0, true, 32.0);
	//AutoExecConfig();

	RegConsoleCmd("sm_party", Command_Party, "Party up with friends and play together.");

	//TODO: Allow players to create their own parties and invite others to join them.
	g_Party[g_TotalParties++].Init("Room 1");
	g_Party[g_TotalParties++].Init("Room 2");
	g_Party[g_TotalParties++].Init("Room 3");
	g_Party[g_TotalParties++].Init("Room 4");
	g_Party[g_TotalParties++].Init("Room 5");
	g_Party[g_TotalParties++].Init("Room 6");
}

public Action Command_Party(int client, int args) {
	if (!convar_Enabled.BoolValue) {
		return Plugin_Continue;
	}

	if (client < 1) {
		PrintToServer("This command can only be executed by a player.");
		return Plugin_Handled;
	}

	OpenPartiesMenu(client);

	return Plugin_Handled;
}

void OpenPartiesMenu(int client) {
	Menu menu = new Menu(MenuHandler_Parties, MENU_ACTIONS_ALL);
	menu.SetTitle("Choose a room:");

	char sID[16];
	for (int i = 0; i < g_TotalParties; i++) {
		IntToString(i, sID, sizeof(sID));
		menu.AddItem(sID, g_Party[i].name);
	}

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Parties(Menu menu, MenuAction action, int param1, int param2) {
	switch (action) {
		case MenuAction_DisplayItem: {
			char sInfo[32]; char sDisplay[256];
			menu.GetItem(param2, sInfo, sizeof(sInfo), _, sDisplay, sizeof(sDisplay));

			int room = StringToInt(sInfo);

			if (room < 0 || room >= g_TotalParties) {
				return RedrawMenuItem(sDisplay);
			}

			Format(sDisplay, sizeof(sDisplay), "%s (%i/%i)", sDisplay, g_Party[room].players.Length, convar_MaxMembers.IntValue);

			if (g_Party[room].IsInParty(param1)) {
				StrCat(sDisplay, sizeof(sDisplay), " (Leave)");
			} else {
				StrCat(sDisplay, sizeof(sDisplay), " (Join)");
			}

			return RedrawMenuItem(sDisplay);
		}

		case MenuAction_DrawItem: {
			char sInfo[32]; int itemdraw;
			menu.GetItem(param2, sInfo, sizeof(sInfo), itemdraw);

			int room = StringToInt(sInfo);

			if (room < 0 || room >= g_TotalParties) {
				return itemdraw;
			}

			if (g_Party[room].players.Length >= convar_MaxMembers.IntValue && !g_Party[room].IsInParty(param1)) {
				return ITEMDRAW_DISABLED;
			}

			return itemdraw;
		}

		case MenuAction_Select: {
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));

			int room = StringToInt(sInfo);

			if (room < 0 || room >= g_TotalParties) {
				PrintToChat(param1, "Invalid room selected.");
				OpenPartiesMenu(param1);
				return 0;
			}

			if (g_Party[room].IsInParty(param1)) {
				g_Party[room].RemovePlayer(param1);
				PrintToChat(param1, "You have left the room.");
			} else {

				if (g_Party[room].players.Length >= convar_MaxMembers.IntValue) {
					PrintToChat(param1, "This room is full.");
					OpenPartiesMenu(param1);
					return 0;
				}

				for (int i = 0; i < g_TotalParties; i++) {
					g_Party[i].RemovePlayer(param1);
				}

				g_Party[room].AddPlayer(param1);
				PrintToChat(param1, "You have joined the room.");
			}

			OpenPartiesMenu(param1);
		}
		
		case MenuAction_End: {
			delete menu;
		}
	}
	
	return 0;
}

public int Native_IsEnabled(Handle plugin, int numParams) {
	return convar_Enabled.BoolValue;
}

public int Native_GetClients(Handle plugin, int numParams) {
	int room = GetNativeCell(1);

	if (room < 0 || room >= g_TotalParties) {
		return view_as<int>(INVALID_HANDLE); //Null = Error
	}

	return view_as<int>(g_Party[room].players);
}

public int Native_GetParty(Handle plugin, int numParams) {
	int client = GetNativeCell(1);

	if (client < 1 || client > MaxClients) {
		return NO_ROOM;
	}

	for (int i = 0; i < g_TotalParties; i++) {
		if (g_Party[i].IsInParty(client)) {
			return i;
		}
	}

	return NO_ROOM;
}

public void OnClientDisconnect_Post(int client) {
	for (int i = 0; i < g_TotalParties; i++) {
		g_Party[i].RemovePlayer(client);
	}
}