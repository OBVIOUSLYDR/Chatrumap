# Chatrumap
SourceMod Plugin für CS:GO — !map und !listmaps mit unbegrenzter Mapanzahl (20+ Maps), benutzerdefinierten Namen und Map-spezifischen Server Commands  |  SourceMod plugin for CS:GO — !map and !listmaps with unlimited maps (20+), custom display names and per-map server command support





# Chatrumap

Ein SourceMod Plugin für CS:GO Community-Server das Spielern erlaubt Maps über den Chat zu wechseln und alle verfügbaren Maps einzusehen — mit Unterstützung für Map-spezifische Server-Konfigurationen und **unbegrenzter Mapanzahl**.

---

## 🇩🇪 Deutsch

### Features

- `!map <mapname>` — Map wechseln (für alle Spieler nutzbar)
- `!listmaps` — Zeigt alle verfügbaren Maps mit benutzerdefinierten Namen im Chat
- **Unbegrenzte Maps** — Keine Begrenzung auf 6 Maps wie beim Standard-Mapchooser, problemlos 20+ Maps möglich
- Map-spezifische Commands — Beim Laden einer Map werden automatisch Server-Commands ausgeführt
- Semikolon-getrennte Commands oder eine Command pro Zeile
- Benutzerdefinierte Anzeigenamen für Maps
- Kein Doppel-Trigger Bug

### Voraussetzungen

- [SourceMod 1.11](https://www.sourcemod.net/downloads.php?branch=stable)
- [Metamod:Source](https://www.metamodsource.net/downloads.php?branch=stable)

### Installation

1. `chatrumap.smx` herunterladen
2. Hochladen nach:
   ```
   csgo/addons/sourcemod/plugins/chatrumap.smx
   ```
3. `maps.cfg` hochladen nach:
   ```
   csgo/addons/sourcemod/configs/maps.cfg
   ```
4. Server neustarten

### maps.cfg Format

```
// Kommentare mit //
mapname "Anzeigename"
{
    command1
    command2;command3
}
```

### Beispiel

```
de_dust2 "Dust II"
{

}

bhop_beginner "Bhop Beginner"
{
    bot_kick;mp_freezetime 0;sv_airaccelerate 800
    sv_enablebunnyhopping 1;sv_staminajumpcost 0;sv_staminalandcost 0
}

1vs1_arena "1vs1 Arena"
{
    mp_t_default_primary weapon_ak47
    mp_ct_default_primary weapon_ak47
    mp_t_default_secondary weapon_deagle
    mp_ct_default_secondary weapon_deagle
}
```

### Commands

| Chat Command | Beschreibung |
|---|---|
| `!map <mapname>` | Wechselt die Map nach 5 Sekunden |
| `!listmaps` | Zeigt alle Maps aus der maps.cfg im Chat |

### Hinweise

- Zeilen mit `//` werden ignoriert
- Commands in `{}` werden **3 Sekunden nach Map-Start** ausgeführt
- Maps ohne Commands erscheinen trotzdem in `!listmaps`

---

## 🇬🇧 English

### Features

- `!map <mapname>` — change the map (usable by all players)
- `!listmaps` — shows all available maps with custom display names in chat
- **Unlimited maps** — no 6-map limit like the default mapchooser, easily supports 20+ maps
- Per-map command blocks — automatically execute server commands when a specific map loads
- Supports semicolon-separated commands or one command per line
- Custom display names for maps
- No double-trigger bug

### Requirements

- [SourceMod 1.11](https://www.sourcemod.net/downloads.php?branch=stable)
- [Metamod:Source](https://www.metamodsource.net/downloads.php?branch=stable)

### Installation

1. Download `chatrumap.smx`
2. Upload to:
   ```
   csgo/addons/sourcemod/plugins/chatrumap.smx
   ```
3. Upload `maps.cfg` to:
   ```
   csgo/addons/sourcemod/configs/maps.cfg
   ```
4. Restart the server

### maps.cfg Format

```
// Comments start with //
mapname "Display Name"
{
    command1
    command2;command3
}
```

### Example

```
de_dust2 "Dust II"
{

}

bhop_beginner "Bhop Beginner"
{
    bot_kick;mp_freezetime 0;sv_airaccelerate 800
    sv_enablebunnyhopping 1;sv_staminajumpcost 0;sv_staminalandcost 0
}

1vs1_arena "1vs1 Arena"
{
    mp_t_default_primary weapon_ak47
    mp_ct_default_primary weapon_ak47
    mp_t_default_secondary weapon_deagle
    mp_ct_default_secondary weapon_deagle
}
```

### Commands

| Chat Command | Description |
|---|---|
| `!map <mapname>` | Changes the map after 5 seconds |
| `!listmaps` | Shows all maps from maps.cfg in chat |

### Notes

- Lines starting with `//` are comments and will be ignored
- Commands inside `{}` are executed **3 seconds after the map starts**
- Maps without commands still show up in `!listmaps`

---

## Credits

- **Author:** OBVIOUSLY.DR
- Built for CS:GO community servers running the 2026 standalone re-release (App 740)
