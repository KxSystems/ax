export PATH="${PWD}/deps/depot_tools:${PATH}"

OS=$(uname -s)

if [ "$OS" == Darwin ]; then
    # Prevent GN from using GNU Binutils
    export PATH=$(echo "$PATH" | awk -v RS=: -v ORS=: '$0 != "/opt/homebrew/opt/binutils/bin"')
fi

cd deps/skia
python3 tools/git-sync-deps

if [ "$1" == "" ]; then
    CC=clang
    CXX=clang++
else
    CC=clang-$1
    CXX=clang++-$1
fi

ARGS="cc=\"$CC\" cxx=\"$CXX\" "\
'extra_cflags_cc=["-std=c++17"] '\
'is_official_build=true '\
'skia_enable_discrete_gpu=false '\
'skia_enable_fontmgr_custom_empty=true '\
'skia_enable_ganesh=false '\
'skia_use_gl=false '\
'skia_use_x11=false '\
'skia_enable_pdf=false '\
'skia_use_expat=false '\
'skia_use_freetype=true '\
'skia_use_libjpeg_turbo_decode=false '\
'skia_use_libjpeg_turbo_encode=false '\
'skia_use_libwebp_decode=false '\
'skia_use_libwebp_encode=false '\
'skia_use_piex=false '\
'skia_use_dng_sdk=false '\
'skia_use_system_expat=false '\
'skia_use_system_freetype2=false '\
'skia_use_system_harfbuzz=false '\
'skia_use_system_icu=false '\
'skia_use_system_libpng=false '\

SYS_ZLIB=false

if [ "$OS" == Darwin ]; then
    SYS_ZLIB=true
fi

ARGS=$ARGS"skia_use_system_zlib=$SYS_ZLIB"

bin/gn gen out/Static --args="$ARGS"

#bin/gn args out/Static --list
#exit 0

bin/fetch-ninja

ninja -C out/Static skia
