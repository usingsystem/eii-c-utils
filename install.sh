#!/bin/bash -e

# Copyright (c) 2020 Intel Corporation.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

RED='\033[0;31m'
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
NC='\033[0m' # No Color

function log_warn() {
    echo -e "${YELLOW}WARN: $1 ${NC}"
}

function log_info() {
    echo -e "${GREEN}INFO: $1 ${NC}"
}

function log_error() {
    echo -e "${RED}ERROR: $1 ${NC}"
}

function log_fatal() {
    echo -e "${RED}FATAL: $1 ${NC}"
    exit -1
}

function check_error() {
    if [ $? -ne 0 ] ; then
        log_fatal "$1"
    fi
}

CUR_DIR=`pwd`
INSTALL_PATH="$CMAKE_INSTALL_PREFIX/lib"
wjelement_commit="1c792c1669fd8441cf17647facc0cc908441dc0d"
# cjson version
cjson_version="1.7.12"

# URLs
wjelement_url="https://github.com/netmail-open/wjelement"
cjson_url="https://github.com/DaveGamble/cJSON/archive/v${cjson_version}.tar.gz"

wjelement_dir="wjelement"

DEPS=deps
if [ -d "$DEPS" ] ; then
    rm -rf $DEPS
    mkdir $DEPS
    check_error "Failed to create dependencies directory"
else
    mkdir $DEPS
fi

cd $DEPS

# Installing WJElement dependency
if [ -f "$INSTALL_PATH/libwjelement.so" ]; then
    log_info "libwjelement already installed"
else

    git clone $wjelement_url
    check_error "Failed to git clone wjelement"

    cd $wjelement_dir/
    check_error "Failed to change to wjelement directory"

    git checkout  -b known_version $wjelement_commit
    check_error "Failed to checkout to a commit"

    if [ ! -d "build" ] ; then
        mkdir build
        check_error "Failed to create build directory"
    fi

    cd build
    check_error "Failed to change to build directory"

    log_info "Configuring wjelement for compilation"

    cmake -DCMAKE_INSTALL_INCLUDEDIR=$CMAKE_INSTALL_PREFIX/include -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} ..
    check_error "Failed to configure wjelement"

    make -j$(nproc --ignore=2)
    check_error "Failed to compile wjelement"

    log_info "Installing wjelement..."
    make install
    check_error "Failed to install wjelement"

    cd ../..
fi

# Installing cJSON dependency
if [ -f "$INSTALL_PATH/libcjson.so.${cjson_version}" ]; then
    log_info "libcjson ${cjson_version} already installed"
else
    if [ ! -f "cjson.tar.gz" ] ; then
        log_info "Downloading cJSON source"
        wget -q --show-progress $cjson_url -O cjson.tar.gz
        check_error "Failed to download cJSON source"
    fi

    cjson_dir="cJSON-${cjson_version}"

    if [ ! -d "$cjson_dir" ] ; then
        log_info "Extracting cJSON"
        tar xf cjson.tar.gz
        check_error "Failed to extract cJSON"
    fi

    cd $cjson_dir
    check_error "Failed to change to cJSON directory"

    if [ ! -d "build" ] ; then
        mkdir build
        check_error "Failed to create build directory"
    fi

    cd build
    check_error "Failed to change to build directory"

    log_info "Configuring cJSON for compilation"
    cmake -DCMAKE_INSTALL_INCLUDEDIR=$CMAKE_INSTALL_PREFIX/include -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX} ..
    check_error "Failed to configure cJSON"

    log_info "Compiling cJSON library"
    make -j$(nproc --ignore=2)
    check_error "Failed to compile cJSON library"

    log_info "Installing cJSON library"
    make install
    check_error "Failed to install cJSON library"
fi

# Installing IntelSafeString dependency
if [ -f "$INSTALL_PATH/libsafestring.so" ]; then
    log_info "libsafestring already installed"
else
    cd $CUR_DIR/IntelSafeString

    rm -rf build
    check_error "Failed to remove existing build directory"

    mkdir build
    check_error "Failed to create build directory"

    cd build/
    check_error "Failed to change to build directory"

    log_info "Configuring IntelSafeString for compilation"
    cmake ..
    check_error "Failed to configure IntelSafeString"

    log_info "Compiling IntelSafeString libary"
    make -j$(nproc --ignore=2)
    check_error "Failed to compile IntelSafeString library"

    log_info "Installing IntelSafeString library"
    make install
    check_error "Failed to install IntelSafeString library"
fi

log_info "Done."
