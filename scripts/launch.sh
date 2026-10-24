#!/bin/zsh
# Abre o Silent Hill 2 Enhanced Edition com o Wine compilado do port.
source "${0:A:h}/env.sh"

cd "$SH2_GAME_DIR" || { echo "Jogo não encontrado em $SH2_GAME_DIR — rode scripts/install-game.sh"; exit 1; }

# Reaplica as opções do port no d3d8.ini (o EE cria o arquivo na primeira execução)
if [[ -f d3d8.ini ]]; then
    section=""
    while IFS='=' read -r key value; do
        key=${key// /}; value=${value// /}
        [[ -z $key || $key == \;* ]] && continue
        if [[ $key == \[* ]]; then section=$key; continue; fi
        if grep -q "^$key = " d3d8.ini; then
            sed -i '' "s/^$key = .*/$key = $value/" d3d8.ini
        else
            sed -i '' "s/^\\$section\$/&\\
$key = $value/" d3d8.ini
        fi
    done < "$SH2_PORT/config/d3d8-overrides.ini"
fi

wine sh2pc.exe "$@"
wineserver -k
