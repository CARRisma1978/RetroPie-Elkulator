# RetroPie-Elkulator

A RetroPie-Setup module that builds and installs [Elkulator](https://github.com/stardot/elkulator), the Acorn Electron emulator, with patches that fix emulation bugs and make it work well from EmulationStation on a Raspberry Pi. It appears in RetroPie-Setup's **Experimental** section and adds an **Acorn Electron** system to EmulationStation.

> **Use at your own risk.** This module builds software from source and edits EmulationStation's `es_systems.cfg` (a backup is kept). It has only been tested on the setup listed below.

## What it does

- Downloads the Elkulator source from [stardot/elkulator](https://github.com/stardot/elkulator), applies the patches below, and builds it.
- Downloads the Electron BIOS ROMs to `~/RetroPie/BIOS/electron` if they are missing, and checks each one's SHA-1. The ROMs are not included in this repo.
- Creates `~/RetroPie/roms/electron` and adds the **electron** system to EmulationStation.
- Writes a launcher that sets up each game type, switches the TV to 50 Hz if it can, and starts Elkulator full screen.
- Keeps its settings in `/opt/retropie/configs/electron/elk.cfg`.

### Supported files

| Type | Extensions | How it starts |
|---|---|---|
| Tape | `.uef` `.csw` | Types `CHAIN""` automatically |
| DFS disc | `.ssd` `.dsd` | Boots with SHIFT+BREAK |
| ADFS disc | `.adf` `.adm` `.adl` | Boots with SHIFT+BREAK |
| Cartridge | `.rom` | Pairs named `name_1.rom` + `name_2.rom` are loaded together |

**Per-game typing:** put the commands in a `<game>.autotype` file next to the game, one per line (e.g. `*RUN`). They replace the automatic `CHAIN""` for tapes, and are typed after booting for discs.

### Controls

| Key / button | Action |
|---|---|
| F1 | Electron ESCAPE |
| F12 | BREAK |
| F11 | Elkulator menu |
| ESC | Quit |
| Select + Start | Quit (gamepad; set with `joy_quit_buttons` in `elk.cfg`) |

## The patches

| Patch | What it does |
|---|---|
| `01-cpu-adc-sbc-overflow-fix.diff` | Fixes the 6502 ADC/SBC overflow flag and decimal mode, using the B-Em code. From [uiopaubo/elkulator](https://github.com/uiopaubo/elkulator) (branch `fix-overflow-handling`), not yet merged upstream. |
| `02-ula-rom-paging-fix.diff` | Fixes the Electron ULA's ROM paging. From [uiopaubo/elkulator](https://github.com/uiopaubo/elkulator) (branch `fix-ula-paging-register`), not yet merged upstream. |
| `03-openal-remove-alut.diff` | Removes the deprecated ALUT library; opens audio with core OpenAL instead. |
| `04-fullscreen-desktop-scaled.diff` | Full screen works on the Pi's X server: a borderless desktop-sized window with the picture scaled to fit (`fullscreen_scale` in `elk.cfg`). Adds the `-fullscreen` option. |
| `05-quit-esc-and-gamepad.diff` | ESC quits, and a gamepad button combination can quit too (`joy_quit_buttons`). |
| `06-autoboot-autotype.diff` | Adds `-autoboot`, `-autotype` and `-autodelay`, used by the launcher to boot discs and type commands. |

## Requirements

- **Raspberry Pi** with **RetroPie** installed using RetroPie-Setup. Tested on a Pi 5 only.
- **Raspberry Pi OS Bookworm Lite 64-bit** (Debian 12).
- **An internet connection.** The module downloads the source, packages and ROMs.

The module installs everything else it needs with apt (X server, Allegro 4, OpenAL and the build tools).

### Tested on

| | |
|---|---|
| Hardware | Raspberry Pi 5 (16 GB), 1080p over HDMI |
| OS | Raspberry Pi OS Bookworm Lite 64-bit (Debian 12.15) |
| RetroPie | 4.8.12 |
| X server | xorg-server 2:21.1.7-3+rpt3+deb12u13 |
| Gamepad | 8BitDo M30 |

## Installing

RetroPie-Setup picks up extra modules from its `ext` folder. This module goes in:

```
~/RetroPie-Setup/ext/acorn/scriptmodules/supplementary/
```

### Option 1 - clone with git (recommended)

This puts the whole repo in the right place, so a later `git pull` updates the module and patches:

```bash
git clone https://github.com/CARRisma1978/RetroPie-Elkulator.git ~/RetroPie-Setup/ext/acorn
```

To get newer versions later:

```bash
cd ~/RetroPie-Setup/ext/acorn && git pull
```

Then choose **Update** on the module in RetroPie-Setup.

### Option 2 - copy the files by hand

Download the `scriptmodules` folder from this repo and copy it into `~/RetroPie-Setup/ext/acorn/`, keeping the folders as they are:

```
~/RetroPie-Setup/ext/acorn/scriptmodules/supplementary/elkulator.sh
~/RetroPie-Setup/ext/acorn/scriptmodules/supplementary/elkulator/patches/*.diff
```

If you edit the files on Windows, save them with **Unix (LF)** line endings. In Notepad++: *Edit → EOL Conversion → Unix (LF)*. The module and patches fail on the Pi with Windows (CRLF) line endings.

## Running

1. Start RetroPie-Setup:

   ```bash
   sudo ~/RetroPie-Setup/retropie_setup.sh
   ```

2. Go to **Manage packages → Manage experimental packages → elkulator** and choose **Install from source**.
3. Restart EmulationStation. The **Acorn Electron** system appears once it has games in it.
4. Put games in `~/RetroPie/roms/electron`.

If any BIOS ROM couldn't be downloaded, the install says which one. Copy it into `~/RetroPie/BIOS/electron` by hand. The ROMs needed are `os`, `basic.rom`, `plus1.rom`, `dfs.rom`, `adfs.rom`, `os300.rom` and `sndrom`.

### Settings

`/opt/retropie/configs/electron/elk.cfg` is created on the first install and kept after that. Settings added by the patches:

| Setting | Values |
|---|---|
| `fullscreen_scale` | `0` largest whole-number scale (sharp, default); `1` 4:3 aspect; `2` fill the screen |
| `display_scale` | `2` X at half the TV resolution, so Elkulator's menus are twice the size (default); `1` full TV resolution |
| `joy_quit_buttons` | Gamepad buttons held together to quit, e.g. `10,11` (8BitDo M30 Select + Start) |

## Updating

Choose **Update** on the module in RetroPie-Setup. It fetches the latest Elkulator source, re-applies the patches and rebuilds. Your `elk.cfg` is kept.

## Removing

Choose **Remove** on the module. Your games, BIOS ROMs and `elk.cfg` are kept, and so is the **electron** entry in `es_systems.cfg`. Remove that by hand if you want to; the module keeps a backup of the file from before it was added (`es_systems.cfg.bak-elkulator`).

## Credits

- [Elkulator](https://github.com/stardot/elkulator) by Tom Walker and the [Stardot](https://stardot.org.uk/) community (GPL-2.0)
- Patches 01 and 02 by [uiopaubo](https://github.com/uiopaubo/elkulator)
- The 6502 ADC/SBC code in patch 01 comes from [B-Em](https://github.com/stardot/b-em)
- [RetroPie-Setup](https://github.com/RetroPie/RetroPie-Setup) (GPL-3.0)
- The Acorn Electron BIOS ROMs are downloaded from the [Elkulator v1.0 release](http://elkulator.acornelectron.co.uk/) and a [mirror on GitHub](https://github.com/demrepofdave/elkulator). They are not included in this repo.

## Licence

- **`elkulator.sh`** (the RetroPie module) is released under the GNU General Public License v3.0, the same as RetroPie-Setup; see [LICENSE](LICENSE).
- **The patches** are changes to Elkulator's source code, so they are under Elkulator's own licence, the GNU General Public License v2.0.
