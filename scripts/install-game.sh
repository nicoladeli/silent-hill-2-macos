#!/bin/zsh
# Instala Silent Hill 2 (PC) + Enhanced Edition (+ tradução opcional) no prefixo do port.
#
# Uso:
#   scripts/install-game.sh --setup "Silent Hill Setup.rar" [--langpack SH2EE_LangPack_X.zip] [--ee-setup SH2EEsetup.exe]
#
# --setup     .rar/.zip/.iso do instalador original OU a pasta com data1.cab
# --langpack  pacote de idioma do Enhanced Edition (pasta lang/ + language.ini)
# --ee-setup  SH2EEsetup.exe local (padrão: baixa do site oficial do projeto)
set -e
source "${0:A:h}/env.sh"

EE_SETUP_URL="https://files.townofsilenthill.com/SH2EE/SH2EEsetup.exe"
SETUP="" LANGPACK="" EE_SETUP="" FORCE=0
while (( $# )); do
    case $1 in
        --setup)    SETUP="${2:A}"; shift 2 ;;
        --langpack) LANGPACK="${2:A}"; shift 2 ;;
        --ee-setup) EE_SETUP="${2:A}"; shift 2 ;;
        --force)    FORCE=1; shift ;;
        *) echo "opção desconhecida: $1"; exit 1 ;;
    esac
done

step() { print -P "%F{cyan}==> $*%f" }
die()  { print -P "%F{red}erro: $*%f"; exit 1 }

[[ -n $SETUP && -e $SETUP ]] || die "informe o instalador do jogo com --setup"
[[ -x $SH2_WINE/bin/wine ]] || die "Wine não encontrado em $SH2_WINE — rode scripts/build-wine.sh"
if [[ -d $SH2_GAME_DIR && $FORCE == 0 ]]; then
    die "já existe uma instalação em $SH2_GAME_DIR (seus saves ficam lá). Use --force para reinstalar."
fi

TMP="$(mktemp -d)"
trap 'chmod -R u+w "$TMP" 2>/dev/null; rm -rf "$TMP"' EXIT

step "Lendo o instalador original"
if [[ -d $SETUP ]]; then
    CAB_DIR="$SETUP"
else
    unar -q -o "$TMP/setup" "$SETUP"
    CAB_DIR="$(dirname "$(find "$TMP/setup" -iname data1.cab | head -1)")"
fi
[[ -f $CAB_DIR/data1.cab ]] || die "data1.cab não encontrado no instalador"

step "Criando o prefixo Wine em $WINEPREFIX"
# mscoree/mshtml vazios: sem isso o wineboot fica parado na janela de instalar Wine Mono/Gecko,
# que o jogo não usa
WINEDLLOVERRIDES="mscoree,mshtml=" wine wineboot --init >/dev/null 2>&1
wineserver -w
wine reg add 'HKCU\Software\Wine\DllOverrides' /v d3d8 /d native,builtin /f >/dev/null
wine reg add 'HKCU\Software\Wine\DllOverrides' /v dinput8 /d native,builtin /f >/dev/null
wine reg add 'HKCU\Software\Wine\Mac Driver' /v CaptureDisplaysForFullscreen /d n /f >/dev/null
wine reg add 'HKCU\Software\Wine\Mac Driver' /v RetinaMode /d n /f >/dev/null
wine reg add 'HKCU\Software\Wine\Direct3D' /v VideoMemorySize /d 2048 /f >/dev/null
wine reg add 'HKCU\Software\Wine\Direct3D' /v csmt /t REG_DWORD /d 1 /f >/dev/null

step "Extraindo o jogo (InstallShield)"
mkdir -p "$SH2_GAME_DIR/data/movie"
unshield -d "$TMP/cab" -g "Program Files" x "$CAB_DIR/data1.cab" >/dev/null
unshield -d "$TMP/cab" -g "Data Files" x "$CAB_DIR/data1.cab" >/dev/null
cp -R "$TMP/cab/Program_Files/." "$SH2_GAME_DIR/"
cp -R "$TMP/cab/Data_Files/." "$SH2_GAME_DIR/data/"
cp "$CAB_DIR"/movie/*.bik "$SH2_GAME_DIR/data/movie/"

step "Instalando o Enhanced Edition (baixa ~4 GB)"
if [[ -n $EE_SETUP ]]; then
    cp "$EE_SETUP" "$SH2_GAME_DIR/SH2EEsetup.exe"
else
    curl -fL -o "$SH2_GAME_DIR/SH2EEsetup.exe" "$EE_SETUP_URL"
fi
(cd "$SH2_GAME_DIR" && wine SH2EEsetup.exe /LANG=pt_br /SILENT /SUPPRESSMSGBOXES /NORESTART "/LOG=C:\\sh2ee-install.log")
wineserver -w
grep -aq "Installation process succeeded" "$WINEPREFIX/drive_c/sh2ee-install.log" || die "o instalador do EE falhou (veja $WINEPREFIX/drive_c/sh2ee-install.log)"

step "Desligando a flag Large Address Aware do executável"
cp -n "$SH2_GAME_DIR/sh2pc.exe" "$SH2_GAME_DIR/sh2pc.exe.laa"
python3 -I - "$SH2_GAME_DIR/sh2pc.exe" <<'EOF'
import struct, sys
path = sys.argv[1]
data = bytearray(open(path, 'rb').read())
off = struct.unpack_from('<I', data, 0x3c)[0] + 4 + 18
flags = struct.unpack_from('<H', data, off)[0]
struct.pack_into('<H', data, off, flags & ~0x20)
open(path, 'wb').write(data)
EOF

if [[ -n $LANGPACK ]]; then
    step "Aplicando pacote de idioma"
    unzip -oq "$LANGPACK" -d "$SH2_GAME_DIR"
    chmod -R u+w "$SH2_GAME_DIR/lang"
    rm -f "$SH2_GAME_DIR"/lang/**/desktop.ini(N)
fi

step "Criando os apps em /Applications"
zsh "$SH2_PORT/scripts/make-apps.sh" "${SH2_APPS_DIR:-/Applications}"

step "Pronto! Abra \"Silent Hill 2\" pelo Launchpad."
