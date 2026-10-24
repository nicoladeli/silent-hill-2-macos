#!/bin/zsh
# Encerra o jogo e todos os processos do Wine do port.
source "${0:A:h}/env.sh"

wineserver -k 2>/dev/null
pkill -f 'sh2pc.exe'
osascript -e 'display notification "Jogo encerrado" with title "Silent Hill 2"'
