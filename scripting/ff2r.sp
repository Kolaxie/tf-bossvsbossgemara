/*
	Here we go again
		-Batfoxkid
*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <adminmenu>
#include <clientprefs>
#include <adt_trie_sort>
#include <cfgmap>
#include <morecolors>
#include <dhooks>
#include <tf2items>
#include <tf2attributes>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN

#define PLUGIN_VERSION			"1.0.0"

#define FILE_CHARACTERS	"data/freak_fortress_2/characters.cfg"
#define FOLDER_CONFIGS	"configs/freak_fortress_2"

#define MAJOR_REVISION	1
#define MINOR_REVISION	11
#define STABLE_REVISION	0

#define GITHUB_URL	"github.com/Batfoxkid/Freak-Fortress-2-Rewrite"

#define FAR_FUTURE		100000000.0
#define MAXENTITIES		2048
#define MAXTF2PLAYERS	MAXPLAYERS+1

#define TFTeam_Unassigned	0
#define TFTeam_Spectator	1
#define TFTeam_Red			2
#define TFTeam_Blue			3
#define TFTeam_MAX			4

enum TFStatType_t
{
	TFSTAT_UNDEFINED = 0,
	TFSTAT_SHOTS_HIT,
	TFSTAT_SHOTS_FIRED,
	TFSTAT_KILLS,
	TFSTAT_DEATHS,
	TFSTAT_DAMAGE,
	TFSTAT_CAPTURES,
	TFSTAT_DEFENSES,
	TFSTAT_DOMINATIONS,
	TFSTAT_REVENGE,
	TFSTAT_POINTSSCORED,
	TFSTAT_BUILDINGSDESTROYED,
	TFSTAT_HEADSHOTS,
	TFSTAT_PLAYTIME,
	TFSTAT_HEALING,
	TFSTAT_INVULNS,
	TFSTAT_KILLASSISTS,
	TFSTAT_BACKSTABS,
	TFSTAT_HEALTHLEACHED,
	TFSTAT_BUILDINGSBUILT,
	TFSTAT_MAXSENTRYKILLS,
	TFSTAT_TELEPORTS,
	TFSTAT_FIREDAMAGE,
	TFSTAT_BONUS_POINTS,
	TFSTAT_BLASTDAMAGE,
	TFSTAT_DAMAGETAKEN,
	TFSTAT_HEALTHKITS,
	TFSTAT_AMMOKITS,
	TFSTAT_CLASSCHANGES,
	TFSTAT_CRITS,
	TFSTAT_SUICIDES,
	TFSTAT_CURRENCY_COLLECTED,
	TFSTAT_DAMAGE_ASSIST,
	TFSTAT_HEALING_ASSIST,
	TFSTAT_DAMAGE_BOSS,
	TFSTAT_DAMAGE_BLOCKED,
	TFSTAT_DAMAGE_RANGED,
	TFSTAT_DAMAGE_RANGED_CRIT_RANDOM,
	TFSTAT_DAMAGE_RANGED_CRIT_BOOSTED,
	TFSTAT_REVIVED,
	TFSTAT_THROWABLEHIT,
	TFSTAT_THROWABLEKILL,
	TFSTAT_KILLSTREAK_MAX,
	TFSTAT_KILLS_RUNECARRIER,
	TFSTAT_FLAGRETURNS,
	TFSTAT_TOTAL
};

enum
{
	WINREASON_NONE = 0,
	WINREASON_ALL_POINTS_CAPTURED,
	WINREASON_OPPONENTS_DEAD,
	WINREASON_FLAG_CAPTURE_LIMIT,
	WINREASON_DEFEND_UNTIL_TIME_LIMIT,
	WINREASON_STALEMATE,
	WINREASON_TIMELIMIT,
	WINREASON_WINLIMIT,
	WINREASON_WINDIFFLIMIT,
	WINREASON_RD_REACTOR_CAPTURED,
	WINREASON_RD_CORES_COLLECTED,
	WINREASON_RD_REACTOR_RETURNED,
	WINREASON_PD_POINTS,
	WINREASON_SCORED,
	WINREASON_STOPWATCH_WATCHING_ROUNDS,
	WINREASON_STOPWATCH_WATCHING_FINAL_ROUND,
	WINREASON_STOPWATCH_PLAYING_ROUNDS,
	WINREASON_CUSTOM_OUT_OF_TIME
};

enum SectionType
{
	Section_Unknown = 0,
	Section_Ability,	// ability | Ability Name
	Section_Map,		// map_
	Section_Weapon,		// weapon | wearable | tf_ | saxxy
	Section_Sound,		// sound_ | catch_
	Section_ModCache,	// mod_precache
	Section_Precache,	// precache
	Section_Download,	// download
	Section_Model,		// mod_download
	Section_Material	// mat_download
};

enum struct SoundEnum
{
	char Sound[PLATFORM_MAX_PATH];
	char Name[64];
	char Artist[64];
	float Time;
	
	char Overlay[PLATFORM_MAX_PATH];
	float Duration;
	
	int Entity;
	int Channel;
	int Level;
	int Flags;
	float Volume;
	int Pitch;
	
	void Default()
	{
		this.Entity = SOUND_FROM_PLAYER;
		this.Channel = SNDCHAN_AUTO;
		this.Level = SNDLEVEL_NORMAL;
		this.Flags = SND_NOFLAGS;
		this.Volume = SNDVOL_NORMAL;
		this.Pitch = SNDPITCH_NORMAL;
	}
}

public const char SndExts[][] = { ".mp3", ".wav" };

public const int TeamColors[][] =
{
	{255, 255, 100, 255},
	{100, 255, 100, 255},
	{255, 100, 100, 255},
	{100, 100, 255, 255}
};

enum
{
	Version,
	NextCharset,
	Debugging,
	
	AggressiveOverlay,
	AggressiveSwap,

	SubpluginFolder,
	FileCheck,
	
	SoundType,
	BossTriple,
	BossCrits,
	BossHealing,
	BossKnockback,
	
	BossVsBoss,
	SpecTeam,
	CaptureTime,
	CaptureAlive,
	HealthBar,
	RefreshDmg,
	RefreshTime,
	DisguiseModels,
	PlayerGlow,
	BossSewer,
	Telefrags,
	
	PrefBlacklist,
	PrefToggle,
	PrefSpecial,
	
	AllowSpectators,
	MovementFreeze,
	PreroundTime,
	//BonusRoundTime,
	Tournament,
	WaitingTime,
	
	Cvar_MAX
}

ConVar Cvar[Cvar_MAX];

int PlayersAlive[TFTeam_MAX];
int MaxPlayersAlive[TFTeam_MAX];
int Charset;
bool Enabled;
int RoundStatus;
bool PluginsEnabled;
Handle PlayerHud;
Handle ThisPlugin;

#include "ff2r/client.sp"
#include "ff2r/stocks.sp"

#include "ff2r/attributes.sp"
#include "ff2r/bosses.sp"
#include "ff2r/commands.sp"
#include "ff2r/configs.sp"
#include "ff2r/convars.sp"
#include "ff2r/database.sp"
#include "ff2r/dhooks.sp"
#include "ff2r/econdata.sp"
#include "ff2r/events.sp"
#include "ff2r/formula_parser.sp"
#include "ff2r/forwards.sp"
#include "ff2r/forwards_old.sp"
#include "ff2r/gamemode.sp"
#include "ff2r/goomba.sp"
#include "ff2r/menu.sp"
#include "ff2r/music.sp"
#include "ff2r/natives.sp"
#include "ff2r/natives_old.sp"
#include "ff2r/preference.sp"
#include "ff2r/sdkcalls.sp"
#include "ff2r/sdkhooks.sp"
#include "ff2r/steamworks.sp"
#include "ff2r/tf2utils.sp"
#include "ff2r/weapons.sp"

public Plugin myinfo =
{
	name		=	"[TF2] Boss vs Boss Gemara",
	author		=	"Batfoxkid, many others and forked by Drixevel & Kolaxie",
	description	=	"Fork of the FF2 mode to allow for custom boss vs boss matches.",
	version		=	PLUGIN_VERSION,
	url			=	"https://sourcemod.net/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char plugin[PLATFORM_MAX_PATH];
	GetPluginFilename(myself, plugin, sizeof(plugin));
	if(!StrContains(plugin, "freaks", false))
		return APLRes_SilentFailure;
	
	ThisPlugin = myself;
	
	Forward_PluginLoad();
	ForwardOld_PluginLoad();
	Native_PluginLoad();
	NativeOld_PluginLoad();
	TF2U_PluginLoad();
	TFED_PluginLoad();
	Weapons_PluginLoad();
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("ff2_rewrite.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	if(!TranslationPhraseExists("Difficulty Menu"))
		SetFailState("Translation file \"ff2_rewrite.phrases\" is outdated");
	
	PlayerHud = CreateHudSynchronizer();
	
	Attributes_PluginStart();
	Bosses_PluginStart();
	Command_PluginStart();
	ConVar_PluginStart();
	Database_PluginStart();
	DHook_Setup();
	Events_PluginStart();
	Gamemode_PluginStart();
	Menu_PluginStart();
	Music_PluginStart();
	Preference_PluginStart();
	SDKCall_Setup();
	SDKHook_PluginStart();
	SteamWorks_PluginStart();
	TF2U_PluginStart();
	TFED_PluginStart();
	Weapons_PluginStart();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public void OnAllPluginsLoaded()
{
	Configs_AllPluginsLoaded();
}

public void OnMapInit()
{
	Gamemode_MapInit();
}

public void OnMapStart()
{
	Configs_MapStart();
	DHook_MapStart();
	Gamemode_MapStart();
}

public void OnConfigsExecuted()
{
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	if(Configs_SetMap(mapname))
	{
		Charset = Cvar[NextCharset].IntValue;
	}
	else
	{
		Charset = -1;
	}
	
	Bosses_BuildPacks(Charset, mapname);
	ConVar_ConfigsExecuted();
	Preference_ConfigsExecuted();
	Weapons_ConfigsExecuted();
}

public void OnMapEnd()
{
	Bosses_MapEnd();
	Gamemode_MapEnd();
	Preference_MapEnd();
}

public void OnPluginEnd()
{
	Bosses_PluginEnd();
	ConVar_Disable();
	Database_PluginEnd();
	DHook_PluginEnd();
	Gamemode_PluginEnd();
	Music_PlaySongToAll();
}

public void OnLibraryAdded(const char[] name)
{
	SDKHook_LibraryAdded(name);
	SteamWorks_LibraryAdded(name);
	TF2U_LibraryAdded(name);
	TFED_LibraryAdded(name);
	Weapons_LibraryAdded(name);
}

public void OnLibraryRemoved(const char[] name)
{
	SDKHook_LibraryRemoved(name);
	SteamWorks_LibraryRemoved(name);
	TF2U_LibraryRemoved(name);
	TFED_LibraryRemoved(name);
	Weapons_LibraryRemoved(name);
}

public void OnClientPutInServer(int client)
{
	DHook_HookClient(client);
	SDKHook_HookClient(client);
}

public void OnClientPostAdminCheck(int client)
{
	Database_ClientPostAdminCheck(client);
}

public void OnClientDisconnect(int client)
{
	Bosses_ClientDisconnect(client);
	Database_ClientDisconnect(client);
	Events_CheckAlivePlayers(client);
	Preference_ClientDisconnect(client);
	
	Client(client).ResetByAll();
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	Bosses_PlayerRunCmd(client, buttons);
	Gamemode_PlayerRunCmd(client, buttons);
	Music_PlayerRunCmd(client);
	return Plugin_Continue;
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if(!Client(client).IsBoss || Client(client).Crits || TF2_IsCritBoosted(client))
		return Plugin_Continue;
	
	result = false;
	return Plugin_Changed;
}

public void TF2_OnConditionAdded(int client, TFCond cond)
{
	Gamemode_ConditionAdded(client, cond);
}

public void TF2_OnConditionRemoved(int client, TFCond cond)
{
	Gamemode_ConditionRemoved(client, cond);
}