#if defined _bvb_rounds_included
	#endinput
#endif
#define _bvb_rounds_included

native bool BVBRounds_IsSpecialRound();
native int BVBRounds_GetClient();
native int BVBRounds_GetPickedBoss();
native bool BVBRounds_IsUltraRound();
native int BVBRounds_GetUltraClient();
native int BVBRounds_GetUltraBoss();

public SharedPlugin __pl_bvb_rounds =
{
	name = "bvb-rounds",
	file = "bvb-rounds.smx",
	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_bvb_rounds_SetNTVOptional()
{
	MarkNativeAsOptional("BVBRounds_IsSpecialRound");
	MarkNativeAsOptional("BVBRounds_GetClient");
	MarkNativeAsOptional("BVBRounds_GetPickedBoss");
	MarkNativeAsOptional("BVBRounds_IsUltraRound");
	MarkNativeAsOptional("BVBRounds_GetUltraClient");
	MarkNativeAsOptional("BVBRounds_GetUltraBoss");
}
#endif
