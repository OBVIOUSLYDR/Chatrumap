# Chatrumap

> **DE:** SourceMod Plugin für CS:GO – !map und !maplist mit Kategorien, unbegrenzter Mapanzahl (20+ Maps), benutzerdefinierten Namen und Map-spezifischen Server Commands
>
> **EN:** SourceMod plugin for CS:GO – !map and !maplist with categories, unlimited maps (20+), custom display names and per-map server command support

---

## 🇩🇪 Deutsch

### Features

- `!map <mapname>` — Map wechseln (für alle Spieler nutzbar)
- `!maplist` — Zeigt alle Kategorien mit Mapanzahl
- `!maplist <kategorie>` — Zeigt alle Maps einer Kategorie (z.B. `!maplist bhop`)
- **Unbegrenzte Maps** — Keine 6-Map Begrenzung wie beim Standard-Mapchooser, problemlos 20+ Maps möglich
- **Kategorien** — Maps nach Typ gruppieren (DE, Bhop, Surf, MG, Aim, AWP, 1vs1 etc.)
- Map-spezifische Commands — Beim Laden einer Map werden automatisch Server-Commands ausgeführt
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

### Commands

| Chat Command | Beschreibung |
|---|---|
| `!map <mapname>` | Wechselt die Map nach 5 Sekunden |
| `!maplist` | Zeigt alle Kategorien |
| `!maplist <kategorie>` | Zeigt alle Maps der Kategorie |

### maps.cfg Format

```
// Kommentare mit //

[Kategoriename]
mapname "Anzeigename"
{
    command1
    command2;command3
}
```

### Beispiel

```
[DE Maps]
de_dust2 "Dust II"
{
    mp_freezetime 6;bot_kick;mp_restartgame 1
}

[Bhop]
bhop_beginner "Bhop Beginner"
{
    sv_airaccelerate 800;sv_enablebunnyhopping 1
    sv_staminajumpcost 0;sv_staminalandcost 0
}

[Surf]
surf_mesa "Surf Mesa"
{
    sv_airaccelerate 800;sv_friction 0.4
}

[1vs1]
1vs1_arena "1vs1 Arena"
{
    mp_t_default_primary weapon_ak47
    mp_ct_default_primary weapon_ak47
}
```

### Hinweise

- Zeilen mit `//` werden ignoriert
- Commands in `{}` werden **3 Sekunden nach Map-Start** ausgeführt
- Beide Formate unterstützt: `;` getrennt auf einer Zeile oder einzeln untereinander
- Maps ohne Commands erscheinen trotzdem in `!maplist`
- Kategorien unterstützen Partial-Match: `!maplist de` findet `DE Maps`

---

## 🇬🇧 English

### Features

- `!map <mapname>` — change the map (usable by all players)
- `!maplist` — shows all categories with map count
- `!maplist <category>` — shows all maps in a category (e.g. `!maplist bhop`)
- **Unlimited maps** — no 6-map limit like the default mapchooser, easily supports 20+ maps
- **Categories** — group maps by type (DE, Bhop, Surf, MG, Aim, AWP, 1vs1 etc.)
- Per-map command blocks — automatically execute server commands when a specific map loads
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

### Commands

| Chat Command | Description |
|---|---|
| `!map <mapname>` | Changes the map after 5 seconds |
| `!maplist` | Shows all categories |
| `!maplist <category>` | Shows all maps in a category |

### maps.cfg Format

```
// Comments start with //

[Category Name]
mapname "Display Name"
{
    command1
    command2;command3
}
```

### Example

```
[DE Maps]
de_dust2 "Dust II"
{
    mp_freezetime 6;bot_kick;mp_restartgame 1
}

[Bhop]
bhop_beginner "Bhop Beginner"
{
    sv_airaccelerate 800;sv_enablebunnyhopping 1
    sv_staminajumpcost 0;sv_staminalandcost 0
}

[Surf]
surf_mesa "Surf Mesa"
{
    sv_airaccelerate 800;sv_friction 0.4
}

[1vs1]
1vs1_arena "1vs1 Arena"
{
    mp_t_default_primary weapon_ak47
    mp_ct_default_primary weapon_ak47
}
```

### Notes

- Lines starting with `//` are ignored
- Commands inside `{}` are executed **3 seconds after map start**
- Both formats supported: `;` separated on one line or one command per line
- Maps without commands still show up in `!maplist`
- Categories support partial match: `!maplist de` finds `DE Maps`

---

## Credits

- **Author:** OBVIOUSLY.DR
- Built for CS:GO community servers running the 2026 standalone re-release (App 740)
