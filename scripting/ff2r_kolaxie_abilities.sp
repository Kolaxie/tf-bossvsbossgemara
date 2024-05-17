#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <cfgmap>
#include <ff2r>

Handle g_Cinematic[MAXPLAYERS + 1];
int g_CinematicCamera[MAXPLAYERS + 1];

public Plugin myinfo = {
	name = "[FF2] Kolaxie Abilities",
	author = "Drixevel",
	description = "Abilities for Freak Fortress 2 for Kolaxie made by Drixevel.",
	version = "1.0.0",
	url = "https://drixevel.dev/"
};

public void OnPluginStart() {
	HookEvent("player_death", Event_OnPlayerDeath);

	for(int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
	{
		if(IsClientInGame(clientIdx))
		{
			BossData cfg = FF2R_GetBossData(clientIdx);			
			if(cfg)
				FF2R_OnBossCreated(clientIdx, cfg, false);
		}
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2]) {
	BossData boss = FF2R_GetBossData(client);
	AbilityData ability;
	if (boss && (ability = boss.GetAbility("cinematic"))) {
		char animation[64];
		if (!ability.GetString("animation", animation, sizeof(animation))) {
			return Plugin_Continue;
		}

		SetAnimation(client, animation);

		bool frozen;
		if ((frozen = ability.GetBool("freeze_inputs"))) {
			TF2_AddCondition(client, TFCond_FreezeInput, TFCondDuration_Infinite);
		}

		bool camera;
		if ((camera = ability.GetBool("camera"))) {
			CreateCamera(client);
			int cameraent = g_CinematicCamera[client];

			char sWatcher[MAX_NAME_LENGTH];
			GetClientName(client, sWatcher, sizeof(sWatcher));

			for (int i = 1; i <= MaxClients; i++) {
				if (IsClientInGame(i) && !IsFakeClient(i)) {
					SetEntProp(i, Prop_Send, "m_iObserverMode", 1);
					SetClientViewEntity(i, client);

					SetVariantString(sWatcher); 
					AcceptEntityInput(cameraent, "Enable", i, cameraent, 0);
				}
			}
		}

		float time = ability.GetFloat("time");

		if (time < 0.0) {
			time = 0.0;
		}

		StopTimer(g_Cinematic[client]);

		DataPack pack;
		g_Cinematic[client] = CreateDataTimer(time, Timer_StopCinematic, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(frozen);
		pack.WriteCell(camera);
	}

	return Plugin_Continue;
}

public void FF2R_OnAbility(int clientIdx, const char[] ability, AbilityData cfg) {
	if (!cfg.IsMyPlugin())
		return;
	
	if (!cfg.GetBool("enabled", true))
		return;
	
	/**
		"ff2_skybox"
		{
			"slot" "0"
			"skybox" "sky_alpinestorm_01"

			"plugin_name"    "ff2r_kolaxie_abilities"
		}
	*/

	char skybox[64];
	if (StrContains(ability, "ff2_skybox", false) == 0 && cfg.GetString("skybox", skybox, sizeof(skybox))) {
		SetSkybox(skybox);
	}

	char config[64];
	if (StrEqual(ability, "ff2_bossconf", false) && cfg.GetString("boss_name", config, sizeof(config)) > 0 && cfg.GetInt("slot") == 0) {
		int special = FF2R_Bosses_GetByName(config);

		if (special == -1) {
			return;
		}

		ConfigMap newcfg = FF2R_Bosses_GetConfig(special);

		if (newcfg == null) {
			return;
		}
		
		FF2R_SetBossData(clientIdx, newcfg, true);
	}
}

void SetSkybox(const char[] skybox) {
	ConVar sv_skyname = FindConVar("sv_skyname");

	if (sv_skyname == null) {
		return;
	}

	sv_skyname.SetString(skybox);

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			SendConVarValue(i, sv_skyname, skybox);
		}
	}
}

public Action Timer_StopCinematic(Handle timer, DataPack pack) {
	pack.Reset();

	int userid = pack.ReadCell();
	bool frozen = pack.ReadCell();
	bool camera = pack.ReadCell();

	int client;
	if ((client = GetClientOfUserId(userid)) == 0) {
		return Plugin_Continue;
	}

	if (!IsClientInGame(client) || !IsPlayerAlive(client)) {
		g_Cinematic[client] = null;
		return Plugin_Continue;
	}

	if (frozen) {
		TF2_RemoveCondition(client, TFCond_FreezeInput);
	}
	
	if (camera) {
		int cameraent = g_CinematicCamera[client];

		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
				SetEntProp(i, Prop_Send, "m_iObserverMode", 0);
				SetClientViewEntity(i, i);
				AcceptEntityInput(cameraent, "Disable", i, cameraent, 0);
			}
		}

		DestroyCamera(client);
	}

	g_Cinematic[client] = null;
	return Plugin_Continue;
}

public void OnClientDisconnect(int client) {
	StopTimer(g_Cinematic[client]);
}

public void FF2R_OnBossCreated(int clientIdx, BossData cfg, bool setup)
{
	AbilityData ability = cfg.GetAbility("ff2_steamid_skins");

	if (!ability.IsMyPlugin())
		return;
		
	if (!ability.GetBool("enabled", true))
		return;
	
	/**
		"ff2_steamid_skins"
		{
			"plugin_name"    "ff2r_kolaxie_abilities"

			"steamids"
			{
				"STEAM:0:blabla"   "0"
				"STEAM:0:helloworld"   "1"
			}
		}
	*/
	
	ConfigData steamids = cfg.GetSection("steamids");
	if(steamids) {
		int skin = cfg.GetInt(GetSteamID(clientIdx));
		SetEntProp(clientIdx, Prop_Send, "m_nSkin", skin);
		DispatchKeyValueInt(clientIdx, "skin", skin);
	}
}

char[] GetSteamID(int client) {
	char steamid[64];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	return steamid;
}

public void FF2R_OnBossRemoved(int client) {
	StopTimer(g_Cinematic[client]);
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client == 0) {
		return;
	}

	StopTimer(g_Cinematic[client]);
}

void CreateCamera(int client) {
	int entity = CreateEntityByName("point_viewcontrol");

	if (!IsValidEntity(entity)) {
		return;
	}

	char sCamName[64]; 
	Format(sCamName, sizeof(sCamName), "CinematicCam%d", client);
	DispatchKeyValue(entity, "targetname", sCamName);
	
	char sWatcher[64]; 
	GetClientName(client, sWatcher, sizeof(sWatcher));
	DispatchKeyValue(client, "targetname", sWatcher); 
	
	float fAngles[3];
	char sCamAngles[64];
	Format(sCamAngles, sizeof(sCamAngles), "%f %f %f", fAngles[0], fAngles[1], fAngles[2]);
	DispatchKeyValue(entity, "angles", sCamAngles);
	
	DispatchKeyValue(entity, "LagCompensate", "1");
	DispatchKeyValue(entity, "MoveType", "8");
	DispatchKeyValue(entity, "fov", "100");
	DispatchKeyValue(entity, "spawnflags", "64");
	DispatchSpawn(entity);

	SetVariantString("head");
	AcceptEntityInput(entity, "SetParentAttachment");

	float fPos[3];
	TeleportEntity(entity, fPos, NULL_VECTOR, NULL_VECTOR);
	
	g_CinematicCamera[client] = EntIndexToEntRef(entity);
}

void DestroyCamera(int client) {
	if (g_CinematicCamera[client] != 0) {
		RemoveEntity(g_CinematicCamera[client]);
		g_CinematicCamera[client] = 0;
	}
}

void SetAnimation(int client, const char[] animation) {
	SetVariantString(animation);
	AcceptEntityInput(client, "SetAnimation");
}

bool StopTimer(Handle& timer) {
	if (timer != null) {
		KillTimer(timer);
		timer = null;
		return true;
	}
	
	return false;
}