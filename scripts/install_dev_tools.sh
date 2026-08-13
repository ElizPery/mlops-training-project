#!/bin/bash
set -euo pipefail

LOG_FILE="install.log"
touch "$LOG_FILE"

# HELPER FUNCTIONS

# 1. Custom logging
log() {
    local level="$1"; shift
    local timestamp
    timestamp="$(date +'%Y-%m-%d %H:%M:%S')"
    local msg="[$timestamp] [$level] $*"
    
    # Writing to log file
    echo "$msg" >> "$LOG_FILE"
    
    # Writing to console
    case "$level" in
        INFO)  echo "INFO: $msg" ;;
        WARN)  echo "WARN: $msg" ;;
        ERROR) echo "ERROR: $msg" ;;
    esac
}

# 2. Checking virtualenv
in_virtualenv() {
    python3 -c "import sys; raise SystemExit(0 if sys.prefix != sys.base_prefix else 1)" &>/dev/null
}

# 3. Checking for PEP 668 EXTERNALLY-MANAGED (Ubuntu 23.04+ / Debian 12+)
python_is_externally_managed() {
    python3 -c "
        import sysconfig, os
        marker = os.path.join(sysconfig.get_path('stdlib'), 'EXTERNALLY-MANAGED')
        raise SystemExit(0 if os.path.exists(marker) else 1)
        " &>/dev/null
}

#  DOCKER & COMPOSE INSTALLATION

install_docker() {
    if command -v docker >/dev/null 2>&1; then
        log "INFO" "Docker is already installed: $(docker --version)"
    else
        log "WARN" "Docker not found. Attempting automatic installation..."
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL https://get.docker.com | sh && \
            sudo usermod -aG docker "$USER" 2>/dev/null || true
            log "INFO" "Docker installed successfully."
        else
            log "ERROR" "curl is missing. Please install Docker manually: https://docs.docker.com/engine/install/"
        fi
    fi
}

install_docker_compose() {
    # Checking for Docker Compose V2
    if docker compose version >/dev/null 2>&1; then
        log "INFO" "Docker Compose V2 is already installed: $(docker compose version)"
    else
        log "WARN" "Docker Compose V2 not found. Attempting installation..."
        local PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"
        if command -v sudo >/dev/null 2>&1 || [ -w "/usr/local/lib/docker" ]; then
            sudo mkdir -p "$PLUGIN_DIR"
            sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
                -o "$PLUGIN_DIR/docker-compose"
            sudo chmod +x "$PLUGIN_DIR/docker-compose"
            log "INFO" "Docker Compose V2 installed successfully."
        else
            log "ERROR" "Cannot install Docker Compose V2 automatically. Please install manually."
        fi
    fi
}

# PYTHON 3.13+ & PIP CHECK/INSTALL

install_python() {
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
        MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
        MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)

        if [ "$MAJOR" -ge 3 ] && [ "$MINOR" -ge 13 ]; then
            log "INFO" "Python version is compliant: $(python3 --version)"
            return 0
        else
            log "WARN" "Installed Python version ($PYTHON_VERSION) is lower than required 3.13+."
        fi
    else
        log "WARN" "Python3 is not installed."
    fi

    # Try installing Python 3.13 (Ubuntu/Debian)
    if command -v apt >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
        log "INFO" "Attempting to install Python 3.13 via deadsnakes PPA..."
        sudo apt update -y
        sudo apt install -y software-properties-common
        sudo add-apt-repository -y ppa:deadsnakes/ppa
        sudo apt update -y
        if sudo apt install -y python3.13 python3.13-venv python3.13-dev; then
            log "INFO" "Python 3.13 installed successfully."
            return 0
        fi
    fi

    log "ERROR" "Automatic Python 3.13 installation is not supported on this OS. Please install Python >= 3.13 manually."
    exit 1
}

install_pip() {
    if ! command -v pip3 >/dev/null 2>&1; then
        log "WARN" "pip3 not found. Attempting installation..."
        if command -v apt >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
            if sudo apt update -y && sudo apt install -y python3-pip; then
                log "INFO" "pip3 installed successfully."
                return 0
            fi
        fi
        
        if ! python3 -m ensurepip --default-pip 2>/dev/null; then
            log "ERROR" "Failed to install pip3. Please install pip3 manually."
            exit 1
        fi
    fi
    
    log "INFO" "pip3 is available: $(pip3 --version)"
}

# PYTHON PACKAGES INSTALLATION

install_python_packages() {
    local EXTRA_FLAGS=""

    if in_virtualenv; then
        log "INFO" "Running inside a Python virtual environment."
    else
        log "WARN" "Running outside virtual environment (system level)."
        if python_is_externally_managed; then
            log "WARN" "System is EXTERNALLY-MANAGED (PEP 668). Adding '--break-system-packages' flag."
            EXTRA_FLAGS="--break-system-packages"
        fi
    fi

    log "INFO" "Checking and installing Python ML dependencies..."

    if [ -f "requirements.txt" ]; then
        python3 -m pip install $EXTRA_FLAGS --quiet --upgrade pip || true
        if python3 -m pip install $EXTRA_FLAGS --quiet -r requirements.txt; then
            log "INFO" "Successfully installed/verified packages from requirements.txt"
        else
            log "ERROR" "Failed to install packages from requirements.txt"
            exit 1
        fi
    else
        log "WARN" "requirements.txt not found. Installing pinned versions (torch==2.7.0, torchvision==0.22.0, pillow==11.2.1)..."
        python3 -m pip install $EXTRA_FLAGS --quiet --upgrade pip || true
        
        if python3 -m pip install $EXTRA_FLAGS --quiet "torch==2.7.0" "torchvision==0.22.0" "pillow==11.2.1"; then
            log "INFO" "Successfully installed pinned Python 3.13 packages."
        else
            log "ERROR" "Failed to install default packages (torch==2.7.0, torchvision==0.22.0, pillow==11.2.1)."
            exit 1
        fi
    fi
}

# VERIFICATION

verify_installations() {
    log "INFO" "Verifying installed package imports:"

    local FAILED=0

    python3 -c "import torch; print('  - PyTorch:', torch.__version__)" >> "$LOG_FILE" 2>&1 \
        && log "INFO" "PyTorch import successful" \
        || { log "ERROR" "PyTorch import failed"; FAILED=1; }

    python3 -c "import torchvision; print('  - Torchvision:', torchvision.__version__)" >> "$LOG_FILE" 2>&1 \
        && log "INFO" "Torchvision import successful" \
        || { log "ERROR" "Torchvision import failed"; FAILED=1; }

    python3 -c "import PIL; print('  - Pillow:', PIL.__version__)" >> "$LOG_FILE" 2>&1 \
        && log "INFO" "Pillow import successful" \
        || { log "ERROR" "Pillow import failed"; FAILED=1; }

    if [ "$FAILED" -ne 0 ]; then
        log "ERROR" "Environment verification failed! One or more libraries could not be imported."
        exit 1
    fi
}

# MAIN EXECUTION FLOW

log "INFO" "=========================================="
log "INFO" "Start dev environment setup"
log "INFO" "=========================================="

install_docker
install_docker_compose
install_python
install_pip
install_python_packages
verify_installations

log "INFO" "=========================================="
log "INFO" "Dev environment check completed"
log "INFO" "=========================================="