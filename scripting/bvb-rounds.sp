#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <adminmenu>
#include <morecolors>
#include <textstore>
#include <ff2r>
#include <debugger>
#include <morecolors>

#define TEXTSTORE_ITEM "Raid Boss - "

ConVar convar_Enabled;
ConVar convar_Chance;
ConVar convar_Chance_Ultra;
ConVar convar_Max;
ConVar convar_Cooldown;

Database g_Database;
bool g_IsSQLite;
bool g_IsFF2Loaded;

enum struct PluginData {
	bool enabled;			// Whether the current round is enabled to be special or not.
	int client;				// The client that is playing the current round on the special team.
	int boss;				// The boss they are playing as.

	bool nextround;			// Whether the next round is enabled to be special or not.
	int nextroundclient;	// The client that is playing the next round on the special team.
	int nextroundboss;		// The boss they picked for next round.

	int amount;				// The amount of rounds that have been played this map.

	bool ultra;				// Whether the current round is an ultra round or not.
	int ultraclient;		// The client that is playing an ultra boss this round if enabled.
	int ultraboss;			// The boss the client is for the ultra round.
	bool forceultra;		// Forces the next round to be ultra no matter what.

	void Init() {
		this.enabled = false;
		this.client = 0;
		this.boss = 0;

		this.nextround = false;
		this.nextroundclient = 0;
		this.nextroundboss = 0;

		this.amount = 0;

		this.ultra = false;
		this.ultraclient = 0;
		this.ultraboss = 0;
		this.forceultra = false;
	}

	void Clear() {
		this.enabled = false;
		this.client = 0;
		this.boss = 0;

		this.nextround = false;
		this.nextroundclient = 0;
		this.nextroundboss = 0;

		this.amount = 0;

		this.ultra = false;
		this.ultraclient = 0;
		this.ultraboss = 0;
		this.forceultra = false;
	}
}

PluginData g_Data;

float g_Cooldown[MAXPLAYERS + 1];

TopMenu g_AdminMenu;
TopMenuObject g_AdminMenuObj;

public Plugin myinfo = {
	name = "[BvB] Rounds",
	author = "Drixevel",
	description = "Specialized rounds for the BvB system.",
	version = "1.0.0",
	url = "https://drixevel.dev/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("bvb-rounds");

	CreateNative("BVBRounds_IsSpecialRound", Native_IsSpecialRound);
	CreateNative("BVBRounds_GetClient", Native_GetClient);
	CreateNative("BVBRounds_GetPickedBoss", Native_GetPickedBoss);
	CreateNative("BVBRounds_IsUltraRound", Native_IsUltraRound);
	CreateNative("BVBRounds_GetUltraClient", Native_IsUltraClient);
	CreateNative("BVBRounds_GetUltraBoss", Native_IsUltraBoss);

	return APLRes_Success;
}

public void OnPluginStart() {
	Database.Connect(OnSQLConnect, "default");

	CreateConVar("sm_bvb_rounds_version", "1.0.0", "Version control for this plugin.", FCVAR_DONTRECORD);
	convar_Enabled = CreateConVar("sm_bvb_rounds_enabled", "1", "Should this plugin be enabled or disabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_Chance = CreateConVar("sm_bvb_rounds_chance", "0.25", "What's the chance that a special around occurs per map?\n(0.0 = 0%, 1.0 = 100%, 0.50 = 50%)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_Chance_Ultra = CreateConVar("sm_bvb_rounds_chance_ultra", "0.25", "What's the chance of a special round being an ultra round?\n(0.0 = 0%, 1.0 = 100%, 0.50 = 50%)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_Max = CreateConVar("sm_bvb_rounds_max", "1", "What's the maximum amount of rounds available per map for a special round to occur?", FCVAR_NOTIFY, true, 0.0);
	convar_Cooldown = CreateConVar("sm_bvb_rounds_cooldown", "10800", "What's the cooldown a player should have for manually starting a round in seconds?\n(60 seconds = 1 minute)", FCVAR_NOTIFY, true, 0.0);
	//AutoExecConfig();

	g_Data.Init();

	HookEvent("teamplay_round_win", Event_OnRoundEnd);

	RegAdminCmd("sm_raid", AdminCmd_RaidRound, ADMFLAG_GENERIC, "Starts a raid round.");
	RegAdminCmd("sm_raidround", AdminCmd_RaidRound, ADMFLAG_GENERIC, "Starts a raid round.");
	RegAdminCmd("sm_startraid", AdminCmd_RaidRound, ADMFLAG_GENERIC, "Starts a raid round.");
	RegAdminCmd("sm_startraidround", AdminCmd_RaidRound, ADMFLAG_GENERIC, "Starts a raid round.");
	RegAdminCmd("sm_ultra", AdminCmd_UltraRound, ADMFLAG_GENERIC, "Starts an ultra round.");
	RegAdminCmd("sm_ultraround", AdminCmd_UltraRound, ADMFLAG_GENERIC, "Starts an ultra round.");
	RegAdminCmd("sm_startultra", AdminCmd_UltraRound, ADMFLAG_GENERIC, "Starts an ultra round.");
	RegAdminCmd("sm_startultraround", AdminCmd_UltraRound, ADMFLAG_GENERIC, "Starts an ultra round.");
}

public void OnAllPluginsLoaded() {
	g_IsFF2Loaded = LibraryExists("freak_fortress_2");
}

public void OnLibraryAdded(const char[] name) {
	if (StrEqual(name, "freak_fortress_2", false)) {
		g_IsFF2Loaded = true;
	}
}

public void OnLibraryRemoved(const char[] name) {
	if (StrEqual(name, "adminmenu", false)) {
		g_AdminMenu = null;
	}

	if (StrEqual(name, "freak_fortress_2", false)) {
		g_IsFF2Loaded = false;
	}
}

public void OnSQLConnect(Database db, const char[] error, any data) {
	if (db == null) {
		ThrowError("Error while connecting to database: %s", error);
	}
	
	g_Database = db;
	LogMessage("Connected to database successfully.");

	char identifier[64];
	g_Database.Driver.GetIdentifier(identifier, sizeof(identifier));

	g_IsSQLite = StrEqual(identifier, "sqlite");

	if (g_IsSQLite) {
		g_Database.Query(OnCreateTable, "CREATE TABLE IF NOT EXISTS bvb_specialrounds (id INTEGER PRIMARY KEY AUTOINCREMENT, accountid INTEGER UNIQUE, cooldown TIMESTAMP);", DBPrio_Low);
	} else {
		g_Database.Query(OnCreateTable, "CREATE TABLE IF NOT EXISTS bvb_specialrounds (id INTEGER PRIMARY KEY AUTO_INCREMENT, accountid BIGINT(64) UNIQUE, cooldown TIMESTAMP);", DBPrio_Low);
	}
}

public void OnCreateTable(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		ThrowError("Error while creating table: %s", error);
	}
}

public void OnClientAuthorized(int client, const char[] auth) {
	if (!convar_Enabled.BoolValue) {
		return;
	}

	if (g_Database != null) {
		char query[256];
		g_Database.Format(query, sizeof(query), "SELECT cooldown FROM bvb_specialrounds WHERE accountid = %d;", GetSteamAccountID(client));
		g_Database.Query(OnLoadCooldown, query, GetClientUserId(client), DBPrio_Low);
	}
}

public void OnLoadCooldown(Database db, DBResultSet results, const char[] error, any data) {
	if (!convar_Enabled.BoolValue) {
		return;
	}

	int client = GetClientOfUserId(data);

	if (client < 1) {
		return;
	}

	if (results == null) {
		ThrowError("Error while loading player cooldown: %s", error);
	}

	if (results.FetchRow()) {
		g_Cooldown[client] = results.FetchFloat(0);
	}
}

public void OnClientDisconnect_Post(int client) {
	g_Cooldown[client] = 0.0;

	if (g_Data.nextroundclient > 0 && GetClientOfUserId(g_Data.nextroundclient) == client) {
		g_Data.nextround = false;
		g_Data.nextroundclient = 0;
		g_Data.nextroundboss = 0;
	}
}

public void OnMapEnd() {
	g_Data.Clear();
}

public void FF2R_OnRoundSetup() {
	if (!convar_Enabled.BoolValue) {
		return;
	}

	bool enabled;

	// If the maximum amount of rounds has been reached, don't do anything until it's reset.
	int max = convar_Max.IntValue;
	if (max > 0 && g_Data.amount >= max) {
		return;
	}

	// If there's a setup for next round, use that.
	if (g_Data.nextround) {
		g_Data.nextround = false;

		g_Data.client = GetClientOfUserId(g_Data.nextroundclient);
		g_Data.boss = g_Data.nextroundboss;

		g_Data.nextroundclient = 0;
		g_Data.nextroundboss = 0;

		enabled = true;
		PrintCenterTextAll("A Raid Boss has appeared! Goodluck!");
	}

	// If there's no setup for next round, make a random chance for it to happen this round.
	float chance = convar_Chance.FloatValue;
	if (!enabled && GetRandomFloat(0.0, 1.0) < chance) {
		g_Data.ultra = GetRandomFloat(0.0, 1.0) < convar_Chance_Ultra.FloatValue;

		if (g_Data.forceultra) {
			g_Data.ultra = true;
			g_Data.forceultra = false;
		}

		//raid
		g_Data.client = GetRandomPlayer();
		g_Data.boss = GetRandomBoss(false);

		//ultra
		if (g_Data.ultra) {
			g_Data.ultraclient = GetRandomPlayer();
			g_Data.ultraboss = GetRandomBoss(true);
		}

		enabled = true;
		PrintCenterTextAll("An Ultra Boss has appeared! Chaos inbound!");		
	}

	g_Data.enabled = enabled;
}

int GetRandomBoss(bool ultra) {
	if (!g_IsFF2Loaded) {
		return -1;
	}

	int total = FF2R_Bosses_GetConfigLength();

	int[] bosses = new int[total];
	int count;

	for (int i = 0; i < total; i++) {
		int index = GetRandomInt(0, total - 1);
		ConfigMap boss = FF2R_Bosses_GetConfig(index);

		if (boss == null) {
			continue;
		}

		bool isultra;
		boss.GetBool((ultra ? "ultra" : "raid"), isultra);

		if (!ultra && !isultra) {
			continue;
		}

		bosses[count++] = index;
	}

	if (count == 0) {
		return -1;
	}

	return bosses[GetRandomInt(0, count - 1)];
}

int GetRandomPlayer() {
	int players[MAXPLAYERS + 1];
	int count = 0;

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			players[count] = i;
			count++;
		}
	}

	if (count == 0) {
		return 0;
	}

	return players[GetRandomInt(0, count - 1)];
}

public ItemResult TextStore_Item(int client, bool equipped, KeyValues item, int index, const char[] name, int &count) {
	if (!convar_Enabled.BoolValue) {
		return Item_None;
	}
	
	if (StrContains(name, TEXTSTORE_ITEM, false) == 0) {
		char boss[64];
		item.GetString("boss", boss, sizeof(boss));
		
		int bossIndex = -1;
		if (g_IsFF2Loaded) {
			bossIndex = FF2R_Bosses_GetByName(boss);
		}

		if (bossIndex == -1) {
			return Item_None;
		}

		int max = convar_Max.IntValue;
		if (max > 0 && g_Data.amount >= max) {
			CPrintToChat(client, "{green}[FF2]{default} The maximum amount of Raid this map has been reached.");
			return Item_None;
		}

		float cooldown = convar_Cooldown.FloatValue;
		if (g_Cooldown[client] > 0.0 && !CheckCommandAccess(client, "", ADMFLAG_ROOT, true)) {
			float time = g_Cooldown[client] - GetGameTime();
			if (time > 0.0) {
				char sTime[32];
				FormatSeconds(time, sTime, sizeof(sTime), "%H:%M:%S");
				CPrintToChat(client, "{green}[FF2]{default} You must wait '%s' before forcing a Raid.", sTime);
				return Item_None;
			}
		}

		if (g_Data.nextround) {
			CPrintToChat(client, "{green}[FF2]{default} A Raid round is already in queue.");
			return Item_None;
		}

		g_Data.nextround = true;
		g_Data.nextroundclient = GetClientUserId(client);
		g_Data.nextroundboss = bossIndex;
		g_Cooldown[client] = GetGameTime() + cooldown;

		if (g_Database != null) {
			char query[256];
			if (g_IsSQLite) {
				g_Database.Format(query, sizeof(query), "INSERT OR REPLACE INTO bvb_specialrounds (accountid, cooldown) VALUES (%d, %d);", GetSteamAccountID(client), g_Cooldown[client]);
			} else {
				g_Database.Format(query, sizeof(query), "INSERT INTO bvb_specialrounds (accountid, cooldown) VALUES (%d, %d) ON DUPLICATE KEY UPDATE cooldown = VALUES(cooldown);;", GetSteamAccountID(client), g_Cooldown[client]);
			}
			g_Database.Query(OnStoreCooldown, query, _, DBPrio_Low);
		}

		CPrintToChatAll("{green}[FF2]{default} %N has used a Raid for next round. Pick your boss via /ff2boss and get ready!", client);
		return Item_Used;
	}

	return Item_None;
}

public void OnStoreCooldown(Database db, DBResultSet results, const char[] error, any data) {
	if (results == null) {
		ThrowError("Error while storing player cooldown: %s", error);
	}
}

void FormatSeconds(float seconds, char[] buffer, int maxlength, const char[] format, bool precision = false) {
	int t = RoundToFloor(seconds);

	int day; char sDay[32];
	if (t >= 86400) {
		day = RoundToFloor(t / 86400.0);
		t = t % 86400;

		Format(sDay, sizeof(sDay), "%02d", day);
	}

	int hour; char sHour[32];
	if (t >= 3600) {
		hour = RoundToFloor(t / 3600.0);
		t = t % 3600;

		Format(sHour, sizeof(sHour), "%02d", hour);
	}

	int mins; char sMinute[32];
	if (t >= 60) {
		mins = RoundToFloor(t / 60.0);
		t = t % 60;

		Format(sMinute, sizeof(sMinute), "%02d", mins);
	}

	char sSeconds[32];
	switch (precision) {
		case true: {
			Format(sSeconds, sizeof(sSeconds), "%05.2f", float(t) + seconds - RoundToFloor(seconds));
		}
		case false: {
			Format(sSeconds, sizeof(sSeconds), "%02d", t);
		}
	}

	strcopy(buffer, maxlength, format);

	ReplaceString(buffer, maxlength, "%D", strlen(sDay) > 0 ? sDay : "00");
	ReplaceString(buffer, maxlength, "%H", strlen(sHour) > 0 ? sHour : "00");
	ReplaceString(buffer, maxlength, "%M", strlen(sMinute) > 0 ? sMinute : "00");
	ReplaceString(buffer, maxlength, "%S", strlen(sSeconds) > 0 ? sSeconds : "00");
}

public int Native_IsSpecialRound(Handle plugin, int numParams) {
	return g_Data.enabled;
}

public int Native_GetClient(Handle plugin, int numParams) {
	return g_Data.client;
}

public int Native_GetPickedBoss(Handle plugin, int numParams) {
	return g_Data.boss;
}

public int Native_IsUltraRound(Handle plugin, int numParams) {
	return g_Data.ultra;
}

public int Native_IsUltraClient(Handle plugin, int numParams) {
	return g_Data.ultraclient;
}

public int Native_IsUltraBoss(Handle plugin, int numParams) {
	return g_Data.ultraboss;
}

public void OnAdminMenuCreated(Handle aTopMenu) {
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	if (topmenu == g_AdminMenu && g_AdminMenuObj != INVALID_TOPMENUOBJECT) {
		return;
	}

	g_AdminMenuObj = AddToTopMenu(topmenu, "BvB Special Rounds", TopMenuObject_Category, CategoryHandler, INVALID_TOPMENUOBJECT);
}

public void OnAdminMenuReady(Handle aTopMenu) {
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	if (g_AdminMenuObj == INVALID_TOPMENUOBJECT) {
		OnAdminMenuCreated(topmenu);
	}

	if (topmenu == g_AdminMenu) {
		return;
	}

	g_AdminMenu = topmenu;

	AddToTopMenu(g_AdminMenu, "sm_raidround", TopMenuObject_Item, AdminMenu_RaidRound, g_AdminMenuObj, "sm_raidround", ADMFLAG_ROOT);
	AddToTopMenu(g_AdminMenu, "sm_ultraround", TopMenuObject_Item, AdminMenu_UltraRound, g_AdminMenuObj, "sm_ultraround", ADMFLAG_ROOT);
}

public void CategoryHandler(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength) {
	switch (action) {
		case TopMenuAction_DisplayTitle: {
			strcopy(buffer, maxlength, "BvB Special Rounds");
		}
		case TopMenuAction_DisplayOption: {
			strcopy(buffer, maxlength, "BvB Special Rounds");
		}
	}
}

public void AdminMenu_RaidRound(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength) {
	switch (action) {
		case TopMenuAction_DisplayOption: {
			strcopy(buffer, maxlength, "Start a Raid Round");
		}
		case TopMenuAction_SelectOption: {
			FakeClientCommand(param, "sm_raidround");
		}
	}
}

public void AdminMenu_UltraRound(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength) {
	switch (action) {
		case TopMenuAction_DisplayOption: {
			strcopy(buffer, maxlength, "Start an Ultra Round");
		}
		case TopMenuAction_SelectOption: {
			FakeClientCommand(param, "sm_ultraround");
		}
	}
}

public void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast) {
	g_Data.enabled = false;

	g_Data.client = 0;
	g_Data.boss = 0;

	g_Data.ultra = false;
	g_Data.ultraclient = 0;
	g_Data.ultraboss = 0;
}

public Action AdminCmd_RaidRound(int client, int args) {
	if (g_Data.nextround) {
		CPrintToChat(client, "{green}[FF2]{default} A raid round is already queued up.");
		return Plugin_Handled;
	}

	g_Data.nextround = true;
	g_Data.nextroundclient = GetClientUserId(GetRandomPlayer());
	g_Data.nextroundboss = GetRandomBoss(false);
	
	CPrintToChatAll("{green}[FF2]{default} %N is starting up a raid round for next round.", client);

	return Plugin_Handled;
}

public Action AdminCmd_UltraRound(int client, int args) {
	if (g_Data.ultra) {
		CPrintToChat(client, "{green}[FF2]{default} An ultra round is already queued up.");
		return Plugin_Handled;
	}

	g_Data.nextround = true;
	g_Data.nextroundclient = GetClientUserId(GetRandomPlayer());
	g_Data.nextroundboss = GetRandomBoss(false);
	g_Data.forceultra = true;
	
	CPrintToChatAll("{green}[FF2]{default} %N is starting up an ultra round for next round.", client);

	return Plugin_Handled;
}