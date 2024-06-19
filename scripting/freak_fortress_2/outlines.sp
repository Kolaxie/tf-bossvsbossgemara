int g_Glow[MAXPLAYERS + 1] = {-1, ...};

stock int TF2_CreateGlow(int target, int color[4] = {255, 255, 255, 255}) {
	char sClassname[64];
	GetEntityClassname(target, sClassname, sizeof(sClassname));

	char sTarget[128];
	Format(sTarget, sizeof(sTarget), "%s%i", sClassname, target);
	DispatchKeyValue(target, "targetname", sTarget);

	int glow = CreateEntityByName("tf_glow");

	if (IsValidEntity(glow)) {
		char sGlow[64];
		Format(sGlow, sizeof(sGlow), "%i %i %i %i", color[0], color[1], color[2], color[3]);

		DispatchKeyValue(glow, "target", sTarget);
		DispatchKeyValue(glow, "Mode", "1"); //Mode is currently broken.
		DispatchKeyValue(glow, "GlowColor", sGlow);
		DispatchSpawn(glow);
		
		SetVariantString("!activator");
		AcceptEntityInput(glow, "SetParent", target, glow);

		AcceptEntityInput(glow, "Enable");
	}

	return glow;
}

bool IsEndOfRound() {
	int timeleft = GetTimeRemaining();

	if (timeleft == -1) {
		return false;
	}

	return timeleft <= (Cvar[GlowTimeLeft].IntValue * 60);
}

void Outlines_Tick() {
	if (!IsEndOfRound()) {
		return;
	}

	GiveOutlines();
}

void GiveOutlines() {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientConnected(i) || !IsClientInGame(i) || !IsPlayerAlive(i)) {
			continue;
		}

		GiveOutline(i);
	}
}

void GiveOutline(int client) {
	if (!Cvar[GlowEnable].BoolValue) {
		return;
	}

	if (!IsEndOfRound()) {
		return;
	}

	if (client < 1 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client)) {
		return;
	}

	ClearOutline(client);

	int color[4];

	if (g_IsTeams) {
		switch (g_Team[client]) {
			case 0: {
				color = {255, 0, 0, 255};
			}
			case 1: {
				color = {0, 0, 255, 255};
			}
			case 2: {
				color = {255, 255, 0, 255};
			}
			case 3: {
				color = {0, 255, 0, 255};
			}
		}
	} else {
		color = GetClientTeam(client) == 2 ? {255, 0, 0, 255} : {0, 0, 255, 255};
	}

	g_Glow[client] = TF2_CreateGlow(client, color);
}

void ClearOutlines() {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientConnected(i) || !IsClientInGame(i) || !IsPlayerAlive(i)) {
			continue;
		}

		ClearOutline(i);
	}
}

void ClearOutline(int client) {
	if (client < 1 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client)) {
		return;
	}

	if (g_Glow[client] > MaxClients && IsValidEntity(g_Glow[client])) {
		AcceptEntityInput(g_Glow[client], "Kill");
	}

	g_Glow[client] = -1;
}