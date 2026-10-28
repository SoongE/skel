#!/usr/bin/env bash
set -uEo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
PYTHON=1
LINK=0
APT=1

APT_PACKAGES=(
  sudo openssh-client openssh-server sshfs git tree zsh tmux ncurses-term
  zip unzip rsync vim wget curl ca-certificates tzdata language-pack-en fontconfig
  autojump miller fd-find bat ripgrep fzf iotop iftop progress net-tools lsof
  build-essential libglib2.0-0 libaio-dev libegl1 libgles2 libturbojpeg ffmpeg
)
APT_OPTIONAL=(lsd btop duf libnccl2 libnccl-dev)
UV_TOOLS=(nvitop tmuxp)
VENV_PACKAGES=(torch numpy transformers timm wandb einops datasets accelerate jupyterlab ipykernel)

usage() {
  cat <<EOF
Usage: $0 [--link] [--no-apt] [--no-python]
  --link       symlink dotfiles to this repo instead of copying
  --no-apt     (Linux) skip apt update/install
  --no-python  (Linux) skip creating ~/.base_venv
EOF
}

for arg in "$@"; do
  case $arg in
    --link) LINK=1 ;;
    --no-apt) APT=0 ;;
    --no-python) PYTHON=0 ;;
    -h | --help) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; }

FAILED_STEPS=()
STEP_FAILED=0

on_error() {
  local status=$? cmd=$BASH_COMMAND caller=${FUNCNAME[1]:-}
  STEP_FAILED=1
  case $caller in step | on_error) return 0 ;; esac
  case $cmd in return*) return 0 ;; esac
  case $(type -t -- "${cmd%% *}" 2>/dev/null || true) in function) return 0 ;; esac
  warn "Failed (exit $status): $cmd"
}
trap on_error ERR

step() {
  STEP_FAILED=0
  "$@"
  if [[ $STEP_FAILED -eq 1 ]]; then FAILED_STEPS+=("$1"); fi
}

as_root() {
  local status=0
  if [[ $EUID -eq 0 ]]; then "$@" || status=$?; else sudo "$@" || status=$?; fi
  if [[ $status -ne 0 ]]; then
    warn "Failed (exit $status): $*"
    return "$status"
  fi
}

place() {
  local src="$DOTFILES/dotfiles/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L $dst ]]; then
    rm "$dst"
  elif [[ -e $dst ]] && ! cmp -s "$src" "$dst"; then
    mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
  fi
  if [[ $LINK -eq 1 ]]; then
    ln -sfn "$src" "$dst"
  else
    cp "$src" "$dst"
  fi
}

shim() {
  local real="$1" name="$2"
  if command -v "$real" >/dev/null && ! command -v "$name" >/dev/null; then
    as_root ln -sf "$(command -v "$real")" "/usr/local/bin/$name"
  fi
}

install_apt_packages() {
  log "Installing apt packages"
  as_root apt-get update
  local pkg available=()
  for pkg in "${APT_OPTIONAL[@]}"; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then available+=("$pkg"); fi
  done
  as_root env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends "${APT_PACKAGES[@]}" "${available[@]}"
  as_root apt-get clean
  shim fdfind fd
  shim batcat bat
}

install_starship() {
  if ! command -v starship >/dev/null; then
    log "Installing starship"
    curl -fsSL https://starship.rs/install.sh | as_root sh -s -- -y -b /usr/local/bin
  fi
}

install_uv() {
  if ! command -v uv >/dev/null && [[ ! -x $HOME/.local/bin/uv ]]; then
    log "Installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh
  fi
  export PATH="$HOME/.local/bin:$PATH"
}

install_uv_tools() {
  log "Installing ${UV_TOOLS[*]}"
  local tool
  for tool in "${UV_TOOLS[@]}"; do
    as_root env UV_TOOL_DIR=/opt/uv/tools UV_TOOL_BIN_DIR=/usr/local/bin UV_PYTHON_INSTALL_DIR=/opt/uv/python \
      "$(command -v uv)" tool install "$tool"
  done
}

setup_base_venv() {
  log "Setting up ~/.base_venv"
  if [[ ! -d $HOME/.base_venv ]]; then
    uv venv "$HOME/.base_venv" --prompt base
  fi
  uv pip install --python "$HOME/.base_venv/bin/python" --torch-backend=auto "${VENV_PACKAGES[@]}"
}

install_fonts() {
  log "Installing fonts"
  local dir=/usr/share/fonts/truetype/helvetica-neue
  as_root mkdir -p "$dir"
  as_root cp "$DOTFILES"/fonts/helvetica-neue/*.ttf "$dir"/
  as_root fc-cache -f >/dev/null
  rm -rf "$HOME/.cache/matplotlib"
}

set_login_shell() {
  local user zsh_path
  user="$(id -un)"
  zsh_path="$(command -v zsh)"
  if [[ "$(getent passwd "$user" | cut -d: -f7)" != */zsh ]]; then
    log "Changing login shell to zsh"
    as_root chsh -s "$zsh_path" "$user"
  fi
}

install_macos() {
  if ! command -v brew >/dev/null; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  log "Installing Brewfile packages"
  brew bundle --file="$DOTFILES/Brewfile"
  install_uv
  if ! command -v claude >/dev/null; then
    log "Installing Claude Code"
    curl -fsSL https://claude.ai/install.sh | bash
  fi
}

load_zsh_plugins() {
  log "Loading zsh plugins"
  zsh -i -c true </dev/null
}

install_dotfiles() {
  if [[ $LINK -eq 1 ]]; then log "Linking dotfiles"; else log "Copying dotfiles"; fi
  place zshenv "$HOME/.zshenv"
  place zprofile "$HOME/.zprofile"
  place zshrc "$HOME/.zshrc"
  place aliases "$HOME/.aliases"
  place tmux.conf "$HOME/.tmux.conf"
  place starship.toml "$HOME/.config/starship.toml"
  if [[ $OS == Darwin ]]; then
    place gitconfig "$HOME/.gitconfig"
  fi
}

case $OS in
  Linux)
    if [[ $APT -eq 1 ]]; then step install_apt_packages; fi
    step install_starship
    step install_uv
    step install_uv_tools
    if [[ $PYTHON -eq 1 ]]; then step setup_base_venv; fi
    step install_fonts
    step set_login_shell
    ;;
  Darwin)
    step install_macos
    ;;
  *)
    echo "Unsupported OS: $OS" >&2
    exit 1
    ;;
esac

step install_dotfiles
step load_zsh_plugins

if [[ ${#FAILED_STEPS[@]} -gt 0 ]]; then
  warn "Finished with errors in: ${FAILED_STEPS[*]}"
  exit 1
fi
log "Done. Open a new shell to apply."
