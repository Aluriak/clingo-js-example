#!/usr/bin/env bash

set -e
set -x

# install emscripten (copy-paste of documentation)
#mkdir -p emscripten
#cd emscripten
#wget http://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-portable.tar.gz -O emsdk-portable.tar.gz
#tar -xvf emsdk-portable.tar.gz
#cd emsdk-portable
#git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
git pull

# Fetch the latest registry of available tools.
#./emsdk update
# Download and install the latest SDK tools.
./emsdk install latest
# Make the "latest" SDK "active" for the current user. (writes ~/.emscripten file)
./emsdk activate latest
# Activate PATH and other environment variables in the current terminal
source ./emsdk_env.sh
cd ..

# compile lua
unzip -o lua.zip -d lua
cd lua
emcmake make generic local
cd ..

# now compile clingo
if [ ! -d "clingo" ] ; then
    git clone https://github.com/potassco/clingo.git
    cd clingo
else
    cd clingo
    git pull
fi
git submodule update --init --recursive

mkdir -p build/web
cd build/web

emcmake cmake \
        -DCLINGO_BUILD_WEB=On \
        -DCLINGO_BUILD_WITH_PYTHON=On \
		-DCLINGO_REQUIRE_PYTHON=On \
		-DPYCLINGO_USER_INSTALL=Off \
		-DPYTHON_INCLUDE_DIR="$(pwd)/../../../Python-2.7.16/Include" \
		-DPYTHON_LIBRARY="$(pwd)/../../../Python-2.7.16/libpython2.7.a" \
        -DLUA_INCLUDE_DIR="$(pwd)/../../../lua/install/include" \
        -DLUA_LIBRARIES="$(pwd)/../../../lua/install/lib/liblua.a" \
        -DCLINGO_BUILD_WITH_LUA=On \
        -DCLINGO_REQUIRE_LUA=On \
        -DCLINGO_BUILD_SHARED=Off \
        -DCLASP_BUILD_WITH_THREADS=Off \
        -DCMAKE_VERBOSE_MAKEFILE=On \
        -DCMAKE_BUILD_TYPE=release \
        -DCMAKE_CXX_FLAGS="-s ALLOW_MEMORY_GROWTH=1 -s MODULARIZE=1" \
        -DCMAKE_EXE_LINKER_FLAGS="" \
        -DCMAKE_EXE_LINKER_FLAGS_RELEASE="" \
        ../..

cd ../..
make -C build/web web

# copy the result into the test site
cd ..  # return to root
cp ./clingo/build/web/bin/clingo.* ./docs/js/
