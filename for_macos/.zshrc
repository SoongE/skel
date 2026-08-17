# ── PATH ─────────────────────────────────────────────
export PATH=/opt/homebrew/bin:$PATH

if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH=/opt/homebrew/opt/ruby/bin:$PATH
  [ -s ~/.cache/gemdir ] || { mkdir -p ~/.cache; gem environment gemdir >| ~/.cache/gemdir 2>/dev/null; }
  [ -s ~/.cache/gemdir ] && export PATH="$(<~/.cache/gemdir)/bin:$PATH"
fi

# ── history ──────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS EXTENDED_HISTORY INC_APPEND_HISTORY
setopt AUTO_CD INTERACTIVE_COMMENTS

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
alias vim="nvim"

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
alias rs='rsync -ahvL'

eval "$(starship init zsh)"

zinit light zdharma-continuum/fast-syntax-highlighting
