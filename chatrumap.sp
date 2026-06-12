#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define DELIMITER     "\x01"
#define CMD_DELAY     3.0

char      g_sNextMap[128];
float     g_fLastCmd[MAXPLAYERS + 1];
StringMap g_hMapData;   // mapname -> "DisplayName\x01cmd1\x01cmd2\x01..."

public Plugin myinfo = {
    name        = "Chatrumap",
    author      = "OBVIOUSLY.DR",
    description = "!map, !listmaps + Map Commands",
    version     = "1.3",
    url         = ""
};

// ── Startup ────────────────────────────────────────────────────────────────
public void OnPluginStart()
{
    g_hMapData = new StringMap();
    LoadMapConfig();

    RegConsoleCmd("sm_map",      Cmd_Map,      "Map wechseln: !map <mapname>");
    RegConsoleCmd("sm_listmaps", Cmd_ListMaps, "Maps anzeigen: !listmaps");

    AddCommandListener(Hook_Say, "say");
    AddCommandListener(Hook_Say, "say_team");
}

// ── Map Start: Commands ausführen ──────────────────────────────────────────
public void OnMapStart()
{
    LoadMapConfig();

    char curMap[128];
    GetCurrentMap(curMap, sizeof(curMap));

    char data[4096];
    if (!g_hMapData.GetString(curMap, data, sizeof(data)))
        return;

    // Format: "DisplayName\x01cmd1\x01cmd2\x01..."
    // Wenn nur DisplayName drin ist (kein \x01 mehr) -> keine Commands
    if (FindCharInString(data, '\x01') == -1)
        return;

    DataPack dp = new DataPack();
    dp.WriteString(data);
    CreateTimer(CMD_DELAY, Timer_ExecCommands, dp);
}

public Action Timer_ExecCommands(Handle timer, DataPack dp)
{
    dp.Reset();

    char data[4096];
    dp.ReadString(data, sizeof(data));

    // Split by delimiter
    char parts[64][256];
    int count = ExplodeString(data, DELIMITER, parts, sizeof(parts), sizeof(parts[]));

    // parts[0] = DisplayName, parts[1..n] = Commands
    for (int i = 1; i < count; i++)
    {
        TrimString(parts[i]);
        if (strlen(parts[i]) > 0)
            ServerCommand(parts[i]);
    }

    return Plugin_Stop;
}

// ── Config laden ───────────────────────────────────────────────────────────
void LoadMapConfig()
{
    delete g_hMapData;
    g_hMapData = new StringMap();

    char mapsFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, mapsFile, sizeof(mapsFile), "configs/maps.cfg");
    if (!FileExists(mapsFile)) return;

    File f = OpenFile(mapsFile, "r");
    if (f == null) return;

    char line[512];
    char curMap[128];
    char curDisp[128];
    char commands[4096];  // DisplayName + \x01 + Commands
    bool inBlock = false;

    while (!f.EndOfFile() && f.ReadLine(line, sizeof(line)))
    {
        TrimString(line);
        if (strlen(line) == 0 || strncmp(line, "//", 2) == 0)
            continue;

        // Block öffnen
        if (StrEqual(line, "{"))
        {
            inBlock = true;
            Format(commands, sizeof(commands), "%s", curDisp);
            continue;
        }

        // Block schließen → Map speichern
        if (StrEqual(line, "}"))
        {
            if (strlen(curMap) > 0)
                g_hMapData.SetString(curMap, commands);

            inBlock   = false;
            curMap[0] = '\0';
            curDisp[0] = '\0';
            commands[0] = '\0';
            continue;
        }

        // Innerhalb eines Blocks: Commands parsen
        if (inBlock)
        {
            // Semikolon-getrennte Commands auf einer Zeile unterstützen
            char cmds[32][256];
            int cnt = ExplodeString(line, ";", cmds, sizeof(cmds), sizeof(cmds[]));

            for (int i = 0; i < cnt; i++)
            {
                TrimString(cmds[i]);
                if (strlen(cmds[i]) == 0) continue;
                Format(commands, sizeof(commands), "%s%s%s", commands, DELIMITER, cmds[i]);
            }
        }
        else
        {
            // Mapname + Anzeigename parsen
            // Ohne {}: Map direkt ohne Commands speichern wenn neue Zeile kommt
            if (strlen(curMap) > 0)
                g_hMapData.SetString(curMap, curDisp);

            int quoteStart = FindCharInString(line, '"');
            if (quoteStart != -1)
            {
                strcopy(curMap, sizeof(curMap), line);
                curMap[quoteStart] = '\0';
                TrimString(curMap);

                int quoteEnd = FindCharInString(line[quoteStart + 1], '"');
                if (quoteEnd != -1)
                {
                    strcopy(curDisp, sizeof(curDisp), line[quoteStart + 1]);
                    curDisp[quoteEnd] = '\0';
                }
                else
                    strcopy(curDisp, sizeof(curDisp), curMap);
            }
            else
            {
                strcopy(curMap, sizeof(curMap), line);
                strcopy(curDisp, sizeof(curDisp), line);
            }
        }
    }

    // Letzte Map ohne {} speichern falls nötig
    if (strlen(curMap) > 0 && !inBlock)
        g_hMapData.SetString(curMap, curDisp);

    delete f;
}

// ── Chat Hook ──────────────────────────────────────────────────────────────
public Action Hook_Say(int client, const char[] command, int argc)
{
    if (client == 0) return Plugin_Continue;

    if (GetGameTime() - g_fLastCmd[client] < 0.2)
        return Plugin_Continue;

    char text[256];
    GetCmdArgString(text, sizeof(text));
    StripQuotes(text);

    if (StrEqual(text, "!listmaps", false))
    {
        g_fLastCmd[client] = GetGameTime();
        Cmd_ListMaps(client, 0);
        return Plugin_Handled;
    }

    if (strncmp(text, "!map ", 5, false) == 0)
    {
        g_fLastCmd[client] = GetGameTime();
        char mapName[128];
        strcopy(mapName, sizeof(mapName), text[5]);
        TrimString(mapName);
        DoMapChange(client, mapName);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

// ── !listmaps ──────────────────────────────────────────────────────────────
public Action Cmd_ListMaps(int client, int args)
{
    char mapsFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, mapsFile, sizeof(mapsFile), "configs/maps.cfg");

    if (!FileExists(mapsFile))
    {
        ReplyToCommand(client, "[Chatrumap] Keine maps.cfg gefunden!");
        return Plugin_Handled;
    }

    File f = OpenFile(mapsFile, "r");
    if (f == null)
    {
        ReplyToCommand(client, "[Chatrumap] Fehler beim Oeffnen der maps.cfg!");
        return Plugin_Handled;
    }

    ArrayList mapNames    = new ArrayList(ByteCountToCells(128));
    ArrayList displayNames = new ArrayList(ByteCountToCells(128));

    char line[256];
    char curMap[128];
    char curDisp[128];
    bool inBlock = false;

    while (!f.EndOfFile() && f.ReadLine(line, sizeof(line)))
    {
        TrimString(line);
        if (strlen(line) == 0 || strncmp(line, "//", 2) == 0) continue;

        if (StrEqual(line, "{"))  { inBlock = true;  continue; }
        if (StrEqual(line, "}"))
        {
            if (strlen(curMap) > 0)
            {
                mapNames.PushString(curMap);
                displayNames.PushString(curDisp);
            }
            inBlock = false;
            curMap[0] = '\0';
            curDisp[0] = '\0';
            continue;
        }
        if (inBlock) continue;

        // Mapname parsen
        if (strlen(curMap) > 0)
        {
            mapNames.PushString(curMap);
            displayNames.PushString(curDisp);
        }

        int quoteStart = FindCharInString(line, '"');
        if (quoteStart != -1)
        {
            strcopy(curMap, sizeof(curMap), line);
            curMap[quoteStart] = '\0';
            TrimString(curMap);

            int quoteEnd = FindCharInString(line[quoteStart + 1], '"');
            if (quoteEnd != -1)
            {
                strcopy(curDisp, sizeof(curDisp), line[quoteStart + 1]);
                curDisp[quoteEnd] = '\0';
            }
            else strcopy(curDisp, sizeof(curDisp), curMap);
        }
        else
        {
            strcopy(curMap, sizeof(curMap), line);
            strcopy(curDisp, sizeof(curDisp), line);
        }
    }
    if (strlen(curMap) > 0 && !inBlock)
    {
        mapNames.PushString(curMap);
        displayNames.PushString(curDisp);
    }
    delete f;

    int count = mapNames.Length;
    if (count == 0)
    {
        ReplyToCommand(client, "[Chatrumap] Mapliste ist leer!");
        delete mapNames; delete displayNames;
        return Plugin_Handled;
    }

    PrintToChat(client, " \x04[Chatrumap]\x01 Verfuegbare Maps \x0B(%d)\x01:", count);
    char mapN[128], dispN[128];
    for (int i = 0; i < count; i++)
    {
        mapNames.GetString(i, mapN, sizeof(mapN));
        displayNames.GetString(i, dispN, sizeof(dispN));
        PrintToChat(client, " \x04►\x01 \x0B%s\x01 \x08(!map %s)", dispN, mapN);
    }

    delete mapNames; delete displayNames;
    return Plugin_Handled;
}

// ── !map <name> ────────────────────────────────────────────────────────────
public Action Cmd_Map(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[Chatrumap] Verwendung: !map <mapname>  |  !listmaps");
        return Plugin_Handled;
    }
    char mapName[128];
    GetCmdArg(1, mapName, sizeof(mapName));
    DoMapChange(client, mapName);
    return Plugin_Handled;
}

// ── Map wechseln ───────────────────────────────────────────────────────────
void DoMapChange(int client, const char[] mapName)
{
    if (!IsMapValid(mapName))
    {
        if (client > 0)
            PrintToChat(client, " \x04[Chatrumap]\x01 Map \x02%s\x01 nicht gefunden! Nutze \x04!listmaps", mapName);
        return;
    }

    char dispName[128];
    GetDisplayName(mapName, dispName, sizeof(dispName));
    strcopy(g_sNextMap, sizeof(g_sNextMap), mapName);

    char name[MAX_NAME_LENGTH];
    if (client > 0) GetClientName(client, name, sizeof(name));
    else strcopy(name, sizeof(name), "Server");

    PrintToChatAll(" \x04[Chatrumap]\x01 \x0B%s\x01 wechselt zur Map \x04%s\x01 in \x025\x01 Sekunden!", name, dispName);
    CreateTimer(5.0, Timer_ChangeMap);
}

void GetDisplayName(const char[] mapName, char[] buffer, int maxlen)
{
    char data[4096];
    if (g_hMapData.GetString(mapName, data, sizeof(data)))
    {
        int delim = FindCharInString(data, '\x01');
        if (delim != -1) { strcopy(buffer, delim + 1, data); }
        else strcopy(buffer, maxlen, data);
    }
    else strcopy(buffer, maxlen, mapName);
}

public Action Timer_ChangeMap(Handle timer)
{
    ForceChangeLevel(g_sNextMap, "Chatrumap: Map change by player");
    return Plugin_Stop;
}
