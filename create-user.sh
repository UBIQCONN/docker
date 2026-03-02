#!/bin/bash

uname="ubq"
gname="ubq_build"
upasswd="12345"

uid=${1:-1000}
gid=${2:-$uid}

# --- Check group (exact GID match) ---
if getent group "$gname" > /dev/null 2>&1; then
    echo "Group $gname already exists"
else
    groupadd -g "$gid" "$gname"
    if [ $? -eq 0 ]; then
        echo "Created group $gname($gid)."
    else
        echo "Create group failed!"
        exit 1
    fi
fi

# --- Check user (exact username match) ---
if getent passwd "$uname" > /dev/null 2>&1; then
    echo "User $uname already exists, skipping creation."
else
    useradd -d /home/$uname -s /bin/bash -u "$uid" -g "$gid" "$uname"
    if [ $? -eq 0 ]; then
        echo "Created user $uname($uid)."
        chown "$uname:$gname" /home/$uname
    else
        echo "Create user failed!"
        exit 1
    fi
fi

echo "$uname:$upasswd" | chpasswd

# --- Skeleton files (always ensure they exist) ---
for f in .bash_logout .bashrc .profile; do
    if [ ! -f /home/$uname/$f ]; then
        cp /etc/skel/$f /home/$uname/
    fi
    chown "$uname:$gname" /home/$uname/$f
done

# --- Workspace directory ---
if [ ! -d /home/$uname/workspace ]; then
    mkdir -p /home/$uname/workspace || { echo "mkdir workspace failed"; exit 1; }
    chown "$uname:$gname" /home/$uname/workspace
fi

# --- Add convenience build functions to .bashrc ---
MARKER="# == MTK BUILD FUNCTIONS =="
if ! grep -q "$MARKER" /home/$uname/.bashrc 2>/dev/null; then
    cat >> /home/$uname/.bashrc << 'BASHRC_EOF'

# == MTK BUILD FUNCTIONS ==

# Helper function to verify current path
mtk_check_workspace() {
    local current_path="$(pwd)"
    if [[ ! "$current_path" =~ (mt8391|mt8391_MSSI_V) ]]; then
        echo "⚠️  WARNING: Current path does not contain 'mt8391' or 'mt8391_MSSI_V'"
        echo "    Current path: $current_path"
        echo "    Please change to the correct workspace (mt8391 or mt8391_MSSI_V)"
        return 1
    fi
    return 0
}

mtk_build() {
    local lunch_target="${1:-vnd_aiot8391p2_64_bsp-userdebug}"
    local jobs="${2:-10}"
    
    # Check target is the expected default
    if [[ "$lunch_target" != "vnd_aiot8391p2_64_bsp-userdebug" ]]; then
        echo "⚠️  WARNING: Unexpected target: $lunch_target"
        echo "    Expected: vnd_aiot8391p2_64_bsp-userdebug"
        return 1
    fi

    # Verify workspace path
    mtk_check_workspace || return 1
    
    echo "==> Setting up build environment..."
    source build/envsetup.sh
    export OUT_DIR=out
    echo "==> lunch $lunch_target"
    lunch "$lunch_target"
    echo "==> Building with -j${jobs}..."
    make -j"$jobs" vnd_images krn_images 2>&1 | tee build.log
}

mtk_split_build() {
    local target="${1:-full_aiot8391p2_64_bsp-userdebug}"
    local vendor_path="${2:-}"
    
    # Check target is the expected default
    if [[ "$target" != "full_aiot8391p2_64_bsp-userdebug" ]]; then
        echo "⚠️  WARNING: Unexpected target: $target"
        echo "    Expected: full_aiot8391p2_64_bsp-userdebug"
        return 1
    fi
    
    # Verify workspace path
    mtk_check_workspace || return 1

    echo "==> Running split build: $target"
    if [[ -n "$vendor_path" ]]; then
        echo "==> Using vendor path: $vendor_path"
        python split_build_helper.py --run "$target" --vf-path "$vendor_path"
    else
        python split_build_helper.py --run "$target"
    fi
}

mtk_package() {
    local target="${1:-full_aiot8391p2_64_bsp-userdebug}"
    local output_path="${2:-../flash/${target}_t-alps-release-u0.mp5-aiot-V7.150.tar.gz}"
    
    # Verify workspace path
    mtk_check_workspace || return 1

    echo "==> Packaging target: $target"
    tar -czvf "$output_path" \
        -C out/target/product/aiot8391p2_64_bsp/merged/ \
        --exclude='target_files.zip' --exclude='testcases' .
}

echo "MTK build helpers loaded: mtk_build [lunch_target] [jobs], mtk_split_build [target]"
# == END MTK BUILD FUNCTIONS ==
BASHRC_EOF
    chown "$uname:$gname" /home/$uname/.bashrc
    echo "Added build functions to .bashrc"
fi
