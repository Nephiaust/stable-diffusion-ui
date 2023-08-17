#!/bin/bash

INSTALL_DIR="$(eval echo ~$USER)/stablediffusion"

# *******************************************************
# *******************************************************
# **                                                   **
# **            DO NOT EDIT BELOW THIS BLOCK           **
# **                                                   **
# **                INITIALISATION BLOCK               **
# **                                                   **
# *******************************************************
# *******************************************************

set -o pipefail

echo "Checking & Installing requirements for Easy Diffusion"

#source $INSTALL_DIR/scripts/functions.sh

# *******************************************************
# *******************************************************
# **                                                   **
# **              INTERNAL VARIABLES BLOCK             **
# **                                                   **
# *******************************************************
# *******************************************************

ORIGINAL_DIR=$pwd

OS_NAME=$(uname -s)
case "${OS_NAME}" in
    Linux*)     OS_NAME="linux";;
    Darwin*)    OS_NAME="osx";;
    *)          echo "Unknown OS: $OS_NAME! This script runs only on Linux or Mac" && exit
esac

OS_ARCH=$(uname -m)
case "${OS_ARCH}" in
    x86_64*)
        OS_ARCH="64";;
    arm64*)     
        case "${OS_NAME}" in
            Linux*)     OS_ARCH="aarch64";;
            *)          OS_ARCH="arm64";;
        esac;;
    aarch64*)
        OS_ARCH="aarch64";;
    *)
        echo "Unknown system architecture: $OS_ARCH! This script runs only on x86_64 or arm64" && exit
esac

export MAMBA_ROOT_PREFIX="$INSTALL_DIR/installer_files/mamba"
INSTALL_ENV_DIR="$INSTALL_DIR/installer_files/env"
LEGACY_INSTALL_ENV_DIR="$INSTALL_DIR/installer"
MICROMAMBA_DOWNLOAD_URL="https://micro.mamba.pm/api/micromamba/${OS_NAME}-${OS_ARCH}/latest"
umamba_exists="F"

# *******************************************************
# *******************************************************
# **                                                   **
# **                 FUNCTIONS BLOCK                   **
# **                                                   **
# *******************************************************
# *******************************************************

fail() {
    echo
    echo "EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE"
    echo
    if [ "$1" != "" ]; then
        echo ERROR: $1
    else
        echo An error occurred.
    fi
    cat <<EOF

Error downloading Stable Diffusion UI. Sorry about that, please try to:
 1. Run this installer again.
 2. If that doesn't fix it, please try the common troubleshooting steps at https://github.com/cmdr2/stable-diffusion-ui/wiki/Troubleshooting
 3. If those steps don't help, please copy *all* the error messages in this window, and ask the community at https://discord.com/invite/u9yhsFmEkB
 4. If that doesn't solve the problem, please file an issue at https://github.com/cmdr2/stable-diffusion-ui/issues

Thanks!


EOF
    read -p "Press any key to continue"
    exit 1
}

filesize() {
    case "$(uname -s)" in
        Linux*)     stat -c "%s" $1;;
        Darwin*)    /usr/bin/stat -f "%z" $1;;
        *)          echo "Unknown OS: $OS_NAME! This script runs only on Linux or Mac" && exit
    esac
}


# *******************************************************
# *******************************************************
# **                                                   **
# **                  MAIN CODE BLOCK                  **
# **                                                   **
# *******************************************************
# *******************************************************

if ! which curl &> /dev/null; then fail "'curl' not found. Please install curl."; fi
if ! which tar &> /dev/null; then fail "'tar' not found. Please install tar."; fi
if ! which bzip2 &> /dev/null; then fail "'bzip2' not found. Please install bzip2."; fi
#if ! which git &> /dev/null; then fail "'git' not found. Please install git."; fi

if pwd | grep ' '
    then
        fail "The installation directory's path contains a space character. Conda will fail to install. Please change the directory."
fi



if [ -e "$INSTALL_ENV_DIR" ]; then export PATH="$INSTALL_ENV_DIR/bin:$PATH"; fi

PACKAGES_TO_INSTALL=""

if [ ! -e "$LEGACY_INSTALL_ENV_DIR/etc/profile.d/conda.sh" ] && [ ! -e "$INSTALL_ENV_DIR/etc/profile.d/conda.sh" ]
    then
        PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL conda python=3.8.5"
        echo " * Need to install python"
fi

if ! hash "git" &>/dev/null
    then
        PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL git"
        echo " * Need to install git"
fi

if "$MAMBA_ROOT_PREFIX/micromamba" --version &>/dev/null
    then
        umamba_exists="T"
        echo " * Found micromamba"
fi

# (if necessary) install git and conda into a contained environment
if [ "$PACKAGES_TO_INSTALL" != "" ]; then
    # download micromamba
    if [ "$umamba_exists" == "F" ]; then
        echo " * Downloading micromamba for $OS_ARCH on $OS_NAME to $MAMBA_ROOT_PREFIX/micromamba"

        mkdir -p "$MAMBA_ROOT_PREFIX"
        curl --progress-bar -L "$MICROMAMBA_DOWNLOAD_URL" | tar -xj -O bin/micromamba > "$MAMBA_ROOT_PREFIX/micromamba"

        if [ "$?" != "0" ]; then
            echo
            echo "EE micromamba download failed"
            echo "EE If the lines above contain 'bzip2: Cannot exec', your system doesn't have bzip2 installed"
            echo "EE If there are network errors, please check your internet setup"
            fail "micromamba download failed"
        fi
        
        echo " * Enabling micromamba"
        chmod u+x "$MAMBA_ROOT_PREFIX/micromamba" &> /dev/null

        # test the mamba binary
        echo " * Micromamba version"
        "$MAMBA_ROOT_PREFIX/micromamba" --version
    fi

    # create the installer env
    if [ ! -e "$INSTALL_ENV_DIR" ]; then
        echo " * Creating empty micromamba envrionment at $INSTALL_ENV_DIR"
        "$MAMBA_ROOT_PREFIX/micromamba" create -y -q --prefix "$INSTALL_ENV_DIR" || fail "unable to create the install environment"
    fi

    # Double check that the enviroment directory was created.
    if [ ! -e "$INSTALL_ENV_DIR" ]; then
        fail "There was a problem while installing $PACKAGES_TO_INSTALL using micromamba. Cannot continue."
    fi

    echo " * Packages to install:$PACKAGES_TO_INSTALL"
    "$MAMBA_ROOT_PREFIX/micromamba" install -y --prefix "$INSTALL_ENV_DIR" -c conda-forge $PACKAGES_TO_INSTALL
    if [ "$?" != "0" ]; then
        fail "Installation of the packages '$PACKAGES_TO_INSTALL' failed."
    fi
fi

# Verify that the environment exists
if [ -e $INSTALL_ENV_DIR ]
    then
        echo " * Runtime environment set up and ready"
        export PATH="$INSTALL_ENV_DIR/bin:$PATH"
    else
        fail "Missing runtime environment"
fi

if ! which git &> /dev/null; then fail "'git' not found. Please install git."; fi
if ! which conda &> /dev/null; then fail "'conda' not found. Please install conda."; fi

echo ""
echo "Preparing to start Easy Diffusion"
echo ""

cd $INSTALL_DIR

export PYTHONPATH=$INSTALL_DIR/installer_files/env/lib/python3.8/site-packages:$INSTALL_DIR/stable-diffusion/env/lib/python3.8/site-packages


if [ -f "scripts/get_config.py" ]; then
    export update_branch="$( python scripts/get_config.py --default=main update_branch )"
fi

if [ "$update_branch" == "" ]; then
    export update_branch="main"
fi

if [ -f "scripts/install_status.txt" ] && [ `grep -c sd_ui_git_cloned scripts/install_status.txt` -gt "0" ]; then
    echo "Easy Diffusion's git repository was already installed. Updating from $update_branch.."
    mkdir scripts
    
    cd sd-ui-files

    git reset --hard
    git -c advice.detachedHead=false checkout "$update_branch"
    git pull

    cd ..
else
    printf "\n\nDownloading Easy Diffusion..\n\n"
    printf "Using the $update_branch channel\n\n"

    if git clone -b "$update_branch" https://github.com/cmdr2/stable-diffusion-ui.git sd-ui-files ; then
        echo sd_ui_git_cloned >> scripts/install_status.txt
    else
        fail "git clone failed"
    fi
fi

rm -rf ui
cp -Rf sd-ui-files/ui .
cp sd-ui-files/scripts/check_modules.py scripts/
cp sd-ui-files/scripts/check_models.py scripts/
cp sd-ui-files/scripts/get_config.py scripts/
cp sd-ui-files/scripts/developer_console.sh .
