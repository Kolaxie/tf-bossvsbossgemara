int g_Sprite[MAXPLAYERS + 1] = {-1, ...};

#define SPRITE_BLUE "materials/effects/powerup_supernova_icon_blue.vmt"
#define SPRITE_BLUE_MTRL "materials/effects/powerup_supernova_icon_blue.vtf"
#define SPRITE_RED "materials/effects/powerup_supernova_icon_red.vmt"
#define SPRITE_RED_MTRL "materials/effects/powerup_supernova_icon_red.vtf"
#define PARTICLE_RED "powerup_icon_supernova_red"
#define PARTICLE_BLUE "powerup_icon_supernova_blue"

int AttachSprite(int client, const char[] sprite, float offset = 25.0) {
	float origin[3];
	GetClientEyePosition(client, origin);

	origin[2] += offset;

	int entity = CreateSprite(origin, sprite);

	if (!IsValidEntity(entity)) {
		return entity;
	}

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client, entity, 0);

	g_Sprite[client] = entity;

	return entity;
}

int CreateSprite(float origin[3], const char[] sprite) {
	int entity = CreateEntityByName("info_particle_system");

	if (!IsValidEntity(entity)) {
		return entity;
	}

	DispatchKeyValueVector(entity, "origin", origin);
	DispatchKeyValueVector(entity, "angles", view_as<float>({0.0, 0.0, 0.0}));
	DispatchKeyValue(entity, "effect_name", sprite);
	DispatchKeyValueInt(entity, "start_active", 1);
	DispatchSpawn(entity);
	ActivateEntity(entity);
	
	TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
	//PrintToChatAll("Sprite created!");

	return entity;
}

bool RemoveSprite(int client) {
	if (g_Sprite[client] > -1) {
		KillSprite(g_Sprite[client]);
		g_Sprite[client] = -1;
		return true;
	}

	return false;
}

bool KillSprite(int sprite) {
	if (sprite > MaxClients && IsValidEntity(sprite)) {
		AcceptEntityInput(sprite, "kill");
		return true;
	}

	return false;
}

void Sprites_MapStart() {
	PrecacheGeneric(SPRITE_BLUE);
	PrecacheGeneric(SPRITE_BLUE_MTRL);
	PrecacheGeneric(SPRITE_RED);
	PrecacheGeneric(SPRITE_RED_MTRL);
}