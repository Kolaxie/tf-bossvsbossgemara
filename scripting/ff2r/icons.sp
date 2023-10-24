void CreateIcon(client, const char[] sprite, float offset)
{
	KillIcon(client);
	
	char name[64]; 
	Format(name, sizeof(name), "client%i", client);
	DispatchKeyValue(client, "targetname", name);

	float origin[3];
	GetClientAbsOrigin(client, origin);
	origin[2] += offset;

	int entity = CreateEntityByName("env_sprite_oriented");
	
	if (IsValidEntity(entity))
	{
		DispatchKeyValue(entity, "model", sprite);
		DispatchKeyValue(entity, "classname", "env_sprite_oriented");
		DispatchKeyValue(entity, "spawnflags", "1");
		DispatchKeyValue(entity, "scale", "0.1");
		DispatchKeyValue(entity, "rendermode", "1");
		DispatchKeyValue(entity, "rendercolor", "255 255 255");
		DispatchKeyValue(entity, "targetname", "donator_spr");
		DispatchKeyValue(entity, "parentname", name);
		DispatchSpawn(entity);
		
		TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);

		g_Icons[client] = entity;
	}
}

void KillIcon(int client)
{
	if (g_Icons[client] > 0 && IsValidEntity(g_Icons[client]))
	{
		AcceptEntityInput(g_Icons[client], "kill");
		g_Icons[client] = 0;
	}
}

void Icons_ClientDisconnect(int client) {
	KillIcon(client);
}

void Icons_MapStart() {
	PrecacheGeneric(ICON_MATERIAL_VTF);
	PrecacheGeneric(ICON_MATERIAL_VMT);
}