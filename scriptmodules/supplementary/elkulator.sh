#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#
# Elkulator (Acorn Electron emulator) - stardot/elkulator + local patches
# Location: ~/Retropie-Setup/ext/acorn/scriptmodules/supplementary/elkulator.sh
# Patches : ~/Retropie-Setup/ext/acorn/scriptmodules/supplementary/elkulator/patches/*.diff
#

rp_module_id="elkulator"
rp_module_desc="Elkulator - Acorn Electron emulator (stardot)"
rp_module_help="Games go in $romdir/electron\n\n\
Supported: .uef (tape) .ssd .dsd (DFS disc) .adf .adm (ADFS disc) .rom (cartridge)\n\
Cartridge pairs: name_1.rom + name_2.rom are loaded together.\n\n\
BIOS ROMs ($biosdir/electron): os basic.rom plus1.rom dfs.rom adfs.rom os300.rom sndrom\n\
(downloaded automatically if missing).\n\n\
Tapes type CHAIN\"\" automatically; discs boot with SHIFT+BREAK.\n\
Per-game typing: put the commands in <game>.autotype next to the game, one per line\n\
(e.g. *RUN).\n\n\
Keys: F1 = Electron ESCAPE, F12 = BREAK, F11 = menu, ESC = quit.\n\
Gamepad: Select+Start = quit (joy_quit_buttons in elk.cfg).\n\n\
Settings: $configdir/electron/elk.cfg"
rp_module_licence="GPL2 https://raw.githubusercontent.com/stardot/elkulator/master/COPYING"
rp_module_repo="git https://github.com/stardot/elkulator.git master"
rp_module_section="exp"
rp_module_flags=""

# BIOS ROMs and their sha1sums (same files as the Elkulator v1.0 release)
_elk_roms=(
    "os:2863b45dc880a7ed91ad9828795a3eb5ed0bcdd4"
    "basic.rom:4a7393f3a45ea309f744441c16723e2ef447a281"
    "plus1.rom:2de04ab7c81414d6c9c967f965c53fc276392463"
    "dfs.rom:eaf340b64a0a747ec479e575cc7b07cf928fd845"
    "adfs.rom:e7c7a1094d50a3579751df2007269067c8ff6812"
    "os300.rom:e759e77efd8073c74a04b3907adcca4c6edd1cc8"
    "sndrom:2e409b92c97cda34ff25c2951e5f799125fe7e32"
)
_elk_rom_url="https://raw.githubusercontent.com/demrepofdave/elkulator/demrepofdave/allegro5_integration/roms"
_elk_rom_tarball="http://elkulator.acornelectron.co.uk/ElkulatorV1.0Linux.tar.gz"

function depends_elkulator() {
    getDepends xorg matchbox-window-manager x11-xserver-utils xmlstarlet \
        autoconf automake liballegro4-dev libopenal-dev zlib1g-dev
}

function sources_elkulator() {
    # start from a clean tree so the patches always apply to pristine source
    if [[ -d "$md_build/.git" ]]; then
        git -C "$md_build" reset --hard -q
        git -C "$md_build" clean -fdxq
    fi
    gitPullOrClone

    # upstream source uses CRLF line endings; the patches are LF (Unix)
    find "$md_build/src" -maxdepth 1 -type f \
        \( -name '*.c' -o -name '*.h' -o -name '*.cpp' -o -name 'Makefile.am' \) \
        -exec sed -i 's/\r$//' {} +
    sed -i 's/\r$//' "$md_build/configure.ac"

    local patch
    for patch in "$md_data/patches/"*.diff; do
        [[ -f "$patch" ]] || continue
        applyPatch "$patch" || return 1
    done
}

function build_elkulator() {
    aclocal -I m4
    automake -a -i
    autoconf
    ./configure
    make clean
    make -j"$(nproc)"
    md_ret_require="$md_build/src/elkulator"
}

function install_elkulator() {
    cp -v "src/elkulator" "$md_inst/"
    cp -v "elk.cfg" "$md_inst/elk.cfg.default"
    cp -rv "ddnoise" "$md_inst/"
    local doc
    for doc in readme.txt Readme-LINUX.txt Readme-ROMS.txt COPYING; do
        [[ -f "$doc" ]] && cp -v "$doc" "$md_inst/"
    done
}

function _get_roms_elkulator() {
    local dir="$biosdir/electron"
    local entry file sum missing=()
    mkUserDir "$dir"

    for entry in "${_elk_roms[@]}"; do
        file="${entry%%:*}"
        [[ -f "$dir/$file" ]] && continue
        download "$_elk_rom_url/$file" "$dir/$file"
        sum="${entry##*:}"
        if [[ ! -s "$dir/$file" ]] || [[ "$(sha1sum "$dir/$file" | cut -d' ' -f1)" != "$sum" ]]; then
            rm -f "$dir/$file"
            missing+=("$file")
        fi
    done

    # fall back to the official Elkulator v1.0 release
    if [[ ${#missing[@]} -gt 0 ]]; then
        local tmp
        tmp="$(mktemp -d)"
        if downloadAndExtract "$_elk_rom_tarball" "$tmp"; then
            for file in "${missing[@]}"; do
                local src
                src="$(find "$tmp" -type f -path "*/roms/$file" | head -n 1)"
                [[ -n "$src" ]] && cp "$src" "$dir/$file"
            done
        fi
        rm -rf "$tmp"
    fi

    for entry in "${_elk_roms[@]}"; do
        file="${entry%%:*}"
        if [[ -f "$dir/$file" ]]; then
            chown "$user:$user" "$dir/$file"
        else
            md_ret_errors+=("Missing BIOS ROM $dir/$file - copy it in manually")
        fi
    done
}

function _default_cfg_elkulator() {
    local cfg="$1"
    cp "$md_inst/elk.cfg.default" "$cfg"
    sed -i 's/\r$//' "$cfg"
    # the upstream default config remembers a demo disc - drop it
    sed -i '/^discname_[01] = /d' "$cfg"

    iniConfig " = " "" "$cfg"
    iniSet "tapespeed" "1"
    iniSet "plus1" "1"
    iniSet "plus3" "0"
    iniSet "dfsena" "0"
    iniSet "adfsena" "0"
    iniSet "defaultwriteprotect" "0"
    iniSet "turbo" "0"
    iniSet "mrb" "0"
    iniSet "mrbmode" "0"
    iniSet "ulamode" "0"
    iniSet "key_define_047" "59"
    iniSet "fullscreen_scale" "0"
    iniSet "display_scale" "2"
    iniSet "joy_quit_buttons" "10,11"
}

function _add_es_system_elkulator() {
    local es_cfg="$configdir/all/emulationstation/es_systems.cfg"
    [[ -f "$es_cfg" ]] || es_cfg="/etc/emulationstation/es_systems.cfg"
    [[ -f "$es_cfg" ]] || return 0
    grep -q "<name>electron</name>" "$es_cfg" && return 0

    local block
    block="$(cat <<_EOF_
  <system>
    <name>electron</name>
    <fullname>Acorn Electron</fullname>
    <path>$romdir/electron</path>
    <extension>.rom .uef .ssd .adm .dsd .adf .ROM .UEF .SSD .ADM .DSD .ADF</extension>
    <command>/opt/retropie/supplementary/runcommand/runcommand.sh 0 _SYS_ electron %ROM%</command>
    <platform>electron</platform>
    <theme>electron</theme>
  </system>
_EOF_
)"

    cp -p "$es_cfg" "$es_cfg.bak-elkulator"
    local tmp
    tmp="$(mktemp)"
    # insert after the oric system; otherwise before c64; otherwise at the end
    BLOCK="$block" awk '
        BEGIN { block = ENVIRON["BLOCK"]; done = 0 }
        {
            lines[++n] = $0
        }
        END {
            # find the oric system and its closing tag
            oric_end = 0; c64_start = 0; start = 0
            for (i = 1; i <= n; i++) {
                if (lines[i] ~ /<system>/) start = i
                if (lines[i] ~ /<name>[[:space:]]*oric[[:space:]]*<\/name>/) in_oric = 1
                if (in_oric && lines[i] ~ /<\/system>/) { oric_end = i; in_oric = 0 }
                if (!c64_start && lines[i] ~ /<name>[[:space:]]*c64[[:space:]]*<\/name>/) c64_start = start
            }
            for (i = 1; i <= n; i++) {
                if (!done && c64_start && !oric_end && i == c64_start) { print block; done = 1 }
                if (!done && !oric_end && !c64_start && lines[i] ~ /<\/systemList>/) { print block; done = 1 }
                print lines[i]
                if (!done && oric_end && i == oric_end) { print block; done = 1 }
            }
        }
    ' "$es_cfg" > "$tmp" && cat "$tmp" > "$es_cfg"
    rm -f "$tmp"
}

function _write_launcher_elkulator() {
    local launcher="$md_inst/elkulator.sh"
    cat > "$launcher" <<_EOF_
#!/bin/bash
# Elkulator launcher - generated by the RetroPie elkulator module.
# This file is rewritten on every install/update of Elkulator.
# Per-game commands: put them in <game>.autotype next to the game file.

ELK_DIR="$md_inst"
ELK_CFG="$configdir/electron/elk.cfg"
_EOF_
    cat >> "$launcher" <<'_EOF_'

rom="$1"
[[ -f "$rom" ]] || { echo "Elkulator: file not found: $rom" >&2; exit 1; }

set_cfg() {
    local key="$1" val="$2"
    if grep -q "^${key} = " "$ELK_CFG"; then
        sed -i "s|^${key} = .*|${key} = ${val}|" "$ELK_CFG"
    else
        echo "${key} = ${val}" >> "$ELK_CFG"
    fi
}

# plus3 dfsena adfsena
filing_system() {
    set_cfg plus3 "$1"
    set_cfg dfsena "$2"
    set_cfg adfsena "$3"
}

# <game>.autotype -> one command per line, each followed by RETURN
autotype_override() {
    local f="${rom%.*}.autotype"
    [[ -f "$f" ]] || return 1
    tr -d '\r' < "$f" | awk 'NF { printf "%s\\n", $0 }'
}

# forget the last disc used, so only this game's media is inserted
sed -i '/^discname_[01] = /d' "$ELK_CFG"

args=(-fullscreen)
ext="${rom##*.}"
ext="${ext,,}"

case "$ext" in
    uef|csw)
        filing_system 0 0 0
        cmd="$(autotype_override)" || cmd='CHAIN""\n'
        args+=(-tape "$rom" -autotype "$cmd")
        ;;
    ssd|dsd)
        filing_system 1 1 0
        args+=(-disc "$rom" -autoboot)
        cmd="$(autotype_override)" && args+=(-autotype "$cmd")
        ;;
    adf|adm|adl)
        filing_system 1 0 1
        args+=(-disc "$rom" -autoboot)
        cmd="$(autotype_override)" && args+=(-autotype "$cmd")
        ;;
    rom)
        filing_system 0 0 0
        base="${rom%.*}"
        sfx="${rom##*.}"
        if [[ "$base" == *_1 && -f "${base%_1}_2.$sfx" ]]; then
            args+=(-rom 0 "$rom" -rom 1 "${base%_1}_2.$sfx")
        elif [[ "$base" == *_2 && -f "${base%_2}_1.$sfx" ]]; then
            args+=(-rom 0 "${base%_2}_1.$sfx" -rom 1 "$rom")
        else
            args+=(-rom 0 "$rom")
        fi
        ;;
    *)
        echo "Elkulator: unsupported file type: $rom" >&2
        exit 1
        ;;
esac

# sound straight to ALSA (no PulseAudio)
export ALSOFT_DRIVERS=alsa

# no screen blanking
xset -dpms s off s noblank 2>/dev/null

# display_scale in elk.cfg: 2 (default) = X runs at half the TV resolution
# and the display doubles it, so Elkulator's menus are twice the size;
# 1 = full TV resolution
scale="$(awk -F' = ' '$1 == "display_scale" { print $2; exit }' "$ELK_CFG")"
xr_scale=()
[[ "$scale" != "1" ]] && xr_scale=(--scale 0.5x0.5 --filter nearest)

# the Electron runs at 50 Hz: switch the current resolution to 50 Hz if the
# TV supports it (X is closed on exit, so the normal mode returns)
out="$(xrandr --query 2>/dev/null | awk '/ connected/ { print $1; exit }')"
mode="$(xrandr --query 2>/dev/null | awk '/\*/ { print $1; exit }')"
if [[ -n "$out" && -n "$mode" ]]; then
    if xrandr --output "$out" --mode "$mode" --rate 50 "${xr_scale[@]}" 2>/dev/null; then
        echo "Elkulator: requested $mode at 50 Hz on $out ${xr_scale[*]}"
    elif xrandr --output "$out" --mode "$mode" "${xr_scale[@]}" 2>/dev/null; then
        echo "Elkulator: $out does not offer $mode at 50 Hz - keeping the current rate ${xr_scale[*]}"
    else
        echo "Elkulator: display scaling not available - using the full resolution"
        xrandr --output "$out" --mode "$mode" --rate 50 2>/dev/null
    fi
    # the rate marked * is the one in use; the others are what the TV offers
    xrandr --query 2>/dev/null | awk '/\*/ { $1 = $1; print "Elkulator: now " $0; exit }'
    xrandr --query 2>/dev/null | awk '/^Screen/ { sub(/.*current /, ""); sub(/,.*/, ""); print "Elkulator: X screen " $0; exit }'
fi

# Elkulator finds roms/, ddnoise/ and elk.cfg next to its executable
cd "$ELK_DIR" || exit 1
exec ./elkulator "${args[@]}"
_EOF_
    chmod 755 "$launcher"
}

function configure_elkulator() {
    mkRomDir "electron"
    mkUserDir "$configdir/electron"

    if [[ "$md_mode" == "remove" ]]; then
        delEmulator "$md_id" "electron"
        return
    fi

    # BIOS ROMs live in the bios share; Elkulator looks in <install>/roms
    _get_roms_elkulator
    rm -rf "$md_inst/roms"
    ln -sfn "$biosdir/electron" "$md_inst/roms"

    # elk.cfg lives in configs/electron; defaults only on first install.
    # A config without fullscreen_scale was made by an older (unpatched)
    # Elkulator install - keep a copy and start afresh.
    local cfg="$configdir/electron/elk.cfg"
    if [[ -f "$cfg" ]] && ! grep -q "^fullscreen_scale" "$cfg"; then
        mv "$cfg" "$cfg.old"
    fi
    if [[ ! -f "$cfg" ]]; then
        _default_cfg_elkulator "$cfg"
    fi
    chown "$user:$user" "$cfg"
    rm -f "$md_inst/elk.cfg"
    ln -sf "$cfg" "$md_inst/elk.cfg"

    _write_launcher_elkulator

    # XINIT: runcommand starts X without a window manager. Elkulator's
    # desktop-sized window then covers the screen with no title bar, and
    # no window manager can take keys such as F11 for itself.
    # (remove the x11 backend set by earlier versions of this module)
    if [[ -f "$configdir/all/backends.cfg" ]]; then
        iniConfig " = " '"' "$configdir/all/backends.cfg"
        iniDel "$md_id"
    fi
    addEmulator 1 "$md_id" "electron" "XINIT:$md_inst/elkulator.sh %ROM%"
    _add_es_system_elkulator
}
