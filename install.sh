#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# ClawWorker Installer
# Detects OS/arch, downloads the latest release, installs the
# binary, and registers it as a system service (systemd / launchd).
#
# Usage:
#   curl -fsSL https://get.clawworker.ai/install.sh | bash
#   curl -fsSL https://get.clawworker.ai/install.sh | bash -s -- --version v1.2.0
#   curl -fsSL https://get.clawworker.ai/install.sh | bash -s -- --mode gateway
#   curl -fsSL https://get.clawworker.ai/install.sh | bash -s -- --no-service
# ──────────────────────────────────────────────────────────────
set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────
INSTALL_DIR="/usr/local/bin"
DATA_DIR="${HOME}/.clawworker"
SERVICE_MODE="gateway"
INSTALL_SERVICE=true
VERSION="latest"
REPO_OWNER="clawworker"
REPO_NAME="install"
BINARY_NAME="clawworker"

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────
info()    { printf "${BLUE}[info]${NC}    %s\n" "$*"; }
success() { printf "${GREEN}[✓]${NC}       %s\n" "$*"; }
warn()    { printf "${YELLOW}[warn]${NC}    %s\n" "$*"; }
error()   { printf "${RED}[error]${NC}   %s\n" "$*" >&2; }
fatal()   { error "$@"; exit 1; }

banner() {
  printf "\n${CYAN}${BOLD}"
  cat << 'ART'
   _____ _                __        __         _
  / ____| |               \ \      / /        | |
 | |    | | __ ___      __ \ \ /\ / /__  _ __ | | _____ _ __
 | |    | |/ _` \ \ /\ / /  \ \/  \/ / _ \| '__| |/ / _ \ '__|
 | |____| | (_| |\ V  V /    \  /\  / (_) | |  |   <  __/ |
  \_____|_|\__,_| \_/\_/      \/  \/ \___/|_|  |_|\_\___|_|
ART
  printf "${NC}\n"
  printf "  ${BOLD}Your AI assistant, everywhere.${NC}\n\n"
}

# ── Parse arguments ───────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)    VERSION="$2"; shift 2 ;;
    --mode)       SERVICE_MODE="$2"; shift 2 ;;
    --install-dir) INSTALL_DIR="$2"; shift 2 ;;
    --no-service) INSTALL_SERVICE=false; shift ;;
    --help)
      banner
      echo "Usage: install.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --version VERSION    Install specific version (default: latest)"
      echo "  --mode MODE          Service mode: gateway|serve|agent (default: gateway)"
      echo "  --install-dir DIR    Binary install directory (default: /usr/local/bin)"
      echo "  --no-service         Skip service installation"
      echo "  --help               Show this help"
      exit 0
      ;;
    *) fatal "Unknown option: $1. Use --help for usage." ;;
  esac
done

# ── Detect platform ──────────────────────────────────────────
detect_os() {
  local os
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  case "$os" in
    linux*)  echo "linux" ;;
    darwin*) echo "darwin" ;;
    *)       fatal "Unsupported operating system: $os. ClawWorker supports Linux and macOS." ;;
  esac
}

detect_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64)   echo "amd64" ;;
    aarch64|arm64)   echo "arm64" ;;
    *)               fatal "Unsupported architecture: $arch. ClawWorker supports amd64 and arm64." ;;
  esac
}

# ── Resolve version ──────────────────────────────────────────
resolve_version() {
  if [[ "$VERSION" == "latest" ]]; then
    info "Fetching latest release version..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest" \
      | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name":\s*"([^"]+)".*/\1/')
    if [[ -z "$VERSION" ]]; then
      fatal "Could not determine latest version. Check https://github.com/${REPO_OWNER}/${REPO_NAME}/releases"
    fi
  fi
  success "Version: ${VERSION}"
}

# ── Download & verify ────────────────────────────────────────
download_binary() {
  local os="$1" arch="$2"
  local asset="${BINARY_NAME}-${os}-${arch}.tar.gz"
  local url="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/${asset}"
  local checksum_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}/checksums.txt"
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  info "Downloading ${BINARY_NAME} ${VERSION} for ${os}/${arch}..."
  if ! curl -fsSL --progress-bar -o "${tmp_dir}/${asset}" "$url"; then
    rm -rf "$tmp_dir"
    fatal "Download failed. Check that version ${VERSION} exists for ${os}/${arch}."
  fi

  # Verify checksum
  info "Verifying checksum..."
  if curl -fsSL -o "${tmp_dir}/checksums.txt" "$checksum_url" 2>/dev/null; then
    local expected
    expected=$(grep "${asset}" "${tmp_dir}/checksums.txt" | awk '{print $1}')
    if [[ -n "$expected" ]]; then
      local actual
      if command -v sha256sum &>/dev/null; then
        actual=$(sha256sum "${tmp_dir}/${asset}" | awk '{print $1}')
      elif command -v shasum &>/dev/null; then
        actual=$(shasum -a 256 "${tmp_dir}/${asset}" | awk '{print $1}')
      fi
      if [[ -n "${actual:-}" && "$actual" != "$expected" ]]; then
        rm -rf "$tmp_dir"
        fatal "Checksum mismatch! Expected: ${expected}, Got: ${actual}"
      fi
      success "Checksum verified"
    else
      warn "Checksum entry not found for ${asset}, skipping verification"
    fi
  else
    warn "Checksums file not available, skipping verification"
  fi

  # Extract
  info "Extracting..."
  tar xzf "${tmp_dir}/${asset}" -C "${tmp_dir}"

  # Install binary
  local bin_path="${tmp_dir}/${BINARY_NAME}-${os}-${arch}"
  if [[ ! -f "$bin_path" ]]; then
    # Try without os-arch suffix
    bin_path="${tmp_dir}/${BINARY_NAME}"
  fi

  if [[ ! -f "$bin_path" ]]; then
    rm -rf "$tmp_dir"
    fatal "Binary not found in archive"
  fi

  chmod +x "$bin_path"

  # Move to install dir (may need sudo)
  if [[ -w "$INSTALL_DIR" ]]; then
    mv "$bin_path" "${INSTALL_DIR}/${BINARY_NAME}"
  else
    info "Elevated permissions required to install to ${INSTALL_DIR}"
    sudo mv "$bin_path" "${INSTALL_DIR}/${BINARY_NAME}"
  fi

  rm -rf "$tmp_dir"
  success "Installed ${BINARY_NAME} to ${INSTALL_DIR}/${BINARY_NAME}"
}

# ── Service installation ─────────────────────────────────────
install_service_linux() {
  local service_file="${HOME}/.config/systemd/user/${BINARY_NAME}.service"
  mkdir -p "$(dirname "$service_file")"
  mkdir -p "${DATA_DIR}"

  cat > "$service_file" << UNIT
[Unit]
Description=ClawWorker AI Assistant
After=network.target

[Service]
Type=simple
ExecStart="${INSTALL_DIR}/${BINARY_NAME}" ${SERVICE_MODE}
WorkingDirectory="${DATA_DIR}"
Restart=on-failure
RestartSec=5
Environment="CLAWWORKER_DATA_DIR=${DATA_DIR}"

[Install]
WantedBy=default.target
UNIT

  systemctl --user daemon-reload
  systemctl --user enable "${BINARY_NAME}"
  success "Systemd user service installed and enabled"

  info "Starting ${BINARY_NAME}..."
  if systemctl --user start "${BINARY_NAME}"; then
    success "Service started"
  else
    warn "Service could not start — run 'clawworker onboard' to configure, then 'systemctl --user start ${BINARY_NAME}'"
  fi
}

install_service_darwin() {
  local plist_dir="${HOME}/Library/LaunchAgents"
  local plist_file="${plist_dir}/ai.clawworker.${BINARY_NAME}.plist"
  local log_dir="${HOME}/Library/Logs/${BINARY_NAME}"
  mkdir -p "$plist_dir" "$log_dir" "${DATA_DIR}"

  cat > "$plist_file" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>ai.clawworker.${BINARY_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${INSTALL_DIR}/${BINARY_NAME}</string>
        <string>${SERVICE_MODE}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${log_dir}/${BINARY_NAME}.log</string>
    <key>StandardErrorPath</key>
    <string>${log_dir}/${BINARY_NAME}.err.log</string>
    <key>WorkingDirectory</key>
    <string>${DATA_DIR}</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>CLAWWORKER_DATA_DIR</key>
        <string>${DATA_DIR}</string>
    </dict>
</dict>
</plist>
PLIST

  launchctl load "$plist_file" 2>/dev/null || true
  success "LaunchAgent installed and loaded"

  # Check if it's running
  if launchctl list "ai.clawworker.${BINARY_NAME}" &>/dev/null; then
    success "Service started"
  else
    warn "Service registered but may need configuration — run 'clawworker onboard' first"
  fi
}

install_service() {
  local os="$1"
  info "Installing ${BINARY_NAME} as a system service..."

  case "$os" in
    linux)  install_service_linux ;;
    darwin) install_service_darwin ;;
  esac
}

# ── Uninstall helper (embedded for reference) ────────────────
print_uninstall_info() {
  local os="$1"
  echo ""
  info "To uninstall later, run:"
  echo ""
  case "$os" in
    linux)
      echo "  systemctl --user stop ${BINARY_NAME}"
      echo "  systemctl --user disable ${BINARY_NAME}"
      echo "  rm ~/.config/systemd/user/${BINARY_NAME}.service"
      echo "  systemctl --user daemon-reload"
      echo "  sudo rm ${INSTALL_DIR}/${BINARY_NAME}"
      ;;
    darwin)
      echo "  launchctl unload ~/Library/LaunchAgents/ai.clawworker.${BINARY_NAME}.plist"
      echo "  rm ~/Library/LaunchAgents/ai.clawworker.${BINARY_NAME}.plist"
      echo "  sudo rm ${INSTALL_DIR}/${BINARY_NAME}"
      ;;
  esac
  echo ""
}

# ── Post-install info ────────────────────────────────────────
print_next_steps() {
  local os="$1"
  echo ""
  printf "${BOLD}${GREEN}━━━ Installation complete! ━━━${NC}\n"
  echo ""
  printf "${BOLD}Next steps:${NC}\n"
  echo ""
  echo "  1. Configure ClawWorker:"
  echo "     ${BINARY_NAME} onboard"
  echo ""
  echo "  2. Or set environment variables:"
  echo "     export CLAWWORKER_PROVIDER=openai"
  echo "     export CLAWWORKER_API_KEY=sk-..."
  echo ""

  if [[ "$INSTALL_SERVICE" == true ]]; then
    case "$os" in
      linux)
        echo "  3. Manage the service:"
        echo "     systemctl --user status ${BINARY_NAME}"
        echo "     systemctl --user restart ${BINARY_NAME}"
        echo "     journalctl --user -u ${BINARY_NAME} -f"
        ;;
      darwin)
        echo "  3. Manage the service:"
        echo "     launchctl list ai.clawworker.${BINARY_NAME}"
        echo "     tail -f ~/Library/Logs/${BINARY_NAME}/${BINARY_NAME}.log"
        ;;
    esac
    echo ""
  fi

  echo "  Quick test:"
  echo "     ${BINARY_NAME} agent -m \"Hello, ClawWorker!\""
  echo ""
  printf "${BOLD}Documentation:${NC} https://github.com/${REPO_OWNER}/${REPO_NAME}#readme\n"
  echo ""
}

# ── Update command ────────────────────────────────────────────
# This is used when the script is called with 'update' as first arg
if [[ "${1:-}" == "update" ]]; then
  shift
  VERSION="${1:-latest}"
  OS="$(detect_os)"
  ARCH="$(detect_arch)"
  resolve_version
  info "Updating ClawWorker..."

  # Stop service before update
  case "$OS" in
    linux)  systemctl --user stop "${BINARY_NAME}" 2>/dev/null || true ;;
    darwin) launchctl unload "${HOME}/Library/LaunchAgents/ai.clawworker.${BINARY_NAME}.plist" 2>/dev/null || true ;;
  esac

  download_binary "$OS" "$ARCH"

  # Restart service
  case "$OS" in
    linux)  systemctl --user start "${BINARY_NAME}" 2>/dev/null || true ;;
    darwin) launchctl load "${HOME}/Library/LaunchAgents/ai.clawworker.${BINARY_NAME}.plist" 2>/dev/null || true ;;
  esac

  success "ClawWorker updated to ${VERSION}"
  exit 0
fi

# ── Main ──────────────────────────────────────────────────────
main() {
  banner

  local os arch
  os="$(detect_os)"
  arch="$(detect_arch)"

  info "Detected platform: ${os}/${arch}"

  resolve_version
  download_binary "$os" "$arch"

  # Create data directory
  mkdir -p "${DATA_DIR}"

  # Verify installation
  if "${INSTALL_DIR}/${BINARY_NAME}" version &>/dev/null; then
    local installed_version
    installed_version=$("${INSTALL_DIR}/${BINARY_NAME}" version 2>/dev/null || echo "unknown")
    success "Binary verified: ${installed_version}"
  else
    warn "Binary installed but could not verify version"
  fi

  # Install as service
  if [[ "$INSTALL_SERVICE" == true ]]; then
    install_service "$os"
  else
    info "Skipping service installation (--no-service)"
  fi

  print_next_steps "$os"
  print_uninstall_info "$os"
}

main
