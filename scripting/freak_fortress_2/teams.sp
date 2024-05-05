public Action Timer_StartTeams(Handle timer) {
	if (BVBRounds_IsEnabled() && BVBRounds_IsSpecialRound()) {
		return Plugin_Stop;
	}

	g_IsTeams = true;
	CPrintToChatAll("{green}[FF2]{default} Teams enabled!");

	int teams = 4;
	int max = (GetTeamClientCount(2) + GetTeamClientCount(3)) / teams;
	int[] count = new int[teams];

	int[] clientIndices = new int[MaxClients];
	int numClients = 0;

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			clientIndices[numClients] = i;
			numClients++;
		}
	}

	SortIntegers(clientIndices, numClients, Sort_Random);

	for (int i = 0; i < numClients; i++) {
		int client = clientIndices[i];

		int minTeam = 0;
		int minCount = count[0];

		for (int j = 1; j < teams; j++) {
			if (count[j] < minCount && count[j] < max) {
				minTeam = j;
				minCount = count[j];
			}
		}

		g_Team[client] = minTeam;
		count[minTeam]++;

		char sTeam[16];
		switch (minTeam) {
			case 0:
				sTeam = "{red}Red";
			case 1:
				sTeam = "{blue}Blue";
			case 2:
				sTeam = "{yellow}Yellow";
			case 3:
				sTeam = "{green}Green";
		}

		CPrintToChat(client, "You have been assigned to team: %s", sTeam);
	}

	return Plugin_Continue;
}