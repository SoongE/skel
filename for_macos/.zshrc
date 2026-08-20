# ── PATH ─────────────────────────────────────────────
export LS_COLORS="$(vivid generate catppuccin-mocha):di=1;38;5;117:ln=38;5;180"

# ── history ──────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS EXTENDED_HISTORY INC_APPEND_HISTORY
setopt AUTO_CD INTERACTIVE_COMMENTS

# 화살표 위/아래 = 입력한 접두어로 히스토리 검색
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# ── zinit ────────────────────────────────────────────
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light zsh-users/zsh-completions
autoload -Uz compinit && compinit -d ~/.cache/zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'

# ── autojump ─────────────────────────────────────────
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && \
  source /opt/homebrew/etc/profile.d/autojump.sh

# ── aliases ──────────────────────────────────────────
alias ls="lsd"
alias la="ls -al"
alias ll="lsd -la"
alias lt="lsd --tree"
alias grep="rg"
alias top="btop"
alias df="duf"
alias vim="nvim"
alias nv='watch -c -n 1 nvidia-htop.py -c -l'

alias dai='docker attach seungminDockImp'
alias das='docker attach seungminDock'
alias dim='docker images'
alias dps='docker ps -a'

alias tl='tmux ls'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tk='tmux kill-session'
alias til='watch -c -n 1 view_tmux'
alias xl='tmuxp load'

alias gs='git status'
alias gm='git commit -m'
alias gp='git push'
alias ga='git add'
alias gal='git add .'
alias gd='git diff'

alias pt='python3'
alias jp='jupyter notebook --NotebookApp.token="" --NotebookApp.password=""'
alias rs='rsync -ahvL'

# ── prompt ───────────────────────────────────────────
eval "$(starship init zsh)"

# ── syntax highlighting (반드시 마지막) ──────────────
zinit light zdharma-continuum/fast-syntax-highlighting

# ── turn off mouse reporting ─────────────────────────
autoload -Uz add-zsh-hook
_reset_input_modes() {
  printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1015l\e[?1004l'
}
add-zsh-hook precmd _reset_input_modes
