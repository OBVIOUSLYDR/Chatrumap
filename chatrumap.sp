#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define DELIMITER  "\x01"
#define CMD_DELAY  3.0

char      g_sNextMap[128];
float     g_fLastCmd[MAXPLAYERS + 1];
char      g_sLastMsg[MAXPLAYERS + 1][256]; // Double-message Fix
StringMap g_hMapData;    // mapname -> "DisplayName\x01cmd1\x01..."
StringMap g_hCategories; // category_lower -> "map1\x01map2\x01..."
ArrayList g_hCatOrder;   // Reihenfolge der Kategorien (Anzeigename)

public Plugin myinfo = {
    name        = "Chatrumap",
    author      = "OBVIOUSLY.DR",
    description = "!map, !maplist + Kategorien + Map Commands",
    version     = "1.5",
    url         = ""
};

// ── Startup ────────────────────────────────────────────────────────────────
public void OnPluginStart()
{
    g_hMapData    = new StringMap();
    g_hCategories = new StringMap();
    g_hCatOrder   = new ArrayList(ByteCountToCells(128));
    LoadMapConfig();

    RegConsoleCmd("sm_map",     Cmd_Map,     "Map wechseln: !map <mapname>");
    RegConsoleCmd("sm_maplist", Cmd_MapList, "Maps anzeigen: !maplist [kategorie]");

    AddCommandListener(Hook_Say, "say");
    AddCommandListener(Hook_Say, "say_team");
}

// ── Map Start ──────────────────────────────────────────────────────────────
public void OnMapStart()
{
    LoadMapConfig();

    char curMap[128];
    GetCurrentMap(curMap, sizeof(curMap));

    char data[4096];
    if (!g_hMapData.GetString(curMap, data, sizeof(data))) return;
    if (FindCharInString(data, '\x01') == -1) return;

    DataPack dp = new DataPack();
    dp.WriteString(data);
    CreateTimer(CMD_DELAY, Timer_ExecCommands, dp);
}

public Action Timer_ExecCommands(Handle timer, DataPack dp)
{
    dp.Reset();
    char data[4096];
    dp.ReadString(data, sizeof(data));

    char parts[64][256];
    int count = ExplodeString(data, DELIMITER, parts, sizeof(parts), sizeof(parts[]));

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
    delete g_hCategories;
    delete g_hCatOrder;
    g_hMapData    = new StringMap();
    g_hCategories = new StringMap();
    g_hCatOrder   = new ArrayList(ByteCountToCells(128));

    char mapsFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, mapsFile, sizeof(mapsFile), "configs/maps.cfg");
    if (!FileExists(mapsFile)) return;

    File f = OpenFile(mapsFile, "r");
    if (f == null) return;

    char line[512];
    char curMap[128];
    char curDisp[128];
    char curCat[128];        // Aktuelle Kategorie (Anzeigename)
    char curCatLower[128];   // Aktuelle Kategorie (lowercase key)
    char commands[4096];
    bool inBlock = false;

    while (!f.EndOfFile() && f.ReadLine(line, sizeof(line)))
    {
        TrimString(line);
        if (strlen(line) == 0 || strncmp(line, "//", 2) == 0)
            continue;

        // Kategorie: [Name]
        if (line[0] == '[')
        {
            int closing = FindCharInString(line, ']');
            if (closing > 1)
            {
                strcopy(curCat, closing, line[1]);
                strcopy(curCatLower, sizeof(curCatLower), curCat);
                for (int i = 0; i < strlen(curCatLower); i++)
                    curCatLower[i] = CharToLower(curCatLower[i]);

                // Kategorie in Reihenfolge speichern wenn neu
                char existing[4096];
                if (!g_hCategories.GetString(curCatLower, existing, sizeof(existing)))
                {
                    g_hCatOrder.PushString(curCat);
                    g_hCategories.SetString(curCatLower, "");
                }
            }
            continue;
        }

        // Block öffnen
        if (StrEqual(line, "{"))
        {
            inBlock = true;
            Format(commands, sizeof(commands), "%s", curDisp);
            continue;
        }

        // Block schließen
        if (StrEqual(line, "}"))
        {
            if (strlen(curMap) > 0)
            {
                g_hMapData.SetString(curMap, commands);

                // Map zur Kategorie hinzufügen
                if (strlen(curCatLower) > 0)
                {
                    char catMaps[4096];
                    g_hCategories.GetString(curCatLower, catMaps, sizeof(catMaps));
                    if (strlen(catMaps) > 0)
                        Format(catMaps, sizeof(catMaps), "%s%s%s", catMaps, DELIMITER, curMap);
                    else
                        strcopy(catMaps, sizeof(catMaps), curMap);
                    g_hCategories.SetString(curCatLower, catMaps);
                }
            }
            inBlock   = false;
            curMap[0] = '\0';
            curDisp[0] = '\0';
            commands[0] = '\0';
            continue;
        }

        // Commands im Block
        if (inBlock)
        {
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
            // Vorherige Map ohne Block speichern
            if (strlen(curMap) > 0)
            {
                g_hMapData.SetString(curMap, curDisp);
                if (strlen(curCatLower) > 0)
                {
                    char catMaps[4096];
                    g_hCategories.GetString(curCatLower, catMaps, sizeof(catMaps));
                    if (strlen(catMaps) > 0)
                        Format(catMaps, sizeof(catMaps), "%s%s%s", catMaps, DELIMITER, curMap);
                    else
                        strcopy(catMaps, sizeof(catMaps), curMap);
                    g_hCategories.SetString(curCatLower, catMaps);
                }
            }

            // Mapname + Anzeigename parsen
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
    }

    if (strlen(curMap) > 0 && !inBlock)
    {
        g_hMapData.SetString(curMap, curDisp);
        if (strlen(curCatLower) > 0)
        {
            char catMaps[4096];
            g_hCategories.GetString(curCatLower, catMaps, sizeof(catMaps));
            if (strlen(catMaps) > 0)
                Format(catMaps, sizeof(catMaps), "%s%s%s", catMaps, DELIMITER, curMap);
            else
                strcopy(catMaps, sizeof(catMaps), curMap);
            g_hCategories.SetString(curCatLower, catMaps);
        }
    }

    delete f;
}

// ── Chat Hook ──────────────────────────────────────────────────────────────
public Action Hook_Say(int client, const char[] command, int argc)
{
    if (client <= 0) return Plugin_Continue;

    char text[256];
    GetCmdArgString(text, sizeof(text));
    StripQuotes(text);

    // Double-message Fix: gleiche Nachricht innerhalb 0.5s ignorieren
    if (GetGameTime() - g_fLastCmd[client] < 0.5 && StrEqual(g_sLastMsg[client], text, false))
        return Plugin_Continue;

    if (StrEqual(text, "!maplist", false))
    {
        g_fLastCmd[client] = GetGameTime();
        strcopy(g_sLastMsg[client], sizeof(g_sLastMsg[]), text);
        Cmd_MapList(client, 0);
        return Plugin_Handled;
    }

    if (strncmp(text, "!maplist ", 9, false) == 0)
    {
        g_fLastCmd[client] = GetGameTime();
        strcopy(g_sLastMsg[client], sizeof(g_sLastMsg[]), text);
        char cat[128];
        strcopy(cat, sizeof(cat), text[9]);
        TrimString(cat);
        ShowCategory(client, cat);
        return Plugin_Handled;
    }

    if (strncmp(text, "!map ", 5, false) == 0)
    {
        g_fLastCmd[client] = GetGameTime();
        strcopy(g_sLastMsg[client], sizeof(g_sLastMsg[]), text);
        char mapName[128];
        strcopy(mapName, sizeof(mapName), text[5]);
        TrimString(mapName);
        DoMapChange(client, mapName);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

// ── !maplist ───────────────────────────────────────────────────────────────
public Action Cmd_MapList(int client, int args)
{
    if (args >= 1)
    {
        char cat[128];
        GetCmdArg(1, cat, sizeof(cat));
        ShowCategory(client, cat);
        return Plugin_Handled;
    }

    int catCount = g_hCatOrder.Length;
    if (catCount == 0)
    {
        ReplyToCommand(client, "[Chatrumap] Keine Kategorien gefunden!");
        return Plugin_Handled;
    }

    PrintToChat(client, " \x04[Chatrumap]\x01 Kategorien – \x0Btipp !maplist <kategorie>\x01:");
    char catName[128];
    for (int i = 0; i < catCount; i++)
    {
        g_hCatOrder.GetString(i, catName, sizeof(catName));

        // Maps in Kategorie zaehlen
        char catLower[128];
        strcopy(catLower, sizeof(catLower), catName);
        for (int j = 0; j < strlen(catLower); j++)
            catLower[j] = CharToLower(catLower[j]);

        char catMaps[4096];
        g_hCategories.GetString(catLower, catMaps, sizeof(catMaps));

        char parts[64][128];
        int count = (strlen(catMaps) > 0) ? ExplodeString(catMaps, DELIMITER, parts, sizeof(parts), sizeof(parts[])) : 0;

        PrintToChat(client, " \x04►\x01 \x0B%s\x01 \x08(%d Maps)", catName, count);
    }

    return Plugin_Handled;
}

void ShowCategory(int client, const char[] input)
{
    // Input zu lowercase
    char inputLower[128];
    strcopy(inputLower, sizeof(inputLower), input);
    for (int i = 0; i < strlen(inputLower); i++)
        inputLower[i] = CharToLower(inputLower[i]);

    // Kategorie suchen (partial match)
    char foundCat[128];
    char foundKey[128];
    bool found = false;

    int catCount = g_hCatOrder.Length;
    char catName[128];
    for (int i = 0; i < catCount; i++)
    {
        g_hCatOrder.GetString(i, catName, sizeof(catName));
        char catLower[128];
        strcopy(catLower, sizeof(catLower), catName);
        for (int j = 0; j < strlen(catLower); j++)
            catLower[j] = CharToLower(catLower[j]);

        if (strncmp(catLower, inputLower, strlen(inputLower)) == 0 || StrContains(catLower, inputLower) != -1)
        {
            strcopy(foundCat, sizeof(foundCat), catName);
            strcopy(foundKey, sizeof(foundKey), catLower);
            found = true;
            break;
        }
    }

    if (!found)
    {
        PrintToChat(client, " \x04[Chatrumap]\x01 Kategorie \x02%s\x01 nicht gefunden! Nutze \x04!maplist", input);
        return;
    }

    char catMaps[4096];
    g_hCategories.GetString(foundKey, catMaps, sizeof(catMaps));

    if (strlen(catMaps) == 0)
    {
        PrintToChat(client, " \x04[Chatrumap]\x01 Keine Maps in \x0B%s\x01!", foundCat);
        return;
    }

    char parts[64][128];
    int count = ExplodeString(catMaps, DELIMITER, parts, sizeof(parts), sizeof(parts[]));

    PrintToChat(client, " \x04[Chatrumap]\x01 \x0B%s\x01 Maps \x08(%d):", foundCat, count);

    for (int i = 0; i < count; i++)
    {
        char dispName[128];
        GetDisplayName(parts[i], dispName, sizeof(dispName));
        PrintToChat(client, " \x04►\x01 \x0B%s\x01 \x08(!map %s)", dispName, parts[i]);
    }
}

// ── !map <name> ────────────────────────────────────────────────────────────
public Action Cmd_Map(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "[Chatrumap] Verwendung: !map <mapname>  |  !maplist");
        return Plugin_Handled;
    }
    char mapName[128];
    GetCmdArg(1, mapName, sizeof(mapName));
    DoMapChange(client, mapName);
    return Plugin_Handled;
}

void DoMapChange(int client, const char[] mapName)
{
    if (!IsMapValid(mapName))
    {
        if (client > 0)
            PrintToChat(client, " \x04[Chatrumap]\x01 Map \x02%s\x01 nicht gefunden! Nutze \x04!maplist", mapName);
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
        if (delim != -1) strcopy(buffer, delim + 1, data);
        else strcopy(buffer, maxlen, data);
    }
    else strcopy(buffer, maxlen, mapName);
}

public Action Timer_ChangeMap(Handle timer)
{
    ForceChangeLevel(g_sNextMap, "Chatrumap: Map change by player");
    return Plugin_Stop;
}
