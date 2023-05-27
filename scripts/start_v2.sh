#!/bin/bash

source ./scripts/functions.sh

set -o pipefail

OS_NAME=$(uname -s)
case "${OS_NAME}" in
    Linux*)     OS_NAME="linux";;
    Darwin*)    OS_NAME="osx";;
    *)          echo "Unknown OS: $OS_NAME! This script runs only on Linux or Mac" && exit
esac

OS_ARCH=$(uname -m)
case "${OS_ARCH}" in
    x86_64*)    OS_ARCH="64";;
    arm64*)     OS_ARCH="arm64";;
    aarch64*)     OS_ARCH="arm64";;
    *)          echo "Unknown system architecture: $OS_ARCH! This script runs only on x86_64 or arm64" && exit
esac

if ! which curl &> /dev/null; then fail "'curl' not found. Please install curl."; fi
if ! which tar &> /dev/null; then fail "'tar' not found. Please install tar."; fi
if ! which bzip2 &> /dev/null; then fail "'bzip2' not found. Please install bzip2."; fi
if ! which git &> /dev/null; then fail "'git' not found. Please install git."; fi


if pwd | grep ' '
    then
        fail "The installation directory's path contains a space character. Conda will fail to install. Please change the directory."
fi

# https://mamba.readthedocs.io/en/latest/installation.html
if [ "$OS_NAME" == "linux" ] && [ "$OS_ARCH" == "arm64" ]; then OS_ARCH="aarch64"; fi

# config
export MAMBA_ROOT_PREFIX="$(pwd)/installer_files/mamba"
INSTALL_ENV_DIR="$(pwd)/installer_files/env"
LEGACY_INSTALL_ENV_DIR="$(pwd)/installer"
MICROMAMBA_DOWNLOAD_URL="https://micro.mamba.pm/api/micromamba/${OS_NAME}-${OS_ARCH}/latest"
umamba_exists="F"

if [ -e "$INSTALL_ENV_DIR" ]; then export PATH="$INSTALL_ENV_DIR/bin:$PATH"; fi

PACKAGES_TO_INSTALL=""

if [ ! -e "$LEGACY_INSTALL_ENV_DIR/etc/profile.d/conda.sh" ] && [ ! -e "$INSTALL_ENV_DIR/etc/profile.d/conda.sh" ]
    then
        PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL conda python=3.8.5"
fi

if ! hash "git" &>/dev/null
    then
        PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL git"
fi

if "$MAMBA_ROOT_PREFIX/micromamba" --version &>/dev/null; then umamba_exists="T"; fi

echo "Installation packages"
echo $PACKAGES_TO_INSTALL
