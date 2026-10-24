#!/bin/zsh
# Cria "Silent Hill 2.app" e "Fechar Silent Hill 2.app" em /Applications.
# Os apps só chamam scripts/launch.sh e scripts/quit.sh deste repositório.
set -e
source "${0:A:h}/env.sh"

DEST="${1:-/Applications}"

make_icon() {
    local out="$1" ico="$SH2_GAME_DIR/sh2.ico" set
    [[ -f $ico ]] || return 0
    set="$(mktemp -d)/sh2.iconset"; mkdir -p "$set"
    for s in 16 32 128 256 512; do
        sips -s format png -z $s $s "$ico" --out "$set/icon_${s}x${s}.png" >/dev/null
    done
    iconutil -c icns "$set" -o "$out"
}

make_app() {
    local name="$1" exe="$2" script="$3" id="$4" extra="$5"
    local app="$DEST/$name.app"
    rm -rf "$app"
    mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
    cat > "$app/Contents/MacOS/$exe" <<EOF
#!/bin/zsh
export SH2_HOME="$SH2_HOME"
exec "$SH2_PORT/scripts/$script" "\$@"
EOF
    chmod +x "$app/Contents/MacOS/$exe"
    cat > "$app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>$name</string>
  <key>CFBundleDisplayName</key><string>$name</string>
  <key>CFBundleIdentifier</key><string>$id</string>
  <key>CFBundleExecutable</key><string>$exe</string>
  <key>CFBundleIconFile</key><string>sh2</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.games</string>
  <key>NSHighResolutionCapable</key><true/>
  $extra
</dict></plist>
EOF
    make_icon "$app/Contents/Resources/sh2.icns"
    echo "criado: $app"
}

make_app "Silent Hill 2" SilentHill2 launch.sh io.github.sh2-mac-port \
    '<key>LSSupportsGameMode</key><true/>'
make_app "Fechar Silent Hill 2" FecharSH2 quit.sh io.github.sh2-mac-port.quit \
    '<key>LSUIElement</key><true/>'
