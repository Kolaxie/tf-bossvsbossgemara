#if defined _debugger_included
	#endinput
#endif
#define _debugger_included

enum StatusCode {
	StatusCode_Success,
	StatusCode_Failure,
	StatusCode_Debugging
}

public void LogDebugger(StatusCode code, const char[] format, any ...) {
	char buffer[1024];
	VFormat(buffer, sizeof(buffer), format, 3);

	char plugin[64];
	GetPluginInfo(null, PlInfo_Name, plugin, sizeof(plugin));

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "logs/debug-%s.log", plugin);

	Format(buffer, sizeof(buffer), "[Status Code: %i] - %s", view_as<int>(code), buffer);

	LogToFile(path, buffer);
}

public void LogSuccess(const char[] format, any ...) {
	char buffer[1024];
	VFormat(buffer, sizeof(buffer), format, 2);

	char plugin[64];
	GetPluginInfo(null, PlInfo_Name, plugin, sizeof(plugin));

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "logs/debug-%s.log", plugin);

	Format(buffer, sizeof(buffer), "[Status Code: %i] - %s", view_as<int>(StatusCode_Success), buffer);

	LogToFile(path, buffer);
}

public void LogFailure(const char[] format, any ...) {
	char buffer[1024];
	VFormat(buffer, sizeof(buffer), format, 2);

	char plugin[64];
	GetPluginInfo(null, PlInfo_Name, plugin, sizeof(plugin));

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "logs/debug-%s.log", plugin);

	Format(buffer, sizeof(buffer), "[Status Code: %i] - %s", view_as<int>(StatusCode_Failure), buffer);

	LogToFile(path, buffer);
}

public void LogDebugging(const char[] format, any ...) {
	char buffer[1024];
	VFormat(buffer, sizeof(buffer), format, 2);

	char plugin[64];
	GetPluginInfo(null, PlInfo_Name, plugin, sizeof(plugin));

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "logs/debug-%s.log", plugin);

	Format(buffer, sizeof(buffer), "[Status Code: %i] - %s", view_as<int>(StatusCode_Debugging), buffer);

	LogToFile(path, buffer);
}