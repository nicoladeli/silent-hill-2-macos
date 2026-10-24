#!/bin/zsh
# Compila o Wine do código-fonte aberto do CrossOver (LGPL) para macOS x86_64 + WoW64 (i386).
# Resultado: $SH2_HOME/wine
#
# Requisitos: Mac Apple Silicon com Rosetta 2, Xcode Command Line Tools e Homebrew.
set -e
source "${0:A:h}/env.sh"

CX_VERSION="${CX_VERSION:-26.3.0}"
CX_URL="https://media.codeweavers.com/pub/crossover/source/crossover-sources-$CX_VERSION.tar.gz"
# Bibliotecas x86_64 (freetype, gnutls e dependências) tiradas do build open source do Gcenx
DEPS_URL="https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.18/wine-staging-11.18-osx64.tar.xz"

DEPS="$SH2_BUILD/deps"
SRC="$SH2_BUILD/sources/wine"
OBJ="$SH2_BUILD/wine-build"
JOBS="${JOBS:-$(sysctl -n hw.ncpu)}"

step() { print -P "%F{cyan}==> $*%f" }

step "Ferramentas de build (Homebrew)"
for f in bison flex mingw-w64 pkgconf freetype gnutls unshield unar; do
    brew list --formula $f >/dev/null 2>&1 || brew install $f
done

mkdir -p "$SH2_BUILD"
cd "$SH2_BUILD"

if [[ ! -d $SRC ]]; then
    step "Baixando fonte do CrossOver $CX_VERSION"
    curl -fL -o crossover-sources.tar.gz "$CX_URL"
    tar xzf crossover-sources.tar.gz sources/wine
    step "Aplicando patches do port"
    for p in "$SH2_PORT"/patches/*.patch; do
        patch -d "$SRC" -p1 < "$p"
    done
fi

if [[ ! -d $DEPS/lib ]]; then
    step "Montando bibliotecas x86_64"
    mkdir -p "$DEPS/lib/pkgconfig" "$DEPS/include"
    curl -fL -o deps.tar.xz "$DEPS_URL"
    tar xJf deps.tar.xz --strip-components 5 -C "$DEPS/lib" --include='Wine Staging.app/Contents/Resources/wine/lib/*.dylib'
    rm -f deps.tar.xz
    # As ferramentas de build (ex.: sfnt2fon) linkam freetype/gnutls: ID via @rpath + -rpath no LDFLAGS
    for l in libfreetype libgnutls; do
        real="$(readlink -f "$DEPS/lib/$l.dylib")"
        install_name_tool -id "@rpath/${real:t}" "$real"
        codesign -f -s - "$real"
    done
    # Headers são independentes de arquitetura: vêm do Homebrew
    cp -R "$(brew --prefix freetype)/include/freetype2" "$DEPS/include/"
    cp -R "$(brew --prefix gnutls)/include/gnutls" "$DEPS/include/"
    print "prefix=$DEPS\nName: freetype2\nDescription: freetype\nVersion: 26.2.20\nCflags: -I\${prefix}/include/freetype2\nLibs: -L\${prefix}/lib -lfreetype" > "$DEPS/lib/pkgconfig/freetype2.pc"
    print "prefix=$DEPS\nName: gnutls\nDescription: gnutls\nVersion: 3.8.9\nCflags: -I\${prefix}/include\nLibs: -L\${prefix}/lib -lgnutls" > "$DEPS/lib/pkgconfig/gnutls.pc"
fi

step "Configurando (x86_64 via Rosetta)"
mkdir -p "$OBJ"
cd "$OBJ"
arch -x86_64 /bin/zsh -c "
export PATH=$(brew --prefix bison)/bin:$(brew --prefix flex)/bin:$(brew --prefix)/bin:/usr/bin:/bin:/usr/sbin:/sbin
export PKG_CONFIG_LIBDIR=$DEPS/lib/pkgconfig
export CC='clang -arch x86_64' CXX='clang++ -arch x86_64' OBJC='clang -arch x86_64'
export CFLAGS='-O2 -Wno-deprecated-declarations -Wno-incompatible-pointer-types -Wno-int-conversion'
export LDFLAGS='-Wl,-rpath,$DEPS/lib -Wl,-headerpad_max_install_names'
$SRC/configure --prefix=$SH2_WINE --enable-archs=i386,x86_64 --disable-tests \
  --with-coreaudio --with-freetype --with-gnutls --with-mingw --with-unwind --with-pthread \
  --without-vulkan --without-gstreamer --without-sdl --without-x --without-wayland --without-alsa --without-pulse --without-oss \
  --without-dbus --without-fontconfig --without-cups --without-sane --without-gphoto --without-krb5 --without-gssapi \
  --without-netapi --without-pcap --without-pcsclite --without-v4l2 --without-usb --without-udev --without-capi --without-inotify --without-opencl
"

step "Compilando com $JOBS núcleos (30-60 min)"
arch -x86_64 /bin/zsh -c "export PATH=$(brew --prefix bison)/bin:$(brew --prefix flex)/bin:$(brew --prefix)/bin:/usr/bin:/bin:/usr/sbin:/sbin; make -j$JOBS && make install"

step "Copiando bibliotecas para $SH2_WINE/lib"
cp "$DEPS"/lib/*.dylib "$SH2_WINE/lib/"

"$SH2_WINE/bin/wine" --version
step "Wine pronto em $SH2_WINE"
