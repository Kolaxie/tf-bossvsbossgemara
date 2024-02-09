#if defined _ff2_party_included
	#endinput
#endif
#define _ff2_party_included

#define NO_ROOM -1

native ArrayList FF2Party_GetClients(int room);
native int FF2Party_GetParty(int client);

public SharedPlugin __pl_ff2_party =
{
	name = "ff2-party",
	file = "ff2-party.smx",
	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_ff2_party_SetNTVOptional()
{
	MarkNativeAsOptional("FF2Party_GetClients");
	MarkNativeAsOptional("FF2Party_GetParty");
}
#endif
