#!/bin/zsh
# Caminhos e variáveis compartilhados por todos os scripts do port.
# SH2_HOME pode ser sobrescrito antes de chamar qualquer script.

: ${SH2_HOME:="$HOME/Games/SH2"}
SH2_WINE="$SH2_HOME/wine"
SH2_BUILD="$SH2_HOME/build"
SH2_GAME_DIR="$SH2_HOME/prefix/drive_c/Games/Silent Hill 2"
SH2_PORT="${0:A:h:h}"

export WINEPREFIX="$SH2_HOME/prefix"
export WINEDEBUG="${WINEDEBUG:--all}"
export WINEMSYNC=1
export DYLD_FALLBACK_LIBRARY_PATH="$SH2_WINE/lib"

wine()       { "$SH2_WINE/bin/wine" "$@" }
wineserver() { "$SH2_WINE/bin/wineserver" "$@" }
