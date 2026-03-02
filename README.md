# Docker Ubuntu 20.04 - MediaTek Build Environment

Docker container setup for MediaTek MT8391 Android builds (Ubuntu 20.04).

---

## Quick Start

```bash
# Start/enter the Docker container
./setenv_docker.sh
```

---

## Files

| File | Description |
|------|-------------|
| `setenv_docker.sh` | Create/start/enter Docker container |
| `create-user.sh` | Setup build user and install MTK build helper functions |

---

## MTK Build Helper Functions

Once inside the container, the following functions are available in your shell.

### `mtk_build [lunch_target] [jobs]`

Build vendor and kernel images using `make`.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `lunch_target` | `vnd_aiot8391p2_64_bsp-userdebug` | Lunch target |
| `jobs` | `10` | Number of parallel make jobs |

**Usage:**
```bash
# Default build (vendor + kernel images, -j10)
cd ~/workspace/mt8391
mtk_build

# Custom job count
mtk_build vnd_aiot8391p2_64_bsp-userdebug 16
```

**What it does:**
1. Validates current path contains `mt8391` or `mt8391_MSSI_V`
2. Validates lunch target matches expected default
3. Runs `source build/envsetup.sh`
4. Sets `OUT_DIR=out`
5. Runs `lunch <target>`
6. Runs `make -j<jobs> vnd_images krn_images`
7. Saves build output to `build.log`

---

### `mtk_split_build [target] [vendor_path]`

Build using MediaTek split build helper (`split_build_helper.py`).

| Parameter | Default | Description |
|-----------|---------|-------------|
| `target` | `full_aiot8391p2_64_bsp-userdebug` | Split build lunch target |
| `vendor_path` | *(empty)* | Optional vendor framework path (`--vf-path`) |

**Usage:**
```bash
# Default split build (no vendor path)
cd ~/workspace/mt8391
mtk_split_build

# With vendor path (bifurcated build from mt8391_MSSI_V)
cd ~/workspace/mt8391_MSSI_V
mtk_split_build full_aiot8391p2_64_bsp-userdebug ../mt8391
```

**What it does:**
1. Validates current path contains `mt8391` or `mt8391_MSSI_V`
2. Validates target matches expected default
3. Runs `split_build_helper.py --run <target>`
4. If `vendor_path` provided, adds `--vf-path <vendor_path>`

---

### `mtk_package [target] [output_path]`

Package merged build output into a `.tar.gz` for flashing.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `target` | `full_aiot8391p2_64_bsp-userdebug` | Target name (used in output filename) |
| `output_path` | `../flash/<target>_t-alps-release-u0.mp5-aiot-V7.150.tar.gz` | Output tar.gz path |

**Usage:**
```bash
# Default packaging
cd ~/workspace/mt8391
mtk_package

# Custom output path
mtk_package full_aiot8391p2_64_bsp-userdebug ~/my_flash_image.tar.gz
```

**What it does:**
1. Validates current path contains `mt8391` or `mt8391_MSSI_V`
2. Creates tar.gz from `out/target/product/aiot8391p2_64_bsp/merged/`
3. Excludes `target_files.zip` and `testcases`
4. Saves to `../flash/` (workspace level) by default

---

## Typical Build Workflow

```bash
# 1. Enter Docker container
./setenv_docker.sh

# 2. Navigate to source tree
cd ~/workspace/mt8391

# 3. Build
mtk_split_build

# 4. Package for flashing
mtk_package
```

---

## Change History

| Date | Description |
|------|-------------|
| 2026-03-02 | Added `mtk_build`, `mtk_split_build`, `mtk_package` helper functions |
| 2026-03-02 | Added `mtk_check_workspace` path validation |
| 2026-03-02 | Added `--vf-path` support for bifurcated builds in `mtk_split_build` |
| 2026-03-02 | Added target validation to prevent wrong lunch targets |
| Initial | Docker container setup with `create-user.sh` and `setenv_docker.sh` |
