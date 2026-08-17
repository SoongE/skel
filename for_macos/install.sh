#!/bin/bash
set -euo pipefail

echo "🚀 Mac 터미널 기본 패키지 설치를 시작합니다..."

# ============================================
# 1. Homebrew 설치 (없는 경우)
# ============================================
if ! command -v brew &>/dev/null; then
  echo "📦 Homebrew 설치 중..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ============================================
# 2. Ghostty 설치
# ============================================
echo "👻 Ghostty 설치 중..."
brew install --cask ghostty

# ============================================
# 3. 폰트 설치
# ============================================
echo "🔤 폰트 설치 중..."
brew install --cask font-hack-nerd-font
brew install --cask font-noto-sans-cjk-kr

# ============================================
# 4. CLI 도구 설치
# ============================================
echo "🛠️ CLI 도구 설치 중..."
brew install lsd bat fzf fd ripgrep git-delta btop dust duf neovim starship

# ============================================
# 6. Zinit 설치
# ============================================
if [ ! -d "$HOME/.local/share/zinit/zinit.git" ]; then
  echo "🔌 Zinit 설치 중..."
  mkdir -p "$HOME/.local/share/zinit"
  git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
fi

# ============================================
# 7. AI 도구 설치
# ============================================
echo "🤖 AI 코딩 도구 설치 중..."

# Claude Code
if ! command -v claude &>/dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

echo ""
echo "✅ 기본 패키지 설치가 완료되었습니다!"
echo "👉 이제 아래 설정 파일(ghostty, starship, .zshrc)을 적용하세요."
