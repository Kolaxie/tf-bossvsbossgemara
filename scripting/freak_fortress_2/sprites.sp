int g_Sprite[MAXPLAYERS + 1] = {-1, ...};

#define SPRITE_BLUE "materials/effects/powerup_supernova_icon_blue.vmt"
#define SPRITE_BLUE_MTRL "materials/effects/powerup_supernova_icon_blue.vtf"
#define SPRITE_RED "materials/effects/powerup_supernova_icon_red.vmt"
#define SPRITE_RED_MTRL "materials/effects/powerup_supernova_icon_red.vtf"

int AttachSprite(int client, const char[] sprite, float offset = 25.0) {
	float origin[3];
	GetClientAbsOrigin(client, origin);

	origin[2] += offset;

	int entity = CreateSprite(origin, sprite);

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client, entity, 0);

	g_Sprite[client] = entity;

	return entity;
}

int CreateSprite(float origin[3], const char[] sprite) {
	int entity = CreateEntityByName("env_sprite_oriented");

	if (!IsValidEntity(entity)) {
		return entity;
	}

	DispatchKeyValue(entity, "classname", "env_sprite_oriented");
	DispatchKeyValueVector(entity, "origin", origin);
	DispatchKeyValue(entity, "model", sprite);
	DispatchKeyValueInt(entity, "spawnflags", 1);
	DispatchKeyValueFloat(entity, "scale", 0.25);
	DispatchKeyValueInt(entity, "rendermode", 0);
	DispatchKeyValueInt(entity, "renderfx", 0); 
	DispatchKeyValueInt(entity, "renderamt", 255); 
	DispatchKeyValue(entity, "rendercolor", "255 255 255");
	DispatchKeyValueInt(entity, "disablereceiveshadows", 1);
	DispatchSpawn(entity);
	ActivateEntity(entity);
	
	TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);

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

stock bool ReorientAllSprites() {
	bool found;

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientConnected(i) || !IsClientInGame(i) || !IsPlayerAlive(i)) {
			continue;
		}

		if (ReorientSprite(i)) {
			found = true;
		}
	}

	return found;
}

bool ReorientSprite(int client) {
	if (client < 1 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client)) {
		return false;
	}

	int entity = g_Sprite[client];

	if (entity > MaxClients && IsValidEntity(entity))
	{
		float origin[3];
		GetClientEyePosition(client, origin);

		origin[2] += 25.0;

		float velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

		TeleportEntity(entity, origin, NULL_VECTOR, velocity);

		return true;
	}

	return false;
}

public void OnGameFrame() {
	//ReorientAllSprites();
}

void Sprites_MapStart() {
	PrecacheGeneric(SPRITE_BLUE);
	PrecacheGeneric(SPRITE_BLUE_MTRL);
	PrecacheGeneric(SPRITE_RED);
	PrecacheGeneric(SPRITE_RED_MTRL);
}